<#
.SYNOPSIS
    Atualiza todos os aplicativos instalados na estação de trabalho via Winget.

.DESCRIPTION
    Script atômico para manter o ecossistema de software de terceiros atualizado,
    executando winget upgrade --all com parâmetros determinísticos não-interativos.

.EXAMPLE
    .\update_all_apps.ps1

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

Write-Host "`n[*] Verificando e atualizando todos os pacotes instalados via Winget..." -ForegroundColor Cyan

if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] O comando 'winget' não foi localizado no sistema." -ForegroundColor Red
    exit 1
}

winget.exe upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[✓] Todos os pacotes suportados foram atualizados!" -ForegroundColor Green
} else {
    Write-Host "`n[*] Processo de atualização finalizado com código: $LASTEXITCODE" -ForegroundColor Yellow
}
