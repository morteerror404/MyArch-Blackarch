#!/bin/bash
# HyprArch Config Installer
# License: GPLv3
# Author: SeuNome

# --- Configurações Globais ---
set -euo pipefail
trap 'echo -e "\033[1;31mErro na linha $LINENO\033[0m"; exit 1' ERR

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretórios
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprarch-backups"
LOG_FILE="/tmp/hyprarch-install-configs.log"

# --- Funções Principais ---

init_dirs() {
    echo -e "${YELLOW}Inicializando diretórios...${NC}"
    mkdir -p "$BACKUP_DIR" "$CONFIG_DIR"/{hypr,waybar,rofi}
    touch "$LOG_FILE"
}

backup_existing() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo -e "${BLUE}Criando backup das configurações atuais...${NC}"
    
    declare -a config_dirs=("hypr" "waybar" "rofi")
    for dir in "${config_dirs[@]}"; do
        if [ -d "$CONFIG_DIR/$dir" ]; then
            echo -e "Backup: $dir" >> "$LOG_FILE"
            tar -czf "$BACKUP_DIR/$dir-$timestamp.tar.gz" -C "$CONFIG_DIR" "$dir" && \
            echo -e "${GREEN}Backup de $dir criado em $BACKUP_DIR/$dir-$timestamp.tar.gz${NC}"
        fi
    done
}

install_configs() {
    echo -e "${YELLOW}Instalando novas configurações...${NC}"
    
    declare -A config_map=(
        ["hypr"]="hyprland.conf exec.conf"
        ["waybar"]="config.jsonc style.css"
        ["rofi"]="config.rasi"
    )
    
    for dir in "${!config_map[@]}"; do
        echo -e "\n${BLUE}Configurando $dir...${NC}"
        for file in ${config_map[$dir]}; do
            if [ -f "$REPO_DIR/configs/$dir/$file" ]; then
                cp -v "$REPO_DIR/configs/$dir/$file" "$CONFIG_DIR/$dir/" | tee -a "$LOG_FILE"
            fi
        done
    done
    
    # Permissões especiais
    chmod +x "$CONFIG_DIR/hypr/exec.conf" 2>/dev/null
}

verify_installation() {
    echo -e "\n${YELLOW}Verificando instalação...${NC}"
    
    declare -a critical_files=(
        "$CONFIG_DIR/hypr/hyprland.conf"
        "$CONFIG_DIR/waybar/config.jsonc"
        "$CONFIG_DIR/rofi/config.rasi"
    )
    
    for file in "${critical_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo -e "${RED}ERRO: Arquivo crítico não instalado: $file${NC}" >&2
            return 1
        fi
    done
    
    echo -e "${GREEN}Todos arquivos de configuração foram instalados com sucesso!${NC}"
}

# --- Execução Principal ---
main() {
    echo -e "\n${BLUE}=== HyprArch Config Installer ===${NC}"
    echo -e "Configs serão instaladas em: ${YELLOW}$CONFIG_DIR${NC}"
    echo -e "Backups serão salvos em: ${YELLOW}$BACKUP_DIR${NC}"
    echo -e "Log detalhado: ${YELLOW}$LOG_FILE${NC}"
    
    init_dirs
    backup_existing
    install_configs
    verify_installation
    
    echo -e "\n${GREEN}Instalação concluída!${NC}"
    echo -e "Execute ${YELLOW}hyprctl reload${NC} para aplicar as configurações"
}

main "$@"