#!/bin/bash
# HyprArch All-in-One Installer
# License: GPLv3
# Author: Combined from multiple sources

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories and files
CONFIG_DIR="/etc/skel/.config"
THEMES_DIR="$HOME/.themes/hyprland"
BACKUP_DIR="/etc/hyprarch-backups"
LOG_FILE="/var/log/hyprarch-install.log"
PACMAN_CONF="/etc/pacman.conf"
HYPR_CONF="$CONFIG_DIR/hypr/hyprland.conf"

# BlackArch mirrors
MIRRORS=(
    "http://au.mirrors.cicku.me/blackarch/\$repo/os/\$arch"
    "https://au.mirrors.cicku.me/blackarch/\$repo/os/\$arch"
    "http://blackarch.mirror.digitalpacific.com.au/\$repo/os/\$arch"
    "http://mirror.easyname.at/blackarch/\$repo/os/\$arch"
    "https://ca.mirrors.cicku.me/blackarch/\$repo/os/\$arch"
    "https://mirrors.hust.edu.cn/blackarch/\$repo/os/\$arch"
    "https://mirrors.nju.edu.cn/blackarch/\$repo/os/\$arch"
    "http://mirrors.aliyun.com/blackarch/\$repo/os/\$arch"
    "http://mirrors.dotsrc.org/blackarch/\$repo/os/\$arch"
    "http://mirror.cedia.org.ec/blackarch/\$repo/os/\$arch"
    "http://blackarch.leneveu.fr/blackarch/\$repo/os/\$arch"
    "http://mirror.cyberbits.eu/blackarch/\$repo/os/\$arch"
    "https://www.blackarch.org/blackarch/\$repo/os/\$arch"
    "http://de.mirrors.cicku.me/blackarch/\$repo/os/\$arch"
    "https://ftp.halifax.rwth-aachen.de/blackarch/\$repo/os/\$arch"
    "http://blackarch.unixpeople.org/\$repo/os/\$arch"
    "http://ftp.cc.uoc.gr/mirrors/linux/blackarch/\$repo/os/\$arch"
)

# BlackArch categories
CATEGORIES=(
    "automation" "backdoor" "binary" "cracker" "crypto" "database" "defensive"
    "dos" "exploitation" "forensic" "fuzzer" "malware" "mobile" "networking"
    "recon" "scanner" "social" "webapp" "windows" "wireless"
)

# Dependencies
BASE_DEPS=(
    hyprland waybar rofi swaybg swaylock-effects wofi wl-clipboard kitty
    xdg-desktop-portal-hyprland curl jq git
)
EXTRA_DEPS=(
    grim slurp swappy polkit-kde-agent qt5-wayland qt6-wayland
)

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Setup logging
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo -e "${BLUE}Installation started at $(date)${NC}"
}

# Check internet connectivity
check_connectivity() {
    echo -e "${YELLOW}Checking internet connectivity...${NC}"
    ping -c 1 archlinux.org >/dev/null 2>&1 || {
        echo -e "${RED}Error: No internet connection detected${NC}"
        exit 1
    }
}

# Install base system
install_base() {
    echo -e "${YELLOW}Installing base system...${NC}"
    pacstrap /mnt base base-devel linux linux-firmware networkmanager grub efibootmgr sudo nano || {
        echo -e "${RED}Error: Failed to install base system${NC}"
        exit 1
    }
}

# Configure base system
configure_system() {
    echo -e "${YELLOW}Configuring system...${NC}"
    genfstab -U /mnt >> /mnt/etc/fstab
    ln -sf /usr/share/zoneinfo/Region/City /mnt/etc/localtime
    hwclock --systohc
    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
    echo "hyprarch" > /mnt/etc/hostname
}

# Install Hyprland and dependencies
install_hyprland() {
    echo -e "${YELLOW}Installing Hyprland and dependencies...${NC}"
    pacman -Sy --noconfirm
    pacman -S --needed --noconfirm "${BASE_DEPS[@]}" || {
        echo -e "${RED}Error: Failed to install base Hyprland packages${NC}"
        exit 1
    }
    pacman -S --needed --noconfirm "${EXTRA_DEPS[@]}" || {
        echo -e "${YELLOW}Warning: Failed to install some optional packages${NC}"
    }
}

# Configure NVIDIA if detected
configure_nvidia() {
    if lspci | grep -qi nvidia; then
        echo -e "${YELLOW}Configuring NVIDIA...${NC}"
        pacman -S --noconfirm nvidia nvidia-utils nvidia-settings || {
            echo -e "${RED}Error: Failed to install NVIDIA packages${NC}"
            exit 1
        }
        echo "options nvidia-drm modeset=1" > /mnt/etc/modprobe.d/nvidia.conf
    fi
}

# Setup default Hyprland configurations
setup_hyprland_configs() {
    echo -e "${YELLOW}Setting up default Hyprland configurations...${NC}"
    mkdir -p "$CONFIG_DIR"/{hypr,waybar,rofi}
    chmod -R 755 "$CONFIG_DIR"
    
    if [ ! -f "$HYPR_CONF" ]; then
        cat > "$HYPR_CONF" << 'EOF'
# Default Hyprland Configuration
monitor=,preferred,auto,1
exec-once=waybar & dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
input { kb_layout=us; follow_mouse=1 }
general { gaps_in=5; gaps_out=10; border_size=2 }
decoration { rounding=5; blur=true }
animations { enabled=yes }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
    fi
    
    if [ -f /usr/share/waybar/config ] && [ ! -f "$CONFIG_DIR/waybar/config" ]; then
        cp /usr/share/waybar/config "$CONFIG_DIR/waybar/"
    fi
}

# Install BlackArch
install_blackarch() {
    echo -e "${YELLOW}Installing BlackArch...${NC}"
    if ! grep -q "\[blackarch\]" "$PACMAN_CONF"; then
        curl -O https://blackarch.org/strap.sh || {
            echo -e "${RED}Error: Failed to download strap.sh${NC}"
            exit 1
        }
        expected_checksum=$(curl -s https://blackarch.org/checksums | grep strap.sh | awk '{print $1}')
        actual_checksum=$(sha1sum strap.sh | awk '{print $1}')
        if [ "$expected_checksum" != "$actual_checksum" ]; then
            echo -e "${RED}Error: Checksum mismatch for strap.sh${NC}"
            exit 1
        }
        chmod +x strap.sh
        ./strap.sh || {
            echo -e "${RED}Error: Failed to run strap.sh${NC}"
            exit 1
        }
        rm -f strap.sh checksums
    fi
    
    update_mirrorlist
    register_category_repos
    pacman -Syyu --noconfirm || {
        echo -e "${RED}Error: Failed to update repositories${NC}"
        exit 1
    }
    pacman -S --noconfirm blackarch-{networking,scanner,forensic} nmap wireshark-qt metasploit sqlmap || {
        echo -e "${RED}Error: Failed to install BlackArch tools${NC}"
        exit 1
    }
}

# Update mirrorlist
update_mirrorlist() {
    local mirrorlist="/etc/pacman.d/mirrorlist"
    cp "$mirrorlist" "${mirrorlist}.blackarch.bak"
    for mirror in "${MIRRORS[@]}"; do
        if ! grep -Fx "Server = $mirror" "$mirrorlist" > /dev/null; then
            echo "Server = $mirror" >> "$mirrorlist"
        fi
    done
}

# Register BlackArch category repositories
register_category_repos() {
    cp "$PACMAN_CONF" "${PACMAN_CONF}.blackarch.bak"
    if ! grep -q "\[blackarch\]" "$PACMAN_CONF"; then
        echo -e "\n[blackarch]" >> "$PACMAN_CONF"
        for mirror in "${MIRRORS[@]}"; do
            echo -e "Server = $mirror" >> "$PACMAN_CONF"
        done
    fi
    for category in "${CATEGORIES[@]}"; do
        repo_name="blackarch-$category"
        if ! grep -q "\[${repo_name}\]" "$PACMAN_CONF"; then
            echo -e "\n[${repo_name}]" >> "$PACMAN_CONF"
            for mirror in "${MIRRORS[@]}"; do
                echo -e "Server = $mirror" >> "$PACMAN_CONF"
            done
        fi
    done
}

# Configure pacman
configure_pacman() {
    echo -e "${YELLOW}Configuring pacman...${NC}"
    mkdir -p "$BACKUP_DIR"
    cp "$PACMAN_CONF" "$BACKUP_DIR/pacman.conf.bak.$(date +%Y%m%d_%H%M%S)"
    for feature in "ParallelDownloads = 5" "Color" "ILoveCandy" "VerbosePkgLists" "CheckSpace"; do
        if grep -q "^#$feature" "$PACMAN_CONF"; then
            sed -i "s/^#$feature/$feature/" "$PACMAN_CONF"
        elif ! grep -q "^$feature" "$PACMAN_CONF"; then
            echo "$feature" >> "$PACMAN_CONF"
        fi
    done
    echo "MAKEFLAGS=\"-j$(nproc)\"" >> "$PACMAN_CONF"
}

# Setup themes
setup_themes() {
    echo -e "${YELLOW}Setting up themes...${NC}"
    mkdir -p "$THEMES_DIR" "$BACKUP_DIR"
    chmod -R 755 "$THEMES_DIR" "$BACKUP_DIR"
    
    for theme in minimalist hacker dracula; do
        mkdir -p "$THEMES_DIR/$theme"
        case $theme in
            minimalist)
                cat > "$THEMES_DIR/$theme/hyprland.conf" << 'EOF'
# Minimalist Theme for Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=us; follow_mouse=1 }
general { gaps_in=2; gaps_out=5; border_size=1 }
decoration { rounding=0; blur=false }
animations { enabled=false }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
                ;;
            hacker)
                cat > "$THEMES_DIR/$theme/hyprland.conf" << 'EOF'
# Hacker Theme for Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=us; follow_mouse=1 }
general { gaps_in=5; gaps_out=10; border_size=2; col.active_border=rgb(00ff00) }
decoration { rounding=5; blur=true; drop_shadow=true }
animations { enabled=true }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
                ;;
            dracula)
                cat > "$THEMES_DIR/$theme/hyprland.conf" << 'EOF'
# Dracula Theme for Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=us; follow_mouse=1 }
general { gaps_in=5; gaps_out=15; border_size=3; col.active_border=rgb(bd93f9) }
decoration { rounding=8; blur=true; drop_shadow=true }
animations { enabled=true }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
                ;;
        esac
    done
}

# Fetch themes from GitHub
fetch_themes() {
    echo -e "${YELLOW}Fetching themes from GitHub...${NC}"
    local query="hyprland+theme"
    local url="https://api.github.com/search/repositories?q=$query&sort=stars&order=desc&per_page=5"
    local response=$(curl -s "$url")
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to fetch themes${NC}"
        return 1
    fi
    local themes=$(echo "$response" | jq -r '.items[] | "\(.name) (\(.stargazers_count) stars): \(.html_url)"')
    if [ -z "$themes" ]; then
        echo -e "${RED}No themes found${NC}"
        return 1
    fi
    local i=1
    declare -A theme_map
    while IFS= read -r line; do
        name=$(echo "$line" | cut -d'(' -f1 | xargs)
        url=$(echo "$line" | cut -d':' -f2- | xargs)
        echo "$i. $name"
        theme_map[$i]="$url"
        ((i++))
    done <<< "$themes"
    echo -en "${YELLOW}Select a theme (1-$((i-1)) or 0 to skip): ${NC}"
    read -r choice
    if [ "$choice" -eq 0 ] || [ -z "$choice" ]; then
        echo -e "${BLUE}Skipping theme installation${NC}"
        return 0
    fi
    if [ -z "${theme_map[$choice]}" ]; then
        echo -e "${RED}Invalid selection${NC}"
        return 1
    fi
    local theme_name=$(echo "${theme_map[$choice]}" | awk -F'/' '{print $NF}' | sed 's/.git$//')
    local theme_dir="$THEMES_DIR/$theme_name"
    git clone "${theme_map[$choice]}" "$theme_dir" || {
        echo -e "${RED}Error: Failed to clone theme${NC}"
        return 1
    }
    if [ -f "$theme_dir/hyprland.conf" ]; then
        cp "$HYPR_CONF" "$BACKUP_DIR/hyprland-backup-$(date +%Y%m%d_%H%M%S).conf"
        cp "$theme_dir/hyprland.conf" "$HYPR_CONF"
        echo -e "${GREEN}Theme $theme_name applied${NC}"
    else
        echo -e "${YELLOW}No hyprland.conf in theme${NC}"
    fi
    rm -rf "$theme_dir"
}

# Install additional utilities
install_utils() {
    echo -e "${BLUE}Install additional utilities? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${BLUE}Select utilities:${NC}"
        echo "1) Zsh + Oh-My-Zsh"
        echo "2) Htop"
        echo "3) Neofetch"
        echo "4) All"
        echo "5) Custom"
        echo -e "${BLUE}Enter numbers (comma-separated):${NC}"
        read -r choices
        IFS=',' read -ra selections <<< "$choices"
        for choice in "${selections[@]}"; do
            case "$choice" in
                1)
                    pacman -S --noconfirm zsh zsh-completions
                    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
                    echo -e "${BLUE}Enter username for Zsh (blank to skip):${NC}"
                    read -r target_user
                    [ -n "$target_user" ] && chsh -s /bin/zsh "$target_user"
                    ;;
                2) pacman -S --noconfirm htop ;;
                3) pacman -S --noconfirm neofetch ;;
                4) 
                    pacman -S --noconfirm zsh zsh-completions htop neofetch
                    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
                    echo -e "${BLUE}Enter username for Zsh (blank to skip):${NC}"
                    read -r target_user
                    [ -n "$target_user" ] && chsh -s /bin/zsh "$target_user"
                    ;;
                5)
                    echo -e "${BLUE}Enter custom packages (space-separated):${NC}"
                    read -r custom_packages
                    pacman -S --noconfirm $custom_packages
                    ;;
                *) echo -e "${RED}Invalid option: $choice${NC}" ;;
            esac
        done
    fi
}

# Main function
main() {
    check_root
    setup_logging
    check_connectivity
    
    echo -e "${GREEN}Starting HyprArch installation...${NC}"
    
    echo -e "${BLUE}Select components to install:${NC}"
    echo "1) Base system"
    echo "2) Hyprland"
    echo "3) BlackArch tools"
    echo "4) Themes"
    echo "5) Pacman optimizations"
    echo "6) Additional utilities"
    echo "7) All"
    echo -e "${BLUE}Enter numbers (comma-separated):${NC}"
    read -r choices
    
    IFS=',' read -ra selections <<< "$choices"
    for choice in "${selections[@]}"; do
        case "$choice" in
            1) install_base; configure_system ;;
            2) install_hyprland; configure_nvidia; setup_hyprland_configs ;;
            3) install_blackarch ;;
            4) setup_themes; fetch_themes ;;
            5) configure_pacman ;;
            6) install_utils ;;
            7)
                install_base
                configure_system
                install_hyprland
                configure_nvidia
                setup_hyprland_configs
                install_blackarch
                setup_themes
                fetch_themes
                configure_pacman
                install_utils
                ;;
            *) echo -e "${RED}Invalid option: $choice${NC}" ;;
        esac
    done
    
    echo -e "${GREEN}Installation complete! Log: $LOG_FILE${NC}"
}

main "$@"