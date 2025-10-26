#!/bin/bash

## SDDM Theme Installer for Kali / Debian (repositorio: espinalclark/sddm-themes)

set -euo pipefail

readonly THEME_REPO="https://github.com/espinalclark/sddm-themes.git"
readonly THEME_NAME="sddm-themes"
readonly THEMES_DIR="/usr/share/sddm/themes"
readonly PATH_TO_GIT_CLONE="$HOME/$THEME_NAME"
readonly METADATA="$THEMES_DIR/$THEME_NAME/metadata.desktop"
readonly DATE=$(date +%s)

log() { echo -e "\e[32m[✔]\e[0m $*"; }
warn() { echo -e "\e[33m[!]\e[0m $*"; }
err() { echo -e "\e[31m[x]\e[0m $*" >&2; }

install_deps() {
    log "Instalando dependencias en Debian/Kali..."
    sudo apt update
    sudo apt install -y sddm libqt6svg6 qt6-virtualkeyboard-plugin libqt6multimedia6 \
        qml6-module-qtquick-controls qml6-module-qtquick-effects libxcb-cursor0 git
}

clone_repo() {
    log "Clonando repositorio $THEME_REPO..."
    [[ -d "$PATH_TO_GIT_CLONE" ]] && mv "$PATH_TO_GIT_CLONE" "${PATH_TO_GIT_CLONE}_$DATE"
    git clone -b master --depth 1 "$THEME_REPO" "$PATH_TO_GIT_CLONE"
}

install_theme() {
    log "Instalando tema en $THEMES_DIR..."
    sudo mkdir -p "$THEMES_DIR"
    sudo cp -r "$PATH_TO_GIT_CLONE" "$THEMES_DIR/"
    if [[ -d "$THEMES_DIR/$THEME_NAME/Fonts" ]]; then
        sudo cp -r "$THEMES_DIR/$THEME_NAME/Fonts"/* /usr/share/fonts/
        sudo fc-cache -f -v
    fi

    echo "[Theme]
Current=$THEME_NAME" | sudo tee /etc/sddm.conf >/dev/null

    sudo mkdir -p /etc/sddm.conf.d
    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null
}

fix_wayland() {
    log "Forzando uso de X11 (recomendado en Kali)..."
    sudo sed -i 's/^#*DisplayServer=.*$/DisplayServer=x11/' /etc/sddm.conf || true
}

enable_sddm() {
    log "Habilitando SDDM..."
    sudo systemctl disable lightdm gdm3 2>/dev/null || true
    sudo systemctl enable sddm --now
}

preview_theme() {
    sddm-greeter-qt6 --test-mode --theme "$THEMES_DIR/$THEME_NAME/" || warn "Vista previa fallida."
}

main() {
    [[ $EUID -eq 0 ]] && { err "No ejecutes como root."; exit 1; }
    install_deps
    clone_repo
    install_theme
    fix_wayland
    preview_theme
    enable_sddm
    log "✅ Instalación completa. Reinicia para aplicar."
}

main "$@"

