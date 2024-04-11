#!/bin/bash

echo "Setting up development tools..."

sudo apt update
sudo apt install \
  fzf \
  stow \
  xclip \
  ripgrep \
  tmux \
  i3 \
  libx11-dev \
  xrandr \

cd ~/.dotfiles
stow .

# nvm install
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# lazygit install
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# install xkblayout-state tread keybard layout
git clone https://github.com/nonpop/xkblayout-state /tmp/xkblayout-state
make -C /tmp/xkblayout-state
mv /tmp/xkblayout-state/xkblayout-state /usr/local/bin

# Define the lines to append to .bashrc
lines_to_append="
export LAYOUT_STATE=\$/usr/local/bin/xkblayout-state
export PATH=\$PATH:/usr/local/go/bin:\$GOPATH/bin:\$LAYOUT_STATE

# Startup keyboard layout
if [ -f ~/.scripts/layout.sh ]; then
    . ~/.scripts/layout.sh
fi

# Startup tmux session on bash login
if [ -f ~/.scripts/startup.sh ]; then
    . ~/.scripts/startup.sh
fi"

# Append the lines to .bashrc
echo "$lines_to_append" >> ~/.bashrc

source ~/.scripts/bash.sh
source ~/.bashrc

# Setup multiple monitors
. ~/.scripts/monitors.sh
