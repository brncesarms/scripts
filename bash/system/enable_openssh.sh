#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Provisionamento do Servidor OpenSSH no Linux (Multi-Distro)
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_GRAY='\033[0;37m'
C_RESET='\033[0m'

CHAVE_PADRAO_LAB="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILiS0LKTWLy0WVbY7O515TKpR9yxxDrJjXH0c3zcWELZ brcesarms@gmail.com"

if [ "$(id -u)" -ne 0 ]; then
    printf '%b[!] Privilégios de root (sudo) são necessários para configurar o OpenSSH.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(id -un)}"
USER_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || echo "/root")"

# Carregar lib ou fallback
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd || echo "")"
if [ -f "${LIB_DIR}/distro.sh" ]; then
    # shellcheck disable=SC1091
    . "${LIB_DIR}/distro.sh"
else
    detectar_distro() {
        if [ -f /etc/os-release ]; then . /etc/os-release; DISTRO_ID="${ID:-unknown}"; else DISTRO_ID="unknown"; fi
        case "$DISTRO_ID" in
            debian|ubuntu|linuxmint|pop) PKG_MGR="apt"; SSH_SERVICE="ssh" ;;
            fedora|rhel|centos|rocky|almalinux) PKG_MGR="dnf"; SSH_SERVICE="sshd" ;;
            arch|manjaro|omarchy|endeavouros) PKG_MGR="pacman"; SSH_SERVICE="sshd" ;;
            *) PKG_MGR="unknown"; SSH_SERVICE="sshd" ;;
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
printf '%b [*] PROVISIONAMENTO DO SERVIDOR OPENSSH NATIVO%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

# 1. Instalação do pacote OpenSSH Server
printf '%b[1/4] Verificando pacote OpenSSH Server...%b\n' "$C_GRAY" "$C_RESET"
if ! command -v sshd >/dev/null 2>&1; then
    printf '%b[+] Instalando OpenSSH via %s...%b\n' "$C_YELLOW" "$PKG_MGR" "$C_RESET"
    instalar_pacotes_multi "openssh-server" "openssh-server" "openssh"
    printf '%b[✓] Pacote OpenSSH instalado com sucesso!%b\n' "$C_GREEN" "$C_RESET"
else
    printf '%b[✓] OpenSSH Server já instalado.%b\n' "$C_GREEN" "$C_RESET"
fi

# 2. Habilitação e Inicialização do Serviço
printf '\n%b[2/4] Configurando inicialização automática do serviço %s...%b\n' "$C_GRAY" "$SSH_SERVICE" "$C_RESET"
systemctl enable "$SSH_SERVICE" >/dev/null 2>&1 || true
systemctl start "$SSH_SERVICE" >/dev/null 2>&1 || true

if systemctl is-active "$SSH_SERVICE" >/dev/null 2>&1; then
    printf '%b[✓] Serviço %s ativo e habilitado no boot!%b\n' "$C_GREEN" "$SSH_SERVICE" "$C_RESET"
else
    printf '%b[!] Aviso: Verifique o status com: systemctl status %s%b\n' "$C_YELLOW" "$SSH_SERVICE" "$C_RESET"
fi

# 3. Liberação de Firewall (Porta 22 TCP)
printf '\n%b[3/4] Ajustando regras de firewall para porta 22 TCP...%b\n' "$C_GRAY" "$C_RESET"
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi "Status: active"; then
    ufw allow ssh >/dev/null 2>&1
    printf '%b[✓] Regra adicionada no UFW (Ubuntu/Debian).%b\n' "$C_GREEN" "$C_RESET"
elif command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
    firewall-cmd --permanent --add-service=ssh >/dev/null 2>&1
    firewall-cmd --reload >/dev/null 2>&1
    printf '%b[✓] Regra adicionada no firewalld (Fedora/RHEL).%b\n' "$C_GREEN" "$C_RESET"
else
    printf '%b[+] Firewall nativo inativo ou permissivo — porta 22 acessível.%b\n' "$C_GRAY" "$C_RESET"
fi

# 4. Injeção de Chave Pública SSH autorizada
printf '\n%b[4/4] Configurando chaves autorizadas em authorized_keys...%b\n' "$C_GRAY" "$C_RESET"
SSH_DIR="${USER_HOME}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ -f "$AUTH_KEYS" ]; then
    if ! grep -qF "$CHAVE_PADRAO_LAB" "$AUTH_KEYS"; then
        echo "$CHAVE_PADRAO_LAB" >> "$AUTH_KEYS"
    fi
else
    echo "$CHAVE_PADRAO_LAB" > "$AUTH_KEYS"
fi

chmod 600 "$AUTH_KEYS"
chown -R "$REAL_USER":"$(id -gn "$REAL_USER" 2>/dev/null || echo "$REAL_USER")" "$SSH_DIR"
printf '%b[✓] Chave pública da Tríade autorizada em %s%b\n' "$C_GREEN" "$AUTH_KEYS" "$C_RESET"

# Resumo de Acesso
IP_LOCAL="$(hostname -I 2>/dev/null | awk '{print $1}' || echo "IP_DO_HOST")"

printf '\n%b========================================================%b\n' "$C_GREEN" "$C_RESET"
printf '%b [✓] SERVIDOR OPENSSH PRONTO PARA CONEXÃO!%b\n' "$C_GREEN" "$C_RESET"
printf '     Comando de conexão via terminal:\n'
printf '%b     ssh %s@%s%b\n' "$C_YELLOW" "$REAL_USER" "$IP_LOCAL" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_GREEN" "$C_RESET"
