require 'net/http'
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

  def coordinates_for_host host
    unless @host_coordinates[host]
      @host_ips[host] ||= IPSocket.getaddr(host) rescue nil

      response = Net::HTTP.get('api.hostip.info', "/get_html.php?position=true&ip=#{@host_ips[host]}")
      latitude  = response.match(/Latitude: (-?[0-9.]+)/)[1].to_f  rescue nil
      longitude = response.match(/Longitude: (-?[0-9.]+)/)[1].to_f rescue nil
      @host_coordinates[host] = [longitude, latitude]
    end

    @host_coordinates[host]
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

