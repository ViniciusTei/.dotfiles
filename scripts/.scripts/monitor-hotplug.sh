#!/bin/bash

# Auto-configure monitors on hotplug or i3 startup.
# Works in two contexts:
#   - As user (called from i3 exec_always): runs xrandr directly
#   - As root (called from udev on DRM change event): finds X session user and su's to run xrandr

if [ "$(id -u)" -eq 0 ]; then
    # Running as root via udev — find the X11 user and display number
    XUSER=$(who | grep '(:[0-9]' | awk '{ print $1 }' | head -1)
    if [ -z "$XUSER" ]; then
        exit 1
    fi
    XDISPLAY=$(who | grep '(:[0-9]' | grep -oP '\(:\K[0-9]+' | head -1)
    XDISPLAY=":${XDISPLAY:-0}"
    XHOME=$(getent passwd "$XUSER" | cut -d: -f6)
    XAUTH="$XHOME/.Xauthority"

    run_xrandr() {
        su "$XUSER" -c "DISPLAY=$XDISPLAY XAUTHORITY=$XAUTH xrandr $*"
    }

    XRANDR_OUTPUT=$(su "$XUSER" -c "DISPLAY=$XDISPLAY XAUTHORITY=$XAUTH xrandr")
else
    # Running as user via i3
    run_xrandr() {
        xrandr "$@"
    }

    XRANDR_OUTPUT=$(xrandr)
fi

CONNECTED=$(echo "$XRANDR_OUTPUT" | grep ' connected' | awk '{ print $1 }')
DISCONNECTED=$(echo "$XRANDR_OUTPUT" | grep ' disconnected' | awk '{ print $1 }')

# Turn off disconnected outputs
for output in $DISCONNECTED; do
    run_xrandr --output "$output" --off
done

# Enable connected outputs
OUTPUTS=($CONNECTED)
count=${#OUTPUTS[@]}

[ "$count" -eq 0 ] && exit 0

# First output = primary
run_xrandr --output "${OUTPUTS[0]}" --auto --primary

# Remaining outputs positioned to the right of the previous
for ((i = 1; i < count; i++)); do
    run_xrandr --output "${OUTPUTS[$i]}" --auto --right-of "${OUTPUTS[$((i - 1))]}"
done
