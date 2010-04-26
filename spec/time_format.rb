require File.dirname(__FILE__) + '/spec_helper.rb'

describe TimeFormat do
  it 'should return a minute based time format for times within an hour' do
    now = Time.now
    times = [now, now + 123456789, now + 1]
  end

  it 'should return a hour based time format for times within a day' do
    now = Time.now
    times = [now, now + 123456789, now + 1]
  end

  it 'should return a day based time format for times greater than a day' do
    now = Time.now
    times = [now, now + 123456789, now + 1]
  end
end

