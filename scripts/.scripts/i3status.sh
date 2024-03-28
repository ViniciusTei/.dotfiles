#!/bin/bash

i3status -c "~/.config/i3/i3status.conf" | while :
do
  read line
  layout=$(~/Downloads/xkblayout-state/xkblayout-state print %s)
  echo "󰌌 $layout | $line" || exit 1
done
