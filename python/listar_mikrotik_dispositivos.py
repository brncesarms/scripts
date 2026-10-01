#!/usr/bin/env python3
"""
listar_mikrotik_dispositivos.py - Lista dispositivos e leases DHCP conectados ao MikroTik RouterOS v7.
Projetado para Small Language Models (SLMs): saída tabular ultra-estruturada, rápida e de baixo consumo de tokens.
"""
import sys
import subprocess
import re
import argparse

def main():
    parser = argparse.ArgumentParser(
        description="Consulta e formata dispositivos conectados na rede MikroTik RouterOS v7."
    )
    parser.add_argument(
        "--online", "-o", action="store_true",
        help="Exibir apenas dispositivos com status ativo/conectado (bound)"
    )
    args = parser.parse_args()

    cmd = [
        "ssh",
        "-o", "ConnectTimeout=4",
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        "mikrotik",
        "/ip/dhcp-server/lease/print detail without-paging"
    ]

    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=8)
        if res.returncode != 0:
            err = res.stderr.strip() or "Falha de autenticação ou porta inacessível."
            print(f"❌ Erro ao consultar MikroTik via SSH: {err}", file=sys.stderr)
            sys.exit(1)

        raw = res.stdout
        blocks = re.split(r'\n\s*\d+\s+', '\n' + raw)
        entries = []

        for b in blocks:
            if not b.strip() or 'address=' not in b:
                continue

            comment_m = re.search(r';;;\s*([^\n]+)', b)
            comment = comment_m.group(1).strip() if comment_m else ""

            addr_m = re.search(r'address=([0-9.]+)', b)
            addr = addr_m.group(1) if addr_m else ""

            mac_m = re.search(r'mac-address=([0-9A-Fa-f:]+)', b)
            mac = mac_m.group(1).upper() if mac_m else ""

            status_m = re.search(r'status=([a-zA-Z]+)', b)
            status = status_m.group(1) if status_m else "unknown"

            host_m = re.search(r'host-name="?([^"\s\n]+)"?', b)
            hostname = host_m.group(1) if host_m else ""

            label = comment or hostname or f"Dispositivo ({mac[-8:] if mac else 'S/MAC'})"
            is_online = (status == "bound")

            if args.online and not is_online:
                continue

            entries.append({
                "ip": addr,
                "mac": mac,
                "status": status,
                "name": label,
                "online": is_online
            })

        if not entries:
            print("🟡 Nenhum dispositivo encontrado no MikroTik.")
            sys.exit(0)

        # Ordenação: primeiro online, depois por octeto de IP
        entries.sort(key=lambda x: (not x["online"], [int(p) for p in x["ip"].split(".") if p.isdigit()]))

        online_count = sum(1 for e in entries if e["online"])
        offline_count = len(entries) - online_count

        print("=" * 82)
        print("📡 DISPOSITIVOS NA REDE MIKROTIK (DHCP Leases)")
        print("=" * 82)
        print(f"{'IP':<15} {'STATUS':<11} {'NOME / DISPOSITIVO':<36} {'MAC':<17}")
        print("-" * 82)

        for e in entries:
            icon = "🟢 ONLINE" if e["online"] else "⚪ OFFLINE"
            print(f"{e['ip']:<15} {icon:<11} {e['name'][:35]:<36} {e['mac']:<17}")

        print("=" * 82)
        print(f"📊 Total listado: {len(entries)} (🟢 {online_count} online | ⚪ {offline_count} em espera)\n")

    except subprocess.TimeoutExpired:
        print("❌ Timeout: MikroTik (10.0.0.1) não respondeu em 4 segundos.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erro inesperado: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
