# Bluetooth CLI + Rofi UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `btctl.sh` into a non-interactive scriptable CLI and add a Rofi UI layer triggered by a Polybar click at the mouse position.

**Architecture:** `btctl.sh` is a pure CLI API (no fzf/read, pipe-delimited output) called by `rofi-bluetooth.sh` which handles all UI flows using Rofi menus positioned at the mouse cursor via xdotool. Polybar triggers the UI on left-click and shows connected device name or idle icon.

**Tech Stack:** bash, bluetoothctl, rofi, xdotool, notify-send, polybar, i3

---

## File Map

| Action | Path |
|---|---|
| Rewrite | `scripts/.scripts/btctl.sh` |
| Create | `scripts/.scripts/rofi-bluetooth.sh` |
| Create | `tests/test_btctl.sh` |
| Modify | `polybar/.config/polybar/config.ini` |
| Modify | `i3/.config/i3/config` |
| Modify | `scripts/.scripts/setup.sh` |

---

## Task 1: Test infrastructure + btctl core tests

**Files:**
- Create: `tests/test_btctl.sh`

- [ ] **Step 1: Write test file with mock bluetoothctl and core assertions**

Create `tests/test_btctl.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
BTCTL="$(cd "$(dirname "$0")/.." && pwd)/scripts/.scripts/btctl.sh"

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    echo "  expected: [$expected]"
    echo "  actual:   [$actual]"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit() {
  local desc="$1" expected_code="$2"
  shift 2
  local actual_code=0
  "$@" >/dev/null 2>&1 || actual_code=$?
  assert_eq "$desc" "$expected_code" "$actual_code"
}

# ── Mock setup ────────────────────────────────────────────────────────────────
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"' EXIT

cat > "$MOCK_DIR/bluetoothctl" << 'MOCK'
#!/usr/bin/env bash
case "$1" in
  devices)
    echo "Device AA:BB:CC:DD:EE:FF Fone JBL"
    echo "Device 11:22:33:44:55:66 Mouse Logitech"
    echo "Device 99:88:77:66:55:44 Speaker Anker"
    ;;
  info)
    case "$2" in
      AA:BB:CC:DD:EE:FF)
        printf 'Device AA:BB:CC:DD:EE:FF\n\tConnected: yes\n\tPaired: yes\n\tTrusted: yes\n' ;;
      11:22:33:44:55:66)
        printf 'Device 11:22:33:44:55:66\n\tConnected: no\n\tPaired: yes\n\tTrusted: no\n' ;;
      99:88:77:66:55:44)
        printf 'Device 99:88:77:66:55:44\n\tConnected: no\n\tPaired: no\n\tTrusted: no\n' ;;
    esac
    ;;
  show)
    printf 'Controller XX:XX:XX:XX:XX:XX\n  Powered: yes\n' ;;
  power|pair|trust|connect|disconnect|remove)
    exit 0 ;;
esac
MOCK
chmod +x "$MOCK_DIR/bluetoothctl"
export PATH="$MOCK_DIR:$PATH"

# ── Core tests ────────────────────────────────────────────────────────────────

# list: pipe-delimited format
output=$("$BTCTL" list)
assert_eq "list: line count" "3" "$(echo "$output" | wc -l | tr -d ' ')"
assert_eq "list: first MAC"  "AA:BB:CC:DD:EE:FF" "$(echo "$output" | head -1 | cut -d'|' -f1)"
assert_eq "list: first NAME" "Fone JBL"          "$(echo "$output" | head -1 | cut -d'|' -f2)"
assert_eq "list: first CONNECTED" "yes"          "$(echo "$output" | head -1 | cut -d'|' -f3)"
assert_eq "list: first PAIRED"    "yes"          "$(echo "$output" | head -1 | cut -d'|' -f4)"
assert_eq "list: first TRUSTED"   "yes"          "$(echo "$output" | head -1 | cut -d'|' -f5)"

# list --paired: only devices with PAIRED=yes
output=$("$BTCTL" list --paired)
assert_eq "list --paired: count" "2" "$(echo "$output" | wc -l | tr -d ' ')"
assert_eq "list --paired: no Speaker Anker" "" "$(echo "$output" | grep 'Speaker Anker' || true)"

# list --available: only devices with PAIRED=no
output=$("$BTCTL" list --available)
assert_eq "list --available: count" "1" "$(echo "$output" | wc -l | tr -d ' ')"
assert_eq "list --available: MAC" "99:88:77:66:55:44" "$(echo "$output" | cut -d'|' -f1)"

# connected: only CONNECTED=yes
output=$("$BTCTL" connected)
assert_eq "connected: count" "1" "$(echo "$output" | wc -l | tr -d ' ')"
assert_eq "connected: MAC"   "AA:BB:CC:DD:EE:FF" "$(echo "$output" | cut -d'|' -f1)"

# power status
assert_eq "power status" "yes" "$("$BTCTL" power status)"

# exit codes
assert_exit "unknown command → exit 2"  2 "$BTCTL" notacommand
assert_exit "power bad arg → exit 2"    2 "$BTCTL" power badarg
assert_exit "pair no MAC → exit 2"      2 "$BTCTL" pair
assert_exit "connect no MAC → exit 2"   2 "$BTCTL" connect
assert_exit "disconnect no MAC → exit 2" 2 "$BTCTL" disconnect
assert_exit "remove no MAC → exit 2"    2 "$BTCTL" remove
assert_exit "info no MAC → exit 2"      2 "$BTCTL" info

# ── Device op tests ───────────────────────────────────────────────────────────

assert_exit "pair <MAC> → exit 0"       0 "$BTCTL" pair       AA:BB:CC:DD:EE:FF
assert_exit "connect <MAC> → exit 0"    0 "$BTCTL" connect    AA:BB:CC:DD:EE:FF
assert_exit "disconnect <MAC> → exit 0" 0 "$BTCTL" disconnect AA:BB:CC:DD:EE:FF
assert_exit "remove <MAC> → exit 0"     0 "$BTCTL" remove     AA:BB:CC:DD:EE:FF
assert_exit "scan → exit 0"             0 "$BTCTL" scan 0

# info returns output
output=$("$BTCTL" info AA:BB:CC:DD:EE:FF)
assert_eq "info: contains Connected" "yes" "$(echo "$output" | grep -o 'Connected: yes' | cut -d' ' -f2 || true)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

Make it executable:
```bash
chmod +x tests/test_btctl.sh
```

- [ ] **Step 2: Run tests — verify they all fail**

```bash
cd /home/vinicius.teixiera/.dotfiles
bash tests/test_btctl.sh 2>&1 | tail -20
```

Expected: many FAIL lines (btctl doesn't have the new commands yet), script exits non-zero.

---

## Task 2: Rewrite `btctl.sh` core and pass all tests

**Files:**
- Rewrite: `scripts/.scripts/btctl.sh`

- [ ] **Step 3: Replace btctl.sh with new implementation**

Overwrite `scripts/.scripts/btctl.sh` entirely:

```bash
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
    info=$(bluetoothctl info "$mac" 2>/dev/null)
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

cmd_scan() {
  local t=${1:-$SCAN_TIME}
  (
    printf 'power on\n'
    printf 'scan on\n'
    sleep "$t"
    printf 'scan off\n'
    printf 'exit\n'
  ) | bluetoothctl >/dev/null 2>&1 || true
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
```

- [ ] **Step 4: Run tests — verify all pass**

```bash
bash tests/test_btctl.sh
```

Expected output ends with:
```
Results: 26 passed, 0 failed
```

If any test fails, read the FAIL output and fix `btctl.sh` before continuing.

- [ ] **Step 5: Commit**

```bash
git add scripts/.scripts/btctl.sh tests/test_btctl.sh
git commit -m "feat: rewrite btctl as non-interactive CLI with pipe-delimited output"
```

---

## Task 3: Create `rofi-bluetooth.sh`

**Files:**
- Create: `scripts/.scripts/rofi-bluetooth.sh`

- [ ] **Step 6: Write syntax + MAC extraction test**

Add a new test file `tests/test_rofi_bluetooth.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/.scripts/rofi-bluetooth.sh"

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    echo "  expected: [$expected]"
    echo "  actual:   [$actual]"
    FAIL=$((FAIL + 1))
  fi
}

# Syntax check
bash -n "$SCRIPT" && echo "PASS: syntax check" && PASS=$((PASS+1)) \
                  || { echo "FAIL: syntax check"; FAIL=$((FAIL+1)); }

# MAC extraction: "Name (MAC)" → MAC
extract_mac() { sed -E 's/.*\(([^)]+)\)/\1/'; }
assert_eq "extract simple MAC"     "AA:BB:CC:DD:EE:FF" \
  "$(echo 'Fone JBL (AA:BB:CC:DD:EE:FF)' | extract_mac)"
assert_eq "extract multi-word name" "11:22:33:44:55:66" \
  "$(echo 'Mouse Logitech Pro X (11:22:33:44:55:66)' | extract_mac)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

Make it executable:
```bash
chmod +x tests/test_rofi_bluetooth.sh
```

Run — it should fail on syntax check (file doesn't exist yet):
```bash
bash tests/test_rofi_bluetooth.sh 2>&1 | tail -5
```

Expected: `FAIL: syntax check`, exits non-zero.

- [ ] **Step 7: Create rofi-bluetooth.sh**

Create `scripts/.scripts/rofi-bluetooth.sh`:

```bash
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
```

Make it executable:
```bash
chmod +x scripts/.scripts/rofi-bluetooth.sh
```

- [ ] **Step 8: Run tests — verify all pass**

```bash
bash tests/test_rofi_bluetooth.sh
```

Expected:
```
PASS: syntax check
PASS: extract simple MAC
PASS: extract multi-word name

Results: 3 passed, 0 failed
```

- [ ] **Step 9: Commit**

```bash
git add scripts/.scripts/rofi-bluetooth.sh tests/test_rofi_bluetooth.sh
git commit -m "feat: add rofi-bluetooth UI controller with xdotool positioning"
```

---

## Task 4: Add bluetooth module to Polybar

**Files:**
- Modify: `polybar/.config/polybar/config.ini`

- [ ] **Step 10: Add bluetooth module definition**

In `polybar/.config/polybar/config.ini`, add the following block after the `[module/battery]` section (around line 173):

```ini
[module/bluetooth]
type = custom/script
exec = bash -c 'dev=$(~/.scripts/btctl.sh connected | cut -d"|" -f2 | head -1); [ -n "$dev" ] && printf "󰂯 %s" "$dev" || echo "󰂲"'
interval = 5
label = %output%
click-left = ~/.scripts/rofi-bluetooth.sh
```

- [ ] **Step 11: Add bluetooth to modules-right**

In `polybar/.config/polybar/config.ini`, change line 49 from:

```ini
modules-right = xkblayout net-check network pulseaudio filesystem cpu memory battery date 
```

to:

```ini
modules-right = xkblayout net-check network bluetooth pulseaudio filesystem cpu memory battery date
```

- [ ] **Step 12: Verify polybar config syntax**

```bash
grep -n "bluetooth" polybar/.config/polybar/config.ini
```

Expected output:
```
49:modules-right = xkblayout net-check network bluetooth pulseaudio filesystem cpu memory battery date
175:[module/bluetooth]
```

- [ ] **Step 13: Commit**

```bash
git add polybar/.config/polybar/config.ini
git commit -m "feat: add bluetooth module to polybar"
```

---

## Task 5: Update i3 config and setup.sh

**Files:**
- Modify: `i3/.config/i3/config`
- Modify: `scripts/.scripts/setup.sh`

- [ ] **Step 14: Add Rofi floating rules to i3 config**

In `i3/.config/i3/config`, add the following two lines at the end of the file (after line 201):

```
for_window [class="Rofi"] floating enable
for_window [class="Rofi"] border none
```

- [ ] **Step 15: Verify i3 config**

```bash
grep -n "Rofi" i3/.config/i3/config
```

Expected:
```
203:for_window [class="Rofi"] floating enable
204:for_window [class="Rofi"] border none
```

- [ ] **Step 16: Add xdotool to setup.sh**

In `scripts/.scripts/setup.sh`, change line 7 from:

```bash
sudo apt install -y fzf stow xclip ripgrep tmux i3 libx11-dev feh rofi \
```

to:

```bash
sudo apt install -y fzf stow xclip ripgrep tmux i3 libx11-dev feh rofi xdotool \
```

- [ ] **Step 17: Verify setup.sh**

```bash
grep "xdotool" scripts/.scripts/setup.sh
```

Expected:
```
sudo apt install -y fzf stow xclip ripgrep tmux i3 libx11-dev feh rofi xdotool \
```

- [ ] **Step 18: Commit**

```bash
git add i3/.config/i3/config scripts/.scripts/setup.sh
git commit -m "feat: add rofi floating rules to i3 and xdotool to setup deps"
```

---

## Task 6: End-to-end smoke test

- [ ] **Step 19: Run full test suite**

```bash
bash tests/test_btctl.sh && bash tests/test_rofi_bluetooth.sh
```

Expected: all tests pass, both scripts exit 0.

- [ ] **Step 20: Verify btctl.sh is executable and symlinked**

```bash
ls -la ~/.scripts/btctl.sh
~/.scripts/btctl.sh help
```

Expected: symlink points into dotfiles, `help` output lists all commands.

- [ ] **Step 21: Manual smoke test (requires bluetooth adapter)**

```bash
~/.scripts/btctl.sh power status        # prints yes or no
~/.scripts/btctl.sh list                # prints MAC|NAME|... lines or empty
~/.scripts/btctl.sh connected           # prints connected devices or empty
```

- [ ] **Step 22: Reload polybar**

```bash
~/.scripts/launch-polybar.sh
```

Verify the bluetooth icon `󰂲` appears in the bar and left-click opens the Rofi menu at cursor position.

- [ ] **Step 23: Reload i3 config**

Press `Super+Shift+C` (i3 reload) to apply the new `for_window` rules.
