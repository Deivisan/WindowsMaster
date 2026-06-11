# 🔐 SSH Access - WindowsMaster

## 🌐 Debug Console

**🔗 https://crumpet-scouring-self.ngrok-free.dev**

---

## 🎯 Objetivo

Conseguir acesso SSH do host Linux → Windows VM via port forwarding QEMU.

---

## ✅ Status Atual

| Item | Status |
|------|--------|
| OpenSSH instalado | ✅ Running |
| Porta 22 ouvindo | ❌ **NÃO** (Connection refused) |
| Firewall porta 22 | ✅ Configurado |
| Restart-Service sshd | ✅ Executado |
| ssh localhost:2222 | ❌ Connection refused |

---

## 📋 Script de Diagnóstico Completo

Execute este script **como Administrador** no PowerShell e cole **TODA a saída** no Debug Console:

```powershell
# Baixe e execute o script de diagnóstico completo
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Deivisan/WindowsMaster/main/shared/scripts/diagnose-ssh.ps1" -OutFile "$env:TEMP\diagnose-ssh.ps1"
& "$env:TEMP\diagnose-ssh.ps1"
```

Ou execute manualmente os comandos abaixo:

### 1. sshd_config Completo
```powershell
Get-Content C:\ProgramData\ssh\sshd_config
```

### 2. Onde SSH está Escutando
```powershell
netstat -an | findstr LISTENING
```

### 3. Logs do OpenSSH (Event Viewer)
```powershell
Get-WinEvent -LogName "OpenSSH/Operational" -MaxEvents 30
```

### 4. Logs do sshd (arquivo)
```powershell
Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 50
```

### 5. Teste SSH Local
```powershell
ssh -o ConnectTimeout=3 ufrb@localhost "echo TEST_OK"
```

### 6. Informações de Rede
```powershell
ipconfig /all
route print
```

---

## 🔧 Hipóteses do Problema

### Hipótese 1: QEMU/SLiRP NAT
- VM está em rede NAT (10.0.2.x)
- Host está em rede real (172.17.x.x)
- **Port forwarding QEMU deve resolver** ✅ (já configurado)

### Hipótese 2: sshd_config restrito
- `ListenAddress 127.0.0.1` no sshd_config
- SSH só aceita conexões locais

### Hipótese 3: Windows Firewall
- Regra existe mas não permite conexões de `10.0.2.2` (gateway QEMU)

### Hipótese 4: sshd não escutando
- Serviço "Running" mas processo não vinculado à porta 22

---

## 🔐 Conexão Final

```bash
ssh -p 2222 ufrb@localhost
```

Senha: `Ufrb@2026`

---

**Última atualização:** 11/jun/2026
