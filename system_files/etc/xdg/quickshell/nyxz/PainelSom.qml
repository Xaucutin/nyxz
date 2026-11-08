import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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

    // nyxz-audio: perfis e microfone sem ruído (lido ao abrir o painel)
    property var audio: ({ perfis: [], supressao: false })
    onVisibleChanged: if (visible) lerAudio.running = true
    Process {
        id: lerAudio
        command: ["/usr/libexec/nyxz/nyxz-audio", "estado"]
        stdout: StdioCollector {
            onStreamFinished: { try { painel.audio = JSON.parse(this.text); } catch (e) {} }
        }
    }
    function nyxzAudio(args) {
        Quickshell.execDetached(["/usr/libexec/nyxz/nyxz-audio"].concat(args));
        releitura.restart();
    }
    Timer { id: releitura; interval: 900; onTriggered: lerAudio.running = true }

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

            // Perfis (ex.: Call, Jogo): um clique troca saída, microfone, volume e supressão
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 6
                visible: painel.audio.perfis !== undefined && painel.audio.perfis.length > 0
                Repeater {
                    model: painel.audio.perfis || []
                    delegate: Rectangle {
                        required property string modelData
                        width: rotuloPerfil.implicitWidth + 20
                        height: 26
                        radius: 13
                        color: areaPerfil.containsMouse ? Tema.hover : Tema.elevado
                        border.width: 1
                        border.color: Tema.borda
                        Text {
                            id: rotuloPerfil
                            anchors.centerIn: parent
                            text: parent.modelData
                            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.suave
                        }
                        MouseArea {
                            id: areaPerfil
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: painel.nyxzAudio(["perfil", "aplicar", parent.modelData])
                        }
                    }
                }
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
                    id: linhaApp
                    required property var modelData
                    property bool escolhendo: false
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Text {
                            Layout.fillWidth: true
                            text: painel.nomeApp(linhaApp.modelData)
                            font.family: Tema.fonte
                            font.pixelSize: 13
                            color: Tema.suave
                            elide: Text.ElideRight
                        }
                        // Saída de áudio só deste app (o WirePlumber lembra por app)
                        Text {
                            visible: painel.saidas.length > 1
                            text: linhaApp.escolhendo ? "Fechar" : "Saída…"
                            font.family: Tema.fonte
                            font.pixelSize: 11
                            color: areaSaidaApp.containsMouse ? Tema.texto : Tema.texto3
                            MouseArea {
                                id: areaSaidaApp
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                onClicked: linhaApp.escolhendo = !linhaApp.escolhendo
                            }
                        }
                    }
                    Repeater {
                        model: linhaApp.escolhendo ? painel.saidas : []
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: 18
                            Layout.rightMargin: 10
                            Layout.preferredHeight: 28
                            radius: 6
                            color: areaOpcaoSaida.containsMouse ? Tema.hover : "transparent"
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                text: parent.modelData.description || parent.modelData.name
                                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
                            }
                            MouseArea {
                                id: areaOpcaoSaida
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    painel.nyxzAudio(["saida-app", String(linhaApp.modelData.id), parent.modelData.name]);
                                    linhaApp.escolhendo = false;
                                }
                            }
                        }
                    }
                    LinhaVolume {
                        no: linhaApp.modelData
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
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.topMargin: 2
                visible: painel.microfone !== null
                Text {
                    Layout.fillWidth: true
                    text: "Sem ruído (tira barulho de fundo e eco)"
                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
                }
                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 20
                    radius: 10
                    color: painel.audio.supressao ? Tema.suave : Tema.trilho
                    Rectangle {
                        width: 14; height: 14; radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        x: painel.audio.supressao ? parent.width - width - 3 : 3
                        color: painel.audio.supressao ? Tema.fundo : Tema.texto3
                        Behavior on x { NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: painel.nyxzAudio(["supressao", painel.audio.supressao ? "desligar" : "ligar"])
                    }
                }
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
