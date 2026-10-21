#!/bin/bash
# Sélecteur graphique de sessions tmux pour Waybar

SESSIONS=$(tmux ls 2>/dev/null)

if [ -z "$SESSIONS" ]; then
    notify-send "Tmux" "Aucune session active en cours" -i terminal 2>/dev/null
    exit 0
fi

# Formattage pour la boîte de dialogue zenity
CHOICE=$(tmux ls -F '#{session_name}|#{session_windows} f.|#{?session_attached,Attachée,Détachée}' 2>/dev/null | \
    while IFS='|' read -r name win stat; do
        echo "$name"
        echo "$win"
        echo "$stat"
    done | \
    zenity --list \
        --title="Sessions Tmux" \
        --text="Sélectionnez une session :" \
        --column="Session" --column="Fenêtres" --column="Statut" \
        --width=380 --height=280 2>/dev/null)

if [ -n "$CHOICE" ]; then
    kitty -e tmux attach -t "$CHOICE"
fi
