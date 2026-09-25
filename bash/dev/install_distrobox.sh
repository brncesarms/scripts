#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação do Distrobox (Contêineres Integrados no Desktop)
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RESET='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    printf '%b[!] Privilégios de root (sudo) são necessários para instalar o Distrobox.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE DISTROBOX%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

if ! command -v distrobox >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y distrobox >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y distrobox >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm distrobox >/dev/null 2>&1
    fi
fi

printf '%b[✓] Distrobox instalado com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
