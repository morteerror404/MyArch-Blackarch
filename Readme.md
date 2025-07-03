### 📂 Estrutura do Projeto
```
HyprArch-Installer/
│
├── 📄 README.md                      # Documentação principal (ATUALIZADO)
├── ⚙️ hyprarch-installer.sh          # Script principal de instalação
│
├── 📁 configs/                       # Configurações padrão
│   ├── 🖼️ hypr/
│   │   ├── 📄 hyprland.conf          # Configuração do Hyprland
│   │   ├── 📄 exec.conf              # Programas iniciais
│   │   └── 📄 README.md              # Documentação
│   │
│   ├── 📊 waybar/
│   │   ├── 📄 config.jsonc           # Configuração da barra
│   │   ├── 🎨 style.css              # Estilos
│   │   └── 📄 README.md              # Guia
│   │
│   └── 🚀 rofi/
│       ├── 📄 config.rasi            # Menu de aplicativos
│       └── 📄 README.md              # Documentação
│
├── 📁 scripts/
│   ├── ⚡ setup-hyprland.sh          # Instalação do Hyprland 
│   ├── 🔒 setup-blackarch.sh         # Ferramentas de segurança
│   ├── 🎨 theme-manager.sh           # Gerenciador de temas 
│   └── 📦 pacman-editor.sh           # Editor de configuração
│
├── 📁 tools/
│   ├── 🌐 network-scanner.sh         # Diagnóstico de rede
│   └── 📈 system-monitor.sh          # Monitor de sistema
│
└── 📁 docs/
    ├── 📄 ARCHITECTURE.md            # Fluxo do sistema
    ├── 📄 SECURITY.md                # Melhores práticas
    └── 📄 NETWORK.md                 # Configuração de rede
```

### 🔄 Fluxo de Trabalho Corrigido

1. **Instalação**:
   ```bash
   curl -L https://raw.githubusercontent.com/seu-repo/main/hyprarch-installer.sh | bash
   ```

2. **Gerenciamento**:
   - Configurações: `./scripts/theme-manager.sh` (novo sistema de rollback)
   - Atualização: `./scripts/pacman-editor.sh --update`

3. **Backup Automático**:
   - Armazenado em: `~/.local/share/hyprarch-backups/`
   - Formato: `backup-YYYYMMDD_HHMMSS.tar.gz`

### ✨ Melhorias Implementadas

1. **No `setup-hyprland.sh`**:
   ```bash
   # Verificação de GPU
   if lspci | grep -qi "nvidia"; then
       pacman -S --noconfirm nvidia nvidia-utils
   fi
   ```

2. **No `theme-manager.sh`**:
   ```bash
   # Sistema de rollback
   restore_theme() {
       tar -xzf "$BACKUP_DIR/last-theme.tar.gz" -C "$CONFIG_DIR"
   }
   ```

3. **Padronização**:
   - Todos os scripts agora incluem:
     ```bash
     set -euo pipefail
     trap "echo 'Erro na linha $LINENO'" ERR
     ```

### 📌 Próximos Passos

1. Testar em ambiente virtual:
   ```bash
   qemu-system-x86_64 -m 8G -enable-kvm -cdrom archlinux.iso
   ```

2. Documentar casos de uso comum:
   ```bash
   nano docs/TROUBLESHOOTING.md
   ```

3. Adicionar validação de checksum:
   ```bash
   sha256sum -c install.sha256
   ```

> **Nota**: Todos os arquivos README.md foram revisados e padronizados com:
> - Guias de configuração
> - Exemplos de uso
> - Links para documentação oficial

