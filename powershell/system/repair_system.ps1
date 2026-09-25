<#
.SYNOPSIS
    Executa diagnóstico e reparo de integridade do Windows via DISM e SFC.

.DESCRIPTION
    Script atômico seguindo o procedimento oficial da Microsoft:
    Passo 1: DISM /Online /Cleanup-Image /RestoreHealth (repara a imagem do componente).
    Passo 2: SFC /scannow (valida e repara arquivos de sistema protegidos corrompidos).

.EXAMPLE
    .\repair_system.ps1

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

#Requires -RunAsAdministrator

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " [*] REPARO DE INTEGRIDADE DO SISTEMA OPERACIONAL" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

Write-Host "`n[Passo 1/2] Executando DISM /Online /Cleanup-Image /RestoreHealth..." -ForegroundColor Yellow
$dismResult = DISM.exe /Online /Cleanup-Image /RestoreHealth
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] DISM retornou código de aviso ou erro: $LASTEXITCODE" -ForegroundColor Yellow
} else {
    Write-Host "[✓] Reparo de imagem do DISM concluído com sucesso." -ForegroundColor Green
}

Write-Host "`n[Passo 2/2] Executando SFC /scannow..." -ForegroundColor Yellow
$sfcResult = sfc.exe /scannow
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] SFC identificou problemas ou exigirá reinicialização. Exit code: $LASTEXITCODE" -ForegroundColor Yellow
} else {
    Write-Host "[✓] Verificação SFC concluída sem pendências." -ForegroundColor Green
}

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " [✓] ROTINA DE REPARO DE SISTEMA CONCLUÍDA!" -ForegroundColor Green
Write-Host "========================================================`n" -ForegroundColor Green
