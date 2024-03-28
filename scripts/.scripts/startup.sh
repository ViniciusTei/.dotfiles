#! /bin/bash

if ! [ "$TERM_PROGRAM" = tmux ]; then
  tmux new-session -A -s vinicius 
fi
