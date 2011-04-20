module EelClient
  class Mo
    #############
    # Constants #
    #############
    VALID_ATTR = [:aggregator_message_id, :source, :destination, :content, :carrier_id]



    ############################
    # Other Class Declarations #
    ############################
    attr_reader *VALID_ATTR



    #################
    # Class Methods #
    #################
    class << self
      def from_xml(xml)
        doc = Nokogiri.XML(xml)
        attrs = {}
        VALID_ATTR.each do |attr|
          # Convert our attribute names to the names in the XML.
          xml_attr = attr.to_s.gsub(/_[a-z]/, &:upcase).gsub('_', '')
          attrs[attr] = doc.xpath("//mobileOriginatedSmsMessage/#{xml_attr}").first.text
        end

        new(attrs)
      end
    end



    ####################
    # Instance Methods #
    ####################
    def initialize(attrs)
      attrs.each do |key, value|
        raise ArgumentError, "Attributes must be one of #{VALID_ATTR.map(&:to_s).join(',')}" if VALID_ATTR.include?(key.to_s)
        raise ArgumentError, "Attributes must be specified with Symbols" unless key.is_a?(Symbol)
        instance_variable_set "@#{key}", value.freeze
      end
    end

    # Returns a Hash of all the attributes
    def attributes
      VALID_ATTR.inject({}) do |h, attr|
        h[attr] = self.send(attr)
        h
      end
    end
  end
end
