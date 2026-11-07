pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Estado compartilhado entre barra, busca e painéis.
Singleton {
    id: estado

    property bool buscaAberta: false
    property bool somAberto: false

    // Menu do botão direito de um app na barra
    property var menuToplevel: null
    property real menuX: 0
    property bool menuAberto: false

    function fecharTudo() {
        buscaAberta = false;
        somAberto = false;
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
}
