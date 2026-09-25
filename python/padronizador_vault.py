#!/usr/bin/env python3
"""
padronizador_vault.py - Padronizador Determinístico de Notas e Vaults do Obsidian
Ajusta nomenclatura de arquivos (dois dígitos), normaliza frontmatter YAML (privacy, author, tags)
e corrige referências internas em lote sem consumo excessivo de tokens.
Suporta repositórios planos e com subdiretórios recursivos.
"""

import os
import sys
import re
import argparse
import subprocess
from pathlib import Path

OBSIDIAN_BASE = "/home/brn/obsidian"
DEFAULT_AUTHOR = "Bruno César / Antigravity"

VAULT_RENAMES = {
    "windows": {
        "ssh-remoto-configuracao.md": "20_ssh_remoto_configuracao.md"
    },
    "linux": {
        "1-atualizar-pacotes.md": "01_atualizar_pacotes.md",
        "omarchy--pos-instalacao.md": "02_omarchy_pos_instalacao.md",
        "fedora--pos-instalacao.md": "03_fedora_pos_instalacao.md",
        "containers--distrobox-docker-v2.md": "04_containers_distrobox_docker.md",
        "virtualizacao--virt-manager.md": "05_virtualizacao_virt_manager.md",
        "virtualizacao--win11-kvm.md": "06_virtualizacao_win11_kvm.md",
        "nmcli--wifi-obsidian.md": "07_wifi_varredura_canais_nmcli.md",
        "ffmpeg.md": "08_ffmpeg_nvenc_transcodificacao.md",
        "ollama-gpu-igpu-radeon.md": "09_ollama_igpu_radeon_rocm.md",
        "homebrew.md": "10_homebrew_gerenciador_pacotes.md",
        "git.md": "11_git_instalacao_configuracao.md"
    },
    "redes": {
        "02_alterando_usuário_senha.md": "02_alterando_usuario_senha.md",
        "07_bloqueio_sites_serviços.md": "07_bloqueio_sites_servicos.md",
        "08_priorizar_sites_e_serviços.md": "08_priorizar_sites_e_servicos.md",
        "script_sxt_2016.md": "13_script_sxt_2016.md",
        "automatic_reboot.md": "14_automatic_reboot.md",
        "01_básico_para_proteger_seu_mikrotik.md": "01_basico_para_proteger_seu_mikrotik.md",
        "01_exemplo_sumarização_ospf.md": "01_exemplo_sumarizacao_ospf.md"
    }
}

def get_vault_path(vault_input: str) -> Path:
    p = Path(vault_input)
    if p.is_dir():
        return p.resolve()
    
    candidate = Path(OBSIDIAN_BASE) / vault_input
    if candidate.is_dir():
        return candidate.resolve()
    
    raise ValueError(f"Vault não encontrado: {vault_input} (nem como caminho absoluto nem em {OBSIDIAN_BASE})")

def normalize_filename(vault_name: str, old_name: str) -> str:
    """Padroniza arquivos com prefixo de 1 dígito ou mapa de taxonomia do vault."""
    # 1. Mapa explícito por vault
    if vault_name in VAULT_RENAMES and old_name in VAULT_RENAMES[vault_name]:
        return VAULT_RENAMES[vault_name][old_name]
    
    # 2. Padrão 1_foo.md ou 1-foo.md -> 01_foo.md
    m = re.match(r"^([0-9])[-_]([a-zA-Z0-9_\-]+)\.md$", old_name)
    if m:
        digit, rest = m.groups()
        return f"0{digit}_{rest}.md"
        
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

def deduce_tags_from_path(rel_path: str, vault_name: str) -> list:
    """Deduz tags padrão com base no caminho relativo e repositório."""
    tags = ["publico", vault_name]
    parts = rel_path.lower().split("/")
    
    for p in parts[:-1]:
        clean_p = re.sub(r"^[0-9]+_", "", p)
        if clean_p and clean_p != vault_name and clean_p not in tags:
            tags.append(clean_p)
            
    if "mikrotik" in rel_path.lower():
        if "mikrotik" not in tags:
            tags.append("mikrotik")
        if "routeros" not in tags:
            tags.append("routeros")
            
    return tags

def update_frontmatter(fm_text: str, default_title: str, rel_path: str, vault_name: str, privacy: str = "public") -> str:
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
    title = data.get("title", default_title).strip('"')
    date_created = data.get("date_created", data.get("date", "2024-02-25"))
    author = data.get("author", DEFAULT_AUTHOR)
    
    # Se não tinha tags no documento, deduz da pasta
    if not tags:
        tags = deduce_tags_from_path(rel_path, vault_name)

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

def run_git_mv(repo_dir: Path, src_rel: str, dst_rel: str, dry_run: bool = False):
    """Executa git mv mantendo histórico."""
    if dry_run:
        print(f"   [DRY-RUN] git mv {src_rel} -> {dst_rel}")
        return
    
    cmd = ["git", "mv", src_rel, dst_rel]
    res = subprocess.run(cmd, cwd=repo_dir, capture_output=True, text=True)
    if res.returncode != 0:
        # Se git mv falhar, usa rename do sistema de arquivos
        src_path = repo_dir / src_rel
        dst_path = repo_dir / dst_rel
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        src_path.rename(dst_path)

def main():
    parser = argparse.ArgumentParser(description="Padronizador de Notas de Vaults do Obsidian")
    parser.add_argument("--vault", required=True, help="Nome do vault ou caminho absoluto (ex: windows, linux, redes)")
    parser.add_argument("--privacy", default="public", choices=["public", "private"], help="Nível de privacidade (default: public)")
    parser.add_argument("--dry-run", action="store_true", help="Simula as ações sem alterar arquivos")
    args = parser.parse_args()

    vault_path = get_vault_path(args.vault)
    is_git = (vault_path / ".git").is_dir()

    print(f"✨ Iniciando padronização no vault: {vault_path.name} ({vault_path})")
    print(f"🔒 Privacidade alvo: {args.privacy} | Git detectado: {is_git}")
    if args.dry_run:
        print("🔍 MODO SIMULAÇÃO (DRY-RUN) ATIVO")

    # Coleta recursiva de arquivos .md ignorando diretórios ocultos (ex: .git)
    md_files = sorted([
        f for f in vault_path.rglob("*.md")
        if not any(part.startswith(".") for part in f.parts)
    ])
    
    if not md_files:
        print("❌ Nenhum arquivo Markdown (.md) encontrado no vault.")
        return

    # Passo 1: Mapear renomeações necessárias (preservando estrutura de pastas)
    renames = {}
    for f in md_files:
        filename = f.name
        new_filename = normalize_filename(vault_path.name, filename)
        if new_filename != filename:
            rel_src = str(f.relative_to(vault_path))
            rel_dst = str(f.parent.relative_to(vault_path) / new_filename) if f.parent != vault_path else new_filename
            renames[rel_src] = rel_dst

    print(f"\n📁 Verificando nomes de arquivos... ({len(renames)} a renomear)")
    for old_rel, new_rel in renames.items():
        print(f"   🔄 Renomeando: {old_rel} ➔ {new_rel}")
        run_git_mv(vault_path, old_rel, new_rel, args.dry_run)

    # Passo 2: Atualizar lista de arquivos após renomeação
    current_files = sorted([
        f for f in vault_path.rglob("*.md")
        if not any(part.startswith(".") for part in f.parts)
    ])

    # Mapa de substituição de links
    link_replacements = {}
    for old_rel, new_rel in renames.items():
        old_base = Path(old_rel).name
        new_base = Path(new_rel).name
        link_replacements[old_rel] = new_rel
        link_replacements[f"./{old_rel}"] = f"./{new_rel}"
        link_replacements[old_base] = new_base
        link_replacements[f"./{old_base}"] = f"./{new_base}"

    print(f"\n📝 Normalizando Frontmatter YAML e Links Internos em {len(current_files)} notas...")
    for f in current_files:
        rel_path = str(f.relative_to(vault_path))
        with open(f, "r", encoding="utf-8") as fp:
            content = fp.read()

        fm_text, body = parse_frontmatter(content)
        
        # Obter título default
        title_match = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
        default_title = title_match.group(1).strip() if title_match else f.stem
        # Limpar numeração inicial do título no frontmatter se houver (ex: '# 1 - IP...' -> 'IP...')
        clean_title = re.sub(r"^[0-9]+\s*[-–]\s*", "", default_title)

        new_fm = update_frontmatter(fm_text, clean_title, rel_path, vault_path.name, privacy=args.privacy)

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
        print(f"   ✅ Processado: {rel_path}")

    print("\n🎉 Padronização de notas e frontmatters concluída com sucesso!")

if __name__ == "__main__":
    main()
