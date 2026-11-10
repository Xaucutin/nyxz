import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Sessões de projeto (ideia 1): abrir um projeto liga os bancos dele, abre o VS Code,
// roda o comando de desenvolvimento com os segredos do cofre no ambiente e abre os links.
// Fechar desliga tudo e libera a memória.
Pagina {
    id: p
    titulo: "Projetos"
    descricao: "Cada projeto lembra a pasta, os bancos, o comando de desenvolvimento, os links e os segredos de que precisa. Um clique abre tudo; outro fecha e libera a memória."

    readonly property string cmd: "/usr/libexec/nyxz/nyxz-dev"
    property var projetos: []
    property var bancos: []
    property var segredos: []
    property string erro: ""
    property string configurando: ""
    property string logsDe: ""
    property string logs: ""
    property string removendo: ""
    // rascunho da configuração aberta
    property var rascunho: ({ bancos: [], segredos: [] })

    function atualizar() { listar.rodar([cmd, "projetos", "listar"]); }
    Component.onCompleted: {
        atualizar();
        lerBancos.rodar([cmd, "bancos", "listar"]);
        lerCofre.rodar([cmd, "cofre", "listar"]);
    }
    Timer { interval: 4000; repeat: true; running: true; onTriggered: p.atualizar() }

    Comando { id: listar; onPronto: s => { try { p.projetos = JSON.parse(s); } catch (e) { p.projetos = []; } } }
    Comando { id: lerBancos; onPronto: s => { try { p.bancos = JSON.parse(s).map(b => b.nome); } catch (e) { p.bancos = []; } } }
    Comando { id: lerCofre; onPronto: s => { try { p.segredos = JSON.parse(s).itens.map(i => i.nome); } catch (e) { p.segredos = []; } } }
    Comando {
        id: acao
        onPronto: (saida, codigo) => { p.erro = codigo === 0 ? "" : (saida.trim() || "A ação não deu certo."); p.atualizar(); }
    }
    function fazer(args) { acao.rodar(["sh", "-c", '"$0" "$@" 2>&1', cmd].concat(args)); }
    Comando { id: lerLogs; onPronto: s => p.logs = s.trim() || "(sem saída ainda)" }
    Timer {
        interval: 1500; repeat: true; triggeredOnStart: true
        running: p.logsDe !== ""
        onTriggered: lerLogs.rodar([p.cmd, "projetos", "logs", p.logsDe])
    }
    Process {
        id: salvar
        stdinEnabled: true
        onRunningChanged: if (!running) { p.configurando = ""; p.atualizar(); }
    }

    function alternar(lista, item) {
        const l = (lista || []).slice();
        const i = l.indexOf(item);
        if (i >= 0) l.splice(i, 1); else l.push(item);
        return l;
    }

    Text {
        Layout.fillWidth: true
        visible: p.erro !== ""
        text: p.erro
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.erro
    }

    // ---------------------------------------------- novo projeto
    Text { text: "Adicionar projeto"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: pNome; Layout.preferredWidth: 200; rotulo: "Nome"; validador: /^[a-z0-9][a-z0-9_-]{0,40}$/ }
        Campo { id: pPasta; Layout.fillWidth: true; rotulo: "Pasta do projeto"; text: "~/Projetos/" }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: "Adicionar"
            principal: true
            ativo: pNome.aceito && pNome.text.length > 0 && pPasta.text.length > 2
            onClicado: { p.fazer(["projetos", "adicionar", pNome.text, pPasta.text]); pNome.text = ""; }
        }
    }

    // ---------------------------------------------- projetos
    Repeater {
        model: p.projetos
        delegate: Rectangle {
            id: cartao
            required property var modelData
            Layout.fillWidth: true
            Layout.topMargin: 6
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
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle { width: 8; height: 8; radius: 4; color: cartao.modelData.aberto ? Tema.ok : Tema.texto4 }
                    Text { text: cartao.modelData.nome; font.family: Tema.fonteMono; font.pixelSize: 14; color: Tema.texto }
                    Text {
                        Layout.fillWidth: true
                        text: cartao.modelData.pasta + (cartao.modelData.existe ? "" : "  (pasta não encontrada)")
                        elide: Text.ElideMiddle
                        font.family: Tema.fonteMono; font.pixelSize: 11
                        color: cartao.modelData.existe ? Tema.texto3 : Tema.aviso
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: [
                        cartao.modelData.bancos.length ? "bancos: " + cartao.modelData.bancos.join(", ") : "",
                        cartao.modelData.comando ? "roda: " + cartao.modelData.comando : "",
                        cartao.modelData.segredos.length ? "segredos: " + cartao.modelData.segredos.join(", ") : "",
                        cartao.modelData.urls.length ? "abre: " + cartao.modelData.urls.join(", ") : ""
                    ].filter(x => x).join("   ·   ") || "Configure o que esta sessão abre."
                    wrapMode: Text.Wrap
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Botao {
                        texto: cartao.modelData.aberto ? "Fechar sessão" : "Abrir sessão"
                        principal: !cartao.modelData.aberto
                        ativo: cartao.modelData.existe
                        onClicado: p.fazer(["projetos", cartao.modelData.aberto ? "fechar" : "abrir", cartao.modelData.nome])
                    }
                    Botao {
                        texto: "Terminal"
                        ativo: cartao.modelData.existe
                        onClicado: Quickshell.execDetached(["nyx", "run", "/usr/libexec/nyxz/terminal", "-e", p.cmd, "projetos", "shell", cartao.modelData.nome])
                    }
                    Botao {
                        visible: !!cartao.modelData.comando
                        texto: p.logsDe === cartao.modelData.nome ? "Fechar saída" : "Saída"
                        onClicado: p.logsDe = p.logsDe === cartao.modelData.nome ? "" : cartao.modelData.nome
                    }
                    Botao {
                        texto: p.configurando === cartao.modelData.nome ? "Cancelar" : "Configurar"
                        onClicado: {
                            if (p.configurando === cartao.modelData.nome) { p.configurando = ""; return; }
                            p.rascunho = { bancos: cartao.modelData.bancos.slice(), segredos: cartao.modelData.segredos.slice() };
                            p.configurando = cartao.modelData.nome;
                        }
                    }
                    Botao {
                        visible: cartao.modelData.git && !cartao.modelData.protegido
                        texto: "Proteger segredos no Git"
                        onClicado: p.fazer(["projetos", "proteger", cartao.modelData.nome])
                    }
                    Text {
                        visible: cartao.modelData.protegido
                        topPadding: 8
                        text: "  Git protegido"
                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.ok
                    }
                    Botao {
                        visible: p.removendo !== cartao.modelData.nome
                        texto: "Tirar da lista"
                        onClicado: p.removendo = cartao.modelData.nome
                    }
                    Botao {
                        visible: p.removendo === cartao.modelData.nome
                        texto: "Confirmar (a pasta fica)"
                        perigo: true
                        onClicado: { p.fazer(["projetos", "remover", cartao.modelData.nome]); p.removendo = ""; }
                    }
                }

                // Configuração da sessão
                ColumnLayout {
                    visible: p.configurando === cartao.modelData.nome
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: "Bancos que ligam junto"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { visible: p.bancos.length === 0; text: "Nenhum banco criado (Dev Hub → Bancos locais)."; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
                        Repeater {
                            model: p.bancos
                            delegate: Botao {
                                required property string modelData
                                texto: modelData
                                principal: p.rascunho.bancos.indexOf(modelData) >= 0
                                onClicado: p.rascunho = Object.assign({}, p.rascunho, { bancos: p.alternar(p.rascunho.bancos, modelData) })
                            }
                        }
                    }
                    Campo {
                        id: cComando
                        Layout.fillWidth: true
                        rotulo: "Comando de desenvolvimento (ex.: npm run dev)"
                        text: cartao.modelData.comando || ""
                    }
                    Campo {
                        id: cUrls
                        Layout.fillWidth: true
                        rotulo: "Links para abrir no navegador (separados por espaço)"
                        text: (cartao.modelData.urls || []).join(" ")
                    }
                    Text { text: "Segredos do cofre que viram variáveis de ambiente"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { visible: p.segredos.length === 0; text: "Nenhum segredo no cofre (Dev Hub → Cofre)."; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
                        Repeater {
                            model: p.segredos
                            delegate: Botao {
                                required property string modelData
                                texto: modelData
                                principal: p.rascunho.segredos.indexOf(modelData) >= 0
                                onClicado: p.rascunho = Object.assign({}, p.rascunho, { segredos: p.alternar(p.rascunho.segredos, modelData) })
                            }
                        }
                    }
                    Botao {
                        texto: "Salvar"
                        principal: true
                        onClicado: {
                            salvar.command = [p.cmd, "projetos", "configurar", cartao.modelData.nome];
                            salvar.running = true;
                            salvar.write(JSON.stringify({
                                bancos: p.rascunho.bancos,
                                segredos: p.rascunho.segredos,
                                comando: cComando.text.trim(),
                                urls: cUrls.text.split(/\s+/).filter(u => u)
                            }));
                            salvar.closeStdin();
                        }
                    }
                }

                // Saída do comando de desenvolvimento
                Rectangle {
                    visible: p.logsDe === cartao.modelData.nome
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    radius: 6
                    color: Tema.fundo
                    clip: true
                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        contentHeight: textoLogs.implicitHeight
                        contentY: Math.max(0, contentHeight - height)
                        Text {
                            id: textoLogs
                            width: parent.width
                            text: p.logs
                            wrapMode: Text.WrapAnywhere
                            font.family: Tema.fonteMono; font.pixelSize: 10; color: Tema.texto2
                        }
                    }
                }
            }
        }
    }
}
