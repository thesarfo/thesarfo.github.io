# Install build tools
sudo apt update
sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev autoconf \
bison build-essential libyaml-dev libffi-dev libgdbm-dev libncurses5-dev

# Install rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"

# Install ruby-build plugin
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Restart shell or manually reload bashrc
source ~/.bashrc

# Install Ruby 3.1.4
rbenv install 3.1.4
rbenv global 3.1.4

