#!/bin/bash
# ============================================================
# start-vm.sh — Inicia a VM WindowsMaster
# ============================================================
# Uso: ./scripts/start-vm.sh
# ============================================================

VM_NAME="winmaster-base"

echo "▶️  Iniciando VM '$VM_NAME'..."

if ! systemctl is-active --quiet libvirtd 2>/dev/null; then
    echo "   Iniciando libvirtd..."
    sudo systemctl start libvirtd
    sleep 2
fi

if virsh list --all --name 2>/dev/null | grep -qx "$VM_NAME"; then
    sudo virsh start "$VM_NAME" 2>/dev/null && echo "✅ VM '$VM_NAME' iniciada"
else
    echo "❌ VM '$VM_NAME' não está definida. Execute primeiro: sudo ./scripts/build-vm.sh"
    exit 1
fi

# Mostra info de conexão
echo ""
echo "  📺 VNC: $(virsh domdisplay "$VM_NAME" 2>/dev/null || echo 'localhost:5900')"
echo "  🔗 vncviewer localhost:5900"
