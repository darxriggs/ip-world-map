#!/usr/bin/env ruby

require 'rubygems'
require 'RMagick'

# show an image
#im = Magick::ImageList.new("htc.jpg")
#im.display

# draw a half-transparent red circle
im = Magick::ImageList.new("htc.jpg")
draw = Magick::Draw.new
draw.fill('red')
draw.fill_opacity('50%')
draw.circle(200, 200, 50, 200)
draw.draw(im)
im.display

# generate an animated image out of 2 images
#im = Magick::ImageList.new("htc.jpg", "htc2.jpg")
#im.write("animation.gif")

