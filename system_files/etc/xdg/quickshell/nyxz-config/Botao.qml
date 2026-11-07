import QtQuick

// Botão da Nyxz. "principal" = claro sobre escuro; "perigo" = texto vermelho.
Rectangle {
    id: botao
    property string texto: ""
    property bool principal: false
    property bool perigo: false
    property bool ativo: true
    signal clicado()

    implicitWidth: rotulo.implicitWidth + 26
    implicitHeight: 32
    radius: 6
    opacity: ativo ? 1 : 0.45
    color: principal ? (area.containsMouse ? "#E2E0E8" : Tema.texto) : (area.containsMouse ? Tema.selecionado : "#16161B")
    border.color: principal ? Tema.texto : "#26262D"
    border.width: 1
    Behavior on color { ColorAnimation { duration: Tema.rapido } }

    Text {
        id: rotulo
        anchors.centerIn: parent
        text: botao.texto
        font.family: Tema.fonte
        font.pixelSize: 13
        font.weight: botao.principal ? Font.Medium : Font.Normal
        color: botao.principal ? Tema.fundo : botao.perigo ? Tema.erro : "#E4E2EA"
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: botao.ativo
        onClicked: botao.clicado()
    }
}
