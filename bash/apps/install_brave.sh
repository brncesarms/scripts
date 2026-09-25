#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação do Brave Browser
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RESET='\033[0m'

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE BRAVE BROWSER%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

if command -v brave-browser >/dev/null 2>&1 || command -v brave >/dev/null 2>&1; then
    printf '%b[✓] Brave Browser já está instalado no sistema.%b\n\n' "$C_GREEN" "$C_RESET"
    exit 0
fi

printf '[+] Executando script de instalação oficial do Brave...\n'
curl -fsS https://dl.brave.com/install.sh | sh >/dev/null 2>&1 || true

if command -v brave-browser >/dev/null 2>&1 || command -v brave >/dev/null 2>&1; then
    printf '\n%b[✓] Brave Browser instalado com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
else
    printf '%b[!] Falha na instalação automática. Consulte https://brave.com/linux/%b\n\n' "$C_YELLOW" "$C_RESET"
fi
