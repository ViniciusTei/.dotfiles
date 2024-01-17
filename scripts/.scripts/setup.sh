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


# nvm install
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# lazygit install
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

source ~/.scripts/bash.sh
source ~/.bashrc
