require 'cgi'
require 'net/http'
require 'net/https'
require 'rexml/document'

module EelClient

  class InvalidResource < StandardError
    attr_accessor :errors, :response
  end

  class UnexpectedResponse < Net::HTTPError

  end

  class << self
    attr_accessor :host, :username, :password
  end

end

require 'eel_client/mt'
require 'eel_client/premium_mt'
require 'eel_client/mo'
