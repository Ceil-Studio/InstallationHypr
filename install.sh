#!/bin/bash
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
  echo "Erreur : Ne lance pas ce script en root. yay en a besoin pour l'AUR."
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Paquets officiels Pacman
PACKAGES=(
    # Base graphique & Composants Hyprland
    "hyprland"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "waybar"
    "mako"
    "kitty"
    "tmux"

    # Utilitaires Hyprland (disponibles dans les dépôts officiels extra)
    "hyprlauncher"
    "hyprshutdown"

    # Capture d'écran, Presse-papier & Multimédia
    "grim"
    "slurp"
    "wl-clipboard"
    "pipewire"
    "pipewire-pulse"
    "pipewire-audio"
    "wireplumber"
    "pavucontrol"
    "playerctl"
    "brightnessctl"

    # Réseau & Bluetooth
    "networkmanager"
    "bluez"
    "bluez-utils"

    # Outils CLI & Dépendances des scripts Waybar
    "jq"
    "socat"
    "zenity"
    "libnotify"
    "htop"
    "yazi"
    "vim"
    "kate"
    "gimp"
    "chromium"
    # "blender"

    # Polices d'icônes et d'écriture
    "ttf-jetbrains-mono-nerd"
    "ttf-firacode-nerd"

    # Outils de build indispensables pour l'AUR
    "base-devel"
    "git"
)

# 2. Paquets AUR (ajoute ici tes paquets spécifiques AUR si besoin)
AUR_PACKAGES=()

echo ":: Mise à jour et installation des paquets officiels..."
sudo pacman -Syu --needed "${PACKAGES[@]}"

# 3. Installation automatique de yay si aucun helper AUR n'est détecté
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo ":: Aucun helper AUR détecté. Installation automatique de yay-bin..."
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin"
    (cd "$TEMP_DIR/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$TEMP_DIR"
fi

# 4. Installation des paquets AUR éventuels
if [ ${#AUR_PACKAGES[@]} -gt 0 ]; then
    echo ":: Installation des paquets AUR..."
    if command -v yay &> /dev/null; then
        yay -S --needed "${AUR_PACKAGES[@]}"
    elif command -v paru &> /dev/null; then
        paru -S --needed "${AUR_PACKAGES[@]}"
    fi
fi

# 5. Création des répertoires de base
mkdir -p ~/.config

# 6. Liens symboliques des dossiers de configuration
TARGET_CONFIGS=("hypr" "waybar" "yazi" "blender")

echo ":: Création des liens symboliques..."
for conf in "${TARGET_CONFIGS[@]}"; do
    if [ -d "$REPO_DIR/.config/$conf" ]; then
        rm -rf ~/.config/"$conf"
        ln -s "$REPO_DIR/.config/$conf" ~/.config/"$conf"
        echo "-> Lien créé pour ~/.config/$conf"
    else
        echo "-> Avertissement : $conf introuvable dans le dépôt."
    fi
done

# Cas particulier Chromium : uniquement les Bookmarks pour éviter 3+ Go de cache dans Git
if [ -f "$REPO_DIR/.config/chromium/Default/Bookmarks" ]; then
    mkdir -p ~/.config/chromium/Default
    cp "$REPO_DIR/.config/chromium/Default/Bookmarks" ~/.config/chromium/Default/Bookmarks
    echo "-> Favoris Chromium restaurés."
fi

# Cas particulier .tmux.conf (placé dans le repo)
if [ -f "$REPO_DIR/.tmux.conf" ]; then
    ln -sf "$REPO_DIR/.tmux.conf" ~/.tmux.conf
    echo "-> Lien créé pour ~/.tmux.conf"
fi

# Cas particulier .ssh/config
if [ -f "$REPO_DIR/.ssh/config" ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ln -sf "$REPO_DIR/.ssh/config" ~/.ssh/config
    chmod 600 ~/.ssh/config
    echo "-> Configuration ~/.ssh/config liée avec permissions sécurisées (600)."
fi

# Cas particulier Antigravity CLI (~/.gemini/config)
if [ -d "$REPO_DIR/.gemini/config" ]; then
    mkdir -p ~/.gemini
    rm -rf ~/.gemini/config
    ln -s "$REPO_DIR/.gemini/config" ~/.gemini/config
    echo "-> Configuration Antigravity (~/.gemini/config) liée avec succès."
fi

# 7. Permissions d'exécution sur tous les scripts Waybar
if [ -d ~/.config/waybar ]; then
    chmod +x ~/.config/waybar/*.sh 2>/dev/null || true
    echo "-> Scripts Waybar rendus exécutables."
fi

# 8. Activation des services indispensables
echo ":: Activation des services nécessaires..."
sudo systemctl enable --now bluetooth.service NetworkManager.service 2>/dev/null || true

# 9. Rappel pour la génération de clés SSH si absentes
if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
    echo ""
    echo ":: Info : Aucune clé SSH trouvée dans ~/.ssh/"
    echo "   Pour générer une nouvelle clé Ed25519 propre :"
    echo "   ssh-keygen -t ed25519 -C \"ton_email@exemple.com\""
fi

echo "Installation terminée avec succès !"
