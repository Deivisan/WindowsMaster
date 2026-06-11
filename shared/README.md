# shared/ — Pasta Compartilhada Windows ↔ Linux

## 🎯 Conceito

Pasta real no Linux (`WindowsMaster/shared/`) que aparece **dentro do Windows** via VirtIO-9P.

**Vantagem:** Crie/edit scripts `.ps1` no Linux → aparecem instantaneamente no Windows.

---

## 📁 Estrutura

```
WindowsMaster/
└── shared/           ← Montado no Windows
    ├── scripts/      ← .ps1 (WinRM, RDP, SSH, etc)
    ├── logs/         ← Logs de execução
    ├── backups/      ← Backups de configs
    └── configs/      ← JSON/YAML de configuração
```

---

## 🚀 Como Usar

### 1. Configurar VM (Linux)

```bash
sudo ./scripts/setup-shared-folder.sh
```

### 2. No Windows (após reiniciar VM)

```powershell
# Mapear como drive X:
net use X: \\10.0.2.2\shared /persistent:yes

# Executar scripts
X:\scripts\win10-configure-all.ps1
```

### 3. Criar Novo Script (Linux)

```bash
vim shared/scripts/meu-script.ps1
```

O script aparece automaticamente no Windows em `X:\scripts\`

---

## 📜 Scripts Disponíveis

| Script | Propósito |
|--------|-----------|
| `win10-configure-all.ps1` | OpenSSH + WinRM + RDP + usuário `ufrb` |

---

## 📡 Descobrir IP da VM

```cmd
ipconfig
```

Geralmente: `10.0.2.15`

---

**Última atualização:** 11/jun/2026
