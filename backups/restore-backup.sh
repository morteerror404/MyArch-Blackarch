#!/bin/bash
# HyprArch Backup Restorer
# Licença: GPLv3
# Autor: SeuNome

# Cores para feedback visual
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações de diretório
BACKUP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprarch-backups"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOG_FILE="/tmp/hyprarch-restore.log"

# Verificar e criar diretórios
init_dirs() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}ERRO: Diretório de backups não encontrado em $BACKUP_DIR${NC}" >&2
        exit 1
    fi
    mkdir -p "$CONFIG_DIR"
    touch "$LOG_FILE"
}

# Listar backups disponíveis
list_backups() {
    echo -e "${BLUE}Backups disponíveis:${NC}"
    local backups=($(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${YELLOW}Nenhum backup encontrado!${NC}"
        exit 1
    fi

    for i in "${!backups[@]}"; do
        echo "$((i+1)). ${backups[$i]##*/}"
    done
}

# Validar checksum do backup
validate_backup() {
    local backup_file="$1"
    echo -e "${YELLOW}Validando integridade do backup...${NC}"
    
    if ! tar -tzf "$backup_file" &>/dev/null; then
        echo -e "${RED}ERRO: Backup corrompido ou inválido!${NC}" >&2
        return 1
    fi
    
    # Verificar arquivos críticos
    if ! tar -tzf "$backup_file" | grep -q "hypr/"; then
        echo -e "${RED}ERRO: Backup não contém configurações do Hyprland!${NC}" >&2
        return 1
    fi
}

# Restaurar backup
restore() {
    local backup_file="$1"
    local temp_dir=$(mktemp -d)
    
    echo -e "${BLUE}Extraindo backup...${NC}"
    if ! tar -xzf "$backup_file" -C "$temp_dir"; then
        echo -e "${RED}Falha ao extrair backup!${NC}" >&2
        rm -rf "$temp_dir"
        exit 1
    fi

    echo -e "${YELLOW}Restaurando configurações...${NC}"
    rsync -av --checksum "$temp_dir/" "$CONFIG_DIR/" | tee -a "$LOG_FILE"
    
    # Corrigir permissões
    find "$CONFIG_DIR" -type d -exec chmod 755 {} \;
    find "$CONFIG_DIR" -type f -exec chmod 644 {} \;
    chmod +x "$CONFIG_DIR/hypr/exec.conf" 2>/dev/null
    
    rm -rf "$temp_dir"
}

# Menu principal
main_menu() {
    echo -e "\n${BLUE}=== HyprArch Backup Restorer ===${NC}"
    list_backups
    echo -e "${YELLOW}0) Cancelar${NC}"
    
    read -p "Selecione o backup para restaurar: " choice
    local backups=($(ls -1t "$BACKUP_DIR"/*.tar.gz))
    
    if [[ "$choice" == "0" ]]; then
        echo -e "${YELLOW}Operação cancelada.${NC}"
        exit 0
    elif [[ ! "${backups[$((choice-1))]+isset}" ]]; then
        echo -e "${RED}Seleção inválida!${NC}" >&2
        exit 1
    fi
    
    local selected_backup="${backups[$((choice-1))]}"
    
    if validate_backup "$selected_backup"; then
        restore "$selected_backup"
        echo -e "\n${GREEN}Backup restaurado com sucesso!${NC}"
        echo -e "Execute ${YELLOW}hyprctl reload${NC} para aplicar as mudanças."
    else
        echo -e "${RED}Falha ao restaurar backup. Verifique $LOG_FILE${NC}" >&2
        exit 1
    fi
}

# Execução principal
init_dirs
main_menu