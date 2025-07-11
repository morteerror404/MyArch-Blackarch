

# HyprArch All-in-One Installer

## Descrição

O **HyprArch All-in-One Installer** é um script Bash unificado que automatiza a instalação e configuração de um sistema Arch Linux com o ambiente de desktop Hyprland, ferramentas de segurança do BlackArch, temas personalizados e otimizações do gerenciador de pacotes pacman. Este script combina funcionalidades de múltiplos scripts anteriores, reduzindo redundâncias e proporcionando uma experiência de instalação modular e interativa.

O script permite ao usuário selecionar componentes específicos para instalação, como o sistema base, Hyprland, ferramentas do BlackArch, temas e utilitários adicionais, além de oferecer suporte a configurações avançadas e backups automáticos.

## Licença

Este projeto é licenciado sob a **GPLv3**.

## Requisitos

- **Permissões de root**: O script deve ser executado como root (`sudo` ou usuário root).
- **Conexão com a internet**: Necessária para baixar pacotes e temas.
- **Sistema Arch Linux**: O script é projetado para ser executado em um ambiente Arch Linux, preferencialmente durante a instalação inicial ou em um sistema já configurado.

## Funcionalidades

O script oferece as seguintes funcionalidades, que podem ser selecionadas individualmente ou instaladas em conjunto:

1. **Instalação do Sistema Base**:
   - Instala pacotes essenciais do Arch Linux (`base`, `base-devel`, `linux`, `linux-firmware`, `networkmanager`, `grub`, `efibootmgr`, `sudo`, `nano`).
   - Configura fstab, fuso horário, locale e hostname.

2. **Instalação do Hyprland**:
   - Instala o ambiente de desktop Hyprland e dependências principais (`waybar`, `rofi`, `swaybg`, `swaylock-effects`, `wofi`, `wl-clipboard`, `kitty`, `xdg-desktop-portal-hyprland`, `curl`, `jq`, `git`).
   - Inclui pacotes recomendados (`grim`, `slurp`, `swappy`, `polkit-kde-agent`, `qt5-wayland`, `qt6-wayland`).
   - Configura suporte para GPUs NVIDIA, se detectadas.

3. **Instalação de Ferramentas BlackArch**:
   - Configura o repositório BlackArch e instala ferramentas de segurança em categorias como `networking`, `scanner` e `forensic`, além de ferramentas específicas como `nmap`, `wireshark-qt`, `metasploit` e `sqlmap`.
   - Atualiza a lista de espelhos (`mirrorlist`) e registra repositórios por categoria no `pacman.conf`.

4. **Gerenciamento de Temas**:
   - Instala temas pré-configurados (`minimalist`, `hacker`, `dracula`) no diretório `/etc/skel/.config/hypr`.
   - Permite buscar e instalar temas do GitHub, com suporte a backups automáticos antes de aplicar novas configurações.

5. **Otimização do Pacman**:
   - Habilita recursos como downloads paralelos, interface colorida (`Color`, `ILoveCandy`), listas detalhadas de pacotes e verificação de espaço em disco.
   - Configura o número de jobs de compilação com base no número de núcleos do processador (`MAKEFLAGS`).
   - Permite gerenciar repositórios e restaurar backups do `pacman.conf`.

6. **Utilitários Adicionais**:
   - Oferece a opção de instalar `zsh` com `Oh-My-Zsh`, `htop`, `neofetch` ou pacotes personalizados.

## Como Usar

1. **Baixe o Script**:
   - Salve o script como `hyprarch-installer.sh` em um local acessível.
   - Torne-o executável:
     ```bash
     chmod +x hyprarch-installer.sh
     ```

2. **Execute o Script**:
   - Execute como root:
     ```bash
     sudo ./hyprarch-installer.sh
     ```

3. **Selecione Componentes**:
   - O script apresenta um menu interativo para escolher os componentes a instalar:
     ```
     1) Sistema base
     2) Hyprland
     3) Ferramentas BlackArch
     4) Temas
     5) Otimizações do pacman
     6) Utilitários adicionais
     7) Tudo
     ```
   - Digite os números correspondentes, separados por vírgulas (ex.: `1,2,4`).

4. **Siga as Instruções**:
   - Durante a execução, o script solicitará inputs adicionais, como:
     - Seleção de temas do GitHub.
     - Escolha de utilitários adicionais.
     - Nome de usuário para configurar o shell `zsh`.

5. **Verifique os Logs**:
   - Todas as ações são registradas em `/var/log/hyprarch-install.log` para depuração.

## Estrutura do Script

O script é modular, com funções específicas para cada componente:

- **check_root**: Verifica se o script está sendo executado como root.
- **setup_logging**: Configura logs em `/var/log/hyprarch-install.log`.
- **check_connectivity**: Verifica a conectividade com a internet.
- **install_base**: Instala o sistema base do Arch Linux.
- **configure_system**: Configura fstab, fuso horário, locale e hostname.
- **install_hyprland**: Instala o Hyprland e dependências.
- **configure_nvidia**: Configura suporte para GPUs NVIDIA.
- **setup_hyprland_configs**: Cria configurações padrão para o Hyprland e Waybar.
- **install_blackarch**: Configura e instala ferramentas do BlackArch.
- **update_mirrorlist**: Atualiza a lista de espelhos do BlackArch.
- **register_category_repos**: Registra repositórios por categoria no `pacman.conf`.
- **configure_pacman**: Otimiza configurações do pacman.
- **setup_themes**: Instala temas pré-configurados.
- **fetch_themes**: Busca e aplica temas do GitHub.
- **install_utils**: Instala utilitários adicionais.

## Backups

- **Configurações do Pacman**: Backups do `/etc/pacman.conf` são salvos em `/etc/hyprarch-backups/pacman.conf.bak.<data-hora>`.
- **Configurações do Hyprland**: Backups do `hyprland.conf` são salvos em `/etc/hyprarch-backups/hyprland-backup-<data-hora>.conf`.
- **Mirrorlist**: Backups do `/etc/pacman.d/mirrorlist` são salvos com a extensão `.blackarch.bak`.

## Notas

- **Fuso Horário**: Substitua `Region/City` em `configure_system` pelo fuso horário desejado (ex.: `America/Sao_Paulo`).
- **Temas do GitHub**: Requer `curl`, `jq` e `git` para buscar temas. Certifique-se de que a conexão com a internet esteja ativa.
- **BlackArch**: O script verifica a integridade do `strap.sh` com checksum antes da execução.
- **NVIDIA**: A configuração para GPUs NVIDIA é aplicada automaticamente se uma GPU compatível for detectada.

## Possíveis Problemas

- **Sem conexão com a internet**: Verifique sua rede antes de executar o script.
- **Falha na instalação de pacotes**: Certifique-se de que os repositórios estão acessíveis e atualizados (`pacman -Syyu`).
- **Temas do GitHub**: Algumas APIs do GitHub podem ter limites de requisição. Tente novamente após alguns minutos se ocorrerem erros.

## Contribuições

Contribuições são bem-vindas! Envie pull requests ou reporte problemas no repositório do projeto (se aplicável).

