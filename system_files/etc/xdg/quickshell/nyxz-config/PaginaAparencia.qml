import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Aparência: papel de parede (imagem ou vídeo) com galeria das pastas do usuário.
// Quem aplica é /usr/libexec/nyxz/papel-de-parede; o shell acompanha o arquivo
// ~/.config/nyxz/papel-de-parede.json e troca na hora.
Pagina {
    id: p
    titulo: "Aparência"
    descricao: "Papel de parede: imagem ou vídeo (mp4, webm, mkv, gif). Vídeo fica sem som, em loop, e pausa quando a área de trabalho está coberta."

    property var itens: []
    property bool lendo: true

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/papel-de-parede.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        JsonAdapter {
            id: cfg
            property string tipo: "cor"
            property string arquivo: ""
            property string ajuste: "preencher"
        }
    }

    Comando {
        id: listar
        onPronto: saida => {
            try { p.itens = JSON.parse(saida); } catch (e) { p.itens = []; }
            p.lendo = false;
        }
        Component.onCompleted: rodar(["/usr/libexec/nyxz/papel-de-parede", "listar"])
    }

    function definir(arquivo, ajuste) {
        Quickshell.execDetached(["/usr/libexec/nyxz/papel-de-parede", "definir", arquivo, ajuste]);
    }

    // ---------------------------------------------- encaixe
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Text {
            Layout.preferredWidth: 150
            text: "Encaixe"
            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto3
        }
        Row {
            spacing: 6
            Repeater {
                model: [
                    { id: "preencher", nome: "Preencher" },
                    { id: "ajustar", nome: "Ajustar" },
                    { id: "centralizar", nome: "Centralizar" }
                ]
                delegate: Botao {
                    required property var modelData
                    texto: modelData.nome
                    principal: cfg.ajuste === modelData.id
                    onClicado: if (cfg.tipo !== "cor") p.definir(cfg.arquivo, modelData.id)
                }
            }
        }
        Item { Layout.fillWidth: true }
        Botao {
            texto: "Cor sólida"
            principal: cfg.tipo === "cor"
            onClicado: Quickshell.execDetached(["/usr/libexec/nyxz/papel-de-parede", "remover"])
        }
    }

    Text {
        Layout.topMargin: 10
        text: p.lendo ? "Procurando imagens e vídeos…"
            : p.itens.length === 0 ? "Nenhuma imagem ou vídeo em Imagens, Vídeos ou Downloads."
            : "Imagens e vídeos de Imagens, Vídeos e Downloads"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }

    // ---------------------------------------------- galeria
    GridLayout {
        Layout.fillWidth: true
        columns: Math.max(2, Math.floor(width / 176))
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
            model: p.itens
            delegate: Rectangle {
                id: cartao
                required property var modelData
                readonly property bool atual: cfg.tipo !== "cor" && cfg.arquivo === modelData.arquivo
                Layout.fillWidth: true
                Layout.preferredHeight: width * 9 / 16 + 26
                radius: 8
                color: area.containsMouse ? Tema.hover : Tema.elevado
                border.width: atual ? 2 : 1
                border.color: atual ? Tema.texto2 : Tema.borda

                Rectangle {
                    id: miniatura
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4
                    height: width * 9 / 16
                    radius: 5
                    color: Tema.trilho
                    clip: true
                    Image {
                        anchors.fill: parent
                        visible: !cartao.modelData.video
                        source: cartao.modelData.video ? "" : "file://" + cartao.modelData.arquivo
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(320, 180)
                        asynchronous: true
                    }
                    Image {
                        anchors.centerIn: parent
                        visible: cartao.modelData.video
                        source: "icones/tocar.svg"
                        sourceSize: Qt.size(22, 22)
                    }
                }
                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    text: (cartao.modelData.video ? "Vídeo · " : "") + cartao.modelData.nome
                    elide: Text.ElideMiddle
                    font.family: Tema.fonte; font.pixelSize: 11
                    color: cartao.atual ? Tema.texto : Tema.texto2
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: p.definir(cartao.modelData.arquivo, cfg.ajuste)
                }
            }
        }
    }
}
