#!/usr/bin/env bash
# ==============================================================================
# Script Atômico: Perfil Completo Modo BRNCZZR (Workstation Dev Linux)
# Autor: Bruno César (https://github.com/brncesarms/scripts)
# Padrão de Mercado 2026 - Zero Gambiarras
# ==============================================================================
set -euo pipefail

C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RESET='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    printf '%b[!] Privilégios de root (sudo) são necessários para provisionar a Workstation Dev.%b\n' "$C_YELLOW" "$C_RESET"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_BASH="$(cd "${SCRIPT_DIR}/.." && pwd)"

printf '\n%b========================================================%b\n' "$C_CYAN" "$C_RESET"
printf '%b [*] PROVISIONAMENTO: PERFIL DEV COMPLETO (MODO BRNCZZR)%b\n' "$C_CYAN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_CYAN" "$C_RESET"

run_atomic() {
    local script_path="$1"
    if [ -x "$script_path" ] || [ -f "$script_path" ]; then
        bash "$script_path"
    else
        printf '%b[!] Script atômico não localizado: %s%b\n' "$C_YELLOW" "$script_path" "$C_RESET"
    fi
}

# 1. Base e Ferramental de Compilação
run_atomic "${SCRIPT_DIR}/install_base_dev.sh"

# 2. Infraestrutura de Desktop & Fontes
run_atomic "${ROOT_BASH}/system/setup_flatpak.sh"
run_atomic "${ROOT_BASH}/system/install_nerdfont.sh"
run_atomic "${ROOT_BASH}/system/install_gnome_tweaks.sh"

# 3. Navegação & Monitoramento
run_atomic "${ROOT_BASH}/apps/install_brave.sh"
run_atomic "${ROOT_BASH}/apps/install_btop.sh"

# 4. Containers & Ambientes
run_atomic "${SCRIPT_DIR}/install_docker.sh"
run_atomic "${SCRIPT_DIR}/install_distrobox.sh"
run_atomic "${SCRIPT_DIR}/install_homebrew.sh"

# 5. Aplicativos de Produtividade & IDE
run_atomic "${SCRIPT_DIR}/install_vscode.sh"
run_atomic "${SCRIPT_DIR}/install_obsidian.sh"

# 6. Agentes & CLIs de Engenharia
run_atomic "${SCRIPT_DIR}/install_antigravity.sh"
run_atomic "${SCRIPT_DIR}/install_opencode.sh"

printf '\n%b========================================================%b\n' "$C_GREEN" "$C_RESET"
printf '%b [✓] WORKSTATION DEV (MODO BRNCZZR) CONFIGURADA COM SUCESSO!%b\n' "$C_GREEN" "$C_RESET"
printf '%b========================================================%b\n\n' "$C_GREEN" "$C_RESET"
