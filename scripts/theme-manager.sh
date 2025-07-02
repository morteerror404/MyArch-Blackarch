#!/bin/bash
# Hyprland Theme Manager with Rollback
# License: GPLv3
# Author: MorteError404 + Chat gptola

# Configurações
THEMES_DIR="$HOME/.themes"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
BACKUP_DIR="$HOME/.theme-backups"
LOG_FILE="/tmp/hypr-theme-manager.log"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Inicialização
init_backup() {
    mkdir -p "$BACKUP_DIR"
    local backup_name="hyprland-backup-$(date +%Y%m%d_%H%M%S)"
    cp "$HYPR_CONF" "$BACKUP_DIR/$backup_name.conf"
    echo -e "${BLUE}Backup criado: $BACKUP_DIR/$backup_name.conf${NC}" | tee -a "$LOG_FILE"
}

apply_theme() {
    local theme=$1
    echo -e "${YELLOW}Aplicando tema $theme...${NC}" | tee -a "$LOG_FILE"
    
    # Backup antes de aplicar
    init_backup
    
    case $theme in
        minimalist)
            sed -i 's/^colors:.*/colors: minimalist/' "$HYPR_CONF"
            sed -i 's/^decoration:.*/decoration: clean/' "$HYPR_CONF"
            ;;
        hacker)
            sed -i 's/^colors:.*/colors: hacker/' "$HYPR_CONF"
            sed -i 's/^decoration:.*/decoration: terminal/' "$HYPR_CONF"
            ;;
        dracula)
            sed -i 's/^colors:.*/colors: dracula/' "$HYPR_CONF"
            sed -i 's/^decoration:.*/decoration: gothic/' "$HYPR_CONF"
            ;;
        *)
            echo -e "${RED}Tema desconhecido!${NC}" | tee -a "$LOG_FILE"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Tema aplicado com sucesso!${NC}" | tee -a "$LOG_FILE"
}

list_backups() {
    echo -e "${BLUE}Backups disponíveis:${NC}"
    ls -1t "$BACKUP_DIR"/*.conf 2>/dev/null | awk -F/ '{print NR") " $NF}'
}

restore_backup() {
    list_backups
    read -p "Selecione o backup para restaurar: " backup_num
    
    local backups=($(ls -1t "$BACKUP_DIR"/*.conf 2>/dev/null))
    if [ -z "${backups[$((backup_num-1))]}" ]; then
        echo -e "${RED}Backup inválido!${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    local selected_backup="${backups[$((backup_num-1))]}"
    cp "$selected_backup" "$HYPR_CONF"
    
    echo -e "${GREEN}Backup restaurado: $selected_backup${NC}" | tee -a "$LOG_FILE"
}

show_menu() {
    echo -e "\n${BLUE}=== Gerenciador de Temas Hyprland ===${NC}"
    echo "1) Aplicar tema Minimalista"
    echo "2) Aplicar tema Hacker"
    echo "3) Aplicar tema Dracula"
    echo "4) Restaurar backup"
    echo "5) Listar backups"
    echo -e "${RED}0) Sair${NC}"
}

main() {
    # Verificar se Hyprland está instalado
    if ! command -v hyprctl &>/dev/null; then
        echo -e "${RED}Hyprland não está instalado!${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi

    mkdir -p "$THEMES_DIR"
    touch "$LOG_FILE"
    
    while true; do
        show_menu
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1) apply_theme minimalist ;;
            2) apply_theme hacker ;;
            3) apply_theme dracula ;;
            4) restore_backup ;;
            5) list_backups ;;
            0) exit 0 ;;
            *) echo -e "${RED}Opção inválida!${NC}" | tee -a "$LOG_FILE" ;;
        esac
        
        # Verificar se o Hyprland está ativo para reload
        if pgrep -x "Hyprland" >/dev/null; then
            read -p "Recarregar o Hyprland agora? (s/N) " reload
            if [[ "$reload" =~ [sS] ]]; then
                hyprctl reload
            fi
        fi
    done
}

main "$@"