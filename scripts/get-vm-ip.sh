#!/bin/bash
# ============================================================
# get-vm-ip.sh — Descobre o IP da VM Windows
# ============================================================
# Funciona com SLiRP (NAT) — mostra o IP interno da VM
# ============================================================

VM_NAME="${1:-winmaster-base}"

echo "═══════════════════════════════════════════════════"
echo "  Descobrindo IP da VM: $VM_NAME"
echo "═══════════════════════════════════════════════════"
echo ""

# ─── Tenta via libvirt (se bridged) ───
IP=$(sudo virsh domifaddr "$VM_NAME" 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)

if [ -n "$IP" ]; then
    echo "✅ IP encontrado via libvirt: $IP"
    exit 0
fi

# ─── Com SLiRP (NAT), a VM aparece como 10.0.2.x ───
echo "⚠️  VM usa SLiRP (NAT) — IP interno: 10.0.2.x"
echo ""
echo "Para descobrir o IP exato:"
echo "  1. Abra o VNC da VM"
echo "  2. Execute no CMD/PowerShell:"
echo "     ipconfig"
echo "  3. Procure o adaptador 'Ethernet' ou 'Ethernet adapter'"
echo ""
echo "Ou use o QEMU Guest Agent (se instalado):"
echo "  sudo virsh qemu-agent-command $VM_NAME --cmd '{\"execute\":\"guest-network-get-interfaces\"}'"
echo "═══════════════════════════════════════════════════"
