#!/usr/bin/env python3
"""Bluetooth GTK3 status panel — launched by Polybar on bluetooth icon click."""

import os
import subprocess
import sys
from dataclasses import dataclass
from typing import List

# GTK imports (skipped when running under headless unit tests via stub)
try:
    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gtk, Gdk, GLib, Pango
    _GTK_AVAILABLE = True
except (ImportError, ValueError):
    _GTK_AVAILABLE = False

BTCTL = os.path.expanduser("~/.scripts/btctl.sh")
POLYBAR_HEIGHT = 27  # pixels; matches polybar config height


@dataclass
class BtDevice:
    mac: str
    name: str
    connected: bool
    paired: bool
    trusted: bool

    @classmethod
    def from_line(cls, line: str) -> "BtDevice":
        # Peel the 3 fixed boolean fields from the right, leaving "MAC|name" on the left
        head, connected, paired, trusted = line.rsplit("|", 3)
        mac, name = head.split("|", 1)
        return cls(
            mac=mac,
            name=name,
            connected=connected == "yes",
            paired=paired == "yes",
            trusted=trusted == "yes",
        )


def parse_devices(output: str) -> List[BtDevice]:
    """Parse multi-line btctl.sh list output into BtDevice list."""
    return [
        BtDevice.from_line(line)
        for line in output.splitlines()
        if line.strip()
    ]


class BtBackend:
    def __init__(self, btctl_path: str = BTCTL):
        self._btctl = btctl_path

    def _run(self, *args) -> subprocess.CompletedProcess:
        try:
            return subprocess.run(
                [self._btctl, *args],
                capture_output=True,
                text=True,
            )
        except FileNotFoundError:
            raise RuntimeError(f"btctl not found: {self._btctl}") from None

    def power_status(self) -> bool:
        result = self._run("power", "status")
        return result.stdout.strip() == "yes"

    def list_paired(self) -> List[BtDevice]:
        result = self._run("list", "--paired")
        return parse_devices(result.stdout)

    def set_power(self, on: bool) -> bool:
        result = self._run("power", "on" if on else "off")
        return result.returncode == 0

    def connect(self, mac: str) -> bool:
        result = self._run("connect", mac)
        return result.returncode == 0

    def disconnect(self, mac: str) -> bool:
        result = self._run("disconnect", mac)
        return result.returncode == 0

    def scan_and_list(self) -> List[BtDevice]:
        self._run("scan", "5")  # best-effort; ignore failure, existing paired devices still listed
        result = self._run("list", "--paired")
        return parse_devices(result.stdout)


PANEL_CSS = b"""
window {
    background-color: #282a36;
    border-radius: 6px;
    border: 1px solid #44475a;
}
label {
    color: #f8f8f2;
    font-size: 13px;
}
label.device-name {
    font-weight: bold;
    font-size: 14px;
}
label.status-connected {
    color: #50fa7b;
}
label.status-disconnected {
    color: #6272a4;
}
label.badge {
    background-color: #44475a;
    color: #f8f8f2;
    border-radius: 4px;
    padding: 1px 6px;
    font-size: 11px;
}
label.error {
    color: #ff5555;
    font-size: 12px;
}
button {
    background-color: #bd93f8;
    color: #282a36;
    border: none;
    border-radius: 4px;
    padding: 2px 10px;
    font-size: 12px;
}
button:hover {
    background-color: #caa9fa;
}
button.power-on {
    background-color: #50fa7b;
    color: #282a36;
}
button.power-off {
    background-color: #ff5555;
    color: #f8f8f2;
}
button.scan {
    background-color: #ffb86c;
    color: #282a36;
}
button.scan:disabled {
    background-color: #6272a4;
    color: #f8f8f2;
}
separator {
    background-color: #44475a;
    min-height: 1px;
}
"""


def apply_css():
    provider = Gtk.CssProvider()
    provider.load_from_data(PANEL_CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )


def get_mouse_position():
    """Return (x, y) of current mouse cursor using xdotool."""
    result = subprocess.run(
        ["xdotool", "getmouselocation", "--shell"],
        capture_output=True, text=True
    )
    pos = {}
    for line in result.stdout.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            pos[k.strip()] = int(v.strip())
    return pos.get("X", 0), pos.get("Y", 0)


class BtPanel(Gtk.Window):
    def __init__(self, backend: BtBackend):
        super().__init__()
        self._backend = backend
        self._mouse_x, _ = get_mouse_position()

        # Window chrome
        self.set_decorated(False)
        self.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU)
        self.set_keep_above(True)
        self.set_resizable(False)
        self.set_border_width(8)
        self._positioned = False

        # Auto-dismiss on focus loss
        self.connect("focus-out-event", lambda *_: Gtk.main_quit())

        # Position after GTK calculates window size
        self.connect("size-allocate", self._on_size_allocate)

        # Root container
        self._root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self._root.set_margin_top(4)
        self._root.set_margin_bottom(4)
        self.add(self._root)

    def _on_size_allocate(self, widget, allocation):
        if self._positioned:
            return
        screen = Gdk.Screen.get_default()
        screen_height = screen.get_height()
        x = self._mouse_x - allocation.width // 2
        y = screen_height - POLYBAR_HEIGHT - allocation.height
        # Keep panel on-screen horizontally
        x = max(0, min(x, screen.get_width() - allocation.width))
        self.move(x, y)
        self._positioned = True

    def build_header(self, power_on: bool) -> Gtk.Box:
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        hbox.set_margin_start(4)
        hbox.set_margin_end(4)

        icon = Gtk.Label(label="󰂯")
        title = Gtk.Label(label="Bluetooth")
        hbox.pack_start(icon, False, False, 0)
        hbox.pack_start(title, False, False, 0)

        btn = Gtk.Button(label="ON" if power_on else "OFF")
        btn.get_style_context().add_class("power-on" if power_on else "power-off")
        btn.connect("clicked", self._on_power_toggle)
        hbox.pack_end(btn, False, False, 0)

        return hbox

    def build_separator(self) -> Gtk.Separator:
        return Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)

    def build_device_row(self, device: BtDevice) -> Gtk.Box:
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        vbox.set_margin_start(4)
        vbox.set_margin_end(4)

        # Line 1: device name
        name_label = Gtk.Label(label=device.name, xalign=0)
        name_label.get_style_context().add_class("device-name")
        vbox.pack_start(name_label, False, False, 0)

        # Line 2: status dot + badges
        status_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        dot = "●" if device.connected else "○"
        status_text = "Connected" if device.connected else "Disconnected"
        status_label = Gtk.Label(label=f"{dot} {status_text}", xalign=0)
        css_class = "status-connected" if device.connected else "status-disconnected"
        status_label.get_style_context().add_class(css_class)
        status_hbox.pack_start(status_label, False, False, 0)

        if device.paired:
            badge = Gtk.Label(label="Paired")
            badge.get_style_context().add_class("badge")
            status_hbox.pack_start(badge, False, False, 0)
        if device.trusted:
            badge = Gtk.Label(label="Trusted")
            badge.get_style_context().add_class("badge")
            status_hbox.pack_start(badge, False, False, 0)

        vbox.pack_start(status_hbox, False, False, 0)

        # Line 3: action button (right-aligned) + error label (hidden by default)
        action_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        error_label = Gtk.Label(label="", xalign=0)
        error_label.get_style_context().add_class("error")
        error_label.set_no_show_all(True)

        if device.connected:
            btn = Gtk.Button(label="Disconnect")
            btn.connect("clicked", self._on_disconnect, device.mac, error_label)
        else:
            btn = Gtk.Button(label="Connect")
            btn.connect("clicked", self._on_connect, device.mac, error_label)

        action_hbox.pack_end(btn, False, False, 0)
        vbox.pack_start(action_hbox, False, False, 0)
        vbox.pack_start(error_label, False, False, 0)

        return vbox

    def build_footer(self) -> Gtk.Button:
        btn = Gtk.Button(label="Scan for devices")
        btn.get_style_context().add_class("scan")
        btn.set_halign(Gtk.Align.CENTER)
        btn.connect("clicked", self._on_scan)
        return btn

    def populate(self, power_on: bool, devices: List[BtDevice]):
        # Clear existing children
        for child in self._root.get_children():
            self._root.remove(child)

        self._root.pack_start(self.build_header(power_on), False, False, 0)

        if power_on:
            for device in devices:
                self._root.pack_start(self.build_separator(), False, False, 4)
                self._root.pack_start(self.build_device_row(device), False, False, 0)

            self._root.pack_start(self.build_separator(), False, False, 4)
            self._root.pack_start(self.build_footer(), False, False, 0)

        self._root.show_all()

    # ── Action handlers (implemented in Task 3) ───────────────────────────
    def _on_power_toggle(self, button: Gtk.Button):
        pass

    def _on_connect(self, button: Gtk.Button, mac: str, err_label: Gtk.Label):
        pass

    def _on_disconnect(self, button: Gtk.Button, mac: str, err_label: Gtk.Label):
        pass

    def _on_scan(self, button: Gtk.Button):
        pass
