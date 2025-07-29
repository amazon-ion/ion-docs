#!/bin/bash
set -e

BOOTSTRAP_DIR=${HOME}/bootstrap

# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
echo 'eval "$(~/.rbenv/bin/rbenv init - zsh)"' >> ~/.zshrc

# Make sure we can see rbenv
eval "$(~/.rbenv/bin/rbenv init - bash)"

# Install latest stable Ruby
rbenv install "$(rbenv install -l | grep -v - | tail -1)"
rbenv global  "$(rbenv install -l | grep -v - | tail -1)"

# Install our required Gems
cd "${BOOTSTRAP_DIR}"
bundle install

# Rake doesn't like the ownership of our workspace in the container
git config --global --add safe.directory /workspace
