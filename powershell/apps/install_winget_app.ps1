<#
.SYNOPSIS
    Instala um pacote de software via Windows Package Manager (Winget) de forma atômica e idempotente.

.DESCRIPTION
    Script utilitário com checagem de pré-requisitos:
    - Validação de existência do comando winget.
    - Checagem prévia se o pacote já está instalado.
    - Instalação silenciosa com aceitação automática de acordos e licenças.

.PARAMETER AppId
    Identificador exato do pacote no repositório Winget (ex: "7zip.7zip", "Google.Chrome").

.PARAMETER Name
    Nome amigável descritivo para exibição nos logs.

.PARAMETER Force
    Força a reinstalação mesmo que o pacote já conste como instalado.

.EXAMPLE
    .\install_winget_app.ps1 -AppId "7zip.7zip" -Name "7-Zip"

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppId,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$Name = "",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

if ([string]::IsNullOrWhiteSpace($Name)) { $Name = $AppId }

Write-Host "[*] Verificando pacote: $Name ($AppId)..." -NoNewline -ForegroundColor Gray

# Pré-flight: checagem do executável winget
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-Host " [FALHA]" -ForegroundColor Red
    Write-Host "[ERRO] O comando 'winget' (App Installer) não foi localizado no sistema." -ForegroundColor Red
    Write-Host "[*] Instale o pacote 'App Installer' através da Microsoft Store para prosseguir." -ForegroundColor Yellow
    exit 1
}

# Verificação se já está instalado (se não forçado)
if (-not $Force) {
    $checkInstalled = winget.exe list --id $AppId --exact 2>$null
    if ($LASTEXITCODE -eq 0 -and ($checkInstalled | Out-String) -match [regex]::Escape($AppId)) {
        Write-Host " [JÁ INSTALADO]" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host " [INSTALANDO]" -ForegroundColor Green
Write-Host "    > winget install --id $AppId --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity" -ForegroundColor DarkGray

winget.exe install --id $AppId --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity

if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] $Name instalado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "[!] Falha ou aviso ao instalar $Name (Código de Saída: $LASTEXITCODE)." -ForegroundColor Yellow
    exit $LASTEXITCODE
}
