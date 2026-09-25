#!/usr/bin/env python3
"""
curador_obsidian.py - Curador e Linter Semântico de Coerência do Obsidian
Audita e organiza notas Markdown nos repositórios temáticos corretos da vitrine.
Consome ZERO tokens de LLM (100% determinístico e local).
"""

import os
import sys
import re
import argparse
import subprocess
import shutil

OBSIDIAN_DIR = "/home/brn/obsidian"

# Regras de taxonomia por repositório
TAXONOMIA = {
    "canal-youtube": {
        "tags": ["canal-youtube", "roteiro", "youtube", "video", "reels"],
        "keywords": ["roteiro", "gravação", "locução", "canal", "estúdio", "youtube"]
    },
    "proxmox": {
        "tags": ["proxmox", "virtualizacao", "qemu", "lxc", "pve", "vm"],
        "keywords": ["proxmox", "pve", "qm create", "guest agent", "vioscsi", "virtio-win"]
    },
    "redes": {
        "tags": ["redes", "mikrotik", "routeros", "ubiquiti", "tcp-ip", "cidr", "bgp", "ospf"],
        "keywords": ["routeros", "mikrotik", "vlan", "subnet", "winbox", "handshake tcp", "roteador"]
    },
    "windows": {
        "tags": ["windows", "powershell", "winget", "debloat", "active-directory"],
        "keywords": ["winget", "powershell", "sfc /scannow", "powercfg", "chkdsk", "windows 11"]
    },
    "linux": {
        "tags": ["linux", "arch", "omarchy", "fedora", "distrobox", "docker", "bash"],
        "keywords": ["pacman", "systemd", "distrobox", "wayland", "hyprland", "kernel linux"]
    },
    "ia": {
        "tags": ["ia", "ai", "ollama", "llm", "rag", "benchmark", "fastembed", "hermes"],
        "keywords": ["modelo de linguagem", "ollama", "benchmark moe", "embedding", "nous research"]
    },
    "basic-dev": {
        "tags": ["basic-dev", "dart", "flutter", "programacao", "dev"],
        "keywords": ["flutter", "dart", "sdk flutter", "android studio", "pubspec"]
    },
    "vault-privado": {
        "tags": ["privado", "segredo", "credenciais", "planejamento"],
        "keywords": ["privacy: private", "confidencial", "interno"]
    }
}

def extrair_metadados(filepath):
    """Extrai frontmatter YAML e primeiras linhas de conteúdo."""
    tags = []
    privacy = "public"
    title = os.path.basename(filepath)
    content_sample = ""

    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        content_sample = content[:1500].lower()
        
        # Frontmatter regex
        match = re.search(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
        if match:
            fm = match.group(1).lower()
            if "privacy: private" in fm:
                privacy = "private"
            
            # Extrair tags do yaml
            for line in fm.split("\n"):
                if "tags:" in line:
                    continue
                if line.strip().startswith("- "):
                    tags.append(line.strip().lstrip("- ").strip())
                elif "tags:" in line and "[" in line:
                    t_list = line.split("[")[1].split("]")[0]
                    tags.extend([t.strip().strip("'\"") for t in t_list.split(",")])
    except Exception as e:
        pass

    return {
        "path": filepath,
        "filename": os.path.basename(filepath),
        "tags": tags,
        "privacy": privacy,
        "sample": content_sample
    }

def classificar_arquivo(meta):
    """Determina o repositório canônico ideal para o arquivo."""
    # Se for estritamente privado
    if meta["privacy"] == "private" or "privado" in meta["tags"]:
        return "vault-privado"

    pontuacoes = {}
    for repo, regras in TAXONOMIA.items():
        if repo == "vault-privado":
            continue
        score = 0
        # Pontuação por tags explícitas
        for t in meta["tags"]:
            if t in regras["tags"]:
                score += 5
        # Pontuação por palavras-chave no cabeçalho
        for kw in regras["keywords"]:
            if kw in meta["sample"]:
                score += 1
            if kw in meta["filename"].lower():
                score += 4
        pontuacoes[repo] = score

    melhor_repo = max(pontuacoes, key=pontuacoes.get)
    if pontuacoes[melhor_repo] > 0:
        return melhor_repo
    return None

def auditar_obsidian(fix=False):
    relatorio = []
    movimentacoes = []

    for root, dirs, files in os.walk(OBSIDIAN_DIR):
        # Ignora pastas ocultas (.git, .obsidian)
        if "/." in root or root.endswith("/."):
            continue

        rel_path = os.path.relpath(root, OBSIDIAN_DIR)
        current_repo = rel_path.split(os.sep)[0] if rel_path != "." else "."

        for file in files:
            if not file.endswith(".md"):
                continue

            full_path = os.path.join(root, file)
            meta = extrair_metadados(full_path)
            repo_ideal = classificar_arquivo(meta)

            if not repo_ideal:
                continue

            # Se estiver na raiz ou no repositório incorreto
            if current_repo != repo_ideal and not (current_repo == "vault-privado" and meta["privacy"] == "private"):
                movimentacoes.append({
                    "origem": full_path,
                    "arquivo": file,
                    "repo_atual": current_repo,
                    "repo_ideal": repo_ideal,
                    "destino": os.path.join(OBSIDIAN_DIR, repo_ideal, file)
                })

    if not movimentacoes:
        print("✅ [CURADORIA] Todos os arquivos Markdown do Obsidian estão rigorosamente alinhados aos seus repositórios!")
        return 0

    print(f"⚠️ [CURADORIA] Foram detectados {len(movimentacoes)} arquivos fora do seu repositório de domínio:\n")
    for m in movimentacoes:
        print(f" • 📄 '{m['arquivo']}'")
        print(f"   Local Atual: {m['repo_atual']}/ ➔ Ideal: {m['repo_ideal']}/")

    if fix:
        print("\n🔧 [AUTO-FIX] Aplicando correções determinísticas e sincronizando Git...")
        repos_afetados = set()
        for m in movimentacoes:
            dst_dir = os.path.dirname(m["destino"])
            os.makedirs(dst_dir, exist_ok=True)
            shutil.move(m["origem"], m["destino"])
            print(f"  ✓ Movido: {m['arquivo']} -> {m['repo_ideal']}/")
            if m["repo_atual"] != ".":
                repos_afetados.add(os.path.join(OBSIDIAN_DIR, m["repo_atual"]))
            repos_afetados.add(os.path.join(OBSIDIAN_DIR, m["repo_ideal"]))

        for r_dir in repos_afetados:
            if os.path.isdir(os.path.join(r_dir, ".git")):
                r_name = os.path.basename(r_dir)
                subprocess.run(["git", "add", "-A"], cwd=r_dir, stdout=subprocess.DEVNULL)
                subprocess.run(["git", "commit", "-m", "chore: organizacao automatica de notas pelo curador"], cwd=r_dir, stdout=subprocess.DEVNULL)
                push_cmd = subprocess.run(["git", "push", "origin", "main"], cwd=r_dir, capture_output=True, text=True)
                if push_cmd.returncode == 0:
                    print(f"  🚀 Git push efetuado com sucesso em '{r_name}'")
                else:
                    print(f"  ⚠️ Aviso ao dar push em '{r_name}': {push_cmd.stderr.strip()}")

        print("\n🎉 [SUCESSO] Curadoria concluída e repositórios sincronizados no GitHub!")
    else:
        print("\n💡 Para mover automaticamente e sincronizar no GitHub, execute:")
        print("   python3 ~/scripts/python/curador_obsidian.py --fix")

    return len(movimentacoes)

def main():
    parser = argparse.ArgumentParser(description="Curador Semântico do Obsidian")
    parser.add_argument("--check", action="store_true", help="Apenas audita sem mover arquivos")
    parser.add_argument("--fix", action="store_true", help="Move arquivos para o repositório correto e sincroniza Git")
    args = parser.parse_args()

    auditar_obsidian(fix=args.fix)

if __name__ == "__main__":
    main()
