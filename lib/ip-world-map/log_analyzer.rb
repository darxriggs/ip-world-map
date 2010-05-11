require 'time'
require 'date'
require 'net/http'
require 'yaml'

class LogAnalyzer
  attr_accessor :host_coordinates

  def initialize *filenames
    @COORDINATES_FILE = File.join(File.dirname(__FILE__), '..', '..', 'resources', 'coordinates.yml') 
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

  def save_coordinates_to_file filename = @COORDINATES_FILE
    File.open(filename, 'w'){ |f| f.write @host_coordinates.to_yaml }
  end

  def load_cached_coordinates_from_file filename = @COORDINATES_FILE
    @host_coordinates = YAML.load_file(filename) if File.readable? filename
  end

  def stats
    unknown_coordinates, known_coordinates = @host_coordinates.partition{ |ip, coords| coords.include? nil }

    { :unknown_coordinates => unknown_coordinates.size, :known_coordinates => known_coordinates.size }
  end

  def calculate_oldest_time details
    details.min{ |a, b| a[:time] <=> b[:time] }[:time]
  end

  def group_by_time details, slot_in_seconds
    return {} unless details && slot_in_seconds
    details_per_slot = {}

    # TODO: maybe assign empty arrays to missing slots where no traffic was detected
    details.each do |detail|
      slot_start_time = calculate_slot_start_time(detail[:time], slot_in_seconds)
      details_per_slot[slot_start_time] ||= []
      details_per_slot[slot_start_time] << detail
    end

    details_per_slot
  end

  def calculate_slot_start_time time, slot_in_seconds
    Time.at(time.tv_sec - (time.tv_sec % slot_in_seconds))
  end
end

