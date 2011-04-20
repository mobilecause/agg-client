module EelClient
  module TestSupport
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
        <<-XML.strip
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <mobileTerminatedResponse>
            <aggregatorMessageId>56a6c636-8a56-4015-a39c-5fd48e3da00a</aggregatorMessageId>
            <errors/>
          </mobileTerminatedResponse>
        XML
      end

      def failure_xml
        <<-XML.strip
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <mobileTerminatedResponse>
            <aggregatorMessageId>52c52d57-4cc7-4df6-b2e8-ce2fd4080e74</aggregatorMessageId>
            <errors>
              <error>
                <code>001</code>
                <message>Invalid Resource</message>
              </error>
              <error>
                <code>002</code>
                <message>unexpected element (uri:&quot;&quot;, local:&quot;mobileTerminatedPremiumSmsMessage&quot;). Expected elements are &lt;{}mobileTerminatedSmsMessage&gt;</message>
              </error>
            </errors>
          </mobileTerminatedResponse>
        XML
      end
    end
  end
end