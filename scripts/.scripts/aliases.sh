#! /bin/bash

alias tmuxnew=tmux new -A -s vinicius 

# cd to projects folder with fuzzy finder
alias od='cd $(find ~/Documentos/www -maxdepth 1 -type d | fzf)'

# nvim open project aliases
alias nd='nvim $(find ~/Documentos/www -maxdepth 1 -type d | fzf)'
alias n=nvim

# work developments
alias merge_develop="~/.scripts/merge_develop.sh"
alias create_branch="~/.scripts/create_branch.sh"
alias cbrdoc.sh="~/.scripts/cbrdoc.sh"
