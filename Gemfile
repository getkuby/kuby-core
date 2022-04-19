source 'https://rubygems.org'

gemspec

gem 'kuby-crdb', github: 'getkuby/kuby-crdb'
gem 'kube-dsl', github: 'getkuby/kube-dsl'
gem 'kuby-cert-manager', github: 'getkuby/kuby-cert-manager'
gem 'kubernetes-cli', github: 'getkuby/kubernetes-cli'

group :development, :test do
  gem 'pry-byebug'
  gem 'rake'

  gem 'curdle', '~> 1.0'
  gem 'parlour', '~> 6.0'
  gem 'tapioca', '~> 0.7'
  gem 'sorbet-runtime', '= 0.5.9897'
  gem 'sorbet-static', '= 0.5.9897'
end

group :test do
  gem 'rspec', '~> 3.0'
end
