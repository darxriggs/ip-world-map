require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe IpLookupService do
  describe 'IP check' do
    it 'should check if a given string is an IP' do
      IpLookupService.is_ip?('1.1.1.1').should be true
      IpLookupService.is_ip?('1.1.1.1234').should be false
      IpLookupService.is_ip?('no IP').should be false
    end
  end

  describe 'hostname -> IP resolval' do
    it 'should return the IP for an existing hostname' do
      stubbed_result = [['AF_INET', 0, 'domain.net', '1.1.1.1', 2, 1, 6],
                        ['AF_INET', 0, 'domain.net', '2.2.2.2', 2, 2, 0]]
      Socket.stub!(:getaddrinfo).and_return(stubbed_result)

      IpLookupService.ip_for_host('existing hostname').should match /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}$/
    end

    it 'should return the IP if an IP is given as hostname' do
      IpLookupService.ip_for_host('1.1.1.1').should == '1.1.1.1'
    end

    it 'should handle the case that no IP can be resolved for a hostname' do
      Socket.stub!(:getaddrinfo).and_raise(SocketError)

      IpLookupService.ip_for_host('non-existing hostname').should be nil
    end
  end

  describe 'hostname -> coordinates resolval' do
    it 'should return the coordinates for an IP' do
      stubbed_result = "Country: GERMANY (DE)\nCity: Berlin\n\nLatitude: 52.5\nLongitude: 13.4167\nIP: 1.1.1.1\n"
      Net::HTTP.stub!(:get).and_return(stubbed_result)
      Socket.stub!(:getaddrinfo)
   
      IpLookupService.new.coordinates_for_host('some hostname').should == [13.4167, 52.5]
    end
   
    it 'should handle the case that no coordinates can be resolved for an IP' do
      stubbed_result = "Country: GERMANY (DE)\nCity: Berlin\n\nLatitude: \nLongitude: \nIP: 1.1.1.1\n"
      Net::HTTP.stub!(:get).and_return(stubbed_result)
      Socket.stub!(:getaddrinfo)
   
      IpLookupService.new.coordinates_for_host('some hostname').should == [nil, nil]
    end
  end
end

