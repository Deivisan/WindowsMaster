#!/bin/bash
# ============================================================
# build-vm.sh — Cria VM Windows 10 no QEMU/KVM + VNC
# ============================================================
# Cria e inicia uma VM com Windows 10 22H2 para
# preparação da imagem base do WindowsMaster.
#
# Uso: sudo ./build-vm.sh [--start] [--vnc-port 5900]
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ISO_DIR="$REPO_DIR/iso"
AUTOUNAttEND_DIR="$REPO_DIR/autounattend"

# ─── Configurações ───
VM_NAME="winmaster-base"
VM_DIR="/var/lib/libvirt/images"
DISK="$VM_DIR/$VM_NAME.qcow2"
DISK_SIZE="60G"
RAM="4096"        # 4GB
VCPUS="4"         # 4 vCPUs
VNC_PORT="${2:-5900}"
BRIDGE=""

# ISO do Windows 10
WIN_ISO=$(ls "$ISO_DIR"/*.iso 2>/dev/null | head -1)
VIRTIO_ISO="/var/lib/libvirt/images/virtio-win.iso"

# ─── Core count físico ───
PHYSICAL_CORES=$(nproc)
VCPUS=$(( PHYSICAL_CORES / 2 ))
[ "$VCPUS" -lt 2 ] && VCPUS=2
[ "$VCPUS" -gt 8 ] && VCPUS=8

# ─── Cores ───
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
RESET='\033[0m'

info()  { echo -e "${AZUL}[INFO]${RESET} $1"; }
ok()    { echo -e "${VERDE}[OK]${RESET}   $1"; }
aviso() { echo -e "${AMARELO}[AVISO]${RESET} $1"; }
erro()  { echo -e "${VERMELHO}[ERRO]${RESET} $1"; }

# ═══════════════════════════════════════════════════
#  VERIFICAÇÕES
# ═══════════════════════════════════════════════════

verificar_dependencias() {
    info "Verificando dependências..."
    
    # QEMU
    for cmd in qemu-system-x86_64 qemu-img; do
        if ! command -v "$cmd" &>/dev/null; then
            erro "$cmd não encontrado. Instale com: sudo pacman -S qemu-full"
            exit 1
        fi
    done
    ok "QEMU encontrado"
    
    # Libvirt
    if ! command -v virsh &>/dev/null; then
        erro "virsh não encontrado. Instale com: sudo pacman -S libvirt"
        exit 1
    fi
    ok "libvirt encontrado"
    
    # OVMF (UEFI)
    if [ ! -f /usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd ]; then
        aviso "OVMF UEFI não encontrado. Instale edk2-ovmf"
        aviso "sudo pacman -S edk2-ovmf"
    else
        ok "OVMF UEFI disponível"
    fi
}

verificar_iso() {
    info "Verificando ISO do Windows 10..."
    
    if [ -z "$WIN_ISO" ]; then
        erro "Nenhuma ISO do Windows 10 encontrada em $ISO_DIR/"
        echo ""
        echo "  Baixe primeiro com: sudo ./scripts/download-iso.sh"
        echo "  Ou coloque a ISO manualmente em: $ISO_DIR/"
        exit 1
    fi
    
    ok "ISO: $(basename "$WIN_ISO") ($(du -h "$WIN_ISO" | cut -f1))"
}

verificar_virtio() {
    info "Verificando VirtIO drivers..."
    
    if [ ! -f "$VIRTIO_ISO" ]; then
        aviso "virtio-win.iso não encontrado em $VIRTIO_ISO"
        aviso "Baixe de: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
        echo ""
        echo "  Instalação sem VirtIO pode não detectar o disco!"
        echo "  Pressione ENTER para continuar mesmo assim..."
        read -r
    else
        ok "VirtIO ISO disponível"
    fi
}

verificar_kvm() {
    if [ ! -c /dev/kvm ]; then
        erro "KVM não disponível (/dev/kvm não encontrado)"
        erro "Verifique se a virtualização está habilitada na BIOS"
        erro "E se o módulo kvm_amd está carregado: sudo modprobe kvm_amd"
        exit 1
    fi
    ok "KVM disponível"
}

verificar_libvirtd() {
    if ! systemctl is-active --quiet libvirtd 2>/dev/null; then
        info "Iniciando libvirtd..."
        sudo systemctl start libvirtd
        sleep 2
    fi
    ok "libvirtd ativo"
}

# ═══════════════════════════════════════════════════
#  CRIAÇÃO DA VM
# ═══════════════════════════════════════════════════

criar_disco() {
    info "Criando disco ($DISK_SIZE)..."
    
    if [ -f "$DISK" ]; then
        echo ""
        aviso "Disco já existe: $DISK"
        aviso "Tamanho: $(du -h "$DISK" | cut -f1)"
        echo ""
        echo "  Deseja recriar? (s/N) "
        read -r resp
        if [ "$resp" = "s" ] || [ "$resp" = "S" ]; then
            info "Removendo disco antigo..."
            sudo rm -f "$DISK"
        else
            ok "Usando disco existente"
            return 0
        fi
    fi
    
    sudo qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
    sudo chown libvirt-qemu:kvm "$DISK" 2>/dev/null || true
    ok "Disco criado: $DISK"
}

limpar_vm_antiga() {
    info "Verificando VM existente..."
    
    if virsh list --all --name 2>/dev/null | grep -qx "$VM_NAME"; then
        aviso "VM '$VM_NAME' já existe. Removendo..."
        sudo virsh destroy "$VM_NAME" 2>/dev/null || true
        sudo virsh undefine "$VM_NAME" --nvram 2>/dev/null || true
        ok "VM antiga removida"
    fi
}

# ─── Cria XML da VM manualmente (mais controle que virt-install) ───
criar_xml_vm() {
    info "Criando definição da VM..."
    
    local UUID=$(uuidgen 2>/dev/null || echo "05767510-3845-48bd-a262-ea3d1752cdd8")
    local MAC="52:54:00:$(printf '%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))"
    
    # Detecta a arquitetura da máquina QEMU
    local MACHINE="pc-q35-9.0"
    # Tenta detectar a versão disponível
    local QEMU_VERSION=$(qemu-system-x86_64 --version | grep -oP 'version \K[0-9]+\.[0-9]+' | head -1 || echo "9.0")
    local QEMU_MAJOR=$(echo "$QEMU_VERSION" | cut -d. -f1)
    local QEMU_MINOR=$(echo "$QEMU_VERSION" | cut -d. -f2)
    
    # Constrói o nome da máquina baseado na versão do QEMU
    MACHINE="pc-q35-${QEMU_MAJOR}.${QEMU_MINOR}"
    
    local OVMF_CODE="/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd"
    local OVMF_VARS="/usr/share/edk2/x64/OVMF_VARS.4m.fd"
    local NVRAM="/var/lib/libvirt/qemu/nvram/${VM_NAME}_VARS.fd"
    
    # Fallback se não existir o secureboot
    if [ ! -f "$OVMF_CODE" ]; then
        OVMF_CODE="/usr/share/edk2/x64/OVMF_CODE.fd"
        OVMF_VARS="/usr/share/edk2/x64/OVMF_VARS.fd"
    fi
    
    sudo mkdir -p /var/lib/libvirt/qemu/nvram
    
    # Cria o XML
    sudo tee /etc/libvirt/qemu/$VM_NAME.xml > /dev/null <<XML
<!-- WINDOWSMASTER - Windows 10 22H2 Base Image -->
<domain type='kvm'>
  <name>$VM_NAME</name>
  <uuid>$UUID</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://microsoft.com/win/10"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit='KiB'>$((RAM * 1024))</memory>
  <currentMemory unit='KiB'>$((RAM * 1024))</currentMemory>
  <vcpu placement='static'>$VCPUS</vcpu>
  <os firmware='efi'>
    <type arch='x86_64' machine='$MACHINE'>hvm</type>
    <firmware>
      <feature enabled='no' name='enrolled-keys'/>
      <feature enabled='yes' name='secure-boot'/>
    </firmware>
    <loader readonly='yes' secure='yes' type='pflash' format='raw'>$OVMF_CODE</loader>
    <nvram template='$OVMF_VARS' templateFormat='raw' format='raw'>$NVRAM</nvram>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode='custom'>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
      <vpindex state='on'/>
      <runtime state='on'/>
      <synic state='on'/>
      <stimer state='on'/>
      <frequencies state='on'/>
      <tlbflush state='on'/>
      <ipi state='on'/>
      <avic state='on'/>
    </hyperv>
    <smm state='on'/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'/>
  <clock offset='localtime'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
    <timer name='hypervclock' present='yes'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    
    <!-- Disco principal Windows -->
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='writethrough' io='threads'/>
      <source file='$DISK'/>
      <target dev='sda' bus='sata'/>
    </disk>
    
    <!-- ISO do Windows 10 -->
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='$WIN_ISO'/>
      <target dev='sdb' bus='sata'/>
      <readonly/>
    </disk>
XML
    
    # Adiciona VirtIO ISO se existir
    if [ -f "$VIRTIO_ISO" ]; then
        sudo tee -a /etc/libvirt/qemu/$VM_NAME.xml > /dev/null <<XML
    
    <!-- VirtIO Drivers -->
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='$VIRTIO_ISO'/>
      <target dev='sdc' bus='sata'/>
      <readonly/>
    </disk>
XML
    fi
    
    # Final do XML
    sudo tee -a /etc/libvirt/qemu/$VM_NAME.xml > /dev/null <<XML
    
    <controller type='usb' index='0' model='qemu-xhci'/>
    <controller type='sata' index='0'/>
    <controller type='pci' index='0' model='pcie-root'/>
    
    <!-- Rede SLiRP (user mode) → VM consegue internet -->
    <interface type='user'>
      <mac address='$MAC'/>
      <model type='e1000e'/>
    </interface>
    
    <!-- VNC para acesso gráfico -->
    <graphics type='vnc' port='$VNC_PORT' autoport='no' listen='0.0.0.0'>
      <listen type='address' address='0.0.0.0'/>
    </graphics>
    
    <!-- TPM 2.0 emulado (Windows 10 também aceita) -->
    <tpm model='tpm-crb'>
      <backend type='emulator' version='2.0'/>
    </tpm>
    
    <!-- Tablet USB para mouse preciso -->
    <input type='tablet' bus='usb'/>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    
    <!-- Vídeo VirtIO -->
    <video>
      <model type='virtio' heads='1' primary='yes'/>
    </video>
    
    <!-- QEMU Guest Agent -->
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>
    
    <!-- Balloon -->
    <memballoon model='virtio'/>
  </devices>
</domain>
XML
    
    info "Definição XML criada em /etc/libvirt/qemu/$VM_NAME.xml"
}

# ═══════════════════════════════════════════════════
#  INÍCIO
# ═══════════════════════════════════════════════════

iniciar_vm() {
    info "Definindo VM no libvirt..."
    sudo virsh define /etc/libvirt/qemu/$VM_NAME.xml
    ok "VM '$VM_NAME' definida"
    
    info "Iniciando VM..."
    sudo virsh start "$VM_NAME"
    
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo -e "${VERDE}  ✅ VM '$VM_NAME' INICIADA!${RESET}"
    echo ""
    echo "  📺 VNC:"
    echo "     Endereço:  localhost:$VNC_PORT"
    echo "     Ou:        $(hostname -I 2>/dev/null | awk '{print $1}'):$VNC_PORT"
    echo ""
    echo "  🔗 Conectar via VNC:"
    echo "     vncviewer localhost:$VNC_PORT"
    echo "     ou http://localhost:$VNC_PORT (navegador)"
    echo ""
    echo "  💡 Dica: Coloque o autounattend.xml na raiz"
    echo "     da ISO do Windows 10 para instalação"
    echo "     automatizada."
    echo ""
    echo "  📋 Comandos úteis:"
    echo "     virsh shutdown $VM_NAME"
    echo "     virsh start    $VM_NAME"
    echo "     virsh destroy  $VM_NAME"
    echo "     virsh domstate $VM_NAME"
    echo "═══════════════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════
#  EXECUÇÃO
# ═══════════════════════════════════════════════════

main() {
    echo ""
    echo "╔═══════════════════════════════════════════════╗"
    echo "║     WindowsMaster — Build VM Base             ║"
    echo "║     Windows 10 22H2 + QEMU/KVM + VNC          ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""
    
    # Verifica se é root
    if [ "$(id -u)" -ne 0 ]; then
        echo "⚠️  Este script precisa de sudo para algumas operações."
        echo "   Relançando com sudo..."
        exec sudo "$0" "$@"
        exit 1
    fi
    
    verificar_dependencias
    verificar_kvm
    verificar_libvirtd
    verificar_iso
    verificar_virtio
    limpar_vm_antiga
    criar_disco
    criar_xml_vm
    
    iniciar_vm
}

main "$@"
