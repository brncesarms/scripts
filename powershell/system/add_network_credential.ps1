<#
.SYNOPSIS
    Cadastra credenciais de rede no Windows Credential Manager de forma segura.

.DESCRIPTION
    Script atômico para persistir credenciais SMB/RPC/RDP no cofre do Windows via cmdkey.

.PARAMETER Target
    IP ou Hostname do servidor / recurso compartilhado.

.PARAMETER Username
    Nome do usuário de rede (ex: DOMINIO\usuario ou usuario).

.PARAMETER Password
    Senha de rede. Se omitida em modo interativo, solicita via prompt seguro.

.EXAMPLE
    .\add_network_credential.ps1 -Target "192.168.0.34" -Username "operador"

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Target = "",

    [Parameter(Mandatory = $false)]
    [string]$Username = "",

    [Parameter(Mandatory = $false)]
    [string]$Password = ""
)

Write-Host "`n[*] Mapeamento de Credencial de Rede (Windows Credential Manager)" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($Target)) {
    $Target = Read-Host "Digite o IP ou Hostname do Servidor [Padrão: 192.168.0.34]"
    if ([string]::IsNullOrWhiteSpace($Target)) { $Target = "192.168.0.34" }
}

if ([string]::IsNullOrWhiteSpace($Username)) {
    $Username = Read-Host "Digite o Usuário de Rede [Padrão: padrao]"
    if ([string]::IsNullOrWhiteSpace($Username)) { $Username = "padrao" }
}

if ([string]::IsNullOrWhiteSpace($Password)) {
    $passSec = Read-Host "Digite a Senha de Rede" -AsSecureString
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passSec))
}

if (-not [string]::IsNullOrWhiteSpace($Password)) {
    cmdkey.exe /add:$Target /user:$Username /pass:$Password | Out-Null
    Write-Host "[✓] Credencial para $Target salva com segurança no Windows!" -ForegroundColor Green
} else {
    Write-Host "[!] Senha não informada. Nenhuma credencial foi adicionada." -ForegroundColor Yellow
}
