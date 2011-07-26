class PointInTime
  attr_reader :x, :y

  def initialize x, y, initial_opacity, lifetime
    @x, @y = x, y
    @time = 0
    @decay = Decay.new(initial_opacity, lifetime)
  end

  def opacity_in_time time
    @time = time if time
    opacity
  end

  def opacity
    @decay.value(@time)
  end

  def age
    @time += 1
  end
end

