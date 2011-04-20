module EelClient
  class PremiumMt < Mt

    attr_accessor :product_code, :initial_opt_in_receipt_message_id, :secondary_opt_in_receipt_message_id, :description

    private

    def validate
      super
      %w(product_code description).each do |field|
        if send(field).to_s.strip == ""
          errors[field.to_sym] = ["cannot be blank"]
        end
      end

      %w(initial_opt_in_receipt_message_id secondary_opt_in_receipt_message_id).each do |field|
        unless send(field).to_s.strip.length == 36
          errors[field.to_sym] = ["must be a 36 character UUID"]
        end
      end
    end

    def fields
      super + %w(product_code initial_opt_in_receipt_message_id secondary_opt_in_receipt_message_id description)
    end

    def path
      '/premium_sms_messages'
    end

    def xml_template
      <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <mobileTerminatedPremiumSmsMessage>
          <clientMessageId>:client_message_id</clientMessageId>
          <source>:source</source>
          <destination>:destination</destination>
          <carrierId>:carrier_id</carrierId>
          <content>:content</content>
          <productCode>:product_code</productCode>
          <description>:description</description>
          <initialOptInReceipt>
            <smsDetails>
              <messageId>:initial_opt_in_receipt_message_id</messageId>
            </smsDetails>
          </initialOptInReceipt>
          <secondaryOptInReceipt>
            <smsDetails>
              <messageId>:secondary_opt_in_receipt_message_id</messageId>
            </smsDetails>
          </secondaryOptInReceipt>
          <deliveryTimeStamp>#{Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")}</deliveryTimeStamp>
        </mobileTerminatedPremiumSmsMessage>
      XML
    end

  end
end
