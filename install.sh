#!/bin/bash

if [ "$EUID" -eq 0 ]; then
  echo "Ne lance pas ce script en root. yay/paru en a besoin pour les paquets AUR."
  exit 1
fi

# Dépendances identifiées depuis tes configurations
PACKAGES=(
    "hyprland"
    "waybar"
    "yazi"
    # "blender"
    "kitty" #[cite: 1]
    "mako" #[cite: 1]
    "chromium" #[cite: 1, 6]
    "grim" #[cite: 1]
    "slurp" #[cite: 1]
    "wl-clipboard" # Requis pour wl-copy[cite: 1]
    "wireplumber" # Requis pour wpctl[cite: 1, 2]
    "brightnessctl" #[cite: 1, 2]
    "playerctl" #[cite: 1]
    "socat" #[cite: 4]
    "jq" #[cite: 5]
    "pavucontrol" #[cite: 2]
    "bluez" # Requis pour bluetoothctl[cite: 2]
    "bluez-utils" # Requis pour bluetoothctl[cite: 2]
    "ttf-jetbrains-mono-nerd" #[cite: 3]
    "ttf-firacode-nerd" #[cite: 3]
    "vim" #[cite: 6]
    "kate" #[cite: 6, 7]
    "gimp" #[cite: 6]
)

AUR_PACKAGES=(
    "hyprlauncher" #[cite: 1]
    "hyprshutdown" #[cite: 1]
)

echo "Mise à jour et installation des paquets officiels..."
sudo pacman -Syu --needed "${PACKAGES[@]}"

echo "Installation des paquets AUR..."
if command -v yay &> /dev/null; then
    yay -S --needed "${AUR_PACKAGES[@]}"
elif command -v paru &> /dev/null; then
    paru -S --needed "${AUR_PACKAGES[@]}"
else
    echo "AUR helper introuvable. Installe manuellement : ${AUR_PACKAGES[*]}"
fi

echo "Importation des configurations..."
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_CONFIGS=("hypr" "waybar" "yazi" "blender")

for conf in "${TARGET_CONFIGS[@]}"; do
    if [ -d "$REPO_DIR/.config/$conf" ]; then
        mkdir -p ~/.config/"$conf"
        # -rT fusionne le contenu sans créer de sous-dossier accidentel
        cp -rT "$REPO_DIR/.config/$conf" ~/.config/"$conf"
        echo "-> $conf copié."
    else
        echo "-> Avertissement : $conf introuvable dans le dépôt."
    fi
done

# Rendre les daemons Waybar exécutables
if [ -f ~/.config/waybar/ws_daemon.sh ] && [ -f ~/.config/waybar/ws_state.sh ]; then
    chmod +x ~/.config/waybar/ws_daemon.sh ~/.config/waybar/ws_state.sh #[cite: 4, 5]
    echo "Scripts Waybar rendus exécutables."
fi

echo "Installation terminée."
