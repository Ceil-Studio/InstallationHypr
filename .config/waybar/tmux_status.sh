#!/bin/bash
# Statut tmux pour Waybar

SESSIONS=$(tmux ls 2>/dev/null)

if [ -z "$SESSIONS" ]; then
    echo '{"text": "", "tooltip": "Tmux : Aucune session\n\n• Clic gauche : Nouveau tmux\n• Clic droit : Rattacher (tmux a)", "class": "empty"}'
    exit 0
fi

TOTAL=$(echo "$SESSIONS" | wc -l)
DETACHED=$(echo "$SESSIONS" | grep -v '(attached)' | wc -l)

TOOLTIP="Sessions Tmux ($TOTAL active(s), $DETACHED détachée(s)) :
$SESSIONS

• Clic gauche : Nouveau tmux
• Clic droit : Rattacher (tmux a)"

if [ "$DETACHED" -gt 0 ]; then
    jq -c -n \
      --arg text " $DETACHED" \
      --arg tooltip "$(echo -e "$TOOLTIP")" \
      --arg class "detached" \
      '{text: $text, tooltip: $tooltip, class: $class}'
else
    jq -c -n \
      --arg text "" \
      --arg tooltip "$(echo -e "$TOOLTIP")" \
      --arg class "attached" \
      '{text: $text, tooltip: $tooltip, class: $class}'
fi
