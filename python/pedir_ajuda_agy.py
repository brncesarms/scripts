#!/usr/bin/env python3
"""
pedir_ajuda_agy.py - Utilitário para o OpenCode CLI solicitar ajuda ao Antigravity CLI (AGY).
Gera o arquivo /home/brn/archimedes/AJUDA_AGY.md e exibe a instrução no terminal.
"""
import sys
import os
import argparse
from datetime import datetime

AJUDA_FILE = "/home/brn/archimedes/AJUDA_AGY.md"

def main():
    parser = argparse.ArgumentParser(description="Gera arquivo de handoff AJUDA_AGY.md para o Antigravity CLI")
    parser.add_argument("--objetivo", "-o", default="", help="O que o usuário pediu ou o objetivo da tarefa")
    parser.add_argument("--erro", "-e", default="", help="Mensagem de erro exata ou dúvida encontrada")
    parser.add_argument("--contexto", "-c", default="", help="Arquivos envolvidos ou ações já tentadas")

    args, unknown = parser.parse_known_args()

    # Se foram passados argumentos posicionais sem flags
    if unknown and not args.objetivo and not args.erro:
        args.objetivo = " ".join(unknown)

    if not args.objetivo:
        args.objetivo = "Solicitação de ajuda e mentoria para o Antigravity CLI (AGY)."

    # Formatação do arquivo Markdown
    conteudo_md = f"""# 🚨 AJUDA AGY (Antigravity Handoff)

> **Data/Hora:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
> **Solicitante:** OpenCode CLI (Modelo Local Qwen 35B)  

---

### 🎯 Objetivo
{args.objetivo}

### ⚠️ Falha / Dúvida / Impasse
{args.erro if args.erro else "O modelo local necessita do raciocínio superior da nuvem para concluir esta tarefa com sucesso."}

### 📄 Arquivos & Contexto Envolvidos
{args.contexto if args.contexto else "Verifique os arquivos modificados recentemente no repositório /home/brn/archimedes/."}

---
*Este arquivo será removido automaticamente pelo Antigravity CLI ao concluir a solução.*
"""

    os.makedirs(os.path.dirname(AJUDA_FILE), exist_ok=True)
    with open(AJUDA_FILE, "w", encoding="utf-8") as f:
        f.write(conteudo_md)

    print("\n" + "="*70)
    print("⚠️  [MUDANÇA PARA NUVEM] Falha ou solicitação enviada ao AGY.")
    print(f"📄 Arquivo criado com sucesso: {AJUDA_FILE}")
    print("="*70)
    print("👉 Execute no seu terminal o comando abaixo:\n")
    print('   antigravity "Analise o arquivo AJUDA_AGY.md e resolva o problema"')
    print("\n" + "="*70 + "\n")

if __name__ == "__main__":
    main()
