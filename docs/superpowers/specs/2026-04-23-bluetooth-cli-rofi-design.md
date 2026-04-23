# Bluetooth CLI + Rofi UI Design

**Date:** 2026-04-23

## Overview

Refactor `btctl.sh` into a non-interactive, scriptable CLI and add a Rofi-based UI layer triggered by a Polybar click. The goal is a clean separation between the CLI API (btctl) and the UI controller (rofi-bluetooth.sh).

---

## Architecture

```
Polybar (click-left)
    ↓
~/.scripts/rofi-bluetooth.sh   ← UI controller, xdotool positioning
    ↓
~/.scripts/btctl.sh            ← CLI API, no interactivity
    ↓
bluetoothctl
```

### File Locations

| File | Dotfiles path | Stowed to |
|---|---|---|
| CLI | `scripts/.scripts/btctl.sh` | `~/.scripts/btctl.sh` |
| UI controller | `scripts/.scripts/rofi-bluetooth.sh` | `~/.scripts/rofi-bluetooth.sh` |
| Polybar config | `polybar/.config/polybar/config.ini` | `~/.config/polybar/config.ini` |
| i3 config | `i3/.config/i3/config` | `~/.config/i3/config` |

Both scripts land in the existing `scripts` stow package — no new packages needed.

---

## Section 1: `btctl` CLI Refactor

### Commands

```bash
btctl power on|off|status
btctl list                   # all known devices
btctl list --paired          # paired=yes only
btctl list --available       # paired=no (unpaired candidates from recent scan)
btctl connected              # connected=yes only
btctl scan [seconds]         # populates bluetoothctl device cache, no output
btctl pair <MAC>             # pair + trust only (no auto-connect)
btctl connect <MAC>
btctl disconnect <MAC>
btctl remove <MAC>
btctl info <MAC>             # raw bluetoothctl info output (human-readable, not pipe-delimited)
```

### Output Format

One line per device, pipe-delimited:

```
MAC|NAME|CONNECTED|PAIRED|TRUSTED
```

Example:
```
AA:BB:CC:DD:EE:FF|Fone JBL|yes|yes|yes
```

`btctl power status` prints a single word: `yes` or `no`.

`btctl scan` prints nothing — it only populates the bluetoothctl device cache. Callers use `btctl list --available` afterwards.

### Core Function

```bash
get_devices() {
  bluetoothctl devices | while read -r _ mac name; do
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    connected=$(echo "$info" | grep -q "Connected: yes" && echo yes || echo no)
    paired=$(echo "$info"    | grep -q "Paired: yes"    && echo yes || echo no)
    trusted=$(echo "$info"   | grep -q "Trusted: yes"   && echo yes || echo no)
    echo "$mac|$name|$connected|$paired|$trusted"
  done
}
```

### Exit Codes

| Situation | Code |
|---|---|
| Success | 0 |
| Operational failure (e.g. pair failed) | 1 |
| Invalid usage (bad command/args) | 2 |

### Removed

- `select_device_interactive` — all interactivity moves to `rofi-bluetooth.sh`
- `fzf` dependency
- `read` prompts

---

## Section 2: `rofi-bluetooth.sh` UI Controller

### Mouse Positioning

```bash
eval "$(xdotool getmouselocation --shell)"
# Opens Rofi above the Polybar click point
rofi -dmenu -p "Bluetooth" -location 0 -xoffset "$X" -yoffset "$((Y - 200))"
```

The `-200` y-offset lifts the menu above the polybar. Fine-tune after testing.

### Main Menu

```
Power on/off      ← label is dynamic: "Power off" if on, "Power on" if off
Scan + Pair
Connect
Disconnect
Remove
```

### Device Picker Format

Displayed to the user: `Fone JBL (AA:BB:CC:DD:EE:FF)`

MAC extraction: `sed -E 's/.*\(([^)]+)\)/\1/'`

### Flows

| Selection | Flow |
|---|---|
| Power on/off | `btctl power on/off` → `notify-send` |
| Scan + Pair | `btctl scan 5` → `btctl list --available` → Rofi picker → `btctl pair <MAC>` → `notify-send` |
| Connect | `btctl list --paired` (filters already-connected) → Rofi picker → `btctl connect <MAC>` → `notify-send` |
| Disconnect | `btctl connected` → Rofi picker → `btctl disconnect <MAC>` → `notify-send` |
| Remove | `btctl list --paired` → Rofi picker → `btctl remove <MAC>` → `notify-send` |

### Error Handling

- Non-zero exit from `btctl` → `notify-send` shows error message
- Empty Rofi selection (user dismissed) → silent exit

---

## Section 3: Polybar Integration

Add `bluetooth` to `modules-right` in `config.ini` (before `date`, after `battery`):

```ini
[module/bluetooth]
type = custom/script
exec = bash -c 'dev=$(~/.scripts/btctl.sh connected | cut -d"|" -f2 | head -1); [ -n "$dev" ] && printf "󰂯 %s" "$dev" || echo "󰂲"'
interval = 5
label = %output%
click-left = ~/.scripts/rofi-bluetooth.sh
```

- Connected device: shows `󰂯 Fone JBL`
- Nothing connected: shows `󰂲`

---

## Section 4: i3 Config

Add floating rules so Rofi doesn't tile:

```
for_window [class="Rofi"] floating enable
for_window [class="Rofi"] border none
```

Place near other `for_window` rules or at the end of the window rules section.

---

## Section 5: `setup.sh` Dependency

Add `xdotool` to the existing `apt install` block:

```bash
sudo apt install -y fzf stow xclip ripgrep tmux i3 libx11-dev feh rofi xdotool \
    ...
```

---

## Out of Scope

- DBus-direct bluetooth control
- Scan cache at btctl level (`/tmp/bt_devices.cache`) — deferred as optional improvement
- GTK/PyQt UI
- Bluetooth daemon for continuous state tracking
