require 'spec_helper'

describe EelClient::PremiumMt do

  def new_message(options = {})
    valid_options = {:client_message_id => 1234,
                     :source => 12345,
                     :destination => 15555551212,
                     :carrier_id => "Att",
                     :description => "some description",
                     :content => "some content",
                     :product_code => "pc01",
                     :initial_opt_in_receipt_message_id => "5952b978-41eb-41e4-9cb5-f3ee73bef94f",
                     :secondary_opt_in_receipt_message_id => "5952b978-41eb-41e4-9cb5-f3dd73bef94f"}
    EelClient::PremiumMt.new(valid_options.merge(options))
  end

  describe "#valid?" do

    it "should return true when the message has all fields and they are all valid" do
      new_message.should be_valid
    end

    it "should return false when valid? is called on a PremiumMt that has no client_message_id" do
      new_message(:client_message_id => nil).should_not be_valid
    end

    it "should return false when valid? is called on a PremiumMt that has no source" do
      new_message(:source => nil).should_not be_valid
    end

    it "should return false when valid? is called on a PremiumMt that has no destination" do
      new_message(:destination => nil).should_not be_valid
    end

    it "should return false when valid? is called on a PremiumMt that has no description" do
      new_message(:description => nil).should_not be_valid
    end

    it "should return false when valid? is called on a PremiumMt that has no content" do
      new_message(:content => nil).should_not be_valid
    end

    it "should return false when valid? is called on a PremiumMt that has no product code" do
      message = new_message(:product_code => nil)
      message.should_not be_valid
      message.errors[:product_code].should == ["cannot be blank"]
    end

    it "should return false when valid? is called on a PremiumMt that has an initial_opt_in_receipt_message_id that is not 36 characters" do
      message = new_message(:initial_opt_in_receipt_message_id => "foobar")
      message.should_not be_valid
      message.errors.should == {:initial_opt_in_receipt_message_id => ["must be a 36 character UUID"]}
    end

    it "should return false when valid? is called on a PremiumMt that has no secondary_opt_in_receipt_message_id that is not 36 characters" do
      message = new_message(:secondary_opt_in_receipt_message_id => "foobar")
      message.should_not be_valid
      message.errors.should == {:secondary_opt_in_receipt_message_id => ["must be a 36 character UUID"]}
    end
  end

  describe "#send_sms_message" do

    before do
      @fake_aggregator = EelClient::TestSupport::FakeAggregator.new
    end

    def send_sms_message_message(params = {})
      Artifice.activate_with(@fake_aggregator) do
        message = new_message(params)
        message.stub(:valid? => true)
        message.send_sms_message
      end
    end

    it "should return false if the message is invalid" do
      message = EelClient::PremiumMt.new
      message.stub(:valid? => false)
      message.send_sms_message.should be_false
    end

    it "should return true if the message is valid" do
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::PremiumMt.new
        message.stub(:valid? => true)
        message.send_sms_message.should == true
        message.aggregator_message_id.should == "56a6c636-8a56-4015-a39c-5fd48e3da00a"
      end
    end

    it "should use the configured host" do
      EelClient.host = "somehost.com"
      send_sms_message_message
      @fake_aggregator.request['SERVER_NAME'].should == 'somehost.com'
    end

    it "should pass the correct basic auth" do
      EelClient.username = "tom"
      EelClient.password = "ground control"
      send_sms_message_message
      credentials = @fake_aggregator.request["HTTP_AUTHORIZATION"]
      username, password = Base64.decode64(credentials.split(' ').last).split(":")
      username.should == "tom"
      password.should == "ground control"
    end

    it "should use HTTPS" do
      send_sms_message_message
      @fake_aggregator.request['rack.url_scheme'].should == 'https'
    end

    it "should post with the correct Content-Type header" do
      send_sms_message_message
      @fake_aggregator.request['CONTENT_TYPE'].should == 'application/mobile_terminated_sms_message_v1+xml'
    end

    it "should post to the correct path" do
      send_sms_message_message
      @fake_aggregator.request['REQUEST_METHOD'].should == 'POST'
      @fake_aggregator.request['PATH_INFO'].should == '/premium_sms_messages'
    end

    it "strips whitespace from the beginning and end of the xml document" do
      send_sms_message_message :client_message_id => 1234,
                               :source => 12345,
                               :destination => 15555551212,
                               :content => "some content"
      xml_document = @fake_aggregator.request['rack.input'].read
      stripped_doc = xml_document.strip
      stripped_doc.should == xml_document
    end

    it "should not choke on xml entities in the message texts" do
      send_sms_message_message :client_message_id => "12<34",
                               :source => "2891><1070",
                               :destination => "131228/>29272",
                               :content => "hi je>>ff"
      posted_xml = @fake_aggregator.request['rack.input'].read

      posted_xml.should match("12&lt;34")
      posted_xml.should match("2891&gt;&lt;1070")
      posted_xml.should match("131228/&gt;29272")
      posted_xml.should match("hi je&gt;&gt;ff")
    end

    it "should blow up when the response is 400" do
      @fake_aggregator.response_type = :invalid_resource
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::PremiumMt.new
        message.stub(:valid? => true)
        proc do
          message.send_sms_message
        end.should raise_error(EelClient::InvalidResource)
      end
    end

    it "should add the parsed error message and code when the response is 400" do
      @fake_aggregator.response_type = :invalid_resource
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::PremiumMt.new
        message.stub(:valid? => true)
        begin
          message.send_sms_message
        rescue Exception => e
          e.errors.should == {
            "001" => "Invalid Resource",
            "002" => 'unexpected element (uri:"", local:"mobileTerminatedPremiumSmsMessage"). Expected elements are <{}mobileTerminatedSmsMessage>'
          }
          e.response.should be_kind_of(Net::HTTPResponse)
        end
      end
    end

    it "should blow up when the response is 500" do
      @fake_aggregator.response_type = :error
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::PremiumMt.new
        message.stub(:valid? => true)
        proc do
          message.send_sms_message
        end.should raise_error(Net::HTTPFatalError)
      end
    end

    it "should raise EelClient::UnexpectedResponse when the response is 200 range but is not a 201" do
      @fake_aggregator.response_type = :two_hundred
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::PremiumMt.new
        message.stub(:valid? => true)
        proc do
          message.send_sms_message
        end.should raise_error(EelClient::UnexpectedResponse)
      end
    end

    it "should add the response, but not the message / code when the response is 500" do
      @fake_aggregator.response_type = :error
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::PremiumMt.new
        message.stub(:valid? => true)
        begin
          message.send_sms_message
        rescue Exception => e
          e.response.should be_kind_of(Net::HTTPResponse)
        end
      end
    end

    it "should post the correct xml" do
      Time.stub_chain(:now, :utc).and_return(Time.parse("2011-02-01 12:12:12"))
      send_sms_message_message :client_message_id => 1234,
                               :source => 12345,
                               :destination => 15555551212,
                               :carrier_id => 'Att',
                               :description => "some description",
                               :content => "some content",
                               :product_code => "pc01",
                               :initial_opt_in_receipt_message_id => "5952b978-41eb-41e4-9cb5-f3ee73bef94f",
                               :secondary_opt_in_receipt_message_id => "5952b978-41eb-41e4-9cb5-f3ee73bef94f"
      posted_xml = Nokogiri::XML(@fake_aggregator.request['rack.input'].read)
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/clientMessageId").inner_text.should == "1234"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/source").inner_text.should == "12345"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/destination").inner_text.should == "15555551212"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/carrierId").inner_text.should == "Att"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/description").inner_text.should == "some description"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/content").inner_text.should == "some content"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/productCode").inner_text.should == "pc01"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/deliveryTimeStamp").inner_text.should == "2011-02-01T12:12:12Z"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/initialOptInReceipt/smsDetails/messageId").inner_text.should == "5952b978-41eb-41e4-9cb5-f3ee73bef94f"
      posted_xml.xpath("/mobileTerminatedPremiumSmsMessage/secondaryOptInReceipt/smsDetails/messageId").inner_text.should == "5952b978-41eb-41e4-9cb5-f3ee73bef94f"
    end
  end
end
