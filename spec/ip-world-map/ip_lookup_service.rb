require 'spec_helper'

describe IpLookupService do
  describe 'hostname -> coordinates resolval' do
    it 'should return the coordinates for an IP' do
      stubbed_result = "Country: GERMANY (DE)\nCity: Berlin\n\nLatitude: 52.5\nLongitude: 13.4167\nIP: 1.1.1.1\n"
      Net::HTTP.stub!(:get).and_return(stubbed_result)

      IpLookupService.new.coordinates_for_host('1.1.1.1').should == [13.4167, 52.5]
    end

    it 'should return the coordinates for a hostname' do
      stubbed_result = "Country: GERMANY (DE)\nCity: Berlin\n\nLatitude: 52.5\nLongitude: 13.4167\nIP: 1.1.1.1\n"
      Net::HTTP.stub!(:get).and_return(stubbed_result)
      IPSocket.stub!(:getaddr).and_return('1.1.1.1')

      IpLookupService.new.coordinates_for_host('some hostname').should == [13.4167, 52.5]
    end

    it 'should handle the case that no IP can be resolved for a hostname' do
      stubbed_result = "Country: GERMANY (DE)\nCity: Berlin\n\nLatitude: \nLongitude: \nIP: 1.1.1.1\n"
      Net::HTTP.stub!(:get).and_return(stubbed_result)
      IPSocket.stub!(:getaddrinfo).and_raise(SocketError)
   
      IpLookupService.new.coordinates_for_host('some hostname').should == [nil, nil]
    end
   
    it 'should handle the case that no coordinates can be resolved for a hostname' do
      stubbed_result = "Country: GERMANY (DE)\nCity: Berlin\n\nLatitude: \nLongitude: \nIP: 1.1.1.1\n"
      Net::HTTP.stub!(:get).and_return(stubbed_result)
      IPSocket.stub!(:getaddr)
   
      IpLookupService.new.coordinates_for_host('some hostname').should == [nil, nil]
    end
  end
end

