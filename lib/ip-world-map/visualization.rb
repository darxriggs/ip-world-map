require 'RMagick'

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

