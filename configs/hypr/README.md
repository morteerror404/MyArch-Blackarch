# Configuração do Hyprland

## Estrutura
- `hyprland.conf`: Configurações principais
- `exec.conf`: Programas iniciais

## Atalhos Básicos
| Comando          | Ação                      |
|------------------|---------------------------|
| SUPER + Q        | Fechar janela             |
| SUPER + M        | Sair do Hyprland          |
| SUPER + V        | Alternar modo flutuante   |

## Dicas
1. Para recarregar as configurações:
   ```bash
   hyprctl reload
   ```
2. Verifique erros:
    ```bash
    journalctl -u hyprland -b
    ```