require 'spec_helper'

describe EelClient do
  describe EelClient::Mt do
    describe "#deliver" do
      before do
        EelClient.host = "mcagg-staging.net"
        EelClient.username = "jack"
        EelClient.password = "password"
      end

      it "should really send a message" do
        message = EelClient::Mt.new(
          :client_message_id => 1234,
          :source => 12345,
          :destination => 18005882300,
          :carrier_id => 'Att',
          :content => "this is some content"
        )
        begin
          puts message.send_sms_message
        rescue Exception => e
          puts "Response was: #{e.message}"
          puts e.backtrace.join("\n")
        end
      end
    end
  end
end
