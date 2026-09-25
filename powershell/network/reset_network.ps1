<#
.SYNOPSIS
    Renova a pilha de rede TCP/IP, limpa caches DNS/ARP e reinicia adaptadores ativos.

.DESCRIPTION
    Script atômico para resolução de problemas de conectividade no Windows:
    - Limpa o cache do cliente DNS local via PowerShell e ipconfig.
    - Libera e renova concessões de endereçamento DHCP.
    - Limpa a tabela de resolução de endereços ARP.
    - Reinicia todos os adaptadores de rede físicos/virtuais com status 'Up'.

.EXAMPLE
    .\reset_network.ps1

.NOTES
    Autor: Bruno César
    Repositório: https://github.com/brncesarms/scripts
    Padrão de Mercado 2026 - Zero Gambiarras
#>

#Requires -RunAsAdministrator

Write-Host "`n[*] Executando renovação completa da pilha de rede e adaptadores..." -ForegroundColor Cyan

# 1. Limpeza de DNS
Clear-DnsClientCache
ipconfig.exe /flushdns | Out-Null
Write-Host "[+] Cache DNS limpo com sucesso." -ForegroundColor Gray

# 2. Renovação DHCP
ipconfig.exe /release | Out-Null
ipconfig.exe /renew | Out-Null
Write-Host "[+] Endereço IP liberado e renovado via DHCP." -ForegroundColor Gray

# 3. Limpeza de ARP
arp.exe -d * 2>$null
Write-Host "[+] Tabela ARP redefinida." -ForegroundColor Gray

# 4. Reinício de adaptadores ativos
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $adapters) {
    Write-Host "[+] Reiniciando adaptador: $($adapter.Name)..." -ForegroundColor Gray
    Restart-NetAdapter -Name $adapter.Name -Confirm:$false
}

Write-Host "`n[✓] Pilha de rede renovada com sucesso!" -ForegroundColor Green
