import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

// Mini player da barra (Ajuste "Taskbar Fluent Media Player"): capa, título e
// controles para qualquer app de mídia via MPRIS (Spotify, vídeo no Brave, mpv...).
// Só aparece quando existe um player; com vários, prefere o que está tocando.
Item {
    id: mini

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    readonly property bool temPlayer: player !== null && (player.trackTitle || "") !== ""

    visible: temPlayer
    implicitWidth: temPlayer ? linha.implicitWidth + 16 : 0
    implicitHeight: 34

    Behavior on implicitWidth {
        NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
    }

    // A posição do MPRIS não avisa sozinha: atualiza 1x por segundo enquanto toca.
    Timer {
        interval: 1000
        repeat: true
        running: mini.player !== null && mini.player.isPlaying && mini.player.positionSupported
        onTriggered: mini.player.positionChanged()
    }

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: area.containsMouse ? Tema.elevado : "transparent"
        Behavior on color { ColorAnimation { duration: Tema.rapido } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        // Clique no meio pausa/toca; rolar troca de faixa.
        onClicked: mouse => { if (mouse.button === Qt.MiddleButton && mini.player) mini.player.togglePlaying(); }
        onWheel: wheel => {
            if (!mini.player) return;
            if (wheel.angleDelta.y > 0 && mini.player.canGoPrevious) mini.player.previous();
            else if (wheel.angleDelta.y < 0 && mini.player.canGoNext) mini.player.next();
        }
    }

    RowLayout {
        id: linha
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        spacing: 8

        // Capa
        ClippingRectangle {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 4
            color: Tema.trilho
            Image {
                anchors.fill: parent
                source: mini.player ? mini.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(44, 44)
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        Column {
            Layout.preferredWidth: Math.min(170, Math.max(titulo.implicitWidth, artista.implicitWidth))
            spacing: 0
            Text {
                id: titulo
                width: parent.width
                text: mini.player ? mini.player.trackTitle : ""
                elide: Text.ElideRight
                font.family: Tema.fonte
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Tema.texto
            }
            Text {
                id: artista
                width: parent.width
                text: mini.player ? (mini.player.trackArtist || mini.player.identity) : ""
                elide: Text.ElideRight
                font.family: Tema.fonte
                font.pixelSize: 10
                color: Tema.texto3
            }
        }

        // Controles
        Row {
            spacing: 0
            BotaoMidia {
                icone: "anterior"
                ativo: mini.player !== null && mini.player.canGoPrevious
                onClicado: mini.player.previous()
            }
            BotaoMidia {
                icone: mini.player && mini.player.isPlaying ? "pausar" : "tocar"
                ativo: mini.player !== null && mini.player.canTogglePlaying
                onClicado: mini.player.togglePlaying()
            }
            BotaoMidia {
                icone: "proxima"
                ativo: mini.player !== null && mini.player.canGoNext
                onClicado: mini.player.next()
            }
        }
    }

    // Progresso da faixa
    Rectangle {
        visible: mini.player !== null && mini.player.positionSupported && mini.player.lengthSupported && mini.player.length > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 2
        height: 2
        radius: 1
        color: Tema.trilho
        Rectangle {
            height: parent.height
            radius: 1
            color: Tema.texto2
            width: mini.player && mini.player.length > 0
                   ? parent.width * Math.min(1, mini.player.position / mini.player.length) : 0
        }
    }

    component BotaoMidia: Item {
        id: b
        property string icone: ""
        property bool ativo: true
        signal clicado()
        width: 24
        height: 24
        opacity: ativo ? 1 : 0.35
        Rectangle {
            anchors.fill: parent
            radius: 6
            color: areaBotao.containsMouse && b.ativo ? Tema.hover : "transparent"
        }
        Image {
            anchors.centerIn: parent
            source: "icones/" + b.icone + ".svg"
            sourceSize: Qt.size(14, 14)
        }
        MouseArea {
            id: areaBotao
            anchors.fill: parent
            hoverEnabled: true
            enabled: b.ativo
            onClicked: b.clicado()
        }
    }
}
