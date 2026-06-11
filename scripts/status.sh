#!/bin/bash
# ============================================================
# status.sh — Status da VM WindowsMaster
# ============================================================
# Uso: ./scripts/status.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VM_NAME="winmaster-base"

echo "═══════════════════════════════════════════════════"
echo "  📊 Status — WindowsMaster VM"
echo "═══════════════════════════════════════════════════"

# Status da VM
ESTADO=$(virsh domstate "$VM_NAME" 2>/dev/null || echo "não definida")
echo ""
echo "  VM:       $VM_NAME"
echo "  Estado:   $ESTADO"

if [ "$ESTADO" = "running" ]; then
    # Info de conexão
    echo ""
    echo "  📺 VNC:"
    virsh domdisplay "$VM_NAME" 2>/dev/null | sed 's/^/     /'
    
    # IP da máquina (se tiver guest agent)
    IP=$(virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    if [ -n "$IP" ]; then
        echo "  🌐 IP:      $IP"
    fi
    
    # RAM e CPU
    echo ""
    echo "  📈 Recursos:"
    virsh dominfo "$VM_NAME" 2>/dev/null | grep -E 'CPU|Memória|Memory' | sed 's/^/     /'
fi

# Disco
DISCO="/var/lib/libvirt/images/$VM_NAME.qcow2"
if [ -f "$DISCO" ]; then
    echo ""
    echo "  💾 Disco:"
    qemu-img info "$DISCO" 2>/dev/null | grep -E 'virtual size|disk size' | sed 's/^/     /'
fi

# Libvirt
echo ""
echo "  🔧 libvirtd: $(systemctl is-active libvirtd 2>/dev/null || echo 'inativo')"

echo ""
echo "═══════════════════════════════════════════════════"
