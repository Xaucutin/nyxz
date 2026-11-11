import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Modo streamer (ideia 29): ajustes. Quem liga, cobre as janelas e guarda as
// notificações é o shell (Streamer.qml e VeuStreamer.qml); aqui só se escolhe o que esconder.
Pagina {
    id: p
    titulo: "Modo streamer"
    descricao: "Liga sozinho quando a tela é transmitida ou gravada (OBS, Discord, Nyxz Share…). Enquanto ligado, guarda as notificações, cobre janelas com senhas ou arquivos .env e esconde IPs e senhas nas Configurações."

    property bool auto: true
    property bool notificacoes: true
    property var palavras: []
    property var janelas: []
    property bool carregado: false

    FileView {
        id: arquivo
        path: Quickshell.env("HOME") + "/.config/nyxz/streamer.json"
        printErrors: false
        blockLoading: true
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d.auto !== undefined) p.auto = d.auto;
                if (d.notificacoes !== undefined) p.notificacoes = d.notificacoes;
                if (d.palavras) p.palavras = d.palavras;
                if (d.janelas) p.janelas = d.janelas;
            } catch (e) {}
            p.carregado = true;
        }
        onLoadFailed: {
            p.palavras = [".env", "senha", "password", "cofre", "secret", "token", "keepass", "bitwarden", "1password", "chaveiro"];
            p.janelas = ["keepassxc", "bitwarden", "seahorse"];
            p.carregado = true;
        }
    }
    function salvar() {
        arquivo.setText(JSON.stringify({ auto: p.auto, notificacoes: p.notificacoes, palavras: p.palavras, janelas: p.janelas }, null, 2));
    }
    function lista(t) { return t.split(",").map(x => x.trim()).filter(x => x); }

    // Janelas abertas (para escolher quais cobrir)
    property var abertas: []
    Process {
        running: true
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const v = [];
                    for (const c of JSON.parse(this.text)) if (c.class && v.indexOf(c.class) < 0) v.push(c.class);
                    p.abertas = v;
                } catch (e) {}
            }
        }
    }

    // ------------------------------------------------ agora
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: ModoStreamer.ativo ? "Ligado agora" : "Desligado agora"; font.family: Tema.fonte; font.pixelSize: 15; font.weight: Font.Medium; color: ModoStreamer.ativo ? Tema.aviso : Tema.texto }
            Text { text: "Também dá para ligar no painel rápido. Na barra aparece \"streamer\" enquanto está ligado."; Layout.fillWidth: true; wrapMode: Text.Wrap; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        }
        Botao {
            texto: ModoStreamer.ativo ? "Desligar" : "Ligar agora"
            principal: !ModoStreamer.ativo
            onClicado: Quickshell.execDetached(["qs", "-c", "nyxz", "ipc", "call", "streamer", "alternar"])
        }
    }

    // ------------------------------------------------ ajustes
    RowLayout {
        Layout.topMargin: 10
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: "Ligar sozinho"; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Quando algum app capturar a tela, com o OBS aberto ou transmitindo pelo Nyxz Share."; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        }
        Interruptor { ligado: p.auto; onAlternado: v => { p.auto = v; p.salvar(); } }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: "Guardar as notificações"; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Nenhuma aparece na tela; ficam na lista para ver depois."; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        }
        Interruptor { ligado: p.notificacoes; onAlternado: v => { p.notificacoes = v; p.salvar(); } }
    }

    Text { Layout.topMargin: 12; text: "Janelas cobertas"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Uma capa escura fica por cima da janela, inclusive no que é transmitido. O mouse e o teclado continuam funcionando nela."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo {
            id: campoPalavras
            Layout.fillWidth: true
            rotulo: "Título da janela contém (separe por vírgula)"
            Component.onCompleted: if (p.carregado) text = p.palavras.join(", ")
            onConfirmado: { p.palavras = p.lista(text); p.salvar(); }
        }
        Botao { Layout.alignment: Qt.AlignBottom; texto: "Salvar"; onClicado: { p.palavras = p.lista(campoPalavras.text); p.salvar(); } }
    }
    Connections {
        target: p
        function onCarregadoChanged() { campoPalavras.text = p.palavras.join(", "); }
    }
    Text { text: "Apps sempre cobertos (clique para marcar ou desmarcar)"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: p.janelas.concat(p.abertas.filter(a => !p.janelas.some(j => a.toLowerCase().indexOf(j.toLowerCase()) >= 0)))
            delegate: Rectangle {
                required property string modelData
                readonly property bool marcado: p.janelas.indexOf(modelData) >= 0
                implicitWidth: rotuloJ.implicitWidth + 20
                implicitHeight: 26
                radius: 13
                color: marcado ? Tema.selecionado : areaJ.containsMouse ? Tema.hover : "transparent"
                border.width: 1
                border.color: marcado ? Tema.bordaPainel : Tema.borda
                Text { id: rotuloJ; anchors.centerIn: parent; text: parent.modelData; font.family: Tema.fonte; font.pixelSize: 12; color: parent.marcado ? Tema.texto : Tema.texto3 }
                MouseArea {
                    id: areaJ
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const l = p.janelas.slice();
                        const i = l.indexOf(parent.modelData);
                        if (i >= 0) l.splice(i, 1); else l.push(parent.modelData);
                        p.janelas = l;
                        p.salvar();
                    }
                }
            }
        }
    }
}
