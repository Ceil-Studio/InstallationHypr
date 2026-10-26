#!/bin/bash
TARGET=$1
ICON=$2

STATE=$(hyprctl -j workspaces | jq -c --argjson t "$TARGET" 'map(select(.id == $t)) | .[0] // empty')
ACTIVE=$(hyprctl -j activeworkspace | jq -r '.id')

if [ "$ACTIVE" == "$TARGET" ]; then
    echo '{"text": "'"$ICON"' '"$TARGET"'", "class": "active", "tooltip": "Bureau '"$TARGET"' (Actif)"}'
elif [ -n "$STATE" ]; then
    WINS=$(echo "$STATE" | jq -r '.windows // 0')
    if [ "$WINS" -gt 0 ] 2>/dev/null; then
        echo '{"text": "'"$ICON"'", "class": "occupied", "tooltip": "Bureau '"$TARGET"' ('"$WINS"' fenêtre(s))"}'
    else
        echo '{"text": "'"$ICON"'", "class": "empty", "tooltip": "Bureau '"$TARGET"' (Vide)"}'
    fi
else
    echo '{"text": "'"$ICON"'", "class": "empty", "tooltip": "Bureau '"$TARGET"' (Vide)"}'
fi
