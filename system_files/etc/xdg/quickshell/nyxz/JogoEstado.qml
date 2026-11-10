pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Se o Modo jogo e o replay estão ligados (para a barra e o painel rápido).
// Os scripts marcam isso com arquivos na pasta temporária da sessão:
//   $XDG_RUNTIME_DIR/nyxz-modo-jogo.json   (modo-jogo)
//   $XDG_RUNTIME_DIR/nyxz-replay-ativo     (serviço nyxz-replay)
Singleton {
    readonly property string pasta: Quickshell.env("XDG_RUNTIME_DIR")
    property bool modoJogo: false
    property bool replay: false

    FileView {
        id: jogo
        printErrors: false   // o caminho é definido no Component.onCompleted
        onLoaded: modoJogo = true
        onLoadFailed: modoJogo = false
    }
    FileView {
        id: gravando
        printErrors: false
        onLoaded: replay = true
        onLoadFailed: replay = false
    }
    Component.onCompleted: {
        jogo.path = pasta + "/nyxz-modo-jogo.json";
        gravando.path = pasta + "/nyxz-replay-ativo";
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: { jogo.reload(); gravando.reload(); }
    }

    function alternarModoJogo() {
        Quickshell.execDetached(["/usr/libexec/nyxz/modo-jogo", modoJogo ? "desligar" : "ligar"]);
        modoJogo = !modoJogo;
    }
    function alternarReplay() {
        Quickshell.execDetached(["/usr/libexec/nyxz/replay", replay ? "desligar" : "ligar"]);
        replay = !replay;
    }
    function salvarReplay() {
        Quickshell.execDetached(["/usr/libexec/nyxz/replay", "salvar"]);
    }
}
