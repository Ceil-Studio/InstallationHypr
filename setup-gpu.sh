#!/bin/bash
set -euo pipefail

# Script d'installation et de configuration automatique des pilotes GPU
# Conçu pour setup Hybride Intel + NVIDIA RTX sous Arch Linux (Wayland / Hyprland)

if [ "$EUID" -eq 0 ]; then
  echo "Erreur : Lance ce script en utilisateur normal (il utilisera sudo pour les étapes root)."
  exit 1
fi

echo "=========================================================="
echo "    Installation & Configuration des pilotes GPU"
echo "=========================================================="

# 1. Détection automatique du/des noyau(x) installé(s) pour les en-têtes (headers)
KERNEL_PACKAGES=()

if pacman -Qq linux-zen &>/dev/null; then
    KERNEL_PACKAGES+=("linux-zen-headers")
fi
if pacman -Qq linux-lts &>/dev/null; then
    KERNEL_PACKAGES+=("linux-lts-headers")
fi
if pacman -Qq linux &>/dev/null; then
    KERNEL_PACKAGES+=("linux-headers")
fi

# Secours si aucun paquet de noyau n'a été détecté via pacman
if [ ${#KERNEL_PACKAGES[@]} -eq 0 ]; then
    CURRENT_KVER="$(uname -r)"
    if [[ "$CURRENT_KVER" =~ "zen" ]]; then
        KERNEL_PACKAGES+=("linux-zen-headers")
    elif [[ "$CURRENT_KVER" =~ "lts" ]]; then
        KERNEL_PACKAGES+=("linux-lts-headers")
    else
        KERNEL_PACKAGES+=("linux-headers")
    fi
fi

echo "-> En-têtes noyau identifiés : ${KERNEL_PACKAGES[*]}"

# 2. Liste des paquets GPU principaux
GPU_PACKAGES=(
    # DKMS & Headers pour compiler le module noyau
    "dkms"
    "${KERNEL_PACKAGES[@]}"

    # Pilotes NVIDIA Open Kernel (Recommandé pour RTX 20xx / 30xx / 40xx)
    "nvidia-open-dkms"
    "nvidia-utils"
    "nvidia-settings"
    "opencl-nvidia"
    "nvidia-prime"

    # Support Intel iGPU & Accélération matérielle (VA-API / QuickSync)
    "intel-media-driver"
    "libva-intel-driver"
    "vulkan-intel"
    "mesa-utils"
)

# 3. Demande optionnelle pour CUDA et Docker GPU
read -rp "Installer également CUDA et le support Docker GPU (nvidia-container-toolkit) ? [O/n] " prompt_cuda
prompt_cuda=${prompt_cuda:-O}
CONFIGURE_DOCKER=false

if [[ "$prompt_cuda" =~ ^[OoYy] ]]; then
    GPU_PACKAGES+=("cuda" "nvidia-container-toolkit")
    CONFIGURE_DOCKER=true
fi

# 4. Installation des paquets
echo ":: Installation des paquets graphiques..."
sudo pacman -Syu --needed "${GPU_PACKAGES[@]}"

# 5. Configuration des options NVIDIA dans /etc/modprobe.d/
echo ":: Configuration des options nvidia-drm (modeset & fbdev)..."
sudo mkdir -p /etc/modprobe.d
sudo tee /etc/modprobe.d/nvidia.conf > /dev/null << 'EOF'
options nvidia_drm modeset=1 fbdev=1
EOF
echo "-> /etc/modprobe.d/nvidia.conf créé avec succès."

# 6. Configuration de l'Early KMS dans /etc/mkinitcpio.conf
echo ":: Vérification de l'Early Loading des modules NVIDIA dans mkinitcpio..."
if grep -q "nvidia" /etc/mkinitcpio.conf; then
    echo "-> Modules NVIDIA déjà présents dans /etc/mkinitcpio.conf."
else
    echo "-> Ajout des modules (nvidia nvidia_modeset nvidia_uvm nvidia_drm)..."
    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak."$(date +%s)"
    sudo sed -i -E 's/^MODULES=\((.*)\)/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    # Nettoyage des éventuels doubles espaces
    sudo sed -i -E 's/MODULES=\([[:space:]]+/MODULES=(/' /etc/mkinitcpio.conf
    echo "-> /etc/mkinitcpio.conf mis à jour (sauvegarde .bak créée)."
fi

# 7. Création du Pacman Hook pour reconstruire l'initramfs lors des màj NVIDIA
echo ":: Configuration du Pacman Hook pour les futures mises à jour..."
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/nvidia.hook > /dev/null << 'EOF'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-open-dkms
Target=nvidia-dkms
Target=linux-zen
Target=linux
Target=linux-lts

[Action]
Description=Reconstruction automatique de l'initramfs pour NVIDIA...
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOF
echo "-> Hook /etc/pacman.d/hooks/nvidia.hook installé."

# 8. Configuration Docker si demandée
if [ "$CONFIGURE_DOCKER" = true ]; then
    if command -v nvidia-ctk &>/dev/null; then
        echo ":: Configuration du runtime Docker pour NVIDIA..."
        sudo nvidia-ctk runtime configure --runtime=docker || true
        if systemctl is-active --quiet docker; then
            sudo systemctl restart docker
            echo "-> Daemon Docker redémarré avec le runtime NVIDIA."
        fi
    fi
fi

# 9. Régénération de l'initramfs
echo ":: Régénération de l'initramfs via mkinitcpio..."
sudo mkinitcpio -P

echo ""
echo "=========================================================="
echo "  Pilotes GPU installés et configurés avec succès !"
echo "  Pense à redémarrer ta machine pour charger les modules :"
echo "  sudo reboot"
echo "=========================================================="
