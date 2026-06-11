# 🔐 SSH Setup — Configuração e Diagnóstico

> Execute estes comandos **no PowerShell como Administrador** dentro do Windows 10.

---

## ✅ Status Atual (Confirmado)

- ✅ `Get-Service sshd` → **Running**
- ✅ `netstat -an | findstr :22` → **LISTENING**
- ✅ `ssh ufrb@localhost` → **Conecta e pede senha**

---

## ❌ Problema Identificado

**Port Forwarding do QEMU está funcionando**, mas o **handshake SSH falha** quando conectando de fora da VM.

---

## 📋 Passo 1: Verificar sshd_config

```powershell
# Verificar configuração do SSH Server
Get-Content C:\ProgramData\ssh\sshd_config | findstr -i 'ListenAddress\|PasswordAuthentication'
```

**Saída esperada:**

```
PasswordAuthentication yes
```

Se aparecer `PasswordAuthentication no`, execute:

```powershell
# Habilitar autenticação por senha
(Get-Content C:\ProgramData\ssh\sshd_config) -replace 'PasswordAuthentication no','PasswordAuthentication yes' | Set-Content C:\ProgramData\ssh\sshd_config
Restart-Service sshd
```

---

## 📋 Passo 2: Verificar Firewall

```powershell
# Verificar regras de firewall do SSH
netsh advfirewall firewall show rule name=all | findstr -i 'SSH.*22'
```

**Saída esperada:** Deve mostrar a regra permitindo conexões na porta 22.

Se não aparecer, execute:

```powershell
New-NetFirewallRule -Name "SSH-22-In" -DisplayName "OpenSSH SSH Server (22)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -RemoteAddress Any
```

---

## 📋 Passo 3: Testar SSH de IP Externo (dentro do Windows)

```powershell
# Testar conexão SSH de outro IP (simulando conexão externa)
ssh ufrb@10.0.2.2
```

Se conectar, o problema é de rede/firewall.
Se falhar, o problema é no sshd_config.

---

## 🌐 Conexão via Host (Port Forwarding)

Uma vez que o SSH aceitar conexões externas, conecte do host via:

```bash
# SSH
ssh -p 2222 ufrb@localhost

# WinRM (porta 5985)
winrs -r:http://localhost:5985 -u:ufrb hostname

# RDP (porta 3389)
rdesktop localhost:3389
```

---

## 🔧 Comandos de Correção Rápida

### Se PasswordAuthentication estiver desabilitado:

```powershell
(Get-Content C:\ProgramData\ssh\sshd_config) -replace '#*PasswordAuthentication.*','PasswordAuthentication yes' | Set-Content C:\ProgramData\ssh\sshd_config
Restart-Service sshd
```

### Se firewall estiver bloqueando:

```powershell
New-NetFirewallRule -Name "SSH-22-In" -DisplayName "SSH Server" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

---

## 📁 Arquivos Relacionados

- `shared/scripts/win10-configure-all.ps1` — Script completo de configuração
- `shared/README.md` — Documentação da pasta compartilhada

---

**Última atualização:** 11/jun/2026
