#!/usr/bin/env ruby

require 'rubygems'
require 'ostruct'
require 'RMagick'
require File.dirname(__FILE__) + "/apache_log_analyzer.rb"

#coordinates_home = [11.6220338, 48.1276458] # Munich
#coordinates_home = [13.4114943, 52.5234802] # Berlin
#coordinates_home = [12.3387844, 45.4343363] # Venezia

$visualization_config = OpenStruct.new({
    :map_filename       => File.dirname(__FILE__) + "/../maps/earthmap-1920x960.tif",
    :map_width          => 800,
    :map_height         => 400,
    :group_seconds      => 24 * 1 * 60 * 60,
    :frames_per_second  => 24,
    :fill_dot_color     => 'red',
    :fill_dot_scale     => 10,
    :fill_dot_opacity   => 1.0,
    :fill_dot_lifetime  => 15,
    :time_format        => nil,
})

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

  def initialize
    @map_filename = $visualization_config.map_filename
    @raw_image = Magick::ImageList.new(@map_filename).first
    if $visualization_config.map_width || $visualization_config.map_height
        width  = $visualization_config.map_width  || @raw_image.columns
        height = $visualization_config.map_height || @raw_image.rows
        @raw_image.resize! width, height
    end
    new_frame
    @position_quantization_in_degrees = 10.0
    @opacity_visibility_threshold = 0.1
    @circle_radius = (map_size[:width] ** 1.25) / (map_size[:width] * $visualization_config.fill_dot_scale).to_f
    @points = []
  end

  def map_size
    @map_size ||= { :width => @frame.columns, :height => @frame.rows }
  end

  def scale
    @scale ||= { :x => 360.0 / map_size[:width], :y => 180.0 / map_size[:height] }
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

  def select_visible_points points
    points.select{ |point| point.opacity >= @opacity_visibility_threshold }
  end

  def draw_positions positions_lon_lat
    @draw.fill($visualization_config.fill_dot_color)

    new_points = positions_lon_lat.collect do |longitude, latitude|
      x, y = x_y_from_longitude_latitude(longitude, latitude)
      PointInTime.new(x, y, $visualization_config.fill_dot_opacity, $visualization_config.fill_dot_lifetime)
    end

    @points = @points.concat(new_points)
    @points = select_visible_points(@points)
#    positions = quantize_positions(@positions)
    points = @points

    points.each do |point|
      @draw.fill_opacity(point.opacity)
      @draw.circle(*circle_parameters(point.x, point.y))
      point.age
    end

    @draw.draw(@frame)

    @frame
  end

  def display
    @frame.display
  end

  def new_frame
    @draw = Magick::Draw.new
    @frame = @raw_image.clone
  end
end

###############################################################################

# see http://en.wikipedia.org/wiki/Exponential_decay
class Decay
  def initialize initial_value, lifetime
    @initial_value = initial_value.to_f
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

  def opacity_in_time time
    @time = time if time
    @decay.value(@time)
  end

  def opacity
    @decay.value(@time)
  end

  def age
    @time += 1
  end
end

###############################################################################

#decay = Decay.new(10, 5)
#p (0..20).collect{ |t| decay.value(t) }
#exit

#decay = Decay.new(10, 5)
#point = PointInTime.new(0,0, 10,5)
#p (0..20).collect{ |t| point.opacity }
#exit

def draw_info_background draw, size
    width, height = size[:width], size[:height]
    draw.fill('grey')
    draw.fill_opacity('50%')
    draw.rectangle(0.2 * width, 0.9 * height, 0.8 * width, 0.9 * height + 30)
end

def draw_info_message draw, size, info
    draw.fill('black')
    draw.fill_opacity('100%')
    draw.text_align(Magick::CenterAlign)
    draw.pointsize(20)
    draw.text(0.5 * size[:width], 0.9 * size[:height] + 20, info)
end

def draw_info image, visualization, info
    draw = Magick::Draw.new
    size = { :width => visualization.map_size[:width], :height => visualization.map_size[:height] }
    draw_info_background(draw, size)
    draw_info_message(draw, size, info)
    draw.draw(image)
end

def detect_time_format times
    some_samples = times.sort[0..99]
    smallest_period = some_samples.each_cons(2).collect{ |time1, time2| (time1 - time2).abs }.min

    return '%b %d %Y %H:%M' if smallest_period <  3600 # scale: minutes
    return '%b %d %Y %H:00' if smallest_period < 86400 # scale: hours
    return '%b %d %Y'                                  # scale: days
end

def show_some_random_points
    logfile = LogfileMock.new
    visualization = Visualization.new
    visualization.position_quantization_in_degrees = 5.0
    visualization.draw_positions(logfile.positions)
    visualization.display
end

def access_image
    analyzer = ApacheLogAnalyzer.new(Dir.glob(ARGV))
    analyzer.load_cached_coordinates_from_file
    details = analyzer.analyze
    positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }

    visualization = Visualization.new
    visualization.draw_positions(positions).display
end

def access_animation
    analyzer = ApacheLogAnalyzer.new(Dir.glob(ARGV))
    analyzer.load_cached_coordinates_from_file
    details = analyzer.analyze
    grouped_details = analyzer.group_by_time(details, $visualization_config.group_seconds)

    animation = Magick::ImageList.new
    visualization = Visualization.new
    time_format = $visualization_config.time_format || detect_time_format(grouped_details.keys)

    grouped_details.sort().each do |time, details|
        visualization.new_frame
        positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }
        p [time, details.size, positions.size]
        image = visualization.draw_positions(positions)

        draw_info(image, visualization, time.strftime(time_format))
        animation << image
    end

    animation.delay = 1000 / ($visualization_config.frames_per_second * 10)
#    animation.each_with_index{ |img, idx| p img; img.write("tng.#{'%03i' % idx}.jpg") }
#    animation.write "tng.gif"
    animation.animate
end

#show_some_random_points
#access_image
access_animation

