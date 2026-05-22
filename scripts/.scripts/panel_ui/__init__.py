#!/usr/bin/env python3
"""Shared GTK3 panel UI components — imported by bt-panel and nw-panel."""

import subprocess
from typing import List, Callable, Optional

try:
    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gtk, Gdk, GLib, Pango
    _GTK_AVAILABLE = True
except (ImportError, ValueError):
    _GTK_AVAILABLE = False

POLYBAR_HEIGHT = 27

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
    background-color: #6272a4;
    background-image: none;
    color: #f8f8f2;
    border: none;
    border-radius: 4px;
    padding: 2px 10px;
    font-size: 12px;
    box-shadow: none;
}
button:hover {
    background-color: #7c8fbf;
    background-image: none;
}
button.power-on {
    background-color: #50fa7b;
    background-image: none;
    color: #282a36;
}
button.power-on:hover {
    background-color: #69fb8e;
    background-image: none;
}
button.power-off {
    background-color: #ff5555;
    background-image: none;
    color: #f8f8f2;
}
button.power-off:hover {
    background-color: #ff6e6e;
    background-image: none;
}
button.scan {
    background-color: #6272a4;
    background-image: none;
    color: #f8f8f2;
}
button.scan:disabled {
    background-color: #44475a;
    background-image: none;
    color: #6272a4;
}
separator {
    background-color: #44475a;
    min-height: 1px;
}
"""


def apply_css() -> None:
    provider = Gtk.CssProvider()
    provider.load_from_data(PANEL_CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )


def get_mouse_position():
    result = subprocess.run(
        ["xdotool", "getmouselocation", "--shell"],
        capture_output=True, text=True,
    )
    pos = {}
    for line in result.stdout.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            pos[k.strip()] = int(v.strip())
    return pos.get("X", 0), pos.get("Y", 0)


def build_separator() -> "Gtk.Separator":
    return Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)


def build_header(icon: str, title: str, power_on: bool, on_toggle: Callable) -> "Gtk.Box":
    hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    hbox.set_margin_start(4)
    hbox.set_margin_end(4)
    hbox.pack_start(Gtk.Label(label=icon), False, False, 0)
    hbox.pack_start(Gtk.Label(label=title), False, False, 0)
    btn = Gtk.Button(label="ON" if power_on else "OFF")
    btn.get_style_context().add_class("power-on" if power_on else "power-off")
    btn.connect("clicked", on_toggle)
    hbox.pack_end(btn, False, False, 0)
    return hbox


def build_row(
    name: str,
    status_text: str,
    is_connected: bool,
    badges: List[str],
    action_label: str,
    on_action: Callable,
) -> "Gtk.Box":
    """Generic device/network row. on_action(button, error_label) is called on click."""
    vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
    vbox.set_margin_start(4)
    vbox.set_margin_end(4)

    name_label = Gtk.Label(label=name, xalign=0)
    name_label.get_style_context().add_class("device-name")
    vbox.pack_start(name_label, False, False, 0)

    status_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
    status_label = Gtk.Label(label=status_text, xalign=0)
    status_label.get_style_context().add_class(
        "status-connected" if is_connected else "status-disconnected"
    )
    status_hbox.pack_start(status_label, False, False, 0)
    for badge_text in badges:
        badge = Gtk.Label(label=badge_text)
        badge.get_style_context().add_class("badge")
        status_hbox.pack_start(badge, False, False, 0)
    vbox.pack_start(status_hbox, False, False, 0)

    action_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
    error_label = Gtk.Label(label="", xalign=0)
    error_label.get_style_context().add_class("error")
    error_label.set_no_show_all(True)
    btn = Gtk.Button(label=action_label)
    btn.connect("clicked", lambda b: on_action(b, error_label))
    action_hbox.pack_end(btn, False, False, 0)
    vbox.pack_start(action_hbox, False, False, 0)
    vbox.pack_start(error_label, False, False, 0)

    return vbox


def build_footer_button(label: str, on_click: Callable) -> "Gtk.Button":
    btn = Gtk.Button(label=label)
    btn.get_style_context().add_class("scan")
    btn.set_halign(Gtk.Align.CENTER)
    btn.connect("clicked", on_click)
    return btn


def show_password_dialog(parent: "Gtk.Window", ssid: str) -> Optional[str]:
    dialog = Gtk.Dialog(title=f"Connect to {ssid}", transient_for=parent, modal=True)
    dialog.add_buttons(
        Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
        Gtk.STOCK_OK, Gtk.ResponseType.OK,
    )
    content = dialog.get_content_area()
    content.set_spacing(8)
    content.set_border_width(12)
    content.pack_start(Gtk.Label(label=f'Password for "{ssid}":', xalign=0), False, False, 0)
    entry = Gtk.Entry()
    entry.set_visibility(False)
    entry.set_input_purpose(Gtk.InputPurpose.PASSWORD)
    entry.connect("activate", lambda _: dialog.response(Gtk.ResponseType.OK))
    content.pack_start(entry, False, False, 0)
    dialog.show_all()
    response = dialog.run()
    password = entry.get_text() if response == Gtk.ResponseType.OK else None
    dialog.destroy()
    return password


class BasePanelWindow(Gtk.Window):
    """Base GTK window: Dracula-themed popup anchored above polybar, dismissed on focus loss."""

    def __init__(self):
        super().__init__()
        self._mouse_x, _ = get_mouse_position()
        self._positioned = False
        self.set_decorated(False)
        self.set_type_hint(Gdk.WindowTypeHint.POPUP_MENU)
        self.set_keep_above(True)
        self.set_resizable(False)
        self.set_border_width(8)
        self.connect("focus-out-event", lambda *_: Gtk.main_quit())
        self.connect("size-allocate", self._on_size_allocate)
        self._root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self._root.set_margin_top(4)
        self._root.set_margin_bottom(4)
        self.add(self._root)

    def _on_size_allocate(self, widget, allocation):
        if self._positioned:
            return
        screen = Gdk.Screen.get_default()
        x = self._mouse_x - allocation.width // 2
        y = screen.get_height() - POLYBAR_HEIGHT - allocation.height
        x = max(0, min(x, screen.get_width() - allocation.width))
        self.move(x, y)
        self._positioned = True

    def _refresh_root(self, *widgets):
        """Clear, replace content, and reposition on next size-allocate."""
        self._positioned = False
        for child in self._root.get_children():
            self._root.remove(child)
        for w in widgets:
            self._root.pack_start(w, False, False, 0)
        self._root.show_all()
