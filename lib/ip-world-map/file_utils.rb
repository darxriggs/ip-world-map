require 'zlib'

module FileUtils
  def self.zipped? filename
    %w[.gz .Z].include? File.extname(filename)
  end

  def self.open filename, &block
    if zipped? filename
      Zlib::GzipReader.open(filename, &block)
    else
      File.open(filename, &block)
    end
  end
end

