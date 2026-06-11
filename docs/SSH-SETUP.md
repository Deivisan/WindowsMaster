# 🔐 SSH Access - WindowsMaster

## 🌐 Debug Console

**🔗 https://crumpet-scouring-self.ngrok-free.dev**

---

## 📜 Histórico de Tentativas

### Fase 1: QEMU Port Forwarding
- ✅ Configurado hostfwd (porta 2222 → 22)
- ✅ Porta 2222 ouvindo no host
- ❌ SSH dentro do Windows: Connection refused
- **Conclusão:** SSH Server não escutava na porta 22

### Fase 2: Tailscale VPN
- ✅ Windows conectado (IP: 100.82.252.113)
- ✅ Conectividade VPN funcionando
- ❌ SSH: Permission denied (publickey,password)
- **Conclusão:** Senha rejeitada

### Fase 3: Chaves SSH
- ✅ Chave ed25519 gerada no Linux
- ✅ Chave pública adicionada no Windows
- ✅ `PubkeyAuthentication yes` configurado
- ✅ Permissões do arquivo corretas
- ❌ SSH: Permission denied (publickey)
- **Conclusão:** Windows rejeita chave (possível problema de formato/encoding)

---

## ✅ Status Final

| Item | Status |
|------|--------|
| OpenSSH instalado | ✅ Running |
| Porta 22 ouvindo | ❌ Connection refused |
| Tailscale conectado | ✅ 100.82.252.113 |
| Chave pública configurada | ✅ |
| `PubkeyAuthentication` | ✅ yes |
| Permissões authorized_keys | ✅ Corretas |
| SSH via Tailscale | ❌ Permission denied |

---

## 🔧 Próximos Passos (para amanhã)

### 1. Verificar logs do SSH Server
```powershell
Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 50
```

### 2. Verificar Event Viewer
```powershell
Get-WinEvent -LogName "OpenSSH/Operational" -MaxEvents 30
```

### 3. Testar com chave RSA (mais compatível)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/winmaster-rsa -N ""
# Copiar chave pública para Windows
```

### 4. Verificar formato do authorized_keys
```powershell
# Verificar encoding (deve ser UTF-8)
Get-Content "$env:USERPROFILE\.ssh\authorized_keys" -Encoding UTF8
```

### 5. Verificar line endings
```powershell
# Converter CRLF para LF se necessário
(Get-Content "$env:USERPROFILE\.ssh\authorized_keys") -replace "`r`n","`n" | Set-Content "$env:USERPROFILE\.ssh\authorized_keys" -NoNewline
```

---

## 📁 Arquivos Relacionados

- `shared/scripts/diagnose-ssh.ps1` — Script de diagnóstico completo
- `shared/scripts/win10-configure-all.ps1` — Configuração inicial

---

**Última atualização:** 11/jun/2026
