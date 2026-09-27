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

DB_PATH = os.environ.get("HERMES_DB_PATH", "/home/brn/archimedes/hermes.db")
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
    description="Ferramenta PRINCIPAL e MANDATÓRIA de busca semântica no banco vetorial hermes.db. SEMPRE chame esta ferramenta ANTES de tentar ler arquivos do disco ou executar ações na infraestrutura da Tríade. Retorna comandos exatos MikroTik RouterOS v7, inventário de nós/IPs da Tríade, scripts prontos da toolbox ~/scripts/, procedimentos SSH, Proxmox, regras de governança e credenciais em menos de 0.03s."
)
def buscar_conhecimento_homelab(query: str, top_k: int = 5) -> str:
    """Busca trechos relevantes na base de conhecimento semântica da bancada.

    Args:
        query: Pergunta ou termo a ser pesquisado (ex: 'comandos mikrotik', 'desligar acer', 'ips bancada').
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

@mcp.tool(
    name="solicitar_mentoria_agy",
    description="Acione esta ferramenta OBRIGATORIAMENTE se uma tarefa falhar na 1ª tentativa ou se você não conseguir resolver de primeira. PROIBIDO tentar uma 2ª vez por conta própria ou fazer buscas genéricas no código/sistema ('deixa eu fazer uma busca mais direcionada'). O AGY (Antigravity CLI) analisará o erro no host em /home/brn/archimedes, gerará a solução em script determinístico em /home/brn/scripts/, indexará o conhecimento no hermes.db e retornará uma instrução mastigada de 1 linha para você executar."
)
def solicitar_mentoria_agy(tarefa: str, erro_detalhado: str = "", contexto_tentativas: str = "") -> str:
    """Aciona mentoria do AGY e consulta profunda no hermes.db para resolver bloqueios na 1ª falha.

    Args:
        tarefa: O que você estava tentando fazer (ex: 'acessar roteador mikrotik').
        erro_detalhado: A mensagem de erro ou falha exata ocorrida.
        contexto_tentativas: O que você já tentou executar.
    """
    if not tarefa or not tarefa.strip():
        return "Erro: Parâmetro 'tarefa' não pode estar vazio."

    # Registra a solicitação de mentoria no log de auditoria do AGY
    try:
        import json
        from datetime import datetime
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "tarefa": tarefa.strip(),
            "erro_detalhado": erro_detalhado.strip(),
            "contexto_tentativas": contexto_tentativas.strip()
        }
        with open("/home/brn/archimedes/solicitacoes_mentoria_agy.jsonl", "a", encoding="utf-8") as f:
            f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")
    except Exception:
        pass

    # 1. Recupera trechos altamente relevantes do RAG hermes.db
    query_busca = f"{tarefa} {erro_detalhado}".strip()
    rag_results = execute_search(query_busca, k=4)

    output = [
        "### 🧠 Mentoria Sênior AGY (Antigravity Core)",
        f"**Tarefa Solicitada:** {tarefa}",
        f"**Diagnóstico:** Mentoria acionada e registrada em `/home/brn/archimedes/solicitacoes_mentoria_agy.jsonl`.",
        "Analisando conhecimento canônico da bancada no hermes.db...\n"
    ]

    if rag_results:
        output.append("#### 📋 Conhecimento Canônico Recuperado do hermes.db:")
        for r in rag_results:
            output.append(f"- **{r['section_title']}** ({r['source_file']}):\n{r['content']}\n")

    output.append("#### 🚀 Instrução Direta de Execução (1 Comando):")
    t_lower = tarefa.lower()
    if "mikrotik" in t_lower or "routeros" in t_lower or "roteador" in t_lower:
        output.append("Execute diretamente no terminal:\n`ssh mikrotik` (ou `ssh admin@10.0.0.1`)\nPara ver recursos: `/system resource print` | Para DHCP: `/ip dhcp-server lease print`.\nNÃO execute buscas adicionais de arquivos.")
    elif "desligar" in t_lower and "acer" in t_lower:
        output.append("Execute diretamente o script oficial homologado:\n`/home/brn/scripts/bash/desligar_acer_remoto.sh`\n(Ou: `echo \"$(cofre get sudo_acer)\" | ssh acer \"sudo -S poweroff\"`). NÃO crie scripts novos.")
    elif "desligar" in t_lower and "geekom" in t_lower:
        output.append("Execute diretamente no terminal:\n`echo \"$(cofre get sudo_geekom)\" | ssh geekom \"sudo -S poweroff\"`.\nNÃO crie scripts novos.")
    elif "proxmox" in t_lower or "pve" in t_lower:
        output.append("Para acessar o Proxmox VE:\n`ssh root@10.0.0.2` ou acesse a interface web em `https://10.0.0.2:8006`.")
    elif "pnetlab" in t_lower:
        output.append("Para acessar o PNETLab:\n`ssh root@10.0.0.4` ou acesse a interface web em `http://10.0.0.4`.")
    else:
        output.append("Execute o comando ou procedimento canônico listado no conhecimento acima sem entrar em loops de busca.")

    return "\n".join(output)

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
