#!/usr/bin/env bash
set -euo pipefail

# btctl.sh - wrapper simples para bluetoothctl
# Mostra nomes dos dispositivos ao usuário, usa MAC internamente.

SCRIPT_NAME="$(basename "$0")"
SCAN_TIME=5

# Check dependency
if ! command -v bluetoothctl >/dev/null 2>&1; then
  echo "bluetoothctl não encontrado. Instale bluez (e.g., sudo apt install bluez)." >&2
  exit 2
fi

# Read devices from bluetoothctl: lines like "Device <MAC> <NAME...>"
read_devices() {
  mapfile -t _lines < <(bluetoothctl devices 2>/dev/null | sed 's/^Device //')
  names=()
  macs=()
  for line in "${_lines[@]}"; do
    [ -z "$line" ] && continue
    mac="${line%% *}"
    name="${line#* }"
    names+=("$name")
    macs+=("$mac")
  done
}

# Perform a scan for nearby devices (brief)
scan_devices() {
  local t=${1:-$SCAN_TIME}
  echo "Scanning por ${t}s..."
  # Run a single bluetoothctl session: start scan, wait, stop, then list devices
  local out _lines line mac name
  out=$(
    (
      printf 'power on\n'
      printf 'scan on\n'
      sleep "$t"
      printf 'scan off\n'
      printf 'devices\n'
      printf 'exit\n'
    ) | bluetoothctl 2>/dev/null || true
  )

  # Parse the bluetoothctl output for lines containing "Device <MAC> <NAME>"
  mapfile -t _lines < <(printf '%s\n' "$out" | sed -n 's/.*Device //p')
  names=()
  macs=()
  for line in "${_lines[@]}"; do
    [ -z "$line" ] && continue
    mac="${line%% *}"
    name="${line#* }"
    names+=("$name")
    macs+=("$mac")
  done
}

# Select a device by showing only NAMES to the user (numbered). Sets selected_mac and selected_name globals.
select_device_interactive() {
  if [ ${#names[@]} -eq 0 ]; then
    echo "Nenhum dispositivo disponível." >&2
    return 1
  fi

  local i
  display=()
  for i in "${!names[@]}"; do
    display+=("$((i+1)). ${names[$i]}")
  done

  if command -v fzf >/dev/null 2>&1; then
    selected_line=$(printf "%s\n" "${display[@]}" | fzf --height 40% --reverse --prompt="Selecione: " ) || true
    if [ -z "$selected_line" ]; then
      echo "Nenhuma seleção." >&2
      return 1
    fi
    idx=$(echo "$selected_line" | sed -E 's/^([0-9]+)\..*/\1/')
  else
    echo "Selecione o número do dispositivo:";
    printf "%s\n" "${display[@]}"
    read -rp "> " idx
  fi

  if ! [[ "$idx" =~ ^[0-9]+$ ]]; then
    echo "Seleção inválida." >&2
    return 1
  fi
  idx=$((idx-1))
  if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#macs[@]}" ]; then
    echo "Índice fora do alcance." >&2
    return 1
  fi
  selected_mac="${macs[$idx]}"
  selected_name="${names[$idx]}"
  return 0
}

cmd_power() {
  local arg=${1:-}
  if [ "$arg" != "on" ] && [ "$arg" != "off" ]; then
    echo "Uso: $SCRIPT_NAME power on|off"
    return 2
  fi
  echo "Definindo power $arg..."
  if bluetoothctl power "$arg"; then
    echo "Bluetooth: $arg"
    return 0
  else
    echo "Falha ao alterar estado do bluetooth." >&2
    return 1
  fi
}

cmd_list() {
  read_devices
  if [ ${#names[@]} -eq 0 ]; then
    echo "Nenhum dispositivo conhecido.";
    return 0
  fi
  for n in "${names[@]}"; do
    echo "$n"
  done
}

cmd_scan() {
  scan_devices "${1:-$SCAN_TIME}"
  cmd_list
}

cmd_connected() {
  read_devices
  local i info
  for i in "${!macs[@]}"; do
    info=$(bluetoothctl info "${macs[$i]}" 2>/dev/null || true)
    if echo "$info" | grep -q "Connected: yes"; then
      echo "${names[$i]}"
    fi
  done
}

cmd_pair() {
  # optionally pass --scan to do a scan first
  if [ "${1:-}" = "--scan" ]; then
    scan_devices
  else
    read_devices
  fi
  if ! select_device_interactive; then return 1; fi
  echo "Pareando $selected_name ($selected_mac)..."
  if bluetoothctl pair "$selected_mac"; then
    bluetoothctl trust "$selected_mac" >/dev/null 2>&1 || true
    bluetoothctl connect "$selected_mac" >/dev/null 2>&1 || true
    echo "Pareado/Confiável: $selected_name"
    return 0
  else
    echo "Pareamento falhou para $selected_name" >&2
    return 1
  fi
}

cmd_remove() {
  read_devices
  if ! select_device_interactive; then return 1; fi
  echo "Removendo $selected_name ($selected_mac)..."
  if bluetoothctl remove "$selected_mac"; then
    echo "Removido: $selected_name"
    return 0
  else
    echo "Falha ao remover $selected_name" >&2
    return 1
  fi
}

cmd_help() {
  cat <<EOF
Uso: $SCRIPT_NAME <comando>
Comandos:
  power on|off     - Ligar/desligar o adaptador Bluetooth
  list             - Listar dispositivos conhecidos (nome apenas)
  scan [secs]      - Scannear por dispositivos por N segundos e listar
  connected        - Listar dispositivos atualmente conectados
  pair [--scan]    - Parear dispositivo selecionado (opcionalmente faz scan antes)
  remove           - Desparear/remover dispositivo
  help             - Mostrar esta ajuda

Observações:
- O script mostra apenas os nomes para o usuário. O MAC é usado internamente para conectar/parear/remover.
- Se houver nomes duplicados, será mostrado um índice para selecionar corretamente.
- Recomenda-se ter fzf instalado para seleção interativa aprimorada.
EOF
}

# CLI dispatch
case "${1:-}" in
  power)
    shift || true; cmd_power "$@" ;;
  list)
    cmd_list ;;
  scan)
    shift || true; cmd_scan "$1" ;;
  connected)
    cmd_connected ;;
  pair)
    shift || true; cmd_pair "$@" ;;
  remove)
    cmd_remove ;;
  help|--help|-h|"")
    cmd_help ;;
  *)
    echo "Comando desconhecido: ${1:-}<nenhum>" >&2
    cmd_help; exit 2 ;;
esac
