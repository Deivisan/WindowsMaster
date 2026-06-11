# WindowsMaster — Documentação para Agentes de IA

## Stack

| Componente | Tecnologia |
|---|---|
| Hypervisor | QEMU/KVM + libvirt |
| VM Base | Windows 10 22H2 (build 19045) |
| Acesso Gráfico | VNC (porta 5900) |
| Acesso Remoto | WinRM (HTTP 5985) |
| Deploy | FOG Project (servidor em 172.17.0.25) |
| Build | Scripts bash + autounattend.xml |
| Guest Tools | VirtIO drivers, QEMU GA |

## Estrutura do Repositório

```
WindowsMaster/
├── autounattend/          → Arquivos de resposta para instalação automatizada
│   ├── autounattend.xml   → Instalação silent do Windows 10
│   └── .gitkeep
├── scripts/               → Scripts de build, gerenciamento e deploy
│   ├── download-iso.sh    → Baixa última ISO do Windows 10
│   ├── build-vm.sh        → Cria VM no QEMU/KVM
│   ├── start-vm.sh        → Inicia VM
│   ├── stop-vm.sh         → Para VM
│   ├── status.sh          → Status da VM
│   ├── vnc.sh             → Conecta via VNC
│   └── prepare-autounattend.sh → Injeta autounattend na ISO
├── docs/                  → Documentação técnica
├── iso/                   → ISOs baixadas (gitignored)
├── AGENTS.md              → Este arquivo
├── README.md              → Documentação principal
└── .gitignore             → Gitignore robusto
```

## VM Atual

- **Nome:** `winmaster-base`
- **Disco:** `/var/lib/libvirt/images/winmaster-base.qcow2`
- **RAM:** 4GB | **vCPUs:** 4 (host-passthrough)
- **VNC:** `0.0.0.0:5900`
- **UEFI:** Sim, com Secure Boot
- **TPM:** 2.0 emulado
- **Rede:** SLiRP (user mode) → NAT
- **ISO:** `/var/lib/libvirt/images/Win11_25H2_BrazilianPortuguese_x64_v2.iso` (será substituída)

## Fluxo de Trabalho

1. `sudo ./scripts/download-iso.sh` — baixa Win10 22H2 PT-BR
2. `sudo ./scripts/prepare-autounattend.sh` — injeta autounattend.xml na ISO
3. `sudo ./scripts/build-vm.sh` — cria e inicia a VM
4. Acessar via VNC: `./scripts/vnc.sh`
5. Configurar Windows dentro da VM (programas, winrm, ajustes)
6. `sudo ./scripts/sysprep.sh` — prepara para captura FOG (a criar)
7. Capturar imagem via FOG server em 172.17.0.25

## Redes

- Host: 172.17.23.130
- FOG Server: 172.17.0.25
- VM (SLiRP): 10.0.2.x (NAT)
- WinRM alvo: HTTP 5985 na rede 172.17.0.0/16

## Observações Importantes

- A imagem base será clonada via FOG Project para 30+ máquinas
- Todos os PCs alvo têm HD (não SSD) — otimizar para HD
- WinRM deve estar ativo para controle remoto
- Repositório git contém apenas scripts e configs, NÃO a imagem
- Autounattend usa chave genérica (não ativa) — ativação será feita post-deploy
