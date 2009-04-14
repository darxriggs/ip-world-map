#!/usr/bin/env ruby

require 'zlib'
require 'time'
require 'date'
require 'net/http'
require 'yaml'

module FileUtils
  def self.zipped? filename
    %w[.gz .Z].include? File.extname(filename)
  end

  def self.open (filename, &block)
    if zipped? filename
      Zlib::GzipReader.open(filename, &block)
    else
      File.open(filename, &block)
    end
  end
end


class LogAnalyzer
  attr_accessor :host_coordinates

  def initialize *filenames
    @filenames = filenames.flatten.sort.uniq
    @host_coordinates = {}
    @host_ips = {}
  end

  def ip_for_host host
    is_ip?(host) ? host : Socket.getaddrinfo(host, nil)[0][3] rescue nil
  end

  def is_ip? string
    /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$/.match(string) != nil
  end

  def coordinates_for_host host
    unless @host_coordinates[host]
      @host_ips[host] ||= ip_for_host(host)

      response = Net::HTTP.get('api.hostip.info', "/get_html.php?position=true&ip=#{@host_ips[host]}").split(/\n/)
      latitude  = response[2].match(/Latitude: (-?[0-9.]+)/)[1].to_f  rescue nil
      longitude = response[3].match(/Longitude: (-?[0-9.]+)/)[1].to_f rescue nil
      @host_coordinates[host] = [longitude, latitude]
    end

    @host_coordinates[host]
  end

  def details_from_line line
    host = extract_host_from_line(line)
    time = extract_time_from_line(line)
    coordinates = coordinates_for_host(host)

    { :time => time, :host => host, :coordinates => coordinates }
  end

  def analyze
    details = []

    @filenames.each do |filename|
      puts filename
      FileUtils.open(filename) do |file|
        lines = file.readlines
        lines.each do |line|
          details << details_from_line(line)
        end
      end
    end

    details
  end

  def save_coordinates_to_file filename = 'coordinates.yml'
    File.open(filename, 'w'){ |f| f.write @host_coordinates.to_yaml }
  end

  def load_coordinates_from_file filename = 'coordinates.yml'
    @host_coordinates = YAML.load_file(filename)
  end

  def stats
    unknown_coordinates, known_coordinates = @host_coordinates.partition{ |ip, coords| coords.include? nil }

    { :unknown_coordinates => unknown_coordinates.size, :known_coordinates => known_coordinates.size }
  end

  def group_by_time details, slot_in_seconds
    latest_time = details.min{ |a,b| a[:time] <=> b[:time] }[:time]
    slot_time = slot_start_time(latest_time, slot_in_seconds)
    details_per_slot = {}

    # quite slow algorithm
#    while details.count > 0 do
#      slot_cap_time = slot_time + slot_in_seconds
#      details_in_slot, details = details.partition{ |data| data[:time] < slot_cap_time }
#      details_per_slot[slot_time] = details_in_slot
#      slot_time = slot_cap_time
#    end

    # TODO: maybe assign empty arrays to missing slots where no traffic was detected
    details.each do |data|
      time = slot_start_time(data[:time], slot_in_seconds)
      details_per_slot[time] = [] unless details_per_slot[time]
      details_per_slot[time] << data
    end

    details_per_slot
  end

  def slot_start_time time, slot_in_seconds
    Time.at(time.tv_sec - (time.tv_sec % slot_in_seconds))
  end
end


class ApacheLogAnalyzer < LogAnalyzer
  def initialize *filenames
    super
    @@host_regex = /^([\w.-]+)/
    @@time_regex = /\[(\d{2})\/([a-zA-Z]{3})\/(\d{4}):(\d{2}):(\d{2}):(\d{2}) [+-](\d{2})(\d{2})\]/
  end

  def extract_host_from_line line
    # IP: "123.1.2.3" or HOSTNAME: "hostname.domain"
    host = $1 if line =~ @@host_regex
  end

  def extract_time_from_line line
    # CLF format: "[dd/MMM/yyyy:hh:mm:ss +-hhmm]" => parsable format: "dd/MMM/yyyy hh:mm:ss +-hhmm"

  # 1. quite slow
  #  time_string = line.scan(/\[[\w\/:+ ]+\]/).first[1...-1].sub(':', ' ')
  #  Time.parse(time_string)

  # 2. TODO: add timezone information
    #dd, mmm, yyyy, hh, mm, ss, tz_hh, tz_mm = $1, $2, $3, $4, $5, $6, $7, $8 if line =~ @@time_regex
    #Time.utc(yyyy, mmm, dd, hh.to_i - tz_hh.to_i, mm, ss)
    dd, mmm, yyyy, hh, mm, ss = $1, $2, $3, $4, $5, $6 if line =~ @@time_regex
    Time.utc(yyyy, mmm, dd, hh, mm, ss)
  end
end


if $0 ==  __FILE__
  analyzer = ApacheLogAnalyzer.new(Dir.glob(ARGV))
  analyzer.load_coordinates_from_file

  details = analyzer.analyze
  details_per_slot = analyzer.group_by_time(details, 24 * 60 * 60)

  p analyzer.stats
  details_per_slot.sort().each{ |slot, values| p "#{slot}: #{values.size}" }
  p details_per_slot.size
end
