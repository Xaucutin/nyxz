import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

// Som: dispositivo de saída e de entrada, com volume de cada um.
Pagina {
    id: p
    titulo: "Som"
    descricao: "Escolha onde o som sai e qual microfone usar. O volume de cada app fica no painel de som da barra."

    readonly property var saidas: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var entradas: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    PwObjectTracker { objects: p.saidas.concat(p.entradas) }

    component Dispositivo: Rectangle {
        id: disp
        property var no: null
        property bool atual: false
        signal escolhido()
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 6
        color: atual ? "#16161B" : area.containsMouse ? Tema.elevado : "transparent"
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            text: disp.no ? (disp.no.description || disp.no.name) : ""
            font.family: Tema.fonte
            font.pixelSize: 13
            color: disp.atual ? Tema.texto : Tema.texto2
            elide: Text.ElideRight
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: disp.escolhido()
        }
    }

    component Volume: RowLayout {
        id: vol
        property var no: null
        readonly property bool pronto: no !== null && no.audio !== null
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.topMargin: 4
        spacing: 12
        Text {
            text: vol.pronto && vol.no.audio.muted ? "Ativar" : "Mudo"
            font.family: Tema.fonte
            font.pixelSize: 12
            color: Tema.texto3
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: if (vol.pronto) vol.no.audio.muted = !vol.no.audio.muted
            }
        }
        Deslizante {
            Layout.fillWidth: true
            valor: vol.pronto ? vol.no.audio.volume : 0
            opacity: vol.pronto && vol.no.audio.muted ? 0.4 : 1
            onMudou: v => { if (vol.pronto) vol.no.audio.volume = v; }
        }
        Text {
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
            text: vol.pronto ? Math.round(vol.no.audio.volume * 100) + "%" : ""
            font.family: Tema.fonteMono
            font.pixelSize: 12
            color: "#8A8894"
        }
    }

    Text { text: "Saída"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Repeater {
        model: p.saidas
        delegate: Dispositivo {
            required property var modelData
            no: modelData
            atual: Pipewire.defaultAudioSink === modelData
            onEscolhido: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
    Volume { no: Pipewire.defaultAudioSink }

    Text {
        Layout.topMargin: 18
        text: "Entrada (microfone)"
        font.family: Tema.fonte
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Tema.texto3
    }
    Repeater {
        model: p.entradas
        delegate: Dispositivo {
            required property var modelData
            no: modelData
            atual: Pipewire.defaultAudioSource === modelData
            onEscolhido: Pipewire.preferredDefaultAudioSource = modelData
        }
    }
    Volume { no: Pipewire.defaultAudioSource }
    Text {
        Layout.fillWidth: true
        visible: p.entradas.length === 0
        text: "Nenhum microfone encontrado."
        font.family: Tema.fonte
        font.pixelSize: 13
        color: Tema.texto3
    }
}
