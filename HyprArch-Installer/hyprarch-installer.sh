#!/bin/bash

# HyprArch Installer - Arch Linux + Hyprland + BlackArch Tools
# License: GPLv3
# Author: YourName

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/hyprarch-backups"
LOG_FILE="/tmp/hyprarch-install.log"

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Setup logging
setup_logging() {
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo -e "${BLUE}Installation started at $(date)${NC}"
}

# Install base system
install_base() {
    echo -e "${YELLOW}Installing base system...${NC}"
    pacstrap /mnt base base-devel linux linux-firmware \
        networkmanager grub efibootmgr sudo nano
}

# Install Hyprland
install_hyprland() {
    echo -e "${YELLOW}Installing Hyprland...${NC}"
    pacman -S --noconfirm hyprland waybar rofi \
        swaybg swaylock-effects wofi wl-clipboard
}

# Install BlackArch tools
install_blackarch() {
    echo -e "${YELLOW}Installing BlackArch tools...${NC}"
    curl -O https://blackarch.org/strap.sh
    chmod +x strap.sh
    ./strap.sh
    pacman -Syu --noconfirm
    
    # Select tools by category
    pacman -S --noconfirm blackarch-{networking,scanner,forensic}
}

# Configure system
configure_system() {
    echo -e "${YELLOW}Configuring system...${NC}"
    # Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # Set timezone
    ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
    hwclock --systohc
    
    # Set locale
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    
    # Set hostname
    echo "hyprarch" > /etc/hostname
}

# Main function
main() {
    check_root
    setup_logging
    
    echo -e "${GREEN}Starting HyprArch installation...${NC}"
    
    install_base
    install_hyprland
    
    if [[ "$1" == "--blackarch" ]]; then
        install_blackarch
    fi
    
    configure_system
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "Log file: $LOG_FILE"
}

main "$@"