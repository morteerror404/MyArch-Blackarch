#!/bin/bash
# HyprArch Config Remover
# License: GPLv3

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "🧹 Removendo configurações..."
for dir in hypr waybar rofi; do
    if [ -d "$CONFIG_DIR/$dir" ]; then
        rm -rfv "$CONFIG_DIR/$dir"
    fi
done

echo -e "\n⚠️  Backups disponíveis em: $BACKUP_DIR"
echo "   Para restaurar manualmente:"
echo "   tar -xzf $BACKUP_DIR/hypr-<data>.tar.gz -C $CONFIG_DIR"