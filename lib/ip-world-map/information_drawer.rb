require 'RMagick'

# Draws the timestamp.
class InformationDrawer

  def initialize
    @draw = Magick::Draw.new
  end

  def draw_info image, visualization, info
    size = { :width => visualization.map_size[:width], :height => visualization.map_size[:height] }
    draw_background(size)
    draw_message(size, info)
    @draw.draw(image)
  end

  protected

  def draw_background size
    width, height = size[:width], size[:height]
    @draw.fill('grey')
    @draw.fill_opacity('50%')
    @draw.rectangle(0.2 * width, 0.9 * height, 0.8 * width, 0.9 * height + 30)
  end

  def draw_message size, info
    @draw.fill('black')
    @draw.fill_opacity('100%')
    @draw.text_align(Magick::CenterAlign)
    @draw.pointsize(20)
    @draw.text(0.5 * size[:width], 0.9 * size[:height] + 20, info)
  end
end

