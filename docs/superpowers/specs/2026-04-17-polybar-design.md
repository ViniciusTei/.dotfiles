# Polybar Migration Design

**Date:** 2026-04-17  
**Status:** Approved

## Overview

Migrate the i3 status bar from i3status (with custom wrapper script) to Polybar. Goals: multi-monitor support (one bar per connected monitor), cleaner per-module styling, native pulseaudio reactivity, and maintainable config structure.

## File Changes

| File | Action |
|---|---|
| `polybar/.config/polybar/config.ini` | Create — main Polybar config |
| `scripts/.scripts/launch-polybar.sh` | Create — detects monitors, starts one bar per monitor |
| `scripts/.scripts/battery-notify.sh` | Create — battery notification daemon (extracted from i3status.sh) |
| `i3/.config/i3/config` | Modify — remove `bar {}` block, add `exec_always ~/.scripts/launch-polybar.sh` |
| `scripts/.scripts/i3status.sh` | Remove |
| `i3/.config/i3/i3status.conf` | Remove |

The `polybar/` directory becomes a new stow package managed alongside the existing ones.

## Bar Layout

```
LEFT                          CENTER                RIGHT
[workspaces] [window-title]   [date/time]   [keyboard] [net-check] [wireless] [volume] [disk] [cpu] [memory] [battery]
```

## Modules

| Module | Type | Notes |
|---|---|---|
| workspaces | `internal/i3` | Lists i3 workspaces |
| window-title | `internal/xwindow` | Active window title |
| date/time | `internal/date` | Replaces `tztime local`; format: `%A, %d/%m/%Y  %H:%M` |
| cpu | `internal/cpu` | Native polling |
| memory | `internal/memory` | Native polling |
| disk | `internal/fs` | Mount point `/`, low threshold 20% |
| battery | `internal/battery` | Display only; adapter `AC`, battery `BAT1` |
| volume | `internal/pulseaudio` | Reactive via pulseaudio events; replaces ALSA volume module |
| wireless | `internal/network` | Shows SSID + icon; interface `wlp43s0` |
| keyboard | `custom/script` | `xkblayout-state print %s`, poll interval 2s |
| net-check | `custom/script` | Ping 8.8.8.8, poll interval 10s |

### i3 Config — Volume Keybindings

The `$refresh_i3status` variable and `killall -SIGUSR1 i3status` calls are removed from the volume/mute keybindings. The `internal/pulseaudio` module listens to pulseaudio events directly and updates without signals.

## Multi-Monitor

`launch-polybar.sh` workflow:
1. Kill all existing Polybar instances and wait for them to exit
2. Start `battery-notify.sh` in background (single instance)
3. Query `xrandr` for connected outputs
4. Start one `polybar main` instance per output, passing `MONITOR=$output`

```bash
killall -q polybar
while pgrep -u $UID -x polybar > /dev/null; do sleep 1; done

~/.scripts/battery-notify.sh &

for output in $(xrandr --query | grep ' connected' | awk '{print $1}'); do
    MONITOR=$output polybar main &
done
```

## Battery Notifications

Extracted from `i3status.sh` into `battery-notify.sh`. Runs as a background loop (sleep 60s between checks). Notifies at thresholds: 25% (low), 15% (normal), 10% (critical), 5% (critical). Only notifies when not charging.

## Visual Style

- **Height:** 27px
- **Position:** top
- **Font:** FiraCode Nerd Font 10 (already installed)
- **Background:** `#1e1e2e`
- **Foreground:** `#cdd6f4`
- **Colors (same as current i3status.conf):**
  - Good/normal: `#88b090`
  - Degraded: `#ccdc90`
  - Alert/bad: `#e89393`
  - Icon accent: `#89b4fa`
