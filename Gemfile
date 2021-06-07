source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'pry-byebug'
  gem 'rake'
  # lock to a specific version to prevent breaking CI when new versions come out
  gem 'sorbet', '= 0.5.6427'
  gem 'webrick'
end

group :test do
  gem 'rspec', '~> 3.0'
end
