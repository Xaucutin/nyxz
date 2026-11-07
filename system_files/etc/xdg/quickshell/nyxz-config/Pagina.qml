import QtQuick
import QtQuick.Layouts

// Moldura de página: título, descrição e conteúdo com rolagem suave.
Flickable {
    id: pagina
    property string titulo: ""
    property string descricao: ""
    default property alias conteudo: coluna.data

    contentHeight: coluna.implicitHeight + 64
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    // Rolagem com inércia (estilo Lenis)
    flickDeceleration: 1800
    maximumFlickVelocity: 3500

    ColumnLayout {
        id: coluna
        x: 32
        y: 28
        width: pagina.width - 64
        spacing: 10

        Text {
            text: pagina.titulo
            font.family: Tema.fonte
            font.pixelSize: 20
            font.weight: Font.Medium
            color: Tema.texto
        }
        Text {
            Layout.fillWidth: true
            Layout.bottomMargin: 14
            visible: pagina.descricao.length > 0
            text: pagina.descricao
            font.family: Tema.fonte
            font.pixelSize: 13
            color: Tema.texto3
            wrapMode: Text.Wrap
        }
    }
}
