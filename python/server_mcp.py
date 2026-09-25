#!/usr/bin/env python3
"""
server_mcp.py - Servidor MCP para o RAG Semântico do Home Lab / Bancada
Expõe a ferramenta 'buscar_conhecimento_homelab' para Antigravity CLI e Hermes Agent.
Suporta transporte Stdio e SSE (HTTP/SSE).
"""

import os
import sys
import argparse
import sqlite3
from typing import List, Dict, Any

from mcp.server.mcpserver import MCPServer
from mcp.server.transport_security import TransportSecuritySettings
import sqlite_vec
from fastembed import TextEmbedding

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Procura hermes.db na pasta atual ou na pasta pai (raiz do repositório)
_db_candidate1 = os.path.join(os.path.dirname(BASE_DIR), "hermes.db")
_db_candidate2 = os.path.join(BASE_DIR, "hermes.db")
DB_PATH = _db_candidate1 if os.path.exists(_db_candidate1) else _db_candidate2
EMBEDDING_MODEL = "BAAI/bge-small-en-v1.5"

# Inicializa o servidor MCP
mcp = MCPServer(
    name="homelab-rag",
    version="1.0.0",
    description="RAG Semântico da Bancada: MikroTik, Proxmox VE, VMs, IPs, Credenciais e Procedimentos"
)

# Cache do modelo de embeddings
_model = None

def get_embedding_model():
    global _model
    if _model is None:
        _model = TextEmbedding(model_name=EMBEDDING_MODEL)
    return _model

def execute_search(query: str, k: int = 5) -> List[Dict[str, Any]]:
    if not os.path.exists(DB_PATH):
        return []

    model = get_embedding_model()
    query_emb = list(model.embed([query]))[0]

    conn = sqlite3.connect(DB_PATH)
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)

    query_bytes = sqlite_vec.serialize_float32(query_emb.tolist())

    cursor = conn.cursor()
    cursor.execute("""
        SELECT c.source_file, c.section_title, c.content, v.distance
        FROM vec_chunks v
        JOIN chunks c ON c.id = v.chunk_id
        WHERE v.embedding MATCH ? AND k = ?
        ORDER BY v.distance
    """, (query_bytes, k))
    rows = cursor.fetchall()
    conn.close()

    results = []
    for source_file, section_title, content, distance in rows:
        results.append({
            "source_file": source_file,
            "section_title": section_title,
            "content": content.strip(),
            "distance": round(distance, 4)
        })
    return results

@mcp.tool(
    name="buscar_conhecimento_homelab",
    description="Consulta o RAG semântico da bancada para recuperar comandos MikroTik, Proxmox VE, inventário de nós, IPs, procedimentos SSH, regras de automação e credenciais."
)
def buscar_conhecimento_homelab(query: str, top_k: int = 5) -> str:
    """Busca trechos relevantes na base de conhecimento semântica da bancada.

    Args:
        query: Pergunta ou termo a ser pesquisado (ex: 'comandos mikrotik', 'desligamento proxmox', 'ips bancada').
        top_k: Número máximo de trechos relevantes a retornar (padrão: 5).
    """
    if not query or not query.strip():
        return "Erro: Parâmetro 'query' não pode estar vazio."

    try:
        results = execute_search(query.strip(), k=max(1, min(top_k, 10)))
        if not results:
            return f"Nenhuma informação encontrada na base de conhecimento para a consulta: '{query}'."

        output = [f"### 🔍 Resultados do RAG da Bancada para: '{query}'\n"]
        for idx, item in enumerate(results, 1):
            output.append(
                f"#### [{idx}] 📄 {item['source_file']} ➔ {item['section_title']} (Distância: {item['distance']})\n"
                f"{item['content']}\n"
                f"{'-' * 40}"
            )
        return "\n\n".join(output)
    except Exception as e:
        return f"Erro ao consultar a base de conhecimento do Home Lab: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description="Servidor MCP do RAG Home Lab")
    parser.add_argument("--sse", action="store_true", help="Rodar servidor em modo SSE (HTTP)")
    parser.add_argument("--host", default="0.0.0.0", help="Host para bind em modo SSE (padrão: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=8765, help="Porta para bind em modo SSE (padrão: 8765)")
    args = parser.parse_args()

    # Aquecimento prévio do modelo para respostas instantâneas
    get_embedding_model()

    if args.sse:
        sec = TransportSecuritySettings(
            enable_dns_rebinding_protection=False,
            allowed_hosts=["*"],
            allowed_origins=["*"]
        )
        print(f"🚀 Iniciando Servidor MCP SSE em http://{args.host}:{args.port}/sse", file=sys.stderr)
        mcp.run(
            transport="sse",
            host=args.host,
            port=args.port,
            transport_security=sec
        )
    else:
        mcp.run(transport="stdio")

if __name__ == "__main__":
    main()
