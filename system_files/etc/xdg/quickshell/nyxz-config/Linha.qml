import QtQuick
import QtQuick.Layouts

// Linha "rótulo → valor" (tela Sobre, status).
RowLayout {
    property string rotulo: ""
    property string valor: ""
    property bool mono: false
    Layout.fillWidth: true
    Layout.preferredHeight: 30
    spacing: 12

    Text {
        Layout.preferredWidth: 150
        text: parent.rotulo
        font.family: Tema.fonte
        font.pixelSize: 13
        color: Tema.texto3
    }
    Text {
        Layout.fillWidth: true
        text: parent.valor
        font.family: parent.mono ? Tema.fonteMono : Tema.fonte
        font.pixelSize: 13
        color: Tema.suave
        elide: Text.ElideRight
    }
}
