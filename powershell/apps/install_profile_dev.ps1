<#
.SYNOPSIS
    Provisiona o perfil completo 'Modo BRNCZZR' (Dev & Workstation Avançada).

.DESCRIPTION
    Script orquestrador que automatiza o setup completo de uma estação de desenvolvimento:
    - Ferramentas de Engenharia: Git SCM, Visual Studio Code, Notepad++, Java Temurin 17 JDK.
    - Aplicativos base: 7-Zip, Firefox, Chrome, LibreOffice, RustDesk, VLC.
    - Runtimes essenciais (.NET 8 LTS, VC++ 2015-2022 x64/x86).
    - Ativação de conta nativa de Administrador (SID 500).
    - Aplicação dos Tweaks de usabilidade do Windows 11.

.EXAMPLE
    .\install_profile_dev.ps1

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

#Requires -RunAsAdministrator

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

$wingetHelper = Join-Path $scriptDir "install_winget_app.ps1"
$runtimesHelper = Join-Path $rootDir "runtimes\install_runtimes.ps1"
$adminHelper = Join-Path $rootDir "system\enable_builtin_admin.ps1"
$tweaksHelper = Join-Path $rootDir "system\win11_tweaks.ps1"

function Invoke-AtomicApp {
    param ($Id, $Name)
    if (Test-Path $wingetHelper) {
        & $wingetHelper -AppId $Id -Name $Name
    } else {
        winget.exe install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   EXECUTANDO PERFIL: MODO BRNCZZR (DEV & WORKSTATION)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

Write-Host "`n[1/4] Instalando Ferramentas de Desenvolvimento e Utilitários..." -ForegroundColor Yellow
Invoke-AtomicApp "Git.Git" "Git SCM"
Invoke-AtomicApp "Microsoft.VisualStudioCode" "Visual Studio Code"
Invoke-AtomicApp "Notepad++.Notepad++" "Notepad++"
Invoke-AtomicApp "EclipseAdoptium.Temurin.17.JDK" "Java Temurin 17 JDK (LTS)"
Invoke-AtomicApp "7zip.7zip" "7-Zip"
Invoke-AtomicApp "Google.Chrome" "Google Chrome"
Invoke-AtomicApp "Mozilla.Firefox" "Mozilla Firefox"
Invoke-AtomicApp "TheDocumentFoundation.LibreOffice" "LibreOffice"
Invoke-AtomicApp "RustDesk.RustDesk" "RustDesk"
Invoke-AtomicApp "VideoLAN.VLC" "VLC Media Player"

Write-Host "`n[2/4] Provisionando Runtimes Essenciais..." -ForegroundColor Yellow
if (Test-Path $runtimesHelper) {
    & $runtimesHelper
}

Write-Host "`n[3/4] Ativando Administrador Nativo (SID 500)..." -ForegroundColor Yellow
if (Test-Path $adminHelper) {
    & $adminHelper
}

Write-Host "`n[4/4] Aplicando Otimizações e Tweaks de Usabilidade..." -ForegroundColor Yellow
if (Test-Path $tweaksHelper) {
    & $tweaksHelper
}

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " [✓] PERFIL MODO BRNCZZR CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "========================================================`n" -ForegroundColor Green
