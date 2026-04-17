#!/bin/bash

# Kill existing polybar instances and wait for clean exit
killall -q polybar
while pgrep -u "$UID" -x polybar > /dev/null; do sleep 1; done

# Restart battery notifier (single instance)
pkill -f battery-notify.sh 2>/dev/null || true
~/.scripts/battery-notify.sh &

# Start one bar per connected monitor
while IFS= read -r output; do
    MONITOR="$output" polybar main &
done < <(xrandr --query | grep ' connected' | awk '{print $1}')
