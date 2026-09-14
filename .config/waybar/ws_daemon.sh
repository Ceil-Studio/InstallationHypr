#!/bin/bash
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    if [[ $line == workspace* ]]; then
        sleep 0.05
        pkill -RTMIN+10 waybar
    fi
done
