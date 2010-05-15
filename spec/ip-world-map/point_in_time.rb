require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe PointInTime do
  it 'should convert currencies properly' do
    Currency::convert('AUD', 'USD').should > 0
  end

  it 'raise an exception on incorrect currencies' do
    lambda { Currency::convert('YYY', 'XXX') }.should raise_error(Currency::RateError)
  end

  it 'should process amounts properly' do
    amount = 10
    result_with_amount    = Currency::convert('AUD', 'USD', amount)
    result_without_amount = Currency::convert('AUD', 'USD')

    result_with_amount.should == amount * result_without_amount
  end
end

