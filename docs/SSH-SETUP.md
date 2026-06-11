# 🔐 SSH Access - WindowsMaster

## 🌐 Debug Console

**🔗 https://crumpet-scouring-self.ngrok-free.dev**

---

## ✅ Status Atual

| Item | Status |
|------|--------|
| OpenSSH instalado | ✅ Running |
| Porta 22 ouvindo | ❌ Connection refused |
| Tailscale | ✅ Conectado (100.82.252.113) |
| SSH via Tailscale | ❌ Permission denied |

---

## 📋 Comandos de Verificação (Execute no Windows)

### 1. Testar SSH Local (dentro do Windows)
```powershell
ssh ufrb@localhost
```

**O que observar:**
- Conecta? Pede senha?
- Se conectar → problema é de rede/Tailscale
- Se falhar → problema é no SSH Server

---

### 2. Verificar PasswordAuthentication
```powershell
Get-Content C:\ProgramData\ssh\sshd_config | findstr PasswordAuthentication
```

**Saída esperada:**
```
PasswordAuthentication yes
```

**Se aparecer `no` ou nada:**
```powershell
(Get-Content C:\ProgramData\ssh\sshd_config) -replace '#*PasswordAuthentication.*','PasswordAuthentication yes' | Set-Content C:\ProgramData\ssh\sshd_config
Restart-Service sshd
```

---

### 3. Verificar se ufrb está habilitado
```powershell
Get-LocalUser -Name "ufrb" | select Name,Enabled,PasswordLastSet
```

**Saída esperada:**
```
Name  Enabled PasswordLastSet
----  ------- ---------------
ufrb   True   [data da senha]
```

**Se `Enabled` for `False`:**
```powershell
Enable-LocalUser -Name "ufrb"
```

---

### 4. Verificar se ufrb tem senha
```powershell
net user ufrb
```

**Procurar por:** `Password last set` (deve ter uma data, não "Never")

---

### 5. Verificar Permissões do SSH
```powershell
Get-Content C:\ProgramData\ssh\sshd_config | findstr -i 'AllowUsers\|AllowGroups\|DenyUsers'
```

**Se aparecer `AllowUsers` ou `DenyUsers`, adicione ufrb:**
```powershell
# Editar sshd_config e adicionar:
# AllowUsers ufrb
Restart-Service sshd
```

---

### 6. Testar Login com Verbose (debug)
```powershell
ssh -vvv ufrb@localhost 2>&1 | findstr -i "password\|auth\|permission\|failed"
```

---

## 🔐 Conectar via Tailscale

```bash
ssh ufrb@100.82.252.113
```

Senha: `Meddi@2025`

---

## 📝 Cole a Saída Aqui

Cole no Debug Console a saída dos comandos **1, 2 e 3** para diagnosticarmos!

---

**Última atualização:** 11/jun/2026
