#!/usr/bin/env bash
# ==============================================================================
# gpu-stat.sh - Monitor em Tempo Real da iGPU AMD Radeon 780M (GEEKOM A7 MAX)
# ==============================================================================
# Lê métricas diretamente do subsistema DRM/sysfs do kernel Linux
# Sem dependências externas, zero overhead e instantâneo.
# ==============================================================================

set -euo pipefail

SYS_DEVICE="/sys/class/drm/card0/device"
HWMON_DIR=$(ls -d "${SYS_DEVICE}"/hwmon/hwmon* 2>/dev/null | head -n 1)

if [[ ! -d "${SYS_DEVICE}" ]]; then
    echo "❌ Erro: Dispositivo AMD GPU não encontrado em ${SYS_DEVICE}" >&2
    exit 1
fi

print_stats() {
    # 1. Utilização da GPU
    local busy=0
    if [[ -f "${SYS_DEVICE}/gpu_busy_percent" ]]; then
        busy=$(cat "${SYS_DEVICE}/gpu_busy_percent")
    fi

    # 2. VRAM (em Bytes -> GiB)
    local vram_used_bytes=0
    local vram_total_bytes=0
    if [[ -f "${SYS_DEVICE}/mem_info_vram_used" ]]; then
        vram_used_bytes=$(cat "${SYS_DEVICE}/mem_info_vram_used")
        vram_total_bytes=$(cat "${SYS_DEVICE}/mem_info_vram_total")
    fi
    local vram_used_gib
    local vram_total_gib
    vram_used_gib=$(awk "BEGIN {printf \"%.2f\", ${vram_used_bytes}/1073741824}")
    local vram_pct
    vram_pct=$(awk "BEGIN {printf \"%.1f\", (${vram_used_bytes}/${vram_total_bytes})*100}")
    vram_total_gib=$(awk "BEGIN {printf \"%.2f\", ${vram_total_bytes}/1073741824}")

    # 3. GTT (Memória do sistema compartilhada)
    local gtt_used_bytes=0
    if [[ -f "${SYS_DEVICE}/mem_info_gtt_used" ]]; then
        gtt_used_bytes=$(cat "${SYS_DEVICE}/mem_info_gtt_used")
    fi
    local gtt_used_gib
    gtt_used_gib=$(awk "BEGIN {printf \"%.2f\", ${gtt_used_bytes}/1073741824}")

    # 4. Sensores HWMon (Clock, Temp, Power)
    local temp_c="N/A"
    local clock_mhz="N/A"
    local power_w="N/A"

    if [[ -n "${HWMON_DIR}" && -d "${HWMON_DIR}" ]]; then
        if [[ -f "${HWMON_DIR}/temp1_input" ]]; then
            local temp_raw
            temp_raw=$(cat "${HWMON_DIR}/temp1_input")
            temp_c=$(awk "BEGIN {printf \"%.1f\", ${temp_raw}/1000}")
        fi
        if [[ -f "${HWMON_DIR}/freq1_input" ]]; then
            local freq_raw
            freq_raw=$(cat "${HWMON_DIR}/freq1_input")
            clock_mhz=$(awk "BEGIN {printf \"%.0f\", ${freq_raw}/1000000}")
        fi
        if [[ -f "${HWMON_DIR}/power1_average" ]]; then
            local power_raw
            power_raw=$(cat "${HWMON_DIR}/power1_average")
            power_w=$(awk "BEGIN {printf \"%.2f\", ${power_raw}/1000000}")
        fi
    fi

    # 5. Processos Vulkan / Llama Ativos
    local vk_proc=""
    vk_proc=$(pgrep -a -f "llama-server.*vulkan" || true)

    clear || true
    echo "================================================================="
    echo "  🎮 AMD Radeon 780M (GEEKOM A7 MAX) - Monitor iGPU / Vulkan"
    echo "================================================================="
    echo "  📈 Carga da GPU:      ${busy}%"
    echo "  ⚡ Frequência (Clock): ${clock_mhz} MHz"
    echo "  🌡️  Temperatura:      ${temp_c} °C"
    echo "  🔋 Potência da APU:   ${power_w} W"
    echo "-----------------------------------------------------------------"
    echo "  💾 VRAM Alocada:      ${vram_used_gib} GiB / ${vram_total_gib} GiB (${vram_pct}%)"
    echo "  🧠 GTT Compartilhada: ${gtt_used_gib} GiB"
    echo "-----------------------------------------------------------------"
    if [[ -n "${vk_proc}" ]]; then
        echo "  🟢 Processo Vulkan:   Ativo no container (Hermes llama-server)"
    else
        echo "  ⚪ Processo Vulkan:   Em repouso"
    fi
    echo "================================================================="
}

# Se chamado com --watch ou -w, roda em loop contínuo (atualiza a cada 1s)
if [[ "${1:-}" == "--watch" || "${1:-}" == "-w" ]]; then
    while true; do
        print_stats
        echo "  (Pressione Ctrl+C para sair - Atualizando a cada 1s)"
        sleep 1
    done
else
    print_stats
    echo "  💡 Dica: execute 'gpu-stat -w' para monitorar em tempo real!"
fi
