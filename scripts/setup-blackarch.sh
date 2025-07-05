#!/bin/bash
# BlackArch Installer for HyprArch with Mirrorlist and Category Repository Registration
# License: GPLv3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log file
LOGFILE="/var/log/blackarch_install.log"

# BlackArch mirror list (sourced from https://blackarch.org/downloads.html)
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

# BlackArch tool categories (sourced from https://blackarch.org/tools.html)
CATEGORIES=(
    "automation"
    "backdoor"
    "binary"
    "cracker"
    "crypto"
    "database"
    "defensive"
    "dos"
    "exploitation"
    "forensic"
    "fuzzer"
    "malware"
    "mobile"
    "networking"
    "recon"
    "scanner"
    "social"
    "webapp"
    "windows"
    "wireless"
)

# Function to update /etc/pacman.d/mirrorlist with BlackArch mirrors
update_mirrorlist() {
    echo -e "${YELLOW}[+] Updating /etc/pacman.d/mirrorlist with BlackArch mirrors...${NC}" | tee -a "$LOGFILE"
    local mirrorlist="/etc/pacman.d/mirrorlist"

    # Backup mirrorlist
    if [ -f "$mirrorlist" ]; then
        cp "$mirrorlist" "${mirrorlist}.blackarch.bak"
        echo -e "${YELLOW}[+] Backed up mirrorlist to ${mirrorlist}.blackarch.bak${NC}" | tee -a "$LOGFILE"
    else
        echo -e "${RED}Error: mirrorlist file not found${NC}" | tee -a "$LOGFILE"
        exit 1
    fi

    # Add BlackArch mirrors if not already present
    for mirror in "${MIRRORS[@]}"; do
        if ! grep -Fx "Server = $mirror" "$mirrorlist" > /dev/null; then
            echo "Server = $mirror" >> "$mirrorlist"
            echo -e "${GREEN}[+] Added mirror: $mirror${NC}" | tee -a "$LOGFILE"
        else
            echo -e "${YELLOW}[!] Mirror already exists: $mirror${NC}" | tee -a "$LOGFILE"
        fi
    done
}

# Function to register BlackArch category repositories in pacman.conf
register_category_repos() {
    echo -e "${YELLOW}[+] Registering BlackArch category repositories in pacman.conf...${NC}" | tee -a "$LOGFILE"
    local pacman_conf="/etc/pacman.conf"

    # Backup pacman.conf
    if [ -f "$pacman_conf" ]; then
        cp "$pacman_conf" "${pacman_conf}.blackarch.bak"
        echo -e "${YELLOW}[+] Backed up pacman.conf to ${pacman_conf}.blackarch.bak${NC}" | tee -a "$LOGFILE"
    else
        echo -e "${RED}Error: pacman.conf not found${NC}" | tee -a "$LOGFILE"
        exit 1
    fi

    # Add main BlackArch repository
    if ! grep -q "\[blackarch\]" "$pacman_conf"; then
        echo -e "\n[blackarch]" >> "$pacman_conf"
        for mirror in "${MIRRORS[@]}"; do
            echo -e "Server = $mirror" >> "$pacman_conf"
        done
        echo -e "${GREEN}[+] Added main BlackArch repository${NC}" | tee -a "$LOGFILE"
    else
        echo -e "${YELLOW}[!] Main BlackArch repository already configured${NC}" | tee -a "$LOGFILE"
    fi

    # Add each category as a separate repository
    for category in "${CATEGORIES[@]}"; do
        repo_name="blackarch-$category"
        if ! grep -q "\[${repo_name}\]" "$pacman_conf"; then
            echo -e "\n[${repo_name}]" >> "$pacman_conf"
            for mirror in "${MIRRORS[@]}"; do
                echo -e "Server = $mirror" >> "$pacman_conf"
            done
            echo -e "${GREEN}[+] Added $repo_name repository${NC}" | tee -a "$LOGFILE"
        else
            echo -e "${YELLOW}[!] $repo_name repository already configured${NC}" | tee -a "$LOGFILE"
        fi
    done
}

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Run as root${NC}" | tee -a "$LOGFILE"
    exit 1
fi

# Check if BlackArch is already configured
if grep -q "\[blackarch\]" /etc/pacman.conf; then
    echo -e "${YELLOW}[!] BlackArch repository already configured${NC}" | tee -a "$LOGFILE"
else
    # Install BlackArch strap
    echo -e "${YELLOW}[+] Downloading BlackArch strap.sh...${NC}" | tee -a "$LOGFILE"
    if ! curl -O https://blackarch.org/strap.sh; then
        echo -e "${RED}Error: Failed to download strap.sh${NC}" | tee -a "$LOGFILE"
        exit 1
    fi

    # Verify checksum
    echo -e "${YELLOW}[+] Verifying strap.sh checksum...${NC}" | tee -a "$LOGFILE"
    if ! curl -O https://blackarch.org/checksums; then
        echo -e "${RED}Error: Failed to download checksums${NC}" | tee -a "$LOGFILE"
        exit 1
    fi
    expected_checksum=$(grep strap.sh checksums | awk '{print $1}')
    actual_checksum=$(sha1sum strap.sh | awk '{print $1}')
    if [ "$expected_checksum" != "$actual_checksum" ]; then
        echo -e "${RED}Error: Checksum mismatch for strap.sh${NC}" | tee -a "$LOGFILE"
        exit 1
    fi

    chmod +x strap.sh
    if ! ./strap.sh; then
        echo -e "${RED}Error: Failed to run strap.sh${NC}" | tee -a "$LOGFILE"
        exit 1
    fi
fi

# Update mirrorlist and pacman.conf
update_mirrorlist
register_category_repos

# Update repositories
echo -e "${YELLOW}[+] Updating repositories...${NC}" | tee -a "$LOGFILE"
if ! pacman -Syyu --noconfirm; then
    echo -e "${RED}Error: Failed to update repositories${NC}" | tee -a "$LOGFILE"
    exit 1
fi

# Install security tools
echo -e "${YELLOW}[+] Installing security tools...${NC}" | tee -a "$LOGFILE"
if ! pacman -S --noconfirm blackarch-networking blackarch-scanner blackarch-forensic nmap wireshark-qt metasploit sqlmap; then
    echo -e "${RED}Error: Failed to install some security tools${NC}" | tee -a "$LOGFILE"
    exit 1
fi

# Prompt for additional tools
echo -e "${BLUE}\n[?] Install additional utilities? (y/n)${NC}" | tee -a "$LOGFILE"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${BLUE}[?] Select tools to install:${NC}" | tee -a "$LOGFILE"
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
                echo -e "${YELLOW}[+] Installing Zsh...${NC}" | tee -a "$LOGFILE"
                if ! pacman -S --noconfirm zsh zsh-completions; then
                    echo -e "${RED}Error: Failed to install Zsh${NC}" | tee -a "$LOGFILE"
                    exit 1
                fi
                if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
                    echo -e "${RED}Error: Failed to install Oh-My-Zsh${NC}" | tee -a "$LOGFILE"
                    exit 1
                fi
                echo -e "${BLUE}[?] Enter username for Zsh shell change (leave blank to skip):${NC}" | tee -a "$LOGFILE"
                read -r target_user
                if [ -n "$target_user" ]; then
                    if ! chsh -s /bin/zsh "$target_user"; then
                        echo -e "${RED}Error: Failed to change shell for $target_user${NC}" | tee -a "$LOGFILE"
                    fi
                fi
                ;;
            2)
                echo -e "${YELLOW}[+] Installing Htop...${NC}" | tee -a "$LOGFILE"
                if ! pacman -S --noconfirm htop; then
                    echo -e "${RED}Error: Failed to install Htop${NC}" | tee -a "$LOGFILE"
                    exit 1
                fi
                ;;
            3)
                echo -e "${YELLOW}[+] Installing Neofetch...${NC}" | tee -a "$LOGFILE"
                if ! pacman -S --noconfirm neofetch; then
                    echo -e "${RED}Error: Failed to install Neofetch${NC}" | tee -a "$LOGFILE"
                    exit 1
                fi
                ;;
            4)
                echo -e "${YELLOW}[+] Installing all utilities...${NC}" | tee -a "$LOGFILE"
                if ! pacman -S --noconfirm zsh htop neofetch; then
                    echo -e "${RED}Error: Failed to install some utilities${NC}" | tee -a "$LOGFILE"
                    exit 1
                fi
                if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
                    echo -e "${RED}Error: Failed to install Oh-My-Zsh${NC}" | tee -a "$LOGFILE"
                    exit 1
                fi
                echo -e "${BLUE}[?] Enter username for Zsh shell change (leave blank to skip):${NC}" | tee -a "$LOGFILE"
                read -r target_user
                if [ -n "$target_user" ]; then
                    if ! chsh -s /bin/zsh "$target_user"; then
                        echo -e "${RED}Error: Failed to change shell for $target_user${NC}" | tee -a "$LOGFILE"
                    fi
                fi
                ;;
            5)
                echo -e "${BLUE}[?] Enter custom packages (space-separated, e.g., tmux bat):${NC}" | tee -a "$LOGFILE"
                read -r custom_packages
                if ! pacman -S --noconfirm $custom_packages; then
                    echo -e "${RED}Error: Failed to install some custom packages${NC}" | tee -a "$LOGFILE"
                    exit 1
                fi
                ;;
            *)
                echo -e "${RED}Invalid option: $choice${NC}" | tee -a "$LOGFILE"
                ;;
        esac
    done
fi

# Cleanup
rm -f strap.sh checksums
echo -e "${GREEN}[+] Installation complete!${NC}" | tee -a "$LOGFILE"'