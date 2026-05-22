#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCAN_TIME=5

if ! command -v bluetoothctl >/dev/null 2>&1; then
  echo "bluetoothctl not found. Install bluez." >&2
  exit 2
fi

get_devices() {
  bluetoothctl devices 2>/dev/null | sed 's/^Device //' | while IFS= read -r line; do
    [ -z "$line" ] && continue
    mac="${line%% *}"
    name="${line#* }"
    # 1. scan-time cache (most up-to-date for newly discovered devices)
    if [ -f "${BT_NAME_CACHE:-}" ]; then
      cached=$(awk -F'\t' -v m="$mac" '$1 == m {print $2; exit}' "$BT_NAME_CACHE")
      [ -n "$cached" ] && name="$cached"
    fi
    # 2. fall back to Name: field from bluetoothctl info
    if [ "$name" = "${mac//:/-}" ] || [ "$name" = "$mac" ]; then
      info=$(bluetoothctl info "$mac" 2>/dev/null)
      resolved=$(printf '%s\n' "$info" | sed -n 's/^\s*Name: //p' | head -1)
      [ -n "$resolved" ] && name="$resolved"
    else
      info=$(bluetoothctl info "$mac" 2>/dev/null)
    fi
    connected=$(echo "$info" | grep -q "Connected: yes" && echo yes || echo no)
    paired=$(echo "$info"    | grep -q "Paired: yes"    && echo yes || echo no)
    trusted=$(echo "$info"   | grep -q "Trusted: yes"   && echo yes || echo no)
    printf '%s|%s|%s|%s|%s\n' "$mac" "$name" "$connected" "$paired" "$trusted"
  done
}

cmd_power() {
  local arg=${1:-}
  case "$arg" in
    on|off)
      if bluetoothctl power "$arg" >/dev/null 2>&1; then
        return 0
      else
        echo "Failed to set power $arg" >&2
        return 1
      fi
      ;;
    status)
      bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}'
      ;;
    *)
      echo "Usage: $SCRIPT_NAME power on|off|status" >&2
      return 2
      ;;
  esac
}

cmd_list() {
  local filter=${1:-}
  case "$filter" in
    --paired)    get_devices | awk -F'|' '$4 == "yes"' ;;
    --available) get_devices | awk -F'|' '$4 == "no"'  ;;
    "")          get_devices ;;
    *)
      echo "Usage: $SCRIPT_NAME list [--paired|--available]" >&2
      return 2
      ;;
  esac
}

cmd_connected() {
  get_devices | awk -F'|' '$3 == "yes"'
}

BT_NAME_CACHE="${TMPDIR:-/tmp}/btctl_names.$$"

cmd_scan() {
  local t=${1:-$SCAN_TIME}
  : > "$BT_NAME_CACHE"
  (
    printf 'power on\n'
    printf 'scan on\n'
    sleep "$t"
    printf 'scan off\n'
    printf 'exit\n'
  ) | bluetoothctl 2>/dev/null | while IFS= read -r line; do
    # capture "[CHG] Device MAC Name: actual name" events
    if [[ "$line" =~ \[CHG\]\ Device\ ([0-9A-Fa-f:]{17})\ Name:\ (.*) ]]; then
      printf '%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" >> "$BT_NAME_CACHE"
    fi
  done || true
}

cmd_pair() {
  local mac=${1:-}
  if [ -z "$mac" ]; then
    echo "Usage: $SCRIPT_NAME pair <MAC>" >&2
    return 2
  fi
  if bluetoothctl pair "$mac" >/dev/null 2>&1; then
    bluetoothctl trust "$mac" >/dev/null 2>&1 || true
    return 0
  else
    echo "Pair failed for $mac" >&2
    return 1
  fi
}

cmd_connect() {
  local mac=${1:-}
  if [ -z "$mac" ]; then
    echo "Usage: $SCRIPT_NAME connect <MAC>" >&2
    return 2
  fi
  if bluetoothctl connect "$mac" >/dev/null 2>&1; then
    return 0
  else
    echo "Connect failed for $mac" >&2
    return 1
  fi
}

cmd_disconnect() {
  local mac=${1:-}
  if [ -z "$mac" ]; then
    echo "Usage: $SCRIPT_NAME disconnect <MAC>" >&2
    return 2
  fi
  if bluetoothctl disconnect "$mac" >/dev/null 2>&1; then
    return 0
  else
    echo "Disconnect failed for $mac" >&2
    return 1
  fi
}

cmd_remove() {
  local mac=${1:-}
  if [ -z "$mac" ]; then
    echo "Usage: $SCRIPT_NAME remove <MAC>" >&2
    return 2
  fi
  if bluetoothctl remove "$mac" >/dev/null 2>&1; then
    return 0
  else
    echo "Remove failed for $mac" >&2
    return 1
  fi
}

cmd_info() {
  local mac=${1:-}
  if [ -z "$mac" ]; then
    echo "Usage: $SCRIPT_NAME info <MAC>" >&2
    return 2
  fi
  bluetoothctl info "$mac"
}

cmd_help() {
  cat <<EOF
Usage: $SCRIPT_NAME <command>
Commands:
  power on|off|status              Toggle or check bluetooth adapter
  list [--paired|--available]      List all/paired/unpaired devices
  connected                        List connected devices
  scan [seconds]                   Scan for nearby devices (default: ${SCAN_TIME}s)
  pair <MAC>                       Pair and trust a device (no auto-connect)
  connect <MAC>                    Connect to a paired device
  disconnect <MAC>                 Disconnect a device
  remove <MAC>                     Remove/unpair a device
  info <MAC>                       Show raw device info

Output format (except power status and info):
  MAC|NAME|CONNECTED|PAIRED|TRUSTED
EOF
}

case "${1:-}" in
  power)      shift; cmd_power "${1:-}" ;;
  list)       shift; cmd_list  "${1:-}" ;;
  connected)  cmd_connected ;;
  scan)       shift; cmd_scan  "${1:-}" ;;
  pair)       shift; cmd_pair  "${1:-}" ;;
  connect)    shift; cmd_connect    "${1:-}" ;;
  disconnect) shift; cmd_disconnect "${1:-}" ;;
  remove)     shift; cmd_remove     "${1:-}" ;;
  info)       shift; cmd_info       "${1:-}" ;;
  help|--help|-h|"") cmd_help ;;
  *)
    echo "Unknown command: ${1}" >&2
    cmd_help >&2
    exit 2
    ;;
esac
