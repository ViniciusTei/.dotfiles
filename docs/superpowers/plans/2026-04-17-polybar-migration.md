# Polybar Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace i3status + custom wrapper with Polybar, showing one bar per connected monitor with all existing modules preserved.

**Architecture:** New stow package `polybar/` holds `config.ini`. A `launch-polybar.sh` script detects connected monitors via xrandr and starts one Polybar instance per monitor. Battery notifications move to a standalone `battery-notify.sh` daemon started by the launch script. The i3 `bar {}` block is removed and replaced with `exec_always ~/.scripts/launch-polybar.sh`.

**Tech Stack:** Polybar, PulseAudio, xrandr, xkblayout-state, FiraCode Nerd Font (already installed), GNU Stow.

> **Working directory:** All commands run from `~/.dotfiles` unless stated otherwise.

---

### Task 1: Create battery-notify.sh

**Files:**
- Create: `scripts/.scripts/battery-notify.sh`

- [ ] **Step 1: Create the script**

```bash
cat > scripts/.scripts/battery-notify.sh << 'EOF'
#!/bin/bash

while true; do
    battery_level=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo "N/A")
    battery_status=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo "N/A")

    if [ "$battery_level" != "N/A" ] && [ "$battery_status" != "Charging" ]; then
        case "$battery_level" in
            25) notify-send "Battery Warning" "Battery level is at $battery_level%!" -u low ;;
            15) notify-send "Battery Warning" "Battery level is at $battery_level%!" -u normal ;;
            10) notify-send "Battery Warning" "Battery level is at $battery_level%!" -u critical ;;
            5)  notify-send "Battery Warning" "Battery level is at $battery_level%!" -u critical ;;
        esac
    fi

    sleep 60
done
EOF
chmod +x scripts/.scripts/battery-notify.sh
```

- [ ] **Step 2: Verify syntax**

```bash
bash -n scripts/.scripts/battery-notify.sh
```
Expected: no output (no syntax errors).

- [ ] **Step 3: Commit**

```bash
git add scripts/.scripts/battery-notify.sh
git commit -m "feat: add battery-notify daemon script"
```

---

### Task 2: Create launch-polybar.sh

**Files:**
- Create: `scripts/.scripts/launch-polybar.sh`

- [ ] **Step 1: Create the script**

```bash
cat > scripts/.scripts/launch-polybar.sh << 'EOF'
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
EOF
chmod +x scripts/.scripts/launch-polybar.sh
```

- [ ] **Step 2: Verify syntax**

```bash
bash -n scripts/.scripts/launch-polybar.sh
```
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add scripts/.scripts/launch-polybar.sh
git commit -m "feat: add polybar launch script with multi-monitor support"
```

---

### Task 3: Create polybar stow package and config.ini

**Files:**
- Create: `polybar/.config/polybar/config.ini`

- [ ] **Step 1: Create the directory structure**

```bash
mkdir -p polybar/.config/polybar
```

- [ ] **Step 2: Create config.ini**

```bash
cat > polybar/.config/polybar/config.ini << 'EOF'
[colors]
background = #1e1e2e
foreground = #cdd6f4
good       = #88b090
degraded   = #ccdc90
bad        = #e89393
accent     = #89b4fa

[bar/main]
monitor = ${env:MONITOR:}
width = 100%
height = 27
radius = 0
fixed-center = true

background = ${colors.background}
foreground = ${colors.foreground}

line-size = 0
border-size = 0
padding-left = 1
padding-right = 1
module-margin-left = 1
module-margin-right = 1

font-0 = FiraCode Nerd Font:size=10;2
font-1 = FiraCode Nerd Font Mono:size=10;2

modules-left = i3 xwindow
modules-center = date
modules-right = xkblayout net-check network pulseaudio filesystem cpu memory battery

tray-position = right
tray-padding = 2
cursor-click = pointer

[module/i3]
type = internal/i3
format = <label-state> <label-mode>
index-sort = true
wrapping-scroll = false

label-focused = %index%
label-focused-background = ${colors.accent}
label-focused-foreground = ${colors.background}
label-focused-padding = 2

label-unfocused = %index%
label-unfocused-padding = 2

label-visible = %index%
label-visible-background = ${colors.accent}
label-visible-padding = 2

label-urgent = %index%
label-urgent-background = ${colors.bad}
label-urgent-padding = 2

[module/xwindow]
type = internal/xwindow
label = %title:0:50:...%
label-foreground = ${colors.foreground}

[module/date]
type = internal/date
interval = 1
date = %A, %d/%m/%Y
time = %H:%M
label =  %date%   %time%
label-foreground = ${colors.good}

[module/xkblayout]
type = custom/script
exec = xkblayout-state print %s
interval = 2
label = 󰌌 %output%
label-foreground = ${colors.accent}

[module/net-check]
type = custom/script
exec = ping -c 1 -W 1 8.8.8.8 &>/dev/null && echo "󰈀 online" || echo "󰈀 offline"
interval = 10
label = %output%
label-foreground = ${colors.good}

[module/network]
type = internal/network
interface = wlp43s0
interval = 3

format-connected = <label-connected>
label-connected = 󰤨  %essid%
label-connected-foreground = ${colors.good}

format-disconnected = <label-disconnected>
label-disconnected = 󰤭  desconectado
label-disconnected-foreground = ${colors.bad}

[module/pulseaudio]
type = internal/pulseaudio
format-volume = <label-volume>
label-volume =  %percentage%%
label-volume-foreground = ${colors.foreground}
label-muted = 
label-muted-foreground = ${colors.degraded}

[module/filesystem]
type = internal/fs
interval = 30
mount-0 = /
label-mounted =  %percentage_used%% (%used%/%total%)
label-mounted-foreground = ${colors.foreground}
label-unmounted = %mountpoint% not mounted
label-unmounted-foreground = ${colors.bad}

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.accent}
label = %percentage:2%%
label-foreground = ${colors.foreground}

[module/memory]
type = internal/memory
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.accent}
label = %percentage_used%% (%used%/%total%)
label-foreground = ${colors.foreground}

[module/battery]
type = internal/battery
battery = BAT1
adapter = AC
full-at = 98
poll-interval = 5

format-charging = <label-charging>
label-charging = 󰂄 %percentage%%
label-charging-foreground = ${colors.good}

format-discharging = <animation-discharging> %percentage%%
label-discharging-foreground = ${colors.foreground}

format-full = <label-full>
label-full = 󱊣 Full
label-full-foreground = ${colors.good}

animation-discharging-0 = 󱊡
animation-discharging-1 = 󱊢
animation-discharging-2 = 󱊣
animation-discharging-framerate = 500
EOF
```

- [ ] **Step 3: Verify config syntax**

```bash
polybar --version
# Expected: prints polybar version (confirms polybar is installed)
# If not installed: sudo apt install polybar
```

- [ ] **Step 4: Commit**

```bash
git add polybar/.config/polybar/config.ini
git commit -m "feat: add polybar config with all modules"
```

---

### Task 4: Update i3 config

**Files:**
- Modify: `i3/.config/i3/config`

- [ ] **Step 1: Remove $refresh_i3status variable and bar block**

In `i3/.config/i3/config`, replace the following block:

```
set $refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status
```

With (drop `$refresh_i3status`):

```
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle
```

- [ ] **Step 2: Remove the bar {} block**

Remove this block entirely:

```
bar {
  status_command ~/.scripts/i3status.sh
}
```

- [ ] **Step 3: Add exec_always for polybar launch**

Add after the `exec_always ~/.scripts/monitor-hotplug.sh` line:

```
exec_always ~/.scripts/launch-polybar.sh
```

- [ ] **Step 4: Verify the config**

```bash
i3 -C -c i3/.config/i3/config
```
Expected: `OK` (no config errors).

- [ ] **Step 5: Commit**

```bash
git add i3/.config/i3/config
git commit -m "feat: replace i3bar with polybar launch script"
```

---

### Task 5: Update setup.sh

**Files:**
- Modify: `scripts/.scripts/setup.sh`

- [ ] **Step 1: Add polybar to apt install line**

In `scripts/.scripts/setup.sh`, change:

```bash
sudo apt install fzf stow xclip ripgrep tmux i3 libx11-dev feh rofi
```

To:

```bash
sudo apt install fzf stow xclip ripgrep tmux i3 libx11-dev feh rofi polybar
```

- [ ] **Step 2: Add stow polybar**

After the `stow rofi` line, add:

```bash
stow polybar
```

- [ ] **Step 3: Commit**

```bash
git add scripts/.scripts/setup.sh
git commit -m "chore: add polybar to setup script"
```

---

### Task 6: Remove i3status files

**Files:**
- Delete: `scripts/.scripts/i3status.sh`
- Delete: `i3/.config/i3/i3status.conf`

- [ ] **Step 1: Delete the files**

```bash
git rm scripts/.scripts/i3status.sh
git rm i3/.config/i3/i3status.conf
```

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: remove i3status config and wrapper script"
```

---

### Task 7: Stow and verify

- [ ] **Step 1: Stow the polybar package**

```bash
cd ~/.dotfiles
stow polybar
```
Expected: no errors. Verify: `ls -la ~/.config/polybar/` shows `config.ini` symlinked.

- [ ] **Step 2: Reload i3 or restart**

Press `Mod+Shift+r` to restart i3 in-place, or run:
```bash
i3-msg restart
```

- [ ] **Step 3: Verify polybar is running**

```bash
pgrep -a polybar
```
Expected: one `polybar main` process per connected monitor.

- [ ] **Step 4: Verify all modules display correctly**

Check visually that the bar shows:
- Left: workspace numbers, active window title
- Center: date and time
- Right: keyboard layout, network check (online/offline), wireless SSID, volume %, disk usage, CPU %, memory %, battery %

- [ ] **Step 5: Test volume keys**

Press `XF86AudioRaiseVolume` and `XF86AudioLowerVolume`. The volume module on the bar should update without needing a signal.

- [ ] **Step 6: Commit final stow state if any .stow metadata changed**

```bash
git status
# If .stow files were generated or changed:
git add -A
git commit -m "chore: stow polybar package"
```
