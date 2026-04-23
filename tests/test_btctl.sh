#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
BTCTL="$(cd "$(dirname "$0")/.." && pwd)/scripts/.scripts/btctl.sh"

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    echo "  expected: [$expected]"
    echo "  actual:   [$actual]"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit() {
  local desc="$1" expected_code="$2"
  shift 2
  local actual_code=0
  "$@" >/dev/null 2>&1 || actual_code=$?
  assert_eq "$desc" "$expected_code" "$actual_code"
}

# ── Mock setup ────────────────────────────────────────────────────────────────
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"' EXIT

cat > "$MOCK_DIR/bluetoothctl" << 'MOCK'
#!/usr/bin/env bash
case "$1" in
  devices)
    echo "Device AA:BB:CC:DD:EE:FF Fone JBL"
    echo "Device 11:22:33:44:55:66 Mouse Logitech"
    echo "Device 99:88:77:66:55:44 Speaker Anker"
    ;;
  info)
    case "$2" in
      AA:BB:CC:DD:EE:FF)
        printf 'Device AA:BB:CC:DD:EE:FF\n\tConnected: yes\n\tPaired: yes\n\tTrusted: yes\n' ;;
      11:22:33:44:55:66)
        printf 'Device 11:22:33:44:55:66\n\tConnected: no\n\tPaired: yes\n\tTrusted: no\n' ;;
      99:88:77:66:55:44)
        printf 'Device 99:88:77:66:55:44\n\tConnected: no\n\tPaired: no\n\tTrusted: no\n' ;;
    esac
    ;;
  show)
    printf 'Controller XX:XX:XX:XX:XX:XX\n  Powered: yes\n' ;;
  power|pair|trust|connect|disconnect|remove)
    exit 0 ;;
esac
MOCK
chmod +x "$MOCK_DIR/bluetoothctl"
export PATH="$MOCK_DIR:$PATH"

# ── Core tests ────────────────────────────────────────────────────────────────

# list: pipe-delimited format
output=$("$BTCTL" list)
assert_eq "list: line count" "3" "$(echo "$output" | wc -l | tr -d ' ')"
assert_eq "list: first MAC"  "AA:BB:CC:DD:EE:FF" "$(echo "$output" | head -1 | cut -d'|' -f1)"
assert_eq "list: first NAME" "Fone JBL"          "$(echo "$output" | head -1 | cut -d'|' -f2)"
assert_eq "list: first CONNECTED" "yes"          "$(echo "$output" | head -1 | cut -d'|' -f3)"
assert_eq "list: first PAIRED"    "yes"          "$(echo "$output" | head -1 | cut -d'|' -f4)"
assert_eq "list: first TRUSTED"   "yes"          "$(echo "$output" | head -1 | cut -d'|' -f5)"

# list --paired: only devices with PAIRED=yes
output=$("$BTCTL" list --paired)
assert_eq "list --paired: count" "2" "$(echo "$output" | wc -l | tr -d ' ')"
assert_eq "list --paired: no Speaker Anker" "" "$(echo "$output" | grep 'Speaker Anker' || true)"

# list --available: only devices with PAIRED=no
output=$("$BTCTL" list --available)
assert_eq "list --available: count" "1" "$(echo "$output" | wc -l | tr -d ' ')"
assert_eq "list --available: MAC" "99:88:77:66:55:44" "$(echo "$output" | cut -d'|' -f1)"

# connected: only CONNECTED=yes
output=$("$BTCTL" connected)
assert_eq "connected: count" "1" "$(echo "$output" | wc -l | tr -d ' ')"
assert_eq "connected: MAC"   "AA:BB:CC:DD:EE:FF" "$(echo "$output" | cut -d'|' -f1)"

# power status
assert_eq "power status" "yes" "$("$BTCTL" power status)"

# exit codes
assert_exit "unknown command → exit 2"  2 "$BTCTL" notacommand
assert_exit "power bad arg → exit 2"    2 "$BTCTL" power badarg
assert_exit "pair no MAC → exit 2"      2 "$BTCTL" pair
assert_exit "connect no MAC → exit 2"   2 "$BTCTL" connect
assert_exit "disconnect no MAC → exit 2" 2 "$BTCTL" disconnect
assert_exit "remove no MAC → exit 2"    2 "$BTCTL" remove
assert_exit "info no MAC → exit 2"      2 "$BTCTL" info

# ── Device op tests ───────────────────────────────────────────────────────────

assert_exit "pair <MAC> → exit 0"       0 "$BTCTL" pair       AA:BB:CC:DD:EE:FF
assert_exit "connect <MAC> → exit 0"    0 "$BTCTL" connect    AA:BB:CC:DD:EE:FF
assert_exit "disconnect <MAC> → exit 0" 0 "$BTCTL" disconnect AA:BB:CC:DD:EE:FF
assert_exit "remove <MAC> → exit 0"     0 "$BTCTL" remove     AA:BB:CC:DD:EE:FF
assert_exit "scan → exit 0"             0 "$BTCTL" scan 0

# info returns output
output=$("$BTCTL" info AA:BB:CC:DD:EE:FF)
assert_eq "info: contains Connected" "yes" "$(echo "$output" | grep -o 'Connected: yes' | cut -d' ' -f2 || true)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
