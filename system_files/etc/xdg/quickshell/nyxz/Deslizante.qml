import QtQuick

// Controle deslizante fino (volume, brilho). Valor de 0 a 1.
Item {
    id: d
    property real valor: 0
    signal mudou(real v)

    implicitHeight: 16

    Rectangle {
        id: trilho
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 3
        radius: 2
        color: Tema.trilho

        Rectangle {
            width: Math.max(0, Math.min(1, d.valor)) * parent.width
            height: parent.height
            radius: 2
            color: Tema.suave
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(1, d.valor)) * (d.width) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: area.pressed || area.containsMouse ? 13 : 11
        height: width
        radius: width / 2
        color: Tema.texto
        Behavior on width { NumberAnimation { duration: Tema.rapido } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        hoverEnabled: true
        function aplicar(mx) {
            d.mudou(Math.max(0, Math.min(1, mx / d.width)));
        }
        onPressed: mouse => aplicar(mouse.x)
        onPositionChanged: mouse => { if (pressed) aplicar(mouse.x); }
    }
}
