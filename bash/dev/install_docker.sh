#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação e Configuração do Docker + Docker Compose V2
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
    printf '%b[!] Privilégios de root (sudo) são necessários para instalar o Docker.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(id -un)}"

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE DOCKER ENGINE & DOCKER COMPOSE V2%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

# 1. Instalação de Pacotes
if ! command -v docker >/dev/null 2>&1; then
    printf '%b[+] Instalando pacotes Docker...%b\n' "$C_YELLOW" "$C_RESET"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose-v2 >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y moby-engine docker-compose >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm docker docker-compose docker-buildx >/dev/null 2>&1
    fi
fi

# 2. Inicialização do Serviço
printf '%b[+] Ativando e iniciando o serviço docker no boot...%b\n' "$C_GRAY" "$C_RESET"
systemctl enable docker >/dev/null 2>&1 || true
systemctl start docker >/dev/null 2>&1 || true

# 3. Adicionar usuário real ao grupo docker
printf '%b[+] Configurando permissões do usuário %s no grupo docker...%b\n' "$C_GRAY" "$REAL_USER" "$C_RESET"
groupadd -f docker >/dev/null 2>&1 || true
if [ "$REAL_USER" != "root" ]; then
    usermod -aG docker "$REAL_USER" 2>/dev/null || true
    printf '%b[i] Dica: execute "newgrp docker" ou refaça o login para usar o Docker sem sudo.%b\n' "$C_YELLOW" "$C_RESET"
fi

printf '\n%b[✓] Docker Engine configurado com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
