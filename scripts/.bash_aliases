#! /bin/bash

# execute custom bash
. ~/.scripts/bash.sh

# cd to projects folder with fuzzy finder
source ~/.scripts/od.sh

# nvim open project aliases
alias nd='nvim $(find ~/Document{,os} -maxdepth 2 -type d 2>/dev/null | fzf --height 40% --layout=reverse --border)'
alias n=nvim

# work developments
alias cbrdoc.sh="~/.scripts/cbrdoc.sh"
alias layout="~/.scripts/layout.sh"
alias tms="~/.scripts/tmux-sessionize.sh"
alias tmn='tmux new -A -s vinicius'

# git
alias gc='git branch | fzf --height 40% --layout=reverse --border | xargs git checkout'
alias gcr='git branch -r | fzf --height 40% --layout=reverse --border | cut -d'/' -f2- | xargs git checkout'
alias gm='~/.scripts/gitmerge.sh'
alias gcm='git commit -v'
alias gp='git push'
alias gpl='git pull'
alias cmsg='tmp=$(mktemp); git --no-pager diff --staged > "$tmp"; echo "Prompt: Gere uma mensagem de commit (pt-BR, Conventional Commits) baseada em
   @$tmp; não faça o commit." | copilot'


# Bluetooth wrapper
alias btctl='~/.scripts/btctl.sh'

# Harness
alias cc='claude --dangerously-skip-permissions'
