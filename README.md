# WindowsMaster 🪟

> Imagem base Windows 10 gerenciável via WinRM — para deploy em massa com FOG Project

## 🎯 Propósito

Criar e manter uma **imagem base do Windows 10 22H2** (última build disponível) otimizada para HD, com WinRM ativo e programas institucionais, para deploy em **30+ computadores** via **FOG Project**.

O repositório contém **apenas código e scripts** — a imagem em si é gerada localmente e capturada pelo FOG.

## 📋 Pré-requisitos

| Item | Versão |
|---|---|
| Arch Linux (ou qualquer distro) | - |
| QEMU/KVM | `qemu-full` |
| libvirt | `libvirt` + `virt-install` |
| edk2-ovmf | UEFI firmware |
| TigerVNC | `tigervnc` (cliente VNC) |
| xorriso | Para reconstruir ISO |
| FOG Project | Servidor em 172.17.0.25 |

## 🚀 Como Usar

### 1. Baixar a ISO do Windows 10

```bash
sudo ./scripts/download-iso.sh
```

Baixa a última ISO do Windows 10 22H2 em português brasileiro.

### 2. Preparar ISO com instalação automatizada (opcional)

```bash
sudo ./scripts/prepare-autounattend.sh
```

Injeta o `autounattend.xml` na ISO para instalação silenciosa.

### 3. Criar e iniciar a VM

```bash
sudo ./scripts/build-vm.sh
```

Cria uma VM com:
- 4GB RAM, 4 vCPUs, 60GB de disco
- VNC na porta 5900
- UEFI com Secure Boot + TPM 2.0
- VirtIO drivers

### 4. Acessar via VNC

```bash
./scripts/vnc.sh
```

### 5. Configurar o Windows

Dentro da VM:
- Instalar programas institucionais
- Ativar WinRM
- Aplicar otimizações para HD
- Configurar firewall, usuários, etc

### 6. Status da VM

```bash
./scripts/status.sh
```

### 7. Parar a VM

```bash
./scripts/stop-vm.sh          # shutdown graceful
./scripts/stop-vm.sh --force  # desliga forçado
```

## 📡 Plano de Rede

```
Rede:        172.17.0.0/16
Host (PC):   172.17.23.130
FOG Server:  172.17.0.25
VM (NAT):    10.0.2.x
WinRM:       http://<ip>:5985
```

## 🏗️ Arquitetura da Imagem

```
Windows 10 22H2 (build 19045.7417 — jun/2026)
├── Windows 10 Pro (64-bit)
├── VirtIO Drivers (storage + network)
├── QEMU Guest Agent
├── WinRM ativo (HTTP 5985)
├── Programas institucionais
└── Otimizado para HD
```

## 📦 Deploy com FOG

1. Prepare a imagem: configure tudo dentro da VM
2. Execute sysprep: `C:\Windows\System32\Sysprep\sysprep.exe /oobe /generalize /shutdown`
3. Capture a imagem pelo FOG Server (`http://172.17.0.25/fog`)
4. Faça deploy nos 30+ computadores

## 🤝 Contribuindo

Este repositório é privado e mantido por [Deivison Santana](https://github.com/deivisan).

## 📄 Licença

Privado — WindowsMaster © 2026
