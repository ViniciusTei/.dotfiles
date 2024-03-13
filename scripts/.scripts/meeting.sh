#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)

/usr/bin/notify-send Hey "Your meeting starts in 5 min" -i /home/vinicius/.icons/logo512.png 
#/usr/bin/paplay /usr/share/sounds/freedesktop/stereo/message-new-instant.oga
