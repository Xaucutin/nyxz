import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Voltar no tempo (ideia 19): fotos da pasta pessoal pelo Snapper (Btrfs), de hora em
// hora, e restauração de qualquer arquivo ou pasta. Também abre pelo Dolphin
// (botão direito → "Versões anteriores"). Por baixo: /usr/libexec/nyxz/voltar-no-tempo.
Pagina {
    id: p
    titulo: "Voltar no tempo"
    descricao: "Fotos da sua pasta pessoal de hora em hora. Apagou ou estragou um arquivo? Volte para a versão de antes. As fotos só guardam o que mudou, então ocupam pouco espaço."

    readonly property string cmd: "/usr/libexec/nyxz/voltar-no-tempo"
    property var e: null
    property var v: null                   // versões do arquivo escolhido
    property string aviso: ""
    property bool avisoErro: false
    property int substituindo: -1

    function atualizar() { cmdEstado.rodar([cmd, "estado"]); }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    Component.onCompleted: atualizar()
    Timer { id: limpa; interval: 8000; onTriggered: p.aviso = "" }

    // Pedido vindo do Dolphin ("Versões anteriores")
    FileView {
        id: pedido
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/nyxz-voltar-arquivo"
        watchChanges: true
        printErrors: false
        onLoaded: { const t = text().trim(); if (t) { arquivo.text = t; p.verVersoes(); } }
        onFileChanged: reload()
    }

    function verVersoes() {
        if (arquivo.text.trim()) { p.v = null; cmdVersoes.rodar([cmd, "versoes", arquivo.text.trim()]); }
    }
    function data(iso) { return iso ? iso.slice(8, 10) + "/" + iso.slice(5, 7) + " às " + iso.slice(11, 16) : ""; }
    function tamanho(b) {
        const u = ["B", "KB", "MB", "GB"]; let i = 0, x = b || 0;
        while (x >= 1000 && i < 3) { x /= 1000; i++; }
        return x.toFixed(i ? 1 : 0).replace(".", ",") + " " + u[i];
    }

    Comando { id: cmdEstado; onPronto: s => { try { p.e = JSON.parse(s); } catch (x) {} } }
    Comando { id: cmdVersoes; onPronto: (s, codigo) => { try { p.v = JSON.parse(s); } catch (x) { p.avisar("Esse arquivo não está na pasta pessoal.", true); } } }
    Process {
        id: acao
        property string ok: ""
        stdout: StdioCollector { id: saida }
        stderr: StdioCollector { id: erro }
        onExited: codigo => {
            if (codigo === 0) p.avisar(acao.ok.replace("%s", saida.text.trim()), false);
            else p.avisar(erro.text.trim() || "Não deu certo.", true);
            p.atualizar();
            if (p.v) p.verVersoes();
        }
        function rodar(c, msg) { if (running) return; ok = msg || ""; command = c; running = true; }
    }

    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }

    // ------------------------------------------------ desligado
    ColumnLayout {
        visible: p.e !== null && !p.e.ligado
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: p.e && !p.e.instalado ? "O Voltar no tempo não está instalado nesta versão."
                : "Ao ligar, a Nyxz guarda as últimas 24 fotos de hora em hora, 7 diárias e 4 semanais. Pastas pesadas e descartáveis ficam de fora: caches, os jogos da Steam e os containers do Podman. Pede a senha uma vez."
            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto2
        }
        Botao {
            visible: p.e && p.e.instalado
            texto: acao.running ? "Ligando…" : "Ligar o Voltar no tempo"
            principal: true
            ativo: !acao.running
            onClicado: acao.rodar([p.cmd, "ativar"], "Ligado. A primeira foto já foi tirada.")
        }
    }

    // ------------------------------------------------ ligado
    ColumnLayout {
        visible: p.e !== null && p.e.ligado
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: p.e && p.e.fotos.length ? p.e.fotos.length + " fotos guardadas. A mais recente é de " + p.data(p.e.fotos[0].data) + "." : "Nenhuma foto ainda."
                font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
            }
            Botao { texto: "Tirar uma foto agora"; ativo: !acao.running; onClicado: acao.rodar([p.cmd, "foto"], "Foto tirada.") }
        }

        // Achar versões de um arquivo ou pasta
        Text { Layout.topMargin: 10; text: "Recuperar um arquivo ou pasta"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "Arraste o arquivo do Dolphin para cá, digite o caminho ou use o botão direito nele → \"Versões anteriores\". Funciona até com arquivos apagados: digite o caminho onde ele estava."
            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Item {
                Layout.fillWidth: true
                implicitHeight: arquivo.implicitHeight
                Campo { id: arquivo; width: parent.width; rotulo: "Arquivo ou pasta"; onConfirmado: p.verVersoes() }
                DropArea {
                    anchors.fill: parent
                    onDropped: d => { if (d.hasUrls) { arquivo.text = decodeURIComponent(d.urls[0].toString().replace("file://", "")); p.verVersoes(); } }
                }
            }
            Botao { Layout.alignment: Qt.AlignBottom; texto: "Ver versões"; ativo: arquivo.text.trim() !== ""; onClicado: p.verVersoes() }
        }
        Text {
            visible: p.v !== null && p.v.versoes.length === 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "Nenhuma versão diferente nas fotos" + (p.v && p.v.existe ? ": o arquivo está igual desde a foto mais antiga." : ".")
            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
        }
        Repeater {
            model: p.v ? p.v.versoes : []
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: "Como estava em " + p.data(modelData.modificado) + (modelData.pasta ? "  ·  pasta" : "  ·  " + p.tamanho(modelData.tamanho))
                    elide: Text.ElideRight
                    font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                }
                Botao {
                    texto: "Restaurar como cópia"
                    principal: true
                    ativo: !acao.running
                    onClicado: acao.rodar([p.cmd, "restaurar", String(modelData.foto), p.v.arquivo], "Restaurado em %s")
                }
                Botao {
                    visible: p.v.existe && p.substituindo !== modelData.foto
                    texto: "Substituir"
                    onClicado: p.substituindo = modelData.foto
                }
                Botao {
                    visible: p.substituindo === modelData.foto
                    texto: "Confirmar (a atual vai para a lixeira)"
                    perigo: true
                    onClicado: { acao.rodar([p.cmd, "restaurar", String(modelData.foto), p.v.arquivo, "substituir"], "Substituído. A versão de antes está na lixeira."); p.substituindo = -1; }
                }
            }
        }

        // Fotos e o que fica de fora
        Text { Layout.topMargin: 14; text: "Fotos recentes"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
        Repeater {
            model: p.e ? p.e.fotos.slice(0, 8) : []
            delegate: Text {
                required property var modelData
                text: p.data(modelData.data) + "  ·  " + ({ timeline: "de hora em hora", number: "manual" }[modelData.tipo] || modelData.descricao || "foto")
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
            }
        }
        Text {
            Layout.topMargin: 8
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "Fora das fotos: " + (p.e ? p.e.fora.map(f => f.pasta).join(", ") : "")
            font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
        }
        Botao {
            Layout.topMargin: 10
            texto: "Desligar e apagar as fotos"
            perigo: true
            onClicado: acao.rodar([p.cmd, "desativar"], "Desligado. As fotos foram apagadas.")
        }
    }
}
