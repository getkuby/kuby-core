#! /bin/bash

if [[ "$STAGE" == 'test' ]]; then
  bundle exec rspec
elif [[ "$STAGE" == 'typecheck' ]]; then
  srb tc
elif [[ "$STAGE" == "integration" ]]; then
  source ./scripts/integration.sh
  setup_cluster

  set -o xtrace
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt update && sudo apt-get install libmysqlclient-dev nodejs yarn
  gem install rails -v 6.0.3.4
  mkdir kubyapp
  cd kubyapp
  rails _6.0.3.4_ new . -d mysql
  printf "\ngem 'kuby-core', path: '../'\n" >> Gemfile
  bundle exec rails g kuby
  bundle exec kuby -e production build
  set +o xtrace
fi
