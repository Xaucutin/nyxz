import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Menu do botão direito num app da barra: Nova janela, Fechar, Finalizar tarefa.
PanelWindow {
    id: menu

    readonly property var alvo: Estado.menuToplevel
    readonly property var entrada: alvo ? DesktopEntries.heuristicLookup(alvo.appId) : null

    visible: Estado.menuAberto && alvo !== null
    anchors {
        left: true
        bottom: true
    }
    margins {
        left: Math.max(10, Estado.menuX)
        bottom: 58
    }
    implicitWidth: 230
    implicitHeight: coluna.implicitHeight + 10
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "nyxz-menu"

    HyprlandFocusGrab {
        windows: [menu]
        active: menu.visible
        onCleared: Estado.menuAberto = false
    }

    // Finaliza o processo e os filhos (o escopo inteiro do app).
    function finalizar() {
        const t = menu.alvo;
        Hyprland.refreshToplevels();
        const h = Hyprland.toplevels.values.find(x => x.wayland === t);
        const pid = h && h.lastIpcObject ? h.lastIpcObject.pid : 0;
        if (pid > 0)
            Quickshell.execDetached(["/usr/libexec/nyxz/finalizar", String(pid)]);
        Estado.menuAberto = false;
    }

    Rectangle {
        anchors.fill: parent
        radius: Tema.raio
        color: "#111116"
        border.color: "#25252C"
        border.width: 1

        ColumnLayout {
            id: coluna
            anchors.fill: parent
            anchors.margins: 5
            spacing: 0

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                text: menu.entrada ? menu.entrada.name : (menu.alvo ? menu.alvo.appId : "")
                font.family: Tema.fonte
                font.pixelSize: 12
                color: Tema.texto3
                elide: Text.ElideRight
            }

            ItemMenu {
                texto: "Nova janela"
                visible: menu.entrada !== null
                onAcionado: {
                    Estado.abrirApp(menu.entrada);
                    Estado.menuAberto = false;
                }
            }
            ItemMenu {
                texto: "Fechar"
                onAcionado: {
                    menu.alvo.close();
                    Estado.menuAberto = false;
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                color: Tema.borda
            }
            ItemMenu {
                texto: "Finalizar tarefa"
                perigo: true
                onAcionado: menu.finalizar()
            }
        }
    }
}
