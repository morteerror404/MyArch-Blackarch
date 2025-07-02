#!/bin/bash
# Hyprland Installer for HyprArch
# License: GPLv3

# Dependencies
DEPS=(
    hyprland
    waybar
    rofi
    swaybg
    swaylock-effects
    wofi
    wl-clipboard
    kitty
)

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Run as root" >&2
    exit 1
fi

# Install packages
echo "Installing Hyprland and components..."
pacman -S --needed --noconfirm "${DEPS[@]}"

# Configure default files
echo "Setting up default configurations..."
mkdir -p /etc/skel/.config/hypr
cp /usr/share/hyprland/hyprland.conf /etc/skel/.config/hypr/

echo "Hyprland installation complete!"