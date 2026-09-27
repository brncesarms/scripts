#!/bin/bash
# ================================================================================
# 🚀 Script: Desligamento Remoto do Acer Aspire
# Autor: Bruno César
# Data: 2026-09-26
# Padrão: Zero Gambiarras / Integração Canônica com Cofre da Tríade
# ================================================================================

set -euo pipefail

ACER_HOST="acer"

echo "🔍 Verificando conectividade com o Acer Aspire..."
if ! ping -c 1 -W 2 10.0.0.14 > /dev/null 2>&1; then
    echo "✗ Acer não respondeu via LAN (10.0.0.14)."
    echo "  Tentando via Tailscale (100.119.100.53)..."
    if ! ping -c 1 -W 2 100.119.100.53 > /dev/null 2>&1; then
        echo "✗ Acer está offline."
        exit 1
    fi
fi
echo "✓ Acer está online!"

echo "🔐 Recuperando credencial do cofre..."
SUDO_PASS=$(cofre get sudo_acer)

echo "🔌 Enviando comando de desligamento remoto..."
echo "$SUDO_PASS" | ssh -o BatchMode=yes "$ACER_HOST" "sudo -S poweroff"

echo "✅ Comando de desligamento enviado com sucesso para o Acer Aspire!"
