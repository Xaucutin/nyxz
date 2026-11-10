pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Se o Modo jogo e o replay estão ligados (para a barra e o painel rápido).
// Os scripts marcam isso com arquivos na pasta temporária da sessão:
//   $XDG_RUNTIME_DIR/nyxz-modo-jogo.json   (modo-jogo)
//   $XDG_RUNTIME_DIR/nyxz-replay-ativo     (serviço nyxz-replay)
//   $XDG_RUNTIME_DIR/nyxz-streaming-ativo  (serviço nyxz-streaming, Sunshine)
//   $XDG_RUNTIME_DIR/nyxz-share-ativo      (Nyxz Share transmitindo)
Singleton {
    readonly property string pasta: Quickshell.env("XDG_RUNTIME_DIR")
    property bool modoJogo: false
    property bool replay: false
    property bool streaming: false
    property bool share: false
    property bool temStreaming: false   // Sunshine instalado (Apps e componentes)

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
    FileView {
        id: transmitindo
        printErrors: false
        onLoaded: streaming = true
        onLoadFailed: streaming = false
    }
    FileView {
        id: compartilhando
        printErrors: false
        onLoaded: share = true
        onLoadFailed: share = false
    }
    Process {
        id: confereSunshine
        command: ["test", "-x", "/usr/bin/sunshine"]
        running: true
        onExited: codigo => temStreaming = codigo === 0
    }
    Component.onCompleted: {
        jogo.path = pasta + "/nyxz-modo-jogo.json";
        gravando.path = pasta + "/nyxz-replay-ativo";
        transmitindo.path = pasta + "/nyxz-streaming-ativo";
        compartilhando.path = pasta + "/nyxz-share-ativo";
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: { jogo.reload(); gravando.reload(); transmitindo.reload(); compartilhando.reload(); }
    }

    function alternarModoJogo() {
        Quickshell.execDetached(["/usr/libexec/nyxz/modo-jogo", modoJogo ? "desligar" : "ligar"]);
        modoJogo = !modoJogo;
    }
    function alternarReplay() {
        Quickshell.execDetached(["/usr/libexec/nyxz/replay", replay ? "desligar" : "ligar"]);
        replay = !replay;
    }
    function alternarStreaming() {
        Quickshell.execDetached(["/usr/libexec/nyxz/streaming", streaming ? "desligar" : "ligar"]);
        streaming = !streaming;
    }
    function parearStreaming() {
        Quickshell.execDetached(["/usr/libexec/nyxz/streaming", "parear"]);
    }
    function salvarReplay() {
        Quickshell.execDetached(["/usr/libexec/nyxz/replay", "salvar"]);
    }
}
