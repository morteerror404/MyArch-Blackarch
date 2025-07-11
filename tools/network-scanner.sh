#!/bin/bash
# HyprArch Network Scanner (Português)
# Licença: GPLv3

# --- Configurações ---
set -euo pipefail
trap 'echo -e "\033[1;31mErro na linha $LINENO\033[0m"; exit 1' ERR

# Cores
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m'

# Diretórios e arquivos
SCAN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprarch-scans"
LOG_FILE="/tmp/hyprarch-network-scan.log"
DATA=$(date +"%d-%m-%Y_%H-%M-%S")
INTERFACES_FILE="/etc/network/interfaces"

# --- Funções ---

# Verificar dependências
verificar_dependencias() {
    local deps=("ip" "ss" "nmap" "arp-scan" "pgrep" "less" "nmcli")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo -e "${VERMELHO}ERRO: $dep não está instalado! Instale com 'sudo pacman -S ${dep//nmcli/networkmanager}'${NC}" | tee -a "$LOG_FILE"
            exit 1
        fi
    done
    # Verificar se o NetworkManager está ativo
    if ! systemctl is-active --quiet NetworkManager; then
        echo -e "${VERMELHO}ERRO: NetworkManager não está ativo. Inicie com 'sudo systemctl start NetworkManager'${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Iniciar scan e configurar logs
iniciar_scan() {
    mkdir -p "$SCAN_DIR"
    chmod 755 "$SCAN_DIR"
    echo -e "Scan iniciado em: $(date)\n" > "$LOG_FILE"
}

# Verificar se é root
verificar_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${VERMELHO}ERRO: Esta operação requer privilégios de root${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Configurar /etc/network/interfaces
configurar_interfaces_file() {
    local interface=$1
    verificar_root || return
    
    echo -e "${AZUL}\n=== Configuração de /etc/network/interfaces ===${NC}" | tee -a "$LOG_FILE"
    echo -e "${AMARELO}Configurando interface $interface no $INTERFACES_FILE...${NC}" | tee -a "$LOG_FILE"
    
    # Backup do arquivo, se existir
    if [ -f "$INTERFACES_FILE" ]; then
        cp "$INTERFACES_FILE" "${INTERFACES_FILE}.bak.$DATA"
        echo -e "${VERDE}Backup criado: ${INTERFACES_FILE}.bak.$DATA${NC}" | tee -a "$LOG_FILE"
    fi
    
    # Solicitar configuração
    echo -en "${AMARELO}Usar DHCP? (s/n): ${NC}"
    read -r use_dhcp
    if [[ "$use_dhcp" =~ ^[sS]$ ]]; then
        config="auto $interface\niface $interface inet dhcp"
    else
        echo -en "${AMARELO}Digite o endereço IP (ex: 192.168.1.100): ${NC}"
        read -r ip_addr
        echo -en "${AMARELO}Digite a máscara de sub-rede (ex: 255.255.255.0): ${NC}"
        read -r netmask
        echo -en "${AMARELO}Digite o gateway (ex: 192.168.1.1): ${NC}"
        read -r gateway
        config="auto $interface\niface $interface inet static\n    address $ip_addr\n    netmask $netmask\n    gateway $gateway"
    fi
    
    # Criar ou atualizar o arquivo
    mkdir -p "$(dirname "$INTERFACES_FILE")"
    if ! grep -q "iface $interface" "$INTERFACES_FILE" 2>/dev/null; then
        echo -e "$config" >> "$INTERFACES_FILE"
    else
        sed -i "/iface $interface/,/^$/d" "$INTERFACES_FILE"
        echo -e "$config" >> "$INTERFACES_FILE"
    fi
    chmod 644 "$INTERFACES_FILE"
    echo -e "${VERDE}Configuração salva em $INTERFACES_FILE${NC}" | tee -a "$LOG_FILE"
    
    # Aviso sobre NetworkManager
    echo -e "${AMARELO}Nota: O Arch Linux usa o NetworkManager por padrão. O arquivo $INTERFACES_FILE não será usado a menos que você desative o NetworkManager e configure outro gerenciador de rede.${NC}" | tee -a "$LOG_FILE"
}

# Gerenciar conexões do NetworkManager
gerenciar_networkmanager() {
    local interface=$1
    echo -e "${AZUL}\n=== Gerenciamento de Conexões via NetworkManager ===${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${AMARELO}Conexões disponíveis:${NC}" | tee -a "$LOG_FILE"
    nmcli -t -f NAME,DEVICE connection show | grep "$interface" | tee -a "$LOG_FILE" || echo "Nenhuma conexão encontrada para $interface" | tee -a "$LOG_FILE"
    
    echo -e "\n${AMARELO}Opções:${NC}"
    echo "1. Conectar interface"
    echo "2. Desconectar interface"
    echo "3. Criar nova conexão"
    echo -en "${AMARELO}Selecione uma opção (1-3, 0 para voltar): ${NC}"
    read -r opcao_nm
    
    case $opcao_nm in
        1)
            echo -e "${AMARELO}Ativando interface $interface...${NC}" | tee -a "$LOG_FILE"
            nmcli device connect "$interface" | tee -a "$LOG_FILE" || {
                echo -e "${VERMELHO}ERRO: Falha ao conectar $interface${NC}" | tee -a "$LOG_FILE"
                return 1
            }
            echo -e "${VERDE}Interface $interface conectada${NC}" | tee -a "$LOG_FILE"
            ;;
        2)
            echo -e "${AMARELO}Desconectando interface $interface...${NC}" | tee -a "$LOG_FILE"
            nmcli device disconnect "$interface" | tee -a "$LOG_FILE" || {
                echo -e "${VERMELHO}ERRO: Falha ao desconectar $interface${NC}" | tee -a "$LOG_FILE"
                return 1
            }
            echo -e "${VERDE}Interface $interface desconectada${NC}" | tee -a "$LOG_FILE"
            ;;
        3)
            echo -en "${AMARELO}Nome da nova conexão: ${NC}"
            read -r conn_name
            echo -en "${AMARELO}Usar DHCP? (s/n): ${NC}"
            read -r use_dhcp
            if [[ "$use_dhcp" =~ ^[sS]$ ]]; then
                nmcli con add type ethernet con-name "$conn_name" ifname "$interface" | tee -a "$LOG_FILE" || {
                    echo -e "${VERMELHO}ERRO: Falha ao criar conexão${NC}" | tee -a "$LOG_FILE"
                    return 1
                }
            else
                echo -en "${AMARELO}Digite o endereço IP (ex: 192.168.1.100/24): ${NC}"
                read -r ip_addr
                echo -en "${AMARELO}Digite o gateway (ex: 192.168.1.1): ${NC}"
                read -r gateway
                nmcli con add type ethernet con-name "$conn_name" ifname "$interface" ipv4.method manual ipv4.addresses "$ip_addr" ipv4.gateway "$gateway" | tee -a "$LOG_FILE" || {
                    echo -e "${VERMELHO}ERRO: Falha ao criar conexão${NC}" | tee -a "$LOG_FILE"
                    return 1
                }
            fi
            echo -e "${VERDE}Conexão $conn_name criada${NC}" | tee -a "$LOG_FILE"
            ;;
        0) return 0 ;;
        *) echo -e "${VERMELHO}Opção inválida!${NC}" | tee -a "$LOG_FILE" ;;
    esac
}

# Selecionar e priorizar placa de rede
selecionar_placa_rede() {
    echo -e "${AZUL}\n=== Seleção de Placa de Rede ===${NC}" | tee -a "$LOG_FILE"
    local interfaces=($(ip link show | awk -F': ' '/^[0-9]+:/ {print $2}' | grep -v lo))
    
    if [ ${#interfaces[@]} -eq 0 ]; then
        echo -e "${VERMELHO}ERRO: Nenhuma interface de rede encontrada${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi

    echo -e "${AMARELO}Interfaces disponíveis:${NC}" | tee -a "$LOG_FILE"
    for i in "${!interfaces[@]}"; do
        echo "$((i+1)). ${interfaces[$i]}" | tee -a "$LOG_FILE"
    done
    
    echo -en "${AMARELO}Selecione a interface (1-${#interfaces[@]}, 0 para automático): ${NC}"
    read -r escolha
    
    if [ "$escolha" -eq 0 ] || [ -z "$escolha" ]; then
        interface=$(ip route | grep default | awk '{print $5}' || echo "${interfaces[0]}")
        echo -e "${VERDE}Usando interface padrão: $interface${NC}" | tee -a "$LOG_FILE"
    else
        if [ "$escolha" -gt 0 ] && [ "$escolha" -le ${#interfaces[@]} ]; then
            interface="${interfaces[$((escolha-1))]}"
            echo -e "${VERDE}Interface selecionada: $interface${NC}" | tee -a "$LOG_FILE"
        else
            echo -e "${VERMELHO}Seleção inválida! Usando padrão.${NC}" | tee -a "$LOG_FILE"
            interface=$(ip route | grep default | awk '{print $5}' || echo "${interfaces[0]}")
        fi
    fi
    
    # Levantar a placa de rede se estiver desativada
    if ip link show "$interface" | grep -q "state DOWN"; then
        echo -e "${AMARELO}Levantando interface $interface...${NC}" | tee -a "$LOG_FILE"
        verificar_root || return 1
        ip link set "$interface" up || {
            echo -e "${VERMELHO}ERRO: Falha ao ativar interface $interface${NC}" | tee -a "$LOG_FILE"
            exit 1
        }
        echo -e "${VERDE}Interface $interface ativada${NC}" | tee -a "$LOG_FILE"
    fi
    
    echo "$interface"
}

# Scan básico
scan_basico() {
    local interface=$1
    echo -e "${AZUL}\n=== Verificação Básica ===${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${AMARELO}Interfaces de Rede:${NC}" | tee -a "$LOG_FILE"
    ip -br -c addr show "$interface" | tee -a "$LOG_FILE"
    
    echo -e "\n${AMARELO}Conexões Ativas:${NC}" | tee -a "$LOG_FILE"
    ss -tulnp | grep "$interface" | tee -a "$LOG_FILE" || echo "Nenhuma conexão ativa encontrada" | tee -a "$LOG_FILE"
    
    echo -e "\n${AMARELO}Tabela de Roteamento:${NC}" | tee -a "$LOG_FILE"
    ip -c route | tee -a "$LOG_FILE"
}

# Scan avançado
scan_avancado() {
    local interface=$1
    verificar_root || return
    
    echo -e "${AZUL}\n=== Verificação Avançada (Root) ===${NC}" | tee -a "$LOG_FILE"
    
    read -p "Digite a rede para scanear (ex: 192.168.1.0/24): " rede
    if [[ ! "$rede" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
        echo -e "${VERMELHO}ERRO: Formato de rede inválido (exemplo: 192.168.1.0/24)${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo -e "${AMARELO}Verificando dispositivos...${NC}" | tee -a "$LOG_FILE"
    arp-scan --interface="$interface" "$rede" | tee -a "$LOG_FILE" || {
        echo -e "${VERMELHO}ERRO: Falha no arp-scan${NC}" | tee -a "$LOG_FILE"
        return 1
    }
    
    echo -e "\n${AMARELO}Verificando portas...${NC}" | tee -a "$LOG_FILE"
    nmap -sS -T4 "$rede" | tee -a "$LOG_FILE" || {
        echo -e "${VERMELHO}ERRO: Falha no nmap${NC}" | tee -a "$LOG_FILE"
        return 1
    }
}

# Verificar VPN
verificar_vpn() {
    local interface=$1
    echo -e "${AZUL}\n=== Verificação de VPN ===${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${AMARELO}Túneis ativos:${NC}" | tee -a "$LOG_FILE"
    ip tunnel show | grep "$interface" | tee -a "$LOG_FILE" || echo "Nenhum túnel ativo encontrado" | tee -a "$LOG_FILE"
    
    echo -e "\n${AMARELO}Conexões VPN:${NC}" | tee -a "$LOG_FILE"
    pgrep -a openvpn || pgrep -a wireguard | tee -a "$LOG_FILE" || echo "Nenhuma conexão VPN ativa" | tee -a "$LOG_FILE"
}

# Salvar resultados
salvar_resultados() {
    local arquivo_saida="$SCAN_DIR/scan-rede-$DATA.txt"
    cp "$LOG_FILE" "$arquivo_saida"
    chmod 644 "$arquivo_saida"
    echo -e "\n${VERDE}Resultados salvos em: ${AMARELO}$arquivo_saida${NC}" | tee -a "$LOG_FILE"
}

# Verificar scans anteriores
verificar_scans_anteriores() {
    echo -e "${AZUL}\n=== Scans Anteriores ===${NC}" | tee -a "$LOG_FILE"
    local scans=($(ls -t "$SCAN_DIR" 2>/dev/null))
    if [ ${#scans[@]} -eq 0 ]; then
        echo -e "${AMARELO}Nenhum scan anterior encontrado${NC}" | tee -a "$LOG_FILE"
        return 0
    fi
    
    for i in "${!scans[@]}"; do
        echo "$((i+1)). ${scans[$i]}" | tee -a "$LOG_FILE"
    done
    
    echo -en "${AMARELO}Digite o número do scan para visualizar (ou 0 para cancelar): ${NC}"
    read -r scan_escolhido
    
    if [ "$scan_escolhido" -eq 0 ] || [ -z "$scan_escolhido" ]; then
        echo -e "${VERDE}Visualização cancelada${NC}" | tee -a "$LOG_FILE"
        return 0
    fi
    
    if [ "$scan_escolhido" -gt 0 ] && [ "$scan_escolhido" -le ${#scans[@]} ]; then
        less "$SCAN_DIR/${scans[$((scan_escolhido-1))]}" | tee -a "$LOG_FILE"
    else
        echo -e "${VERMELHO}Seleção inválida${NC}" | tee -a "$LOG_FILE"
    fi
}

# Menu principal
menu_principal() {
    verificar_dependencias
    iniciar_scan
    local interface=$(selecionar_placa_rede)
    
    while true; do
        echo -e "\n${AZUL}=== HyprArch Network Scanner (Interface: $interface) ===${NC}" | tee -a "$LOG_FILE"
        echo "1. Verificação Básica"
        echo "2. Verificação Avançada (Requer Root)"
        echo "3. Verificar VPN"
        echo "4. Visualizar Scans Anteriores"
        echo "5. Alterar Interface de Rede"
        echo "6. Configurar /etc/network/interfaces (Requer Root)"
        echo "7. Gerenciar Conexões do NetworkManager"
        echo -e "${VERMELHO}0. Sair${NC}"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) scan_basico "$interface" ;;
            2) scan_avancado "$interface" ;;
            3) verificar_vpn "$interface" ;;
            4) verificar_scans_anteriores ;;
            5) interface=$(selecionar_placa_rede) ;;
            6) configurar_interfaces_file "$interface" ;;
            7) gerenciar_networkmanager "$interface" ;;
            0) salvar_resultados; exit 0 ;;
            *) echo -e "${VERMELHO}Opção inválida!${NC}" | tee -a "$LOG_FILE" ;;
        esac
    done
}

# --- Execução ---
menu_principal