#!/bin/bash
# BlackArch Installer for HyprArch
# License: GPLv3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Run as root${NC}"
    exit 1
fi

# Install BlackArch strap
echo -e "${YELLOW}[+] Installing BlackArch...${NC}"
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
./strap.sh

# Update repos
echo -e "${YELLOW}[+] Updating repositories...${NC}"
pacman -Syyu --noconfirm

# Install tools by category
echo -e "${YELLOW}[+] Installing security tools...${NC}"
pacman -S --noconfirm \
    blackarch-{networking,scanner,forensic} \
    nmap wireshark-qt metasploit sqlmap

# Cleanup
rm strap.sh
echo -e "${GREEN}[+] BlackArch installed successfully!${NC}"