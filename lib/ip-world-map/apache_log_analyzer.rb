require 'time'

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
    # CLF format: "[dd/MMM/yyyy:hh:mm:ss +-hhmm]"

    # TODO: add timezone information
    #dd, mmm, yyyy, hh, mm, ss, tz_hh, tz_mm = $1, $2, $3, $4, $5, $6, $7, $8 if line =~ @@time_regex
    #Time.utc(yyyy, mmm, dd, hh.to_i - tz_hh.to_i, mm, ss)
    dd, mmm, yyyy, hh, mm, ss = $1, $2, $3, $4, $5, $6 if line =~ @@time_regex
    Time.utc(yyyy, mmm, dd, hh, mm, ss)
  end
end

