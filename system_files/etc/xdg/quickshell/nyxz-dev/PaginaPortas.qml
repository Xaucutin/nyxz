import QtQuick
import QtQuick.Layouts
import Quickshell

// Portas em uso (ideia 2): quem está ouvindo em cada porta, com "Abrir no navegador"
// para servidores de desenvolvimento e "Encerrar" para processos da sua conta.
Pagina {
    id: p
    titulo: "Portas em uso"
    descricao: "Quem está usando cada porta deste computador. Servidores de desenvolvimento (Vite, Next, Python…) ganham um botão para abrir no navegador."

    property var portas: []
    property bool soDev: false
    property int encerrando: -1   // pid aguardando confirmação (-1 = nenhum)

    readonly property var visiveis: soDev ? portas.filter(x => x.dev) : portas

    Comando {
        id: ler
        onPronto: saida => { try { p.portas = JSON.parse(saida); } catch (e) { p.portas = []; } }
        Component.onCompleted: rodar(["/usr/libexec/nyxz/nyxz-dev", "portas"])
    }
    Comando {
        id: matar
        onPronto: ler.rodar(["/usr/libexec/nyxz/nyxz-dev", "portas"])
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: ler.rodar(["/usr/libexec/nyxz/nyxz-dev", "portas"])
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Interruptor { ligado: p.soDev; onAlternado: v => p.soDev = v }
        Text {
            Layout.fillWidth: true
            text: "Só servidores de desenvolvimento"
            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
        }
        Text {
            text: p.visiveis.length + (p.visiveis.length === 1 ? " porta" : " portas")
            font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3
        }
    }

    // Cabeçalho
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 12
        Text { Layout.preferredWidth: 70; text: "Porta"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
        Text { Layout.preferredWidth: 140; text: "Programa"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
        Text { Layout.fillWidth: true; text: "Endereço"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
    }

    Repeater {
        model: p.visiveis
        delegate: Rectangle {
            id: linha
            required property var modelData
            readonly property bool local: modelData.endereco.indexOf("127.") === 0 || ["::1", "localhost"].indexOf(modelData.endereco) >= 0
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 6
            color: area.containsMouse ? Tema.hover : "transparent"
            MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12
                Text {
                    Layout.preferredWidth: 62
                    text: String(linha.modelData.porta)
                    font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto
                }
                Text {
                    Layout.preferredWidth: 140
                    text: !linha.modelData.processo ? "do sistema" : linha.modelData.pid > 0 ? linha.modelData.processo + "  " + linha.modelData.pid : linha.modelData.processo
                    elide: Text.ElideRight
                    font.family: Tema.fonteMono; font.pixelSize: 12
                    color: linha.modelData.dev || linha.modelData.banco ? Tema.suave : Tema.texto3
                }
                Text {
                    Layout.fillWidth: true
                    text: linha.local ? "só este computador" : linha.modelData.endereco === "0.0.0.0" || linha.modelData.endereco === "*" ? "aberta na rede" : linha.modelData.endereco
                    elide: Text.ElideRight
                    font.family: Tema.fonte; font.pixelSize: 12
                    color: linha.local ? Tema.texto3 : Tema.aviso
                }
                Botao {
                    visible: linha.modelData.dev
                    texto: "Abrir no navegador"
                    onClicado: Quickshell.execDetached(["xdg-open", "http://localhost:" + linha.modelData.porta])
                }
                Botao {
                    visible: linha.modelData.meu && p.encerrando !== linha.modelData.pid
                    texto: "Encerrar"
                    onClicado: p.encerrando = linha.modelData.pid
                }
                Botao {
                    visible: linha.modelData.pid > 0 && p.encerrando === linha.modelData.pid
                    texto: "Confirmar"
                    perigo: true
                    onClicado: { matar.rodar(["/usr/libexec/nyxz/nyxz-dev", "portas", "encerrar", String(linha.modelData.pid)]); p.encerrando = -1; }
                }
            }
        }
    }
}
