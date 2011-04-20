require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec'
require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/lib/*_spec.rb"
end

RSpec::Core::RakeTask.new(:live) do |t|
  t.pattern = "./spec/integration/*_spec.rb"
end