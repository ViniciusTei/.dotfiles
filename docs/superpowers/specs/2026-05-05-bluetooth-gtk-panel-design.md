# Bluetooth GTK3 Panel Design

**Date:** 2026-05-05

## Overview

Replace the Rofi-based bluetooth UI (`rofi-bluetooth.sh`) with a Python GTK3 status panel triggered by the Polybar bluetooth icon click. The panel shows paired devices with their connection status and inline action buttons, and auto-dismisses on focus loss.

---

## Architecture

```
Polybar (click-left)
    ↓
~/.scripts/bt-panel.py     ← GTK3 panel (replaces rofi-bluetooth.sh)
    ↓
~/.scripts/btctl.sh        ← unchanged CLI backend
    ↓
bluetoothctl
```

### File Changes

| Action | Path |
|---|---|
| Create | `scripts/.scripts/bt-panel.py` |
| Modify | `polybar/.config/polybar/config.ini` — `click-left` points to `bt-panel.py` |
| Delete | `scripts/.scripts/rofi-bluetooth.sh` |
| Modify | `scripts/.scripts/setup.sh` — add `python3-gi` to deps |

---

## Section 1: Window

- `gtk.Window` with `set_decorated(False)` and type hint `Gdk.WindowTypeHint.POPUP_MENU`
- `POPUP_MENU` type hint causes i3 to float the window automatically — no `for_window` rule needed
- Auto-dismisses via `focus-out-event` handler that calls `gtk.main_quit()`
- Positioned above the cursor: mouse coordinates from `xdotool getmouselocation`. Final position is set in a `size-allocate` signal handler — fired by GTK after it calculates the window dimensions — placing the window's bottom edge at `(mouse_x, screen_height - polybar_height)` so it sits flush above the polybar regardless of how many device rows are rendered

---

## Section 2: Layout

Vertical stack inside a `gtk.Box`:

```
┌─────────────────────────────────┐
│  󰂯 Bluetooth          [ON/OFF]  │  ← header: power toggle button
├─────────────────────────────────┤
│  JBL Fone                       │  ← device row
│  ● Connected  [Paired][Trusted] │
│                    [Disconnect] │
├─────────────────────────────────┤
│  Sony WH-1000                   │  ← device row
│  ○ Disconnected  [Paired]       │
│                      [Connect]  │
├─────────────────────────────────┤
│         [Scan for devices]      │  ← footer
└─────────────────────────────────┘
```

**Header:** bluetooth icon + "Bluetooth" label on the left; power ON/OFF toggle button on the right.

**Device row (per paired device):**
- Line 1: device name (bold)
- Line 2: colored status dot + "Connected"/"Disconnected" label + small [Paired] and [Trusted] badge labels
- Line 3: right-aligned Connect or Disconnect button depending on current state
- Error label (hidden by default): shown below line 3 if a `btctl.sh` call fails

**Footer:** centered "Scan for devices" button. Disabled and relabeled "Scanning…" during a 5-second scan, then re-enabled and device list refreshed.

When bluetooth power is off, device rows and footer are hidden — only the header is shown.

---

## Section 3: Styling

GTK CSS applied at startup, matching the Dracula palette used in polybar:

| Element | Color |
|---|---|
| Window background | `#282a36` |
| Primary text | `#f8f8f2` |
| Connected status dot/label | `#50fa7b` (green) |
| Disconnected status dot/label | `#6272a4` (indigo) |
| Badge labels (Paired, Trusted) | `#44475a` bg, `#f8f8f2` text |
| Action buttons | `#bd93f8` bg (purple), `#282a36` text |
| Power ON button | `#50fa7b` (green) |
| Power OFF button | `#ff5555` (red) |
| Scan button | `#ffb86c` (orange) |
| Error label | `#ff5555` (red) |

Border-radius: 6px on the window, 4px on buttons and badges.

---

## Section 4: Data Flow

**Startup sequence (each polybar click launches a fresh process):**
1. Read mouse position via `xdotool getmouselocation`
2. Run `btctl.sh power status` and `btctl.sh list --paired` via `subprocess.run` (sequential — fast enough, avoids thread complexity)
3. Build GTK widget tree from results
4. Show window, position it above cursor
5. Call `gtk.main()` — event loop runs until focus-out or action completes

**Interaction handlers:**

| User action | `btctl.sh` call | UI update |
|---|---|---|
| Power toggle | `power on` or `power off` | Rebuild device list (show/hide rows) |
| Connect button | `connect <MAC>` | Disable button, show spinner label → update row state on return |
| Disconnect button | `disconnect <MAC>` | Disable button, show spinner label → update row state on return |
| Scan button | `scan 5` then `list --paired` | Disable + relabel button → refresh device list on return |
| Click outside window | — | `gtk.main_quit()` via focus-out handler |

All `btctl.sh` calls run synchronously in the main thread, scheduled via `GLib.idle_add` so the window is painted before the subprocess blocks. The brief UI freeze (typically < 500ms) is acceptable for a bluetooth panel — no threading needed. On non-zero exit, an inline error label is shown below the relevant device row — no external notifications.

---

## Section 5: Dependencies

- `python3-gi` (PyGObject) — GTK3 Python bindings
- `gir1.2-gtk-3.0` — GTK3 GObject introspection data
- `xdotool` — mouse position (already a dep from the rofi implementation)
- `python3` — already present

`setup.sh` adds `python3-gi gir1.2-gtk-3.0` to the apt install list.

---

## Out of Scope

- Unpaired/available device scanning UI (scan populates btctl cache; only paired devices are shown in the panel)
- Pairing new devices from the panel
- Battery level display
- System tray / persistent daemon mode
