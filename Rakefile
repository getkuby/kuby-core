require 'bundler'
require 'rspec/core/rake_task'
require 'rubygems/package_task'

require 'kuby'

Bundler::GemHelper.install_tasks

task default: :spec

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end
