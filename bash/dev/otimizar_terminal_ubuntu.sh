#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Configuração de Nerd Fonts & Fix de Locale no Ubuntu
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RESET='\033[0m'

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE NERD FONTS & CONFIGURAÇÃO DO TERMINAL%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

# 1. Instalação de Nerd Fonts
FONT_DIR="${HOME}/.local/share/fonts"
mkdir -p "${FONT_DIR}"

if ! fc-list : family | grep -i "Nerd Font" >/dev/null 2>&1; then
    printf '%b[+] Baixando JetBrainsMono Nerd Font...%b\n' "$C_CYAN" "$C_RESET"
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "${TEMP_DIR}"' EXIT

    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "${TEMP_DIR}/JetBrainsMono.zip"
    unzip -qo "${TEMP_DIR}/JetBrainsMono.zip" -d "${FONT_DIR}/JetBrainsMonoNerdFont"
    fc-cache -fv >/dev/null 2>&1
    printf '%b[✓] JetBrainsMono Nerd Font instalada com sucesso em ~/.local/share/fonts!%b\n\n' "$C_GREEN" "$C_RESET"
else
    printf '%b[✓] Nerd Font já instalada no sistema.%b\n\n' "$C_GREEN" "$C_RESET"
fi

# 2. Configuração Automática do Perfil do GNOME Terminal
if command -v gsettings >/dev/null 2>&1; then
    DEFAULT_PROFILE="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)"
    if [ -n "${DEFAULT_PROFILE}" ]; then
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${DEFAULT_PROFILE}/" use-system-font false 2>/dev/null || true
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${DEFAULT_PROFILE}/" font 'JetBrainsMono Nerd Font 11' 2>/dev/null || true
        printf '%b[✓] Perfil do GNOME Terminal atualizado para usar JetBrainsMono Nerd Font 11!%b\n\n' "$C_GREEN" "$C_RESET"
    fi
fi

# 3. Ajuste de Locale no .bashrc se en_US.UTF-8 não estiver gerado
if ! locale -a 2>/dev/null | grep -i "en_US.utf8" >/dev/null 2>&1; then
    printf '%b[!] Ajustando LANG e LC_ALL para pt_BR.UTF-8 no ~/.bashrc...%b\n' "$C_YELLOW" "$C_RESET"
    if ! grep -q "export LANG=pt_BR.UTF-8" "${HOME}/.bashrc"; then
        echo 'export LANG=pt_BR.UTF-8' >> "${HOME}/.bashrc"
        echo 'export LC_ALL=pt_BR.UTF-8' >> "${HOME}/.bashrc"
    fi
    printf '%b[✓] Variáveis LANG e LC_ALL configuradas para pt_BR.UTF-8 no ~/.bashrc%b\n\n' "$C_GREEN" "$C_RESET"
fi

printf '%b[✓] Otimização do Terminal concluída com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
