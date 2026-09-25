#!/usr/bin/env python3
"""
cofre.py - Cofre Criptografado Canônico da Tríade Omarchy
Padrão de Mercado & Zero Gambiarras: AES-256-CBC com PBKDF2 (100.000 iterações).

Uso:
  cofre set <chave> [valor] [--desc "Descrição"]
  cofre get <chave>
  cofre list
  cofre rm <chave>
  cofre status
"""

import sys
import os
import json
import secrets
import subprocess
import getpass
import argparse
from datetime import datetime

KEY_FILE = os.path.expanduser(os.environ.get("COFRE_KEY", "~/.config/cofre/cofre.key"))
VAULT_FILE = os.path.expanduser(os.environ.get("COFRE_FILE", "/home/brn/obsidian/vault-privado/credenciais/cofre.enc"))


def ensure_key():
    """Garante que a chave mestre exista com permissão restrita 600."""
    key_dir = os.path.dirname(KEY_FILE)
    if not os.path.exists(key_dir):
        os.makedirs(key_dir, mode=0o700, exist_ok=True)

    if not os.path.exists(KEY_FILE):
        # Gera chave criptográfica de 256 bits (64 hex characters)
        new_key = secrets.token_hex(32)
        with open(KEY_FILE, "w", encoding="utf-8") as f:
            f.write(new_key)
        os.chmod(KEY_FILE, 0o600)
    else:
        # Garante que as permissões estejam estritamente em 600
        current_mode = os.stat(KEY_FILE).st_mode & 0o777
        if current_mode != 0o600:
            os.chmod(KEY_FILE, 0o600)

    with open(KEY_FILE, "r", encoding="utf-8") as f:
        return f.read().strip()


def load_vault():
    """Carrega e descriptografa o conteúdo do cofre em memória."""
    key = ensure_key()
    if not os.path.exists(VAULT_FILE):
        return {}

    try:
        proc = subprocess.run([
            "openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "100000",
            "-in", VAULT_FILE,
            "-pass", f"pass:{key}"
        ], capture_output=True)

        if proc.returncode != 0:
            print("❌ Erro ao descriptografar o cofre. Verifique a chave em ~/.config/cofre/cofre.key", file=sys.stderr)
            sys.exit(1)

        decrypted_text = proc.stdout.decode("utf-8")
        return json.loads(decrypted_text)
    except Exception as e:
        print(f"❌ Erro ao ler dados do cofre: {e}", file=sys.stderr)
        sys.exit(1)


def save_vault(data):
    """Criptografa e grava os dados do cofre em disco com AES-256."""
    key = ensure_key()
    vault_dir = os.path.dirname(VAULT_FILE)
    if not os.path.exists(vault_dir):
        os.makedirs(vault_dir, mode=0o700, exist_ok=True)

    payload = json.dumps(data, indent=2, ensure_ascii=False).encode("utf-8")

    proc = subprocess.run([
        "openssl", "enc", "-aes-256-cbc", "-pbkdf2", "-iter", "100000", "-salt",
        "-out", VAULT_FILE,
        "-pass", f"pass:{key}"
    ], input=payload, capture_output=True)

    if proc.returncode != 0:
        print("❌ Erro ao criptografar o cofre com OpenSSL!", file=sys.stderr)
        sys.exit(1)

    os.chmod(VAULT_FILE, 0o600)


def cmd_set(args):
    data = load_vault()
    key = args.key.strip()
    value = args.value

    if not value:
        value = getpass.getpass(f"Digite a senha/segredo para '{key}': ")
        if not value:
            print("❌ Valor vazio não permitido.", file=sys.stderr)
            sys.exit(1)

    desc = args.desc or (data.get(key, {}).get("description", "Credencial da Bancada"))

    data[key] = {
        "value": value,
        "description": desc,
        "updated_at": datetime.now().isoformat()
    }

    save_vault(data)
    print(f"✅ Credencial '{key}' armazenada com sucesso no cofre.")


def cmd_get(args):
    data = load_vault()
    key = args.key.strip()
    if key in data:
        # Imprime apenas o valor puro para facilitar consumo em scripts
        sys.stdout.write(data[key]["value"])
        if sys.stdout.isatty():
            sys.stdout.write("\n")
    else:
        print(f"❌ Chave '{key}' não encontrada no cofre.", file=sys.stderr)
        sys.exit(1)


def cmd_list(args):
    data = load_vault()
    if not data:
        print("ℹ️ O cofre está vazio.")
        return

    print("\n🔐 CREDENCIAIS NO COFRE DA TRÍADE")
    print("=" * 75)
    print(f"{'CHAVE':<25} | {'DESCRIÇÃO':<30} | {'ATUALIZADO EM'}")
    print("-" * 75)
    for k, v in sorted(data.items()):
        desc = v.get("description", "")[:28]
        updated = v.get("updated_at", "")[:19].replace("T", " ")
        print(f"{k:<25} | {desc:<30} | {updated}")
    print("=" * 75)
    print(f"Total: {len(data)} credenciais registradas.\n")


def cmd_rm(args):
    data = load_vault()
    key = args.key.strip()
    if key in data:
        del data[key]
        save_vault(data)
        print(f"🗑️ Credencial '{key}' removida com sucesso.")
    else:
        print(f"❌ Chave '{key}' não encontrada.", file=sys.stderr)
        sys.exit(1)


def cmd_status(args):
    key = ensure_key()
    vault_exists = os.path.exists(VAULT_FILE)
    items_count = len(load_vault()) if vault_exists else 0

    print("\n🛡️ STATUS DO COFRE DA TRÍADE")
    print("=" * 60)
    print(f"Chave Mestre : {KEY_FILE} (Permissão 600)")
    print(f"Arquivo Cifrado : {VAULT_FILE}")
    print(f"Status no Disco : {'✅ Presente' if vault_exists else '⚠️ Não inicializado'}")
    print(f"Algoritmo       : AES-256-CBC (PBKDF2 100k iter)")
    print(f"Total Segredos  : {items_count}")
    print("=" * 60 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Cofre Criptografado da Tríade Omarchy (AES-256 PBKDF2)",
        prog="cofre"
    )
    subparsers = parser.add_subparsers(dest="command", help="Comandos disponíveis")

    # set
    p_set = subparsers.add_parser("set", help="Salva ou atualiza uma credencial")
    p_set.add_argument("key", help="Nome identificador da chave (ex: sudo_geekom)")
    p_set.add_argument("value", nargs="?", default=None, help="Valor do segredo (opcional, pede seguro se omitido)")
    p_set.add_argument("--desc", help="Descrição contextual da credencial")
    p_set.set_defaults(func=cmd_set)

    # get
    p_get = subparsers.add_parser("get", help="Recupera o segredo de uma chave")
    p_get.add_argument("key", help="Nome identificador da chave")
    p_get.set_defaults(func=cmd_get)

    # list
    p_list = subparsers.add_parser("list", help="Lista as chaves registradas (sem expor segredos)")
    p_list.set_defaults(func=cmd_list)

    # rm
    p_rm = subparsers.add_parser("rm", help="Remove uma credencial")
    p_rm.add_argument("key", help="Nome identificador da chave a remover")
    p_rm.set_defaults(func=cmd_rm)

    # status
    p_status = subparsers.add_parser("status", help="Exibe status e integridade do cofre")
    p_status.set_defaults(func=cmd_status)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(0)

    args.func(args)


if __name__ == "__main__":
    main()
