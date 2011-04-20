require 'spec_helper'

describe EelClient::Mo do
  describe ".from_xml" do
    subject { EelClient::Mo.from_xml(@xml) }
    values = {
      :aggregator_message_id => '19nzlu15q652u8p9wh6ajbpnjv7zdwg37yp5',
      :source => '12223334444',
      :destination => '11200',
      :carrier_id => 'Att',
      :content => 'FRED'
    }
    before do
      @xml = <<-EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <mobileOriginatedSmsMessage>
          <aggregatorMessageId>#{values[:aggregator_message_id]}</aggregatorMessageId>
          <source>#{values[:source]}</source>
          <destination>#{values[:destination]}</destination>
          <carrierId>#{values[:carrier_id]}</carrierId>
          <content>#{values[:content]}</content>
        </mobileOriginatedSmsMessage>
      EOF
    end
    values.each do |attr, val|
      it "should set '#{attr}' to '#{val}'" do
        subject.send(attr).should == val
      end
    end
  end



  describe ".new" do
    subject { EelClient::Mo.new(@values) }
    values = {
      :aggregator_message_id => '19nzlu15q652u8p9wh6ajbpnjv7zdwg37yp5',
      :source => '12223334444',
      :destination => '11200',
      :carrier_id => 'Att',
      :content => 'FRED'
    }
    before { @values = values }
    values.each do |attr, val|
      it "should set '#{attr}' to '#{val}'" do
        subject.send(attr).should == val
      end
      it "should freeze '#{attr}'" do
        lambda do
          subject.send(attr).upcase!
        end.should raise_error(RuntimeError, "can't modify frozen string")
      end
    end
  end

  describe "#attributes" do
    it "should return a hash of the attributes" do
      values = {
        :aggregator_message_id => '19nzlu15q652u8p9wh6ajbpnjv7zdwg37yp5',
        :source => '12223334444',
        :destination => '11200',
        :carrier_id => 'Att',
        :content => 'FRED'
      }

      mo = EelClient::Mo.new(values)
      mo.attributes.should == values
    end
  end
end
