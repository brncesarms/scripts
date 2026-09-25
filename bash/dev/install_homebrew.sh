#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação e Configuração do Homebrew (Linuxbrew)
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
    printf '%b[!] Privilégios de root (sudo) são necessários para preparar o diretório /home/linuxbrew.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || echo "/root")"
USER_GROUP="$(id -gn "$REAL_USER" 2>/dev/null || echo "$REAL_USER")"

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE HOMEBREW (LINUXBREW)%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ] || command -v brew >/dev/null 2>&1; then
    printf '%b[✓] Homebrew já está instalado no sistema.%b\n\n' "$C_GREEN" "$C_RESET"
    exit 0
fi

# 1. Preparar diretório com permissões do usuário
printf '%b[1/3] Preparando diretório /home/linuxbrew para %s...%b\n' "$C_GRAY" "$REAL_USER" "$C_RESET"
mkdir -p /home/linuxbrew/.linuxbrew
chown -R "$REAL_USER":"$USER_GROUP" /home/linuxbrew

# 2. Executar instalador oficial não-interativo
printf '%b[2/3] Executando instalador oficial do Linuxbrew...%b\n' "$C_GRAY" "$C_RESET"
CMD_BREW='NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
if [ "$REAL_USER" != "root" ]; then
    su - "$REAL_USER" -c "$CMD_BREW" >/dev/null 2>&1
else
    bash -c "$CMD_BREW" >/dev/null 2>&1
fi

# 3. Configurar ambiente no .bashrc do usuário
printf '%b[3/3] Configurando variáveis de ambiente no .bashrc...%b\n' "$C_GRAY" "$C_RESET"
BASHRC="${USER_HOME}/.bashrc"
if [ -f "$BASHRC" ]; then
    if ! grep -qF 'brew shellenv' "$BASHRC"; then
        printf '\neval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"\n' >> "$BASHRC"
    fi
fi

printf '\n%b[✓] Homebrew instalado e configurado no terminal do usuário %s!%b\n\n' "$C_GREEN" "$REAL_USER" "$C_RESET"
