#!/bin/bash

echo "Setting up development tools..."

echo "Installing dependencies..."
sudo apt update
sudo apt install -y fzf stow xclip ripgrep tmux i3 libx11-dev feh rofi xdotool \
    build-essential cmake cmake-data pkg-config python3 python3-sphinx \
    libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev \
    python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev \
    libxcb-xkb-dev libxcb-xrm-dev libasound2-dev libmpdclient-dev libiw-dev \
    libcurl4-openssl-dev libpulse-dev libjsoncpp-dev libnl-genl-3-dev libuv1-dev

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cd ~/.dotfiles

stow nvim 
stow i3
stow tmux 
stow scripts
stow rofi
stow polybar

mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux

tmux source ~/.tmux.conf

# polybar install from source
POLYBAR_VERSION="3.7.2"
POLYBAR_BUILD_DIR="/tmp/polybar-build"
rm -rf "$POLYBAR_BUILD_DIR" && mkdir -p "$POLYBAR_BUILD_DIR"
curl -L "https://github.com/polybar/polybar/releases/download/${POLYBAR_VERSION}/polybar-${POLYBAR_VERSION}.tar.gz" \
    -o "$POLYBAR_BUILD_DIR/polybar.tar.gz"
tar xzf "$POLYBAR_BUILD_DIR/polybar.tar.gz" -C "$POLYBAR_BUILD_DIR"
mkdir -p "$POLYBAR_BUILD_DIR/polybar-${POLYBAR_VERSION}/build"
cmake -S "$POLYBAR_BUILD_DIR/polybar-${POLYBAR_VERSION}" \
      -B "$POLYBAR_BUILD_DIR/polybar-${POLYBAR_VERSION}/build" \
      -DCMAKE_BUILD_TYPE=Release -DBUILD_DOC=OFF
make -j"$(nproc)" -C "$POLYBAR_BUILD_DIR/polybar-${POLYBAR_VERSION}/build"
sudo make -C "$POLYBAR_BUILD_DIR/polybar-${POLYBAR_VERSION}/build" install
rm -rf "$POLYBAR_BUILD_DIR"

# nvm install
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

DOWLOAD_DIR="~/Downloads"

if [ ! -d "$DIR" ]; then
 	mkdir -p "$DIR"
else
	cd "$DIR"
fi

# neovim install
curl -LO https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# lazygit install
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# install xkblayout-state tread keybard layout
git clone https://github.com/nonpop/xkblayout-state /tmp/xkblayout-state
sudo make -C /tmp/xkblayout-state
sudo mv /tmp/xkblayout-state/xkblayout-state /usr/local/bin

# install kitty terminal
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/

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

echo "Installing monitor hotplug udev rule..."
echo "ACTION==\"change\", SUBSYSTEM==\"drm\", RUN+=\"$HOME/.scripts/monitor-hotplug.sh\"" \
    | sudo tee /etc/udev/rules.d/95-monitor-hotplug.rules > /dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=drm

echo "Development tools setup complete."
