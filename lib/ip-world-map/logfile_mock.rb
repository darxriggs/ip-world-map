class LogfileMock
  attr_accessor :min_random_positions, :max_random_positions

  def initialize
    @min_random_positions = 5
    @max_random_positions = 50
  end

  def random_longitude_latitude
    [ -10 + rand(25) + rand, 40 + rand(15) + rand ]
  end

  def positions
    amount = @min_random_positions + rand(@max_random_positions - @min_random_positions + 1)
    Array.new(amount){ random_longitude_latitude }
  end
end

