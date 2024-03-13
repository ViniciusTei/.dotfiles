#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)

/usr/bin/notify-send Hey "$1" -i /home/vinicius/.icons/alert.png 
