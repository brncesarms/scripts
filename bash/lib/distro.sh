#!/usr/bin/env bash
# ==============================================================================
# Helper de Detecção de Distribuição Linux & Privilégios (Tríade Omarchy)
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================

detectar_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
    else
        DISTRO_ID="unknown"
    fi

    case "$DISTRO_ID" in
        debian|ubuntu|linuxmint|pop)
            PKG_MGR="apt"
            SSH_SERVICE="ssh"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            PKG_MGR="dnf"
            SSH_SERVICE="sshd"
            ;;
        arch|manjaro|omarchy|endeavouros)
            PKG_MGR="pacman"
            SSH_SERVICE="sshd"
            ;;
        *)
            PKG_MGR="unknown"
            SSH_SERVICE="sshd"
            ;;
    esac
}

detectar_usuario_real() {
    if [ -n "${SUDO_USER:-}" ]; then
        REAL_USER="$SUDO_USER"
    else
        REAL_USER="$(id -un)"
    fi
}

home_usuario() {
    if [ "${REAL_USER:-root}" = "root" ]; then
        printf '/root'
    else
        getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6
    fi
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        printf '\033[1;33m[!] Privilégios de root são obrigatórios para este script.\033[0m\n'
        printf '\033[1;36m[*] Execute novamente com sudo: sudo %s\033[0m\n' "$0"
        exit 1
    fi
}

instalar_pacotes_multi() {
    local apt_pkgs="${1:-}"
    local dnf_pkgs="${2:-}"
    local pacman_pkgs="${3:-}"

    detectar_distro
    case "$PKG_MGR" in
        apt)
            [ -n "$apt_pkgs" ] || return 0
            apt-get update -y >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get install -y $apt_pkgs >/dev/null 2>&1
            ;;
        dnf)
            [ -n "$dnf_pkgs" ] || return 0
            dnf install -y $dnf_pkgs >/dev/null 2>&1
            ;;
        pacman)
            [ -n "$pacman_pkgs" ] || return 0
            pacman -Sy --noconfirm $pacman_pkgs >/dev/null 2>&1
            ;;
        *)
            echo "Gerenciador de pacotes desconhecido: $PKG_MGR" >&2
            return 1
            ;;
    esac
}
