# WindowsMaster — Documentação para Agentes de IA (Dinâmico)

> **Este arquivo é a fonte da verdade para agentes de IA.**  
> Atualize-o sempre que criar/modificar scripts, fluxos, ou decisões importantes.

---

## 🎯 Missão Atual

Criar uma **imagem base do Windows 10 22H2** (build 19045.7417) otimizada para HD, com:
- WinRM ativo (HTTP 5985) para controle remoto
- Programas institucionais
- Drivers VirtIO + QEMU Guest Agent
- Pronta para captura via FOG Project (30+ máquinas)

---

## 🧱 Stack Técnico

| Camada | Tecnologia |
|--------|------------|
| Hypervisor | QEMU/KVM + libvirt |
| Firmware | UEFI + Secure Boot + TPM 2.0 |
| Drivers | VirtIO (storage + net) |
| Guest Agent | QEMU Guest Agent |
| Acesso Gráfico | VNC (porta 5900, 0.0.0.0) |
| Acesso Remoto | WinRM HTTP 5985 |
| Deploy | FOG Project v2.10 |
| Automação | autounattend.xml + scripts bash |
| Rede | SLiRP (NAT) — host 172.17.23.130 / FOG 172.17.0.25 |

---

## 📁 Estrutura do Repositório

```
WindowsMaster/
├── AGENTS.md                  ← Este arquivo (fonte da verdade)
├── README.md                  ← Documentação para humanos
├── .gitignore                 ← Robusto (ignora *.iso, *.qcow2, etc)
├── autounattend/
│   ├── autounattend.xml       ← Instalação silenciosa + auto-logon
│   └── .gitkeep
├── scripts/
│   ├── download-iso.sh        ← Baixa ISO oficial Microsoft
│   ├── prepare-autounattend.sh← Injeta autounattend na ISO
│   ├── build-vm.sh            ← Cria VM QEMU/KVM + VNC
│   ├── start-vm.sh            ← Inicia VM
│   ├── stop-vm.sh             ← Para VM
│   ├── status.sh              ← Status da VM
│   ├── vnc.sh                 ← Conecta via VNC
│   └── setup-shared-folder.sh ← Configura VirtIO-9P
├── shared/                    ← Pasta montada no Windows via 9P
│   ├── scripts/               ← .ps1 (WinRM, RDP, SSH, etc)
│   ├── logs/
│   ├── backups/
│   └── configs/
├── docs/
│   └── SSH-SETUP.md           ← Histórico de debug SSH
├── iso/                       ← ISOs (gitignorado)
│   └── Win10_22H2_BrazilianPortuguese_x64v1.iso
├── AGENTS.md
├── README.md
└── .git/
```

---

## 🖥️ VM Atual (winmaster-base)

| Campo | Valor |
|-------|-------|
| Nome | `winmaster-base` |
| Disco | `/var/lib/libvirt/images/winmaster-base.qcow2` |
| RAM | 4GB |
| vCPUs | 4 (host-passthrough) |
| VNC | `0.0.0.0:5900` |
| Firmware | UEFI + Secure Boot |
| TPM | 2.0 emulado |
| Rede | SLiRP (user-mode NAT) |
| ISO | `/var/lib/libvirt/images/Win10_22H2_BrazilianPortuguese_x64v1.iso` |
| VirtIO | `/var/lib/libvirt/images/virtio-win.iso` (195MB) |

---

## 🔄 Fluxo de Trabalho (Ordem de Execução)

1. **ISO já baixada** → `iso/Win10_22H2_BrazilianPortuguese_x64v1.iso` (5.5GB)
2. **(Opcional)** Preparar ISO automatizada:
   ```bash
   sudo ./scripts/prepare-autounattend.sh
   ```
3. **Criar e iniciar a VM**:
   ```bash
   sudo ./scripts/build-vm.sh
   ```
4. **Acessar via VNC**:
   ```bash
   ./scripts/vnc.sh
   ```
5. **Configurar dentro do Windows**:
   - Instalar programas institucionais
   - Ativar WinRM
   - Otimizar para HD
   - Configurar hostname, usuários, etc.
6. **Preparar para FOG** (futuro):
   ```bash
   sudo ./scripts/sysprep.sh
   ```
7. **Capturar no FOG** → http://172.17.0.25/fog

---

## 🌐 Rede e Conectividade

```
Host (Arch):     172.17.23.130
FOG Server:      172.17.0.25
VM (NAT):        10.0.2.x
WinRM Alvo:      http://<vm-ip>:5985
VNC:             localhost:5900
Tailscale:       100.82.252.113 (Windows VM)
```

---

## 📦 Estado Atual (11/jun/2026)

### VM e Infraestrutura
- ✅ Repo criado e enviado para GitHub (público)
- ✅ ISO oficial Windows 10 22H2 PT-BR baixada (5.5GB)
- ✅ VM `winmaster-base` **CRIADA E RODANDO**
- ✅ VNC ativo em `0.0.0.0:5900`
- ✅ Tailscale instalado e configurado

### Tentativas de Acesso Remoto

#### Fase 1: QEMU Port Forwarding
- ✅ Configurado hostfwd (porta 2222 → 22)
- ✅ Porta 2222 ouvindo no host
- ❌ SSH dentro do Windows: Connection refused
- **Conclusão:** SSH Server não escutava na porta 22

#### Fase 2: Tailscale VPN
- ✅ Windows conectado (IP: 100.82.252.113)
- ✅ Conectividade VPN funcionando
- ❌ SSH: Permission denied (publickey,password)
- **Conclusão:** Senha rejeitada

#### Fase 3: Chaves SSH
- ✅ Chave ed25519 gerada no Linux
- ✅ Chave pública adicionada no Windows
- ✅ `PubkeyAuthentication yes` configurado
- ✅ Permissões do arquivo corretas
- ❌ SSH: Permission denied (publickey)
- **Conclusão:** Windows rejeita chave (possível problema de formato/encoding)

### Scripts Criados

| Script | Propósito | Status |
|--------|-----------|--------|
| `shared/scripts/win10-configure-all.ps1` | OpenSSH + WinRM + RDP | ✅ Criado |
| `shared/scripts/diagnose-ssh.ps1` | Diagnóstico completo | ✅ Criado |
| `scripts/setup-shared-folder.sh` | VirtIO-9P mount | ✅ Criado |
| `debug_site.py` | Web console para debug | ✅ Rodando (tmux) |

### Debug Tools

| Tool | URL/Comando | Status |
|------|-------------|--------|
| Debug Console | http://localhost:8888 | ✅ Rodando em tmux |
| ngrok HTTP | https://crumpet-scouring-self.ngrok-free.dev | ✅ Ativo |
| Tailscale | `tailscale status` | ✅ Funcionando |

---

## 🧠 Decisões Importantes

- **Windows 10 22H2** (não 11) — requisito do usuário
- **Build 19045.7417** (KB5094127 — jun/2026) — última disponível
- **Chave genérica** no autounattend (não ativa) — ativação pós-deploy
- **VNC na 5900** para configuração manual inicial
- **WinRM HTTP** (não HTTPS) — rede interna 172.17.x.x
- **SLiRP (NAT)** — VM acessa internet, mas não tem IP na rede 172.17
- **30+ máquinas com HD** (não SSD) — otimizar imagem para HD
- **Repositório só tem código** — imagem capturada via FOG
- **Tailscale** — VPN para acesso remoto confiável (substitui port forwarding problemático)

---

## 🚀 Próximos Passos Imediatos

### Amanhã: Continuar Debug SSH

1. **Verificar logs do SSH Server**
   ```powershell
   Get-Content C:\ProgramData\ssh\logs\sshd.log -Tail 50
   Get-WinEvent -LogName "OpenSSH/Operational" -MaxEvents 30
   ```

2. **Testar com chave RSA** (mais compatível com Windows)
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/winmaster-rsa -N ""
   # Copiar chave pública para Windows
   ```

3. **Verificar formato do authorized_keys**
   - Encoding: UTF-8 (sem BOM)
   - Line endings: LF (não CRLF)

4. **Verificar ListenAddress no sshd_config**
   ```powershell
   Get-Content C:\ProgramData\ssh\sshd_config | findstr ListenAddress
   ```

### Objetivo Final

- ✅ Acesso SSH via Tailscale (100.82.252.113)
- ⏳ WinRM HTTP 5985
- ⏳ RDP porta 3389
- ⏳ Pasta `shared/` montada via VirtIO-9P
- ⏳ Deploy via FOG Project

---

## 📝 Como Atualizar Este Arquivo

Sempre que:
- Criar novo script
- Mudar fluxo de trabalho
- Tomar decisão arquitetural
- Alterar stack ou rede
- Tentar nova abordagem de acesso remoto

→ **Edite este arquivo** e adicione a seção correspondente.

---

**Última atualização:** 11/jun/2026 — Deivison Santana  
**Status:** SSH via Tailscale configurado, chave pública instalada, aguardando debug de autenticação
