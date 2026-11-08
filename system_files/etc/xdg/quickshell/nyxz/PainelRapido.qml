import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// Painel rápido: brilho de cada tela e filtro de luz azul (com horário).
// Os ajustes ficam em ~/.config/nyxz/painel.json. Nada fica rodando por causa
// deste painel: o brilho chama /usr/libexec/nyxz/brilho só quando muda, e o
// hyprsunset só existe enquanto o filtro está ligado.
PanelWindow {
    id: painel

    visible: Estado.rapidoAberto
    anchors { right: true; top: Ajustes.barraEmCima; bottom: !Ajustes.barraEmCima }
    margins { right: 10; top: Ajustes.barraEmCima ? 58 : 0; bottom: Ajustes.barraEmCima ? 0 : 58 }
    implicitWidth: 340
    implicitHeight: coluna.implicitHeight + 28
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "nyxz-rapido"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property var telas: []
    property bool lendo: false

    onVisibleChanged: if (visible) lerTelas()

    function lerTelas() {
        if (listar.running) return;
        lendo = true;
        listar.running = true;
    }

    Process {
        id: listar
        command: ["/usr/libexec/nyxz/brilho", "listar"]
        // Se o script falhar ou não existir, sai do "Procurando…" mesmo assim.
        onRunningChanged: if (!running) painel.lendo = false
        stdout: StdioCollector {
            onStreamFinished: {
                try { painel.telas = JSON.parse(this.text); } catch (e) { painel.telas = []; }
                painel.lendo = false;
            }
        }
    }

    // Aplica o brilho com uma folga curta: o DDC/CI é lento e o controle
    // deslizante manda muitos valores por segundo.
    property var pendente: ({})
    Timer {
        id: aplicarBrilho
        interval: 200
        onTriggered: {
            for (const id in painel.pendente)
                Quickshell.execDetached(["/usr/libexec/nyxz/brilho", "definir", id, String(painel.pendente[id])]);
            painel.pendente = {};
        }
    }
    function mudarBrilho(id, valor) {
        const p = pendente;
        p[id] = Math.round(valor);
        pendente = p;
        aplicarBrilho.restart();
    }

    HyprlandFocusGrab {
        windows: [painel]
        active: painel.visible
        onCleared: Estado.rapidoAberto = false
    }

    Rectangle {
        anchors.fill: parent
        radius: Tema.raioPainel
        color: Tema.painel
        border.color: Tema.bordaPainel
        border.width: 1
        focus: painel.visible
        Keys.onEscapePressed: Estado.rapidoAberto = false

        ColumnLayout {
            id: coluna
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 8

            Text {
                text: "Tela"
                font.family: Tema.fonte
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Tema.texto
            }

            // ---------------------------------------------- brilho
            Text {
                visible: painel.lendo && painel.telas.length === 0
                text: "Procurando as telas…"
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
            }
            Text {
                Layout.fillWidth: true
                visible: !painel.lendo && painel.telas.length === 0
                text: "Nenhuma tela com controle de brilho. Em monitor externo, ligue o DDC/CI no menu do próprio monitor."
                wrapMode: Text.Wrap
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
            }
            Repeater {
                model: painel.telas
                delegate: ColumnLayout {
                    id: tela
                    required property var modelData
                    property real valor: modelData.valor / 100
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: tela.modelData.nome
                            elide: Text.ElideRight
                            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
                        }
                        Text {
                            text: Math.round(tela.valor * 100) + "%"
                            font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3
                        }
                    }
                    Deslizante {
                        Layout.fillWidth: true
                        valor: tela.valor
                        onMudou: v => { tela.valor = v; painel.mudarBrilho(tela.modelData.id, v * 100); }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                color: "#1A1A20"
            }

            // ---------------------------------------------- luz azul
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Filtro de luz azul"
                    font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                }
                Text {
                    text: LuzAzul.ativo ? "ligado" : "desligado"
                    font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3
                }
            }
            Row {
                spacing: 6
                Repeater {
                    model: [
                        { id: "desligado", nome: "Desligado" },
                        { id: "ligado", nome: "Ligado" },
                        { id: "horario", nome: "No horário" }
                    ]
                    delegate: Rectangle {
                        id: opcao
                        required property var modelData
                        readonly property bool escolhida: LuzAzul.modo === modelData.id
                        width: rotulo.implicitWidth + 22
                        height: 28
                        radius: 6
                        color: escolhida ? Tema.selecionado : (areaOpcao.containsMouse ? Tema.hover : Tema.elevado)
                        border.width: 1
                        border.color: escolhida ? Tema.texto4 : Tema.borda
                        Text {
                            id: rotulo
                            anchors.centerIn: parent
                            text: opcao.modelData.nome
                            font.family: Tema.fonte; font.pixelSize: 12
                            color: opcao.escolhida ? Tema.texto : Tema.texto2
                        }
                        MouseArea {
                            id: areaOpcao
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: LuzAzul.definirModo(opcao.modelData.id)
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: LuzAzul.modo !== "desligado"
                Text { text: "Mais quente"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
                Deslizante {
                    Layout.fillWidth: true
                    // 6500 K (neutro) até 2500 K (bem quente); para a esquerda = mais quente
                    valor: (LuzAzul.temperatura - 2500) / 4000
                    onMudou: v => LuzAzul.definirTemperatura(Math.round(2500 + v * 4000))
                }
                Text {
                    text: LuzAzul.temperatura + " K"
                    font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3
                }
            }
            Text {
                visible: LuzAzul.modo === "horario"
                text: "Liga às " + LuzAzul.inicio + " e desliga às " + LuzAzul.fim + "."
                font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
            }
        }
    }
}
