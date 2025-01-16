#!/bin/bash

echo "Setting up development tools..."

echo "Installing dependencies..."
sudo apt update
sudo apt install fzf stow xclip ripgrep tmux i3 libx11-dev

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cd ~/.dotfiles

stow nvim 
stow i3
stow tmux 
stow scripts

tmux source ~/.tmux.conf

# nvm install
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

cd ~/Downloads

# lazygit install
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# install xkblayout-state tread keybard layout
git clone https://github.com/nonpop/xkblayout-state /tmp/xkblayout-state
sudo make -C /tmp/xkblayout-state
sudo mv /tmp/xkblayout-state/xkblayout-state /usr/local/bin

echo "Setting up bash..."
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

# Setup multiple monitors if moniotors is passed as an argument

if [ "$1" == "monitors" ]; then
    echo "Setting up multiple monitors..."
    . ~/.scripts/monitors.sh
fi

echo "Development tools setup complete."
