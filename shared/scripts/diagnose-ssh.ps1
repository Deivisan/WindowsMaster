# ============================================================
# diagnose-ssh.ps1 — Diagnóstico Completo do OpenSSH no Windows
# ============================================================
# Execute como Administrador
# Cole a saída COMPLETA no Debug Console
# ============================================================

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DIAGNÓSTICO COMPLETO DO OpenSSH" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ─── 1. Status do Serviço ───
Write-Host "【1/8】 Status do Serviço SSH" -ForegroundColor Yellow
Get-Service sshd | Format-List Name,Status,StartType,DisplayName
Write-Host ""

# ─── 2. sshd_config Completo ───
Write-Host "【2/8】 Configuração sshd_config" -ForegroundColor Yellow
$sshdConfig = "C:\ProgramData\ssh\sshd_config"
if (Test-Path $sshdConfig) {
    Write-Host "Arquivo: $sshdConfig" -ForegroundColor Green
    Write-Host ""
    Get-Content $sshdConfig
} else {
    Write-Host "❌ Arquivo NÃO encontrado: $sshdConfig" -ForegroundColor Red
}
Write-Host ""

# ─── 3. Onde SSH está Escutando ───
Write-Host "【3/8】 Conexões Ativas (netstat)" -ForegroundColor Yellow
netstat -an | findstr LISTENING | findstr ":22 "
Write-Host ""
Write-Host "Todas as portas LISTENING:" -ForegroundColor Cyan
netstat -an | findstr LISTENING
Write-Host ""

# ─── 4. Regras de Firewall ───
Write-Host "【4/8】 Regras de Firewall (SSH)" -ForegroundColor Yellow
Get-NetFirewallRule -DisplayName "*SSH*" | Format-List DisplayName,Enabled,Direction,Action,LocalPort
Write-Host ""
Write-Host "Todas as regras de entrada TCP:" -ForegroundColor Cyan
Get-NetFirewallRule -Direction Inbound -Protocol TCP | select DisplayName,Enabled,LocalPort | Format-Table -AutoSize
Write-Host ""

# ─── 5. Logs do OpenSSH (Windows Event Log) ───
Write-Host "【5/8】 Logs do OpenSSH (Event Viewer)" -ForegroundColor Yellow
try {
    Get-WinEvent -LogName "OpenSSH/Operational" -MaxEvents 30 -ErrorAction Stop | 
        select TimeCreated,Id,LevelDisplayName,Message | Format-List
} catch {
    Write-Host "❌ Não foi possível acessar OpenSSH/Operational log" -ForegroundColor Red
    Write-Host "Erro: $_" -ForegroundColor Red
}
Write-Host ""

# ─── 6. Logs do sshd (arquivo) ───
Write-Host "【6/8】 Logs do sshd (arquivo)" -ForegroundColor Yellow
$logPath = "C:\ProgramData\ssh\logs\sshd.log"
if (Test-Path $logPath) {
    Write-Host "Arquivo: $logPath" -ForegroundColor Green
    Get-Content $logPath -Tail 50
} else {
    Write-Host "❌ Arquivo NÃO encontrado: $logPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Diretório de logs:" -ForegroundColor Cyan
    Get-ChildItem "C:\ProgramData\ssh\logs" -ErrorAction SilentlyContinue
}
Write-Host ""

# ─── 7. Teste de Conectividade Local ───
Write-Host "【7/8】 Teste SSH Local" -ForegroundColor Yellow
Write-Host "Testando: ssh ufrb@localhost" -ForegroundColor Cyan
$testResult = ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no ufrb@localhost "echo SSH_TEST_OK" 2>&1
Write-Host "Resultado: $testResult" -ForegroundColor $(if($testResult -match "OK"){"Green"}else{"Red"})
Write-Host ""

# ─── 8. Informações de Rede ───
Write-Host "【8/8】 Informações de Rede" -ForegroundColor Yellow
ipconfig | findstr -i "IPv4|Gateway|Subnet"
Write-Host ""
Write-Host "Rotas:" -ForegroundColor Cyan
route print | findstr "0.0.0.0"
Write-Host ""

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  FIM DO DIAGNÓSTICO" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 COLE TUDO ACIMA no Debug Console!" -ForegroundColor Yellow
Write-Host ""
