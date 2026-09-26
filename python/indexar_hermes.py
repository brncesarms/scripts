#!/usr/bin/env python3
"""
indexar_homelab.py - Indexador RAG Nativo para o hermes.db
Usa sqlite-vec + fastembed (100% local, zero APIs externas).
"""
import os
import re
import sys

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

# Caminhos padrão
DB_PATH = os.environ.get("HERMES_DB_PATH", "/home/brn/archimedes/hermes.db")
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
    raw_sections = re.split(r'\n(?=##+ )', text)
    chunks = []
    source_file = os.path.basename(file_path)
    
    for sec in raw_sections:
        lines = sec.strip().split('\n')
        if not lines or not lines[0]:
            continue
        title = lines[0].lstrip('#').strip()
        content = '\n'.join(lines)
        if len(content) > 30:  # Ignorar fatias vazias/muito curtas
            # Estimativa simples de tokens (~4 chars por token)
            tokens_count = max(1, len(content) // 4)
            chunks.append((source_file, title, content, tokens_count))
            
    return chunks

def index_files(file_paths):
    """Gera embeddings locais e indexa no hermes.db."""
    valid_paths = [os.path.abspath(fp) for fp in file_paths if os.path.exists(fp)]
    if not valid_paths:
        print("🟡 [RAG] Nenhum arquivo válido encontrado para indexar.")
        return

    print(f"🟢 [RAG] Inicializando modelo de embeddings local: {EMBEDDING_MODEL}")
    model = TextEmbedding(model_name=EMBEDDING_MODEL)
    
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    init_db(conn)
    
    all_chunks = []
    for fp in valid_paths:
        chunks = chunk_markdown(fp)
        all_chunks.extend(chunks)
        print(f"📄 [RAG] Processado '{os.path.basename(fp)}': {len(chunks)} seções fatiadas.")
            
    if not all_chunks:
        print("🟡 [RAG] Nenhum chunk para indexar.")
        conn.close()
        return

    print(f"⚙️ [RAG] Gerando embeddings locais para {len(all_chunks)} chunks...")
    contents = [f"{c[1]}: {c[2]}" for c in all_chunks]  # Inclui título + conteúdo para melhor representação
    embeddings = list(model.embed(contents))
    
    # Limpar índice antigo para esses arquivos ou recriar
    conn.execute("DELETE FROM vec_chunks;")
    conn.execute("DELETE FROM chunks;")
    
    for (src, title, content, tokens_count), emb in zip(all_chunks, embeddings):
        cur = conn.execute(
            "INSERT INTO chunks (source_file, section_title, content, tokens_count) VALUES (?, ?, ?, ?);",
            (src, title, content, tokens_count)
        )
        chunk_id = cur.lastrowid
        conn.execute(
            "INSERT INTO vec_chunks (chunk_id, embedding) VALUES (?, ?);",
            (chunk_id, sqlite_vec.serialize_float32(emb.tolist()))
        )
        
    conn.commit()
    conn.close()
    print(f"🚀 [SUCESSO] {len(all_chunks)} chunks indexados com sucesso em '{DB_PATH}'!")
    propagar_hermes_db()

def propagar_hermes_db():
    """Propaga o hermes.db via Tailscale/LAN para os outros nós da Tríade Omarchy."""
    import subprocess
    import socket

    hostname = socket.gethostname()
    nodes = [
        {
            "name": "GEEKOM A7 MAX",
            "hostname": "geekom-brn",
            "ips": ["10.0.0.2", "100.100.63.15"],
            "targets": [
                "/home/brn/hermes/hermes-rag/hermes.db",
                "/home/brn/archimedes/hermes.db"
            ],
            "post_cmd": "systemctl --user restart hermes-rag-mcp.service"
        },
        {
            "name": "ALIENWARE Aurora",
            "hostname": "alienware-brn",
            "ips": ["10.0.0.216", "100.123.90.64"],
            "targets": [
                "/home/brn/archimedes/hermes.db"
            ],
            "post_cmd": None
        },
        {
            "name": "ACER Aspire",
            "hostname": "acer-brn",
            "ips": ["10.0.0.207", "100.119.100.53"],
            "targets": [
                "/home/brn/archimedes/hermes.db"
            ],
            "post_cmd": None
        }
    ]

    ssh_opts = ["-o", "ConnectTimeout=3", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]

    print("\n🌐 [RAG REPLICAÇÃO] Replicando hermes.db via Tailscale/LAN para a Tríade...")
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

        print(f"  🚀 [{node['name']}] Conectado via {alive_ip}. Enviando hermes.db...")
        for tgt in node["targets"]:
            tgt_dir = os.path.dirname(tgt)
            subprocess.run(["ssh"] + ssh_opts + [f"brn@{alive_ip}", f"mkdir -p {tgt_dir}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            cp_res = subprocess.run(["scp", "-q"] + ssh_opts + [DB_PATH, f"brn@{alive_ip}:{tgt}"])
            if cp_res.returncode == 0:
                print(f"    ✓ Atualizado em '{tgt}'")
            else:
                print(f"    ❌ Falha ao copiar para '{tgt}'")

        if node.get("post_cmd"):
            subprocess.run(["ssh"] + ssh_opts + [f"brn@{alive_ip}", node["post_cmd"]], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"    ✓ Serviço MCP reiniciado no nó {node['name']}.")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        files = sys.argv[1:]
    else:
        # Busca automática em archimedes, obsidian e scripts
        archimedes_dir = "/home/brn/archimedes"
        files = [
            os.path.join(archimedes_dir, "MANUAL_ESTRUTURA_PROJETO.md"),
            os.path.join(archimedes_dir, "README.md")
        ]
        
        # Inclui notas e vaults de /home/brn/obsidian
        obsidian_dir = "/home/brn/obsidian"
        if os.path.exists(obsidian_dir):
            for root, _, fnames in os.walk(obsidian_dir):
                if "/.git" in root or "/.obsidian" in root:
                    continue
                for fname in fnames:
                    if fname.endswith(".md"):
                        files.append(os.path.join(root, fname))

        # Inclui documentações da toolbox de automação (/home/brn/scripts)
        scripts_dir = "/home/brn/scripts"
        if os.path.exists(scripts_dir):
            for root, _, fnames in os.walk(scripts_dir):
                if "/.git" in root:
                    continue
                for fname in fnames:
                    if fname.endswith(".md"):
                        files.append(os.path.join(root, fname))
        
        # Filtra apenas os que existem
        files = [f for f in files if os.path.exists(f)]
            
    index_files(files)
