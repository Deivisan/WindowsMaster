# 🔐 SSH Access - WindowsMaster

## 🌐 Debug Console

**🔗 https://crumpet-scouring-self.ngrok-free.dev**

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

## 📋 Comandos Executados

### 1. Verificar log do SSH
```powershell
Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 20
# Erro: Arquivo não existe
```

### 2. Testar SSH localhost
```powershell
ssh -p 2222 ufrb@localhost
# Erro: Connection refused
```

### 3. Reiniciar serviço SSH
```powershell
Restart-Service sshd
# ✅ Executado
```

### 4. Testar novamente após restart
```powershell
ssh -p 2222 ufrb@localhost
# ❌ Ainda: Connection refused
```

---

## 🔧 Diagnóstico

**Problema persistente:** SSH Server está "Running" mas **não escuta na porta 22**.

**Possíveis causas:**
1. `sshd_config` tem `ListenAddress` restrito
2. Windows OpenSSH requer `sshd_config` específico
3. Serviço precisa de configuração manual

---

## 📋 Próximos Comandos

### 1. Verificar sshd_config COMPLETO
```powershell
Get-Content C:\ProgramData\ssh\sshd_config
```

### 2. Verificar onde SSH está escutando
```powershell
netstat -an | findstr LISTENING
```

### 3. Verificar Event Viewer (logs do Windows)
```powershell
Get-WinEvent -LogName "OpenSSH/Operational" -MaxEvents 20
```

---

## 🔐 Conectar (quando SSH aceitar)

```bash
ssh -p 2222 ufrb@localhost
```

Senha: `Ufrb@2026`

---

**Última atualização:** 11/jun/2026
