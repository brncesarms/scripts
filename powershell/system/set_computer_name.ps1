<#
.SYNOPSIS
    Renomeia o hostname local do computador com opção de reinicialização controlada.

.DESCRIPTION
    Script atômico para alteração do nome de host da estação de trabalho.

.PARAMETER NewName
    O novo nome NetBIOS/DNS para a estação.

.PARAMETER Restart
    Reinicia o computador imediatamente após aplicar o novo nome.

.EXAMPLE
    .\set_computer_name.ps1 -NewName "WS-DEV01"

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$NewName = "",

    [Parameter(Mandatory = $false)]
    [switch]$Restart
)

Write-Host "`n[*] Renomear Computador" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($NewName)) {
    $NewName = Read-Host "Digite o novo nome para esta estação de trabalho"
}

if (-not [string]::IsNullOrWhiteSpace($NewName)) {
    try {
        Rename-Computer -NewName $NewName -Force -ErrorAction Stop
        Write-Host "[✓] Computador renomeado para: $NewName" -ForegroundColor Green

        if ($Restart) {
            Write-Host "[*] Reiniciando computador imediatamente..." -ForegroundColor Yellow
            Restart-Computer
        } else {
            Write-Host "[!] Lembre-se de reiniciar a estação de trabalho para concluir a alteração." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERRO] Falha ao renomear o computador: $_" -ForegroundColor Red
        exit 1
    }
}
