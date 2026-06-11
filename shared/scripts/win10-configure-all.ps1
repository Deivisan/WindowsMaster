# ============================================================
# win10-configure-all.ps1 — Configuração Completa do Windows 10
# ============================================================
# Executar como Administrador no Windows
# Instala: OpenSSH, WinRM, RDP, QEMU Guest Agent
# ============================================================

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  WindowsMaster — Configuração Completa" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Execute como Administrador!" -ForegroundColor Red
    exit 1
}

# ─── 1. OpenSSH Server ───
Write-Host "🔐 [1/5] Instalando OpenSSH Server..." -ForegroundColor Yellow
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType Automatic
Write-Host "   ✅ OpenSSH instalado e ativo" -ForegroundColor Green

# ─── 2. WinRM ───
Write-Host "🔧 [2/5] Configurando WinRM..." -ForegroundColor Yellow
winrm quickconfig -quiet 2>$null
winrm create winrm/config/Listener?Address=*+Transport=HTTP 2>$null
winrm set winrm/config/service '@{AllowUnencrypted="true"}' 2>$null
winrm set winrm/config/service/auth '@{Basic="true"}' 2>$null
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM
netsh advfirewall firewall add rule name="WinRM-HTTP-5985" dir=in action=allow protocol=TCP localport=5985 2>$null
Write-Host "   ✅ WinRM HTTP 5985 configurado" -ForegroundColor Green

# ─── 3. RDP ───
Write-Host "🖥️  [3/5] Habilitando Remote Desktop..." -ForegroundColor Yellow
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" 2>$null
Write-Host "   ✅ RDP porta 3389 habilitado" -ForegroundColor Green

# ─── 4. QEMU Guest Agent ───
Write-Host "🤖 [4/5] Configurando QEMU Guest Agent..." -ForegroundColor Yellow
# O agente é instalado via virtio-win.iso (disco E:)
# Aqui só garantimos que o serviço vai rodar
if (Test-Path "E:\guest-agent") {
    Write-Host "   📦 Guest Agent encontrado no E:\guest-agent" -ForegroundColor Cyan
    Write-Host "   ⚠️  Execute manualmente: E:\guest-agent\qemu-ga-x86_64.msi" -ForegroundColor Yellow
} else {
    Write-Host "   ⚠️  Monte virtio-win.iso e instale guest-agent" -ForegroundColor Yellow
}
Write-Host "   ✅ QEMU GA pronto para instalação" -ForegroundColor Green

# ─── 5. Firewall e Usuários ───
Write-Host "🔥 [5/5] Configurando Firewall e Usuários..." -ForegroundColor Yellow

# Criar usuário ufrb se não existir
if (-not (Get-LocalUser -Name "ufrb" -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name "ufrb" -NoPassword -AccountNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member "ufrb"
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member "ufrb"
    Add-LocalGroupMember -Group "Remote Management Users" -Member "ufrb"
    Write-Host "   ✅ Usuário 'ufrb' criado (sem senha)" -ForegroundColor Green
} else {
    Write-Host "   ✅ Usuário 'ufrb' já existe" -ForegroundColor Green
}

# Abrir portas no firewall
netsh advfirewall firewall add rule name="SSH-22" dir=in action=allow protocol=TCP localport=22 2>$null
netsh advfirewall firewall add rule name="RDP-3389" dir=in action=allow protocol=TCP localport=3389 2>$null
Write-Host "   ✅ Firewall configurado (22, 3389, 5985)" -ForegroundColor Green

# ─── Resumo ───
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ CONFIGURAÇÃO COMPLETA!" -ForegroundColor Green
Write-Host ""
Write-Host "  📡 Acessos disponíveis:" -ForegroundColor White
Write-Host "     SSH:     ssh ufrb@<IP-VM>" -ForegroundColor Gray
Write-Host "     WinRM:   winrs -r:http://<IP>:5985 -u:ufrb hostname" -ForegroundColor Gray
Write-Host "     RDP:     rdesktop <IP>:3389" -ForegroundColor Gray
Write-Host ""
Write-Host "  💡 IP da VM: execute 'ipconfig' no CMD" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
