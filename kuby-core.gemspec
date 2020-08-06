$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'kuby/version'

Gem::Specification.new do |s|
  s.name     = 'kuby-core'
  s.version  = ::Kuby::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/getkuby/kuby-core'

  s.description = s.summary = 'Deploy your Rails app onto Kubernetes the easy way.'

  s.platform = Gem::Platform::RUBY

  s.add_dependency 'colorize', '~> 0.8'
  s.add_dependency 'docker-remote', '~> 0.1'
  s.add_dependency 'krane', '~> 1.0'
  s.add_dependency 'kuby-cert-manager', '~> 0.2'
  s.add_dependency 'kube-dsl', '~> 0.3'
  s.add_dependency 'kuby-kube-db', '~> 0.4'
  s.add_dependency 'kubernetes-cli', '~> 0.2'
  s.add_dependency 'railties', '>= 5.1'
  s.add_dependency 'rouge', '~> 3.0'

  s.require_path = 'lib'

  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'LICENSE', 'CHANGELOG.md', 'README.md', 'Rakefile', 'kuby-core.gemspec']
end
