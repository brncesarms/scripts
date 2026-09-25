#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação da JetBrainsMono Nerd Font
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
    printf '%b[!] Privilégios de root (sudo) são necessários para instalar fontes no sistema.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

FONT_DIR="/usr/local/share/fonts/NerdFonts"
ZIP_TMP="/tmp/JetBrainsMono.zip"

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE FONTE: JETBRAINSMONO NERD FONT%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

if fc-list 2>/dev/null | grep -qi "JetBrainsMono"; then
    printf '%b[✓] JetBrainsMono Nerd Font já está instalada no sistema.%b\n\n' "$C_GREEN" "$C_RESET"
    exit 0
fi

# 1. Dependências
printf '%b[1/3] Verificando dependências (curl, unzip, fontconfig)...%b\n' "$C_GRAY" "$C_RESET"
if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1 || ! command -v fc-cache >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1 && apt-get install -y curl unzip fontconfig >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl unzip fontconfig >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm curl unzip fontconfig >/dev/null 2>&1
    fi
fi

# 2. Download
printf '%b[2/3] Baixando pacote oficial de Nerd Fonts do GitHub...%b\n' "$C_GRAY" "$C_RESET"
mkdir -p "$FONT_DIR"
curl -fLo "$ZIP_TMP" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" >/dev/null 2>&1
unzip -o "$ZIP_TMP" -d "$FONT_DIR" >/dev/null 2>&1
rm -f "$ZIP_TMP"

# 3. Atualizar Cache
printf '%b[3/3] Atualizando cache de fontes do sistema (fc-cache)...%b\n' "$C_GRAY" "$C_RESET"
fc-cache -fv >/dev/null 2>&1

printf '\n%b[✓] JetBrainsMono Nerd Font instalada com sucesso em %s!%b\n\n' "$C_GREEN" "$FONT_DIR" "$C_RESET"
