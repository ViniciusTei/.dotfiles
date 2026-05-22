#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

if ! command -v nmcli >/dev/null 2>&1; then
  echo "nmcli not found. Install network-manager." >&2
  exit 2
fi

# Detect the first active WiFi interface
get_iface() {
  nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
    | awk -F: '$2 == "wifi" { print $1; exit }'
}

cmd_power() {
  local arg=${1:-}
  case "$arg" in
    on|off)
      if nmcli radio wifi "$arg" >/dev/null 2>&1; then
        return 0
      else
        echo "Failed to set wifi $arg" >&2
        return 1
      fi
      ;;
    status)
      nmcli radio wifi 2>/dev/null | grep -q "^enabled$" && echo "yes" || echo "no"
      ;;
    *)
      echo "Usage: $SCRIPT_NAME power on|off|status" >&2
      return 2
      ;;
  esac
}

cmd_list() {
  local iface
  iface="$(get_iface)"

  # Use -t --escape no to get raw field values separated by ':'
  # Fields: SSID, SIGNAL, SECURITY, ACTIVE
  # SSID may contain ':', so split from the right:
  #   active   = ${line##*:}
  #   rest     = ${line%:*}
  #   security = ${rest##*:}
  #   rest2    = ${rest%:*}
  #   signal   = ${rest2##*:}
  #   ssid     = ${rest2%:*}

  declare -A seen
  nmcli -t --escape no -f SSID,SIGNAL,SECURITY,ACTIVE device wifi list \
        ${iface:+ifname "$iface"} 2>/dev/null \
    | sort -t: -k2 -rn \
    | while IFS= read -r line; do
        [ -z "$line" ] && continue
        active="${line##*:}"
        rest="${line%:*}"
        security="${rest##*:}"
        rest2="${rest%:*}"
        signal="${rest2##*:}"
        ssid="${rest2%:*}"

        # Skip hidden (empty SSID) networks
        [ -z "$ssid" ] && continue

        # Deduplicate by SSID (first occurrence wins after sort by signal desc)
        [ "${seen[$ssid]+set}" ] && continue
        seen["$ssid"]=1

        connected="no"
        [ "$active" = "yes" ] && connected="yes"

        printf '%s|%s|%s|%s\n' "$ssid" "$signal" "$security" "$connected"
      done
}

cmd_saved() {
  nmcli -t -f NAME,TYPE connection show 2>/dev/null \
    | awk -F: '$2 == "802-11-wireless" { print $1 }'
}

cmd_scan() {
  local iface
  iface="$(get_iface)"
  nmcli device wifi rescan ${iface:+ifname "$iface"} 2>/dev/null || true
  sleep 2
}

cmd_connect() {
  local ssid="${1:-}"
  local pass="${2:-}"
  if [ -z "$ssid" ]; then
    echo "Usage: $SCRIPT_NAME connect <SSID> [password]" >&2
    return 2
  fi
  local iface
  iface="$(get_iface)"
  if [ -n "$pass" ]; then
    if nmcli device wifi connect "$ssid" password "$pass" \
        ${iface:+ifname "$iface"} >/dev/null 2>&1; then
      return 0
    else
      echo "Connect failed for '$ssid'" >&2
      return 1
    fi
  else
    if nmcli device wifi connect "$ssid" \
        ${iface:+ifname "$iface"} >/dev/null 2>&1; then
      return 0
    else
      echo "Connect failed for '$ssid'" >&2
      return 1
    fi
  fi
}

cmd_disconnect() {
  local iface
  iface="$(get_iface)"
  if [ -z "$iface" ]; then
    echo "No WiFi interface found" >&2
    return 1
  fi
  if nmcli device disconnect "$iface" >/dev/null 2>&1; then
    return 0
  else
    echo "Disconnect failed for $iface" >&2
    return 1
  fi
}

cmd_status_label() {
  if nmcli radio wifi 2>/dev/null | grep -q "^enabled$"; then
    iface="$(get_iface)"
    ssid=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null \
      | awk -F: -v iface="$iface" '$2 == iface {print $1; exit}' || true)
    if [ -n "$ssid" ]; then
      printf "󰤨  %s\n" "$ssid"
    else
      printf "󰤨\n"
    fi
  else
    printf "󰤭\n"
  fi
}

cmd_help() {
  cat <<EOF
Usage: $SCRIPT_NAME <command>
Commands:
  power on|off|status              Toggle or check WiFi radio
  list                             List available networks (SSID|SIGNAL|SECURITY|CONNECTED)
  saved                            List saved/known SSIDs
  scan                             Rescan for networks then wait 2s
  connect <SSID> [password]        Connect to a network
  disconnect                       Disconnect the WiFi interface

Output format for list:
  SSID|SIGNAL|SECURITY|CONNECTED
EOF
}

case "${1:-}" in
  power)      shift; cmd_power      "${1:-}" ;;
  list)       cmd_list ;;
  saved)      cmd_saved ;;
  scan)       cmd_scan ;;
  connect)    shift; cmd_connect    "${1:-}" "${2:-}" ;;
  disconnect) cmd_disconnect ;;
  status-label) cmd_status_label ;;
  help|--help|-h|"") cmd_help ;;
  *)
    echo "Unknown command: ${1}" >&2
    cmd_help >&2
    exit 2
    ;;
esac
