require 'spec_helper'

describe EelClient::Mt do

  def new_message(options = {})
    valid_options = {
      :client_message_id => 1234,
      :source => 12345,
      :destination => 15555551212,
      :carrier_id => "Att",
      :content => "some content"
    }
    EelClient::Mt.new(valid_options.merge(options))
  end

  describe ".new" do
    context "when the client_message_id key isn't provided" do
      it "should generate a client_message_id" do
        EelClient::Mt.new.client_message_id.should_not be_nil
      end

      it "should attempt to generate a unique client_message_id" do
        EelClient::Mt.new.client_message_id.should_not == EelClient::Mt.new.client_message_id
      end
    end

    context "when the client_message_id is nil" do
      it "should have a nil client_message_id" do
        EelClient::Mt.new(:client_message_id => nil).client_message_id.should be_nil
      end
    end

    context "when the client_message_id is 12345" do
      it "should have a client_message_id of 12345" do
        EelClient::Mt.new(:client_message_id => 12345).client_message_id.should == 12345
      end
    end

    it "should raise an error when a string is used as a key" do
      lambda { EelClient::Mt.new('content' => 'whatever') }.should raise_error(ArgumentError)
    end

    context "when carrier_id is present" do
      context "when the carrier_id is not one of #{EelClient::Mt::VALID_CARRIER_IDS.inspect}" do
        it "should raise an error" do
          lambda do
            EelClient::Mt.new(:carrier_id => 'whatever')
          end.should raise_error(ArgumentError, "Carrier ID \"whatever\" is not one of #{EelClient::Mt::VALID_CARRIER_IDS.join(', ')}")
        end
      end
    end
  end

  describe "#valid?" do
    it "should return true when the message was successful" do
      new_message.should be_valid
    end

    it "should return false when valid? is called on a Message that has no client_message_id" do
      new_message(:client_message_id => nil).should_not be_valid
    end

    it "should return false when valid? is called on a Message that has no source" do
      new_message(:source => nil).should_not be_valid
    end

    it "should return false when valid? is called on a Message that has no destination" do
      new_message(:destination => nil).should_not be_valid
    end

    it "should return false when valid? is called on a Message that has no content" do
      new_message(:content => nil).should_not be_valid
    end
  end

  describe "#send_sms_message!" do
    context "#valid? is false" do
      before { subject.stub(:valid? => false) }
      it "should raise an exception" do
        subject.stub(:send_sms_message => false)
        lambda {
          subject.send_sms_message!
        }.should raise_error(EelClient::Mt::InvalidMtError)
      end
    end
    context "#valid? is true" do
      before { subject.stub(:valid? => true) }

      it "should call #send_sms_message" do
        subject.should_receive(:send_sms_message).and_return(true)
        subject.send_sms_message!
      end
      it "should return true if #send_sms_message returns true" do
        subject.stub(:send_sms_message => true)
        subject.send_sms_message!.should be_true
      end
      it "should raise an exception if #send_sms_message returns false" do
        subject.stub(:send_sms_message => false)
        lambda {
          subject.send_sms_message!
        }.should raise_error(EelClient::Mt::SendSmsMtError)
      end
    end
  end
  describe "#send_sms_message" do

    before do
      class FakeAggregator

        attr_accessor :request, :response_type

        def call(env)
          self.request = env
          case response_type
            when :invalid_resource
              [400, {}, [failure_xml]]
            when :error
              [500, {}, ["kaboom"]]
            when :two_hundred
              [200, {}, ["kaboom"]]
            else
              [201, {}, [success_xml]]
          end
        end

        def success_xml
          <<-XML
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <mobileTerminatedResponse>
              <aggregatorMessageId>56a6c636-8a56-4015-a39c-5fd48e3da00a</aggregatorMessageId>
              <errors/>
            </mobileTerminatedResponse>
          XML
        end

        def failure_xml
          <<-XML
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <mobileTerminatedResponse>
              <aggregatorMessageId>43679d38-0d2f-46c3-a0bc-0469fed49996</aggregatorMessageId>
              <errors>
                <error>
                  <code>004</code>
                  <message>Invalid Resource</message>
                </error>
              </errors>
            </mobileTerminatedResponse>
          XML
        end
      end

      @fake_aggregator = FakeAggregator.new
    end

    after do
      Object.send(:remove_const, :FakeAggregator)
    end

    def send_sms_message_message(params = {})
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::Mt.new params
        message.stub(:valid? => true)
        message.send_sms_message
      end
    end

    it "should return false if the message is invalid" do
      message = EelClient::Mt.new
      message.stub(:valid? => false)
      message.send_sms_message.should be_false
    end

    it "should return true if the message is valid" do
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::Mt.new
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
      @fake_aggregator.request['PATH_INFO'].should == '/sms_messages'
    end

    it "should post the correct xml" do
      send_sms_message_message :client_message_id => 1234,
                               :source => 12345,
                               :destination => 15555551212,
                               :carrier_id => 'Att',
                               :content => "some content"
      posted_xml = Nokogiri::XML(@fake_aggregator.request['rack.input'].read)
      posted_xml.xpath("/mobileTerminatedSmsMessage/clientMessageId").inner_text.should == "1234"
      posted_xml.xpath("/mobileTerminatedSmsMessage/source").inner_text.should == "12345"
      posted_xml.xpath("/mobileTerminatedSmsMessage/destination").inner_text.should == "15555551212"
      posted_xml.xpath("/mobileTerminatedSmsMessage/carrierId").inner_text.should == "Att"
      posted_xml.xpath("/mobileTerminatedSmsMessage/content").inner_text.should == "some content"
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
        message = EelClient::Mt.new
        message.stub(:valid? => true)
        proc do
          message.send_sms_message
        end.should raise_error(EelClient::InvalidResource)
      end
    end

    it "should add the parsed error message and code when the response is 400" do
      @fake_aggregator.response_type = :invalid_resource
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::Mt.new
        message.stub(:valid? => true)
        begin
          message.send_sms_message
        rescue Exception => e
          e.errors.should == {"004" => "Invalid Resource"}
          e.response.should be_kind_of(Net::HTTPResponse)
        end
      end
    end

    it "should blow up when the response is 500" do
      @fake_aggregator.response_type = :error
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::Mt.new
        message.stub(:valid? => true)
        proc do
          message.send_sms_message
        end.should raise_error(Net::HTTPFatalError)
      end
    end

    it "should raise EelClient::UnexpectedResponse when the response is 200 range but is not a 201" do
      @fake_aggregator.response_type = :two_hundred
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::Mt.new
        message.stub(:valid? => true)
        proc do
          message.send_sms_message
        end.should raise_error(EelClient::UnexpectedResponse)
      end
    end

    it "should add the response, but not the message / code when the response is 500" do
      @fake_aggregator.response_type = :error
      Artifice.activate_with(@fake_aggregator) do
        message = EelClient::Mt.new
        message.stub(:valid? => true)
        begin
          message.send_sms_message
        rescue Exception => e
          e.response.should be_kind_of(Net::HTTPResponse)
        end
      end
    end

  end

end
