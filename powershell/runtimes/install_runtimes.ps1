<#
.SYNOPSIS
    Instala o pacote essencial de runtimes e bibliotecas de execução para Windows.

.DESCRIPTION
    Script atômico para provisionamento de dependências de software:
    - Microsoft .NET 8 Desktop Runtime (LTS)
    - Microsoft .NET 9 Desktop Runtime
    - Microsoft Visual C++ 2015-2022 Redistributable (x64)
    - Microsoft Visual C++ 2015-2022 Redistributable (x86)
    - Eclipse Temurin OpenJDK 17 JRE (LTS)

.PARAMETER IncludeAllInOneVC
    Inclui o pacote consolidado abbodi1406 contendo todos os redistribuíveis de 2005 até o presente.

.EXAMPLE
    .\install_runtimes.ps1

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$IncludeAllInOneVC
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wingetHelper = Join-Path (Split-Path -Parent $scriptDir) "apps\install_winget_app.ps1"

function Invoke-AppInstall {
    param ($Id, $Name)
    if (Test-Path $wingetHelper) {
        & $wingetHelper -AppId $Id -Name $Name
    } else {
        Write-Host "[*] Instalando $Name ($Id)..." -ForegroundColor Gray
        winget.exe install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " [*] INSTALAÇÃO DE PACOTES DE RUNTIME & AMBIENTES BASE" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

Invoke-AppInstall "Microsoft.DotNet.DesktopRuntime.8" ".NET 8 Desktop Runtime (LTS)"
Invoke-AppInstall "Microsoft.DotNet.DesktopRuntime.9" ".NET 9 Desktop Runtime"
Invoke-AppInstall "Microsoft.VCRedist.2015+.x64" "Visual C++ 2015-2022 (x64)"
Invoke-AppInstall "Microsoft.VCRedist.2015+.x86" "Visual C++ 2015-2022 (x86)"
Invoke-AppInstall "EclipseAdoptium.Temurin.17.JRE" "Java Temurin 17 JRE (LTS)"

if ($IncludeAllInOneVC) {
    Invoke-AppInstall "abbodi1406.vcredist" "Visual C++ All-in-One (abbodi1406)"
}

Write-Host "`n[✓] Todos os runtimes essenciais foram provisionados!" -ForegroundColor Green
