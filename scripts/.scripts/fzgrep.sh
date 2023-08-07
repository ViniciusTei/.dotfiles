#!/bin/bash
# go get github.com/junegunn/fzf

#setting table size
BEFORE=10
AFTER=10
HEIGHT=$(expr $BEFORE + $AFTER + 3 )  # 2 lines for the preview box and 1 extra line fore the match

PREVIEW="git diff --unified=5 --color {}"

#"$@" 2>&1 | fzf --height=$HEIGHT --reverse --preview="${PREVIEW}"

git status -s | awk '{ print $2 }' | fzf -m --height=$HEIGHT --reverse --preview="${PREVIEW}"
