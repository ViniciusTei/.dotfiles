#!/bin/bash

echo "Starting setup..."

sudo apt update
sudo apt install \
  fzf \
  nodejs \
  npm \
  python3 \

source ~/.dotfiles/scripts/aliases.sh
