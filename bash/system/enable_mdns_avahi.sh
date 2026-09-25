#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Configuração de Resolução de Nomes mDNS / Avahi (.local)
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
    printf '%b[!] Privilégios de root (sudo) são necessários para configurar o Avahi mDNS.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(id -un)}"

# Carregar lib ou fallback
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
    instalar_pacotes_multi() {
        case "$PKG_MGR" in
            apt) apt-get update -y >/dev/null 2>&1; apt-get install -y "$1" >/dev/null 2>&1 ;;
            dnf) dnf install -y "$2" >/dev/null 2>&1 ;;
            pacman) pacman -Sy --noconfirm "$3" >/dev/null 2>&1 ;;
        esac
    }
fi

detectar_distro

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] ATIVANDO RESOLUÇÃO DE NOMES mDNS / AVAHI (.local)%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

# 1. Instalar avahi
printf '%b[1/3] Verificando pacote avahi-daemon...%b\n' "$C_GRAY" "$C_RESET"
if ! command -v avahi-daemon >/dev/null 2>&1; then
    printf '%b[+] Instalando pacotes avahi via %s...%b\n' "$C_YELLOW" "$PKG_MGR" "$C_RESET"
    instalar_pacotes_multi "avahi-daemon avahi-utils" "avahi-daemon avahi-tools" "avahi avahi-tools"
    printf '%b[✓] Avahi instalado com sucesso!%b\n' "$C_GREEN" "$C_RESET"
else
    printf '%b[✓] avahi-daemon já está instalado.%b\n' "$C_GREEN" "$C_RESET"
fi

# 2. Habilitar serviço
printf '\n%b[2/3] Habilitando e iniciando o serviço avahi-daemon...%b\n' "$C_GRAY" "$C_RESET"
systemctl enable avahi-daemon >/dev/null 2>&1 || true
systemctl start avahi-daemon >/dev/null 2>&1 || true

# 3. Informações de resolução
HOST_NAME="$(hostname -s 2>/dev/null || hostname)"

printf '\n%b========================================================%b\n' "$C_GREEN" "$C_RESET"
printf '%b [✓] mDNS / AVAHI CONFIGURADO COM SUCESSO!%b\n' "$C_GREEN" "$C_RESET"
printf '     Nome da máquina na rede local: %b%s.local%b\n' "$C_YELLOW" "$HOST_NAME" "$C_RESET"
printf '     Comando de conexão via SSH:    %bssh %s@%s.local%b\n' "$C_CYAN" "$REAL_USER" "$HOST_NAME" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_GREEN" "$C_RESET"
