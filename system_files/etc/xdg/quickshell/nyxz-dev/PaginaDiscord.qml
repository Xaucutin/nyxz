import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Discord Studio: bots em discord.js ou discord.py, com o token no cofre, logs ao
// vivo e reinício ao salvar. O bot roda como serviço do usuário (nyxz-bot-<nome>):
// continua rodando com o Dev Hub fechado.
Pagina {
    id: p
    titulo: "Bots do Discord"
    descricao: "Crie um bot a partir de um modelo, guarde o token no cofre e rode com logs ao vivo. Salvar um arquivo do bot reinicia ele sozinho."

    readonly property string cmd: "/usr/libexec/nyxz/nyxz-dev"
    property var bots: []
    property string ling: "js"
    property string erro: ""
    property string aberto: ""        // bot com o painel de logs aberto
    property string logs: ""
    property string tokenDe: ""
    property string servidorDe: ""

    function atualizar() { listar.rodar([cmd, "discord", "bots"]); }
    Component.onCompleted: atualizar()

    Comando { id: listar; onPronto: s => { try { p.bots = JSON.parse(s); } catch (e) { p.bots = []; } } }
    Comando {
        id: acao
        onPronto: (saida, codigo) => { p.erro = codigo === 0 ? "" : (saida.trim() || "A ação não deu certo."); p.atualizar(); }
    }
    function fazer(args) { acao.rodar(["sh", "-c", '"$0" "$@" 2>&1', cmd].concat(args)); }
    Comando { id: lerLogs; onPronto: s => p.logs = s.trim() || "(sem logs ainda)" }
    Timer {
        interval: 1200
        repeat: true
        running: p.aberto !== ""
        triggeredOnStart: true
        onTriggered: lerLogs.rodar([p.cmd, "discord", "logs", p.aberto])
    }
    Timer { interval: 4000; repeat: true; running: true; onTriggered: p.atualizar() }

    // Token: vai pela entrada padrão direto para o cofre
    Process {
        id: guardarToken
        stdinEnabled: true
        onRunningChanged: if (!running) p.atualizar()
    }

    Text {
        Layout.fillWidth: true
        visible: p.erro !== ""
        text: p.erro
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.erro
    }

    // ---------------------------------------------- novo bot
    Text { text: "Novo bot"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: nomeBot; Layout.preferredWidth: 240; rotulo: "Nome (ex.: meu-bot)"; validador: /^[a-z0-9][a-z0-9_-]{0,40}$/ }
        Botao { Layout.alignment: Qt.AlignBottom; texto: "discord.js"; principal: p.ling === "js"; onClicado: p.ling = "js" }
        Botao { Layout.alignment: Qt.AlignBottom; texto: "discord.py"; principal: p.ling === "py"; onClicado: p.ling = "py" }
        Item { Layout.fillWidth: true }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: "Criar bot"
            principal: true
            ativo: nomeBot.aceito && nomeBot.text.length > 0
            onClicado: { p.fazer(["discord", "criar", nomeBot.text, p.ling]); nomeBot.text = ""; }
        }
    }
    Text {
        Layout.fillWidth: true
        text: "O projeto fica em ~/Projetos/Discord/<nome>, com os comandos /ping e /exemplo prontos. Precisa do Node.js (discord.js) ou do Python (discord.py), instalados em Configurações → Apps e componentes."
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
    }

    // ---------------------------------------------- bots
    Repeater {
        model: p.bots
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
                    Rectangle { width: 8; height: 8; radius: 4; color: cartao.modelData.rodando ? Tema.ok : Tema.texto4 }
                    Text { text: cartao.modelData.nome; font.family: Tema.fonteMono; font.pixelSize: 14; color: Tema.texto }
                    Text {
                        Layout.fillWidth: true
                        text: (cartao.modelData.linguagem === "js" ? "discord.js" : "discord.py") +
                              (cartao.modelData.rodando ? " · rodando" : " · parado") +
                              (cartao.modelData.temToken ? "" : " · sem token") +
                              (cartao.modelData.servidorTeste ? " · servidor de testes " + cartao.modelData.servidorTeste : "")
                        elide: Text.ElideRight
                        font.family: Tema.fonte; font.pixelSize: 12
                        color: cartao.modelData.temToken ? Tema.texto3 : Tema.aviso
                    }
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Botao {
                        texto: cartao.modelData.rodando ? "Parar" : "Rodar"
                        principal: !cartao.modelData.rodando
                        ativo: cartao.modelData.temToken
                        onClicado: {
                            p.fazer(["discord", cartao.modelData.rodando ? "parar" : "iniciar", cartao.modelData.nome]);
                            if (!cartao.modelData.rodando) p.aberto = cartao.modelData.nome;
                        }
                    }
                    Botao {
                        texto: p.aberto === cartao.modelData.nome ? "Fechar logs" : "Logs"
                        onClicado: p.aberto = p.aberto === cartao.modelData.nome ? "" : cartao.modelData.nome
                    }
                    Botao { texto: "Token"; onClicado: p.tokenDe = p.tokenDe === cartao.modelData.nome ? "" : cartao.modelData.nome }
                    Botao { texto: "Servidor de testes"; onClicado: p.servidorDe = p.servidorDe === cartao.modelData.nome ? "" : cartao.modelData.nome }
                    Botao { texto: "Abrir no VS Code"; onClicado: Quickshell.execDetached(["nyx", "run", "code", cartao.modelData.pasta]) }
                    Botao { texto: "Abrir pasta"; onClicado: Quickshell.execDetached(["xdg-open", cartao.modelData.pasta]) }
                }

                // Token (vai para o cofre; nunca para arquivo do projeto)
                RowLayout {
                    visible: p.tokenDe === cartao.modelData.nome
                    Layout.fillWidth: true
                    spacing: 8
                    Campo { id: token; Layout.fillWidth: true; rotulo: "Token do bot (Discord Developer Portal → Bot → Reset Token)"; oculto: true }
                    Botao {
                        Layout.alignment: Qt.AlignBottom
                        texto: "Guardar no cofre"
                        principal: true
                        ativo: token.text.length > 20
                        onClicado: {
                            guardarToken.command = [p.cmd, "discord", "token", cartao.modelData.nome];
                            guardarToken.running = true;
                            guardarToken.write(token.text);
                            guardarToken.closeStdin();
                            token.text = "";
                            p.tokenDe = "";
                        }
                    }
                }

                // Servidor de testes: comandos de barra aparecem na hora nesse servidor
                RowLayout {
                    visible: p.servidorDe === cartao.modelData.nome
                    Layout.fillWidth: true
                    spacing: 8
                    Campo {
                        id: servidor
                        Layout.fillWidth: true
                        rotulo: "ID do servidor (Discord: modo desenvolvedor → botão direito no servidor → Copiar ID)"
                        validador: /^[0-9]{0,22}$/
                        text: cartao.modelData.servidorTeste || ""
                    }
                    Botao {
                        Layout.alignment: Qt.AlignBottom
                        texto: "Salvar"
                        ativo: servidor.aceito
                        onClicado: { p.fazer(["discord", "servidor-teste", cartao.modelData.nome, servidor.text]); p.servidorDe = ""; }
                    }
                }

                // Logs ao vivo
                Rectangle {
                    visible: p.aberto === cartao.modelData.nome
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
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
