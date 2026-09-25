<#
.SYNOPSIS
    Aplica otimizações, usabilidade e ajustes de performance no Windows 11.

.DESCRIPTION
    Script atômico para personalização de estações Windows 11 com foco em produtividade técnica:
    - Restauração do Menu de Contexto Clássico completo (sem "Mostrar mais opções").
    - Alinhamento da barra de tarefas à esquerda.
    - Ocultação de Widgets de notícias e botão Copilot.
    - Exibição obrigatória de extensões de arquivos conhecidas.
    - Exibição de arquivos e pastas ocultos.
    - Abertura padrão do Explorador de Arquivos em "Este Computador".
    - Desativação de hibernação (liberação imediata de GBs no SSD).
    - Ativação do Tema Escuro global (Apps e Sistema).

.PARAMETER NoRestartExplorer
    Evita reiniciar o processo do Windows Explorer automaticamente ao término.

.EXAMPLE
    .\win11_tweaks.ps1

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$NoRestartExplorer
)

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " [*] APLICANDO TWEAKS DE SISTEMA E PERFORMANCE NO WIN 11" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Menu de contexto clássico
Write-Host "[+] Ativando Menu de Contexto Clássico completo..." -ForegroundColor Gray
$regMenuClassico = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
if (-not (Test-Path $regMenuClassico)) {
    New-Item -Path $regMenuClassico -Force | Out-Null
    Set-ItemProperty -Path $regMenuClassico -Name "(Default)" -Value "" | Out-Null
}

# 2. Barra de tarefas à esquerda
Write-Host "[+] Alinhando Barra de Tarefas à Esquerda..." -ForegroundColor Gray
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type DWord -Force

# 3. Ocultar widgets e copilot
Write-Host "[+] Ocultando Widgets e botão Copilot da barra de tarefas..." -ForegroundColor Gray
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 4. Exibir extensões de arquivos
Write-Host "[+] Exibindo extensões de arquivos no Explorer..." -ForegroundColor Gray
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force

# 5. Exibir pastas e arquivos ocultos
Write-Host "[+] Exibindo pastas e arquivos ocultos..." -ForegroundColor Gray
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force

# 6. Definir 'Este Computador' como padrão no Explorer
Write-Host "[+] Definindo 'Este Computador' como padrão ao abrir o Explorer..." -ForegroundColor Gray
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord -Force

# 7. Desativar hibernação
Write-Host "[+] Desativando hibernação (liberação de espaço no SSD)..." -ForegroundColor Gray
try {
    powercfg.exe -h off
} catch {
    Write-Host "[!] Não foi possível alterar powercfg (necessário privilégio de Administrador)." -ForegroundColor Yellow
}

# 8. Tema escuro
Write-Host "[+] Ativando Tema Escuro..." -ForegroundColor Gray
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force

# 9. Reinício do Explorer
if (-not $NoRestartExplorer) {
    Write-Host "[+] Reiniciando Windows Explorer para aplicar alterações visualmente..." -ForegroundColor Gray
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

Write-Host "`n[✓] Otimizações do Windows 11 aplicadas com sucesso!" -ForegroundColor Green
