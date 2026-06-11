# ============================================================
# enable-remote-desktop.ps1 — Habilita RDP no Windows 10
# ============================================================
# Executar como Administrador
# Habilita Remote Desktop + Firewall rules
# ============================================================

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  WindowsMaster — Habilitando Remote Desktop" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Execute como Administrador!" -ForegroundColor Red
    exit 1
}

# ─── Habilitar RDP ───
Write-Host "🖥️  Habilitando Remote Desktop..." -ForegroundColor Yellow

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0

# ─── Firewall ───
Write-Host "🔥 Abrindo portas RDP no Firewall..." -ForegroundColor Yellow

Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# ─── Verificar ───
$rdpStatus = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections"
if ($rdpStatus.fDenyTSConnections -eq 0) {
    Write-Host ""
    Write-Host "✅ Remote Desktop HABILITADO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  📡 Porta: 3389 (RDP)" -ForegroundColor White
    Write-Host "  👤 Usuário: Administrador" -ForegroundColor White
    Write-Host "  🔑 Senha: Admin123!" -ForegroundColor White
    Write-Host ""
    Write-Host "  🧪 Conecte via:" -ForegroundColor White
    Write-Host "     rdesktop <IP-VM>:3389" -ForegroundColor Gray
    Write-Host "     ou mstsc.exe no Windows" -ForegroundColor Gray
} else {
    Write-Host "❌ Falha ao habilitar RDP" -ForegroundColor Red
}

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
