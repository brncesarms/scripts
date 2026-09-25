<#
.SYNOPSIS
    Ativa a conta nativa de Administrador local do Windows (SID terminada em -500).

.DESCRIPTION
    Script atômico determinístico para ativar a conta de Administrador nativo independente
    do idioma do sistema operacional (ex: "Administrator", "Administrador"), localizando
    a conta de forma precisa através do Security Identifier (SID *-500).

.EXAMPLE
    .\enable_builtin_admin.ps1

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

#Requires -RunAsAdministrator

Write-Host "`n[*] Habilitando conta de Administrador nativa (Detecção por SID 500)..." -ForegroundColor Cyan

try {
    $admin = Get-LocalUser | Where-Object { $_.SID -like "*-500" }
    if ($admin) {
        Enable-LocalUser -SID $admin.SID
        Write-Host "[✓] Conta de Administrador ($($admin.Name)) ativada com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "[!] Conta com SID final 500 não foi localizada neste host." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERRO] Falha ao habilitar conta de administrador: $_" -ForegroundColor Red
    exit 1
}
