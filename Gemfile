source 'https://rubygems.org'

gemspec

gem 'kuby-crdb', github: 'getkuby/kuby-crdb'

group :development, :test do
  gem 'pry-byebug'
  gem 'rake'
  # lock to a specific version to prevent breaking CI when new versions come out
  gem 'sorbet', '= 0.5.6433'
end

group :test do
  gem 'rspec', '~> 3.0'
end
