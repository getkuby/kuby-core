#! /bin/bash

if [[ "$STAGE" == 'test' ]]; then
  bundle exec rspec
elif [[ "$STAGE" == 'typecheck' ]]; then
  srb tc
fi
