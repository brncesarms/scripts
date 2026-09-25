<#
.SYNOPSIS
    Força a sincronização imediata das Diretivas de Grupo (GPO).

.DESCRIPTION
    Script atômico para execução de gpupdate /force com exibição de status e tratamento de saída.

.EXAMPLE
    .\update_gpo.ps1

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

Write-Host "`n[*] Forçando atualização de diretivas de grupo (gpupdate /force)..." -ForegroundColor Cyan
gpupdate.exe /force

if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Diretivas de Grupo atualizadas com sucesso!" -ForegroundColor Green
} else {
    Write-Host "[!] gpupdate finalizado com código de aviso ou erro: $LASTEXITCODE" -ForegroundColor Yellow
}
