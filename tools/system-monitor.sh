#!/bin/bash
# HyprArch System Monitor
# License: GPLv3

# Refresh interval (seconds)
INTERVAL=2

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Monitor system resources
monitor() {
    while true; do
        clear
        echo -e "${GREEN}HyprArch System Monitor${NC}"
        echo -e "-------------------------"
        
        # CPU Usage
        echo -e "${YELLOW}CPU Usage:${NC}"
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
        
        # Memory
        echo -e "\n${YELLOW}Memory:${NC}"
        free -h | awk '/Mem/{printf "Used: %s/%s (%.2f%%)\n", $3,$2,$3*100/$2}'
        
        # Disk
        echo -e "\n${YELLOW}Disk Space:${NC}"
        df -h | grep -v "tmpfs" | awk '{print $1 ": " $5 " used (" $3 "/" $2 ")"}'
        
        # Temperature
        if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
            TEMP=$(($(cat /sys/class/thermal/thermal_zone0/temp)/1000))
            echo -e "\n${YELLOW}CPU Temp:${NC} $TEMP°C"
        fi
        
        sleep $INTERVAL
    done
}

# Start monitoring
monitor