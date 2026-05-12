#!/usr/bin/env python3
"""WiFi GTK3 status panel — launched by Polybar on network icon click."""

import os
import subprocess
import sys
import threading
from dataclasses import dataclass
from typing import List, Optional, Set

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gtk, GLib
    import panel_ui
    _GTK_AVAILABLE = True
except (ImportError, ValueError):
    _GTK_AVAILABLE = False

NWCTL = os.path.expanduser("~/.scripts/nwctl.sh")


@dataclass
class WifiNetwork:
    ssid: str
    signal: int       # 0-100
    security: str     # "WPA2", "WPA1 WPA2", "--", ""
    connected: bool
    saved: bool

    @classmethod
    def from_line(cls, line: str, saved_ssids: Set[str]) -> "WifiNetwork":
        ssid, signal_s, security, connected_s = line.split("|", 3)
        return cls(
            ssid=ssid,
            signal=int(signal_s) if signal_s.isdigit() else 0,
            security=security,
            connected=connected_s.strip() == "yes",
            saved=ssid in saved_ssids,
        )

    @property
    def signal_bars(self) -> str:
        s = self.signal
        if s >= 75: return "▂▄▆█"
        if s >= 50: return "▂▄▆_"
        if s >= 25: return "▂▄__"
        return "▂___"

    @property
    def is_secured(self) -> bool:
        return bool(self.security and self.security not in ("--", ""))


def parse_networks(output: str, saved_ssids: Set[str]) -> List[WifiNetwork]:
    return [
        WifiNetwork.from_line(line, saved_ssids)
        for line in output.splitlines()
        if line.strip() and line.count("|") >= 3
    ]


class NwBackend:
    def __init__(self, nwctl_path: str = NWCTL):
        self._nwctl = nwctl_path

    def _run(self, *args) -> subprocess.CompletedProcess:
        try:
            return subprocess.run([self._nwctl, *args], capture_output=True, text=True)
        except FileNotFoundError:
            raise RuntimeError(f"nwctl not found: {self._nwctl}") from None

    def power_status(self) -> bool:
        return self._run("power", "status").stdout.strip() == "yes"

    def set_power(self, on: bool) -> bool:
        return self._run("power", "on" if on else "off").returncode == 0

    def saved_ssids(self) -> Set[str]:
        return set(self._run("saved").stdout.splitlines())

    def list_networks(self) -> List[WifiNetwork]:
        saved = self.saved_ssids()
        return parse_networks(self._run("list").stdout, saved)

    def scan_and_list(self) -> List[WifiNetwork]:
        self._run("scan")
        return self.list_networks()

    def connect(self, ssid: str, password: Optional[str] = None) -> bool:
        if password:
            return self._run("connect", ssid, password).returncode == 0
        return self._run("connect", ssid).returncode == 0

    def disconnect(self) -> bool:
        return self._run("disconnect").returncode == 0


class NwPanel(panel_ui.BasePanelWindow):
    def __init__(self, backend: NwBackend):
        super().__init__()
        self._backend = backend

    def populate(self, power_on: bool, networks: List[WifiNetwork]):
        widgets = [panel_ui.build_header("󰤨", "WiFi", power_on, self._on_power_toggle)]

        if power_on:
            for net in networks:
                badges = []
                if net.saved:
                    badges.append("Saved")
                if net.is_secured:
                    badges.append("🔒")

                if net.connected:
                    action_label = "Disconnect"
                    on_action = lambda b, e, n=net: self._on_disconnect(b, n, e)
                else:
                    action_label = "Connect"
                    on_action = lambda b, e, n=net: self._on_connect(b, n, e)

                widgets.append(panel_ui.build_separator())
                widgets.append(panel_ui.build_row(
                    name=net.ssid,
                    status_text=f"{net.signal_bars} {net.signal}%",
                    is_connected=net.connected,
                    badges=badges,
                    action_label=action_label,
                    on_action=on_action,
                ))

            widgets.append(panel_ui.build_separator())
            widgets.append(panel_ui.build_footer_button("Scan for networks", self._on_scan))

        self._refresh_root(*widgets)

    def _on_power_toggle(self, button):
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
                networks = self._backend.list_networks() if power_on else []
                self.populate(power_on, networks)
            else:
                button.set_label("ON" if is_on else "OFF")
                button.set_sensitive(True)
            return False

        GLib.idle_add(_do)

    def _on_connect(self, button, net: WifiNetwork, err_label):
        password = None
        if net.is_secured and not net.saved:
            password = panel_ui.show_password_dialog(self, net.ssid)
            if password is None:
                return

        button.set_sensitive(False)
        button.set_label("…")
        err_label.set_text("")
        err_label.hide()

        def _worker():
            try:
                ok = self._backend.connect(net.ssid, password)
            except Exception as exc:
                GLib.idle_add(lambda: (
                    button.set_label("Connect"), button.set_sensitive(True),
                    err_label.set_text(f"Error: {exc}"), err_label.show(), False
                )[-1])
                return
            if ok:
                GLib.idle_add(lambda: (
                    self.populate(self._backend.power_status(), self._backend.list_networks()), False
                )[-1])
            else:
                GLib.idle_add(lambda: (
                    button.set_label("Connect"), button.set_sensitive(True),
                    err_label.set_text("Connect failed"), err_label.show(), False
                )[-1])

        threading.Thread(target=_worker, daemon=True).start()

    def _on_disconnect(self, button, net: WifiNetwork, err_label):
        button.set_sensitive(False)
        button.set_label("…")
        err_label.set_text("")
        err_label.hide()

        def _worker():
            try:
                ok = self._backend.disconnect()
            except Exception as exc:
                GLib.idle_add(lambda: (
                    button.set_label("Disconnect"), button.set_sensitive(True),
                    err_label.set_text(f"Error: {exc}"), err_label.show(), False
                )[-1])
                return
            if ok:
                GLib.idle_add(lambda: (
                    self.populate(self._backend.power_status(), self._backend.list_networks()), False
                )[-1])
            else:
                GLib.idle_add(lambda: (
                    button.set_label("Disconnect"), button.set_sensitive(True),
                    err_label.set_text("Disconnect failed"), err_label.show(), False
                )[-1])

        threading.Thread(target=_worker, daemon=True).start()

    def _on_scan(self, button):
        button.set_sensitive(False)
        button.set_label("Scanning…")

        def _worker():
            try:
                networks = self._backend.scan_and_list()
                power_on = self._backend.power_status()
                GLib.idle_add(lambda: (self.populate(power_on, networks), False)[-1])
            except Exception:
                GLib.idle_add(lambda: (
                    button.set_sensitive(True), button.set_label("Scan for networks"), False
                )[-1])

        threading.Thread(target=_worker, daemon=True).start()


def main():
    if not _GTK_AVAILABLE:
        print("Error: python3-gi / GTK3 not available.", file=sys.stderr)
        sys.exit(1)

    panel_ui.apply_css()
    backend = NwBackend()
    panel = NwPanel(backend)

    def _load_and_show():
        try:
            power_on = backend.power_status()
            networks = backend.list_networks() if power_on else []
            panel.populate(power_on, networks)
            panel.show_all()
            panel.present()
        except Exception as exc:
            print(f"nw-panel: startup error: {exc}", file=sys.stderr)
            Gtk.main_quit()
        return False

    GLib.idle_add(_load_and_show)
    Gtk.main()


if __name__ == "__main__":
    main()
