#!/bin/bash
# ============================================================
# test-connectivity.sh — Testa conectividade com a VM
# ============================================================
# Uso: ./scripts/test-connectivity.sh <IP-DA-VM>
# Ex:  ./scripts/test-connectivity.sh 10.0.2.15
# ============================================================

set -euo pipefail

VM_IP="${1:-}"

if [ -z "$VM_IP" ]; then
    echo "Uso: $0 <IP-DA-VM>"
    echo "Ex:  $0 10.0.2.15"
    exit 1
fi

echo "═══════════════════════════════════════════════════"
echo "  Testando conectividade com $VM_IP"
echo "═══════════════════════════════════════════════════"
echo ""

# ─── Ping ───
echo "📡 Ping..."
if ping -c 2 -W 2 "$VM_IP" &>/dev/null; then
    echo "  ✅ Ping OK"
else
    echo "  ❌ Ping FALHOU"
fi
echo ""

# ─── WinRM (HTTP 5985) ───
echo "🔧 WinRM (porta 5985)..."
if timeout 3 bash -c "echo > /dev/tcp/$VM_IP/5985" 2>/dev/null; then
    echo "  ✅ Porta 5985 ABERTA"
else
    echo "  ❌ Porta 5985 FECHADA"
fi
echo ""

# ─── RDP (porta 3389) ───
echo "🖥️  RDP (porta 3389)..."
if timeout 3 bash -c "echo > /dev/tcp/$VM_IP/3389" 2>/dev/null; then
    echo "  ✅ Porta 3389 ABERTA"
else
    echo "  ❌ Porta 3389 FECHADA"
fi
echo ""

# ─── SSH (porta 22) - se tiver OpenSSH instalado ───
echo "🔐 SSH (porta 22)..."
if timeout 3 bash -c "echo > /dev/tcp/$VM_IP/22" 2>/dev/null; then
    echo "  ✅ Porta 22 ABERTA"
else
    echo "  ❌ Porta 22 FECHADA (normal se OpenSSH não estiver instalado)"
fi
echo ""

echo "═══════════════════════════════════════════════════"
echo "  Dica: Use 'nmap $VM_IP' para scan completo"
echo "═══════════════════════════════════════════════════"
