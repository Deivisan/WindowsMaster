# ============================================================
# Aliases para WindowsMaster
# ============================================================
# Adicione ao seu ~/.zshrc ou ~/.bashrc:
#
#   source /home/deivi/Projetos/WindowsMaster/aliases.sh
# ============================================================

# ─── Alias principal: win10 ───
# Inicia visualização VNC otimizada da VM WindowsMaster
alias win10='cd /home/deivi/Projetos/WindowsMaster && ./scripts/vnc.sh'

# ─── Alias: win10-status ───
# Verifica status da VM
alias win10-status='sudo virsh domstate winmaster-base && sudo virsh domblklist winmaster-base'

# ─── Alias: win10-start ───
# Inicia a VM
alias win10-start='sudo virsh start winmaster-base && echo "✅ VM iniciada" && sleep 2 && win10-status'

# ─── Alias: win10-stop ───
# Para a VM (graceful shutdown)
alias win10-stop='sudo virsh shutdown winmaster-base && echo "⏸️  VM desligando..."'

# ─── Alias: win10-force-stop ───
# Força desligamento da VM
alias win10-force-stop='sudo virsh destroy winmaster-base && echo "⚠️  VM forçada a parar"'

# ─── Alias: win10-restart ───
# Reinicia a VM
alias win10-restart='sudo virsh reboot winmaster-base && echo "🔄 VM reiniciando..."'

# ─── Alias: win10-console ───
# Abre console serial (útil para debug)
alias win10-console='sudo virsh console winmaster-base'

# ─── Função: win10-info ───
# Mostra informações completas da VM
win10-info() {
    echo "═══════════════════════════════════════════════════"
    echo "  WindowsMaster VM Info"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "📊 Estado:"
    sudo virsh domstate winmaster-base 2>/dev/null || echo "  VM não definida"
    echo ""
    echo "💾 Discos:"
    sudo virsh domblklist winmaster-base 2>/dev/null || echo "  Indisponível"
    echo ""
    echo "🔌 Redes:"
    sudo virsh domifaddr winmaster-base 2>/dev/null || echo "  SLiRP (NAT) - IP não visível via libvirt"
    echo ""
    echo "📈 Recursos:"
    sudo virsh dominfo winmaster-base 2>/dev/null | grep -E "CPU|Memória|Tempo" || echo "  Indisponível"
    echo "═══════════════════════════════════════════════════"
}

# ─── Função: win10-logs ───
# Mostra logs do QEMU da VM
win10-logs() {
    echo "📜 Logs da VM (últimas 50 linhas):"
    echo ""
    sudo journalctl -u libvirtd -n 50 --no-pager 2>/dev/null | grep -i winmaster || echo "  Logs não disponíveis"
}

echo "✅ Aliases do WindowsMaster carregados!"
echo ""
echo "   Comandos disponíveis:"
echo "     win10              → Abre VNC otimizado"
echo "     win10-status       → Status da VM"
echo "     win10-start        → Inicia a VM"
echo "     win10-stop         → Desliga a VM"
echo "     win10-force-stop   → Força parada"
echo "     win10-restart      → Reinicia a VM"
echo "     win10-info         → Informações completas"
echo "     win10-logs         → Logs do QEMU"
echo ""
