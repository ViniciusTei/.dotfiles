#!/bin/bash

echo "Starting setup..."

sudo apt update
sudo apt install \
  fzf \
  nodejs \
  npm \

source ~/.dotfiles/scripts/aliases.sh
