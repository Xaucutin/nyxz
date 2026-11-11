import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Várias instâncias do mesmo app: perfis separados (dados e login próprios) ou um perfil
// temporário que some ao fechar. Por baixo: /usr/libexec/nyxz/instancias.
Pagina {
    id: p
    titulo: "Várias instâncias"
    descricao: "Abra o mesmo app mais de uma vez, cada cópia com os próprios dados e login: Brave \"Trabalho\" e \"Pessoal\", dois Vesktop com contas diferentes. Ou abra uma cópia temporária, limpa, que é apagada ao fechar."

    readonly property string cmd: "/usr/libexec/nyxz/instancias"
    property var apps: []
    property string aviso: ""
    property bool avisoErro: false
    property string removendo: ""

    function atualizar() { cmdListar.rodar([cmd, "listar"]); }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    Component.onCompleted: atualizar()
    Timer { id: limpa; interval: 7000; onTriggered: p.aviso = "" }

    Comando { id: cmdListar; onPronto: s => { try { p.apps = JSON.parse(s); } catch (x) {} } }
    Process {
        id: acao
        property string ok: ""
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => { p.avisar(codigo === 0 ? acao.ok : (erroAcao.text.trim() || "Não deu certo."), codigo !== 0); p.atualizar(); }
        function rodar(c, msg) { if (running) return; ok = msg; command = c; running = true; }
    }

    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }
    Text {
        visible: p.apps.length === 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Nenhum app compatível instalado ainda (Brave, Chrome, Firefox, Vesktop, Discord, VS Code, Telegram, Obsidian, Slack)."
        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto3
    }

    Repeater {
        model: p.apps
        delegate: Rectangle {
            id: cartao
            required property var modelData
            readonly property var a: modelData
            Layout.fillWidth: true
            Layout.preferredHeight: col.implicitHeight + 28
            radius: Tema.raio
            color: Tema.elevado
            border.width: 1
            border.color: Tema.borda
            opacity: a.suportado ? 1 : 0.6
            ColumnLayout {
                id: col
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 14
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: cartao.a.nome + (cartao.a.forma === "flatpak" ? "  ·  Flatpak" : "") + (cartao.a.experimental ? "  ·  experimental" : "")
                        font.family: Tema.fonte; font.pixelSize: 14; font.weight: Font.Medium; color: Tema.texto
                    }
                    Botao {
                        visible: cartao.a.suportado
                        texto: "Abrir temporário"
                        onClicado: acao.rodar([p.cmd, "abrir", cartao.a.app, "--temporario"], cartao.a.nome + " temporário aberto: os dados somem ao fechar.")
                    }
                }
                Text {
                    visible: !cartao.a.suportado
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: "Não funciona: " + cartao.a.motivo + "."
                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
                }
                Repeater {
                    model: cartao.a.perfis
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8
                        Text { Layout.fillWidth: true; text: modelData.nome; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto2 }
                        Botao { texto: "Abrir"; principal: true; onClicado: acao.rodar([p.cmd, "abrir", cartao.a.app, modelData.nome], cartao.a.nome + " \"" + modelData.nome + "\" aberto.") }
                        Botao {
                            readonly property string chave: cartao.a.app + "/" + modelData.pasta
                            texto: p.removendo === chave ? "Confirmar (apaga os dados)" : "Remover"
                            perigo: true
                            onClicado: {
                                if (p.removendo !== chave) { p.removendo = chave; return; }
                                p.removendo = "";
                                acao.rodar([p.cmd, "remover", cartao.a.app, modelData.pasta], "Perfil removido.");
                            }
                        }
                    }
                }
                RowLayout {
                    visible: cartao.a.suportado
                    Layout.fillWidth: true
                    spacing: 8
                    Campo { id: novo; Layout.fillWidth: true; rotulo: "Novo perfil (ex.: Trabalho)"; onConfirmado: criar.clicado() }
                    Botao {
                        id: criar
                        Layout.alignment: Qt.AlignBottom
                        texto: "Criar"
                        ativo: novo.text.trim() !== ""
                        onClicado: { acao.rodar([p.cmd, "criar", cartao.a.app, novo.text.trim()], "Perfil criado. Clique em \"Abrir\"."); novo.text = ""; }
                    }
                }
            }
        }
    }
    Text {
        Layout.topMargin: 8
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "A janela normal do app continua sendo a de sempre. Cada perfil tem os próprios dados: entre nas contas uma vez em cada um. Dois apps com o mesmo perfil ao mesmo tempo não é possível, para não corromper os dados."
        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
    }
}
