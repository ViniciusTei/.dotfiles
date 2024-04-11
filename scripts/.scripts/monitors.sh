#!/bin/bash

echo "Setup multiple monitors..\n\n"
MAIN=$(xrandr | fzf --prompt 'Select the main monitor: ' | awk '{ print $1 }')
echo "Select monitor to the left"
LEFT=$(xrandr | fzf --prompt 'Select the second monitor: ' | awk '{ print $1 }')
xrandr --output $LEFT --auto --left-of $MAIN

