# 🐧 Scripts Atômicos Bash (Linux Multi-Distro & Tríade Omarchy)

> **Módulo de Automação Linux, DevOps, Containers e Workstations**  
> **Autor:** Bruno César Medeiros Siqueira ([@brncesarms](https://github.com/brncesarms))  
> **Compatibilidade:** Arch Linux / Omarchy, Fedora / RHEL, Ubuntu / Debian  
> **Padrão de Engenharia:** Padrão de Mercado 2026 - Zero Gambiarras, Idempotência e Execução Headless.

---

## 🏛️ 1. Princípios Arquiteturais

Os scripts deste módulo seguem rigorosamente a política de **Scripts Atômicos (Single Responsibility Principle)**:
* **Multi-Distro Determinístico:** Detecção automática do gerenciador de pacotes (`pacman`, `dnf`, `apt`) e serviços de sistema (`sshd`, `ssh`).
* **Segurança e Privilégios:** Scripts com alteração de sistema validam a presença de privilégios de root (`sudo`).
* **Headless-First:** Podem ser executados diretamente no terminal, via túnel SSH, em lote, ou via one-liner web remoto (`curl -fsSL ... | bash`).
* **Desacoplamento de UI:** Servem como o motor (*backend*) consumido pela interface TUI [`linux-toolbox-tui`](https://github.com/brncesarms/linux-toolbox-tui).

---

## 📂 2. Catálogo de Scripts

### 🛠️ Sistema & Rede (`bash/system/`)
| Script | Descrição | Requer Sudo |
| :--- | :--- | :---: |
| `update_system.sh` | Atualização geral do sistema com auto-detecção da distro (`pacman -Syu`, `dnf upgrade`, `apt-get upgrade`). | Sim |
| `enable_openssh.sh` | Instala OpenSSH Server, ativa inicialização no boot, libera Firewall (UFW/firewalld) e injeta chaves autorizadas da Tríade. | Sim |
| `enable_mdns_avahi.sh` | Configura o Avahi Daemon para resolução de nomes em rede local (`<hostname>.local`). | Sim |
| `install_nerdfont.sh` | Baixa e instala a fonte JetBrainsMono Nerd Font em `/usr/local/share/fonts/NerdFonts` e atualiza o cache (`fc-cache`). | Sim |
| `setup_flatpak.sh` | Instala o Flatpak e configura o repositório oficial Flathub. | Sim |
| `install_gnome_tweaks.sh` | Instala GNOME Tweaks e codecs essenciais de mídia. | Sim |

### 🚀 Desenvolvimento & Containers (`bash/dev/`)
| Script | Descrição | Requer Sudo |
| :--- | :--- | :---: |
| `install_base_dev.sh` | Pacote essencial de compilação: `git`, `curl`, `wget`, `build-essential` / `base-devel`. | Sim |
| `install_docker.sh` | Instala Docker Engine + Docker Compose V2, ativa o serviço no systemd e adiciona o usuário real ao grupo `docker`. | Sim |
| `install_distrobox.sh` | Instala o Distrobox para contêineres integrados de ambiente. | Sim |
| `install_homebrew.sh` | Provisiona o Linuxbrew de forma não-interativa e injeta `eval` no `~/.bashrc`. | Sim |
| `install_vscode.sh` | Instala o Visual Studio Code via Flatpak (`com.visualstudio.code`). | Não |
| `install_obsidian.sh` | Instala o Obsidian via Flatpak (`md.obsidian.Obsidian`). | Não |
| `install_opencode.sh` | Instala o OpenCode CLI oficial. | Não / Sim |
| `install_antigravity.sh` | Instala o Google Antigravity CLI (`agy` / `antigravity`). | Não / Sim |
| `install_profile_dev.sh` | Orquestrador completo: instala toda a stack dev (Modo BRNCZZR) em sequência determinística. | Sim |

### 🌐 Aplicativos Gerais (`bash/apps/`)
| Script | Descrição | Requer Sudo |
| :--- | :--- | :---: |
| `install_brave.sh` | Instala o Brave Browser via instalador oficial da Brave Software. | Sim |
| `install_btop.sh` | Instala o monitor avançado de processos e hardware `btop`. | Sim |

### 🔄 Orquestração da Tríade (`bash/`)
| Script | Descrição | Requer Sudo |
| :--- | :--- | :---: |
| `synclab.sh` | Sincronizador determinístico com `--all` para conciliação Git paralela via SSH na Tríade (Acer, Alienware, Geekom). | Não |

---

## 🚀 3. Formas de Execução

### A. Execução Local via Terminal
```bash
# Provisionar servidor OpenSSH com chaves autorizadas:
sudo /home/brn/scripts/bash/system/enable_openssh.sh

# Instalar Docker Engine e configurar usuário:
sudo /home/brn/scripts/bash/dev/install_docker.sh

# Instalar a Workstation Dev completa (Modo BRNCZZR):
sudo /home/brn/scripts/bash/dev/install_profile_dev.sh
```

### B. Execução Remota Web (One-Liner Headless)
```bash
# Exemplo: Provisionamento rápido do OpenSSH Server diretamente do GitHub em qualquer máquina Linux nova:
curl -fsSL https://raw.githubusercontent.com/brncesarms/scripts/main/bash/system/enable_openssh.sh | sudo bash
```
