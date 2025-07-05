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
│   ├── 📈 autoservice.sh             # Diagnóstico de serviços
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
   curl -L https://raw.githubusercontent.com/morteerror404/MyArch-Blackarch/HyprArch-Installer/hyprarch-installer.sh | bash
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

# **Guia de Instalação do Arch Linux**  

Este guia ensina a instalar o Arch Linux de três formas:  
1. **Instalação manual** (usando `iwctl` para Wi-Fi)  
2. **Instalação automática** (usando `archinstall`)  
3. **Pós-instalação** (configurações essenciais)  

---

## 📋 **Pré-instalação**  
1. **Baixe a ISO** do Arch Linux:  
   - Site oficial: [https://archlinux.org/download](https://archlinux.org/download)  
2. **Grave a ISO** em um pendrive:  
   - No Linux:  
     ```bash
     sudo dd if=archlinux.iso of=/dev/sdX bs=4M status=progress
     ```  
     (Substitua `sdX` pelo seu pendrive, ex: `sdb`).  
   - No Windows: Use **Rufus** ou **Balena Etcher**.  
3. **Inicie o PC** pelo pendrive (configure a BIOS/UEFI).  

---
 
### **1. Conexão à Internet (Wi-Fi)**  
Se estiver usando Wi-Fi, use o `iwctl`:  
```bash
iwctl                           # Abre o prompt do iwd
station wlan0 scan              # Escaneia redes
station wlan0 get-networks      # Lista redes disponíveis
station wlan0 connect SUA_REDE  # Conecta à rede (digite a senha)
exit                            # Sai do iwd
```  
Verifique a conexão:  
```bash
ping -c 3 google.com
```

---

# 🤖 **Instalação Automática (archinstall)**  
Se preferir um instalador automático:  
```bash
archinstall
```  
Siga o menu interativo para configurar:  
- **Idioma**: `pt_BR`  
- **Teclado**: `br-abnt2`  
- **Disco**: Selecione o modo de particionamento (UEFI recomendado)  
- **Usuário**: Crie um com permissões de `sudo`  
- **Pacotes**: Marque `networkmanager`, `firefox` e etc.  

Ao final, reinicie:  
```bash
reboot
```  

## 🖥️ **Instalação Manual** 

### **1. Particionamento do Disco**  
Liste os discos:  
```bash
fdisk -l
```  
Use `cfdisk` (para discos MBR) ou `gdisk` (para GPT):  
```bash
cfdisk /dev/sdX
```  
**Exemplo de partições (UEFI):**  
- `/dev/sdX1` → **EFI** (300MB, tipo `EFI System`)  
- `/dev/sdX2` → **Swap** (opcional, ex: 4GB)  
- `/dev/sdX3` → **Root** (`/`, resto do espaço, tipo `Linux filesystem`)  

Formate as partições:  
```bash
mkfs.fat -F32 /dev/sdX1        # Formata a partição EFI
mkswap /dev/sdX2               # Cria swap (se necessário)
swapon /dev/sdX2               # Ativa swap
mkfs.ext4 /dev/sdX3            # Formata a partição root
```  

### **2. Instalação do Sistema**  
Monte as partições:  
```bash
mount /dev/sdX3 /mnt           # Monta a root
mkdir /mnt/boot                # Cria pasta boot
mount /dev/sdX1 /mnt/boot      # Monta a EFI
```  

Instale os pacotes básicos:  
```bash
pacstrap /mnt base linux linux-firmware networkmanager grub efibootmgr sudo nano
```  

### **3. Configuração Básica**  
Gere o `fstab` (arquivo de partições):  
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```  

Entre no sistema instalado:  
```bash
arch-chroot /mnt
```  

Defina o **hostname**:  
```bash
echo "nome-do-pc" > /etc/hostname
```  

Configure o **relógio**:  
```bash
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
```  

Configure o **locales** (idioma):  
```bash
nano /etc/locale.gen           # Descomente `pt_BR.UTF-8`
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
```  

Crie um **usuário**:  
```bash
useradd -m -G wheel usuario    # -m cria o diretório home
passwd usuario                 # Define senha
```  

Instale o **GRUB** (bootloader):  
```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```  

Ative o **NetworkManager** (para internet após o boot):  
```bash
systemctl enable NetworkManager
```  

Saia do `chroot` e reinicie:  
```bash
exit
umount -R /mnt
reboot
```  

---

## 🚀 **Pós-instalação**  

### **1. Configurações de Rede**  

Atualize o sistema:  

```bash
sudo systemctl restart NetworkManager
```  
```bash
sudo systemctl start iwd
```  
```bash
sudo iwctl
```  
```bash
station wlan0 scan
```  
```bash
station wlan0 get-networks
```  
```bash
station wlan0 connect 
```
```bash
sudo ip link set enp2s0 up
```  
```bash  
sudo nano /etc/netctl/INTERFACE
```  
```bash
sudo nano /etc/NetworkManager/NetworkManager.conf
```  
```bash
Description='Minha conexão'
Interface=enp2s0 ou wlan0
Connection=ethernet
IP=dhcp
```  

Instale utilitários úteis:  
```bash
sudo pacman -S neofetch htop git wget curl zsh
```  

### **2. Configurações Básicas**   

Atualize o sistema:  
```bash
sudo pacman -Syu
```  

Instale utilitários úteis:  
```bash
sudo pacman -S neofetch htop git wget curl zsh
```  

### **3. Drivers (se necessário)**  
- **Wi-Fi/Bluetooth**:  
  ```bash
  sudo pacman -S bluez bluez-utils
  sudo systemctl enable bluetooth
  ```  
- **GPU NVIDIA**:  
  ```bash
  sudo pacman -S nvidia nvidia-utils
  ```  

---

## ✅ **Pronto!**  
Seu Arch Linux está instalado. Use `neofetch` para ver as informações do sistema:  
```bash
neofetch
```  

**Dica:** Para personalizar ainda mais, veja a [Wiki do Arch](https://wiki.archlinux.org/).  

🐧 **Boa jornada no Arch!**