import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Espaços com nome (ideia 31): nome e papel de parede de cada área de trabalho.
// Grava ~/.config/nyxz/espacos.json; a barra e o fundo acompanham na hora.
Pagina {
    id: p
    titulo: "Espaços"
    descricao: "Dê nome às áreas de trabalho (ex.: Código, Jogos, Estudo) e, se quiser, um papel de parede para cada uma. O nome aparece na barra no lugar do número."

    property var papeis: []

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/espacos.json"
        printErrors: false
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: cfg
            property var espacos: []
        }
    }

    Comando {
        id: listar
        onPronto: saida => {
            try { p.papeis = JSON.parse(saida).filter(i => !i.video).slice(0, 12); } catch (e) { p.papeis = []; }
        }
        Component.onCompleted: rodar(["/usr/libexec/nyxz/papel-de-parede", "listar"])
    }

    function valor(numero, chave) {
        const e = cfg.espacos.find(x => x.numero === numero);
        return e ? (e[chave] || "") : "";
    }
    function definir(numero, chave, v) {
        const lista = cfg.espacos.filter(x => x.numero !== numero);
        const atual = Object.assign({ numero: numero, nome: "", papel: "" }, cfg.espacos.find(x => x.numero === numero) || {});
        atual[chave] = v;
        if (atual.nome || atual.papel) lista.push(atual);
        lista.sort((a, b) => a.numero - b.numero);
        cfg.espacos = lista;
    }

    Repeater {
        model: 5
        delegate: Rectangle {
            id: cartao
            required property int index
            readonly property int numero: index + 1
            Layout.fillWidth: true
            Layout.preferredHeight: corpo.implicitHeight + 24
            radius: 8
            color: Tema.elevado
            border.width: 1
            border.color: Tema.borda

            ColumnLayout {
                id: corpo
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        text: String(cartao.numero)
                        font.family: Tema.fonteMono; font.pixelSize: 14; color: Tema.texto3
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: Tema.raio
                        color: Tema.painel
                        border.width: 1
                        border.color: campo.activeFocus ? Tema.texto4 : Tema.borda
                        TextInput {
                            id: campo
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            maximumLength: 16
                            text: p.valor(cartao.numero, "nome")
                            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                            clip: true
                            // Grava ao terminar (Enter ou ao sair do campo), não a cada letra.
                            onEditingFinished: p.definir(cartao.numero, "nome", text.trim())
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: campo.text.length === 0
                                text: "Sem nome (mostra o número)"
                                font: campo.font
                                color: Tema.texto4
                            }
                        }
                    }
                }

                Text {
                    text: "Papel de parede"
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    // "Padrão" = o papel de parede geral (Aparência)
                    Rectangle {
                        width: 72; height: 42
                        radius: 5
                        color: Tema.painel
                        border.width: p.valor(cartao.numero, "papel") === "" ? 2 : 1
                        border.color: p.valor(cartao.numero, "papel") === "" ? Tema.texto2 : Tema.borda
                        Text {
                            anchors.centerIn: parent
                            text: "Padrão"
                            font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto2
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: p.definir(cartao.numero, "papel", "")
                        }
                    }
                    Repeater {
                        model: p.papeis
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool escolhido: p.valor(cartao.numero, "papel") === modelData.arquivo
                            width: 72; height: 42
                            radius: 5
                            color: Tema.trilho
                            clip: true
                            border.width: escolhido ? 2 : 0
                            border.color: Tema.texto2
                            Image {
                                anchors.fill: parent
                                anchors.margins: parent.escolhido ? 2 : 0
                                source: "file://" + modelData.arquivo
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(144, 84)
                                asynchronous: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: p.definir(cartao.numero, "papel", modelData.arquivo)
                            }
                        }
                    }
                }
            }
        }
    }
}
