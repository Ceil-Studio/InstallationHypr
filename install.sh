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
    "xdg-utils"
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
TARGET_CONFIGS=("hypr" "waybar" "yazi" "blender" "xdg-desktop-portal")

echo ":: Création des liens symboliques..."
for conf in "${TARGET_CONFIGS[@]}"; do
    SRC_DIR="$REPO_DIR/.config/$conf"
    DEST_DIR="$HOME/.config/$conf"
    if [ -d "$SRC_DIR" ]; then
        if [ -L "$DEST_DIR" ] && [ "$(readlink -f "$DEST_DIR")" = "$(readlink -f "$SRC_DIR")" ]; then
            echo "-> ~/.config/$conf est déjà correctement lié."
        else
            rm -rf "$DEST_DIR"
            ln -sfn "$SRC_DIR" "$DEST_DIR"
            echo "-> Lien créé pour ~/.config/$conf"
        fi
    else
        echo "-> Avertissement : $conf introuvable dans le dépôt."
    fi
done

# Cas particulier Chromium : uniquement les Bookmarks pour éviter 3+ Go de cache dans Git
SRC_BOOKMARKS="$REPO_DIR/.config/chromium/Default/Bookmarks"
DEST_BOOKMARKS="$HOME/.config/chromium/Default/Bookmarks"

if [ -f "$SRC_BOOKMARKS" ]; then
    if [ -f "$DEST_BOOKMARKS" ] && [ "$SRC_BOOKMARKS" -ef "$DEST_BOOKMARKS" ]; then
        echo "-> Les favoris Chromium pointent déjà sur le même fichier (aucun besoin de copier)."
    else
        mkdir -p "$HOME/.config/chromium/Default"
        cp "$SRC_BOOKMARKS" "$DEST_BOOKMARKS"
        echo "-> Favoris Chromium restaurés."
    fi
fi

# Cas particulier .tmux.conf (placé dans le repo)
if [ -f "$REPO_DIR/.tmux.conf" ]; then
    if [ -L ~/.tmux.conf ] && [ "$(readlink -f ~/.tmux.conf)" = "$(readlink -f "$REPO_DIR/.tmux.conf")" ]; then
        echo "-> ~/.tmux.conf est déjà correctement lié."
    else
        ln -sf "$REPO_DIR/.tmux.conf" ~/.tmux.conf
        echo "-> Lien créé pour ~/.tmux.conf"
    fi
fi

# Cas particulier .ssh/config
if [ -f "$REPO_DIR/.ssh/config" ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    if [ -L ~/.ssh/config ] && [ "$(readlink -f ~/.ssh/config)" = "$(readlink -f "$REPO_DIR/.ssh/config")" ]; then
        echo "-> ~/.ssh/config est déjà correctement lié."
    else
        ln -sf "$REPO_DIR/.ssh/config" ~/.ssh/config
        echo "-> Configuration ~/.ssh/config liée avec permissions sécurisées (600)."
    fi
    chmod 600 ~/.ssh/config
fi

# Cas particulier Antigravity CLI (~/.gemini/config)
if [ -d "$REPO_DIR/.gemini/config" ]; then
    mkdir -p ~/.gemini
    if [ -L ~/.gemini/config ] && [ "$(readlink -f ~/.gemini/config)" = "$(readlink -f "$REPO_DIR/.gemini/config")" ]; then
        echo "-> ~/.gemini/config est déjà correctement lié."
    else
        rm -rf ~/.gemini/config
        ln -sfn "$REPO_DIR/.gemini/config" ~/.gemini/config
        echo "-> Configuration Antigravity (~/.gemini/config) liée avec succès."
    fi
fi

# 7. Configuration de Yazi par défaut et thème sombre GTK
if command -v xdg-mime &>/dev/null; then
    xdg-mime default yazi.desktop inode/directory
    echo "-> Yazi défini comme gestionnaire de fichiers par défaut (inode/directory)."
fi

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
fi

# 8. Permissions d'exécution sur tous les scripts Waybar
if [ -d ~/.config/waybar ]; then
    chmod +x ~/.config/waybar/*.sh 2>/dev/null || true
    echo "-> Scripts Waybar rendus exécutables."
fi

# 9. Activation des services indispensables
echo ":: Activation des services nécessaires..."
sudo systemctl enable --now bluetooth.service NetworkManager.service 2>/dev/null || true

# 10. Rappel pour la génération de clés SSH si absentes
if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
    echo ""
    echo ":: Info : Aucune clé SSH trouvée dans ~/.ssh/"
    echo "   Pour générer une nouvelle clé Ed25519 propre :"
    echo "   ssh-keygen -t ed25519 -C \"ton_email@exemple.com\""
fi

echo "Installation terminée avec succès !"
