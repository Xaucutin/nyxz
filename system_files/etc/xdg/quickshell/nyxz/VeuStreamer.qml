import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Modo streamer: cobre, por cima de tudo (inclusive na transmissão), as janelas com
// segredos: título com ".env", "senha", "cofre"… ou apps escolhidos. A capa deixa o
// mouse e o teclado passarem: dá para continuar usando a janela sem mostrá-la.
// Só existe enquanto o modo streamer está ativo.
Scope {
    id: veu

    // Posições das janelas: o Hyprland só atualiza quando pedimos (com folga de 150 ms)
    Connections {
        target: Hyprland
        enabled: Streamer.ativo
        function onRawEvent(ev) {
            if (/^(openwindow|closewindow|movewindow|windowtitle|changefloatingmode|workspace|activewindow|fullscreen|resizewindow|focusedmon)/.test(ev.name))
                atualizar.restart();
        }
    }
    Timer { id: atualizar; interval: 150; onTriggered: Hyprland.refreshToplevels() }
    // Arrastar/redimensionar não gera evento a cada passo: confere de vez em quando
    Timer { interval: 1000; running: Streamer.ativo; repeat: true; onTriggered: Hyprland.refreshToplevels() }
    Connections {
        target: Streamer
        function onAtivoChanged() { if (Streamer.ativo) Hyprland.refreshToplevels(); }
    }

    function secreta(t) {
        const o = t.lastIpcObject || {};
        const titulo = String(o.title || t.title || "").toLowerCase();
        const classe = String(o.class || "").toLowerCase();
        if (Streamer.janelas.some(j => j && classe.indexOf(String(j).toLowerCase()) >= 0)) return true;
        return Streamer.palavras.some(w => w && titulo.indexOf(String(w).toLowerCase()) >= 0);
    }

    Variants {
        model: Streamer.ativo ? Hyprland.toplevels.values.filter(t => veu.secreta(t) && t.workspace && t.workspace.active
                                                                        && t.lastIpcObject && t.lastIpcObject.size) : []
        PanelWindow {
            id: capa
            required property var modelData
            readonly property var o: modelData.lastIpcObject
            readonly property var tela: Quickshell.screens.find(sc => o.at[0] >= sc.x && o.at[0] < sc.x + sc.width
                                                                   && o.at[1] >= sc.y && o.at[1] < sc.y + sc.height) || Quickshell.screens[0]
            screen: tela
            anchors { top: true; left: true }
            margins.left: o.at[0] - tela.x
            margins.top: o.at[1] - tela.y
            implicitWidth: o.size[0]
            implicitHeight: o.size[1]
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nyxz-streamer"
            mask: Region {}           // o mouse passa para a janela de baixo

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: Tema.painel
                border.width: 1
                border.color: Tema.borda
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Oculto no modo streamer"
                        font.family: Tema.fonte; font.pixelSize: 15; font.weight: Font.Medium; color: Tema.texto2
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: capa.o.class || ""
                        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto4
                    }
                }
            }
        }
    }
}
