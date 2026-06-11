#!/bin/bash
# ============================================================
# configure-disks.sh — Configura discos da VM WindowsMaster
# ============================================================
# Remove ISO do Windows, adiciona disco A-I-Tools (X:)
# Mantém virtio-win.iso (E:)
# ============================================================

set -euo pipefail

VM_NAME="winmaster-base"
AI_TOOLS_DISK="/var/lib/libvirt/images/ai-tools.qcow2"

echo "═══════════════════════════════════════════════════"
echo "  Configurando discos da VM: $VM_NAME"
echo "═══════════════════════════════════════════════════"
echo ""

# ─── Parar VM ───
if sudo virsh list --name 2>/dev/null | grep -qx "$VM_NAME"; then
    echo "⏸️  Parando VM..."
    sudo virsh destroy "$VM_NAME" 2>/dev/null || true
    sleep 2
fi

# ─── Backup do XML ───
echo "💾 Backup do XML..."
sudo cp "/etc/libvirt/qemu/$VM_NAME.xml" "/etc/libvirt/qemu/$VM_NAME.xml.bkp.$(date +%s)"

# ─── Modificar XML ───
echo "🔧 Modificando configuração de discos..."

sudo python3 << 'PYEOF'
import re
import sys

xml_path = "/etc/libvirt/qemu/winmaster-base.xml"

with open(xml_path, 'r') as f:
    xml = f.read()

# 1. Remover a ISO do Windows 10 (cdrom com Win10)
xml = re.sub(
    r'<disk type=\'file\' device=\'cdrom\'>.*?<source file=\'/var/lib/libvirt/images/Win10[^>]+\.iso\'/>.*?</disk>\s*',
    '',
    xml,
    flags=re.DOTALL
)

# 2. Adicionar disco A-I-Tools (sdb) após o disco principal (sda)
# Encontrar o fechamento do disk sda e inserir após
ai_tools_disk = '''    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='writethrough' io='threads'/>
      <source file='/var/lib/libvirt/images/ai-tools.qcow2'/>
      <target dev='sdb' bus='sata'/>
      <address type='drive' controller='0' bus='0' target='0' unit='1'/>
    </disk>
'''

# Inserir após o fechamento do primeiro disk
xml = re.sub(
    r'(</disk>\s*)(\s*<disk type=\'file\' device=\'cdrom\'>)',
    r'\1' + ai_tools_disk + r'\2',
    xml,
    count=1
)

with open(xml_path, 'w') as f:
    f.write(xml)

print("✅ XML modificado")
PYEOF

echo ""
echo "🔄 Redefinindo VM..."
sudo virsh define "/etc/libvirt/qemu/$VM_NAME.xml"

echo ""
echo "▶️  Iniciando VM..."
sudo virsh start "$VM_NAME"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ DISCOS CONFIGURADOS!"
echo ""
echo "  📀 Configuração final:"
sudo virsh domblklist "$VM_NAME"
echo ""
echo "  💾 A-I-Tools (X:) → /var/lib/libvirt/images/ai-tools.qcow2"
echo "  📦 VirtIO (E:)    → /var/lib/libvirt/images/virtio-win.iso"
echo "═══════════════════════════════════════════════════"
