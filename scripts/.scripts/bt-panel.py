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
        mac, name, connected, paired, trusted = line.split("|", 4)
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
        return subprocess.run(
            [self._btctl, *args],
            capture_output=True,
            text=True,
        )

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
        self._run("scan", "5")
        result = self._run("list", "--paired")
        return parse_devices(result.stdout)
