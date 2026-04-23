#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/.scripts/rofi-bluetooth.sh"

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

# Syntax check
bash -n "$SCRIPT" && echo "PASS: syntax check" && PASS=$((PASS+1)) \
                  || { echo "FAIL: syntax check"; FAIL=$((FAIL+1)); }

# MAC extraction: "Name (MAC)" → MAC
extract_mac() { sed -E 's/.*\(([^)]+)\)/\1/'; }
assert_eq "extract simple MAC"     "AA:BB:CC:DD:EE:FF" \
  "$(echo 'Fone JBL (AA:BB:CC:DD:EE:FF)' | extract_mac)"
assert_eq "extract multi-word name" "11:22:33:44:55:66" \
  "$(echo 'Mouse Logitech Pro X (11:22:33:44:55:66)' | extract_mac)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
