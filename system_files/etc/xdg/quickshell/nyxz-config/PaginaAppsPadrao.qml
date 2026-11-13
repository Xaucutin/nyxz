import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Apps padrão e tipos de arquivo (como no Windows). Por baixo: /usr/libexec/nyxz/apps-padrao.
Pagina {
    id: p
    titulo: "Apps padrão"
    descricao: "Qual app abre cada coisa: links, e-mail, música, vídeo, imagens, PDF… e, mais abaixo, qualquer extensão de arquivo."

    readonly property string cmd: "/usr/libexec/nyxz/apps-padrao"
    property var lista: []
    property var ext: null
    property string aviso: ""

    function atualizar() { cmdListar.rodar([cmd, "listar"]); }
    Component.onCompleted: atualizar()
    Comando { id: cmdListar; onPronto: s => { try { p.lista = JSON.parse(s); } catch (e) {} } }
    Comando { id: cmdExt; onPronto: s => { try { p.ext = JSON.parse(s); p.aviso = ""; } catch (e) { p.ext = null; p.aviso = "Extensão desconhecida."; } } }
    Process {
        id: acao
        onExited: { p.atualizar(); if (p.ext) cmdExt.rodar([p.cmd, "extensao", campoExt.text.trim()]); }
        function rodar(c) { if (!running) { command = c; running = true; } }
    }

    Repeater {
        model: p.lista
        delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Text { Layout.topMargin: 6; text: modelData.nome; font.family: Tema.fonte; font.pixelSize: 13; font.weight: Font.Medium; color: Tema.texto }
            Text {
                visible: modelData.apps.length === 0
                text: "Nenhum app instalado abre isso."
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto4
            }
            Escolhas {
                Layout.fillWidth: true
                apps: modelData.apps
                atual: modelData.atual
                onEscolhido: id => acao.rodar([p.cmd, "definir", modelData.id, id])
            }
        }
    }

    Text { Layout.topMargin: 16; text: "Por extensão de arquivo"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: campoExt; Layout.fillWidth: true; rotulo: "Extensão (ex.: .mkv, .md, .svg)"; onConfirmado: cmdExt.rodar([p.cmd, "extensao", text.trim()]) }
        Botao { Layout.alignment: Qt.AlignBottom; texto: "Ver"; ativo: campoExt.text.trim() !== ""; onClicado: cmdExt.rodar([p.cmd, "extensao", campoExt.text.trim()]) }
    }
    Text { visible: p.aviso !== ""; text: p.aviso; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.erro }
    Escolhas {
        visible: p.ext !== null
        Layout.fillWidth: true
        apps: p.ext ? p.ext.apps : []
        atual: p.ext ? p.ext.atual : ""
        onEscolhido: id => acao.rodar([p.cmd, "extensao", campoExt.text.trim(), id])
    }

    component Escolhas: Flow {
        id: f
        property var apps: []
        property string atual: ""
        signal escolhido(string id)
        spacing: 6
        Repeater {
            model: f.apps
            delegate: Rectangle {
                required property var modelData
                readonly property bool marcado: f.atual === modelData.id
                implicitWidth: rot.implicitWidth + 20
                implicitHeight: 26
                radius: 13
                color: marcado ? Tema.selecionado : area.containsMouse ? Tema.hover : "transparent"
                border.width: 1
                border.color: marcado ? Tema.bordaPainel : Tema.borda
                Text { id: rot; anchors.centerIn: parent; text: parent.modelData.nome; font.family: Tema.fonte; font.pixelSize: 12; color: parent.marcado ? Tema.texto : Tema.texto2 }
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: f.escolhido(parent.modelData.id) }
            }
        }
    }
}
