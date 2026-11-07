import QtQuick
import QtQuick.Layouts

// Item clicável de menu.
Rectangle {
    id: item
    property string texto: ""
    property bool perigo: false
    signal acionado()

    Layout.fillWidth: true
    Layout.preferredHeight: 32
    radius: 5
    color: area.containsMouse ? (perigo ? Tema.perigoFundo : Tema.hover) : "transparent"
    Behavior on color { ColorAnimation { duration: Tema.rapido } }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        text: item.texto
        font.family: Tema.fonte
        font.pixelSize: 13
        color: item.perigo ? Tema.erro : Tema.suave
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: item.acionado()
    }
}
