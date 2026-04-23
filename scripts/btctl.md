btctl - CLI wrapper for bluetoothctl

Installation
- Use stow from ~/.dotfiles: stow scripts
- Or manually: cp scripts/.scripts/btctl.sh ~/.scripts/btctl.sh && chmod +x ~/.scripts/btctl.sh
- Optional alias in ~/.bash_aliases: alias btctl='~/.scripts/btctl.sh'

Usage
btctl <command>

Commands
  power on|off|status              Toggle or check bluetooth adapter
  list [--paired|--available]      List all/paired/unpaired devices
  connected                        List connected devices
  scan [seconds]                   Scan for nearby devices (default: 5s)
  pair <MAC>                       Pair and trust a device (no auto-connect)
  connect <MAC>                    Connect to a paired device
  disconnect <MAC>                 Disconnect a device
  remove <MAC>                     Remove/unpair a device
  info <MAC>                       Show raw device info

Output format (list and connected)
  MAC|NAME|CONNECTED|PAIRED|TRUSTED

  Example:
  AA:BB:CC:DD:EE:FF|Fone JBL|yes|yes|yes

  power status outputs a single word: yes or no

Notes
- pair does NOT auto-connect; call connect separately after pairing
- scan populates bluetoothctl's device cache; use list --available afterwards
- list --available shows unpaired devices (candidates for pairing)
- list --paired shows paired devices
