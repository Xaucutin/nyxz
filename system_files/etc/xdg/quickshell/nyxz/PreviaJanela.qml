import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Prévia da janela ao passar o mouse na barra (Ajuste "Instant Taskbar Thumbnail
// Previews"). Uma só para a barra inteira: troca de alvo em vez de criar uma por app.
// Captura pelo hyprland-toplevel-export, em tamanho pequeno, só enquanto aparece.
PopupWindow {
    id: previa

    property var toplevel: null   // janela (Toplevel do ToplevelManager)
    property Item alvo: null      // botão da barra embaixo da prévia
    property int atrasoAbrir: 0   // ms (Ajustes; padrão 0 = na hora)

    function mostrar(t, item) {
        fechar.stop();
        toplevel = t;
        alvo = item;
        if (atrasoAbrir > 0 && !visible) abrir.restart();
        else exibir = true;
        anchor.updateAnchor();
    }
    function agendarFechar() { abrir.stop(); fechar.restart(); }
    function esconder() { abrir.stop(); fechar.stop(); exibir = false; }

    property bool exibir: false
    Timer { id: abrir; interval: previa.atrasoAbrir; onTriggered: previa.exibir = true }
    // Pequena folga para o mouse ir do botão até a prévia sem ela sumir.
    Timer { id: fechar; interval: 180; onTriggered: if (!areaPrevia.containsMouse) previa.exibir = false }

    visible: exibir && toplevel !== null && alvo !== null
    anchor.item: alvo
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Top
    anchor.margins.top: -8
    implicitWidth: 264
    implicitHeight: coluna.implicitHeight + 20
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Tema.raioPainel
        color: Tema.painel
        border.color: Tema.bordaPainel
        border.width: 1
        opacity: previa.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Tema.rapido } }

        ColumnLayout {
            id: coluna
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: previa.toplevel ? Estado.tituloLimpo(previa.toplevel.title) : ""
                elide: Text.ElideRight
                font.family: Tema.fonte
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Tema.texto
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(60, captura.implicitHeight)
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Tema.elevado
                    visible: !captura.hasContent
                    Text {
                        anchors.centerIn: parent
                        text: "Sem prévia"
                        font.family: Tema.fonte
                        font.pixelSize: 11
                        color: Tema.texto4
                    }
                }
                ScreencopyView {
                    id: captura
                    anchors.horizontalCenter: parent.horizontalCenter
                    captureSource: previa.visible ? previa.toplevel : null
                    live: previa.visible
                    constraintSize: Qt.size(244, 150)
                }
            }
        }

        MouseArea {
            id: areaPrevia
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onExited: previa.agendarFechar()
            onClicked: mouse => {
                if (!previa.toplevel) return;
                if (mouse.button === Qt.MiddleButton) previa.toplevel.close();
                else previa.toplevel.activate();
                previa.esconder();
            }
        }
    }
}
