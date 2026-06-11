#!/bin/bash
# ============================================================
# setup-ai-tools-disk.sh — Configura disco compartilhado A-I-Tools
# ============================================================
# Cria e monta disco X: dentro do Windows para trocar arquivos
# ============================================================

set -euo pipefail

VM_NAME="winmaster-base"
AI_TOOLS_PATH="/home/deivi/A-I-Tools"
AI_TOOLS_DISK="/var/lib/libvirt/images/ai-tools.qcow2"

echo "═══════════════════════════════════════════════════"
echo "  WindowsMaster — Configurando Disco A-I-Tools (X:)"
echo "═══════════════════════════════════════════════════"
echo ""

# ─── 1. Verificar/criar pasta no host ───
if [ ! -d "$AI_TOOLS_PATH" ]; then
    echo "📁 Criando pasta no host: $AI_TOOLS_PATH"
    mkdir -p "$AI_TOOLS_PATH"
fi
echo "✅ Pasta host: $AI_TOOLS_PATH"

# ─── 2. Verificar/criar disco QEMU ───
if [ ! -f "$AI_TOOLS_DISK" ]; then
    echo "💾 Criando disco QEMU: $AI_TOOLS_DISK (10GB)"
    sudo qemu-img create -f qcow2 "$AI_TOOLS_DISK" 10G
    sudo chown libvirt-qemu:kvm "$AI_TOOLS_DISK"
fi
echo "✅ Disco QEMU: $AI_TOOLS_DISK"

# ─── 3. Parar VM se estiver rodando ───
if sudo virsh list --name 2>/dev/null | grep -qx "$VM_NAME"; then
    echo "⏸️  Parando VM..."
    sudo virsh destroy "$VM_NAME" 2>/dev/null || true
    sleep 3
fi

# ─── 4. Backup do XML ───
XML_PATH="/etc/libvirt/qemu/$VM_NAME.xml"
BACKUP="$XML_PATH.bkp.$(date +%s)"
sudo cp "$XML_PATH" "$BACKUP"
echo "💾 Backup: $BACKUP"

# ─── 5. Modificar XML ───
echo "🔧 Configurando discos no XML..."

sudo python3 << 'PYEOF'
import re

xml_path = "/etc/libvirt/qemu/winmaster-base.xml"

with open(xml_path, 'r') as f:
    xml = f.read()

# Remover ISO do Windows 10 (cdrom com Win10)
xml = re.sub(
    r'<disk type=\'file\' device=\'cdrom\'>.*?<source file=\'/var/lib/libvirt/images/Win10[^>]+\.iso\'/>.*?</disk>\s*',
    '',
    xml,
    flags=re.DOTALL
)

# Verificar se já existe o disco ai-tools
if 'ai-tools.qcow2' not in xml:
    # Adicionar disco A-I-Tools (sdb) após o disco principal (sda)
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

print("✅ XML modificado com disco A-I-Tools")
PYEOF

# ─── 6. Redefinir e iniciar VM ───
echo "🔄 Redefinindo VM..."
sudo virsh define "$XML_PATH"

echo "▶️  Iniciando VM..."
sudo virsh start "$VM_NAME"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ DISCO A-I-TOOLS CONFIGURADO!"
echo ""
echo "  📀 Configuração:"
sudo virsh domblklist "$VM_NAME"
echo ""
echo "  💾 Host:  $AI_TOOLS_PATH"
echo "  💿 VM:    X: (A-I-Tools)"
echo ""
echo "  📦 E:     VirtIO Drivers (readonly)"
echo "═══════════════════════════════════════════════════"
