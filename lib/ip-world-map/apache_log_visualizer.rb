require 'RMagick'

class ApacheLogVisualizer
  def initialize log_files
    @log_files = log_files
  end

  def self.detect_time_format times
    some_samples = times.sort[0..99]
    smallest_period = some_samples.each_cons(2).collect{ |time1, time2| (time1 - time2).abs }.min || 1

    return '%b %d %Y %H:%M' if smallest_period <  3600 # scale: minutes
    return '%b %d %Y %H:00' if smallest_period < 86400 # scale: hours
    return '%b %d %Y'                                  # scale: days
  end

  def generate_image
    analyzer = ApacheLogAnalyzer.new(@log_files)
    details = analyzer.analyze
    positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }

    visualization = Visualization.new
    image = visualization.draw_positions(positions)
    save_image image
  end

  def generate_animation
    analyzer = ApacheLogAnalyzer.new(@log_files)
    details = analyzer.analyze
    grouped_details = analyzer.group_by_time(details, $visualization_config.group_seconds)

    animation = Magick::ImageList.new
    visualization = Visualization.new
    time_format = $visualization_config.time_format || ApacheLogVisualizer.detect_time_format(grouped_details.keys)
    frame_number = 0

    puts "\nGenerating frames:" if $visualization_config.verbose
    grouped_details.sort.each do |time, details|
      frame_number += 1
      visualization.new_frame
      positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }
      p [time, details.size, positions.size] if $visualization_config.verbose
      image = visualization.draw_positions(positions)

      InformationDrawer.new.draw_info(image, visualization, time.strftime(time_format))
      save_image image, frame_number
    end

    render_frames_as_video
  end

  def save_image image, frame_number = 0
    if $visualization_config.animate
      image.write "animation.#{'%09d' % frame_number}.bmp"
    else
      image.write "snapshot.#{$visualization_config.output_format}"
    end
  end

  def render_frames_as_video
    puts "\nGenerating video:" if $visualization_config.verbose
    output = `ffmpeg -r #{$visualization_config.frames_per_second} -qscale 1 -y -i animation.%09d.bmp animation.#{$visualization_config.output_format} 2>&1`
    puts output if $visualization_config.verbose
    raise 'could not create the animation' unless $?.exitstatus == 0
  end

  def visualize
    if $visualization_config.animate
      generate_animation
    else
      generate_image
    end
  end
end

