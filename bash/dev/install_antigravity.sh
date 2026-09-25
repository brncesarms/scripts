#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação do Google Antigravity CLI (agy / antigravity)
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RESET='\033[0m'

REAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || echo "/root")"

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE GOOGLE ANTIGRAVITY CLI%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

if command -v agy >/dev/null 2>&1 || command -v antigravity >/dev/null 2>&1; then
    printf '%b[✓] Antigravity CLI já está instalado no sistema.%b\n\n' "$C_GREEN" "$C_RESET"
    exit 0
fi

printf '[+] Baixando instalador oficial do Google Antigravity...\n'
curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin >/dev/null 2>&1 || true

if [ -x /usr/local/bin/agy ]; then
    ln -sf /usr/local/bin/agy /usr/local/bin/antigravity 2>/dev/null || true
    if [ "$REAL_USER" != "root" ] && [ -d "${USER_HOME}" ]; then
        mkdir -p "${USER_HOME}/.local/bin"
        ln -sf /usr/local/bin/agy "${USER_HOME}/.local/bin/agy" 2>/dev/null || true
        ln -sf /usr/local/bin/agy "${USER_HOME}/.local/bin/antigravity" 2>/dev/null || true
        chown -h "$REAL_USER" "${USER_HOME}/.local/bin/agy" "${USER_HOME}/.local/bin/antigravity" 2>/dev/null || true
    fi
    printf '\n%b[✓] Antigravity CLI instalado com sucesso! (comandos: agy / antigravity)%b\n\n' "$C_GREEN" "$C_RESET"
else
    printf '%b[!] Não foi possível concluir a instalação automática do Antigravity CLI.%b\n\n' "$C_YELLOW" "$C_RESET"
fi
