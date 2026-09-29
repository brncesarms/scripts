#!/usr/bin/env bash
# ==============================================================================
# Script: otimizar_brave_hardware_accel.sh
# Descrição: Remove a flag --disable-gpu-compositing e ativa aceleração por GPU
#            e rasterização no Brave/Chromium no Omarchy Linux (Wayland).
# Autor: Bruno César / Antigravity
# ==============================================================================

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-"$HOME/.config"}"
BRAVE_FLAGS_FILE="${CONFIG_DIR}/brave-flags.conf"
CHROMIUM_FLAGS_FILE="${CONFIG_DIR}/chromium-flags.conf"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🚀 Iniciando otimização do Brave para correção de áudio/vídeo desync..."

# Função para atualizar o arquivo de flags
otimizar_flags() {
    local target_file="$1"
    if [ -f "$target_file" ]; then
        echo "📦 Criando backup de $target_file..."
        cp "$target_file" "${target_file}.bak_${TIMESTAMP}"
        
        # Remove a flag problematica --disable-gpu-compositing
        sed -i '/--disable-gpu-compositing/d' "$target_file"
        
        # Garante que flags otimizadas de GPU estejam presentes se não existirem
        if ! grep -q "ignore-gpu-blocklist" "$target_file"; then
            echo "--ignore-gpu-blocklist" >> "$target_file"
        fi
        if ! grep -q "enable-gpu-rasterization" "$target_file"; then
            echo "--enable-gpu-rasterization" >> "$target_file"
        fi
        
        echo "✅ $target_file otimizado com sucesso."
    fi
}

otimizar_flags "$BRAVE_FLAGS_FILE"
otimizar_flags "$CHROMIUM_FLAGS_FILE"

echo "🎙️ Reiniciando PipeWire para garantir sincronismo de áudio..."
systemctl --user restart pipewire pipewire-pulse 2>/dev/null || true

echo "✨ Correção aplicada com sucesso! Reinicie o Brave para aplicar as alterações."
