# ============================================================
# configure-winrm.ps1 — Configura WinRM para WindowsMaster
# ============================================================
# Executar como Administrador dentro do Windows 10
# Habilita WinRM HTTP na porta 5985 para controle remoto
# ============================================================

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  WindowsMaster — Configuração WinRM" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ─── Verificar se é Administrador ───
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Este script precisa ser executado como Administrador!" -ForegroundColor Red
    exit 1
}

# ─── Configurar WinRM ───
Write-Host "🔧 Configurando WinRM..." -ForegroundColor Yellow

# Habilita WinRM QuickConfig (sem prompt)
winrm quickconfig -quiet

# Define listeners HTTP
winrm create winrm/config/Listener?Address=*+Transport=HTTP

# Permite conexões não criptografadas (rede interna)
winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# Permite autenticação básica
winrm set winrm/config/service/auth '@{Basic="true"}'

# Aumenta o timeout e o tamanho do envelope
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'

# ─── Configurar Firewall ───
Write-Host "🔥 Configurando Firewall..." -ForegroundColor Yellow

# Habilita regra do Windows Remote Management (HTTP-In)
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes

# Cria regra explícita para porta 5985 (caso não exista)
netsh advfirewall firewall add rule name="WinRM-HTTP-5985" dir=in action=allow protocol=TCP localport=5985

# ─── Configurar Serviços ───
Write-Host "⚙️  Configurando Serviços..." -ForegroundColor Yellow

# WinRM service
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

# Windows Remote Management (WS-Management)
Set-Service -Name "WinRM" -StartupType Automatic

# ─── Verificar Status ───
Write-Host ""
Write-Host "📊 Status do WinRM:" -ForegroundColor Green
winrm enumerate winrm/config/listener

Write-Host ""
Write-Host "🔍 Testando conectividade:" -ForegroundColor Green
Test-NetConnection -ComputerName localhost -Port 5985

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  ✅ WinRM configurado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "  📡 Porta: 5985 (HTTP)" -ForegroundColor White
Write-Host "  🔐 Autenticação: Basic" -ForegroundColor White
Write-Host "  🌐 Criptografia: Desabilitada (rede interna)" -ForegroundColor White
Write-Host ""
Write-Host "  🧪 Teste de conexão:" -ForegroundColor White
Write-Host "     winrs -r:http://<IP-VM>:5985 -u:Administrador -p:Admin123! hostname" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
