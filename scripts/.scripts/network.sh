#!/bin/bash

if ping -c 1 -W 1 8.8.8.8 &>/dev/null; then
  echo "online"
else
  echo "offline"
fi

