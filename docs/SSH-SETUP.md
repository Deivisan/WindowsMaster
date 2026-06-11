# 🔐 SSH Setup — Primeiros Passos

> Execute estes comandos **no PowerShell como Administrador** dentro do Windows 10 para ativar o OpenSSH e obter o IP.

---

## 📋 Comandos (copie e cole um por um)

### 1️⃣ Instalar OpenSSH Server

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

### 2️⃣ Iniciar e configurar o serviço SSH

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

### 3️⃣ Descobrir o IP da VM

```powershell
ipconfig
```

**⚠️ IMPORTANTE:** Copie o IP que aparecer (geralmente `10.0.2.15`) e envie para o agente.

---

## 4️⃣ (Opcional) Criar usuário `ufrb` sem senha

```powershell
New-LocalUser -Name "ufrb" -NoPassword -AccountNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "ufrb"
```

---

## ✅ Verificação Final

Execute para confirmar que o SSH está ativo:

```powershell
Get-Service sshd
```

Saída esperada:

```
Status   Name               DisplayName
------   ----               -----------
Running  sshd               OpenSSH SSH Server
```

---

## 🔐 Após obter o IP

Me envie o IP e eu conecto via:

```bash
ssh ufrb@<IP-DA-VM>
```

A partir daí eu faço toda a configuração:
- WinRM (HTTP 5985)
- RDP (porta 3389)
- Mapeamento da pasta `shared/`
- Scripts PowerShell automatizados
- Acesso total à partição C:

---

## 📁 Arquivos Relacionados

- `shared/scripts/win10-configure-all.ps1` — Configuração completa (executar após SSH)
- `shared/README.md` — Documentação da pasta compartilhada

---

**Última atualização:** 11/jun/2026
