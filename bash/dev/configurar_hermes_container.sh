#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Configuração de Usuário brn, Locales e Direct Bash no Hermes
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RESET='\033[0m'

PVE_HOST="${1:-10.0.0.2}"
HERMES_VMID="${2:-252}"

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] OTIMIZAÇÃO E CONFIGURAÇÃO DO HERMES (ID %s)%b\n' "$C_CYAN" "$HERMES_VMID" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

# 1. Instalação de utilitários e criação do usuário brn
printf '%b[+] Criando usuário brn e instalando pacotes no container %s...%b\n' "$C_CYAN" "$HERMES_VMID" "$C_RESET"
ssh "root@${PVE_HOST}" "pct exec ${HERMES_VMID} -- bash -c '
    apt-get update && apt-get install -y curl unzip fontconfig locales sudo docker.io && \
    locale-gen en_US.UTF-8 pt_BR.UTF-8 && \
    id brn >/dev/null 2>&1 || useradd -m -s /bin/bash -g users -G sudo,docker brn && \
    usermod -aG docker brn 2>/dev/null || true && \
    echo \"brn:mikrotik\" | chpasswd && \
    echo \"root:mikrotik\" | chpasswd && \
    echo \"brn ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/brn && \
    chmod 0440 /etc/sudoers.d/brn && \
    mkdir -p /home/brn/.ssh && \
    ([ -f /root/.ssh/authorized_keys ] && cp /root/.ssh/authorized_keys /home/brn/.ssh/authorized_keys || true) && \
    chown -R brn:users /home/brn/.ssh && \
    chmod 700 /home/brn/.ssh && \
    chmod 600 /home/brn/.ssh/authorized_keys 2>/dev/null || true
'"

# 2. Ajustar .bashrc para root e brn (Direct Bash)
printf '%b[+] Configurando .bashrc simples para brn e root...%b\n' "$C_CYAN" "$C_RESET"
ssh "root@${PVE_HOST}" "pct exec ${HERMES_VMID} -- bash -c '
    touch /home/brn/.hushlogin /root/.hushlogin && chown brn:users /home/brn/.hushlogin
    cat << \"EOF\" > /home/brn/.bashrc
# ~/.bashrc - Configuração Canônica Hermes Container
case \$- in
    *i*) ;;
      *) return;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8
export TZ=America/Porto_Velho

alias ls=\"ls --color=auto\"
alias ll=\"ls -la\"
alias acer=\"ssh -t acer\"
alias hermes=\"ssh -t hermes\"
alias geekom=\"ssh -t geekom\"
alias archimedes=\"ssh -t archimedes\"
alias mikrotik=\"ssh -t mikrotik\"
alias hermes-agent=\"docker exec -it hermes-agent hermes\"
alias hermes-attach=\"docker attach hermes-agent\"
EOF
    cp /home/brn/.bashrc /root/.bashrc
    chown brn:users /home/brn/.bashrc
'"

printf '%b[✓] Hermes configurado para Bash direto simples com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
