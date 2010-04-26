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

