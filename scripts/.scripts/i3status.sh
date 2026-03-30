#!/bin/bash

i3status -c "~/.config/i3/i3status.conf" | while :
do
  read line
  layout=$(xkblayout-state print %s)
  connection="󰈀 offline"

  battery_level=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo "N/A")
  battery_status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo "N/A")
  battery_status_icon = ""

  if [ "$battery_status" == "Charging" ]; then
    battery_status_icon="󱐋"
  fi
  
  if [ "$battery_level" -eq 25 ]; then
    if [ "$battery_status" != "Charging" ]; then
      notify-send "Battery Warning" "Battery level is at $battery_level%!" -u low
    fi
  fi 
  
  if [ "$battery_level" -eq 15 ]; then
    if [ "$battery_status" != "Charging" ]; then
      notify-send "Battery Warning" "Battery level is at $battery_level%!" -u normal
    fi
  fi 
  
  if [ "$battery_level" -eq 10 ]; then
    if [ "$battery_status" != "Charging" ]; then
      notify-send "Battery Warning" "Battery level is at $battery_level%!" -u critical
    fi
  fi 
  
  if [ "$battery_level" -eq 5 ]; then
    if [ "$battery_status" != "Charging" ]; then
      notify-send "Battery Warning" "Battery level is at $battery_level%!" -u critical
    fi
  fi 

  if [ "$battery_level" != "N/A" ]; then
    if [ "$battery_level" -ge 80 ]; then
      battery_icon="󱊣"
    elif [ "$battery_level" -ge 60 ]; then
      battery_icon="󱊢"
    elif [ "$battery_level" -ge 40 ]; then
      battery_icon="󱊢"
    elif [ "$battery_level" -ge 20 ]; then
      battery_icon="󱊡"
    else
      battery_icon="󱊣"
    fi
    line="$line | $battery_icon $battery_status_icon $battery_level%"
   else
    line="$line | Battery: N/A"
  fi

  if ping -c 1 -W 1 8.8.8.8 &>/dev/null; then
    connection="󰈀 online"
  fi
  echo "󰌌 $layout | $connection | $line" || exit 1
done
