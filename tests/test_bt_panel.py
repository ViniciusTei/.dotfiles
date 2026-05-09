#!/usr/bin/env python3
import sys
import os
import unittest
from unittest.mock import patch, MagicMock

# Allow importing bt-panel.py (hyphen in name requires importlib)
import importlib.util, types

def load_bt_panel():
    spec = importlib.util.spec_from_file_location(
        "bt_panel",
        os.path.join(os.path.dirname(__file__), "..", "scripts", ".scripts", "bt-panel.py"),
    )
    # Stub out gi.repository so GTK import doesn't fail in headless tests
    gi_mock = types.ModuleType("gi")
    gi_mock.require_version = MagicMock()
    gi_mock.repository = types.ModuleType("gi.repository")
    for name in ["Gtk", "Gdk", "GLib", "Pango"]:
        setattr(gi_mock.repository, name, MagicMock())
    sys.modules.setdefault("gi", gi_mock)
    sys.modules.setdefault("gi.repository", gi_mock.repository)
    for name in ["Gtk", "Gdk", "GLib", "Pango"]:
        sys.modules.setdefault(f"gi.repository.{name}", getattr(gi_mock.repository, name))

    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


bt = load_bt_panel()


class TestBtDevice(unittest.TestCase):
    def test_parse_connected_trusted_paired(self):
        line = "AA:BB:CC:DD:EE:FF|Fone JBL|yes|yes|yes"
        dev = bt.BtDevice.from_line(line)
        self.assertEqual(dev.mac, "AA:BB:CC:DD:EE:FF")
        self.assertEqual(dev.name, "Fone JBL")
        self.assertTrue(dev.connected)
        self.assertTrue(dev.paired)
        self.assertTrue(dev.trusted)

    def test_parse_disconnected_untrusted(self):
        line = "11:22:33:44:55:66|Sony WH-1000|no|yes|no"
        dev = bt.BtDevice.from_line(line)
        self.assertFalse(dev.connected)
        self.assertTrue(dev.paired)
        self.assertFalse(dev.trusted)

    def test_parse_devices_multiple_lines(self):
        output = (
            "AA:BB:CC:DD:EE:FF|Fone JBL|yes|yes|yes\n"
            "11:22:33:44:55:66|Sony WH-1000|no|yes|no\n"
        )
        devices = bt.parse_devices(output)
        self.assertEqual(len(devices), 2)
        self.assertEqual(devices[0].mac, "AA:BB:CC:DD:EE:FF")
        self.assertEqual(devices[1].mac, "11:22:33:44:55:66")

    def test_parse_devices_empty_output(self):
        devices = bt.parse_devices("")
        self.assertEqual(devices, [])

    def test_parse_devices_ignores_blank_lines(self):
        output = "AA:BB:CC:DD:EE:FF|Fone JBL|yes|yes|yes\n\n"
        devices = bt.parse_devices(output)
        self.assertEqual(len(devices), 1)


class TestBtBackend(unittest.TestCase):
    def setUp(self):
        self.backend = bt.BtBackend(btctl_path="/mock/btctl.sh")

    @patch("subprocess.run")
    def test_power_status_yes(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout="yes\n")
        self.assertTrue(self.backend.power_status())
        mock_run.assert_called_once_with(
            ["/mock/btctl.sh", "power", "status"],
            capture_output=True, text=True
        )

    @patch("subprocess.run")
    def test_power_status_no(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout="no\n")
        self.assertFalse(self.backend.power_status())

    @patch("subprocess.run")
    def test_list_paired_returns_devices(self, mock_run):
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="AA:BB:CC:DD:EE:FF|Fone JBL|yes|yes|yes\n"
        )
        devices = self.backend.list_paired()
        self.assertEqual(len(devices), 1)
        self.assertEqual(devices[0].mac, "AA:BB:CC:DD:EE:FF")
        mock_run.assert_called_once_with(
            ["/mock/btctl.sh", "list", "--paired"],
            capture_output=True, text=True
        )

    @patch("subprocess.run")
    def test_power_on_returns_true_on_success(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0)
        self.assertTrue(self.backend.set_power(True))

    @patch("subprocess.run")
    def test_power_off_returns_true_on_success(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0)
        self.assertTrue(self.backend.set_power(False))

    @patch("subprocess.run")
    def test_power_on_returns_false_on_failure(self, mock_run):
        mock_run.return_value = MagicMock(returncode=1)
        self.assertFalse(self.backend.set_power(True))

    @patch("subprocess.run")
    def test_connect_returns_true_on_success(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0)
        self.assertTrue(self.backend.connect("AA:BB:CC:DD:EE:FF"))
        mock_run.assert_called_once_with(
            ["/mock/btctl.sh", "connect", "AA:BB:CC:DD:EE:FF"],
            capture_output=True, text=True
        )

    @patch("subprocess.run")
    def test_connect_returns_false_on_failure(self, mock_run):
        mock_run.return_value = MagicMock(returncode=1)
        self.assertFalse(self.backend.connect("AA:BB:CC:DD:EE:FF"))

    @patch("subprocess.run")
    def test_disconnect_returns_true_on_success(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0)
        self.assertTrue(self.backend.disconnect("AA:BB:CC:DD:EE:FF"))
        mock_run.assert_called_once_with(
            ["/mock/btctl.sh", "disconnect", "AA:BB:CC:DD:EE:FF"],
            capture_output=True, text=True
        )

    @patch("subprocess.run")
    def test_scan_returns_devices(self, mock_run):
        mock_run.side_effect = [
            MagicMock(returncode=0),  # scan 5
            MagicMock(returncode=0, stdout="AA:BB:CC:DD:EE:FF|Fone JBL|no|yes|yes\n"),  # list --paired
        ]
        devices = self.backend.scan_and_list()
        self.assertEqual(len(devices), 1)
        self.assertEqual(mock_run.call_count, 2)


if __name__ == "__main__":
    unittest.main()
