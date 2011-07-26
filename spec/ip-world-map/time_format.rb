require 'spec_helper'

describe 'TimeFormat' do
  it 'should return a minute based time format for times within an hour' do
    now = Time.now
    times = [now, now + 3599]

    detect_time_format(times).should == '%b %d %Y %H:%M'
  end

  it 'should return a hour based time format for times within a day' do
    now = Time.now
    times = [now, now + 86399]

    detect_time_format(times).should == '%b %d %Y %H:00'
  end

  it 'should return a day based time format for times greater than a day' do
    now = Time.now
    times = [now, now + 86400]

    detect_time_format(times).should == '%b %d %Y'
  end
end

