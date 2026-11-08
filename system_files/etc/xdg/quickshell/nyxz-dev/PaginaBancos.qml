import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Bancos locais (estilo XAMPP): cada banco num container Podman da sua conta,
// só na sua máquina (127.0.0.1), com os dados guardados num volume próprio.
// Quem faz o trabalho é /usr/libexec/nyxz/nyxz-dev.
Pagina {
    id: p
    titulo: "Bancos locais"
    descricao: "PostgreSQL, MariaDB, MySQL, Redis e MongoDB para desenvolvimento, cada um isolado e só acessível neste computador. Ligue só quando for usar: parado não gasta memória."

    readonly property string cmd: "/usr/libexec/nyxz/nyxz-dev"
    property var tipos: ({})
    property var bancos: []
    property string tipo: "postgres"
    property string versao: ""
    property string passoAtual: ""
    property string ultimoLog: ""
    property string erro: ""
    property bool criando: false
    property string logsDe: ""
    property string logsTexto: ""
    property string removendo: ""

    function senhaNova() {
        const c = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        let s = "";
        for (let i = 0; i < 16; i++) s += c[Math.floor(Math.random() * c.length)];
        return s;
    }
    function escolherTipo(t) {
        tipo = t;
        versao = tipos[t] ? tipos[t].versoes[0] : "";
        campoPorta.text = tipos[t] ? String(tipos[t].porta) : "";
    }
    function atualizar() { listar.rodar([cmd, "bancos", "listar"]); }

    Comando {
        id: lerTipos
        onPronto: saida => {
            try { p.tipos = JSON.parse(saida); p.escolherTipo(p.tipo); } catch (e) {}
        }
        Component.onCompleted: rodar([p.cmd, "bancos", "tipos"])
    }
    Comando {
        id: listar
        onPronto: saida => { try { p.bancos = JSON.parse(saida); } catch (e) { p.bancos = []; } }
        Component.onCompleted: p.atualizar()
    }
    Comando {
        id: acao
        onPronto: (saida, codigo) => {
            if (codigo !== 0) p.erro = saida.trim() || "A ação não deu certo.";
            p.atualizar();
        }
    }
    Comando {
        id: logs
        onPronto: saida => p.logsTexto = saida.trim() || "(sem logs ainda)"
    }
    // Atualiza o estado de vez em quando (um banco pode parar sozinho)
    Timer { interval: 5000; running: true; repeat: true; onTriggered: if (!listar.running) p.atualizar() }

    // Criação com progresso ao vivo (PASSO/LOG/FIM)
    Process {
        id: criar
        stdout: SplitParser {
            onRead: linha => {
                const [tipoLinha, ...resto] = linha.split("|");
                if (tipoLinha === "PASSO") p.passoAtual = resto.join("|");
                else if (tipoLinha === "LOG") p.ultimoLog = resto.join("|");
                else if (tipoLinha === "FIM") {
                    if (resto[0] === "erro") p.erro = resto.slice(1).join("|");
                    else { campoNome.text = ""; campoSenha.text = p.senhaNova(); }
                }
            }
        }
        onRunningChanged: if (!running) { p.criando = false; p.passoAtual = ""; p.ultimoLog = ""; p.atualizar(); }
    }

    // ---------------------------------------------- novo banco
    Text { text: "Novo banco"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: Object.keys(p.tipos)
            delegate: Botao {
                required property string modelData
                texto: p.tipos[modelData].nome
                principal: p.tipo === modelData
                onClicado: p.escolherTipo(modelData)
            }
        }
    }
    RowLayout {
        spacing: 6
        Text { Layout.preferredWidth: 90; text: "Versão"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        Repeater {
            model: p.tipos[p.tipo] ? p.tipos[p.tipo].versoes : []
            delegate: Botao {
                required property string modelData
                texto: modelData
                principal: p.versao === modelData
                onClicado: p.versao = modelData
            }
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 10
        rowSpacing: 8
        Campo { id: campoNome; Layout.fillWidth: true; rotulo: "Nome (ex.: loja)"; validador: /^[a-z0-9][a-z0-9_-]{0,30}$/ }
        Campo { id: campoPorta; Layout.fillWidth: true; rotulo: "Porta"; validador: /^[0-9]{2,5}$/ }
        Campo { id: campoUsuario; Layout.fillWidth: true; rotulo: "Usuário"; text: "dev" }
        Campo { id: campoSenha; Layout.fillWidth: true; rotulo: "Senha"; text: p.senhaNova() }
    }
    RowLayout {
        Layout.fillWidth: true
        Botao {
            texto: p.criando ? "Criando…" : "Criar e ligar"
            principal: true
            ativo: !p.criando && campoNome.aceito && campoPorta.aceito && campoUsuario.text.length > 0 && campoSenha.text.length > 0
            onClicado: {
                p.erro = "";
                p.criando = true;
                criar.command = [p.cmd, "bancos", "criar", p.tipo, p.versao, campoNome.text, campoPorta.text, campoUsuario.text, campoSenha.text];
                criar.running = true;
            }
        }
        Text {
            Layout.fillWidth: true
            visible: p.criando
            text: p.passoAtual + (p.ultimoLog ? "  ·  " + p.ultimoLog : "")
            elide: Text.ElideRight
            font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3
        }
    }
    Text {
        Layout.fillWidth: true
        visible: p.erro !== ""
        text: p.erro
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.erro
    }

    // ---------------------------------------------- bancos criados
    Text {
        Layout.topMargin: 14
        text: p.bancos.length ? "Seus bancos" : "Nenhum banco ainda."
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Repeater {
        model: p.bancos
        delegate: Rectangle {
            id: cartao
            required property var modelData
            Layout.fillWidth: true
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
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: cartao.modelData.ligado ? Tema.ok : Tema.texto4
                    }
                    Text {
                        text: cartao.modelData.nome
                        font.family: Tema.fonteMono; font.pixelSize: 14; color: Tema.texto
                    }
                    Text {
                        Layout.fillWidth: true
                        text: cartao.modelData.tipoNome + " " + cartao.modelData.versao + " · porta " + cartao.modelData.porta +
                              (cartao.modelData.ligado ? " · ligado" : cartao.modelData.estado === "ausente" ? " · container sumiu" : " · parado")
                        elide: Text.ElideRight
                        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: cartao.modelData.conexao
                    elide: Text.ElideMiddle
                    font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto2
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Botao {
                        texto: cartao.modelData.ligado ? "Parar" : "Ligar"
                        principal: !cartao.modelData.ligado
                        onClicado: acao.rodar([p.cmd, "bancos", cartao.modelData.ligado ? "parar" : "iniciar", cartao.modelData.nome])
                    }
                    Botao {
                        texto: "Copiar conexão"
                        onClicado: Quickshell.execDetached(["wl-copy", cartao.modelData.conexao])
                    }
                    Botao {
                        texto: p.logsDe === cartao.modelData.nome ? "Fechar logs" : "Logs"
                        onClicado: {
                            if (p.logsDe === cartao.modelData.nome) { p.logsDe = ""; return; }
                            p.logsDe = cartao.modelData.nome;
                            p.logsTexto = "Carregando…";
                            logs.rodar([p.cmd, "bancos", "logs", cartao.modelData.nome]);
                        }
                    }
                    Botao {
                        visible: p.removendo !== cartao.modelData.nome
                        texto: "Remover"
                        onClicado: p.removendo = cartao.modelData.nome
                    }
                    Botao {
                        visible: p.removendo === cartao.modelData.nome
                        texto: "Remover e apagar os dados"
                        perigo: true
                        onClicado: { acao.rodar([p.cmd, "bancos", "remover", cartao.modelData.nome, "--apagar-dados"]); p.removendo = ""; }
                    }
                    Botao {
                        visible: p.removendo === cartao.modelData.nome
                        texto: "Remover e guardar os dados"
                        onClicado: { acao.rodar([p.cmd, "bancos", "remover", cartao.modelData.nome]); p.removendo = ""; }
                    }
                    Botao {
                        visible: p.removendo === cartao.modelData.nome
                        texto: "Cancelar"
                        onClicado: p.removendo = ""
                    }
                }
                Rectangle {
                    visible: p.logsDe === cartao.modelData.nome
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
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
                            text: p.logsTexto
                            wrapMode: Text.WrapAnywhere
                            font.family: Tema.fonteMono; font.pixelSize: 10; color: Tema.texto2
                        }
                    }
                }
            }
        }
    }
}
