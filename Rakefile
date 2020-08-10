require 'bundler'
require 'rspec/core/rake_task'
require 'rubygems/package_task'

require 'kuby'

Bundler::GemHelper.install_tasks

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end
task :default => :test
