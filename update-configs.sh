#!/bin/bash
# HyprArch Config Updater
# License: GPLv3

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "🔄 Atualizando configurações..."
cd "$REPO_DIR"
git pull origin main && ./install-configs.sh