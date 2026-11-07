import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

// Barra de tarefas: logo, workspaces, apps abertos, bandeja, som e relógio.
PanelWindow {
    id: barra

    anchors {
        left: true
        right: true
        bottom: true
    }
    margins {
        left: 10
        right: 10
        bottom: 10
    }
    implicitHeight: 40
    exclusiveZone: 40
    color: "transparent"
    WlrLayershell.namespace: "nyxz-barra"

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Rectangle {
        anchors.fill: parent
        radius: Tema.raio
        color: Tema.barra

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 8
            spacing: 2

            // ---------------------------------------------- logo (abre a busca)
            Item {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: areaLogo.containsMouse ? Tema.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: Tema.rapido } }
                }
                Image {
                    anchors.centerIn: parent
                    source: "icones/nyxz.svg"
                    sourceSize: Qt.size(26, 13)
                    smooth: true
                }
                MouseArea {
                    id: areaLogo
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const abrir = !Estado.buscaAberta;
                        Estado.fecharTudo();
                        Estado.buscaAberta = abrir;
                    }
                }
            }

            // ---------------------------------------------- workspaces 1 a 5
            Row {
                Layout.leftMargin: 8
                Layout.rightMargin: 12
                spacing: 0

                Repeater {
                    model: 5
                    Item {
                        required property int index
                        readonly property int numero: index + 1
                        readonly property var ws: Hyprland.workspaces.values.find(w => w.id === numero)
                        readonly property bool ativo: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === numero
                        readonly property bool ocupado: ws !== undefined && ws.toplevels.values.length > 0
                        width: 24
                        height: 30

                        Text {
                            anchors.centerIn: parent
                            text: parent.numero
                            font.family: Tema.fonteMono
                            font.pixelSize: 12
                            color: parent.ativo ? Tema.texto : parent.ocupado ? "#8A8894" : Tema.texto4
                            Behavior on color { ColorAnimation { duration: Tema.rapido } }
                        }
                        Rectangle {
                            width: parent.ativo ? 8 : 0
                            height: 2
                            radius: 1
                            color: Tema.texto
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            Behavior on width {
                                NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Estado.irParaWorkspace(parent.numero)
                        }
                    }
                }

                WheelHandler {
                    onWheel: event => Estado.despachar(
                        "hl.dsp.focus({ workspace = '" + (event.angleDelta.y < 0 ? "e+1" : "e-1") + "' })",
                        "workspace " + (event.angleDelta.y < 0 ? "e+1" : "e-1"))
                }
            }

            // ---------------------------------------------- apps abertos
            Row {
                spacing: 2
                Repeater {
                    model: ToplevelManager.toplevels
                    delegate: Item {
                        id: tarefa
                        required property var modelData
                        readonly property var entrada: DesktopEntries.heuristicLookup(modelData.appId)
                        width: 34
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            radius: 7
                            color: tarefa.modelData.activated ? Tema.hover : areaTarefa.containsMouse ? Tema.elevado : "transparent"
                            Behavior on color { ColorAnimation { duration: Tema.rapido } }
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 19
                            source: Quickshell.iconPath(tarefa.entrada ? tarefa.entrada.icon : tarefa.modelData.appId, "application-x-executable")
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            width: tarefa.modelData.activated ? 10 : 4
                            height: 2
                            radius: 1
                            color: tarefa.modelData.activated ? Tema.texto : Tema.texto4
                            Behavior on width {
                                NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                            }
                        }
                        MouseArea {
                            id: areaTarefa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    const p = tarefa.mapToItem(null, 0, 0);
                                    Estado.fecharTudo();
                                    Estado.menuToplevel = tarefa.modelData;
                                    Estado.menuX = p.x + barra.margins.left - 20;
                                    Estado.menuAberto = true;
                                } else if (mouse.button === Qt.MiddleButton) {
                                    tarefa.modelData.close();
                                } else {
                                    tarefa.modelData.activate();
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // ---------------------------------------------- bandeja
            Row {
                spacing: 0
                Repeater {
                    model: SystemTray.items
                    delegate: Item {
                        id: itemBandeja
                        required property var modelData
                        width: 30
                        height: 30
                        Rectangle {
                            anchors.fill: parent
                            radius: 7
                            color: areaBandeja.containsMouse ? Tema.hover : "transparent"
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 16
                            source: itemBandeja.modelData.icon
                        }
                        MouseArea {
                            id: areaBandeja
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                const m = itemBandeja.modelData;
                                if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && m.onlyMenu)) {
                                    if (m.hasMenu) {
                                        const p = itemBandeja.mapToItem(null, 0, 0);
                                        m.display(barra, p.x, -8);
                                    }
                                } else if (mouse.button === Qt.MiddleButton) {
                                    m.secondaryActivate();
                                } else {
                                    m.activate();
                                }
                            }
                            onWheel: wheel => itemBandeja.modelData.scroll(wheel.angleDelta.y, false)
                        }
                    }
                }
            }

            // ---------------------------------------------- som
            Item {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                readonly property var saida: Pipewire.defaultAudioSink
                readonly property bool mudo: saida !== null && saida.audio !== null && saida.audio.muted

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: Estado.somAberto || areaSom.containsMouse ? Tema.hover : "transparent"
                }
                Image {
                    anchors.centerIn: parent
                    source: parent.mudo ? "icones/mudo.svg" : "icones/volume.svg"
                    sourceSize: Qt.size(16, 16)
                }
                MouseArea {
                    id: areaSom
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const abrir = !Estado.somAberto;
                        Estado.fecharTudo();
                        Estado.somAberto = abrir;
                    }
                    // Rolar a roda do mouse muda o volume (mod "Taskbar Volume Control")
                    onWheel: wheel => {
                        const s = Pipewire.defaultAudioSink;
                        if (!s || !s.audio) return;
                        const passo = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        s.audio.volume = Math.max(0, Math.min(1, s.audio.volume + passo));
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                color: Tema.borda
            }

            // ---------------------------------------------- relógio
            SystemClock {
                id: relogio
                precision: SystemClock.Minutes
            }
            Text {
                text: Qt.formatDateTime(relogio.date, "HH:mm")
                font.family: Tema.fonte
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Tema.texto
            }
        }
    }
}
