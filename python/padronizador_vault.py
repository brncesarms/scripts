#!/usr/bin/env python3
"""
padronizador_vault.py - Padronizador Determinístico de Notas e Vaults do Obsidian
Ajusta nomenclatura de arquivos (dois dígitos), normaliza frontmatter YAML (privacy, author, tags)
e corrige referências internas em lote sem consumo excessivo de tokens.
"""

import os
import sys
import re
import argparse
import subprocess
from pathlib import Path

OBSIDIAN_BASE = "/home/brn/obsidian"

DEFAULT_AUTHOR = "Bruno César / Antigravity"

def get_vault_path(vault_input: str) -> Path:
    p = Path(vault_input)
    if p.is_dir():
        return p.resolve()
    
    # Tenta em /home/brn/obsidian/<vault_input>
    candidate = Path(OBSIDIAN_BASE) / vault_input
    if candidate.is_dir():
        return candidate.resolve()
    
    raise ValueError(f"Vault não encontrado: {vault_input} (nem como caminho absoluto nem em {OBSIDIAN_BASE})")

def normalize_filename(old_name: str) -> str:
    """Padroniza arquivos com prefixo de 1 dígito (ex: 1_foo.md -> 01_foo.md)."""
    m = re.match(r"^([0-9])_([a-zA-Z0-9_\-]+)\.md$", old_name)
    if m:
        digit, rest = m.groups()
        return f"0{digit}_{rest}.md"
    
    # Caso especial específico de notas legadas conhecidas
    if old_name == "ssh-remoto-configuracao.md":
        return "20_ssh_remoto_configuracao.md"
        
    return old_name

def parse_frontmatter(content: str):
    """Separa o YAML frontmatter do corpo do markdown."""
    pattern = r"^---\s*\n(.*?)\n---\s*\n(.*)$"
    match = re.match(pattern, content, re.DOTALL)
    if match:
        fm_text = match.group(1)
        body = match.group(2)
        return fm_text, body
    return None, content

def update_frontmatter(fm_text: str, default_title: str, privacy: str = "public") -> str:
    """Atualiza ou constrói o YAML frontmatter garantindo campos obrigatórios."""
    lines = fm_text.splitlines() if fm_text else []
    data = {}
    tags = []
    
    in_tags = False
    for line in lines:
        if line.strip().startswith("tags:"):
            in_tags = True
            continue
        if in_tags:
            tag_match = re.match(r"^\s*-\s*(.+)$", line)
            if tag_match:
                tag_val = tag_match.group(1).strip().strip("'\"")
                tags.append(tag_val)
                continue
            elif re.match(r"^\s*[a-zA-Z0-9_\-]+:", line):
                in_tags = False
        
        kv_match = re.match(r"^([a-zA-Z0-9_\-]+)\s*:\s*(.*)$", line)
        if kv_match and not in_tags:
            k, v = kv_match.groups()
            data[k.strip()] = v.strip().strip("'\"")

    # Garante campos obrigatórios
    title = data.get("title", default_title)
    date_created = data.get("date_created", "2026-08-17")
    author = data.get("author", DEFAULT_AUTHOR)
    
    # Tags normalizadas
    if privacy == "public":
        if "publico" not in tags:
            tags.insert(0, "publico")
    elif privacy == "private":
        if "privado" not in tags:
            tags.insert(0, "privado")
            
    # Remove tags duplicadas preservando ordem
    clean_tags = []
    for t in tags:
        if t not in clean_tags:
            clean_tags.append(t)

    # Reconstroi frontmatter YAML
    out_lines = [
        "---",
        f"title: \"{title}\"",
        f"date_created: {date_created}",
        f"author: \"{author}\"",
        f"privacy: {privacy}",
        "tags:"
    ]
    for t in clean_tags:
        out_lines.append(f"  - {t}")
    out_lines.append("---")
    
    return "\n".join(out_lines)

def run_git_mv(repo_dir: Path, src: str, dst: str, dry_run: bool = False):
    """Executa git mv mantendo histórico."""
    if dry_run:
        print(f"   [DRY-RUN] git mv {src} -> {dst}")
        return
    
    cmd = ["git", "mv", src, dst]
    res = subprocess.run(cmd, cwd=repo_dir, capture_output=True, text=True)
    if res.returncode != 0:
        # Se git mv falhar (ex: não rastreado ainda), usa rename padrão
        src_path = repo_dir / src
        dst_path = repo_dir / dst
        src_path.rename(dst_path)

def main():
    parser = argparse.ArgumentParser(description="Padronizador de Notas de Vaults do Obsidian")
    parser.add_argument("--vault", required=True, help="Nome do vault ou caminho absoluto (ex: windows, linux)")
    parser.add_argument("--privacy", default="public", choices=["public", "private"], help="Nível de privacidade (default: public)")
    parser.add_argument("--dry-run", action="store_true", help="Simula as ações sem alterar arquivos")
    args = parser.parse_args()

    vault_path = get_vault_path(args.vault)
    is_git = (vault_path / ".git").is_dir()

    print(f"✨ Iniciando padronização no vault: {vault_path.name} ({vault_path})")
    print(f"🔒 Privacidade alvo: {args.privacy} | Git detectado: {is_git}")
    if args.dry_run:
        print("🔍 MODO SIMULAÇÃO (DRY-RUN) ATIVO")

    md_files = sorted(list(vault_path.glob("*.md")))
    if not md_files:
        print("❌ Nenhum arquivo Markdown (.md) encontrado no vault.")
        return

    # Passo 1: Mapear renomeações necessárias
    renames = {}
    for f in md_files:
        filename = f.name
        new_filename = normalize_filename(filename)
        if new_filename != filename:
            renames[filename] = new_filename

    print(f"\n📁 Verificando nomes de arquivos... ({len(renames)} a renomear)")
    for old_name, new_name in renames.items():
        print(f"   🔄 Renomeando: {old_name} ➔ {new_name}")
        run_git_mv(vault_path, old_name, new_name, args.dry_run)

    # Passo 2: Atualizar lista de arquivos após renomeação
    current_files = sorted(list(vault_path.glob("*.md")))

    # Mapa de substituição de links
    link_replacements = {}
    for old_name, new_name in renames.items():
        link_replacements[old_name] = new_name
        link_replacements[f"./{old_name}"] = f"./{new_name}"

    print(f"\n📝 Normalizando Frontmatter YAML e Links Internos em {len(current_files)} notas...")
    for f in current_files:
        with open(f, "r", encoding="utf-8") as fp:
            content = fp.read()

        fm_text, body = parse_frontmatter(content)
        
        # Obter título default
        title_match = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
        default_title = title_match.group(1).strip() if title_match else f.stem

        new_fm = update_frontmatter(fm_text, default_title, privacy=args.privacy)

        # Atualizar links que referenciam arquivos renomeados
        new_body = body
        for old_ref, new_ref in link_replacements.items():
            pattern = rf"\]\((\.?/?){re.escape(old_ref)}\)"
            new_body = re.sub(pattern, lambda m, nr=new_ref: f"]({m.group(1)}{nr})", new_body)

        # Tratar links legados do monorepo antigo (ex: ../README.md)
        new_body = new_body.replace("](../README.md)", "](README.md)")

        new_content = f"{new_fm}\n\n{new_body.lstrip()}"

        if not args.dry_run:
            with open(f, "w", encoding="utf-8") as fp:
                fp.write(new_content)
        print(f"   ✅ Processado: {f.name}")

    print("\n🎉 Padronização de notas e frontmatters concluída com sucesso!")

if __name__ == "__main__":
    main()
