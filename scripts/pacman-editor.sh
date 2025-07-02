#!/bin/bash
# HyprArch Pacman Config Editor
# Licença: GPLv3

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
PACMAN_CONF="/etc/pacman.conf"
BACKUP_DIR="/etc/pacman.d/backups"
BACKUP_FILE="$BACKUP_DIR/pacman.conf.bak.$(date +%Y%m%d_%H%M%S)"

# Função para criar backup
create_backup() {
    echo -e "${YELLOW}==> Criando backup do arquivo atual...${NC}"
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp "$PACMAN_CONF" "$BACKUP_FILE"
    echo -e "${GREEN}Backup salvo em: $BACKUP_FILE${NC}"
}

# Função para habilitar recursos
enable_feature() {
    local feature=$1
    local config_line=$2
    
    if grep -q "^#$config_line" "$PACMAN_CONF"; then
        echo -e "${BLUE}Habilitando $feature...${NC}"
        sudo sed -i "s/^#$config_line/$config_line/" "$PACMAN_CONF"
    elif ! grep -q "^$config_line" "$PACMAN_CONF"; then
        echo -e "${BLUE}Adicionando $feature...${NC}"
        echo "$config_line" | sudo tee -a "$PACMAN_CONF" >/dev/null
    else
        echo -e "${GREEN}$feature já está habilitado${NC}"
    fi
}

# Função para gerenciar repositórios
manage_repo() {
    local repo=$1
    local action=$2
    
    case $action in
        enable)
            if grep -q "^#$repo" "$PACMAN_CONF"; then
                echo -e "${BLUE}Habilitando repositório $repo...${NC}"
                sudo sed -i "s/^#$repo/$repo/" "$PACMAN_CONF"
            else
                echo -e "${GREEN}Repositório $repo já está habilitado${NC}"
            fi
            ;;
        disable)
            if grep -q "^$repo" "$PACMAN_CONF"; then
                echo -e "${YELLOW}Desabilitando repositório $repo...${NC}"
                sudo sed -i "s/^$repo/#$repo/" "$PACMAN_CONF"
            else
                echo -e "${GREEN}Repositório $repo já está desabilitado${NC}"
            fi
            ;;
    esac
}

# Função principal
main() {
    # Verificar root
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}ERRO: Execute como root!${NC}"
        exit 1
    fi

    create_backup

    # Menu interativo
    echo -e "\n${BLUE}=== Editor de pacman.conf ===${NC}"
    echo -e "${YELLOW}1. Otimizações Básicas${NC}"
    echo -e "${YELLOW}2. Gerenciar Repositórios${NC}"
    echo -e "${YELLOW}3. Configurações Avançadas${NC}"
    echo -e "${YELLOW}4. Reverter para Backup${NC}"
    echo -e "${RED}0. Sair${NC}"
    
    read -p "Escolha uma opção: " choice
    
    case $choice in
        1)
            # Otimizações básicas
            enable_feature "ParallelDownloads" "ParallelDownloads = 5"
            enable_feature "Color" "Color"
            enable_feature "ILoveCandy" "ILoveCandy"
            enable_feature "VerbosePkgLists" "VerbosePkgLists"
            ;;
        2)
            # Gerenciar repositórios
            echo -e "\n${BLUE}Repositórios Disponíveis:${NC}"
            repos=($(grep -E '^\[|^#\[' "$PACMAN_CONF" | tr -d '[]#'))
            for i in "${!repos[@]}"; do
                echo "$((i+1)). ${repos[$i]}"
            done
            
            read -p "Selecione o repositório (número): " repo_num
            selected_repo="${repos[$((repo_num-1))]}"
            
            echo -e "\n1. Habilitar\n2. Desabilitar"
            read -p "Ação: " action_choice
            
            case $action_choice in
                1) manage_repo "\[$selected_repo\]" "enable" ;;
                2) manage_repo "\[$selected_repo\]" "disable" ;;
                *) echo -e "${RED}Opção inválida!${NC}" ;;
            esac
            ;;
        3)
            # Configurações avançadas
            echo -e "\n${BLUE}Otimizações Avançadas:${NC}"
            read -p "Número de jobs para compilação (ex: $(nproc)): " jobs
            enable_feature "MAKEFLAGS" "MAKEFLAGS=\"-j$jobs\""
            
            enable_feature "Cache limpo" "CleanMethod = KeepCurrent"
            enable_feature "Verificação de espaço" "CheckSpace"
            ;;
        4)
            # Reverter para backup
            backups=($(ls -t "$BACKUP_DIR"/*.bak.* 2>/dev/null))
            if [ ${#backups[@]} -eq 0 ]; then
                echo -e "${RED}Nenhum backup encontrado!${NC}"
                exit 1
            fi
            
            echo -e "\n${BLUE}Backups disponíveis:${NC}"
            for i in "${!backups[@]}"; do
                echo "$((i+1)). ${backups[$i]}"
            done
            
            read -p "Selecione o backup para restaurar: " backup_num
            selected_backup="${backups[$((backup_num-1))]}"
            
            echo -e "${YELLOW}Restaurando $selected_backup...${NC}"
            sudo cp "$selected_backup" "$PACMAN_CONF"
            echo -e "${GREEN}Backup restaurado com sucesso!${NC}"
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
    
    echo -e "\n${GREEN}Operação concluída!${NC}"
    echo -e "${YELLOW}Execute 'pacman -Syu' para aplicar as mudanças${NC}"
}

main "$@"