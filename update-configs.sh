#!/bin/bash
# HyprArch Config Updater
# License: GPLv3
# Author: SeuNome

# --- Global Configuration ---
set -euo pipefail
trap 'echo -e "\033[1;31mError at line $LINENO\033[0m"; exit 1' ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprarch-backups"
LOCK_FILE="/tmp/hyprarch-update.lock"
LOG_FILE="/tmp/hyprarch-update.log"

# --- Functions ---

check_dependencies() {
    local missing=()
    for cmd in git rsync tar; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing dependencies:${NC} ${missing[*]}"
        exit 1
    fi
}

create_lock() {
    if [ -f "$LOCK_FILE" ]; then
        echo -e "${RED}Update already in progress!${NC}"
        echo -e "If this is incorrect, remove: ${YELLOW}$LOCK_FILE${NC}"
        exit 1
    fi
    touch "$LOCK_FILE"
}

cleanup_lock() {
    rm -f "$LOCK_FILE"
}

backup_current() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo -e "${YELLOW}Creating backup...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_DIR/pre-update-$timestamp.tar.gz" \
        -C "$CONFIG_DIR" \
        hypr \
        waybar \
        rofi 2>> "$LOG_FILE"
    
    echo -e "${GREEN}Backup saved to $BACKUP_DIR/pre-update-$timestamp.tar.gz${NC}"
}

update_repo() {
    echo -e "${BLUE}Updating repository...${NC}"
    
    cd "$REPO_DIR"
    git fetch origin 2>> "$LOG_FILE"
    
    local changes=$(git diff --name-only origin/main)
    if [ -z "$changes" ]; then
        echo -e "${GREEN}Already up to date!${NC}"
        return 1
    fi
    
    git merge --ff-only origin/main 2>> "$LOG_FILE"
    return 0
}

sync_configs() {
    echo -e "${YELLOW}Synchronizing configurations...${NC}"
    
    declare -A config_map=(
        ["hypr"]="hyprland.conf exec.conf"
        ["waybar"]="config.jsonc style.css"
        ["rofi"]="config.rasi"
    )
    
    for dir in "${!config_map[@]}"; do
        echo -e "\n${BLUE}Updating $dir...${NC}"
        mkdir -p "$CONFIG_DIR/$dir"
        
        for file in ${config_map[$dir]}; do
            if [ -f "$REPO_DIR/configs/$dir/$file" ]; then
                rsync -av --checksum \
                    "$REPO_DIR/configs/$dir/$file" \
                    "$CONFIG_DIR/$dir/" | tee -a "$LOG_FILE"
            fi
        done
    done
    
    # Set executable permissions
    chmod +x "$CONFIG_DIR/hypr/exec.conf" 2>/dev/null
}

verify_update() {
    echo -e "\n${YELLOW}Verifying update...${NC}"
    
    declare -a critical_files=(
        "$CONFIG_DIR/hypr/hyprland.conf"
        "$CONFIG_DIR/waybar/config.jsonc"
        "$CONFIG_DIR/rofi/config.rasi"
    )
    
    for file in "${critical_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo -e "${RED}ERROR: Missing critical file after update: $file${NC}" >&2
            return 1
        fi
        
        if ! grep -q '^# HyprArch' "$file" 2>/dev/null; then
            echo -e "${YELLOW}WARNING: File may have been modified: $file${NC}"
        fi
    done
}

# --- Main Execution ---
main() {
    echo -e "\n${BLUE}=== HyprArch Config Updater ===${NC}"
    echo -e "Log file: ${YELLOW}$LOG_FILE${NC}"
    
    check_dependencies
    create_lock
    trap cleanup_lock EXIT
    
    if ! update_repo; then
        exit 0
    fi
    
    backup_current
    sync_configs
    
    if verify_update; then
        echo -e "\n${GREEN}Update successful!${NC}"
        echo -e "Changes saved to ${YELLOW}$BACKUP_DIR${NC}"
        echo -e "To apply changes: ${YELLOW}hyprctl reload${NC}"
    else
        echo -e "\n${RED}Update verification failed!${NC}"
        echo -e "Check log: ${YELLOW}$LOG_FILE${NC}"
        echo -e "Backup available in ${YELLOW}$BACKUP_DIR${NC}"
        exit 1
    fi
}

main "$@"