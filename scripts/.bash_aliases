#! /bin/bash

# execute custom bash
. ~/.scripts/bash.sh

alias tmuxnew='tmux new -A -s vinicius'

# cd to projects folder with fuzzy finder
alias od='cd $(find ~/ -maxdepth 4 -type d -not -path "*/.*" | fzf --height 40% --layout=reverse --border)'

# nvim open project aliases
alias nvim="~/Downloads/nvim-linux64/bin/nvim"
alias nd='nvim $(find ~/Documents/www -maxdepth 2 -type d | fzf --height 40% --layout=reverse --border)'
alias n=nvim

# work developments
alias cbrdoc.sh="~/.scripts/cbrdoc.sh"
alias layout="~/.scripts/layout.sh"
alias gitcheckout='git branch | fzf --height 40% --layout=reverse --border | xargs git checkout'
alias gc='git branch | fzf --height 40% --layout=reverse --border | xargs git checkout'
alias gcr='git branch -r | fzf --height 40% --layout=reverse --border | cut -d'/' -f2- | xargs git checkout'
alias ts="~/.scripts/tmux-sessionize.sh"
alias gitmerge='~/.scripts/gitmerge.sh'
