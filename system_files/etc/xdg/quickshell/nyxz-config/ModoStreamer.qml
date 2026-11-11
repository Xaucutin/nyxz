pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Modo streamer visto pelas Configurações (outro processo): o shell cria a marca
// $XDG_RUNTIME_DIR/nyxz-streamer enquanto ele está ativo. As páginas escondem IPs e senhas.
Singleton {
    id: m
    property bool ativo: false
    function ip(t) { return m.ativo && t ? "oculto (modo streamer)" : t; }

    FileView {
        id: marca
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/nyxz-streamer"
        printErrors: false
        onLoaded: m.ativo = true
        onLoadFailed: m.ativo = false
    }
    // A marca aparece e some: confere a cada 2 s (só com as Configurações abertas)
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: marca.reload() }
}
