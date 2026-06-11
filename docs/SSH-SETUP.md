# 🔐 SSH Setup — Configuração e Verificação

> Execute estes comandos **no PowerShell como Administrador** dentro do Windows 10 para verificar e ativar o OpenSSH.

---

## 📋 Passo 1: Verificar se OpenSSH está Instalado e Rodando

```powershell
# Verificar status do serviço SSH
Get-Service sshd
```

**Saída esperada:**

```
Status   Name               DisplayName
------   ----               -----------
Running  sshd               OpenSSH SSH Server
```

Se aparecer `Stopped`, execute:

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

---

## 📋 Passo 2: Verificar se a Porta 22 está Aberta

```powershell
# Verificar se SSH está escutando na porta 22
netstat -an | findstr :22
```

**Saída esperada:**

```
  TCP    0.0.0.0:22             0.0.0.0:0              LISTENING
  TCP    [::]:22                [::]:0                 LISTENING
```

Se **não aparecer**, o SSH não está configurado corretamente.

---

## 📋 Passo 3: Verificar Firewall

```powershell
# Verificar regras de firewall do SSH
Get-NetFirewallRule -DisplayName '*SSH*' | select DisplayName,Enabled,Action
```

**Saída esperada:**

```
DisplayName          Enabled Action
-----------          ------- ------
OpenSSH-Server-In-TCP   True Allow
```

Se não aparecer ou `Enabled` for `False`, execute:

```powershell
New-NetFirewallRule -Name "SSH-22" -DisplayName "OpenSSH SSH Server (22)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

---

## 📋 Passo 4: Descobrir o IP da VM

```powershell
# Verificar IP da VM
ipconfig
```

**Copie o IP** que aparecer (geralmente `10.0.2.15`) e envie para o agente.

---

## 📋 Passo 5: Testar SSH Localmente (dentro do Windows)

```powershell
# Testar SSH localmente
ssh ufrb@localhost
```

Se pedir senha ou conectar, o SSH está funcionando.

---

## 🔐 Após Confirmar que SSH Está Rodando

Me envie:

1. ✅ Saída do `Get-Service sshd`
2. ✅ Saída do `netstat -an | findstr :22`
3. ✅ O **IP** do `ipconfig`

---

## 🌐 Conexão via Host (Port Forwarding Configurado)

Uma vez que o SSH estiver rodando dentro do Windows, conecte do host via:

```bash
# SSH
ssh -p 2222 ufrb@localhost

# WinRM (porta 5985)
winrs -r:http://localhost:5985 -u:ufrb hostname

# RDP (porta 3389)
rdesktop localhost:3389
```

---

## 📁 Arquivos Relacionados

- `shared/scripts/win10-configure-all.ps1` — Script completo de configuração
- `shared/README.md` — Documentação da pasta compartilhada

---

**Última atualização:** 11/jun/2026
