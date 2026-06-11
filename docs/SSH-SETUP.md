# 🔐 SSH Debug - WindowsMaster

## 🌐 Debug Site (Cole saídas aqui)

**URL:** http://localhost:8888

Cole a saída dos comandos PowerShell aqui para debug rápido.

---

## 📡 ngrok (Túnel Público)

**Status:** Requer cartão de crédito para TCP (conta free)

**Para ativar túnel TCP:**
1. Acesse: https://dashboard.ngrok.com/settings#id-verification
2. Adicione cartão (não é cobrado)
3. Configure seu token: `ngrok config add-authtoken SEU_TOKEN`
4. Execute: `ngrok tcp 2222`

---

## 📋 Comandos para Executar no Windows

### 1. Verificar SSH rodando
```powershell
Get-Service sshd
```

### 2. Verificar porta 22 aberta
```powershell
netstat -an | findstr :22
```

### 3. Verificar sshd_config
```powershell
Get-Content C:\ProgramData\ssh\sshd_config | findstr -i 'ListenAddress\|PasswordAuthentication'
```

### 4. Verificar firewall
```powershell
netsh advfirewall firewall show rule name=all | findstr -i 'SSH.*22'
```

### 5. Verificar log do SSH
```powershell
Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 20
```

---

## 🔧 Comandos de Correção

### Habilitar PasswordAuthentication
```powershell
(Get-Content C:\ProgramData\ssh\sshd_config) -replace '#*PasswordAuthentication.*','PasswordAuthentication yes' | Set-Content C:\ProgramData\ssh\sshd_config
Restart-Service sshd
```

### Abrir porta 22 no firewall
```powershell
New-NetFirewallRule -Name "SSH-22-In" -DisplayName "SSH Server" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

---

## 🌐 Port Forwarding (Host)

- **SSH:** `ssh -p 2222 ufrb@localhost`
- **WinRM:** `winrs -r:http://localhost:5985 -u:ufrb hostname`
- **RDP:** `rdesktop localhost:3389`

---

**Última atualização:** 11/jun/2026
