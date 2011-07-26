require 'spec_helper'

describe ApacheLogVisualizer do
  describe 'time format' do
    it 'should return a minute based time format for times within an hour' do
      now = Time.now
      times = [now, now + 3599]

      ApacheLogVisualizer.detect_time_format(times).should == '%b %d %Y %H:%M'
    end

    it 'should return a hour based time format for times within a day' do
      now = Time.now
      times = [now, now + 86399]

      ApacheLogVisualizer.detect_time_format(times).should == '%b %d %Y %H:00'
    end

    it 'should return a day based time format for times greater than a day' do
      now = Time.now
      times = [now, now + 86400]

      ApacheLogVisualizer.detect_time_format(times).should == '%b %d %Y'
    end
  end
end

