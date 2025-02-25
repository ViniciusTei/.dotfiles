#!/bin/bash

i3status -c "~/.config/i3/i3status.conf" | while :
do
  read line
  layout=$(xkblayout-state print %s)
  connection="󰈀 offline"
  if ping -c 1 -W 1 8.8.8.8 &>/dev/null; then
    connection="󰈀 online"
  fi
  echo "󰌌 $layout | $connection | $line" || exit 1
done
