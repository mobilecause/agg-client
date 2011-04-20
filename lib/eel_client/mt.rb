module EelClient
  class Mt
    #############
    # Constants #
    #############
    class Error < StandardError; end
    class InvalidMtError < EelClient::Mt::Error; end
    class SendSmsMtError < EelClient::Mt::Error; end
    VALID_CARRIER_IDS = %w(Att Tmobile Verizon Sprint Nextel Alltel Metropcs Rural Uscellular Westcentral Ntelos Bluegrass Centennial Cincinnatibell Cellularsouth Boost Cricket Immix Cellcom Virgin Cellularoneillinois Gcialaska Unknown)



    ############################
    # Other Class Declarations #
    ############################
    attr_accessor :aggregator_message_id
    attr_accessor :client_message_id, :source, :destination, :content, :carrier_id
    attr_reader :errors



    ####################
    # Instance Methods #
    ####################
    def initialize(attrs = {})
      unless attrs.keys.include?(:client_message_id)
        attrs[:client_message_id] = Time.now.to_i + rand
      end

      if attrs.keys.include?(:carrier_id) && !VALID_CARRIER_IDS.include?(attrs[:carrier_id])
        raise ArgumentError, "Carrier ID #{attrs[:carrier_id].inspect} is not one of #{VALID_CARRIER_IDS.join(', ')}"
      end

      attrs.each do |key, value|
        raise ArgumentError, "Attributes must be specified with Symbols" unless key.is_a?(Symbol)
        send "#{key}=", value
      end
      @errors = {}
    end

    def valid?
      @errors = {}
      validate
      errors.length == 0
    end

    def path
      '/sms_messages'
    end

    def send_sms_message!
      raise InvalidMtError, "Cannot send an invalid message. Try checking #errors or #valid?" unless valid?

      if send_sms_message
        return true
      else
        raise SendSmsMtError, "Sms message failed to send."
      end
    end

    def send_sms_message
      return false unless valid?

      response = post(path, xml)

      case response
      when Net::HTTPBadRequest
        # TODO: Make this use Nokogiri
        doc = REXML::Document.new(response.body)
        root = doc.root
        self.aggregator_message_id = root.elements["aggregatorMessageId"].text
        exception = EelClient::InvalidResource.new
        errors = {}
        root.elements["errors"].each do |element|
          next unless element.kind_of?(REXML::Element)
          errors[element.elements["code"].text] = element.elements["message"].text
        end
        exception.errors = errors
        exception.response = response
        raise exception
      when Net::HTTPCreated
        doc = REXML::Document.new(response.body)
        root = doc.root
        self.aggregator_message_id = root.elements["aggregatorMessageId"].text
        true
      when Net::HTTPSuccess
        raise UnexpectedResponse.new("Unexpected Response Code", response)
      else
        response.error!
      end
    end



    #########
    private #
    #########

    def validate
      fields.each do |field|
        if send(field).to_s.strip == ""
          errors[field.to_sym] = ["cannot be blank"]
        end
      end
    end

    def fields
      %w(client_message_id source destination carrier_id content)
    end

    def xml_template
      <<-XML
       <?xml version="1.0" encoding="UTF-8"?>
       <mobileTerminatedSmsMessage>
         <clientMessageId>:client_message_id</clientMessageId>
         <source>:source</source>
         <destination>:destination</destination>
         <carrierId>:carrier_id</carrierId>
         <content>:content</content>
       </mobileTerminatedSmsMessage>
      XML
    end

    def xml
      body = xml_template
      fields.each { |field| body = body.gsub(":#{field}", CGI.escapeHTML(send(field).to_s)) }
      body.strip
    end

    def post(path, body)
      uri = URI.parse("https://#{EelClient.host}#{path}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'certs'))

      req = Net::HTTP::Post.new(uri.path, {"Content-Type" => "application/mobile_terminated_sms_message_v1+xml"})
      req.basic_auth EelClient.username, EelClient.password
      req.body = body

      http.request(req)
    end

  end
end
