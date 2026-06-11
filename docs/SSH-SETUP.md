# 🔐 SSH Access - WindowsMaster

## 🌐 Debug Console

**🔗 https://crumpet-scouring-self.ngrok-free.dev**

---

## ✅ Status

| Item | Status |
|------|--------|
| OpenSSH | ✅ Running |
| Porta 22 | ✅ LISTENING |
| Firewall 22 | ✅ Configurado |

---

## 📋 Verificar

```powershell
Get-Content C:\ProgramData\ssh\sshd_config | findstr PasswordAuthentication
Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 20
```

---

## 🔐 Conectar (quando pronto)

```bash
ssh -p 2222 ufrb@localhost
```

Senha: `Ufrb@2026`

---

**Última atualização:** 11/jun/2026
