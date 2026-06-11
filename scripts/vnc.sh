#!/bin/bash
# ============================================================
# vnc.sh — Conecta ao VNC da VM WindowsMaster
# ============================================================
# Uso: ./scripts/vnc.sh [porta]
#   porta padrão: 5900
# ============================================================

PORT="${1:-5900}"

echo "🔗 Conectando ao VNC em localhost:$PORT..."

# Tenta vncviewer (TigerVNC)
if command -v vncviewer &>/dev/null; then
    vncviewer "localhost:$PORT" &
    exit 0
fi

# Tenta gvncviewer (GTK)
if command -v gvncviewer &>/dev/null; then
    gvncviewer "localhost:$PORT" &
    exit 0
fi

# Tenta vinagre
if command -v vinagre &>/dev/null; then
    vinagre "localhost:$PORT" &
    exit 0
fi

# Tenta remmina
if command -v remmina &>/dev/null; then
    remmina -c "vnc://localhost:$PORT" &
    exit 0
fi

echo ""
echo "❌ Nenhum cliente VNC encontrado."
echo "   Instale um: sudo pacman -S tigervnc"
echo ""
echo "   Ou acesse manualmente:"
echo "   vncviewer localhost:$PORT"
exit 1
