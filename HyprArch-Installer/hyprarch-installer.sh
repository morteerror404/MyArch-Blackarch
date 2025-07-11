```
#!/bin/bash
# HyprArch All-in-One Installer
# Licença: GPLv3
# Autor: Combinado de várias fontes
# Última atualização: 10/07/2025

# --- Configurações ---
set -euo pipefail
trap 'log_error "Erro na linha $LINENO"; exit 1' ERR

# Cores
VERMELHO='\033[1;31m'
VERDE='\033[1;32m'
AMARELO='\033[1;33m'
AZUL='\033[1;34m'
NEGRITO='\033[1m'
NC='\033[0m'

# Diretórios e arquivos
CONFIG_DIR="/etc/skel/.config"
THEMES_DIR="$HOME/.themes/hyprland"
BACKUP_DIR="/etc/hyprarch-backups"
LOG_FILE="/var/log/hyprarch-install.log"
PACMAN_CONF="/etc/pacman.conf"
HYPR_CONF="$CONFIG_DIR/hypr/hyprland.conf"

# Espelhos do BlackArch
MIRRORS=(
    "http://au.mirrors.cicku.me/blackarch/\$repo/os/\$arch"
    "https://au.mirrors.cicku.me/blackarch/\$repo/os/\$arch"
    "http://blackarch.mirror.digitalpacific.com.au/\$repo/os/\$arch"
    "http://mirror.easyname.at/blackarch/\$repo/os/\$arch"
    "https://ca.mirrors.cicku.me/blackarch/\$repo/os/\$arch"
    "https://mirrors.hust.edu.cn/blackarch/\$repo/os/\$arch"
    "https://mirrors.nju.edu.cn/blackarch/\$repo/os/\$arch"
    "http://mirrors.aliyun.com/blackarch/\$repo/os/\$arch"
    "http://mirrors.dotsrc.org/blackarch/\$repo/os/\$arch"
    "http://mirror.cedia.org.ec/blackarch/\$repo/os/\$arch"
    "http://blackarch.leneveu.fr/blackarch/\$repo/os/\$arch"
    "http://mirror.cyberbits.eu/blackarch/\$repo/os/\$arch"
    "https://www.blackarch.org/blackarch/\$repo/os/\$arch"
    "http://de.mirrors.cicku.me/blackarch/\$repo/os/\$arch"
    "https://ftp.halifax.rwth-aachen.de/blackarch/\$repo/os/\$arch"
    "http://blackarch.unixpeople.org/\$repo/os/\$arch"
    "http://ftp.cc.uoc.gr/mirrors/linux/blackarch/\$repo/os/\$arch"
)

# Categorias do BlackArch
CATEGORIAS=(
    "automation" "backdoor" "binary" "cracker" "crypto" "database" "defensive"
    "dos" "exploitation" "forensic" "fuzzer" "malware" "mobile" "networking"
    "recon" "scanner" "social" "webapp" "windows" "wireless"
)

# Dependências
DEPENDENCIAS_BASE=(
    hyprland waybar rofi swaybg swaylock-effects wofi wl-clipboard kitty
    xdg-desktop-portal-hyprland curl jq git
)
DEPENDENCIAS_EXTRAS=(
    grim slurp swappy polkit-kde-agent qt5-wayland qt6-wayland
)

# --- Funções ---

# Registrar erro
log_error() {
    local msg="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] ERRO: ${msg}" >> "$LOG_FILE"
    echo -e "${VERMELHO}${NEGRITO}ERRO:${NC} ${msg}" >&2
}

# Exibir mensagem com logo
mostrar_logo() {
    local texto="$1"
    echo -e "\n${NEGRITO}${VERMELHO}[ ${AMARELO}${texto} ${VERMELHO}]${NC}\n"
}

# Verificar execução como root
verificar_root() {
    mostrar_logo "Verificando Permissões"
    [ "$(id -u)" -ne 0 ] && { log_error "Este script deve ser executado como root."; exit 1; }
}

# Configurar log
configurar_log() {
    mostrar_logo "Configurando Log"
    mkdir -p "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo -e "${AZUL}Instalação iniciada em $(date)${NC}"
}

# Verificar conectividade
verificar_conectividade() {
    mostrar_logo "Verificando Conexão"
    echo -e "${NEGRITO}${AMARELO}Verificando conexão com a internet...${NC}"
    ping -c 1 archlinux.org >/dev/null 2>&1 || {
        log_error "Sem conexão com a internet."
        exit 1
    }
}

# Instalar sistema base
instalar_sistema_base() {
    mostrar_logo "Instalando Sistema Base"
    echo -e "${NEGRITO}${AMARELO}Instalando sistema base...${NC}"
    pacstrap /mnt base base-devel linux linux-firmware networkmanager grub efibootmgr sudo nano 2>>"$LOG_FILE" || {
        log_error "Falha ao instalar sistema base."
        exit 1
    }
}

# Configurar sistema
configurar_sistema() {
    mostrar_logo "Configurando Sistema"
    echo -e "${NEGRITO}${AMARELO}Configurando sistema...${NC}"
    genfstab -U /mnt >> /mnt/etc/fstab
    ln -sf /usr/share/zoneinfo/America/Sao_Paulo /mnt/etc/localtime
    hwclock --systohc
    echo "pt_BR.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=pt_BR.UTF-8" > /mnt/etc/locale.conf
    echo "hyprarch" > /mnt/etc/hostname
}

# Instalar Hyprland e dependências
instalar_hyprland() {
    mostrar_logo "Instalando Hyprland"
    echo -e "${NEGRITO}${AMARELO}Instalando Hyprland e dependências...${NC}"
    pacman -Sy --noconfirm 2>>"$LOG_FILE"
    pacman -S --needed --noconfirm "${DEPENDENCIAS_BASE[@]}" 2>>"$LOG_FILE" || {
        log_error "Falha ao instalar pacotes base do Hyprland."
        exit 1
    }
    pacman -S --needed --noconfirm "${DEPENDENCIAS_EXTRAS[@]}" 2>>"$LOG_FILE" || {
        echo -e "${NEGRITO}${AMARELO}Aviso: Falha ao instalar alguns pacotes opcionais${NC}"
    }
}

# Configurar NVIDIA, se detectada
configurar_nvidia() {
    mostrar_logo "Configurando NVIDIA"
    if lspci | grep -qi nvidia; then
        echo -e "${NEGRITO}${AMARELO}Configurando NVIDIA...${NC}"
        pacman -S --noconfirm nvidia nvidia-utils nvidia-settings 2>>"$LOG_FILE" || {
            log_error "Falha ao instalar pacotes NVIDIA."
            exit 1
        }
        echo "options nvidia-drm modeset=1" > /mnt/etc/modprobe.d/nvidia.conf
    else
        echo -e "${NEGRITO}${VERDE}NVIDIA não detectada, pulando configuração${NC}"
    fi
}

# Configurar Hyprland
configurar_hyprland() {
    mostrar_logo "Configurando Hyprland"
    echo -e "${NEGRITO}${AMARELO}Configurando Hyprland...${NC}"
    mkdir -p "$CONFIG_DIR"/{hypr,waybar,rofi}
    chmod -R 755 "$CONFIG_DIR"
    
    if [ ! -f "$HYPR_CONF" ]; then
        cat > "$HYPR_CONF" << 'EOF'
# Configuração Padrão do Hyprland
monitor=,preferred,auto,1
exec-once=waybar & dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
input { kb_layout=br; follow_mouse=1 }
general { gaps_in=5; gaps_out=10; border_size=2 }
decoration { rounding=5; blur=true }
animations { enabled=yes }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
    fi
    
    if [ -f /usr/share/waybar/config ] && [ ! -f "$CONFIG_DIR/waybar/config" ]; then
        cp /usr/share/waybar/config "$CONFIG_DIR/waybar/"
    fi
}

# Instalar BlackArch
instalar_blackarch() {
    mostrar_logo "Instalando BlackArch"
    echo -e "${NEGRITO}${AMARELO}Instalando BlackArch...${NC}"
    if ! grep -q "\[blackarch\]" "$PACMAN_CONF"; then
        curl -s -O https://blackarch.org/strap.sh 2>>"$LOG_FILE" || {
            log_error "Falha ao baixar strap.sh."
            exit 1
        }
        local expected_checksum=$(curl -s https://blackarch.org/checksums | grep strap.sh | awk '{print $1}')
        local actual_checksum=$(sha1sum strap.sh | awk '{print $1}')
        [ "$expected_checksum" != "$actual_checksum" ] && {
            log_error "Checksum inválido para strap.sh."
            exit 1
        }
        chmod +x strap.sh
        ./strap.sh 2>>"$LOG_FILE" || {
            log_error "Falha ao executar strap.sh."
            exit 1
        }
        rm -f strap.sh
    fi
    
    atualizar_lista_espelhos
    registrar_repositorios_categorias
    pacman -Syyu --noconfirm 2>>"$LOG_FILE" || {
        log_error "Falha ao atualizar repositórios."
        exit 1
    }
    pacman -S --noconfirm blackarch-{networking,scanner,forensic} nmap wireshark-qt metasploit sqlmap 2>>"$LOG_FILE" || {
        log_error "Falha ao instalar ferramentas BlackArch."
        exit 1
    }
}

# Atualizar lista de espelhos
atualizar_lista_espelhos() {
    local mirrorlist="/etc/pacman.d/mirrorlist"
    cp "$mirrorlist" "${mirrorlist}.blackarch.bak-$(date +%Y%m%d_%H%M%S)"
    for mirror in "${MIRRORS[@]}"; do
        grep -Fx "Server = $mirror" "$mirrorlist" >/dev/null || echo "Server = $mirror" >> "$mirrorlist"
    done
}

# Registrar repositórios por categoria
registrar_repositorios_categorias() {
    cp "$PACMAN_CONF" "${PACMAN_CONF}.blackarch.bak-$(date +%Y%m%d_%H%M%S)"
    if ! grep -q "\[blackarch\]" "$PACMAN_CONF"; then
        echo -e "\n[blackarch]" >> "$PACMAN_CONF"
        for mirror in "${MIRRORS[@]}"; do
            echo -e "Server = $mirror" >> "$PACMAN_CONF"
        done
    fi
    for categoria in "${CATEGORIAS[@]}"; do
        local repo_name="blackarch-$categoria"
        if ! grep -q "\[${repo_name}\]" "$PACMAN_CONF"; then
            echo -e "\n[${repo_name}]" >> "$PACMAN_CONF"
            for mirror in "${MIRRORS[@]}"; do
                echo -e "Server = $mirror" >> "$PACMAN_CONF"
            done
        fi
    done
}

# Configurar pacman
configurar_pacman() {
    mostrar_logo "Configurando Pacman"
    echo -e "${NEGRITO}${AMARELO}Configurando pacman...${NC}"
    mkdir -p "$BACKUP_DIR"
    cp "$PACMAN_CONF" "$BACKUP_DIR/pacman.conf.bak-$(date +%Y%m%d_%H%M%S)"
    for feature in "ParallelDownloads = 5" "Color" "ILoveCandy" "VerbosePkgLists" "CheckSpace"; do
        grep -q "^#$feature" "$PACMAN_CONF" && sed -i "s/^#$feature/$feature/" "$PACMAN_CONF"
        grep -q "^$feature" "$PACMAN_CONF" || echo "$feature" >> "$PACMAN_CONF"
    done
    grep -q "^MAKEFLAGS=" "$PACMAN_CONF" || echo "MAKEFLAGS=\"-j$(nproc)\"" >> "$PACMAN_CONF"
}

# Configurar temas
configurar_temas() {
    mostrar_logo "Configurando Temas"
    echo -e "${NEGRITO}${AMARELO}Configurando temas...${NC}"
    mkdir -p "$THEMES_DIR" "$BACKUP_DIR"
    chmod -R 755 "$THEMES_DIR" "$BACKUP_DIR"
    
    for tema in minimalista hacker dracula; do
        mkdir -p "$THEMES_DIR/$tema"
        case $tema in
            minimalista)
                cat > "$THEMES_DIR/$tema/hyprland.conf" << 'EOF'
# Tema Minimalista para Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=br; follow_mouse=1 }
general { gaps_in=2; gaps_out=5; border_size=1 }
decoration { rounding=0; blur=false }
animations { enabled=false }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
                ;;
            hacker)
                cat > "$THEMES_DIR/$tema/hyprland.conf" << 'EOF'
# Tema Hacker para Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=br; follow_mouse=1 }
general { gaps_in=5; gaps_out=10; border_size=2; col.active_border=rgb(00ff00) }
decoration { rounding=5; blur=true; drop_shadow=true }
animations { enabled=true }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
                ;;
            dracula)
                cat > "$THEMES_DIR/$tema/hyprland.conf" << 'EOF'
# Tema Dracula para Hyprland
monitor=,preferred,auto,1
exec-once=waybar
input { kb_layout=br; follow_mouse=1 }
general { gaps_in=5; gaps_out=15; border_size=3; col.active_border=rgb(bd93f9) }
decoration { rounding=8; blur=true; drop_shadow=true }
animations { enabled=true }
bind=SUPER,Q,killactive
bind=SUPER,M,exit
bind=SUPER,V,togglefloating
EOF
                ;;
        esac
    done
}

# Baixar temas do GitHub
baixar_temas() {
    mostrar_logo "Baixando Temas"
    echo -e "${NEGRITO}${AMARELO}Baixando temas do GitHub...${NC}"
    local query="hyprland+theme"
    local url="https://api.github.com/search/repositories?q=$query&sort=stars&order=desc&per_page=5"
    local response=$(curl -s "$url" 2>>"$LOG_FILE")
    [ $? -ne 0 ] && { log_error "Falha ao buscar temas."; return 1; }
    local temas=$(echo "$response" | jq -r '.items[] | "\(.name) (\(.stargazers_count) estrelas): \(.html_url)"')
    [ -z "$temas" ] && { log_error "Nenhum tema encontrado."; return 1; }
    
    local i=1
    declare -A tema_mapa
    while IFS= read -r linha; do
        nome=$(echo "$linha" | cut -d'(' -f1 | xargs)
        url=$(echo "$linha" | cut -d':' -f2- | xargs)
        echo "$i. $nome"
        tema_mapa[$i]="$url"
        ((i++))
    done <<< "$temas"
    
    echo -en "${NEGRITO}${AMARELO}Selecione um tema (1-$((i-1)) ou 0 para pular): ${NC}"
    read -r escolha
    if [ "$escolha" -eq 0 ] || [ -z "$escolha" ]; then
        echo -e "${NEGRITO}${AZUL}Pulando instalação de temas${NC}"
        return 0
    fi
    [ -z "${tema_mapa[$escolha]}" ] && { log_error "Seleção inválida."; return 1; }
    
    local nome_tema=$(echo "${tema_mapa[$escolha]}" | awk -F'/' '{print $NF}' | sed 's/.git$//')
    local dir_tema="$THEMES_DIR/$nome_tema"
    git clone "${tema_mapa[$escolha]}" "$dir_tema" 2>>"$LOG_FILE" || {
        log_error "Falha ao clonar tema."
        return 1
    }
    if [ -f "$dir_tema/hyprland.conf" ]; then
        cp "$HYPR_CONF" "$BACKUP_DIR/hyprland-backup-$(date +%Y%m%d_%H%M%S).conf"
        cp "$dir_tema/hyprland.conf" "$HYPR_CONF"
        echo -e "${NEGRITO}${VERDE}Tema $nome_tema aplicado${NC}"
    else
        echo -e "${NEGRITO}${AMARELO}Arquivo hyprland.conf não encontrado no tema${NC}"
    fi
    rm -rf "$dir_tema"
}

# Instalar utilitários adicionais
instalar_utilitarios() {
    mostrar_logo "Instalando Utilitários"
    echo -e "${NEGRITO}${AZUL}Instalar utilitários adicionais? (s/n)${NC}"
    read -r resposta
    if [[ "$resposta" =~ ^([sS])$ ]]; then
        echo -e "${NEGRITO}${AZUL}Selecione os utilitários:${NC}"
        echo "1) Zsh + Oh-My-Zsh"
        echo "2) Htop"
        echo "3) Neofetch"
        echo "4) Todos"
        echo "5) Personalizado"
        echo -e "${NEGRITO}${AZUL}Digite os números (separados por vírgula):${NC}"
        read -r escolhas
        IFS=',' read -ra selecoes <<< "$escolhas"
        for escolha in "${selecoes[@]}"; do
            case "$escolha" in
                1)
                    pacman -S --noconfirm zsh zsh-completions 2>>"$LOG_FILE"
                    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>>"$LOG_FILE"
                    echo -e "${NEGRITO}${AZUL}Digite o nome de usuário para Zsh (vazio para pular):${NC}"
                    read -r usuario
                    [ -n "$usuario" ] && chsh -s /bin/zsh "$usuario" 2>>"$LOG_FILE"
                    ;;
                2) pacman -S --noconfirm htop 2>>"$LOG_FILE" ;;
                3) pacman -S --noconfirm neofetch 2>>"$LOG_FILE" ;;
                4)
                    pacman -S --noconfirm zsh zsh-completions htop neofetch 2>>"$LOG_FILE"
                    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>>"$LOG_FILE"
                    echo -e "${NEGRITO}${AZUL}Digite o nome de usuário para Zsh (vazio para pular):${NC}"
                    read -r usuario
                    [ -n "$usuario" ] && chsh -s /bin/zsh "$usuario" 2>>"$LOG_FILE"
                    ;;
                5)
                    echo -e "${NEGRITO}${AZUL}Digite os pacotes personalizados (separados por espaço):${NC}"
                    read -r pacotes
                    pacman -S --noconfirm $pacotes 2>>"$LOG_FILE"
                    ;;
                *) echo -e "${NEGRITO}${VERMELHO}Opção inválida: $escolha${NC}" ;;
            esac
        done
    fi
}

# Função principal
main() {
    verificar_root
    configurar_log
    verificar_conectividade
    
    echo -e "${NEGRITO}${VERDE}Iniciando instalação do HyprArch...${NC}"
    
    echo -e "${NEGRITO}${AZUL}Selecione os componentes a instalar:${NC}"
    echo "1) Sistema base"
    echo "2) Hyprland"
    echo "3) Ferramentas BlackArch"
    echo "4) Temas"
    echo "5) Otimizações do Pacman"
    echo "6) Utilitários adicionais"
    echo "7) Todos"
    echo -e "${NEGRITO}${AZUL}Digite os números (separados por vírgula):${NC}"
    read -r escolhas
    
    IFS=',' read -ra selecoes <<< "$escolhas"
    for escolha in "${selecoes[@]}"; do
        case "$escolha" in
            1) instalar_sistema_base; configurar_sistema ;;
            2) instalar_hyprland; configurar_nvidia; configurar_hyprland ;;
            3) instalar_blackarch ;;
            4) configurar_temas; baixar_temas ;;
            5) configurar_pacman ;;
            6) instalar_utilitarios ;;
            7)
                instalar_sistema_base
                configurar_sistema
                instalar_hyprland
                configurar_nvidia
                configurar_hyprland
                instalar_blackarch
                configurar_temas
                baixar_temas
                configurar_pacman
                instalar_utilitarios
                ;;
            *) echo -e "${NEGRITO}${VERMELHO}Opção inválida: $escolha${NC}" ;;
        esac
    done
    
    echo -e "${NEGRITO}${VERDE}Instalação concluída! Log: $LOG_FILE${NC}"
}

main "$@"