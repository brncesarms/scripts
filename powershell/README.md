# ⚡ Scripts Atômicos PowerShell (Windows 11 & Infraestrutura)

> **Módulo de Automação Windows, Otimização de Sistema e Redes**  
> **Autor:** Bruno César Medeiros Siqueira ([@brncesarms](https://github.com/brncesarms))  
> **Padrão de Engenharia:** Padrão de Mercado 2026 - Zero Gambiarras, Idempotência e Suporte a Execução Headless.

---

## 🏛️ 1. Princípios Arquiteturais

Os scripts deste diretório seguem a política de **Scripts Atômicos (Single Responsibility Principle)**:
* **Autonomia:** Cada script resolve um único problema de infraestrutura e pode ser chamado isoladamente via terminal, automação remota ou pipeline.
* **Segurança e Privilégios:** Scripts administrativos declaram formalmente `#Requires -RunAsAdministrator`.
* **Idempotência:** Podem ser executados repetidamente sem quebrar configurações existentes.
* **Desacoplamento de Interface:** Servem tanto como back-end determinístico para interfaces TUI (como o [`win-toolbox-tui`](https://github.com/brncesarms/win-toolbox-tui)) quanto para execução direta via SSH ou linha de comando.

---

## 📂 2. Catálogo de Scripts

### 🛠️ Sistema (`powershell/system/`)
| Script | Descrição | Requer Admin |
| :--- | :--- | :---: |
| `enable_openssh.ps1` | Provisiona OpenSSH.Server, configura serviços automáticos, libera Firewall (TCP 22) e injeta chaves autorizadas com ACLs NTFS estritas (`icacls`). | Sim |
| `repair_system.ps1` | Executa a rotina oficial Microsoft de integridade do SO: `DISM RestoreHealth` + `SFC /scannow`. | Sim |
| `repair_disk.ps1` | Diagnóstico e reparo online do disco C: via `Repair-Volume -Scan` (com fallback para `chkdsk`). | Sim |
| `win11_tweaks.ps1` | Restaura menu clássico, alinha taskbar à esquerda, desativa Copilot/Widgets, exibe extensões/ocultos e ativa tema escuro. | Não / Opcional |
| `enable_builtin_admin.ps1` | Localiza e ativa a conta de Administrador nativo independente do idioma do SO (detecção por SID `*-500`). | Sim |
| `add_ssh_key.ps1` | Injeta chaves públicas em `~/.ssh/authorized_keys` e `administrators_authorized_keys` com permissões NTFS estritas. | Não / Sim |
| `set_computer_name.ps1` | Altera o hostname da estação de trabalho com suporte a reinicialização automatizada. | Sim |
| `update_gpo.ps1` | Força a sincronização imediata de Diretivas de Grupo (`gpupdate /force`). | Não |
| `add_network_credential.ps1`| Registra credenciais de rede SMB/RDP no Windows Credential Manager de forma segura. | Não |

### 🌐 Rede (`powershell/network/`)
| Script | Descrição | Requer Admin |
| :--- | :--- | :---: |
| `reset_network.ps1` | Limpa caches DNS/ARP, renova leases DHCP e reinicia adaptadores de rede ativos. | Sim |

### 📦 Aplicativos & Perfis (`powershell/apps/`)
| Script | Descrição | Requer Admin |
| :--- | :--- | :---: |
| `install_winget_app.ps1` | Instalador utilitário com pre-flight check de winget, verificação de pacotes pré-instalados e modo silencioso. | Não |
| `update_all_apps.ps1` | Atualiza em lote todos os softwares instalados via Winget. | Não |
| `install_profile_pma.ps1` | Orquestrador para setup completo corporativo: suíte de escritório, navegadores, PDF, utilitários, runtimes e tweaks. | Sim |
| `install_profile_dev.ps1` | Orquestrador para setup de estação de desenvolvimento: Git, VS Code, Notepad++, Java 17 JDK, navegadores e tweaks. | Sim |

### ☕ Runtimes (`powershell/runtimes/`)
| Script | Descrição | Requer Admin |
| :--- | :--- | :---: |
| `install_runtimes.ps1` | Instalação de dependências essenciais: .NET 8 (LTS), .NET 9, Visual C++ 2015-2022 (x64/x86) e Java Temurin 17 JRE. | Não |

---

## 🚀 3. Formas de Execução

### A. Execução Local via Terminal (PowerShell 7 ou 5.1)
```powershell
# Ativar OpenSSH com chave padrão da Tríade:
powershell -ExecutionPolicy Bypass -File .\powershell\system\enable_openssh.ps1

# Aplicar Tweaks de Usabilidade no Windows 11:
powershell -ExecutionPolicy Bypass -File .\powershell\system\win11_tweaks.ps1

# Rodar reparo completo do sistema:
powershell -ExecutionPolicy Bypass -File .\powershell\system\repair_system.ps1
```

### B. Execução Remota Web (One-Liner Headless)
```powershell
# Exemplo: Provisionamento rápido do OpenSSH Server diretamente do GitHub:
irm https://raw.githubusercontent.com/brncesarms/scripts/main/powershell/system/enable_openssh.ps1 | iex
```
