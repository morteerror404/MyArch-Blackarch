# **HyprArch Installer**  

**Um script completo para instalar Arch Linux + Hyprland + Ferramentas do BlackArch**  

> **Objetivo**: Automatizar a instalação de um sistema **Arch Linux** com o compositor **Hyprland** (Wayland) e as melhores ferramentas de **pentest e segurança** do **BlackArch**, além de temas e configurações prontas.  

---

## **🗺️ Mapa do Repositório**  

```
HyprArch-Installer/
│
├── README.md                 # Documentação principal do projeto
├── hyprarch-installer.sh     # Script principal de instalação
│
├── docs/
│   ├── ARCHITECTURE.md       # Explica a estrutura do projeto
│   └── SECURITY.md           # Boas práticas de segurança
│
├── configs/
│   ├── hypr/                 # Configurações do Hyprland
│   │   ├── hyprland.conf
│   │   ├── exec.conf
│   │   └── README.md         # Como customizar o Hyprland
│   │
│   ├── waybar/               # Configurações da Waybar
│   │   ├── config.jsonc
│   │   ├── style.css
│   │   └── README.md         # Guia de theming da barra
│   │
│   └── rofi/                 # Configurações do Rofi
│       ├── config.rasi
│       └── README.md         # Como modificar menus
│
├── scripts/
│   ├── setup-blackarch.sh    # Instalação do BlackArch
│   ├── setup-hyprland.sh     # Instalação do Hyprland
│   ├── theme-manager.sh      # Gerenciador de temas
│   └── README.md             # Documentação dos scripts
│
├── themes/
│   ├── minimalist/           # Tema minimalista
│   │   ├── hypr/
│   │   ├── waybar/
│   │   └── README.md         # Descrição do tema
│   │
│   ├── hacker/               # Tema estilo hacker
│   │   ├── hypr/
│   │   ├── waybar/
│   │   └── README.md         # Descrição do tema
│   │
│   └── README.md             # Como adicionar novos temas
│
├── tools/
│   ├── network-scanner.sh    # Scanner de rede
│   ├── system-monitor.sh     # Monitor de sistema
│   └── README.md             # Como usar as ferramentas
│
└── backups/
    ├── restore-backup.sh     # Script de restauração
    └── README.md             # Política de backups

```


### Como Usar Esta Estrutura:
1. Clone o repositório
2. Leia os READMEs relevantes antes de modificar
3. Adicione novos arquivos nos diretórios corretos
4. Sempre atualize os READMEs ao fazer mudanças

#### Esta organização permite:

✔️ Manter o projeto bem documentado  
✔️ Facilitar contribuições  
✔️ Manter configurações modulares  
✔️ Permitir fácil restauração

## **📦 O que o script inclui?**  

✅ **Instalação limpa do Arch Linux** (base + kernels recomendados)  
✅ **Hyprland + Waybar + Rofi** configurados  
✅ **Ferramentas do BlackArch** (categorizadas por tipo)  
✅ **Temas pré-configurados** (com suporte a vários repositórios)  
✅ **Gerenciador de pacotes** (`yay` + `paru` + `pacman`)  
✅ **Otimizações de sistema** (swapfile, journald, etc.)  
✅ **Verificação de repositórios** (evita projetos descontinuados)  

---

## **📥 Instalação**  

1. **Baixe o script**:  
   ```sh
   curl -O https://raw.githubusercontent.com/morteerror404/MyArch-Blackarch/HyprArch-Installer/hyprarch-installer.sh
   chmod +x hyprarch-installer.sh
   ```

2. **Execute**:  
   ```sh
   ./hyprarch-installer.sh
   ```

---

## **⚙️ Opções do Script**  

| Comando               | Descrição                                  |
|-----------------------|-------------------------------------------|
| `--minimal`           | Instala apenas o básico (Arch + Hyprland) |
| `--blackarch`         | Adiciona ferramentas do BlackArch         |
| `--themes`            | Instala temas pré-configurados            |
| `--security`          | Configura hardening básico                |
| `--help`              | Mostra esta ajuda                         |

---

## **🎨 Temas Incluídos**  

### **Temas Completos**  
- [JaKooLit/Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland)  
- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)  
- [1amSimp1e/dots](https://github.com/1amSimp1e/dots)  

### **Barras e Paineis**  
- [JakeStanger/ironbar](https://github.com/JakeStanger/ironbar)  
- [Jas-SinghFSU/HyprPanel](https://github.com/Jas-SinghFSU/HyprPanel)  

### **Ferramentas Úteis**  
- [hyprland-community/awesome-hyprland](https://github.com/hyprland-community/awesome-hyprland)  
- [hyprwm/hyprland-plugins](https://github.com/hyprwm/hyprland-plugins)  

---

## **🔧 Ferramentas do BlackArch Incluídas**  

| Categoria       | Exemplos                          |
|----------------|-----------------------------------|
| **Anti-Forensic** | `wipe`, `secure-delete`          |
| **Pentest**      | `metasploit`, `sqlmap`           |
| **Análise**      | `wireshark`, `tcpdump`           |
| **Exploração**   | `exploitdb`, `searchsploit`      |
| **Redes**        | `nmap`, `responder`              |

---

## **📌 Como Contribuir?**  

1. **Dê uma ⭐ no GitHub**  
2. **Abra uma issue** para sugerir melhorias  
3. **Adicione temas/tools** via PR  

🔗 **Repositório**: [github.com/morteerror404/MyArch-Blackarch](https://github.com/morteerror404/MyArch-Blackarch)  

---

## **⚠️ Avisos**  

- **Só use em sistemas que você possui**  
- **Backup seus dados antes**  
- **BlackArch é para fins éticos**  

---

**Feito com ❤️ pela comunidade Arch + Hyprland + BlackArch** 🚀