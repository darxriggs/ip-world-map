#coordinates_home = [11.6220338, 48.1276458] # Munich
#coordinates_home = [13.4114943, 52.5234802] # Berlin
#coordinates_home = [12.3387844, 45.4343363] # Venezia

def detect_time_format times
  some_samples = times.sort[0..99]
  smallest_period = some_samples.each_cons(2).collect{ |time1, time2| (time1 - time2).abs }.min || 1

  return '%b %d %Y %H:%M' if smallest_period <  3600 # scale: minutes
  return '%b %d %Y %H:00' if smallest_period < 86400 # scale: hours
  return '%b %d %Y'                                  # scale: days
end

def access_image(log_files)
  analyzer = ApacheLogAnalyzer.new(log_files)
  analyzer.load_cached_coordinates_from_file
  details = analyzer.analyze
  positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }

  visualization = Visualization.new
  image = visualization.draw_positions(positions)
  save_image image
end

def access_animation(log_files)
  analyzer = ApacheLogAnalyzer.new(log_files)
  analyzer.load_cached_coordinates_from_file
  details = analyzer.analyze
  grouped_details = analyzer.group_by_time(details, $visualization_config.group_seconds)

  animation = Magick::ImageList.new
  visualization = Visualization.new
  time_format = $visualization_config.time_format || detect_time_format(grouped_details.keys)
  frame_number = 0

  grouped_details.sort.each do |time, details|
    frame_number += 1
    visualization.new_frame
    positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }
    p [time, details.size, positions.size]
    image = visualization.draw_positions(positions)

    InformationDrawer.new.draw_info(image, visualization, time.strftime(time_format))
    save_image image, frame_number
  end

  create_animation
end

def save_image(image, frame_number = 0)
  if $visualization_config.animate
    image.write "animation.#{'%09d' % frame_number}.bmp"
  else
    image.write "snapshot.#{$visualization_config.output_format}"
  end
end
  
def create_animation
  success = system "ffmpeg -r #{$visualization_config.frames_per_second} -qscale 1 -y -i animation.%09d.bmp animation.#{$visualization_config.output_format}"
  raise 'could not create the animation' unless success
end

def visualize(log_files)
  if $visualization_config.animate
    access_animation(log_files)
  else
    access_image(log_files)
  end
end

