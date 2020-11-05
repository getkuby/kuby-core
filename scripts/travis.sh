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
  setup_node

  echo travis_fold:start:generate_app
  gem install rails -v 6.0.3.4
  cd ..
  rails _6.0.3.4_ new kubyapp -d mysql
  cp -R ./kuby-core/ ./kubyapp/vendor/kuby-core
  cd kubyapp
  printf "\ngem 'kuby-core', path: 'vendor/kuby-core'\n" >> Gemfile
  printf "\ngem 'docker-remote', github: 'getkuby/docker-remote', branch: 'debug'\n" >> Gemfile
  bundle install
  bundle exec rails g kuby
  cp ../kuby-core/scripts/kuby.rb ./
  echo "Using the following Kuby config:"
  cat kuby.rb
  echo travis_fold:end:generate_app

  echo travis_fold:start:start_registry
  docker run -d -p 5000:5000 --name registry registry:2
  echo travis_fold:end:start_registry

  echo travis_fold:start:build
  GLI_DEBUG=true bundle exec kuby -e production build
  echo travis_fold:end:build

  echo travis_fold:start:push
  GLI_DEBUG=true bundle exec kuby -e production push
  echo travis_fold:end:push

  echo travis_fold:start:deploy
  GLI_DEBUG=true bundle exec kuby -e production deploy
  echo travis_fold:end:deploy

  curl kubyapp-web:8080
fi
