import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Congelar apps (ideia 33), lado do shell: avisa cada troca de foco (o app focado é
// descongelado na hora) e pede uma conferência a cada minuto. Desligado, não faz nada.
// Quem congela é /usr/libexec/nyxz/congelar (cgroup.freeze).
Scope {
    id: c
    readonly property string cmd: "/usr/libexec/nyxz/congelar"
    property bool ligado: false
    property bool noJogo: true

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/congelar.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { const d = JSON.parse(text()); c.ligado = !!d.ligado && (d.apps || []).length > 0; c.noJogo = d.noJogo !== false; }
            catch (e) { c.ligado = false; }
        }
        onLoadFailed: c.ligado = false
    }

    Connections {
        target: Hyprland
        enabled: c.ligado
        function onRawEvent(ev) {
            if (ev.name === "activewindowv2" && ev.data && ev.data !== ",")
                Quickshell.execDetached([c.cmd, "foco", ev.data]);
        }
    }
    Timer {
        interval: 60000; running: c.ligado; repeat: true
        onTriggered: Quickshell.execDetached([c.cmd, "avaliar"])
    }
    // Jogo abriu: congela já os apps escolhidos; fechou: solta os que foram por causa dele
    Connections {
        target: JogoEstado
        enabled: c.ligado && c.noJogo
        function onModoJogoChanged() {
            Quickshell.execDetached([c.cmd, JogoEstado.modoJogo ? "avaliar" : "fim-jogo"]);
        }
    }
}
