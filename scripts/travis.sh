#! /bin/bash

if [[ "$STAGE" == 'test' ]]; then
  bundle exec rspec
elif [[ "$STAGE" == 'typecheck' ]]; then
  bundle exec srb tc
elif [[ "$STAGE" == "integration" ]]; then
  source scripts/integration.sh
fi
