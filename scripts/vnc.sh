#!/bin/bash
# ============================================================
# vnc.sh — Conecta ao VNC da VM WindowsMaster
# ============================================================
# Uso: win10 [porta]
# ============================================================

PORT="${1:-5900}"

# Conectar
if command -v vncviewer &>/dev/null; then
    vncviewer -RemoteResize -AutoSelect "localhost:$PORT" &
elif command -v virt-viewer &>/dev/null; then
    virt-viewer --connect qemu:///system --auto-resize=always winmaster-base &
else
    echo "vncviewer ou virt-viewer não encontrado"
    exit 1
fi
