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
    curl
    jq
    git
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

# Check for internet connectivity
check_connectivity() {
    echo -e "${YELLOW}[+] Checking internet connectivity...${NC}"
    ping -c 1 archlinux.org >/dev/null 2>&1 || {
        echo -e "${RED}Error: No internet connection detected${NC}" >&2
        exit 1
    }
}

# Configurar NVIDIA se detectado
configure_nvidia() {
    if lspci | grep -qi nvidia; then
        echo -e "${YELLOW}[+] Configurando NVIDIA...${NC}"
        pacman -S --noconfirm nvidia nvidia-utils nvidia-settings || {
            echo -e "${RED}Failed to install NVIDIA packages${NC}" >&2
            exit 1
        }
        echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
    fi
}

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
    chmod -R 755 /etc/skel/.config

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
        if [ -f /usr/share/waybar/config ]; then
            cp /usr/share/waybar/config /etc/skel/.config/waybar/
        else
            echo -e "${YELLOW}Warning: Default Waybar config not found${NC}"
        fi
    fi
}

# Fetch popular Hyprland themes from GitHub
fetch_themes() {
    echo -e "${YELLOW}[+] Fetching popular Hyprland themes from GitHub...${NC}"
    
    # Search GitHub for Hyprland themes
    local query="hyprland+theme"
    local url="https://api.github.com/search/repositories?q=$query&sort=stars&order=desc&per_page=5"
    
    # Make API request
    local response
    response=$(curl -s "$url")
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to fetch themes from GitHub${NC}"
        return
    fi

    # Parse and display themes
    echo -e "${BLUE}Available Hyprland themes:${NC}"
    local themes
    themes=$(echo "$response" | jq -r '.items[] | "\(.name) (\(.stargazers_count) stars): \(.html_url)"')
    if [ -z "$themes" ]; then
        echo -e "${RED}No themes found${NC}"
        return
    fi

    # Display options
    local i=1
    declare -A theme_map
    while IFS= read -r line; do
        name=$(echo "$line" | cut -d'(' -f1 | xargs)
        url=$(echo "$line" | cut -d':' -f2- | xargs)
        echo "$i. $name"
        theme_map[$i]="$url"
        ((i++))
    done <<< "$themes"

    # Prompt user for selection
    echo -en "${YELLOW}Select a theme (1-$((i-1)) or 0 to skip): ${NC}"
    read -r choice
    if [ "$choice" -eq 0 ] || [ -z "$choice" ]; then
        echo -e "${BLUE}Skipping theme installation${NC}"
        return
    fi

    # Validate choice
    if [ -z "${theme_map[$choice]}" ]; then
        echo -e "${RED}Invalid selection${NC}"
        return
    fi

    # Clone selected theme
    echo -e "${YELLOW}Installing theme from ${theme_map[$choice]}...${NC}"
    local temp_dir
    temp_dir=$(mktemp -d)
    git clone "${theme_map[$choice]}" "$temp_dir" || {
        echo -e "${RED}Error: Failed to clone theme${NC}"
        rm -rf "$temp_dir"
        return
    }

    # Copy hyprland.conf if exists
    if [ -f "$temp_dir/hyprland.conf" ]; then
        cp "$temp_dir/hyprland.conf" /etc/skel/.config/hypr/hyprland.conf
        echo -e "${GREEN}Hyprland configuration from theme applied${NC}"
    else
        echo -e "${YELLOW}Warning: No hyprland.conf found in theme${NC}"
    fi

    # Clean up
    rm -rf "$temp_dir"
    echo -e "${GREEN}Theme installation complete${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}Starting HyprArch installation...${NC}"
    
    check_connectivity
    configure_nvidia
    install_packages
    setup_configs
    fetch_themes
    
    echo -e "${GREEN}[+] Installation complete!${NC}"
    echo -e "Default configurations created in /etc/skel/.config/"
    echo -e "For new users, these files will be copied to their home directory."
}

main "$@"