#!/bin/bash

while true; do
    battery_level=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo "N/A")
    battery_status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo "N/A")

    if [ "$battery_level" != "N/A" ] && [ "$battery_status" != "Charging" ]; then
        case "$battery_level" in
            25) notify-send "Battery Warning" "Battery level is at $battery_level%!" -u low ;;
            15) notify-send "Battery Warning" "Battery level is at $battery_level%!" -u normal ;;
            10) notify-send "Battery Warning" "Battery level is at $battery_level%!" -u critical ;;
            5)  notify-send "Battery Warning" "Battery level is at $battery_level%!" -u critical ;;
        esac
    fi

    sleep 60
done
