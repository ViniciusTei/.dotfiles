#!/usr/bin/env python3
"""Bluetooth GTK3 status panel — launched by Polybar on bluetooth icon click."""

import os
import subprocess
import sys
import threading
from dataclasses import dataclass
from typing import List

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# GTK imports (skipped when running under headless unit tests via stub)
try:
    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gtk, GLib
    import panel_ui
    _GTK_AVAILABLE = True
except (ImportError, ValueError):
    _GTK_AVAILABLE = False

BTCTL = os.path.expanduser("~/.scripts/btctl.sh")


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

    def pair(self, mac: str) -> bool:
        result = self._run("pair", mac)
        return result.returncode == 0

    def scan_and_list(self) -> List[BtDevice]:
        self._run("scan", "5")  # best-effort; ignore failure
        result = self._run("list")  # all devices: paired + newly discovered
        return parse_devices(result.stdout)


class BtPanel(panel_ui.BasePanelWindow):
    def __init__(self, backend: BtBackend):
        super().__init__()
        self._backend = backend

    def populate(self, power_on: bool, devices: List[BtDevice]):
        widgets = [panel_ui.build_header("󰂯", "Bluetooth", power_on, self._on_power_toggle)]

        if power_on:
            for device in devices:
                badges = []
                if device.paired:
                    badges.append("Paired")
                if device.trusted:
                    badges.append("Trusted")

                dot = "●" if device.connected else "○"
                status_text = f"{dot} {'Connected' if device.connected else 'Disconnected'}"

                if device.connected:
                    action_label = "Disconnect"
                    on_action = lambda b, e, mac=device.mac: self._on_disconnect(b, mac, e)
                elif not device.paired:
                    action_label = "Pair"
                    on_action = lambda b, e, mac=device.mac: self._on_pair(b, mac, e)
                else:
                    action_label = "Connect"
                    on_action = lambda b, e, mac=device.mac: self._on_connect(b, mac, e)

                widgets.append(panel_ui.build_separator())
                widgets.append(panel_ui.build_row(
                    name=device.name,
                    status_text=status_text,
                    is_connected=device.connected,
                    badges=badges,
                    action_label=action_label,
                    on_action=on_action,
                ))

            widgets.append(panel_ui.build_separator())
            widgets.append(panel_ui.build_footer_button("Scan for devices", self._on_scan))

        self._refresh_root(*widgets)

    # ── Action handlers ───────────────────────────────────────────────────────
    def _on_power_toggle(self, button: "Gtk.Button"):
        is_on = button.get_label() == "ON"
        button.set_sensitive(False)
        button.set_label("…")

        def _do():
            try:
                ok = self._backend.set_power(not is_on)
            except Exception:
                button.set_label("ON" if is_on else "OFF")
                button.set_sensitive(True)
                return False
            if ok:
                power_on = self._backend.power_status()
                devices = self._backend.list_paired() if power_on else []
                self.populate(power_on, devices)
            else:
                button.set_label("ON" if is_on else "OFF")
                button.set_sensitive(True)
            return False

        GLib.idle_add(_do)

    def _on_connect(self, button: "Gtk.Button", mac: str, err_label: "Gtk.Label"):
        button.set_sensitive(False)
        button.set_label("…")
        err_label.set_text("")
        err_label.hide()

        def _do():
            try:
                ok = self._backend.connect(mac)
            except Exception as exc:
                button.set_label("Connect")
                button.set_sensitive(True)
                err_label.set_text(f"Error: {exc}")
                err_label.show()
                return False
            if ok:
                power_on = self._backend.power_status()
                devices = self._backend.list_paired()
                self.populate(power_on, devices)
            else:
                button.set_label("Connect")
                button.set_sensitive(True)
                err_label.set_text("Connect failed")
                err_label.show()
            return False

        GLib.idle_add(_do)

    def _on_pair(self, button: "Gtk.Button", mac: str, err_label: "Gtk.Label"):
        button.set_sensitive(False)
        button.set_label("…")
        err_label.set_text("")
        err_label.hide()

        def _do():
            try:
                ok = self._backend.pair(mac)
            except Exception as exc:
                button.set_label("Pair")
                button.set_sensitive(True)
                err_label.set_text(f"Error: {exc}")
                err_label.show()
                return False
            if ok:
                power_on = self._backend.power_status()
                devices = self._backend.list_paired()
                self.populate(power_on, devices)
            else:
                button.set_label("Pair")
                button.set_sensitive(True)
                err_label.set_text("Pair failed")
                err_label.show()
            return False

        GLib.idle_add(_do)

    def _on_disconnect(self, button: "Gtk.Button", mac: str, err_label: "Gtk.Label"):
        button.set_sensitive(False)
        button.set_label("…")
        err_label.set_text("")
        err_label.hide()

        def _do():
            try:
                ok = self._backend.disconnect(mac)
            except Exception as exc:
                button.set_label("Disconnect")
                button.set_sensitive(True)
                err_label.set_text(f"Error: {exc}")
                err_label.show()
                return False
            if ok:
                power_on = self._backend.power_status()
                devices = self._backend.list_paired()
                self.populate(power_on, devices)
            else:
                button.set_label("Disconnect")
                button.set_sensitive(True)
                err_label.set_text("Disconnect failed")
                err_label.show()
            return False

        GLib.idle_add(_do)

    def _on_scan(self, button: "Gtk.Button"):
        button.set_sensitive(False)
        button.set_label("Scanning…")

        def _worker():
            try:
                devices = self._backend.scan_and_list()
                power_on = self._backend.power_status()
                GLib.idle_add(lambda: (self.populate(power_on, devices), False)[1])
            except Exception:
                GLib.idle_add(lambda: (
                    button.set_sensitive(True),
                    button.set_label("Scan for devices"),
                    False
                )[2])

        threading.Thread(target=_worker, daemon=True).start()


def main():
    if not _GTK_AVAILABLE:
        print("Error: python3-gi / GTK3 not available. Install python3-gi.", file=sys.stderr)
        sys.exit(1)

    panel_ui.apply_css()

    backend = BtBackend()
    panel = BtPanel(backend)

    def _load_and_show():
        try:
            power_on = backend.power_status()
            devices = backend.list_paired() if power_on else []
            panel.populate(power_on, devices)
            panel.show_all()
            panel.present()
        except Exception as exc:
            print(f"bt-panel: startup error: {exc}", file=sys.stderr)
            Gtk.main_quit()
        return False  # run once

    GLib.idle_add(_load_and_show)
    Gtk.main()


if __name__ == "__main__":
    main()
