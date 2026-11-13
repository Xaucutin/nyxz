pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Estado compartilhado entre barra, busca e painéis.
Singleton {
    id: estado

    property bool buscaAberta: false
    property bool somAberto: false
    property bool rapidoAberto: false
    property bool atalhosAberto: false

    // Não perturbe: as notificações ficam guardadas e aparecem quando desligar.
    // O manual (painel) e o do Modo jogo são separados: um não desliga o outro.
    property bool naoPerturbeManual: false
    property bool naoPerturbeJogo: false
    // O modo streamer também guarda as notificações (aparecem depois, no histórico)
    readonly property bool naoPerturbe: naoPerturbeManual || naoPerturbeJogo || Streamer.ocultaNotificacoes

    // Menu do botão direito de um app na barra
    property var menuToplevel: null
    property real menuX: 0
    property bool menuAberto: false

    function fecharTudo() {
        buscaAberta = false;
        somAberto = false;
        rapidoAberto = false;
        atalhosAberto = false;
        menuAberto = false;
    }

    // O Hyprland 0.57 em modo Lua recebe comandos como expressões Lua.
    function despachar(lua, classico) {
        Hyprland.dispatch(Hyprland.usingLua ? lua : classico);
    }

    function irParaWorkspace(n) {
        despachar("hl.dsp.focus({ workspace = " + n + " })", "workspace " + n);
    }

    function abrirApp(entrada) {
        // Cada app no seu próprio escopo do systemd (ARQUITETURA.md, 2.1).
        Quickshell.execDetached(["nyx", "run", entrada.id + ".desktop"]);
    }

    function executar(comando) {
        Quickshell.execDetached(comando);
    }

    // Ajuste "Remove Taskbar Window Suffixes": tira o nome do app do fim do título
    // ("Página — Brave" → "Página"). Vale para prévias e menus.
    readonly property var sufixos: [
        / [—–-] Brave$/, / [—–-] Mozilla Firefox$/, / [—–-] Visual Studio Code$/,
        / [—–-] Dolphin$/, / [—–-] Discord$/, / [—–-] Vesktop$/, / [—–-] Ghostty$/
    ]
    function tituloLimpo(t) {
        let s = t || "";
        if (!Ajustes.titulosLimpos) return s;
        for (const r of sufixos) s = s.replace(r, "");
        return s;
    }

    // Janela minimizada (special:minimizado) volta para a área atual; as outras só ganham foco
    function hyprDe(t) {
        Hyprland.refreshToplevels();
        return Hyprland.toplevels.values.find(x => x.wayland === t) || null;
    }
    function hx(h) { return "0x" + String(h.address).replace(/^0x/, ""); }
    function restaurarOuAtivar(t) {
        const h = hyprDe(t);
        const ws = h && h.workspace ? h.workspace.name : "";
        if (ws === "special:minimizado" && Hyprland.focusedWorkspace) {
            Hyprland.dispatch("hl.dsp.window.move({ workspace = " + Hyprland.focusedWorkspace.id + ", window = 'address:" + hx(h) + "', follow = true })");
            Hyprland.dispatch("hl.dsp.focus({ window = 'address:" + hx(h) + "' })");
        } else t.activate();
    }
    function minimizar(t) {
        const h = hyprDe(t);
        if (h) Hyprland.dispatch("hl.dsp.window.move({ workspace = 'special:minimizado', window = 'address:" + hx(h) + "', follow = false })");
    }
    function maximizar(t) {
        const h = hyprDe(t);
        if (h) Hyprland.dispatch("hl.dsp.window.fullscreen({ mode = 'maximized', action = 'toggle', window = 'address:" + hx(h) + "' })");
    }
    // Botão "minimizar" desenhado pelo próprio app (GTK, Electron…): o Hyprland só avisa
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name !== "minimized") return;
            const p = ev.data.split(",");
            if (p[1] === "1") Hyprland.dispatch("hl.dsp.window.move({ workspace = 'special:minimizado', window = 'address:0x" + p[0] + "', follow = false })");
        }
    }
}
