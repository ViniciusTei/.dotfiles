#!/usr/bin/env bash

IP=/sbin/ip

gateway=$($IP route get 8.8.8.8 2>/dev/null | awk '{print $3; exit}')
if [[ -z "$gateway" ]]; then
    echo "󰈀 offline"
    exit
fi

# Testa conexão TCP na porta 80 com timeout de 2s
if nc -zw2 1.1.1.1 80 2>/dev/null; then
    echo "󰈀 online"
else
    echo "󰈀 offline"
fi
