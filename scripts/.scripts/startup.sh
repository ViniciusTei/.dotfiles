#! /bin/bash

if [ -z "$TMUX" ] && [ -z "$SSH_CONNECTION" ]; then
  tmux new-session -A -s vinicius
fi
