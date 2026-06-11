#!/bin/bash
# ============================================================
# download-iso.sh — Baixa a última ISO do Windows 10 22H2
# ============================================================
# Baixa a ISO oficial do Windows 10 (22H2, última build)
# em português brasileiro diretamente da Microsoft.
#
# Uso: ./download-iso.sh [idioma]
#   idioma opcional: pt-br (padrão), en-us, etc.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ISO_DIR="$REPO_DIR/iso"
DESTINO="$ISO_DIR"

LANG="${1:-pt-br}"

mkdir -p "$ISO_DIR"

echo "═══════════════════════════════════════════════════"
echo "  Windows 10 22H2 — Download da ISO"
echo "═══════════════════════════════════════════════════"
echo "  Idioma:          $LANG"
echo "  Destino:         $DESTINO"
echo "  Build base:      19045 (22H2)"
echo "  Build recente:   19045.7417 (KB5094127 — jun/2026)"
echo ""

# ─── Verifica se já existe ISO baixada ───
ISO_EXISTENTE=$(ls "$ISO_DIR"/*.iso 2>/dev/null | head -1)
if [ -n "$ISO_EXISTENTE" ]; then
    echo "⚠️  ISO já existe em: $ISO_EXISTENTE"
    echo "   Tamanho: $(du -h "$ISO_EXISTENTE" | cut -f1)"
    echo ""
    echo "   Deseja baixar novamente? (s/N) "
    read -r resp
    if [ "$resp" != "s" ] && [ "$resp" != "S" ]; then
        echo "✅ Usando ISO existente."
        echo "$ISO_EXISTENTE"
        exit 0
    fi
fi

# ─── Verifica dependências ───
for cmd in curl wget; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ $cmd não encontrado. Instale com: sudo pacman -S $cmd"
        exit 1
    fi
done

# ─── Tenta 3 métodos de download ───

metodo_1_ms_api() {
    echo "📡 Método 1: API oficial da Microsoft..."
    
    # Mapeamento de idioma para ID da Microsoft
    local lang_id=""
    case "$LANG" in
        pt-br|pt_BR|portuguese|"português brasileiro") lang_id="Brazilian Portuguese" ;;
        en-us|en_US|english) lang_id="English International" ;;
        en-usa|"en us") lang_id="English (United States)" ;;
        *) lang_id="$LANG" ;;
    esac
    
    # A API da Microsoft para download de ISO do Windows 10
    # Funciona: pega o link direto via API pública
    local api_url="https://www.microsoft.com/software-download/api/GetWindows10ProductDownload"
    local session_id=$(curl -s "$api_url" | grep -oP '"SessionId":"[^"]+"' | cut -d'"' -f4 2>/dev/null || echo "")
    
    if [ -z "$session_id" ]; then
        echo "   ⚠️  API não retornou session id. Pulando..."
        return 1
    fi
    
    echo "   Session ID: $session_id"
    
    # Segundo request: obter links de download
    local download_url="https://www.microsoft.com/software-download/api/GetWindows10ProductDownloadByLanguage"
    local response=$(curl -s -X POST "$download_url" \
        -H "Content-Type: application/json" \
        -d "{\"language\":\"$lang_id\",\"sessionId\":\"$session_id\"}")
    
    local iso_link=$(echo "$response" | grep -oP 'https://[^"]+\.iso' | head -1)
    
    if [ -z "$iso_link" ]; then
        echo "   ⚠️  Link ISO não encontrado na resposta. Pulando..."
        return 1
    fi
    
    local nome_arquivo=$(basename "$iso_link" | sed 's/?.*//')
    [ -z "$nome_arquivo" ] && nome_arquivo="Win10_22H2_${LANG}_x64.iso"
    
    echo "   Link obtido: $iso_link"
    echo "   Arquivo: $nome_arquivo"
    echo ""
    echo "   Baixando... (isso pode levar alguns minutos)"
    
    wget -c -O "$ISO_DIR/$nome_arquivo" "$iso_link" --show-progress
    
    if [ -f "$ISO_DIR/$nome_arquivo" ]; then
        echo "✅ Download concluído: $ISO_DIR/$nome_arquivo"
        du -h "$ISO_DIR/$nome_arquivo"
        return 0
    fi
    
    return 1
}

metodo_2_pagina_direta() {
    echo "📡 Método 2: Página oficial de download..."
    
    local url="https://www.microsoft.com/pt-br/software-download/windows10ISO"
    local tmp_html=$(mktemp)
    
    curl -sL "$url" -o "$tmp_html"
    
    if grep -q "download" "$tmp_html" 2>/dev/null; then
        # Tenta extrair link direto 64 bits português
        local edition="windows-10-22h2"
        local link=$(curl -s "https://www.microsoft.com/software-download/api/GetWindows10ProductDownload" | \
            grep -oP '"DownloadUrl":"[^"]+64[^"]*"' | head -1 | sed 's/"DownloadUrl":"//;s/"//' 2>/dev/null)
        
        if [ -n "$link" ]; then
            local nome="Win10_22H2_${LANG}_x64.iso"
            echo "   Link: $link"
            wget -c -O "$ISO_DIR/$nome" "$link" --show-progress && return 0
        fi
    fi
    
    rm -f "$tmp_html"
    return 1
}

metodo_3_fido() {
    echo "📡 Método 3: Fido (Fido is a tool to download Windows ISOs from Linux)..."
    
    local fido_url="https://raw.githubusercontent.com/pbatard/Fido/master/Fido.sh"
    local fido_script="$ISO_DIR/.Fido.sh"
    
    echo "   Baixando Fido..."
    curl -sL "$fido_url" -o "$fido_script"
    
    if [ ! -s "$fido_script" ]; then
        echo "   ⚠️  Não foi possível baixar o Fido. Pulando..."
        rm -f "$fido_script"
        return 1
    fi
    
    chmod +x "$fido_script"
    
    echo "   Executando Fido para baixar Windows 10 22H2 ${LANG}..."
    echo "   (Siga as instruções interativas do Fido)"
    
    # Fido é interativo, então damos opção ao usuário
    echo ""
    echo "   ⚠️  O Fido é interativo. Deseja executá-lo manualmente depois?"
    echo "      Execute: bash $fido_script"
    echo ""
    echo "   Por enquanto, pulamos esse método automático."
    rm -f "$fido_script"
    return 1
}

# ─── Executa métodos em ordem ───
echo ""
metodo_1_ms_api && { echo ""; echo "✅ ISO pronta!"; exit 0; }
echo ""
metodo_2_pagina_direta && { echo ""; echo "✅ ISO pronta!"; exit 0; }
echo ""
metodo_3_fido && { echo ""; echo "✅ ISO pronta!"; exit 0; }

# ─── Se nenhum funcionou ───
echo ""
echo "═══════════════════════════════════════════════════"
echo "  ❌ Nenhum método automático funcionou."
echo ""
echo "  Baixe manualmente a ISO do Windows 10 22H2 em:"
echo "  https://www.microsoft.com/pt-br/software-download/windows10ISO"
echo ""
echo "  Selecione:"
echo "    - Edição: Windows 10 (22H2)"
echo "    - Idioma: Português Brasileiro"
echo "    - Arquitetura: 64 bits"
echo ""
echo "  Depois coloque o arquivo .iso em:"
echo "    $ISO_DIR/"
echo ""
echo "  Alternativa via Fido (Linux):"
echo "    curl -sL https://raw.githubusercontent.com/pbatard/Fido/master/Fido.sh | bash"
echo "═══════════════════════════════════════════════════"
exit 1
