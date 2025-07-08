#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verifica root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Erro: Execute como root!${NC}"
    exit 1
fi

# Verifica se SUDO_USER está definido
if [ -z "$SUDO_USER" ]; then
    echo -e "${RED}Erro: SUDO_USER não definido. Execute com sudo!${NC}"
    exit 1
fi

# Função para resolver problemas de áudio
fix_audio_issues() {
    echo -e "${CYAN}\n🎧 Resolvendo problemas de áudio...${NC}"
    
    # Verifica se pactl está instalado
    if ! command -v pactl &>/dev/null; then
        echo -e "${RED}Erro: pactl não encontrado. Instale o pacote 'pulseaudio' ou 'pipewire-pulse'.${NC}"
        return 1
    fi
    
    # Verifica se o PipeWire está ativo
    if systemctl --user is-active pipewire &>/dev/null; then
        echo -e "${BLUE}🔄 Reiniciando PipeWire...${NC}"
        systemctl --user restart pipewire pipewire-pulse wireplumber
    else
        echo -e "${YELLOW}⚠️ PipeWire não está ativo, tentando iniciar...${NC}"
        systemctl --user enable --now pipewire pipewire-pulse wireplumber
    fi
    
    # Verifica conflito com PulseAudio
    if systemctl --user is-active pulseaudio &>/dev/null; then
        echo -e "${YELLOW}⚠️ PulseAudio está ativo (pode causar conflitos)${NC}"
        read -p "Deseja desativar o PulseAudio? [s/N] " resp
        if [[ "$resp" =~ ^([sS][iI]?|[yY][eE]?[sS]?)$ ]]; then
            systemctl --user disable --now pulseaudio
            echo -e "${GREEN}✅ PulseAudio desativado${NC}"
        fi
    fi
    
    # Verifica se o usuário está nos grupos de áudio
    if ! groups $SUDO_USER | grep -q 'audio'; then
        echo -e "${YELLOW}⚠️ Usuário não está no grupo 'audio'${NC}"
        usermod -aG audio $SUDO_USER
        echo -e "${GREEN}✅ Usuário adicionado ao grupo audio${NC}"
    fi
    
    echo -e "${CYAN}🔊 Testando configuração de áudio...${NC}"
    sudo -u $SUDO_USER pactl info | grep -E "Server Name|Default Sink"
}

# Função para resolver conflitos entre serviços
resolve_service_conflicts() {
    local SERVICE="$1"
    echo -e "${CYAN}\n⚔️ Verificando conflitos para $SERVICE...${NC}"
    
    # Valida nome do serviço
    if [[ ! "$SERVICE" =~ ^[a-zA-Z0-9_-]+(\.service)?$ ]]; then
        echo -e "${RED}Erro: Nome de serviço inválido!${NC}"
        return 1
    fi
    
    # Obtém serviços que podem estar em conflito
    CONFLICTS=$(systemctl list-dependencies --reverse "$SERVICE" 2>/dev/null | grep -v "●")
    
    if [ -n "$CONFLICTS" ]; then
        echo -e "${YELLOW}⚠️ Possíveis serviços conflitantes:${NC}"
        echo "$CONFLICTS"
        
        for conflict in $CONFLICTS; do
            # Ignora serviços essenciais
            if [[ "$conflict" =~ (dbus|systemd|user) ]]; then
                continue
            fi
            
            read -p "Parar o serviço $conflict temporariamente? [s/N] " resp
            if [[ "$resp" =~ ^([sS][iI]?|[yY][eE]?[sS]?)$ ]]; then
                systemctl stop "$conflict"
                echo -e "${GREEN}⏹️ $conflict parado temporariamente${NC}"
            fi
        done
        
        # Tenta reiniciar o serviço principal
        systemctl restart "$SERVICE"
    else
        echo -e "${GREEN}✅ Nenhum conflito detectado${NC}"
    fi
}

# Função para criar serviço de keepalive durante SSH
setup_ssh_keepalive() {
    echo -e "${CYAN}\n🔄 Configurando serviço para manter o PC ativo durante sessões SSH...${NC}"
    
    # Verifica dependências
    if ! command -v ss &>/dev/null; then
        echo -e "${RED}Erro: 'ss' não encontrado. Instale o pacote 'iproute2'.${NC}"
        return 1
    fi
    if ! command -v systemd-inhibit &>/dev/null; then
        echo -e "${RED}Erro: 'systemd-inhibit' não encontrado. Verifique a instalação do systemd.${NC}"
        return 1
    fi
    
    # Cria script de verificação
    cat > /usr/local/bin/ssh-keepalive.sh << 'EOF'
#!/bin/bash
# Script para manter o PC ativo durante sessões SSH

while true; do
    # Verifica se há conexões SSH (porto 22)
    if ss -tn state established '( sport = :22 )' | grep -q .; then
        # Mantém o sistema ativo usando systemd-inhibit
        systemd-inhibit --what=idle:sleep:shutdown --who="SSH Keepalive" --why="Active SSH session" sleep infinity &
        INHIBIT_PID=$!
    else
        # Se não houver SSH, mata o inibidor, se existir
        if [ -n "$INHIBIT_PID" ]; then
            kill "$INHIBIT_PID" 2>/dev/null
            unset INHIBIT_PID
        fi
    fi
    # Aguarda 10 segundos antes da próxima verificação
    sleep 10
done
EOF
    
    chmod +x /usr/local/bin/ssh-keepalive.sh
    
    # Cria serviço systemd
    cat > /etc/systemd/system/ssh-keepalive.service << 'EOF'
[Unit]
Description=Keep system active during SSH sessions
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/ssh-keepalive.sh
Restart=always
Type=simple

[Install]
WantedBy=multi-user.target
EOF
    
    # Habilita e inicia o serviço
    systemctl daemon-reload
    systemctl enable ssh-keepalive.service
    systemctl start ssh-keepalive.service
    
    if systemctl is-active --quiet ssh-keepalive.service; then
        echo -e "${GREEN}✅ Serviço ssh-keepalive configurado e ativo!${NC}"
    else
        echo -e "${RED}Erro: Falha ao iniciar o serviço ssh-keepalive. Verifique com 'systemctl status ssh-keepalive.service'.${NC}"
        return 1
    fi
}

# Função principal de reparo
repair_service() {
    local SERVICE="$1"
    
    echo -e "\n${YELLOW}🔧 Analisando o serviço $SERVICE...${NC}"
    
    # Verifica se o serviço existe
    if ! systemctl list-unit-files | grep -q "^${SERVICE}.service"; then
        echo -e "${RED}❌ Serviço não encontrado!${NC}"
        return 1
    fi

    # Verifica problemas específicos de áudio
    if [[ "$SERVICE" =~ (pipewire|pulseaudio|wireplumber) ]]; then
        fix_audio_issues
        return 0
    fi

    # Coleta informações do serviço
    STATUS=$(systemctl is-active "$SERVICE")
    FAILED=$(systemctl is-failed "$SERVICE")
    ENABLED=$(systemctl is-enabled "$SERVICE")

    # Caso 1: Serviço falhou
    if [ "$FAILED" == "failed" ]; then
        echo -e "${RED}⚠️ Serviço em estado FAILED!${NC}"
        resolve_service_conflicts "$SERVICE"
        
        echo -e "${BLUE}🛠️ Tentando reparo completo...${NC}"
        systemctl reset-failed "$SERVICE"
        systemctl restart "$SERVICE"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Serviço reparado com sucesso!${NC}"
        else
            echo -e "${RED}❌ Falha no reparo. Verifique os logs:${NC}"
            journalctl -xe -u "$SERVICE" | tail -n 20
            return 1
        fi
    
    # Caso 2: Serviço inativo mas habilitado
    elif [ "$STATUS" == "inactive" ] && [ "$ENABLED" == "enabled" ]; then
        echo -e "${YELLOW}⚠️ Serviço habilitado mas não está rodando${NC}"
        resolve_service_conflicts "$SERVICE"
        
        echo -e "${BLUE}🛠️ Iniciando serviço...${NC}"
        systemctl start "$SERVICE"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Serviço iniciado com sucesso!${NC}"
        else
            echo -e "${RED}❌ Falha ao iniciar. Possíveis causas:${NC}"
            systemctl status "$SERVICE" --no-pager -l
            return 1
        fi
    
    # Caso 3: Serviço ativo e funcionando
    else
        echo -e "${GREEN}✅ Serviço está funcionando corretamente!${NC}"
    fi

    # Mostra status final
    echo -e "\n${BLUE}📊 Status final:${NC}"
    systemctl status "$SERVICE" --no-pager -l | head -n 7
}

# Menu principal
case "$1" in
    --repair|--fix)
        if [ -z "$2" ]; then
            echo -e "${RED}Especifique o nome do serviço!${NC}"
            exit 1
        fi
        repair_service "$2"
        ;;
    --check)
        if [ -z "$2" ]; then
            echo -e "${RED}Especifique o nome do serviço!${NC}"
            exit 1
        fi
        repair_service "$2"
        ;;
    --fix-audio)
        fix_audio_issues
        ;;
    --setup-ssh-keepalive)
        setup_ssh_keepalive
        ;;
    *)
        echo -e "${BLUE}Uso:${NC}"
        echo -e "  $0 --repair <serviço>        # Repara um serviço com problemas"
        echo -e "  $0 --check <serviço>         # Verifica o status do serviço"
        echo -e "  $0 --fix-audio              # Corrige problemas de áudio"
        echo -e "  $0 --setup-ssh-keepalive    # Configura serviço para manter PC ativo durante SSH"
        exit 1
        ;;
esac