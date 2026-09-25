#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação do OpenCode CLI
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
printf '%b [*] INSTALAÇÃO DE OPENCODE CLI%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

if command -v opencode >/dev/null 2>&1; then
    printf '%b[✓] OpenCode CLI já está instalado no sistema.%b\n\n' "$C_GREEN" "$C_RESET"
    exit 0
fi

printf '[+] Baixando e executando instalador oficial (opencode.ai)...\n'
if [ "$REAL_USER" != "root" ]; then
    su - "$REAL_USER" -c 'curl -fsSL https://opencode.ai/install | bash' >/dev/null 2>&1
    if [ -x "${USER_HOME}/.opencode/bin/opencode" ]; then
        ln -sf "${USER_HOME}/.opencode/bin/opencode" /usr/local/bin/opencode 2>/dev/null || true
    fi
else
    curl -fsSL https://opencode.ai/install | bash >/dev/null 2>&1
    [ -x "/root/.opencode/bin/opencode" ] && ln -sf "/root/.opencode/bin/opencode" /usr/local/bin/opencode 2>/dev/null || true
fi

printf '\n%b[✓] OpenCode CLI instalado com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
