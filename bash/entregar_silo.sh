#!/usr/bin/env bash
# ==============================================================================
# entregar_silo.sh — Publicador Atômico de Runbooks e Scripts para o Silo Central
# Repositório: brncesarms/scripts (Vitrine Pública GitHub)
# ==============================================================================
# Uso:
#   entregar_silo.sh <arquivo1> [arquivo2 ...]
#   entregar_silo.sh --dry-run <arquivo>
#   entregar_silo.sh --mover <arquivo>
# ==============================================================================

set -euo pipefail

SILO_HOST="silo"
DRY_RUN=false
MOVER=false
FILES=()

# Cores e Formatação
C_GREEN="\033[1;32m"
C_BLUE="\033[1;34m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_RESET="\033[0m"

mostrar_ajuda() {
    cat << EOF
📦 entregar_silo.sh — Envia Runbooks e Scripts para o Silo Central (CT 249)

Uso:
  entregar_silo.sh [OPÇÕES] <arquivo1> [arquivo2...]

Opções:
  --dry-run        Simula o envio sem transferir ou alterar arquivos.
  --mover          Move o arquivo (recorta da origem após confirmar o envio).
                   (Padrão: apenas copia, preservando o arquivo local).
  -h, --help       Exibe esta tela de ajuda.

Roteamento Inteligente no Silo:
  • *.md                 -> ~/runbooks/
  • *.py, *.sh, *.ps1    -> ~/scripts/
  • outros formatos      -> ~/compartilhado/

Exemplos:
  entregar_silo.sh runbook_mikrotik.md
  entregar_silo.sh auditar_dhcp.py
  entregar_silo.sh --dry-run setup_vpn.sh
EOF
}

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --mover)
            MOVER=true
            shift
            ;;
        -h|--help)
            mostrar_ajuda
            exit 0
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo -e "${C_RED}❌ Erro: Nenhum arquivo informado para entrega.${C_RESET}"
    mostrar_ajuda
    exit 1
fi

# Verifica se o Silo está acessível via SSH
if [[ "$DRY_RUN" == false ]]; then
    if ! ssh -q -o BatchMode=yes -o ConnectTimeout=4 "${SILO_HOST}" exit 2>/dev/null; then
        echo -e "${C_RED}❌ Erro: Nó '${SILO_HOST}' (10.0.0.249) inacessível via SSH.${C_RESET}"
        echo -e "💡 Verifique se o container 249 está ativo no Proxmox e se a chave SSH está autorizada."
        exit 1
    fi
fi

# Processa cada arquivo
for file in "${FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo -e "${C_YELLOW}⚠️ Aviso: Arquivo '${file}' não encontrado. Pulando...${C_RESET}"
        continue
    fi

    filename="$(basename "$file")"
    extension="${filename##*.}"

    # Determina o diretório de destino no Silo
    case "$extension" in
        md)
            DEST_DIR="~/runbooks/"
            TIPO="📘 Runbook"
            ;;
        py|sh|ps1)
            DEST_DIR="~/scripts/"
            TIPO="⚙️ Script"
            ;;
        *)
            DEST_DIR="~/compartilhado/"
            TIPO="📁 Compartilhado"
            ;;
    esac

    echo -e "${C_BLUE}==>${C_RESET} ${TIPO}: ${C_GREEN}${filename}${C_RESET} -> ${SILO_HOST}:${DEST_DIR}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "   ${C_YELLOW}[DRY-RUN] Simulação:${C_RESET} scp \"${file}\" \"${SILO_HOST}:${DEST_DIR}\""
        if [[ "$MOVER" == true ]]; then
            echo -e "   ${C_YELLOW}[DRY-RUN] Simulação de remoção local:${C_RESET} rm \"${file}\""
        else
            echo -e "   ${C_YELLOW}[DRY-RUN] Arquivo original será preservado localmente.${C_RESET}"
        fi
        continue
    fi

    # Executa a cópia segura
    if scp -q "${file}" "${SILO_HOST}:${DEST_DIR}"; then
        echo -e "   ✅ Enviado com sucesso para o Silo!"
        if [[ "$MOVER" == true ]]; then
            rm -f "${file}"
            echo -e "   🗑️ Arquivo local removido (modo --mover)."
        else
            echo -e "   💾 Arquivo original mantido no workspace local (modo cópia segura)."
        fi
    else
        echo -e "   ${C_RED}❌ Falha na transferência de '${file}' para o Silo.${C_RESET}"
        exit 1
    fi
done

echo -e "\n${C_GREEN}🚀 Entrega finalizada com sucesso no Silo!${C_RESET}"
