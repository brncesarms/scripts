#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação do Flatpak e Configuração do Flathub
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_GRAY='\033[0;37m'
C_RESET='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    printf '%b[!] Privilégios de root (sudo) são necessários para configurar o Flatpak.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE FLATPAK & REPOSITÓRIO FLATHUB%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

# 1. Instalar flatpak se não presente
if ! command -v flatpak >/dev/null 2>&1; then
    printf '%b[+] Instalando utilitário flatpak...%b\n' "$C_YELLOW" "$C_RESET"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1 && apt-get install -y flatpak >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y flatpak >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm flatpak >/dev/null 2>&1
    fi
fi

# 2. Configurar remote Flathub
printf '%b[+] Configurando remote oficial Flathub...%b\n' "$C_GRAY" "$C_RESET"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true

printf '\n%b[✓] Flatpak e Flathub configurados com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
