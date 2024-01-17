#! /bin/bash

alias tmuxnew='tmux new -A -s vinicius'

# cd to projects folder with fuzzy finder
alias od='cd $(find ~/Documents/www -maxdepth 2 -type d | fzf --height 40% --layout=reverse --border)'

# nvim open project aliases
alias nvim="~/Downloads/nvim-linux64/bin/nvim"
alias nd='nvim $(find ~/Documents/www -maxdepth 2 -type d | fzf --height 40% --layout=reverse --border)'
alias n=nvim

# work developments
alias cbrdoc.sh="~/.scripts/cbrdoc.sh"
alias layout="~./scripts/layout.sh"
alias gitcheckout='git branch | fzf | xargs git checkout'
