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
│   └── vnc.sh                 ← Conecta via VNC
├── iso/                       ← ISOs (gitignorado)
│   └── Win10_22H2_BrazilianPortuguese_x64v1.iso  ← ISO oficial 5.5GB
├── docs/                      ← Documentação técnica futura
└── .git/                      ← Git
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
| ISO | `/home/deivi/Projetos/WindowsMaster/iso/Win10_22H2_BrazilianPortuguese_x64v1.iso` |
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
   - Ativar WinRM (HTTP 5985)
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
```

---

## 📦 Estado Atual (11/jun/2026)

- ✅ Repo criado e enviado para GitHub (público)
- ✅ ISO oficial Windows 10 22H2 PT-BR baixada (5.5GB)
- ✅ ISO copiada para `iso/`
- ✅ VirtIO ISO presente (`/var/lib/libvirt/images/virtio-win.iso`)
- ✅ AGENTS.md atualizado (este arquivo)
- 🔄 **Próximo passo:** Executar `build-vm.sh` para criar a VM

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

---

## 🚀 Próximos Passos Imediatos

1. Executar `sudo ./scripts/build-vm.sh` → cria e inicia a VM
2. Acessar VNC → verificar se Windows está instalando
3. Aguardar instalação + auto-logon
4. Configurar WinRM, programas, etc.
5. Documentar o que foi feito no Windows para o AGENTS.md

---

## 📝 Como Atualizar Este Arquivo

Sempre que:
- Criar novo script
- Mudar fluxo de trabalho
- Tomar decisão arquitetural
- Alterar stack ou rede

→ **Edite este arquivo** e adicione a seção correspondente.

---

**Última atualização:** 11/jun/2026 — Deivison Santana  
**Status:** Pronto para criar a VM e iniciar a instalação automatizada.
