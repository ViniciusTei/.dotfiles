#! /bin/bash

alias tmuxnew=tmux new -A -s vinicius 

# cd to projects folder with fuzzy finder
alias od='cd $(find ~/Documentos/www -maxdepth 1 -type d | fzf)'

# nvim open project aliases
alias nd='nvim $(find ~/Documentos/www -maxdepth 1 -type d | fzf)'
alias n=nvim

# work developments
alias cbrdoc.sh="~/.scripts/cbrdoc.sh"
alias layout="~./scripts/layout.sh"
alias gitcheckout='git branch | fzf | xargs git checkout'
