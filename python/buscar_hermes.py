#!/usr/bin/env python3
"""
buscar_homelab.py - Busca semântica rápida no hermes.db
Uso: python3 scripts/buscar_homelab.py "como desligar o proxmox"
"""
import sys
import os

# Auto-elevação para o ambiente virtual .venv se não estiver ativo
_venv_python = "/home/brn/archimedes/.venv/bin/python3"
if os.path.exists(_venv_python) and sys.executable != _venv_python:
    try:
        import sqlite_vec
        import fastembed
    except ImportError:
        os.execv(_venv_python, [_venv_python] + sys.argv)

import sqlite3
import sqlite_vec
from fastembed import TextEmbedding

DB_PATH = os.environ.get("HERMES_DB_PATH", "/home/brn/archimedes/hermes.db")
EMBEDDING_MODEL = "BAAI/bge-small-en-v1.5"

def search(query, k=3):
    """Busca os k trechos mais relevantes por similaridade vetorial."""
    if not os.path.exists(DB_PATH):
        return []
        
    model = TextEmbedding(model_name=EMBEDDING_MODEL)
    query_emb = list(model.embed([query]))[0]
    
    conn = sqlite3.connect(DB_PATH)
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    
    query_bytes = sqlite_vec.serialize_float32(query_emb.tolist())
    
    results = conn.execute("""
        SELECT c.source_file, c.section_title, c.content, v.distance
        FROM vec_chunks v
        JOIN chunks c ON c.id = v.chunk_id
        WHERE v.embedding MATCH ? AND k = ?
        ORDER BY v.distance
    """, (query_bytes, k)).fetchall()
    
    conn.close()
    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 buscar_homelab.py <pergunta ou termo de busca>")
        sys.exit(1)
        
    q = " ".join(sys.argv[1:])
    res = search(q)
    
    if not res:
        print(f"🟡 [RAG] Nenhum resultado encontrado para: '{q}'. Verifique se o banco foi indexado.")
        sys.exit(0)
        
    print(f"🔍 [RAG RESULTADOS PARA: '{q}']\n")
    for src, title, content, dist in res:
        print(f"--- 📌 [{src} -> {title}] (Distância: {dist:.4f}) ---")
        print(content.strip())
        print("-" * 50 + "\n")
