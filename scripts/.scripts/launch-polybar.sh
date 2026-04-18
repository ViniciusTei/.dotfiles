#!/bin/bash

# Kill existing polybar instances and wait for clean exit
killall -q polybar
while pgrep -u "$UID" -x polybar > /dev/null; do sleep 1; done

# Restart battery notifier (single instance)
pkill -f battery-notify.sh 2>/dev/null || true
~/.scripts/battery-notify.sh &

# Start one bar per connected monitor
while IFS= read -r output; do
    MONITOR="$output" polybar --config="$HOME/.config/polybar/config.ini" main &
done < <(xrandr --query | grep ' connected' | awk '{print $1}')

# Workaround for polybar bug: position=bottom is ignored with override-redirect=true.
# After bars appear, move each one to the bottom of its monitor.
# sleep 1
# BAR_HEIGHT=27
# xrandr --query | grep ' connected' | while read -r line; do
#     geometry=$(echo "$line" | grep -oP '\d+x\d+\+\d+\+\d+')
#     [ -z "$geometry" ] && continue
#     MON_W=$(echo "$geometry" | grep -oP '^\d+')
#     MON_H=$(echo "$geometry" | grep -oP 'x\K\d+(?=\+)')
#     MON_X=$(echo "$geometry" | grep -oP '\+\K\d+(?=\+)')
#     TARGET_Y=$((MON_H - BAR_HEIGHT))
#     xdotool search --name "polybar" | while read -r wid; do
#         WIN_X=$(xdotool getwindowgeometry "$wid" 2>/dev/null | grep -oP 'Position: \K\d+')
#         WIN_W=$(xdotool getwindowgeometry "$wid" 2>/dev/null | grep -oP 'Geometry: \K\d+')
#         [ "$WIN_X" = "$MON_X" ] && [ "$WIN_W" = "$MON_W" ] && \
#             xdotool windowmove "$wid" "$MON_X" "$TARGET_Y"
#     done
# done
