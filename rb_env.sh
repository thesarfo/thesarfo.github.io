#!/bin/bash

set -e

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt update
sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev autoconf \
bison build-essential libyaml-dev libffi-dev libgdbm-dev libncurses5-dev

# Install rbenv & ruby-build
echo "🧰 Installing rbenv & ruby-build..."
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init - bash)"
fi

if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# Restart shell for rbenv to work
source ~/.bashrc

# Install Ruby
RUBY_VERSION="3.1.4"
echo "💎 Installing Ruby $RUBY_VERSION..."
rbenv install $RUBY_VERSION
rbenv global $RUBY_VERSION

# Confirm
echo "✅ Ruby installed:"
ruby -v
which ruby

# Install bundler
echo "📦 Installing bundler..."
gem install bundler

echo "🎉 Done! You’re now using Ruby $RUBY_VERSION with rbenv."

