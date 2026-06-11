#!/bin/bash
# ============================================================
# prepare-autounattend.sh — Prepara ISO do Win10 com autounattend
# ============================================================
# Cria uma ISO customizada do Windows 10 já com o autounattend.xml
# injetado, para instalação 100% automatizada.
#
# Uso: sudo ./scripts/prepare-autounattend.sh
# ============================================================
# Requer: mkisofs/genisoimage ou xorriso
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ISO_DIR="$REPO_DIR/iso"
AUTOUNAttEND_DIR="$REPO_DIR/autounattend"

# ─── Verifica dependências ───
for cmd in xorriso mkisofs genisoimage; do
    if command -v "$cmd" &>/dev/null; then
        MKISO="$cmd"
        break
    fi
done

if [ -z "${MKISO:-}" ]; then
    echo "❌ Nenhuma ferramenta de criação de ISO encontrada."
    echo "   Instale: sudo pacman -S xorriso"
    exit 1
fi

# ─── ISO original ───
WIN_ISO=$(ls "$ISO_DIR"/*.iso 2>/dev/null | head -1)
if [ -z "$WIN_ISO" ]; then
    echo "❌ ISO do Windows 10 não encontrada em $ISO_DIR/"
    echo "   Baixe primeiro com: sudo ./scripts/download-iso.sh"
    exit 1
fi

# ─── autounattend.xml ───
AUTOUNAttEND="$AUTOUNAttEND_DIR/autounattend.xml"
if [ ! -f "$AUTOUNAttEND" ]; then
    echo "❌ autounattend.xml não encontrado em $AUTOUNAttEND_DIR/"
    exit 1
fi

# ─── Diretório de trabalho ───
WORKDIR=$(mktemp -d)
OUTPUT_ISO="$ISO_DIR/Win10_22H2_Automatizado.iso"

echo "═══════════════════════════════════════════════════"
echo "  Preparando ISO com instalação automatizada"
echo "═══════════════════════════════════════════════════"
echo "  ISO fonte:      $(basename "$WIN_ISO")"
echo "  autounattend:   autounattend.xml"
echo "  ISO destino:    $(basename "$OUTPUT_ISO")"
echo ""

# ─── Monta a ISO original ───
echo "📂 Montando ISO original..."
sudo mount -o loop "$WIN_ISO" "$WORKDIR/mnt" 2>/dev/null || {
    mkdir -p "$WORKDIR/mnt"
    fuseiso "$WIN_ISO" "$WORKDIR/mnt" 2>/dev/null || {
        echo "❌ Não foi possível montar a ISO."
        echo "   Tentando extrair com 7z..."
        mkdir -p "$WORKDIR/extract"
        7z x "$WIN_ISO" -o"$WORKDIR/extract" >/dev/null 2>&1 || {
            echo "❌ Falha ao extrair ISO. Faça manualmente:"
            echo "  1. Copie autounattend.xml para a raiz do pendrive/ISO"
            echo ""
            echo "  O autounattend.xml está em: $AUTOUNAttEND"
            sudo rm -rf "$WORKDIR"
            exit 1
        }
        cp "$AUTOUNAttEND" "$WORKDIR/extract/autounattend.xml"
        
        # Reconstrói a ISO
        echo "📀 Reconstruindo ISO com autounattend..."
        cd "$WORKDIR/extract"
        if [ "$MKISO" = "xorriso" ]; then
            xorriso -as mkisofs \
                -iso-level 3 \
                -full-iso9660-filenames \
                -volid "WINDOWS_MASTER" \
                -eltorito-boot boot/etfsboot.com \
                -eltorito-catalog boot.catalog \
                -no-emul-boot \
                -boot-load-size 8 \
                -boot-info-table \
                -eltorito-alt-boot \
                -e efi/microsoft/boot/efisys.bin \
                -no-emul-boot \
                -o "$OUTPUT_ISO" .
        else
            $MKISO -o "$OUTPUT_ISO" \
                -b boot/etfsboot.com \
                -no-emul-boot \
                -boot-load-size 8 \
                -boot-info-table \
                -eltorito-alt-boot \
                -e efi/microsoft/boot/efisys.bin \
                -no-emul-boot \
                -V "WINDOWS_MASTER" \
                .
        fi
        
        cd "$REPO_DIR"
        sudo rm -rf "$WORKDIR"
        echo ""
        echo "✅ ISO criada: $OUTPUT_ISO"
        echo "   Tamanho: $(du -h "$OUTPUT_ISO" | cut -f1)"
        exit 0
    }
}

# ─── Se montou com sucesso, copia os arquivos ───
echo "📋 Copiando arquivos da ISO..."
mkdir -p "$WORKDIR/extract"
cp -r "$WORKDIR/mnt/"* "$WORKDIR/extract/" 2>/dev/null || sudo cp -r "$WORKDIR/mnt/"* "$WORKDIR/extract/"
sudo umount "$WORKDIR/mnt" 2>/dev/null || fusermount -u "$WORKDIR/mnt" 2>/dev/null || true

# ─── Injeta autounattend.xml ───
echo "📝 Injetando autounattend.xml..."
cp "$AUTOUNAttEND" "$WORKDIR/extract/autounattend.xml"

# ─── Reconstrói ISO ───
echo "📀 Reconstruindo ISO..."
cd "$WORKDIR/extract"

if [ "$MKISO" = "xorriso" ]; then
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "WINDOWS_MASTER" \
        -eltorito-boot boot/etfsboot.com \
        -eltorito-catalog boot.catalog \
        -no-emul-boot \
        -boot-load-size 8 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e efi/microsoft/boot/efisys.bin \
        -no-emul-boot \
        -o "$OUTPUT_ISO" \
        .
else
    $MKISO -o "$OUTPUT_ISO" \
        -b boot/etfsboot.com \
        -no-emul-boot \
        -boot-load-size 8 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e efi/microsoft/boot/efisys.bin \
        -no-emul-boot \
        -V "WINDOWS_MASTER" \
        .
fi

cd "$REPO_DIR"

# ─── Limpeza ───
sudo rm -rf "$WORKDIR"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ ISO com instalação automatizada criada!"
echo ""
echo "  📀 $OUTPUT_ISO"
echo "     Tamanho: $(du -h "$OUTPUT_ISO" | cut -f1)"
echo ""
echo "  Use esta ISO no lugar da original para instalação"
echo "  automática do Windows 10 com as configurações"
echo "  do WindowsMaster."
echo "═══════════════════════════════════════════════════"
