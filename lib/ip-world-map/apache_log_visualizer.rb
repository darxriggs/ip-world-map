#coordinates_home = [11.6220338, 48.1276458] # Munich
#coordinates_home = [13.4114943, 52.5234802] # Berlin
#coordinates_home = [12.3387844, 45.4343363] # Venezia

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
    smallest_period = some_samples.each_cons(2).collect{ |time1, time2| (time1 - time2).abs }.min || 1

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

def access_image(log_files)
    analyzer = ApacheLogAnalyzer.new(log_files)
    analyzer.load_cached_coordinates_from_file
    details = analyzer.analyze
    positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }

    visualization = Visualization.new
    visualization.draw_positions(positions).display
end

def access_animation(log_files)
    analyzer = ApacheLogAnalyzer.new(log_files)
    analyzer.load_cached_coordinates_from_file
    details = analyzer.analyze
    grouped_details = analyzer.group_by_time(details, $visualization_config.group_seconds)

    animation = Magick::ImageList.new
    visualization = Visualization.new
    time_format = $visualization_config.time_format || detect_time_format(grouped_details.keys)

    grouped_details.sort.each do |time, details|
        visualization.new_frame
        positions = details.collect{ |data| data[:coordinates] }.select{ |coords| coords.any? }
        p [time, details.size, positions.size]
        image = visualization.draw_positions(positions)

        draw_info(image, visualization, time.strftime(time_format))
        animation << image
    end

    animation.delay = 1000 / ($visualization_config.frames_per_second * 10)
#    animation.each_with_index{ |img, idx| p img; img.write("tng.#{'%03i' % idx}.jpg") }
#    animation.write 'tng.gif'
    animation.animate
end

def visualize(log_files)
    if $visualization_config.video_format
      access_animation(log_files)
    elsif $visualization_config.image_format
      access_image(log_files)
    else 
      show_some_random_points
    end
end

