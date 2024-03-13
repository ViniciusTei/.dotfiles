#!/bin/bash
curr_date=$(date +"%Y-%m-%d_%H-%M-%S")
filename="screenshot_${curr_date}.png"
maim "$@" ~/Pictures/$filename
notify-send "Scheenshot saved" "$filename"
eog ~/Pictures/$filename
