#!/bin/bash
# ============================================================
# enable-clipboard-spice.sh — Habilita Spice + Clipboard
# ============================================================
# Substitui VNC por Spice para habilitar copiar/colar
# Requer: spice-protocol, qemu-guest-agent
# ============================================================

set -euo pipefail

VM_NAME="winmaster-base"

echo "═══════════════════════════════════════════════════"
echo "  Habilitando Spice + Clipboard na VM"
echo "═══════════════════════════════════════════════════"
echo ""

# ─── Verificar se VM existe ───
if ! sudo virsh list --all --name 2>/dev/null | grep -qx "$VM_NAME"; then
    echo "❌ VM '$VM_NAME' não encontrada"
    exit 1
fi

# ─── Parar VM se estiver rodando ───
if sudo virsh list --name 2>/dev/null | grep -qx "$VM_NAME"; then
    echo "⏸️  Parando VM..."
    sudo virsh shutdown "$VM_NAME" 2>/dev/null || true
    
    # Aguardar shutdown (máx 30s)
    for i in {1..30}; do
        if ! sudo virsh list --name 2>/dev/null | grep -qx "$VM_NAME"; then
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

# ─── Fazer backup do XML atual ───
echo "💾 Fazendo backup do XML..."
sudo cp "/etc/libvirt/qemu/$VM_NAME.xml" "/etc/libvirt/qemu/$VM_NAME.xml.bkp.$(date +%Y%m%d-%H%M%S)"

# ─── Modificar XML para usar Spice ───
echo "🔧 Configurando Spice + Clipboard..."

# Criar novo XML com Spice
sudo python3 << 'PYTHON'
import sys
import re

xml_path = "/etc/libvirt/qemu/winmaster-base.xml"

with open(xml_path, 'r') as f:
    xml = f.read()

# Substituir VNC por Spice
xml = re.sub(
    r'<graphics type=\'vnc\'[^/]*/>',
    '''<graphics type='spice' port='5900' autoport='no' listen='0.0.0.0'>
      <listen type='address' address='0.0.0.0'/>
      <image compression='off'/>
    </graphics>
    <sound model='ich6'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
    </sound>
    <video>
      <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='2'/>
    </channel>''',
    xml
)

# Adicionar channel de clipboard se não existir
if 'spicevmc' not in xml:
    # Adicionar após o channel do QEMU GA
    xml = re.sub(
        r'(</channel>)',
        r'''\1
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='2'/>
    </channel>''',
        xml,
        count=1
    )

with open(xml_path, 'w') as f:
    f.write(xml)

print("✅ XML modificado com Spice + QXL + Clipboard channel")
PYTHON

echo ""
echo "🔄 Redefinindo VM..."
sudo virsh define "/etc/libvirt/qemu/$VM_NAME.xml"

echo ""
echo "▶️  Iniciando VM..."
sudo virsh start "$VM_NAME"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ Spice + Clipboard HABILITADO!"
echo ""
echo "  📺 Agora use SPICY (cliente Spice) para conectar:"
echo "     spicy -h localhost -p 5900"
echo ""
echo "  ✂️  Copiar/Colar vai funcionar automaticamente!"
echo "     Ctrl+C / Ctrl+V normal"
echo ""
echo "  📦 No Windows, instale os Spice Guest Tools:"
echo "     https://www.spice-space.org/download.html"
echo "     (ou baixe virtio-win.iso e instale spice-vdagent)"
echo "═══════════════════════════════════════════════════"
