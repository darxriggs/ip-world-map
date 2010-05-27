class LogAnalyzer
  attr_accessor :host_coordinates

  def initialize *filenames
    @filenames = filenames.flatten.sort.uniq
    @ip_lookup_service = IpLookupService.new
    @ip_lookup_service.load_coordinates
  end

  def analyze
    details = []

    puts "\nReading files:" if $visualization_config.verbose
    @filenames.each do |filename|
      puts filename if $visualization_config.verbose
      FileUtils.open(filename).each_line do |line|
        details << details_from_line(line)
      end
    end

    hosts = details.collect{|detail| detail[:host]}
    coordinates = @ip_lookup_service.coordinates_for_hosts(hosts)

    details.collect! do |detail|
      detail[:coordinates] = coordinates[detail[:host]]
      detail
    end

    details
  end

  def details_from_line line
    host = extract_host_from_line(line)
    time = extract_time_from_line(line)
    { :time => time, :host => host }
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

