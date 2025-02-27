#! /bin/bash

set -e

# clone rails app
gem install prebundler -v '< 1'
git clone https://github.com/getkuby/kuby_test.git
cp -r kuby-core/ kuby_test/vendor/
cd kuby_test

# remove sorbet annotations
gem install curdle
curdle $(find vendor/kuby-core/lib -name '*.rb') > /dev/null

# gems
printf "\ngem 'kuby-core', path: 'vendor/kuby-core'\n" >> Gemfile
printf "gem 'kuby-prebundler', '~> 0.1'\n" >> Gemfile
printf "gem 'kuby-kind', '~> 0.2'\n" >> Gemfile
printf "gem 'kuby-sidekiq', '~> 0.3'\n" >> Gemfile
printf "gem 'sidekiq', '~> 6.5'\n" >> Gemfile

# install ruby deps
bundle lock
cat <<'EOF' > .prebundle_config
Prebundler.configure do |config|
  config.storage_backend = Prebundler::S3Backend.new(
    client: Aws::S3::Client.new(
      region: 'default',
      credentials: Aws::Credentials.new(
        ENV['PREBUNDLER_ACCESS_KEY_ID'],
        ENV['PREBUNDLER_SECRET_ACCESS_KEY']
      ),
      endpoint: 'https://us-east-1.linodeobjects.com',
      http_continue_timeout: 0
    ),
    bucket: 'prebundler',
    region: 'us-east-1'
  )
end
EOF
