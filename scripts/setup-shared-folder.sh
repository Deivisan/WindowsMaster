#!/bin/bash
# ============================================================
# setup-shared-folder.sh — Configura pasta shared/ no Windows
# ============================================================
# Monta WindowsMaster/shared/ dentro do Windows via VirtIO-9P
# ============================================================

set -euo pipefail

VM_NAME="winmaster-base"
SHARE_PATH="/home/deivi/Projetos/WindowsMaster/shared"
SHARE_NAME="shared"
XML_PATH="/etc/libvirt/qemu/$VM_NAME.xml"

echo "═══════════════════════════════════════════════════"
echo "  Configurando Pasta Compartilhada: shared/"
echo "═══════════════════════════════════════════════════"
echo ""

if [ ! -d "$SHARE_PATH" ]; then
    echo "❌ Pasta $SHARE_PATH não existe"
    exit 1
fi
echo "✅ Pasta: $SHARE_PATH"

if sudo virsh list --name 2>/dev/null | grep -qx "$VM_NAME"; then
    echo "⏸️  Parando VM..."
    sudo virsh destroy "$VM_NAME" 2>/dev/null || true
    sleep 3
fi

BACKUP="$XML_PATH.bkp.$(date +%s)"
sudo cp "$XML_PATH" "$BACKUP"
echo "💾 Backup: $BACKUP"

echo "🔧 Adicionando VirtIO-9P ao XML..."

sudo python3 << PYEOF
import re

with open("$XML_PATH", 'r') as f:
    xml = f.read()

if 'shared' in xml and 'filesystem' in xml:
    print("⚠️  Já configurado")
else:
    fs_9p = '''
    <!-- Pasta compartilhada shared/ (X:) via VirtIO-9P -->
    <filesystem type='mount' accessmode='mapped'>
      <driver type='path' wrpolicy='immediate'/>
      <source dir='$SHARE_PATH'/>
      <target dir='$SHARE_NAME'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
    </filesystem>
'''
    xml = re.sub(
        r'(</disk>\s*)(\s*<controller type=\'usb\')',
        r'\1' + fs_9p + r'\2',
        xml,
        count=1
    )
    
    with open("$XML_PATH", 'w') as f:
        f.write(xml)
    print("✅ VirtIO-9P adicionado")
PYEOF

echo "🔄 Redefinindo VM..."
sudo virsh define "$XML_PATH"

echo "▶️  Iniciando VM..."
sudo virsh start "$VM_NAME"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ PASTA COMPARTILHADA CONFIGURADA!"
echo ""
echo "  📂 Host:  $SHARE_PATH"
echo "  💿 VM:    \\\\10.0.2.2\\$SHARE_NAME"
echo ""
echo "  📝 No Windows:"
echo "     net use X: \\\\10.0.2.2\\$SHARE_NAME"
echo ""
echo "  📜 Scripts: X:\\scripts\\"
echo "═══════════════════════════════════════════════════"
