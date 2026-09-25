# ⚙️ Scripts & Automações de Infraestrutura (Toolbox Multiplataforma)

> **Engenharia de Automação, DevOps & Administração de Redes**  
> **Autor:** Bruno César Medeiros Siqueira ([@brncesarms](https://github.com/brncesarms))  
> **Tecnologias:** Bash (Linux/Shell), Python (APIs, RAG & IA), PowerShell (Windows & Active Directory)

---

## 🏛️ 1. Filosofia & Padrão de Engenharia
Este repositório reúne ferramentas determinísticas e scripts utilitários desenvolvidos para operação contínua, governança de bancada e automação de sistemas operacionais.

* **Zero Gambiarras:** Scripts modulares, com tratamento de erros, checagem de privilégios e logs claros.
* **Idempotência:** Scripts projetados para serem executados múltiplas vezes sem quebrar o ambiente.
* **Auto-Elevação:** Scripts Python contam com rotina de auto-elevação para ambientes virtuais (`.venv`) isolados.

---

## 📂 2. Estrutura Canônica

```text
~/scripts/
├── bash/               # Automações Linux, redes, backups, monitoramento e SSH
│   └── synclab.sh      # Utilitário determinístico de sincronização da Tríade Omarchy
├── python/             # Utilitários de dados, RAG semântico, consumo de APIs e IA
│   ├── curador_obsidian.py   # Auditoria, sanitização e links da base Obsidian
│   └── padronizador_vault.py # Formatação de frontmatter e privacidade de notas
└── powershell/         # Scripts atômicos para Windows 11, automação e redes
    ├── system/         # OpenSSH, reparos de integridade (DISM/SFC), tweaks, GPO e contas
    ├── network/        # Renovação de TCP/IP, flush DNS/ARP e reset de adaptadores
    ├── apps/           # Utilitários Winget, perfis corporativos (Modo PMA / Modo Dev)
    └── runtimes/       # Provisionamento de .NET 8/9, VC++ All-in-One e Java Temurin
```

---

## 🛠️ 3. Integração com o Terminal ($PATH)
Para invocar qualquer script de qualquer lugar do terminal:
```bash
export PATH="$HOME/scripts/bash:$HOME/scripts/python:$HOME/scripts/powershell:$PATH"
```

