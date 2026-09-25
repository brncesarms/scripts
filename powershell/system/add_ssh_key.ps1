<#
.SYNOPSIS
    Adiciona e configura chave pública SSH em authorized_keys com permissões NTFS estritas.

.DESCRIPTION
    Script atômico para injeção de chaves públicas SSH tanto no diretório do usuário local
    (~/.ssh/authorized_keys) quanto no diretório administrativo do Windows OpenSSH
    (%ProgramData%/ssh/administrators_authorized_keys).
    Configura permissões estritas com icacls (remoção de herança e concessão exclusiva ao usuário e SYSTEM).

.PARAMETER PublicKey
    String com a chave pública SSH completa (ex: ssh-ed25519 AAAAC3...).

.PARAMETER RestartService
    Reinicia o serviço sshd após a inclusão da chave.

.EXAMPLE
    .\add_ssh_key.ps1 -PublicKey "ssh-ed25519 AAAAC3... brcesarms@gmail.com" -RestartService

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$PublicKey = "",

    [Parameter(Mandatory = $false)]
    [switch]$RestartService
)

$chavePadraoLab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILiS0LKTWLy0WVbY7O515TKpR9yxxDrJjXH0c3zcWELZ brcesarms@gmail.com"

Write-Host "`n--------------------------------------------------------" -ForegroundColor Cyan
Write-Host " [*] CONFIGURAÇÃO DE CHAVE PÚBLICA SSH (AUTHORIZED_KEYS)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($PublicKey)) {
    Write-Host "Cole a chave pública SSH autorizada." -ForegroundColor Gray
    Write-Host "Pressione [ENTER] para usar a chave padrão da Tríade Omarchy:" -ForegroundColor Gray
    Write-Host "  $chavePadraoLab" -ForegroundColor DarkGray
    $inputKey = Read-Host "Chave SSH [Padrão: Tríade Omarchy]"
    if ([string]::IsNullOrWhiteSpace($inputKey)) {
        $PublicKey = $chavePadraoLab
    } else {
        $PublicKey = $inputKey.Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($PublicKey)) {
    Write-Host "[!] Nenhuma chave fornecida. Operação cancelada." -ForegroundColor Yellow
    exit 0
}

# 1. Configurar authorized_keys do usuário atual
$userSshDir = Join-Path $HOME ".ssh"
if (-not (Test-Path $userSshDir)) {
    New-Item -ItemType Directory -Path $userSshDir -Force | Out-Null
}
$userAuthKeys = Join-Path $userSshDir "authorized_keys"

$conteudoExistente = if (Test-Path $userAuthKeys) { Get-Content -Path $userAuthKeys -Raw } else { "" }
if ($conteudoExistente -notmatch [regex]::Escape($PublicKey)) {
    Add-Content -Path $userAuthKeys -Value $PublicKey -Force
}
icacls $userAuthKeys /inheritance:r /grant "$($env:USERNAME):(F)" /grant "SYSTEM:(F)" | Out-Null
Write-Host "[✓] Chave autorizada no perfil do usuário: $userAuthKeys" -ForegroundColor Green

# 2. Configurar administrators_authorized_keys (se permissões administrativas permitirem)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    $sshProgramData = Join-Path $env:ProgramData "ssh"
    if (-not (Test-Path $sshProgramData)) {
        New-Item -ItemType Directory -Path $sshProgramData -Force | Out-Null
    }
    $adminAuthKeys = Join-Path $sshProgramData "administrators_authorized_keys"
    $adminConteudo = if (Test-Path $adminAuthKeys) { Get-Content -Path $adminAuthKeys -Raw } else { "" }
    if ($adminConteudo -notmatch [regex]::Escape($PublicKey)) {
        Add-Content -Path $adminAuthKeys -Value $PublicKey -Force
    }
    icacls $adminAuthKeys /inheritance:r /grant "Administrators:(F)" /grant "SYSTEM:(F)" | Out-Null
    Write-Host "[✓] Chave autorizada no escopo administrativo: $adminAuthKeys" -ForegroundColor Green

    if ($RestartService) {
        Restart-Service sshd -ErrorAction SilentlyContinue
        Write-Host "[✓] Serviço sshd reiniciado com novas credenciais!" -ForegroundColor Green
    }
}
