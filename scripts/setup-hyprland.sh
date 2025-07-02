#!/bin/bash
# Hyprland Auto-Installer for HyprArch
# License: GPLv3
# Author: YourName

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}" >&2
    exit 1
fi

# Dependencies (updated list)
BASE_DEPS=(
    hyprland
    waybar
    rofi
    swaybg
    swaylock-effects
    wofi
    wl-clipboard
    kitty
    xdg-desktop-portal-hyprland
)

# Additional recommended packages
EXTRA_DEPS=(
    grim
    slurp
    swappy
    polkit-kde-agent
    qt5-wayland
    qt6-wayland
)
# Configurar NVIDIA se detectado
if lspci | grep -qi nvidia; then
    echo -e "${YELLOW}[+] Configurando NVIDIA...${NC}"
    pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
    echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
fi
# Install function with error handling
install_packages() {
    echo -e "${YELLOW}[+] Updating package databases...${NC}"
    pacman -Sy --noconfirm || {
        echo -e "${RED}Failed to update databases${NC}" >&2
        exit 1
    }

    echo -e "${YELLOW}[+] Installing Hyprland and base components...${NC}"
    pacman -S --needed --noconfirm "${BASE_DEPS[@]}" || {
        echo -e "${RED}Failed to install base packages${NC}" >&2
        exit 1
    }

    echo -e "${YELLOW}[+] Installing recommended utilities...${NC}"
    pacman -S --needed --noconfirm "${EXTRA_DEPS[@]}" || {
        echo -e "${YELLOW}Warning: Failed to install some optional packages${NC}" >&2
    }
}

# Configure default files
setup_configs() {
    echo -e "${YELLOW}[+] Setting up default configurations...${NC}"
    
    # Create config directory if not exists
    mkdir -p /etc/skel/.config/{hypr,waybar,rofi}

    # Hyprland config
    if [ ! -f /etc/skel/.config/hypr/hyprland.conf ]; then
        echo -e "${GREEN}Creating default Hyprland config...${NC}"
        cat > /etc/skel/.config/hypr/hyprland.conf << 'EOF'
# Default Hyprland Configuration
# See https://wiki.hyprland.org/Configuring/

monitor=,preferred,auto,1

exec-once = waybar & dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

input {
    kb_layout = us
    follow_mouse = 1
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
}

decoration {
    rounding = 5
    blur = true
}

animations {
    enabled = yes
}

bind = SUPER, Q, killactive,
bind = SUPER, M, exit,
bind = SUPER, V, togglefloating,
EOF
    fi

    # Waybar basic config
    if [ ! -f /etc/skel/.config/waybar/config ]; then
        echo -e "${GREEN}Creating default Waybar config...${NC}"
        cp /usr/share/waybar/config /etc/skel/.config/waybar/
    fi
}

# Main execution
main() {
    echo -e "${GREEN}Starting Hyprland installation...${NC}"
    
    install_packages
    setup_configs
    
    echo -e "${GREEN}[+] Installation complete!${NC}"
    echo -e "Default configurations created in /etc/skel/.config/"
    echo -e "For new users, these files will be copied to their home directory"
}

main "$@"