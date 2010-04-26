require File.dirname(__FILE__) + '/spec_helper.rb'

describe PointInTime do
  it 'should be initialized with either Integers and/or Floats' do
    Decay.new(10,   5  )
    Decay.new(10,   5.0)
    Decay.new(10.0, 5  )
    Decay.new(10.0, 5.0)
  end

  it 'should return a value depending on the time' do
    decay = Decay.new(10, 5)

    decay.value(0).should be 10
    decay.value(2).should be 0 # todo
  end
end

