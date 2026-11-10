import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Cola de atalhos (ideia 14): Super + / mostra todos os atalhos, agrupados e com busca.
// Esc, clique fora ou Super + / de novo fecham.
PanelWindow {
    id: cola

    visible: Estado.atalhosAberto
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nyxz-atalhos"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: if (visible) { campo.text = ""; campo.forceActiveFocus(); }

    readonly property var grupos: [
        { nome: "Geral", itens: [
            ["Super", "Espaço", "Busca: apps, contas, desligar"],
            ["Super", "Enter", "Abrir o terminal"],
            ["Super", "/", "Esta lista de atalhos"],
            ["Super", "B", "Brilho e luz azul"],
            ["Super", "Shift + E", "Sair da sessão"]
        ]},
        { nome: "Janelas", itens: [
            ["Super", "Q", "Fechar a janela"],
            ["Super", "F", "Tela cheia"],
            ["Super", "V", "Janela flutuante (solta)"],
            ["Super", "← ↑ → ↓", "Ir para a janela ao lado"],
            ["Super", "arrastar", "Mover a janela de qualquer ponto"],
            ["Super", "botão direito + arrastar", "Redimensionar a janela"]
        ]},
        { nome: "Áreas de trabalho", itens: [
            ["Super", "1 a 5", "Ir para a área de trabalho"],
            ["Super", "Shift + 1 a 5", "Levar a janela para a área de trabalho"],
            ["Super", "rolar o mouse", "Área de trabalho anterior ou seguinte"]
        ]},
        { nome: "Som e mídia", itens: [
            ["", "Teclas de volume", "Aumentar, diminuir e silenciar"],
            ["", "Tecla do microfone", "Silenciar o microfone"],
            ["", "Rolar no ícone de som", "Mudar o volume"],
            ["", "Rolar no mini player", "Faixa anterior ou seguinte"]
        ]},
        { nome: "Jogos", itens: [
            ["Alt", "F10", "Salvar os últimos 30 segundos (replay)"],
            ["Alt", "Shift + F10", "Ligar ou desligar o replay"]
        ]},
        { nome: "Barra", itens: [
            ["", "Botão do meio no app", "Fechar o app"],
            ["", "Botão direito no app", "Fechar ou finalizar tarefa"],
            ["", "Rolar no ícone de sol", "Brilho de todas as telas"]
        ]}
    ]

    function combina(it, f) {
        return !f || (it[0] + " " + it[1] + " " + it[2]).toLowerCase().indexOf(f) >= 0;
    }

    // Fundo escurecido; clicar fora fecha
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.035, 0.035, 0.05, 0.7)
        MouseArea { anchors.fill: parent; onClicked: Estado.atalhosAberto = false }
    }

    Rectangle {
        id: cartao
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 860)
        height: Math.min(parent.height - 80, coluna.implicitHeight + 40)
        radius: Tema.raioPainel
        color: Tema.painel
        border.color: Tema.bordaPainel
        border.width: 1
        opacity: cola.visible ? 1 : 0
        transform: Translate { y: cola.visible ? 0 : 12 }
        Behavior on opacity { NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva } }
        MouseArea { anchors.fill: parent }   // clique dentro não fecha

        ColumnLayout {
            id: coluna
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Atalhos"
                    font.family: Tema.fonte; font.pixelSize: 17; font.weight: Font.DemiBold; color: Tema.texto
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 34
                    radius: Tema.raio
                    color: Tema.elevado
                    border.width: 1
                    border.color: Tema.borda
                    TextInput {
                        id: campo
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                        clip: true
                        Keys.onEscapePressed: Estado.atalhosAberto = false
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: campo.text.length === 0
                            text: "Procurar atalho"
                            font: campo.font
                            color: Tema.texto4
                        }
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: grade.implicitHeight
                contentWidth: width
                contentHeight: grade.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                GridLayout {
                    id: grade
                    width: parent.width
                    columns: width > 640 ? 2 : 1
                    columnSpacing: 28
                    rowSpacing: 16

                    Repeater {
                        model: cola.grupos
                        delegate: ColumnLayout {
                            id: grupo
                            required property var modelData
                            readonly property var itens: modelData.itens.filter(it => cola.combina(it, campo.text.trim().toLowerCase()))
                            visible: itens.length > 0
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 6

                            Text {
                                text: grupo.modelData.nome
                                font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
                            }
                            Repeater {
                                model: grupo.itens
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Tecla { visible: modelData[0] !== ""; texto: modelData[0] }
                                    Text {
                                        visible: modelData[0] !== ""
                                        text: "+"
                                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
                                    }
                                    Tecla { texto: modelData[1] }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 6
                                        text: modelData[2]
                                        elide: Text.ElideRight
                                        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.suave
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component Tecla: Rectangle {
        property string texto: ""
        implicitWidth: rotulo.implicitWidth + 14
        implicitHeight: 22
        radius: 5
        color: Tema.elevado
        border.width: 1
        border.color: Tema.borda
        Text {
            id: rotulo
            anchors.centerIn: parent
            text: parent.texto
            font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto2
        }
    }
}
