#!/bin/bash
# ============================================================
# vnc.sh — Conecta ao VNC da VM WindowsMaster
# ============================================================
# Uso: win10
# Inicia a VM automaticamente se estiver desligada
# ============================================================

VM_NAME="winmaster-base"
PORT=5900

# Verificar se VM existe
if ! sudo virsh list --all --name 2>/dev/null | grep -qx "$VM_NAME"; then
    echo "❌ VM '$VM_NAME' não existe"
    exit 1
fi

# Verificar se VM está rodando
if ! sudo virsh list --name 2>/dev/null | grep -qx "$VM_NAME"; then
    echo "▶️  Iniciando VM '$VM_NAME'..."
    sudo virsh start "$VM_NAME" >/dev/null 2>&1
    
    # Aguardar VNC ficar disponível (máx 30s)
    for i in {1..30}; do
        if sudo netstat -tlnp 2>/dev/null | grep -q ":$PORT " || sudo ss -tlnp | grep -q ":$PORT "; then
            break
        fi
        sleep 1
    done
    sleep 2
fi

# Conectar
if command -v vncviewer &>/dev/null; then
    vncviewer -RemoteResize -AutoSelect "localhost:$PORT" >/dev/null 2>&1 &
elif command -v virt-viewer &>/dev/null; then
    virt-viewer --connect qemu:///system --auto-resize=always "$VM_NAME" >/dev/null 2>&1 &
else
    echo "❌ Nenhum cliente VNC encontrado"
    exit 1
fi
