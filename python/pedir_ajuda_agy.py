#!/usr/bin/env python3
"""
pedir_ajuda_agy.py - Utilitário para o OpenCode CLI solicitar ajuda ao Antigravity CLI (AGY).
Gera o arquivo AJUDA_AGY.md e sincroniza com o nó mestre Archimedes para atendimento pelo AGY.
"""
import sys
import os
import argparse
import subprocess
from datetime import datetime

def main():
    parser = argparse.ArgumentParser(description="Gera arquivo de handoff AJUDA_AGY.md para o Antigravity CLI")
    parser.add_argument("--objetivo", "-o", default="", help="O que o usuário pediu ou o objetivo da tarefa")
    parser.add_argument("--erro", "-e", default="", help="Mensagem de erro exata ou dúvida encontrada")
    parser.add_argument("--contexto", "-c", default="", help="Arquivos envolvidos ou ações já tentadas")

    args, unknown = parser.parse_known_args()

    if unknown and not args.objetivo and not args.erro:
        args.objetivo = " ".join(unknown)

    if not args.objetivo:
        args.objetivo = "Solicitação de ajuda e mentoria para o Antigravity CLI (AGY)."

    # Define onde salvar localmente
    cwd = os.getcwd()
    if os.path.exists("/home/brn/estagiario") and (cwd.startswith("/home/brn/estagiario") or not os.path.exists("/home/brn/archimedes")):
        local_file = "/home/brn/estagiario/AJUDA_AGY.md"
        solicitante = "OpenCode CLI (Estagiário - Container 251)"
    else:
        local_file = "/home/brn/archimedes/AJUDA_AGY.md"
        solicitante = "OpenCode CLI (Tier 1 Local)"

    conteudo_md = f"""# 🚨 AJUDA AGY (Antigravity Handoff)

> **Data/Hora:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
> **Solicitante:** {solicitante}  

---

### 🎯 Objetivo
{args.objetivo}

### ⚠️ Falha / Dúvida / Impasse
{args.erro if args.erro else "O modelo local necessita da assistência da nuvem para concluir esta tarefa com sucesso."}

### 📄 Contexto
{args.contexto if args.contexto else "Verifique o ambiente local."}

---
*Este arquivo será removido automaticamente pelo Antigravity CLI ao concluir a solução.*
"""

    os.makedirs(os.path.dirname(local_file), exist_ok=True)
    with open(local_file, "w", encoding="utf-8") as f:
        f.write(conteudo_md)

    # Se estivermos rodando no Estagiário, envia uma cópia via SCP para o Archimedes
    sincronizado_mestre = False
    if local_file.startswith("/home/brn/estagiario"):
        try:
            scp_cmd = [
                "scp",
                "-o", "ConnectTimeout=4",
                "-o", "BatchMode=yes",
                "-o", "StrictHostKeyChecking=accept-new",
                local_file,
                "archimedes:/home/brn/archimedes/AJUDA_AGY.md"
            ]
            r = subprocess.run(scp_cmd, capture_output=True, timeout=6)
            if r.returncode == 0:
                sincronizado_mestre = True
        except Exception:
            pass

    print("\n" + "="*70)
    print("⚠️  [MUDANÇA PARA NUVEM] Solicitação de ajuda gerada com sucesso!")
    print(f"📄 Arquivo local: {local_file}")
    if sincronizado_mestre:
        print("🌐 Handoff sincronizado em: archimedes:/home/brn/archimedes/AJUDA_AGY.md")
    print("="*70)
    print("👉 Execute no seu terminal do Archimedes/Workstation:\n")
    print('   antigravity "Analise o arquivo AJUDA_AGY.md e resolva o problema"')
    print("\n" + "="*70 + "\n")

if __name__ == "__main__":
    main()
