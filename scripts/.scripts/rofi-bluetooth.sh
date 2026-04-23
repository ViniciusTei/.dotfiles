#!/usr/bin/env bash
set -euo pipefail

BTCTL="$HOME/.scripts/btctl.sh"

eval "$(xdotool getmouselocation --shell)"

rofi_at_mouse() {
  local prompt="$1"
  shift
  rofi -dmenu -p "$prompt" -location 0 -xoffset "$X" -yoffset "$((Y - 200))" "$@"
}

format_device() {
  awk -F'|' '{print $2 " (" $1 ")"}'
}

extract_mac() {
  sed -E 's/.*\(([^)]+)\)/\1/'
}

pick_device() {
  local prompt="$1" devices="$2"
  if [ -z "$devices" ]; then
    notify-send "Bluetooth" "No devices available"
    exit 0
  fi
  echo "$devices" | format_device | rofi_at_mouse "$prompt"
}

power_status=$("$BTCTL" power status 2>/dev/null || echo "no")
if [ "$power_status" = "yes" ]; then
  power_label="Power off"
else
  power_label="Power on"
fi

choice=$(printf '%s\nScan + Pair\nConnect\nDisconnect\nRemove' "$power_label" \
  | rofi_at_mouse "Bluetooth")

[ -z "$choice" ] && exit 0

case "$choice" in
  "Power on")
    if "$BTCTL" power on; then
      notify-send "Bluetooth" "Powered on"
    else
      notify-send "Bluetooth" "Failed to power on"
    fi
    ;;
  "Power off")
    if "$BTCTL" power off; then
      notify-send "Bluetooth" "Powered off"
    else
      notify-send "Bluetooth" "Failed to power off"
    fi
    ;;
  "Scan + Pair")
    notify-send "Bluetooth" "Scanning for 5 seconds..."
    "$BTCTL" scan 5
    devices=$("$BTCTL" list --available)
    selection=$(pick_device "Pair device" "$devices")
    [ -z "$selection" ] && exit 0
    mac=$(echo "$selection" | extract_mac)
    if "$BTCTL" pair "$mac"; then
      notify-send "Bluetooth" "Paired: $selection"
    else
      notify-send "Bluetooth" "Pair failed: $selection"
    fi
    ;;
  "Connect")
    devices=$("$BTCTL" list --paired | awk -F'|' '$3 == "no"')
    selection=$(pick_device "Connect" "$devices")
    [ -z "$selection" ] && exit 0
    mac=$(echo "$selection" | extract_mac)
    if "$BTCTL" connect "$mac"; then
      notify-send "Bluetooth" "Connected: $selection"
    else
      notify-send "Bluetooth" "Connect failed: $selection"
    fi
    ;;
  "Disconnect")
    devices=$("$BTCTL" connected)
    selection=$(pick_device "Disconnect" "$devices")
    [ -z "$selection" ] && exit 0
    mac=$(echo "$selection" | extract_mac)
    if "$BTCTL" disconnect "$mac"; then
      notify-send "Bluetooth" "Disconnected: $selection"
    else
      notify-send "Bluetooth" "Disconnect failed: $selection"
    fi
    ;;
  "Remove")
    devices=$("$BTCTL" list --paired)
    selection=$(pick_device "Remove" "$devices")
    [ -z "$selection" ] && exit 0
    mac=$(echo "$selection" | extract_mac)
    if "$BTCTL" remove "$mac"; then
      notify-send "Bluetooth" "Removed: $selection"
    else
      notify-send "Bluetooth" "Remove failed: $selection"
    fi
    ;;
esac
