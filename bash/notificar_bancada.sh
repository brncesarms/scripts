#!/usr/bin/env bash
# ==============================================================================
# notificar_bancada.sh — Notificação Híbrida de Bancada (Desktop GNOME + Logs)
# Dispara notificações visuais nas estações de trabalho Bluefin Linux
# (Alienware e Acer) e registra na telemetria em /var/log/bancada/
# ==============================================================================

set -euo pipefail

TITULO="${1:-Bancada Homelab}"
MENSAGEM="${2:-Operação concluída.}"
TIPO="${3:-info}" # info, ok, erro

DATA_HORA="$(date -Iseconds)"

# 1. Registrar no log estruturado de bancada
mkdir -p /var/log/bancada
LOG_ENTRY=$(cat <<EOF
{"timestamp": "$DATA_HORA", "tipo": "$TIPO", "titulo": "$TITULO", "mensagem": "$MENSAGEM"}
EOF
)
echo "$LOG_ENTRY" >> /var/log/bancada/notificacoes.log

# 2. Ícone baseado no tipo
case "$TIPO" in
    ok|sucesso)
        ICONE="emblem-default"
        PREFIXO="✅"
        ;;
    erro|falha)
        ICONE="dialog-error"
        PREFIXO="❌"
        ;;
    *)
        ICONE="dialog-information"
        PREFIXO="ℹ️"
        ;;
esac

# 3. Notificar Alienware (10.0.0.10)
if nc -zv -w 1 10.0.0.10 22 >/dev/null 2>&1; then
    ssh -o ConnectTimeout=2 -o BatchMode=yes alienware \
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send -i '$ICONE' '$PREFIXO $TITULO' '$MENSAGEM'" >/dev/null 2>&1 || true
fi

# 4. Notificar Acer (10.0.0.15)
if nc -zv -w 1 10.0.0.15 22 >/dev/null 2>&1; then
    ssh -o ConnectTimeout=2 -o BatchMode=yes acer \
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send -i '$ICONE' '$PREFIXO $TITULO' '$MENSAGEM'" >/dev/null 2>&1 || true
fi

echo "$PREFIXO [$TITULO] $MENSAGEM"
