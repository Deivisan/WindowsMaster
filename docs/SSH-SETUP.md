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
| Conexão SSH localhost | ❌ Connection refused |

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

---

## 🔧 Diagnóstico

**Problema:** SSH Server está "Running" mas **não está escutando** na porta 22.

**Possíveis causas:**
1. `sshd_config` tem `ListenAddress 127.0.0.1` (apenas localhost)
2. Serviço SSH não reiniciou após mudanças
3. Windows OpenSSH requer configuração adicional

---

## 📋 Próximos Comandos

### 1. Verificar sshd_config
```powershell
Get-Content C:\ProgramData\ssh\sshd_config
```

### 2. Verificar onde SSH está escutando
```powershell
netstat -an | findstr LISTENING
```

### 3. Reiniciar serviço SSH
```powershell
Restart-Service sshd
```

---

## 🔐 Conectar (quando SSH aceitar)

```bash
ssh -p 2222 ufrb@localhost
```

Senha: `Ufrb@2026`

---

**Última atualização:** 11/jun/2026
