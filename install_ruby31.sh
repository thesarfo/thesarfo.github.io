#!/bin/bash

set -e

RUBY_VERSION="3.1.4"

echo "📦 Installing build dependencies..."
sudo apt update
sudo apt install -y build-essential libssl-dev libreadline-dev zlib1g-dev \
libyaml-dev libffi-dev libgdbm-dev libncurses5-dev libdb-dev wget

echo "⬇️ Downloading Ruby $RUBY_VERSION..."
cd /tmp
wget https://cache.ruby-lang.org/pub/ruby/3.1/ruby-$RUBY_VERSION.tar.gz
tar -xzf ruby-$RUBY_VERSION.tar.gz
cd ruby-$RUBY_VERSION

echo "⚙️ Configuring build..."
./configure --prefix=/usr/local

echo "🛠️ Building Ruby (this may take a few minutes)..."
make -j"$(nproc)"

echo "📦 Installing Ruby $RUBY_VERSION..."
sudo make install

echo "✅ Ruby installed!"
ruby -v
gem -v

