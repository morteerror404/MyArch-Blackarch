#!/bin/bash
# HyprArch Config Uninstaller
# License: GPLv3
# Author: SeuNome

# --- Global Config ---
set -euo pipefail
trap 'echo -e "\033[1;31mError at line $LINENO\033[0m"; exit 1' ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directories
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprarch-backups"
LOG_FILE="/tmp/hyprarch-uninstall.log"

# --- Functions ---

verify_configs() {
    echo -e "${YELLOW}Verifying HyprArch configurations...${NC}"
    
    declare -a config_dirs=("hypr" "waybar" "rofi")
    local found=0
    
    for dir in "${config_dirs[@]}"; do
        if [ -d "$CONFIG_DIR/$dir" ]; then
            echo -e "${BLUE}Found: $CONFIG_DIR/$dir${NC}"
            ((found++))
        fi
    done
    
    if [ $found -eq 0 ]; then
        echo -e "${YELLOW}No HyprArch configurations found in $CONFIG_DIR${NC}"
        return 1
    fi
}

confirm_uninstall() {
    echo -e "\n${RED}⚠️ WARNING: This will remove:${NC}"
    echo -e "  - ${RED}$CONFIG_DIR/hypr/${NC}"
    echo -e "  - ${RED}$CONFIG_DIR/waybar/${NC}"
    echo -e "  - ${RED}$CONFIG_DIR/rofi/${NC}"
    
    read -p "Are you sure? (y/N): " answer
    case "${answer,,}" in
        y|yes) return 0 ;;
        *)     return 1 ;;
    esac
}

create_final_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo -e "${YELLOW}Creating final backup...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_DIR/final-backup-$timestamp.tar.gz" \
        -C "$CONFIG_DIR" \
        hypr \
        waybar \
        rofi 2>> "$LOG_FILE"
    
    echo -e "${GREEN}Backup saved to $BACKUP_DIR/final-backup-$timestamp.tar.gz${NC}"
}

remove_configs() {
    echo -e "\n${RED}Removing configurations...${NC}"
    
    declare -a dirs_to_remove=("hypr" "waybar" "rofi")
    
    for dir in "${dirs_to_remove[@]}"; do
        if [ -d "$CONFIG_DIR/$dir" ]; then
            echo -e "${YELLOW}Removing $CONFIG_DIR/$dir...${NC}"
            rm -rfv "$CONFIG_DIR/$dir" >> "$LOG_FILE"
        fi
    done
    
    # Cleanup empty config directory
    if [ -z "$(ls -A "$CONFIG_DIR")" ]; then
        rmdir -v "$CONFIG_DIR" >> "$LOG_FILE"
    fi
}

# --- Main Execution ---
main() {
    echo -e "\n${BLUE}=== HyprArch Config Uninstaller ===${NC}"
    echo -e "Log file: ${YELLOW}$LOG_FILE${NC}"
    
    # Verify configs exist first
    if ! verify_configs; then
        echo -e "${YELLOW}Nothing to uninstall. Exiting.${NC}"
        exit 0
    fi
    
    if ! confirm_uninstall; then
        echo -e "${GREEN}Uninstall cancelled.${NC}"
        exit 0
    fi
    
    create_final_backup
    remove_configs
    
    echo -e "\n${GREEN}Uninstall complete!${NC}"
    echo -e "A backup was saved to ${YELLOW}$BACKUP_DIR${NC}"
    echo -e "Detailed log: ${YELLOW}$LOG_FILE${NC}"
}

main "$@"