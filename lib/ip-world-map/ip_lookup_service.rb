require 'net/http'
require 'typhoeus'
require 'yaml'

class IpLookupService

  def initialize filename = nil
    @filename = filename || File.join(File.dirname(__FILE__), '..', '..', 'resources', 'coordinates.yml') 
    reset
  end

  def reset
    @host_coordinates = {}
    @host_ips = {}
  end

  def coordinates_for_hosts hosts
    uniq_hosts = hosts.uniq

    uniq_hosts.each do |host|
      @host_ips[host] ||= IPSocket.getaddress(host) rescue nil
    end

    hydra = Typhoeus::Hydra.new
    uniq_hosts.each do |host|
      unless @host_coordinates[host]
        request = Typhoeus::Request.new("http://api.hostip.info/get_html.php?position=true&ip=#{@host_ips[host]}")
        request.on_complete do |response|
          @host_coordinates[host] = extract_longitude_and_latitude(response.body)
        end
        hydra.queue(request)
      end
    end
    hydra.run

    @host_coordinates
  end

  def coordinates_for_host host
    unless @host_coordinates[host]
      @host_ips[host] ||= IPSocket.getaddress(host) rescue nil
      response = Net::HTTP.get('api.hostip.info', "/get_html.php?position=true&ip=#{@host_ips[host]}")
      @host_coordinates[host] = extract_longitude_and_latitude(response)
    end

    @host_coordinates[host]
  end

  def extract_longitude_and_latitude string
    latitude  = string.match(/Latitude: (-?[0-9.]+)/)[1].to_f  rescue nil
    longitude = string.match(/Longitude: (-?[0-9.]+)/)[1].to_f rescue nil
    [longitude, latitude]
  end

  def save_coordinates
    File.open(@filename, 'w'){ |f| f.write @host_coordinates.to_yaml }
  end

  def load_coordinates
    @host_coordinates = YAML.load_file(@filename) if File.readable? @filename
  end

  def stats
    unknown_coordinates, known_coordinates = @host_coordinates.partition{ |ip, coords| coords.include? nil }

    { :unknown_coordinates => unknown_coordinates.size, :known_coordinates => known_coordinates.size }
  end
end

