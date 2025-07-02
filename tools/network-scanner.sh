#!/bin/bash
# HyprArch Network Scanner
# License: GPLv3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
LOG_DIR="$HOME/.cache/hyprarch-scans"
SCAN_FILE="$LOG_DIR/scan-$(date +%Y%m%d_%H%M%S).log"

# Functions
scan_network() {
    echo -e "${YELLOW}[+] Starting network scan at $(date)${NC}"
    
    echo -e "\n${BLUE}=== Network Interfaces ===${NC}"
    ip -br -c addr show
    
    echo -e "\n${BLUE}=== Active Connections ===${NC}"
    ss -tulnp
    
    echo -e "\n${BLUE}=== ARP Table ===${NC}"
    ip -c neigh show
    
    echo -e "\n${BLUE}=== Ping Test ===${NC}"
    ping -c 4 8.8.8.8 | tail -n 3
}

# Main
mkdir -p "$LOG_DIR"
{
    echo -e "HyprArch Network Scan Report\n"
    scan_network
} | tee "$SCAN_FILE"

echo -e "${GREEN}[+] Scan saved to $SCAN_FILE${NC}"