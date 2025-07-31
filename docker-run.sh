#!/bin/bash

BOOTSTRAP_DIR="${HOME}/bootstrap"

# Make sure we can see rbenv
eval "$(~/.rbenv/bin/rbenv init - bash)"

cp ${BOOTSTRAP_DIR}/Gemfile.lock ./

PATH=${BOOTSTRAP_DIR}/fusion-java/bin:${PATH}

# Execute build
bundle exec rake "$@"
