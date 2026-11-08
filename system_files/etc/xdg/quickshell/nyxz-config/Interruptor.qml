import QtQuick

// Interruptor liga/desliga, discreto, com movimento suave.
Item {
    id: i
    property bool ligado: false
    signal alternado(bool valor)

    implicitWidth: 34
    implicitHeight: 20

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: i.ligado ? Tema.suave : Tema.trilho
        Behavior on color { ColorAnimation { duration: Tema.rapido } }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            anchors.verticalCenter: parent.verticalCenter
            x: i.ligado ? parent.width - width - 3 : 3
            color: i.ligado ? Tema.fundo : Tema.texto3
            Behavior on x {
                NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: i.alternado(!i.ligado)
    }
}
