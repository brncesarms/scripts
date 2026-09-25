#!/usr/bin/env bash
# ==============================================================================
# synclab.sh - Sincronização Determinística Multi-Workstation (Tríade Omarchy)
# Autor: Bruno César (@brncesarms)
# Padrão de Mercado 2026: Git como Fonte Única da Verdade (SSOT)
# ==============================================================================

set -u

# Paleta de Cores ANSI
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_CYAN="\033[36m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_BLUE="\033[34m"
C_MAGENTA="\033[35m"

HOSTNAME_CURRENT=$(hostname)
SCRIPTS_DIR="$HOME/scripts"
OBSIDIAN_DIR="$HOME/obsidian"

echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}  🔄 Synclab: Sincronização da Tríade Omarchy        ${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}  📍 Host Atual: ${C_YELLOW}${HOSTNAME_CURRENT}${C_CYAN} | Usuário: ${C_YELLOW}${USER}${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}\n"

# Função para sincronizar um único repositório Git
sync_repo() {
    local target_dir="$1"
    local repo_name
    repo_name="$(basename "$target_dir")"

    if [ ! -d "$target_dir/.git" ]; then
        echo -e "  ${C_YELLOW}⚠️  [${repo_name}]${C_RESET} Não é um repositório Git válido. Ignorando."
        return 0
    fi

    # Verificar se há alterações locais não salvas
    local uncommitted
    uncommitted=$(git -C "$target_dir" status --porcelain 2>/dev/null)

    if [ -n "$uncommitted" ]; then
        echo -e "  ${C_YELLOW}⚠️  [${repo_name}]${C_RESET} Contém alterações locais não comitadas! Ignorando pull para segurança."
        return 0
    fi

    local current_branch
    current_branch=$(git -C "$target_dir" branch --show-current 2>/dev/null || echo "main")

    # Executar git pull rebase
    local pull_output
    if pull_output=$(git -C "$target_dir" pull --rebase origin "$current_branch" 2>&1); then
        if echo "$pull_output" | grep -q "Already up to date."; then
            echo -e "  ${C_GREEN}✓${C_RESET}  [${repo_name}] Atualizado (${current_branch})."
        else
            echo -e "  ${C_BLUE}⬇️  [${repo_name}]${C_RESET} ${C_BOLD}Novas atualizações recebidas!${C_RESET}"
        fi
    else
        echo -e "  ${C_RED}❌ [${repo_name}] Falha no git pull:${C_RESET} ${pull_output}"
    fi
}

# 1. Sincronização Local
sync_local() {
    echo -e "${C_BOLD}${C_BLUE}📦 1. Sincronizando Repositório de Scripts (~/scripts)...${C_RESET}"
    if [ -d "$SCRIPTS_DIR" ]; then
        sync_repo "$SCRIPTS_DIR"
    else
        echo -e "  ${C_RED}❌ Diretório ~/scripts não encontrado!${C_RESET}"
    fi

    echo -e "\n${C_BOLD}${C_BLUE}📝 2. Sincronizando Cofres do Obsidian (~/obsidian)...${C_RESET}"
    if [ -d "$OBSIDIAN_DIR" ]; then
        for repo in "$OBSIDIAN_DIR"/*; do
            if [ -d "$repo" ] && [ -d "$repo/.git" ]; then
                sync_repo "$repo"
            fi
        done
    else
        echo -e "  ${C_RED}❌ Diretório ~/obsidian não encontrado!${C_RESET}"
    fi

    echo -e "\n${C_GREEN}${C_BOLD}✅ Sincronização Local Concluída no host ${HOSTNAME_CURRENT}!${C_RESET}\n"
}

# 2. Sincronização Remota dos Nós da Tríade
sync_remote_node() {
    local node_name="$1"
    local node_ip_tailscale="$2"
    local node_ip_lan="$3"

    echo -e "${C_BOLD}${C_MAGENTA}🌐 Sincronizando nó remoto: ${node_name}...${C_RESET}"

    # Testar conectividade (primeiro Tailscale, depois LAN)
    local target_ip=""
    if ssh -o ConnectTimeout=2 -o BatchMode=yes "brn@${node_ip_tailscale}" "echo ok" >/dev/null 2>&1; then
        target_ip="${node_ip_tailscale}"
    elif ssh -o ConnectTimeout=2 -o BatchMode=yes "brn@${node_ip_lan}" "echo ok" >/dev/null 2>&1; then
        target_ip="${node_ip_lan}"
    fi

    if [ -z "$target_ip" ]; then
        echo -e "  ${C_YELLOW}⚠️  Nó ${node_name} offline ou inacessível no momento. Ignorando.${C_RESET}\n"
        return 0
    fi

    echo -e "  Conectado via ${C_CYAN}${target_ip}${C_RESET}. Disparando synclab..."
    ssh -o ConnectTimeout=5 "brn@${target_ip}" "/home/brn/scripts/bash/synclab.sh --local"
    echo -e "  ${C_GREEN}✓ Nó ${node_name} sincronizado com sucesso!${C_RESET}\n"
}

# Processamento de Argumentos
MODE="local"
if [ "${1:-}" = "--all" ] || [ "${1:-}" = "-a" ] || [ "${1:-}" = "--triade" ]; then
    MODE="all"
elif [ "${1:-}" = "--local" ] || [ "${1:-}" = "-l" ]; then
    MODE="local"
fi

# Execução
sync_local

if [ "$MODE" = "all" ]; then
    echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}  🚀 Disparando Sincronização em Toda a Tríade        ${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}\n"

    # Se não formos o Geekom, sincronizar o Geekom
    if [[ "$HOSTNAME_CURRENT" != *"geekom"* ]]; then
        sync_remote_node "GEEKOM A7 MAX" "100.100.63.15" "10.0.0.202"
    fi

    # Se não formos o Alienware, sincronizar o Alienware
    if [[ "$HOSTNAME_CURRENT" != *"alienware"* ]]; then
        sync_remote_node "ALIENWARE Aurora" "100.100.63.16" "10.0.0.216"
    fi

    # Se não formos o Acer, sincronizar o Acer
    if [[ "$HOSTNAME_CURRENT" != *"acer"* ]]; then
        sync_remote_node "ACER Aspire" "100.100.63.17" "10.0.0.207"
    fi

    echo -e "${C_GREEN}${C_BOLD}🎉 Toda a Tríade Omarchy foi sincronizada com sucesso!${C_RESET}\n"
fi
