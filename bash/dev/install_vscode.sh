#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Instalação do Visual Studio Code (Flatpak Universal)
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RESET='\033[0m'

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] INSTALAÇÃO DE VISUAL STUDIO CODE (FLATPAK)%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

if flatpak list 2>/dev/null | grep -qi "com.visualstudio.code"; then
    printf '%b[✓] Visual Studio Code já está instalado via Flatpak.%b\n\n' "$C_GREEN" "$C_RESET"
    exit 0
fi

# Garantir flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true

printf '[+] Instalando com.visualstudio.code pelo Flathub...\n'
flatpak install -y flathub com.visualstudio.code

printf '\n%b[✓] Visual Studio Code instalado com sucesso!%b\n\n' "$C_GREEN" "$C_RESET"
