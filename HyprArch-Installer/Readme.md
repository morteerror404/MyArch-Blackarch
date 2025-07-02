# HyprArch Installer

![Hyprland Logo](https://hyprland.org/assets/img/hyprland.png)

> **Um script de instalação automatizado para Arch Linux + Hyprland + BlackArch Tools**

## 📋 Visão Geral

O `hyprarch-installer.sh` é um script Bash que automatiza a instalação de:

- **Arch Linux** básico
- **Hyprland** (compositor Wayland dinâmico)
- **Ferramentas do BlackArch** (opcional)
- Configurações essenciais do sistema

## ✨ Recursos

✅ Instalação limpa do Arch Linux  
✅ Configuração automática do Hyprland  
✅ Suporte a Waybar e Rofi  
✅ Opção para instalar ferramentas do BlackArch  
✅ Log detalhado da instalação  
✅ Interface colorida e amigável  

## 🚀 Como Usar

1. **Boot no Arch ISO** (USB live)
2. **Conecte à internet**:
   ```sh
   iwctl # Para WiFi
   dhcpcd # Para Ethernet
   ```
3. **Execute o instalador**:
   ```sh
   curl -LO https://raw.githubusercontent.com/seu-usuario/HyprArch-Installer/main/hyprarch-installer.sh
   chmod +x hyprarch-installer.sh
   ./hyprarch-installer.sh [--blackarch]
   ```

### Opções:
- `--blackarch`: Instala ferramentas selecionadas do BlackArch

## ⚙️ O Que é Instalado?

### 📦 Pacotes Base
- `base`, `base-devel`, `linux`, `firmware`
- `networkmanager`, `grub`, `sudo`

### 🖥️ Hyprland
- `hyprland`, `waybar`, `rofi`
- `swaybg`, `swaylock-effects`, `wl-clipboard`

### 🛠️ BlackArch (Opcional)
- Ferramentas de rede (`nmap`, `wireshark`)
- Scanners e ferramentas forenses

## 🔧 Pós-Instalação

1. **Configure usuário**:
   ```sh
   useradd -m -G wheel seu_usuario
   passwd seu_usuario
   ```
2. **Ative serviços**:
   ```sh
   systemctl enable NetworkManager
   ```
3. **Reinicie**:
   ```sh
   reboot
   ```

## 📜 Logs
O script gera log completo em:  
`/tmp/hyprarch-install.log`

## ⚠️ Avisos
- Execute apenas em sistemas novos
- Faça backup dos dados importantes
- O BlackArch deve ser usado apenas para fins "éticos"

---
![Arch Linux Logo](https://archlinux.org/static/logos/archlinux-logo-dark-1200dpi.b42bd35d5916.png)
