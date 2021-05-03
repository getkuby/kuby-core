#! /bin/bash

if [[ "$STAGE" == 'test' ]]; then
  bundle install --jobs 2 --retry 3
  bundle exec rspec
elif [[ "$STAGE" == 'typecheck' ]]; then
  bundle install --jobs 2 --retry 3
  bundle exec srb tc
elif [[ "$STAGE" == "integration" ]]; then
  source scripts/integration.sh
fi
