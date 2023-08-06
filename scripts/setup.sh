#!/bin/bash

echo "Starting setup..."

sudo apt update
sudo apt install fzf nodejs python3

source ~/.dotfiles/scripts/aliases.sh
