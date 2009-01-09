#!/usr/bin/env ruby

require 'zlib'

#LOG_FILE = "/var/log/apache2/access.log.1"
LOG_FILE = ARGV[0] || "/var/log/apache2/access.log.2.gz"

module FileUtils
  def self.open (filename, &block)
    if %w[.gz .Z].include? File.extname(filename)
      Zlib::GzipReader.open(filename, &block)
    else
      File.open(filename, &block)
    end
  end
end

module LogAnalyzer
  def details_from_line line
    {
      :host => line.scan(/^[\w.-]+/)[0],
      :date => line.scan(/\[[\w\/:+ ]+\]/)[0]
    }
  end

  def group_by_time access_ungrouped, window_in_seconds
    access_grouped
  end

  module_function :details_from_line
end


FileUtils.open(LOG_FILE) do |file|
  lines = file.readlines[0..9]
  lines.each do |line|
    details = LogAnalyzer::details_from_line(line)
    puts "#{details[:host]} - #{details[:date]}"
  end
end
