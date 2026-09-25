<#
.SYNOPSIS
    Instala, configura e ativa o servidor nativo OpenSSH no Windows 11 / Windows Server.

.DESCRIPTION
    Script atômico e determinístico para provisionamento do OpenSSH Server (sshd).
    Configura serviço automático, libera regras de Firewall na porta 22 TCP,
    injeta chaves públicas em authorized_keys com permissões NTFS estritas (icacls)
    e exibe instruções imediatas de conexão remota.

.PARAMETER PublicKey
    Chave pública SSH (ex: ssh-ed25519 AAAAC3...) para autorizar automaticamente.
    Se omitido em modo interativo, solicita ao operador com valor padrão do laboratório.

.PARAMETER SkipKeyConfig
    Pula a injeção de chaves SSH públicas (mantendo apenas autenticação por credencial local).

.PARAMETER Silent
    Executa sem solicitar inputs interativos (ideal para automações e headless).

.EXAMPLE
    .\enable_openssh.ps1

.EXAMPLE
    .\enable_openssh.ps1 -PublicKey "ssh-ed25519 AAAAC3... email@domain.com" -Silent

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$PublicKey = "",

    [Parameter(Mandatory = $false)]
    [switch]$SkipKeyConfig,

    [Parameter(Mandatory = $false)]
    [switch]$Silent
)

$chavePadraoLab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILiS0LKTWLy0WVbY7O515TKpR9yxxDrJjXH0c3zcWELZ brcesarms@gmail.com"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " [*] HABILITANDO SERVIDOR OPENSSH NATIVO NO WINDOWS" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Instalação da funcionalidade OpenSSH.Server
Write-Host "`n[1/4] Verificando capacidade nativa OpenSSH.Server..." -ForegroundColor Gray
try {
    $sshCap = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'OpenSSH.Server*' }
    if ($null -eq $sshCap -or $sshCap.State -ne 'Installed') {
        Write-Host "[+] Instalando OpenSSH.Server via Windows Capability..." -ForegroundColor Yellow
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
        Write-Host "[✓] Recurso OpenSSH Server instalado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "[✓] Recurso OpenSSH Server já está instalado." -ForegroundColor Green
    }
} catch {
    Write-Host "[ERRO] Falha ao verificar/instalar OpenSSH Capability: $_" -ForegroundColor Red
    exit 1
}

# 2. Configuração e Inicialização dos Serviços
Write-Host "`n[2/4] Configurando serviços sshd e ssh-agent para inicialização automática..." -ForegroundColor Gray
try {
    Set-Service -Name sshd -StartupType 'Automatic'
    Start-Service sshd -ErrorAction SilentlyContinue

    Set-Service -Name ssh-agent -StartupType 'Automatic'
    Start-Service ssh-agent -ErrorAction SilentlyContinue
    Write-Host "[✓] Serviços sshd e ssh-agent ativos e configurados como Automático!" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Falha ao iniciar serviços do OpenSSH: $_" -ForegroundColor Red
    exit 1
}

# 3. Liberação de Firewall (Porta 22 TCP)
Write-Host "`n[3/4] Configurando regra de Firewall (Porta 22 TCP)..." -ForegroundColor Gray
$regraExiste = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $regraExiste) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any | Out-Null
}
$validaRegra = netsh advfirewall firewall show rule name="OpenSSH-Server-In-TCP" 2>$null
if ($validaRegra -notmatch "OpenSSH-Server-In-TCP") {
    netsh advfirewall firewall add rule name="OpenSSH-Server-In-TCP" dir=in action=allow protocol=TCP localport=22 | Out-Null
}
Write-Host "[✓] Porta 22 TCP liberada no Firewall para todos os perfis de rede!" -ForegroundColor Green

# 4. Configuração de Chaves Públicas Autorizadas
Write-Host "`n[4/4] Configuração de Chaves Públicas Autorizadas (authorized_keys)..." -ForegroundColor Gray
if (-not $SkipKeyConfig) {
    if ([string]::IsNullOrWhiteSpace($PublicKey)) {
        if ($Silent) {
            $PublicKey = $chavePadraoLab
        } else {
            Write-Host "Cole a chave pública SSH autorizada." -ForegroundColor Gray
            Write-Host "Pressione [ENTER] para usar a chave padrão da Tríade:" -ForegroundColor Gray
            Write-Host "  $chavePadraoLab" -ForegroundColor DarkGray
            $inputKey = Read-Host "Chave SSH [Padrão: Tríade Omarchy]"
            if ([string]::IsNullOrWhiteSpace($inputKey)) {
                $PublicKey = $chavePadraoLab
            } else {
                $PublicKey = $inputKey.Trim()
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($PublicKey)) {
        # Diretório .ssh do usuário atual
        $userSshDir = Join-Path $HOME ".ssh"
        if (-not (Test-Path $userSshDir)) {
            New-Item -ItemType Directory -Path $userSshDir -Force | Out-Null
        }
        $userAuthKeys = Join-Path $userSshDir "authorized_keys"
        $conteudoExistente = if (Test-Path $userAuthKeys) { Get-Content -Path $userAuthKeys -Raw } else { "" }
        if ($conteudoExistente -notmatch [regex]::Escape($PublicKey)) {
            Add-Content -Path $userAuthKeys -Value $PublicKey -Force
        }
        # Permissões NTFS estritas: apenas o próprio usuário e SYSTEM (sem herança)
        icacls $userAuthKeys /inheritance:r /grant "$($env:USERNAME):(F)" /grant "SYSTEM:(F)" | Out-Null
        Write-Host "[✓] Chave autorizada em: $userAuthKeys" -ForegroundColor Green

        # Diretório ProgramData/ssh para administradores locais
        $sshProgramData = Join-Path $env:ProgramData "ssh"
        if (-not (Test-Path $sshProgramData)) {
            New-Item -ItemType Directory -Path $sshProgramData -Force | Out-Null
        }
        $adminAuthKeys = Join-Path $sshProgramData "administrators_authorized_keys"
        $adminConteudo = if (Test-Path $adminAuthKeys) { Get-Content -Path $adminAuthKeys -Raw } else { "" }
        if ($adminConteudo -notmatch [regex]::Escape($PublicKey)) {
            Add-Content -Path $adminAuthKeys -Value $PublicKey -Force
        }
        # Permissões NTFS estritas: apenas Administrators e SYSTEM
        icacls $adminAuthKeys /inheritance:r /grant "Administrators:(F)" /grant "SYSTEM:(F)" | Out-Null
        Write-Host "[✓] Chave autorizada em: $adminAuthKeys" -ForegroundColor Green

        Restart-Service sshd -ErrorAction SilentlyContinue
        Write-Host "[✓] Serviço sshd reiniciado com chaves atualizadas!" -ForegroundColor Green
    }
} else {
    Write-Host "[*] Injeção de chaves SSH pulada por parâmetro." -ForegroundColor Yellow
}

# Detecção de IP local para instruções
$ipLocal = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { 
    $_.IPAddress -ne "127.0.0.1" -and 
    $_.IPAddress -notlike "169.254*" -and 
    $_.InterfaceAlias -notlike "*Loopback*"
} | Select-Object -ExpandProperty IPAddress -First 1)

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " [✓] SERVIDOR OPENSSH CONFIGURADO COM SUCESSO!" -ForegroundColor Green
Write-Host "     Comando para conectar do Linux/Mac/Terminal:" -ForegroundColor White
Write-Host "     ssh $env:USERNAME@$ipLocal" -ForegroundColor Yellow
Write-Host "========================================================`n" -ForegroundColor Green
