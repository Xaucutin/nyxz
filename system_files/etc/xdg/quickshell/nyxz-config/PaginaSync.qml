import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Nyxz Sync (ideia 13): configurações num repositório privado do próprio usuário no
// GitHub. Senhas e tokens nunca entram. Por baixo: /usr/libexec/nyxz/sync.
Pagina {
    id: p
    titulo: "Nyxz Sync"
    descricao: "Guarda as suas configurações (Ajustes, atalhos, automações, telas, VS Code, terminal e a lista de apps) num repositório privado seu no GitHub. Numa instalação nova, é só entrar e restaurar. Senhas e tokens nunca entram: ficam no Cofre."

    readonly property string cmd: "/usr/libexec/nyxz/sync"
    property var e: null
    property string codigo: ""
    property string aviso: ""
    property bool avisoErro: false
    property bool verLista: false
    property var restaurado: null

    function atualizar() { cmdEstado.rodar([cmd, "estado"]); }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    Component.onCompleted: atualizar()
    Timer { id: limpa; interval: 9000; onTriggered: p.aviso = "" }

    Comando { id: cmdEstado; onPronto: s => { try { p.e = JSON.parse(s); } catch (x) {} } }
    Process {
        id: acao
        property string ok: ""
        stdout: SplitParser {
            onRead: linha => {
                try {
                    const d = JSON.parse(linha);
                    if (d.codigo) p.codigo = d.codigo;
                    if (d.pronto) { p.codigo = ""; conectar.running = true; }
                    if (d.restaurados !== undefined) p.restaurado = d;
                    if (d.conectado && d.temConfiguracoes) p.avisar("Conectado. Este repositório já tem configurações: use \"Restaurar\" para trazê-las.", false);
                } catch (x) {}
            }
        }
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => {
            if (codigo === 0) { if (acao.ok) p.avisar(acao.ok, false); }
            else p.avisar(erroAcao.text.trim() || "Não deu certo.", true);
            p.atualizar();
        }
        function rodar(c, msg) { if (running) return; ok = msg || ""; command = c; running = true; }
    }
    Process {
        id: conectar
        command: [p.cmd, "conectar"]
        stderr: StdioCollector { id: erroConectar }
        onExited: codigo => { if (codigo !== 0) p.avisar(erroConectar.text.trim(), true); else acao.rodar([p.cmd, "enviar"], "Conectado e enviado."); }
    }

    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }

    // ------------------------------------------------ desconectado
    ColumnLayout {
        visible: p.e !== null && !p.e.conectado
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: p.e && !p.e.gh ? "Falta o GitHub CLI nesta versão. Atualize a Nyxz." : "Você entra no GitHub pelo navegador (com um código de uso único) e a Nyxz cria o repositório privado \"nyxz-sync\" na sua conta. O acesso fica guardado no Cofre."
            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto2
        }
        Botao {
            visible: p.e && p.e.gh
            texto: acao.running ? "Esperando o GitHub…" : "Entrar com o GitHub"
            principal: true
            ativo: !acao.running && !conectar.running
            onClicado: acao.rodar([p.cmd, "entrar"], "")
        }
        Rectangle {
            visible: p.codigo !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: colCodigo.implicitHeight + 24
            radius: Tema.raio
            color: Tema.elevado
            border.width: 1
            border.color: Tema.bordaPainel
            ColumnLayout {
                id: colCodigo
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 12
                spacing: 6
                Text { text: "No navegador que abriu, digite este código:"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2 }
                Text { text: p.codigo; font.family: Tema.fonteMono; font.pixelSize: 24; font.weight: Font.Medium; color: Tema.texto }
                Botao { texto: "Copiar o código"; onClicado: Quickshell.execDetached(["wl-copy", p.codigo]) }
            }
        }
    }

    // ------------------------------------------------ conectado
    ColumnLayout {
        visible: p.e !== null && p.e.conectado
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "Conectado" + (p.e && p.e.conta ? " como " + p.e.conta : "") + (p.e && p.e.repositorio ? " · " + p.e.repositorio.replace("https://", "") : "")
            font.family: Tema.fonte; font.pixelSize: 14; font.weight: Font.Medium; color: Tema.texto
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: p.e ? (p.e.erro ? "Último envio falhou: " + p.e.erro : p.e.ultimo ? "Último envio: " + p.e.ultimo.slice(8, 10) + "/" + p.e.ultimo.slice(5, 7) + " às " + p.e.ultimo.slice(11, 16) + ". Envia sozinho quando algo muda." : "Ainda não enviou nada.") : ""
            font.family: Tema.fonte; font.pixelSize: 12; color: p.e && p.e.erro ? Tema.erro : Tema.texto3
        }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            Botao { texto: acao.running ? "Enviando…" : "Enviar agora"; principal: true; ativo: !acao.running; onClicado: acao.rodar([p.cmd, "enviar"], "Enviado.") }
            Botao { texto: "Restaurar deste repositório"; ativo: !acao.running; onClicado: acao.rodar([p.cmd, "restaurar"], "Configurações restauradas.") }
            Botao { texto: "Abrir no GitHub"; visible: p.e && p.e.repositorio.indexOf("http") === 0; onClicado: Quickshell.execDetached(["xdg-open", p.e.repositorio]) }
            Botao { texto: "Parar de sincronizar"; perigo: true; onClicado: acao.rodar([p.cmd, "desconectar"], "O Sync foi desligado. O repositório continua no GitHub.") }
        }
        Text {
            visible: p.restaurado !== null
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: p.restaurado ? p.restaurado.restaurados + " arquivos restaurados" + (p.restaurado.copiaAntes ? " (os de antes estão em " + p.restaurado.copiaAntes.replace(Quickshell.env("HOME"), "~") + ")" : "") + ". Saia e entre de novo para tudo valer."
                  + (p.restaurado.componentes && p.restaurado.componentes.flatpaks && p.restaurado.componentes.flatpaks.length ? " A lista tinha " + p.restaurado.componentes.flatpaks.length + " apps: instale em Apps e componentes." : "") : ""
            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.ok
        }
    }

    // ------------------------------------------------ o que entra
    Text {
        visible: p.e !== null
        Layout.topMargin: 12
        text: (p.verLista ? "▾ " : "▸ ") + "O que entra (" + (p.e ? p.e.entram.length : 0) + " arquivos)" + (p.e && p.e.fora.length ? " · " + p.e.fora.length + " ficam de fora" : "")
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: p.verLista = !p.verLista }
    }
    Repeater {
        model: p.verLista && p.e ? p.e.fora : []
        delegate: Text {
            required property var modelData
            Layout.fillWidth: true
            elide: Text.ElideMiddle
            text: "Fora: ~/" + modelData.arquivo + " (" + modelData.motivo + ")"
            font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.aviso
        }
    }
    Repeater {
        model: p.verLista && p.e ? p.e.entram : []
        delegate: Text {
            required property var modelData
            Layout.fillWidth: true
            elide: Text.ElideMiddle
            text: "~/" + modelData
            font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3
        }
    }
    Text {
        Layout.topMargin: 8
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Nunca entram: arquivos .env, chaves SSH, o Cofre, tokens e qualquer arquivo que pareça ter uma senha. O repositório é sempre privado."
        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
    }
}
