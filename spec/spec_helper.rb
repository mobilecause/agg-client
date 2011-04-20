require 'bundler'
Bundler.require(:default, :development)
require 'rspec' # => required for RubyMine to be able to run specs
require 'base64'

Dir[File.expand_path(File.dirname(__FILE__) + '/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|

  config.before do
    EelClient.host = "myfakehost.com"
    EelClient.username = "jack"
    EelClient.password = "password"
  end

  # gets rid of the bacetrace that we don't care about
  config.backtrace_clean_patterns = [/\.rvm\/gems\//]

end