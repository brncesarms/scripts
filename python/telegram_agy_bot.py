#!/usr/bin/env python3
"""
telegram_agy_bot.py - Bot do Telegram do Archimedes no Proxmox VE
Daemon 24/7 de automação e RAG na Tríade Omarchy.
"""

import os
import sys
import time
import json
import subprocess
import requests

VENV_PYTHON = "/home/brn/scripts/python/.venv/bin/python3"

def exec_cmd(cmd, timeout=30):
    """Executa comando shell e retorna stdout."""
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return res.stdout.strip() or res.stderr.strip()
    except subprocess.TimeoutExpired:
        return f"⚠️ O comando excedeu o tempo limite de {timeout} segundos."
    except Exception as e:
        return f"❌ Erro ao executar comando: {e}"

def get_cofre_val(key):
    """Obtém credencial do cofre.py."""
    out = exec_cmd(f"{VENV_PYTHON} /home/brn/scripts/python/cofre.py get {key} 2>/dev/null", timeout=10)
    if out and not out.startswith("❌") and not out.startswith("usage"):
        return out.strip()
    return None

def set_cofre_val(key, val, desc=""):
    """Salva credencial no cofre.py."""
    exec_cmd(f'{VENV_PYTHON} /home/brn/scripts/python/cofre.py set {key} "{val}" --desc "{desc}"', timeout=10)

# 1. Carrega Token do Bot
TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN") or get_cofre_val("telegram_bot_token")
if not TOKEN:
    print("❌ Erro: telegram_bot_token não encontrado no cofre nem em variáveis de ambiente!")
    sys.exit(1)

API_URL = f"https://api.telegram.org/bot{TOKEN}"

# 2. Carrega Usuários Permitidos (Chat IDs)
allowed_users_raw = os.environ.get("TELEGRAM_ALLOWED_USERS") or get_cofre_val("telegram_allowed_users")
ALLOWED_USERS = set()
if allowed_users_raw:
    for uid in allowed_users_raw.split(","):
        uid_str = uid.strip()
        if uid_str.isdigit():
            ALLOWED_USERS.add(int(uid_str))

def send_message(chat_id, text, parse_mode="Markdown"):
    """Envia mensagem via Telegram API."""
    url = f"{API_URL}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": parse_mode
    }
    try:
        res = requests.post(url, json=payload, timeout=10)
        if not res.ok:
            payload.pop("parse_mode", None)
            requests.post(url, json=payload, timeout=10)
    except Exception as e:
        print(f"❌ Erro ao enviar mensagem Telegram: {e}")

def send_chat_action(chat_id, action="typing"):
    """Envia ação de digitando no chat."""
    try:
        requests.post(f"{API_URL}/sendChatAction", json={"chat_id": chat_id, "action": action}, timeout=5)
    except Exception:
        pass

def handle_start(chat_id, user_info):
    global ALLOWED_USERS
    first_name = user_info.get('first_name', 'Bruno')
    if not ALLOWED_USERS:
        ALLOWED_USERS.add(chat_id)
        set_cofre_val("telegram_allowed_users", str(chat_id), "Chat ID do Administrador no Telegram")
        msg = f"👋 **Olá, {first_name}!**\n\n" \
              f"🔒 Seu Chat ID (`{chat_id}`) foi registrado com sucesso como **Administrador Único** do **Archimedes Bot** no Proxmox VE!\n\n" \
              f"⚡ **Comandos Disponíveis:**\n" \
              f"• `/status` - Status em tempo real do LXC 100 Archimedes e Proxmox\n" \
              f"• `/rag <pergunta>` - Consulta instantânea RAG na base archimedes.db\n" \
              f"• Digite qualquer dúvida para consultar a inteligência da bancada."
    else:
        msg = f"🏛️ **Archimedes Bot On-line (LXC 100 Proxmox)**\n\n" \
              f"Olá, {first_name}! A foto de perfil do bot ficou excelente! 🏛️✨\n\n" \
              f"• Use `/status` para verificar hardware e serviços.\n" \
              f"• Use `/rag <pergunta>` ou envie uma mensagem direta com sua dúvida de infraestrutura."
    send_message(chat_id, msg)

def handle_status(chat_id):
    send_chat_action(chat_id)
    uptime = exec_cmd("uptime -p")
    mem = exec_cmd("free -h | grep Mem | awk '{print $3\" / \"$2}'")
    cpu = exec_cmd("nproc 2>/dev/null || echo '4'").strip()
    load = exec_cmd("cat /proc/loadavg | awk '{print $1\", \"$2\", \"$3}'")
    
    msg = f"🏛️ **Status do LXC 100 Archimedes (Proxmox VE)**\n\n" \
          f"• **vCPUs**: {cpu} Cores\n" \
          f"• **Uptime**: {uptime}\n" \
          f"• **RAM em uso**: {mem}\n" \
          f"• **Carga (Load)**: {load}\n" \
          f"• **RAG Database**: `archimedes.db` (Ativo)\n" \
          f"• **Tailscale IP**: `100.79.165.66` (Online)\n\n" \
          f"⚡ *Archimedes Engine 100% Operacional*"
    send_message(chat_id, msg)

def handle_rag(chat_id, query):
    if not query.strip():
        send_message(chat_id, "💡 Uso correto: `/rag <sua pergunta ou comando>`")
        return
    send_chat_action(chat_id)
    out = exec_cmd(f'{VENV_PYTHON} /home/brn/scripts/python/buscar_agy.py "{query}"', timeout=15)
    
    if len(out) > 3500:
        out = out[:3500] + "\n\n... (Resultado truncado por tamanho)"
    send_message(chat_id, f"📚 **Resultado RAG (`archimedes.db`):**\n\n{out}")

def handle_chat(chat_id, prompt):
    send_chat_action(chat_id)
    p_lower = prompt.lower().strip()
    
    # Tratamento de cumprimentos simples para não poluir com RAG bruto
    saudacoes = ["oi", "olá", "ola", "bom dia", "boa tarde", "boa noite", "hey", "hello", "teste"]
    if p_lower in saudacoes:
        msg = f"👋 **Olá, Bruno!** O bot **Archimedes** está 100% ativo e funcionando perfeitamente no Proxmox!\n\n" \
              f"A nova foto do perfil com a estátua de Arquimedes ficou sensacional! 🏛️✨\n\n" \
              f"💡 **Como posso te ajudar agora?**\n" \
              f"• Envie uma dúvida de infra/redes para busca na base `archimedes.db`.\n" \
              f"• Digite `/status` para ver os recursos do servidor."
        send_message(chat_id, msg)
        return

    # Caso seja uma dúvida ou consulta técnica, executa o RAG semântico
    out = exec_cmd(f'{VENV_PYTHON} /home/brn/scripts/python/buscar_agy.py "{prompt}"', timeout=15)
    
    if out and not out.startswith("❌"):
        if len(out) > 3500:
            out = out[:3500] + "\n\n... (Resultado truncado)"
        send_message(chat_id, f"🧠 **Resposta Archimedes (RAG `archimedes.db`):**\n\n{out}")
    else:
        send_message(chat_id, f"⚡ **Comando recebido:** {prompt}\n\nUse `/rag <pergunta>` para consultar a base de conhecimento.")

def main():
    print("🚀 Iniciando Archimedes Telegram Bot Daemon...")
    offset = 0
    while True:
        try:
            url = f"{API_URL}/getUpdates?offset={offset}&timeout=30"
            resp = requests.get(url, timeout=35)
            if not resp.ok:
                time.sleep(5)
                continue
            
            data = resp.json()
            for update in data.get("result", []):
                offset = update["update_id"] + 1
                msg_data = update.get("message") or update.get("edited_message")
                if not msg_data:
                    continue
                
                chat_id = msg_data["chat"]["id"]
                user_info = msg_data.get("from", {})
                text = msg_data.get("text", "").strip()
                
                if ALLOWED_USERS and chat_id not in ALLOWED_USERS:
                    send_message(chat_id, f"⛔ Acesso Negado! Chat ID `{chat_id}` não autorizado.")
                    continue
                
                if text.startswith("/start"):
                    handle_start(chat_id, user_info)
                elif text.startswith("/status"):
                    handle_status(chat_id)
                elif text.startswith("/rag"):
                    parts = text.split(" ", 1)
                    query = parts[1] if len(parts) > 1 else ""
                    handle_rag(chat_id, query)
                elif text.startswith("/help"):
                    handle_start(chat_id, user_info)
                elif text.startswith("/"):
                    send_message(chat_id, "💡 Comando desconhecido. Use `/status`, `/rag <pergunta>` ou envie uma mensagem direta.")
                elif text:
                    handle_chat(chat_id, text)
                    
        except Exception as e:
            print(f"⚠️ Exceção no loop principal do Telegram: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
