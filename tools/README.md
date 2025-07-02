# 🛠️ Ferramentas do HyprArch

## network-scanner.sh
**Descrição**: Scanner completo de rede que verifica:
- Interfaces de rede
- Conexões ativas
- Tabela ARP
- Teste de ping

**Uso**:
```bash
./network-scanner.sh~

Aqui estão os três arquivos completos para o diretório `tools/`:

### 1. `network-scanner.sh`
```bash
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
```

### 2. `system-monitor.sh`
```bash
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
```

### 3. `README.md`
```markdown
# 🛠️ Ferramentas do HyprArch

## network-scanner.sh
**Descrição**: Scanner completo de rede que verifica:
- Interfaces de rede
- Conexões ativas
- Tabela ARP
- Teste de ping

**Uso**:
```bash
./network-scanner.sh
```

**Saída**: Relatório salvo em `~/.cache/hyprarch-scans/`

## system-monitor.sh
**Descrição**: Monitor de recursos em tempo real que mostra:
- Uso de CPU/Memória
- Espaço em disco
- Temperatura da CPU

**Uso**:
```bash
./system-monitor.sh
```
**Atalho**: Pressione `Ctrl+C` para sair

## 📌 Dicas
1. Torne os scripts executáveis:
```bash
chmod +x *.sh
```

2. Para acesso rápido, crie aliases no seu `.bashrc`:
```bash
alias scan='~/tools/network-scanner.sh'
alias monitor='~/tools/system-monitor.sh'
```

3. Os scripts não requerem privilégios root para funcionamento básico