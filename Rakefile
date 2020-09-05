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

task :vendor_gli do
  require 'open-uri'

  gli_version = '2.19.2'
  dir = File.join(*%w(vendor gems gli))
  gem_path = File.join(dir, 'gli.gem')

  FileUtils.rm_rf(dir)
  FileUtils.mkdir_p(dir)

  File.write(
    gem_path,
    open("https://rubygems.org/downloads/gli-#{gli_version}.gem").read
  )

  Dir.chdir(dir) do
    system("tar xOf gli.gem data.tar.gz | tar zxf -")
  end

  FileUtils.mkdir(File.join(dir, 'lib', 'kuby'))

  FileUtils.mv(
    File.join(dir, 'lib', 'gli'),
    File.join(dir, 'lib', 'kuby')
  )

  FileUtils.mv(
    File.join(dir, 'lib', 'gli.rb'),
    File.join(dir, 'lib', 'kuby', 'gli.rb')
  )

  File.unlink(gem_path)

  Dir.glob(File.join(dir, '**', '*.rb')) do |f|
    contents = File.read(f)
    contents.gsub!(/module GLI$/, "module Kuby::GLI")
    contents.gsub!(/GLI::/, 'Kuby::GLI::')
    contents.gsub!(/require (['"])gli([\/'"])/, 'require \\1kuby/gli\\2')
    File.write(f, contents)
  end
end
