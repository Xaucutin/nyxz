import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Nyxz Doctor (ideia 27): confere o sistema ao abrir a página, explica cada problema em
// português simples e conserta com um clique quando dá. Gera um relatório sem dados
// pessoais para pedir ajuda. Nada fica rodando com a página fechada.
// Por baixo: /usr/libexec/nyxz/doctor (consertos de administrador: nyxz-doctor-root).
Pagina {
    id: p
    titulo: "Nyxz Doctor"
    descricao: "Confere vídeo, som, rede, disco, atualizações, apps, memória e serviços. Quando acha algo, explica o que é e, se der, conserta com um clique."

    readonly property string cmd: "/usr/libexec/nyxz/doctor"
    property var itens: []
    property bool verificando: false
    property string quando: ""
    property string aviso: ""
    property bool avisoErro: false
    property string relatorio: ""
    property bool verCertos: false
    property string consertando: ""
    readonly property var problemas: itens.filter(i => i.estado !== "ok")
    readonly property var certos: itens.filter(i => i.estado === "ok")

    function verificar() {
        if (cmdVerificar.running) return;
        p.verificando = true;
        cmdVerificar.rodar([cmd, "verificar"]);
    }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    function cor(e) { return { ok: Tema.ok, aviso: Tema.aviso, erro: Tema.erro }[e] || Tema.texto3; }
    Component.onCompleted: verificar()
    Timer { id: limpa; interval: 9000; onTriggered: p.aviso = "" }

    Comando {
        id: cmdVerificar
        onPronto: (s, codigo) => {
            p.verificando = false;
            try { p.itens = JSON.parse(s); } catch (e) { p.avisar("Não deu para verificar o sistema.", true); }
            p.quando = Qt.formatTime(new Date(), "HH:mm");
        }
    }
    Process {
        id: acao
        stdinEnabled: true
        property string ok: ""
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => {
            p.consertando = "";
            if (codigo === 0) p.avisar(acao.ok || "Pronto.", false);
            else p.avisar(erroAcao.text.trim() || "Não deu certo.", true);
            p.verificar();
        }
    }
    function consertar(item, c, senha) {
        if (c.pagina) { Quickshell.execDetached(["/usr/libexec/nyxz/configuracoes", c.pagina]); return; }
        if (acao.running) return;
        p.consertando = item.id;
        acao.ok = c.programa ? "" : item.titulo + ": consertado.";
        acao.command = [p.cmd, "consertar", c.id].concat(c.arg ? [c.arg] : []);
        acao.running = true;
        if (senha !== undefined) acao.write(senha);
        acao.closeStdin();
    }
    Process {
        id: cmdRelatorio
        stdout: StdioCollector { id: saidaRelatorio }
        stderr: StdioCollector { id: erroRelatorio }
        onExited: codigo => {
            if (codigo === 0) p.relatorio = saidaRelatorio.text.trim();
            else p.avisar(erroRelatorio.text.trim() || "Não deu para gerar o relatório.", true);
        }
    }

    // ------------------------------------------------ resumo
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: p.verificando && !p.itens.length ? "Verificando…"
                    : p.problemas.length === 0 ? "Tudo certo"
                    : p.problemas.length === 1 ? "1 coisa para olhar" : p.problemas.length + " coisas para olhar"
                font.family: Tema.fonte; font.pixelSize: 17; font.weight: Font.Medium
                color: p.verificando && !p.itens.length ? Tema.texto2
                    : p.problemas.some(i => i.estado === "erro") ? Tema.erro
                    : p.problemas.length ? Tema.aviso : Tema.ok
            }
            Text {
                visible: p.quando !== ""
                text: (p.verificando ? "Verificando de novo…" : "Verificado às " + p.quando) + "  ·  " + p.certos.length + " sem problemas"
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
            }
        }
        Botao { texto: "Verificar de novo"; ativo: !p.verificando; onClicado: p.verificar() }
        Botao {
            texto: cmdRelatorio.running ? "Gerando…" : "Gerar relatório"
            ativo: !cmdRelatorio.running
            onClicado: { p.relatorio = ""; cmdRelatorio.command = [p.cmd, "relatorio"]; cmdRelatorio.running = true; }
        }
    }
    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }

    // Relatório gerado
    Rectangle {
        visible: p.relatorio !== ""
        Layout.fillWidth: true
        Layout.preferredHeight: colRel.implicitHeight + 24
        radius: Tema.raio
        color: Tema.elevado
        border.width: 1
        border.color: Tema.borda
        ColumnLayout {
            id: colRel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Relatório salvo em " + p.relatorio.replace(Quickshell.env("HOME"), "~") + ". Ele não tem seu nome de usuário, o nome do computador, IPs, e-mails nem números de série: dá para mandar num fórum ou para um amigo."
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Botao {
                    texto: "Copiar o texto"
                    onClicado: { Quickshell.execDetached(["sh", "-c", "wl-copy < \"$1\"", "sh", p.relatorio]); p.avisar("Relatório copiado.", false); }
                }
                Botao { texto: "Abrir"; onClicado: Quickshell.execDetached(["xdg-open", p.relatorio]) }
            }
        }
    }

    // ------------------------------------------------ problemas
    Repeater {
        model: p.problemas
        delegate: Rectangle {
            id: cartao
            required property var modelData
            readonly property var it: modelData
            Layout.fillWidth: true
            Layout.preferredHeight: corpo.implicitHeight + 28
            radius: Tema.raio
            color: Tema.elevado
            border.width: 1
            border.color: Tema.borda

            RowLayout {
                id: corpo
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 5
                    implicitWidth: 8; implicitHeight: 8; radius: 4
                    color: p.cor(cartao.it.estado)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: cartao.it.area + "  ·  " + cartao.it.titulo
                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: cartao.it.texto
                        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                    }
                    // Destravar o chaveiro: a senha é digitada aqui (no estilo da Nyxz)
                    RowLayout {
                        visible: cartao.it.consertos.some(c => c.senha)
                        Layout.fillWidth: true
                        spacing: 8
                        Campo {
                            id: senha
                            Layout.fillWidth: true
                            rotulo: "Senha do chaveiro (normalmente a do computador)"
                            oculto: true
                            onConfirmado: botaoSenha.clicado()
                        }
                        Botao {
                            id: botaoSenha
                            Layout.alignment: Qt.AlignBottom
                            texto: p.consertando === cartao.it.id ? "Destravando…" : "Destravar"
                            principal: true
                            ativo: senha.text !== "" && !acao.running
                            onClicado: {
                                if (!ativo) return;
                                p.consertar(cartao.it, cartao.it.consertos.find(c => c.senha), senha.text);
                                senha.text = "";
                            }
                        }
                    }
                    Flow {
                        visible: cartao.it.consertos.some(c => !c.senha)
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: cartao.it.consertos.filter(c => !c.senha)
                            delegate: Botao {
                                required property var modelData
                                required property int index
                                texto: p.consertando === cartao.it.id && !modelData.pagina ? "Consertando…" : modelData.rotulo
                                principal: index === 0 && !modelData.pagina
                                ativo: !acao.running
                                onClicado: p.consertar(cartao.it, modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------ o que está certo
    Text {
        visible: p.certos.length > 0
        Layout.topMargin: 10
        text: (p.verCertos ? "▾ " : "▸ ") + "Sem problemas (" + p.certos.length + ")"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: p.verCertos = !p.verCertos }
    }
    Repeater {
        model: p.verCertos ? p.certos : []
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Rectangle { Layout.alignment: Qt.AlignTop; Layout.topMargin: 6; implicitWidth: 6; implicitHeight: 6; radius: 3; color: Tema.ok }
            Text {
                Layout.preferredWidth: 190
                Layout.alignment: Qt.AlignTop
                text: modelData.titulo
                elide: Text.ElideRight
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
            }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: modelData.texto
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
            }
        }
    }
}
