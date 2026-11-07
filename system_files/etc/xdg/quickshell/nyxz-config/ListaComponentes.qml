import QtQuick
import QtQuick.Layouts

// Lista do catálogo por categoria, com caixas de seleção.
// Usada pelo Nyxz Setup e pela página Apps e componentes.
ColumnLayout {
    id: lista
    property var catalogo: null       // conteúdo de /usr/share/nyxz/catalogo.json
    property var marcados: ({})       // id -> bool
    property var instalados: ({})     // id -> bool
    signal alternar(string id)
    signal definirCategoria(string categoria, bool valor)

    spacing: 4

    Repeater {
        model: lista.catalogo ? lista.catalogo.categorias : []
        delegate: ColumnLayout {
            id: cat
            required property var modelData
            readonly property var itens: lista.catalogo.itens.filter(i => i.categoria === modelData.id)
            readonly property bool todos: itens.every(i => lista.marcados[i.id])
            Layout.fillWidth: true
            Layout.bottomMargin: 14
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: cat.modelData.nome
                        font.family: Tema.fonte
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Tema.texto
                    }
                    Text {
                        text: cat.modelData.descricao
                        font.family: Tema.fonte
                        font.pixelSize: 12
                        color: Tema.texto3
                    }
                }
                Text {
                    text: cat.todos ? "Desmarcar todos" : "Marcar todos"
                    font.family: Tema.fonte
                    font.pixelSize: 12
                    color: Tema.texto2
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: lista.definirCategoria(cat.modelData.id, !cat.todos)
                    }
                }
            }

            Repeater {
                model: cat.itens
                delegate: Rectangle {
                    id: linha
                    required property var modelData
                    readonly property bool marcado: lista.marcados[modelData.id] === true
                    Layout.fillWidth: true
                    Layout.preferredHeight: conteudo.implicitHeight + 18
                    radius: 6
                    color: area.containsMouse ? Tema.elevado : "transparent"
                    Behavior on color { ColorAnimation { duration: Tema.rapido } }

                    RowLayout {
                        id: conteudo
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 12

                        // Caixa de seleção
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 2
                            width: 16
                            height: 16
                            radius: 4
                            color: linha.marcado ? Tema.texto : "transparent"
                            border.color: linha.marcado ? Tema.texto : "#3A3A42"
                            border.width: 1.5
                            Behavior on color { ColorAnimation { duration: Tema.rapido } }
                            Text {
                                anchors.centerIn: parent
                                visible: linha.marcado
                                text: "✓"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: Tema.fundo
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: linha.modelData.nome
                                    font.family: Tema.fonte
                                    font.pixelSize: 13
                                    color: linha.marcado ? Tema.texto : Tema.suave
                                }
                                Text {
                                    visible: lista.instalados[linha.modelData.id] === true
                                    text: "instalado"
                                    font.family: Tema.fonte
                                    font.pixelSize: 11
                                    color: Tema.ok
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: linha.modelData.descricao
                                font.family: Tema.fonte
                                font.pixelSize: 12
                                color: Tema.texto3
                                wrapMode: Text.Wrap
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: linha.modelData.aviso !== undefined
                                text: linha.modelData.aviso || ""
                                font.family: Tema.fonte
                                font.pixelSize: 12
                                color: Tema.aviso
                                wrapMode: Text.Wrap
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignTop
                            text: (linha.modelData.tipo === "rpm" ? "nativo" : "Flatpak") + " · " + linha.modelData.tamanho_mb + " MB"
                            font.family: Tema.fonteMono
                            font.pixelSize: 11
                            color: "#55535F"
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: lista.alternar(linha.modelData.id)
                    }
                }
            }
        }
    }
}
