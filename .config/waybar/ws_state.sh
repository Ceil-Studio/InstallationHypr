#!/bin/bash
TARGET=$1
ICON=$2
ACTIVE=$(hyprctl activeworkspace -j | jq -r '.id')

if [ "$ACTIVE" == "$TARGET" ]; then
    echo '{"text": "'"$ICON"' '"$TARGET"'", "class": "active"}'
else
    echo '{"text": "'"$ICON"' '"$TARGET"'", "class": ""}'
fi
