# Configuração da Waybar

## Módulos Disponíveis
- `hyprland/window`: Janela ativa
- `network`: Conexão de rede
- `pulseaudio`: Controle de áudio

## Personalização
1. Edite `config.jsonc` para adicionar/remover módulos
2. Ajuste cores no `style.css`

Exemplo de módulo:
```json
"battery": {
    "format": "{capacity}% {icon}",
    "format-icons": ["", "", "", "", ""]
}
```