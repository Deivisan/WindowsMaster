#!/bin/bash
# ============================================================
# stop-vm.sh — Para a VM WindowsMaster
# ============================================================
# Uso: ./scripts/stop-vm.sh [--force]
#   --force: destroy em vez de shutdown graceful
# ============================================================

VM_NAME="winmaster-base"
FORCE="${1:-}"

echo "⏹️  Parando VM '$VM_NAME'..."

if [ "$FORCE" = "--force" ]; then
    sudo virsh destroy "$VM_NAME" 2>/dev/null && echo "✅ VM destruída (force)" || echo "⚠️  VM não estava rodando"
else
    sudo virsh shutdown "$VM_NAME" 2>/dev/null && echo "✅ Shutdown enviado à VM" || echo "⚠️  VM não estava rodando"
fi
