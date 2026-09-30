#!/usr/bin/env python3
"""
indexar_agy.py - Indexador RAG Nativo para o archimedes.db
Usa sqlite-vec + fastembed (100% local, zero APIs externas).
"""
import os
import re
import sys

# Auto-elevação para o ambiente virtual .venv se não estiver ativo
_venv_candidates = [
    "/home/brn/archimedes/.venv/bin/python3",
]
_venv_python = next((p for p in _venv_candidates if os.path.exists(p)), None)
if _venv_python and sys.executable != _venv_python:
    try:
        import sqlite_vec
        import fastembed
    except ImportError:
        os.execv(_venv_python, [_venv_python] + sys.argv)

import sqlite3
import sqlite_vec
from fastembed import TextEmbedding

# Caminhos padrão
DB_PATH = os.environ.get("ARCHIMEDES_DB_PATH", os.environ.get("AGY_DB_PATH", os.environ.get("HERMES_DB_PATH", "/home/brn/archimedes/archimedes.db")))
EMBEDDING_MODEL = "BAAI/bge-small-en-v1.5"

def init_db(conn):
    """Inicializa as tabelas e extensões do sqlite-vec."""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    
    conn.executescript("""
    CREATE TABLE IF NOT EXISTS chunks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_file TEXT NOT NULL,
        section_title TEXT NOT NULL,
        content TEXT NOT NULL,
        tokens_count INTEGER DEFAULT 0,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE VIRTUAL TABLE IF NOT EXISTS vec_chunks USING vec0(
        chunk_id INTEGER PRIMARY KEY,
        embedding float[384]
    );
    """)
    conn.commit()

def chunk_markdown(file_path):
    """Fatia o Markdown em seções H2/H3 preservando blocos de código."""
    with open(file_path, "r", encoding="utf-8") as f:
        text = f.read()
    
    # Divide por cabeçalhos ## ou ###
    sections = re.split(r'\n(?=#{2,3}\s)', text)
    chunks = []
    
    rel_path = os.path.basename(file_path)
    
    for sec in sections:
        sec_clean = sec.strip()
        if not sec_clean:
            continue
            
        lines = sec_clean.split("\n")
        header_match = re.match(r'^(#{2,3})\s+(.+)', lines[0])
        title = header_match.group(2).strip() if header_match else "Geral"
        
        # Ignora seções muito curtas de links genéricos se isoladas
        if len(sec_clean) < 40 and "Notas Relacionadas" in title:
            continue
            
        chunks.append({
            "source_file": rel_path,
            "section_title": title,
            "content": sec_clean,
            "tokens_count": len(sec_clean.split())
        })
        
    return chunks

def index_vault():
    """Varre /home/brn/obsidian e /home/brn/scripts/ para indexar notas e scripts."""
    vault_dir = "/home/brn/obsidian"
    scripts_dir = "/home/brn/scripts"
    archimedes_dir = "/home/brn/archimedes"
    
    all_files = []
    
    # 1. Notas do Obsidian (.md)
    if os.path.exists(vault_dir):
        for root, _, files in os.walk(vault_dir):
            for file in files:
                if file.endswith(".md"):
                    all_files.append(os.path.join(root, file))

    # 2. Arquivos de Governança Raiz
    if os.path.exists(archimedes_dir):
        for fname in ["AGENTS.md", "MANUAL_ESTRUTURA_PROJETO.md"]:
            fpath = os.path.join(archimedes_dir, fname)
            if os.path.exists(fpath):
                all_files.append(fpath)
                    
    # 3. Scripts (.sh, .py, .ps1)
    if os.path.exists(scripts_dir):
        for root, _, files in os.walk(scripts_dir):
            if ".git" in root:
                continue
            for file in files:
                if file.endswith((".sh", ".py", ".ps1")):
                    all_files.append(os.path.join(root, file))
                    
    all_chunks = []
    for fpath in all_files:
        try:
            if fpath.endswith(".md"):
                c = chunk_markdown(fpath)
            else:
                with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                rel_p = os.path.basename(fpath)
                c = [{
                    "source_file": rel_p,
                    "section_title": f"Script {rel_p}",
                    "content": f"### Script: {rel_p}\nPath: {fpath}\n```\n{content[:2000]}\n```",
                    "tokens_count": len(content.split())
                }]
            all_chunks.extend(c)
            print(f"📄 [RAG] Processado '{os.path.basename(fpath)}': {len(c)} chunk(s).")
        except Exception as e:
            print(f"⚠️ Erro ao processar {fpath}: {e}")
            
    if not all_chunks:
        print("🟡 NENHUM arquivo para indexar!")
        return
        
    print(f"\n⚙️ [RAG] Gerando embeddings locais para {len(all_chunks)} chunks...")
    model = TextEmbedding(model_name=EMBEDDING_MODEL)
    texts = [c["content"] for c in all_chunks]
    embeddings = list(model.embed(texts))
    
    conn = sqlite3.connect(DB_PATH)
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    
    init_db(conn)
    
    # Reseta banco
    conn.execute("DELETE FROM vec_chunks")
    conn.execute("DELETE FROM chunks")
    
    for chunk, emb in zip(all_chunks, embeddings):
        cursor = conn.execute("""
            INSERT INTO chunks (source_file, section_title, content, tokens_count)
            VALUES (?, ?, ?, ?)
        """, (chunk["source_file"], chunk["section_title"], chunk["content"], chunk["tokens_count"]))
        
        chunk_id = cursor.lastrowid
        emb_bytes = sqlite_vec.serialize_float32(emb.tolist())
        
        conn.execute("""
            INSERT INTO vec_chunks (chunk_id, embedding)
            VALUES (?, ?)
        """, (chunk_id, emb_bytes))
        
    conn.commit()
    conn.close()
    print(f"🚀 [SUCESSO] {len(all_chunks)} chunks indexados com sucesso em '{DB_PATH}'!")
    propagar_agy_db()

def propagar_agy_db():
    """Propaga o agy.db via Tailscale/LAN para os outros nós da Tríade Omarchy."""
    import subprocess
    import socket

    hostname = socket.gethostname()
    nodes = [
        {
            "name": "GEEKOM A7 MAX",
            "hostname": "geekom-brn",
            "ips": ["10.0.0.2", "100.100.63.15"],
            "targets": [
                "/home/brn/archimedes/archimedes.db",
                "/home/brn/scripts/python/archimedes.db"
            ],
            "post_cmd": "systemctl --user restart agy-rag-mcp.service || systemctl --user restart hermes-rag-mcp.service"
        },
        {
            "name": "ALIENWARE Aurora",
            "hostname": "alienware-brn",
            "ips": ["10.0.0.216", "100.123.90.64"],
            "targets": [
                "/home/brn/archimedes/archimedes.db"
            ],
            "post_cmd": None
        },
        {
            "name": "ACER Aspire",
            "hostname": "acer-brn",
            "ips": ["10.0.0.207", "100.119.100.53"],
            "targets": [
                "/home/brn/archimedes/archimedes.db"
            ],
            "post_cmd": None
        }
    ]

    ssh_opts = ["-o", "ConnectTimeout=3", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]

    print("\n🌐 [RAG REPLICAÇÃO] Replicando archimedes.db via Tailscale/LAN para a Tríade...")
    for node in nodes:
        if node["hostname"] in hostname:
            continue

        alive_ip = None
        for ip in node["ips"]:
            res = subprocess.run(
                ["ssh"] + ssh_opts + [f"brn@{ip}", "echo ok"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            if res.returncode == 0:
                alive_ip = ip
                break

        if not alive_ip:
            print(f"  🟡 [{node['name']}] Nó offline ou inacessível no momento. Sincronização pulada.")
            continue

        print(f"  🚀 [{node['name']}] Conectado via {alive_ip}. Enviando agy.db...")
        for tgt in node["targets"]:
            tgt_dir = os.path.dirname(tgt)
            subprocess.run(["ssh"] + ssh_opts + [f"brn@{alive_ip}", f"mkdir -p {tgt_dir}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            cp_res = subprocess.run(["scp", "-q"] + ssh_opts + [DB_PATH, f"brn@{alive_ip}:{tgt}"])
            if cp_res.returncode == 0:
                print(f"    ✓ Atualizado em '{tgt}'")

        if node["post_cmd"]:
            subprocess.run(["ssh"] + ssh_opts + [f"brn@{alive_ip}", node["post_cmd"]], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"    ✓ Serviço MCP reiniciado no nó {node['name']}.")

if __name__ == "__main__":
    index_vault()
