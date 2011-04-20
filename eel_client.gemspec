# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eel_client/version"

Gem::Specification.new do |s|
  s.name        = "eel_client"
  s.version     = EelClient::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["MobileCause, LLC"]
  s.email       = ["support@mobilecause.com"]
  s.homepage    = "http://www.mobilecause.com/"
  s.summary     = %q{EelClient library}
  #s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "eel_client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency('rspec', '=2.5.0')
  s.add_development_dependency('artifice', '=0.6')
  s.add_development_dependency('nokogiri', '=1.4.4')
end
