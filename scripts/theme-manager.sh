#!/bin/bash
# Theme Manager for HyprArch
# License: GPLv3

THEMES_DIR="$HOME/.themes"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

declare -A THEMES=(
    ["1"]="minimal"
    ["2"]="hacker"
    ["3"]="dracula"
)

show_menu() {
    echo "Available Themes:"
    for key in "${!THEMES[@]}"; do
        echo "$key) ${THEMES[$key]}"
    done
}

apply_theme() {
    local theme=$1
    echo "Applying $theme theme..."
    
    case $theme in
        minimal)
            sed -i 's/colors:.*/colors: minimalist/' "$HYPR_CONF"
            ;;
        hacker)
            sed -i 's/colors:.*/colors: hacker/' "$HYPR_CONF"
            ;;
        dracula)
            sed -i 's/colors:.*/colors: dracula/' "$HYPR_CONF"
            ;;
    esac
    
    echo "Theme applied! Restart Hyprland (Alt+F2, r)"
}

main() {
    show_menu
    read -p "Select theme (1-${#THEMES[@]}): " choice
    
    if [[ -n "${THEMES[$choice]}" ]]; then
        apply_theme "${THEMES[$choice]}"
    else
        echo "Invalid choice!"
        exit 1
    fi
}

main "$@"