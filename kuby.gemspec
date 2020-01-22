$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'kuby/version'

Gem::Specification.new do |s|
  s.name     = 'kuby'
  s.version  = ::Kuby::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron/kuby'

  s.description = s.summary = 'Deploy your Rails app onto Kubernetes the easy way.'

  s.platform = Gem::Platform::RUBY

  s.add_dependency 'railties', '~> 6.0'
  s.add_dependency 'colorize'

  s.require_path = 'lib'
  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'CHANGELOG.md', 'README.md', 'Rakefile', 'kuby.gemspec']
end
