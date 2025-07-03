# 🛠️ Ferramentas do HyprArch - Documentação Completa

## 📋 Visão Geral
Este pacote inclui ferramentas essenciais para administração e monitoramento de sistemas Arch Linux com Hyprland, desenvolvidas para oferecer máxima eficiência com interface amigável.

## 🔍 network-scanner.sh

### Descrição Avançada
Scanner de rede completo que realiza diagnóstico completo da conexão, incluindo:

- **Análise de Interfaces**:
  - Lista todas as interfaces de rede
  - Verifica status (UP/DOWN)
  - Detecta endereços IP e MAC

- **Varredura de Rede**:
  - Mapeamento de hosts ativos
  - Detecção de portas abertas
  - Análise de serviços em execução

- **Testes de Conectividade**:
  - Ping para gateway e DNS
  - Teste de velocidade básico
  - Verificação de rotas

### Uso Detalhado
```bash
./network-scanner.sh [opções]
```

**Opções**:
| Opção       | Descrição                          |
|-------------|-----------------------------------|
| `-f`        | Scan rápido (apenas ping)         |
| `-v`        | Modo verboso (mostra detalhes)    |
| `-o <arquivo>` | Salva saída em arquivo específico |

**Exemplos**:
```bash
# Scan completo
./network-scanner.sh

# Scan rápido com saída para arquivo
./network-scanner.sh -f -o scan_rapido.log
```

**Saída**:
- Relatório completo salvo em `~/.cache/hyprarch-scans/network_<data>.log`
- Formato inclui timestamp e detalhes por seção

## 📊 system-monitor.sh

### Funcionalidades Estendidas
Monitor de desempenho em tempo real com:

- **Monitoramento Básico**:
  - Uso de CPU (por núcleo)
  - Memória RAM e Swap
  - Utilização de disco por partição

- **Métricas Avançadas**:
  - Temperatura da CPU/GPU
  - Uso de rede (upload/download)
  - Load average

- **Alertas**:
  - Notifica quando limites são excedidos
  - Destaque para processos problemáticos

### Controles Interativos
```bash
./system-monitor.sh [opções]
```

**Opções**:
| Tecla       | Ação                              |
|-------------|-----------------------------------|
| `1`         | Alternar visão CPU                |
| `2`         | Alternar visão Memória            |
| `r`         | Ordenar processos por RAM         |
| `c`         | Ordenar processos por CPU         |
| `q`         | Sair do programa                  |

**Personalização**:
Edite `~/.config/hyprarch/monitor.conf` para:
- Definir limites de alerta
- Configurar intervalo de atualização
- Selecionar temas de cores

## ⚙️ Configuração Recomendada

1. **Permissões**:
```bash
chmod +x *.sh
```

2. **Aliases Úteis** (adicione ao `.bashrc` ou `.zshrc`):
```bash
# Atalhos rápidos
alias nscan='~/tools/network-scanner.sh -v'
alias sysmon='~/tools/system-monitor.sh'

# Scan completo semanal
alias weeklyscan='~/tools/network-scanner.sh -o ~/scans/$(date +%Y%m%d)_fullscan.log'
```

3. **Agendamento Automático**:
```bash
# Adicione ao crontab para scans diários
0 2 * * * $HOME/tools/network-scanner.sh -f -o $HOME/.cache/hyprarch-scans/daily_scan.log
```

## 🚨 Solução de Problemas

**Problema**: Scanner não detecta interfaces
- **Solução**: Execute com sudo para acesso completo
```bash
sudo ./network-scanner.sh
```

**Problema**: Monitor não mostra temperatura
- **Solução**: Instale sensores
```bash
sudo pacman -S lm_sensors
sudo sensors-detect
```

## 📦 Dependências
| Ferramenta          | Instalação                      |
|---------------------|---------------------------------|
| nmap                | `sudo pacman -S nmap`           |
| htop                | `sudo pacman -S htop`           |
| bc                  | `sudo pacman -S bc`             |
| smartmontools       | `sudo pacman -S smartmontools`  |

## 📌 Dicas Avançadas
1. Integre com Hyprland:
```bash
bind = $mainMod, N, exec, kitty -e ~/tools/network-scanner.sh -v
```

2. Para relatórios gráficos:
```bash
./network-scanner.sh -o scan.html && firefox scan.html
```

3. Monitoramento remoto:
```bash
ssh usuario@servidor "~/tools/system-monitor.sh"
```