#!/bin/bash
# Hyprland Theme Manager with Rollback
# License: GPLv3
# Author: MorteError404

# Configurações
THEMES_DIR="$HOME/.themes/hyprland"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
BACKUP_DIR="$HOME/.theme-backups"
LOG_FILE="/tmp/hypr-theme-manager.log"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verifica dependências
check_dependencies() {
    local deps=("hyprctl" "curl" "jq" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo -e "${RED}Erro: $dep não está instalado!${NC}" | tee -a "$LOG_FILE"
            exit 1
        fi
    done
}

# Inicialização de diretórios e backup
init_setup() {
    mkdir -p "$THEMES_DIR" "$BACKUP_DIR"
    chmod -R 755 "$THEMES_DIR" "$BACKUP_DIR"

    # Criar configurações padrão para temas predefinidos
    mkdir -p "$THEMES_DIR/minimalist" "$THEMES_DIR/hacker" "$THEMES_DIR/dracula"
    
    # Tema Minimalista
    if [ ! -f "$THEMES_DIR/minimalist/hyprland.conf" ]; then
        cat > "$THEMES_DIR/minimalist/hyprland.conf" << 'EOF'
# Minimalist Theme for Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=us; follow_mouse=1 }
general { gaps_in=2; gaps_out=5; border_size=1 }
decoration { rounding=0; blur=false }
animations { enabled=false }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
    fi

    # Tema Hacker
    if [ ! -f "$THEMES_DIR/hacker/hyprland.conf" ]; then
        cat > "$THEMES_DIR/hacker/hyprland.conf" << 'EOF'
# Hacker Theme for Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=us; follow_mouse=1 }
general { gaps_in=5; gaps_out=10; border_size=2; col.active_border=rgb(00ff00) }
decoration { rounding=5; blur=true; drop_shadow=true }
animations { enabled=true }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
    fi

    # Tema Dracula
    if [ ! -f "$THEMES_DIR/dracula/hyprland.conf" ]; then
        cat > "$THEMES_DIR/dracula/hyprland.conf" << 'EOF'
# Dracula Theme for Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=us; follow_mouse=1 }
general { gaps_in=5; gaps_out=15; border_size=3; col.active_border=rgb(bd93f9) }
decoration { rounding=8; blur=true; drop_shadow=true }
animations { enabled=true }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
    fi
}

# Backup da configuração atual
init_backup() {
    if [ ! -f "$HYPR_CONF" ]; then
        echo -e "${RED}Erro: $HYPR_CONF não encontrado!${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    local backup_name="hyprland-backup-$(date +%Y%m%d_%H%M%S)"
    cp "$HYPR_CONF" "$BACKUP_DIR/$backup_name.conf" || {
        echo -e "${RED}Erro ao criar backup!${NC}" | tee -a "$LOG_FILE"
        return 1
    }
    echo -e "${BLUE}Backup criado: $BACKUP_DIR/$backup_name.conf${NC}" | tee -a "$LOG_FILE"
}

# Aplicar tema existente
apply_theme() {
    local theme=$1
    local theme_conf="$THEMES_DIR/$theme/hyprland.conf"
    
    if [ ! -f "$theme_conf" ]; then
        echo -e "${RED}Erro: Configuração do tema $theme não encontrada!${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo -e "${YELLOW}Aplicando tema $theme...${NC}" | tee -a "$LOG_FILE"
    
    # Backup antes de aplicar
    init_backup || return 1
    
    cp "$theme_conf" "$HYPR_CONF" || {
        echo -e "${RED}Erro ao aplicar tema $theme!${NC}" | tee -a "$LOG_FILE"
        return 1
    }
    
    echo -e "${GREEN}Tema $theme aplicado com sucesso!${NC}" | tee -a "$LOG_FILE"
}

# Buscar e instalar temas do GitHub
fetch_themes() {
    echo -e "${YELLOW}[+] Buscando temas populares do Hyprland no GitHub...${NC}" | tee -a "$LOG_FILE"
    
    local query="hyprland+theme"
    local url="https://api.github.com/search/repositories?q=$query&sort=stars&order=desc&per_page=5"
    
    local response
    response=$(curl -s "$url")
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro: Falha ao buscar temas no GitHub${NC}" | tee -a "$LOG_FILE"
        return 1
    fi

    echo -e "${BLUE}Temas disponíveis no GitHub:${NC}"
    local themes
    themes=$(echo "$response" | jq -r '.items[] | "\(.name) (\(.stargazers_count) stars): \(.html_url)"')
    if [ -z "$themes" ]; then
        echo -e "${RED}Nenhum tema encontrado${NC}" | tee -a "$LOG_FILE"
        return 1
    fi

    local i=1
    declare -A theme_map
    while IFS= read -r line; do
        name=$(echo "$line" | cut -d'(' -f1 | xargs)
        url=$(echo "$line" | cut -d':' -f2- | xargs)
        echo "$i. $name"
        theme_map[$i]="$url"
        ((i++))
    done <<< "$themes"

    echo -en "${YELLOW}Selecione um tema (1-$((i-1)) ou 0 para cancelar): ${NC}"
    read -r choice
    if [ "$choice" -eq 0 ] || [ -z "$choice" ]; then
        echo -e "${BLUE}Instalação de tema cancelada${NC}" | tee -a "$LOG_FILE"
        return 0
    fi

    if [ -z "${theme_map[$choice]}" ]; then
        echo -e "${RED}Seleção inválida!${NC}" | tee -a "$LOG_FILE"
        return 1
    fi

    local theme_name
    theme_name=$(echo "${theme_map[$choice]}" | awk -F'/' '{print $NF}' | sed 's/.git$//')
    local theme_dir="$THEMES_DIR/$theme_name"
    
    echo -e "${YELLOW}Instalando tema $theme_name...${NC}" | tee -a "$LOG_FILE"
    git clone "${theme_map[$choice]}" "$theme_dir" || {
        echo -e "${RED}Erro: Falha ao clonar tema${NC}" | tee -a "$LOG_FILE"
        return 1
    }

    if [ -f "$theme_dir/hyprland.conf" ]; then
        apply_theme "$theme_name"
    else
        echo -e "${YELLOW}Aviso: Nenhum hyprland.conf encontrado no tema. Tema salvo em $theme_dir${NC}" | tee -a "$LOG_FILE"
    fi
}

# Listar backups
list_backups() {
    echo -e "${BLUE}Backups disponíveis:${NC}"
    local backups=($(ls -1t "$BACKUP_DIR"/*.conf 2>/dev/null))
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${YELLOW}Nenhum backup encontrado${NC}"
        return 0
    fi
    for i in "${!backups[@]}"; do
        echo "$((i+1)). ${backups[$i]##*/}"
    done
}

# Restaurar backup
restore_backup() {
    local backups=($(ls -1t "$BACKUP_DIR"/*.conf 2>/dev/null))
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum backup disponível!${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    list_backups
    echo -en "${YELLOW}Selecione o backup para restaurar: ${NC}"
    read -r backup_num
    
    if [ -z "${backups[$((backup_num-1))]}" ]; then
        echo -e "${RED}Backup inválido!${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    local selected_backup="${backups[$((backup_num-1))]}"
    cp "$selected_backup" "$HYPR_CONF" || {
        echo -e "${RED}Erro ao restaurar backup!${NC}" | tee -a "$LOG_FILE"
        return 1
    }
    
    echo -e "${GREEN}Backup restaurado: $selected_backup${NC}" | tee -a "$LOG_FILE"
}

# Listar temas disponíveis
list_themes() {
    echo -e "${BLUE}Temas disponíveis:${NC}"
    local themes=($(ls -1 "$THEMES_DIR" 2>/dev/null))
    if [ ${#themes[@]} -eq 0 ]; then
        echo -e "${YELLOW}Nenhum tema instalado${NC}"
        return 0
    fi
    for i in "${!themes[@]}"; do
        echo "$((i+1)). ${themes[$i]}"
    done
}

# Menu principal
show_menu() {
    echo -e "\n${BLUE}=== Gerenciador de Temas Hyprland ===${NC}"
    echo "1) Aplicar tema existente"
    echo "2) Instalar novo tema do GitHub"
    echo "3) Restaurar backup"
    echo "4) Listar backups"
    echo "5) Listar temas instalados"
    echo -e "${RED}0) Sair${NC}"
}

# Função principal
main() {
    check_dependencies
    init_setup
    touch "$LOG_FILE"
    
    while true; do
        show_menu
        echo -en "${YELLOW}Escolha uma opção: ${NC}"
        read -r choice
        
        case $choice in
            1)
                list_themes
                local themes=($(ls -1 "$THEMES_DIR" 2>/dev/null))
                if [ ${#themes[@]} -eq 0 ]; then
                    echo -e "${RED}Nenhum tema disponível para aplicar${NC}" | tee -a "$LOG_FILE"
                    continue
                fi
                echo -en "${YELLOW}Selecione o tema: ${NC}"
                read -r theme_num
                if [ -z "${themes[$((theme_num-1))]}" ]; then
                    echo -e "${RED}Tema inválido!${NC}" | tee -a "$LOG_FILE"
                    continue
                fi
                apply_theme "${themes[$((theme_num-1))]}" ;;
            2) fetch_themes ;;
            3) restore_backup ;;
            4) list_backups ;;
            5) list_themes ;;
            0) exit 0 ;;
            *) echo -e "${RED}Opção inválida!${NC}" | tee -a "$LOG_FILE" ;;
        esac
        
        if pgrep -x "Hyprland" >/dev/null; then
            echo -en "${YELLOW}Recarregar o Hyprland agora? (s/N) ${NC}"
            read -r reload
            if [[ "$reload" =~ [sS] ]]; then
                hyprctl reload
            fi
        fi
    done
}

main "$@"