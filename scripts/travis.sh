#! /bin/bash

if [[ "$STAGE" == 'test' ]]; then
  bundle exec rspec
elif [[ "$STAGE" == 'typecheck' ]]; then
  srb tc
elif [[ "$STAGE" == "integration" ]]; then
  unset BUNDLE_GEMFILE
  set -e

  source ./scripts/integration.sh
  setup_cluster

  source ~/.nvm/nvm.sh
  set -o xtrace
  nvm install 15.0.1
  nvm use 15.0.1
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt-get update && sudo apt-get install -y libmysqlclient-dev yarn
  gem install rails -v 6.0.3.4
  cd ..
  rails _6.0.3.4_ new kubyapp -d mysql
  cp -R ./kuby-core/ ./kubyapp/vendor/kuby-core
  cd kubyapp
  printf "\ngem 'kuby-core', path: 'vendor/kuby-core'\n" >> Gemfile
  bundle exec rails g kuby
  printf "Kuby.environment.docker.insert(:vendor, before: :bundler_phase) { |dockerfile| dockerfile.copy('vendor', 'vendor') }\n" >> kuby.rb
  printf "Kuby.environment.docker.image_url('kubyapp')\n" >> kuby.rb
  printf "Kuby.environment.kubernetes.plugin(:rails_app).tls_enabled(false)\n" >> kuby.rb

  bundle exec kuby -e production build
  bundle exec kuby -e production deploy

  curl kubyapp-web:8080
fi
