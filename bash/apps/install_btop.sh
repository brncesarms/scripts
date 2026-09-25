#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação do Monitor de Sistema BTOP
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RESET='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    printf '%b[!] Privilégios de root (sudo) são necessários para instalar o btop.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DO MONITOR DE SISTEMA BTOP%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

if command -v btop >/dev/null 2>&1; then
    printf '%b[✓] btop já está instalado no sistema.%b\n\n' "$C_GREEN" "$C_RESET"
    exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1 && apt-get install -y btop >/dev/null 2>&1
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y btop >/dev/null 2>&1
elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm btop >/dev/null 2>&1
fi

if command -v btop >/dev/null 2>&1; then
    printf '%b[✓] btop instalado com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
else
    printf '%b[!] Falha na instalação do btop.%b\n\n' "$C_YELLOW" "$C_RESET"
fi
