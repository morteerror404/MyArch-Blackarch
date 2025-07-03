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

# Diretórios
SCAN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprarch-scans"
LOG_FILE="/tmp/hyprarch-network-scan.log"
DATA=$(date +"%d-%m-%Y_%H-%M-%S")

# --- Funções ---

iniciar_scan() {
    mkdir -p "$SCAN_DIR"
    echo -e "Scan iniciado em: $(date)\n" > "$LOG_FILE"
}

verificar_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${VERMELHO}ERRO: Algumas verificações requerem root${NC}" | tee -a "$LOG_FILE"
        return 1
    fi
}

scan_basico() {
    echo -e "${AZUL}\n=== Verificação Básica ===${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${AMARELO}Interfaces de Rede:${NC}" | tee -a "$LOG_FILE"
    ip -br -c addr show | tee -a "$LOG_FILE"
    
    echo -e "\n${AMARELO}Conexões Ativas:${NC}" | tee -a "$LOG_FILE"
    ss -tulnp | tee -a "$LOG_FILE"
    
    echo -e "\n${AMARELO}Tabela de Roteamento:${NC}" | tee -a "$LOG_FILE"
    ip -c route | tee -a "$LOG_FILE"
}

scan_avancado() {
    verificar_root || return
    
    echo -e "${AZUL}\n=== Verificação Avançada (Root) ===${NC}" | tee -a "$LOG_FILE"
    
    read -p "Digite a rede para scanear (ex: 192.168.1.0/24): " rede
    
    echo -e "${AMARELO}Verificando dispositivos...${NC}" | tee -a "$LOG_FILE"
    arp-scan --localnet --interface=$(ip route | grep default | awk '{print $5}') | tee -a "$LOG_FILE"
    
    echo -e "\n${AMARELO}Verificando portas...${NC}" | tee -a "$LOG_FILE"
    nmap -sS -T4 "$rede" | tee -a "$LOG_FILE"
}

verificar_vpn() {
    echo -e "${AZUL}\n=== Verificação de VPN ===${NC}" | tee -a "$LOG_FILE"
    
    echo -e "${AMARELO}Túneis ativos:${NC}" | tee -a "$LOG_FILE"
    ip tunnel show | tee -a "$LOG_FILE"
    
    echo -e "\n${AMARELO}Conexões VPN:${NC}" | tee -a "$LOG_FILE"
    pgrep -a openvpn || pgrep -a wireguard | tee -a "$LOG_FILE"
}

salvar_resultados() {
    local arquivo_saida="$SCAN_DIR/scan-rede-$DATA.txt"
    cp "$LOG_FILE" "$arquivo_saida"
    echo -e "\n${VERDE}Resultados salvos em: ${AMARELO}$arquivo_saida${NC}"
}

verificar_scans_anteriores() {
    echo -e "${AZUL}\n=== Scans Anteriores ===${NC}"
    ls -lt "$SCAN_DIR" | head -n 10
    read -p "Digite o scan para visualizar (ou deixe em branco para cancelar): " scan_escolhido
    
    if [ -n "$scan_escolhido" ]; then
        less "$SCAN_DIR/$scan_escolhido"
    fi
}

# --- Menu Principal ---
menu_principal() {
    iniciar_scan
    
    while true; do
        echo -e "\n${AZUL}=== HyprArch Network Scanner ===${NC}"
        echo "1. Verificação Básica"
        echo "2. Verificação Avançada (Requer Root)"
        echo "3. Verificar VPN"
        echo "4. Visualizar Scans Anteriores"
        echo -e "${VERMELHO}0. Sair${NC}"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) scan_basico ;;
            2) scan_avancado ;;
            3) verificar_vpn ;;
            4) verificar_scans_anteriores ;;
            0) salvar_resultados; exit 0 ;;
            *) echo -e "${VERMELHO}Opção inválida!${NC}" ;;
        esac
    done
}

# --- Execução ---
menu_principal