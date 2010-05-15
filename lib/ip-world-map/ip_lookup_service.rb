require 'net/http'
require 'yaml'

class IpLookupService

  def self.ip_for_host host
    is_ip?(host) ? host : Socket.getaddrinfo(host, nil, Socket::AF_INET)[0][3] rescue nil
  end

  def self.is_ip? string
    /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$/.match(string) != nil
  end

  def initialize filename = nil
    @filename = filename || File.join(File.dirname(__FILE__), '..', '..', 'resources', 'coordinates.yml') 
    reset
    load_coordinates
  end

  def reset
    @host_coordinates = {}
    @host_ips = {}
  end

  def coordinates_for_host host
    unless @host_coordinates[host]
      @host_ips[host] ||= IpLookupService.ip_for_host(host)

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

