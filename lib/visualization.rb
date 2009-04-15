#!/usr/bin/env ruby

require 'rubygems'
require 'RMagick'
require File.dirname(__FILE__) + "/apache_log_analyzer.rb"

#coordinates_home = [11.6220338, 48.1276458] # Munich
#coordinates_home = [13.4114943, 52.5234802] # Berlin
#coordinates_home = [12.3387844, 45.4343363] # Venezia

###############################################################################

class Logfile
  def initialize filename
  end
end

###############################################################################

class LogfileMock
  attr_accessor :min_random_positions, :max_random_positions

  def initialize
    @min_random_positions = 5
    @max_random_positions = 50
  end

  def random_longitude_latitude
    [ -10 + rand(25) + rand, 40 + rand(15) + rand ]
  end

  def random_positions
    amount = @min_random_positions + rand(@max_random_positions - @min_random_positions + 1)
    Array.new(amount) { random_longitude_latitude }
  end
  alias :positions :random_positions
end

###############################################################################

class Visualization
  attr_accessor :position_quantization_in_degrees, :circle_radius

  #def initialize filename = File.dirname(__FILE__) + "/../maps/earthmap-1920x960.tif"
  def initialize filename = File.dirname(__FILE__) + "/../maps/earthmap-800x400.tif"
    @map_filename = filename
    @draw = Magick::Draw.new
    @image = Magick::ImageList.new(@map_filename).first
    @position_quantization_in_degrees = 0.0
    @position_visibility_threshold = 0.1
    @circle_radius = map_size[:width] / 250.0
  end

  def map_size
    { :width => @image.columns, :height => @image.rows }
  end

  def scale
    { :x => 360.0 / map_size[:width], :y => 180.0 / map_size[:height] }
  end

  def x_y_from_longitude_latitude longitude, latitude
    [ (180 + longitude) / scale[:x], (90 - latitude) / scale[:y] ]
  end

  def circle_parameters center_x, center_y
    [ center_x, center_y, center_x + circle_radius, center_y ]
  end

  def quantize_position position
    return position if @position_quantization_in_degrees == 0
    position.collect{ |element| element - element.remainder(@position_quantization_in_degrees) }
  end

  def quantize_positions positions
    positions.collect{ |position| quantize_position(position) }
  end

  def select_visible_positions positions
    positions.select{ |position| position.opacity >= @position_visibility_threshold }
  end

  def draw_positions actual_positions, previous_positions = []
    @draw.fill('red')
    @draw.fill_opacity('50%')

    positions = actual_positions.concat(previous_positions)
#    positions = select_visible_positions(positions)
    positions = quantize_positions(positions)

    positions.each do |longitude, latitude|
      x, y = x_y_from_longitude_latitude(longitude, latitude)
      @draw.circle(*circle_parameters(x, y))
    end

    @draw.draw(@image)

    @image
  end

  def display
    @image.display
  end
end

###############################################################################

# see http://en.wikipedia.org/wiki/Exponential_decay
class Decay
  def initialize initial_value, lifetime
    @initial_value = initial_value
    @lifetime = lifetime.to_f
  end

  def value time
    @initial_value * Math::exp(-time / @lifetime)
  end
end

###############################################################################

class PointInTime
  attr_reader :x, :y

  def initialize x, y, initial_opacity, lifetime
    @x, @y = x, y
    @time = 0
    @decay = Decay.new(initial_opacity, lifetime)
  end

  def opacity time
    @time = time if time
    @decay.value(time || @time)
  end
end

###############################################################################

#decay = Decay.new(10, 5)
#p (0..9).collect{ |t| decay.value(t) }
#exit

#logfile = LogfileMock.new
#visualization = Visualization.new
#visualization.position_quantization_in_degrees = 5.0
#visualization.draw_positions(logfile.positions)
#visualization.display
#exit

analyzer = ApacheLogAnalyzer.new(Dir.glob(ARGV))
analyzer.load_coordinates_from_file
details = analyzer.analyze
#grouped_details = analyzer.group_by_time(details, 3600)
grouped_details = analyzer.group_by_time(details, 86400)

list = Magick::ImageList.new
frames_per_second = 15

previous_positions = []
grouped_details.each_pair do |time, details|
  visualization = Visualization.new
  visualization.circle_radius = 1.0

  visualization.position_quantization_in_degrees = 0.0
  actual_positions = details.select{ |data| data[:coordinates].any? }.collect{ |data| data[:coordinates] }
p [time, details.size, actual_positions.size]
  image = visualization.draw_positions(actual_positions, previous_positions)
  #previous_positions = actual_positions
  previous_positions = []

  draw = Magick::Draw.new
  draw.fill('grey')
  draw.fill_opacity('50%')
  draw.rectangle(0.2 * visualization.map_size[:width], 0.9 * visualization.map_size[:height], 0.8 * visualization.map_size[:width], 0.9 * visualization.map_size[:height] + 30)
  draw.fill('black')
  draw.fill_opacity('100%')
  draw.text_align(Magick::CenterAlign)
  draw.pointsize(20)
  draw.text(0.5 * visualization.map_size[:width], 0.9 * visualization.map_size[:height] + 20, "Time: #{time}")
  draw.draw(image)

  list << image
end
list.delay = 1000 / (frames_per_second * 10)
list.animate

exit


list = Magick::ImageList.new
frames_per_second = 1
duration = 1
previous_positions = []
(duration * frames_per_second).to_int.times do |i|
  visualization = Visualization.new
  visualization.circle_radius = 1.0
  visualization.position_quantization_in_degrees = 0.0
#  actual_positions = logfile.positions
  #details = LogAnalyzer.new(Dir.glob(ARGV)).analyze 
  #p details
  #actual_positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }
  coords, ips = LogAnalyzer.new(Dir.glob(ARGV)).load_coordinates_from_file
  actual_positions = coords.values.select{ |coords| coords.any? }
p actual_positions.size
  image = visualization.draw_positions(actual_positions, previous_positions)
  previous_positions = actual_positions

  draw = Magick::Draw.new
  draw.fill('grey')
  draw.fill_opacity('50%')
  draw.rectangle(0.2 * visualization.map_size[:width], 0.9 * visualization.map_size[:height], 0.8 * visualization.map_size[:width], 0.9 * visualization.map_size[:height] + 30)
  draw.fill('black')
  draw.fill_opacity('100%')
  draw.text_align(Magick::CenterAlign)
  draw.pointsize(20)
  draw.text(0.5 * visualization.map_size[:width], 0.9 * visualization.map_size[:height] + 20, "Frame #{i+1}")
  draw.draw(image)

  list << image
end
list.delay = 1000 / (frames_per_second * 10)
list.animate

