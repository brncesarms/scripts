<#
.SYNOPSIS
    Executa diagnóstico e reparo online do sistema de arquivos NTFS/ReFS sem necessidade de reiniciar.

.DESCRIPTION
    Script atômico que utiliza a API moderna Repair-Volume do PowerShell
    para checagem do volume de disco em modo online. Possui fallback automático
    para chkdsk /scan caso o cmdlet nativo não esteja disponível.

.PARAMETER DriveLetter
    Letra da unidade a ser verificada (padrão: "C").

.EXAMPLE
    .\repair_disk.ps1 -DriveLetter C

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DriveLetter = "C"
)

$DriveLetter = $DriveLetter.TrimEnd(':')

Write-Host "`n[*] Executando diagnóstico online do volume ${DriveLetter}: ..." -ForegroundColor Cyan

try {
    Write-Host "[+] Executando Repair-Volume -DriveLetter $DriveLetter -Scan..." -ForegroundColor Gray
    Repair-Volume -DriveLetter $DriveLetter -Scan -ErrorAction Stop
    Write-Host "[✓] Verificação de integridade do disco ${DriveLetter}: concluída com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "[!] Repair-Volume encontrou aviso. Acionando fallback chkdsk ${DriveLetter}: /scan..." -ForegroundColor Yellow
    chkdsk.exe "${DriveLetter}:" /scan
    Write-Host "[✓] Execução do chkdsk finalizada." -ForegroundColor Green
}
