import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire

// Painel de som: saída, volume geral, volume por app e microfone.
PanelWindow {
    id: painel

    visible: Estado.somAberto
    anchors {
        right: true
        top: Ajustes.barraEmCima
        bottom: !Ajustes.barraEmCima
    }
    margins {
        right: 10
        top: Ajustes.barraEmCima ? 58 : 0
        bottom: Ajustes.barraEmCima ? 0 : 58
    }
    implicitWidth: 380
    implicitHeight: coluna.implicitHeight + 28
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "nyxz-som"
    // Recebe o teclado enquanto aberto, para o Esc fechar (sem isso o painel
    // prendia o teclado até um clique fora).
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property var saidas: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var apps: Pipewire.nodes.values.filter(n => n.audio && n.isStream && n.isSink)
    readonly property var saidaAtual: Pipewire.defaultAudioSink
    readonly property var microfone: Pipewire.defaultAudioSource

    function nomeApp(n) {
        const p = n.properties || {};
        return p["application.name"] || n.description || n.name;
    }

    PwObjectTracker {
        objects: painel.saidas.concat(painel.apps).concat(painel.microfone ? [painel.microfone] : [])
    }

    HyprlandFocusGrab {
        windows: [painel]
        active: painel.visible
        onCleared: Estado.somAberto = false
    }

    Rectangle {
        anchors.fill: parent
        radius: Tema.raioPainel
        color: Tema.painel
        border.color: Tema.bordaPainel
        border.width: 1
        focus: painel.visible
        Keys.onEscapePressed: Estado.somAberto = false

        ColumnLayout {
            id: coluna
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 6

            Text {
                text: "Som"
                font.family: Tema.fonte
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Tema.texto
            }

            Rotulo { texto: "Saída" }
            Repeater {
                model: painel.saidas
                delegate: Rectangle {
                    id: linhaSaida
                    required property var modelData
                    readonly property bool atual: painel.saidaAtual === modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 6
                    color: atual ? "#16161B" : areaSaida.containsMouse ? Tema.hover : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        text: linhaSaida.modelData.description || linhaSaida.modelData.name
                        font.family: Tema.fonte
                        font.pixelSize: 13
                        color: linhaSaida.atual ? Tema.texto : Tema.texto2
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: areaSaida
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Pipewire.preferredDefaultAudioSink = linhaSaida.modelData
                    }
                }
            }

            LinhaVolume {
                Layout.topMargin: 6
                no: painel.saidaAtual
                icone: "icones/volume.svg"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 6
                Layout.bottomMargin: 2
                color: "#1A1A20"
                visible: painel.apps.length > 0
            }
            Rotulo { texto: "Por aplicativo"; visible: painel.apps.length > 0 }
            Repeater {
                model: painel.apps
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        Layout.leftMargin: 10
                        text: painel.nomeApp(parent.modelData)
                        font.family: Tema.fonte
                        font.pixelSize: 13
                        color: Tema.suave
                        elide: Text.ElideRight
                    }
                    LinhaVolume {
                        no: parent.modelData
                        icone: "icones/volume.svg"
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 6
                Layout.bottomMargin: 2
                color: "#1A1A20"
                visible: painel.microfone !== null
            }
            Rotulo { texto: "Microfone"; visible: painel.microfone !== null }
            LinhaVolume {
                visible: painel.microfone !== null
                no: painel.microfone
                icone: "icones/microfone.svg"
            }
        }
    }

    component Rotulo: Text {
        property string texto: ""
        Layout.leftMargin: 10
        Layout.topMargin: 4
        text: texto
        font.family: Tema.fonte
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Tema.texto3
    }

    component LinhaVolume: RowLayout {
        id: lv
        property var no: null
        property string icone: ""
        readonly property bool pronto: no !== null && no.audio !== null
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        spacing: 12

        Image {
            source: lv.pronto && lv.no.audio.muted ? "icones/mudo.svg" : lv.icone
            sourceSize: Qt.size(15, 15)
            opacity: 0.8
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: if (lv.pronto) lv.no.audio.muted = !lv.no.audio.muted
            }
        }
        Deslizante {
            Layout.fillWidth: true
            valor: lv.pronto ? lv.no.audio.volume : 0
            opacity: lv.pronto && lv.no.audio.muted ? 0.4 : 1
            onMudou: v => { if (lv.pronto) lv.no.audio.volume = v; }
        }
        Text {
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
            text: lv.pronto ? (lv.no.audio.muted ? "mudo" : Math.round(lv.no.audio.volume * 100)) : ""
            font.family: Tema.fonteMono
            font.pixelSize: 11
            color: "#8A8894"
        }
    }
}
