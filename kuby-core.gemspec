$:.unshift File.expand_path('lib', __dir__)
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
  s.add_dependency 'docker-remote', '~> 0.8'
  s.add_dependency 'gli', '~> 2.21'
  s.add_dependency 'helm-cli', '~> 0.3'
  s.add_dependency 'krane', '~> 2.0'
  s.add_dependency 'kuby-cert-manager', '~> 0.4'
  s.add_dependency 'kuby-crdb', '~> 0.2'
  s.add_dependency 'kube-dsl', '~> 0.7'
  s.add_dependency 'kubernetes-cli', '~> 0.6'
  s.add_dependency 'railties', '>= 5.1'
  s.add_dependency 'rouge', '~> 3.0'
  s.add_dependency 'rake'

  s.add_development_dependency 'rspec'

  s.require_path = 'lib'
  s.executables << 'kuby'

  s.files = Dir['{bin,lib,rbi,spec}/**/*', 'Gemfile', 'LICENSE', 'CHANGELOG.md', 'README.md', 'Rakefile', 'kuby-core.gemspec']
end
