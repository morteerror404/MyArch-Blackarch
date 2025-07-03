#!/bin/bash
# BlackArch Installer for HyprArch
# License: GPLv3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Install security tools
echo -e "${YELLOW}[+] Installing security tools...${NC}"
pacman -S --noconfirm \
    blackarch-{networking,scanner,forensic} \
    nmap wireshark-qt metasploit sqlmap

# Prompt for additional tools
echo -e "${BLUE}\n[?] Install additional utilities? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${BLUE}[?] Select tools to install:${NC}"
    echo -e "1) Zsh + Oh-My-Zsh (shell)"
    echo -e "2) Htop (process monitor)"
    echo -e "3) Neofetch (system info)"
    echo -e "4) All of the above"
    echo -e "5) Custom list"
    echo -e "${BLUE}Enter numbers (comma-separated, e.g., 1,2,3):${NC}"
    read -r choices

    IFS=',' read -ra selections <<< "$choices"
    for choice in "${selections[@]}"; do
        case "$choice" in
            1)
                echo -e "${YELLOW}[+] Installing Zsh...${NC}"
                pacman -S --noconfirm zsh zsh-completions
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
                chsh -s /bin/zsh "$(whoami)"
                ;;
            2)
                echo -e "${YELLOW}[+] Installing Htop...${NC}"
                pacman -S --noconfirm htop
                ;;
            3)
                echo -e "${YELLOW}[+] Installing Neofetch...${NC}"
                pacman -S --noconfirm neofetch
                ;;
            4)
                echo -e "${YELLOW}[+] Installing all utilities...${NC}"
                pacman -S --noconfirm zsh htop neofetch
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
                chsh -s /bin/zsh "$(whoami)"
                ;;
            5)
                echo -e "${BLUE}[?] Enter custom packages (space-separated, e.g., tmux bat):${NC}"
                read -r custom_packages
                pacman -S --noconfirm $custom_packages
                ;;
            *)
                echo -e "${RED}Invalid option: $choice${NC}"
                ;;
        esac
    done
fi

# Cleanup
rm -f strap.sh
echo -e "${GREEN}[+] Installation complete!${NC}"