#!/bin/bash
# ============================================================
# vnc.sh — Conecta ao VNC da VM WindowsMaster (otimizado)
# ============================================================
# Uso: ./scripts/vnc.sh [porta]
#   porta padrão: 5900
#
# Funcionalidades:
# - Alias "win10" disponível após source
# - Auto-ajuste de resolução (fullscreen + resize)
# - Suporte a múltiplos clientes VNC
# ============================================================

PORT="${1:-5900}"
VNC_HOST="localhost"

# Cores
AZUL='\033[0;34m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
RESET='\033[0m'

info()  { echo -e "${AZUL}[INFO]${RESET} $1"; }
ok()    { echo -e "${VERDE}[OK]${RESET}   $1"; }
aviso() { echo -e "${AMARELO}[AVISO]${RESET} $1"; }

# ─── Verificar se VM está rodando ───
if ! sudo virsh list --name 2>/dev/null | grep -qx "winmaster-base"; then
    echo ""
    echo "❌ VM 'winmaster-base' não está rodando."
    echo "   Inicie com: sudo virsh start winmaster-base"
    echo ""
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "  🖥️  WindowsMaster — Conexão VNC"
echo "═══════════════════════════════════════════════════"
echo ""
info "Conectando ao VNC em ${VNC_HOST}:${PORT}..."
echo ""

# ─── Opção 1: TigerVNC (melhor suporte a resize) ───
if command -v vncviewer &>/dev/null; then
    ok "Usando TigerVNC (vncviewer)"
    echo ""
    echo "  📺 Controles úteis:"
    echo "     F8          → Menu de opções"
    echo "     F8 → Fullscreen → Alterna tela cheia"
    echo "     F8 → Options  → Ajuste de qualidade/velocidade"
    echo "     Ctrl+Alt+←  → Sair do fullscreen"
    echo ""
    echo "  💡 Dica: No menu F8, ative 'Resize remote session to local window'"
    echo "     para auto-ajuste de resolução!"
    echo ""
    
    # TigerVNC com opções otimizadas
    vncviewer \
        -RemoteResize \
        -AutoSelect \
        -CompressLevel=6 \
        -QualityLevel=7 \
        "${VNC_HOST}:${PORT}" &
    
    exit 0
fi

# ─── Opção 2: virt-viewer (melhor integração com libvirt) ───
if command -v virt-viewer &>/dev/null; then
    ok "Usando virt-viewer (melhor integração)"
    echo ""
    virt-viewer \
        --connect qemu:///system \
        --fullscreen \
        --auto-resize=always \
        winmaster-base &
    exit 0
fi

# ─── Opção 3: spicy (Spice - melhor performance + clipboard) ───
if command -v spicy &>/dev/null; then
    aviso "VNC não encontrado. Usando Spice (spicy)..."
    echo ""
    echo "  ⚠️  Nota: Spice usa porta diferente (geralmente 5900 também)"
    echo "     Mas clipboard funciona automaticamente!"
    echo ""
    spicy -h "${VNC_HOST}" -p "${PORT}" &
    exit 0
fi

# ─── Fallback ───
echo ""
echo "❌ Nenhum cliente VNC/Spice encontrado."
echo ""
echo "   Instale um dos seguintes:"
echo "     sudo pacman -S tigervnc      # TigerVNC (recomendado)"
echo "     sudo pacman -S virt-viewer   # Virt-viewer"
echo "     sudo pacman -S spice-gtk     # Spicy (Spice)"
echo ""
echo "   Ou conecte manualmente:"
echo "     vncviewer ${VNC_HOST}:${PORT}"
echo ""
exit 1
