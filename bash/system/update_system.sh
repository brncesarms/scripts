#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Atualização Completa do Sistema Operacional (Multi-Distro)
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_RESET='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    printf '%b[!] Privilégios de root (sudo) são necessários para atualizar o sistema.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

# Carregar lib se disponível ou fallback
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd || echo "")"
if [ -f "${LIB_DIR}/distro.sh" ]; then
    # shellcheck disable=SC1091
    . "${LIB_DIR}/distro.sh"
else
    detectar_distro() {
        if [ -f /etc/os-release ]; then . /etc/os-release; DISTRO_ID="${ID:-unknown}"; else DISTRO_ID="unknown"; fi
        case "$DISTRO_ID" in
            debian|ubuntu|linuxmint|pop) PKG_MGR="apt" ;;
            fedora|rhel|centos|rocky|almalinux) PKG_MGR="dnf" ;;
            arch|manjaro|omarchy|endeavouros) PKG_MGR="pacman" ;;
            *) PKG_MGR="unknown" ;;
        esac
    }
fi

detectar_distro

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] ATUALIZANDO O SISTEMA OPERACIONAL (%s / %s)%b\n' "$C_CYAN" "${DISTRO_ID:-Linux}" "$PKG_MGR" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

case "$PKG_MGR" in
    apt)
        apt-get update -y
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        apt-get autoremove -y >/dev/null 2>&1 || true
        ;;
    dnf)
        dnf upgrade -y
        dnf autoremove -y >/dev/null 2>&1 || true
        ;;
    pacman)
        pacman -Syu --noconfirm
        ;;
    *)
        printf '%b[ERRO] Gerenciador de pacotes desconhecido (%s).%b\n' "$C_RED" "$PKG_MGR" "$C_RESET"
        exit 1
        ;;
esac

printf '\n%b[✓] Atualização do sistema concluída com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
