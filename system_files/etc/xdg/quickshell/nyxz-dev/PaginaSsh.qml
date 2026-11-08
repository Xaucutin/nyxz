import QtQuick
import QtQuick.Layouts
import Quickshell

// SSH: hosts do ~/.ssh/config, chaves, túneis e o servidor SSH deste computador.
// Tudo continua sendo o SSH normal: o que é feito aqui também funciona no terminal.
Pagina {
    id: p
    titulo: "SSH"
    descricao: "Seus servidores, chaves e túneis. Conectar abre o terminal já no servidor; Arquivos abre as pastas do servidor no gerenciador de arquivos."

    readonly property string cmd: "/usr/libexec/nyxz/nyxz-dev"
    property var hosts: []
    property var chaves: []
    property var tuneis: []
    property bool servidor: false
    property string erro: ""
    property string tunelDe: ""
    property string removendo: ""

    function atualizar() {
        lerHosts.rodar([cmd, "ssh", "hosts"]);
        lerChaves.rodar([cmd, "ssh", "chaves"]);
        lerTuneis.rodar([cmd, "ssh", "tuneis"]);
        lerServidor.rodar([cmd, "ssh", "servidor", "estado"]);
    }
    Component.onCompleted: atualizar()

    Comando { id: lerHosts; onPronto: s => { try { p.hosts = JSON.parse(s); } catch (e) { p.hosts = []; } } }
    Comando { id: lerChaves; onPronto: s => { try { p.chaves = JSON.parse(s); } catch (e) { p.chaves = []; } } }
    Comando { id: lerTuneis; onPronto: s => { try { p.tuneis = JSON.parse(s); } catch (e) { p.tuneis = []; } } }
    Comando { id: lerServidor; onPronto: s => { try { p.servidor = JSON.parse(s).ativo; } catch (e) {} } }
    Comando {
        id: acao
        onPronto: (saida, codigo) => {
            p.erro = codigo === 0 ? "" : (saida.trim() || "A ação não deu certo.");
            p.atualizar();
        }
    }
    // O Comando junta só a saída padrão; para ver o erro, a ação manda o stderr junto.
    function fazer(args) { acao.rodar(["sh", "-c", '"$0" "$@" 2>&1', cmd].concat(args)); }

    Text {
        Layout.fillWidth: true
        visible: p.erro !== ""
        text: p.erro
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.erro
    }

    // ---------------------------------------------- servidor deste computador
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: "Servidor SSH deste computador"; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text {
                Layout.fillWidth: true
                text: p.servidor ? "Ligado: outros computadores podem entrar neste pela rede (com senha ou chave)."
                                 : "Desligado: ninguém entra neste computador por SSH."
                wrapMode: Text.Wrap
                font.family: Tema.fonte; font.pixelSize: 11; color: p.servidor ? Tema.aviso : Tema.texto3
            }
        }
        Botao {
            texto: p.servidor ? "Desligar" : "Ligar"
            onClicado: p.fazer(["ssh", "servidor", p.servidor ? "desligar" : "ligar"])
        }
    }

    // ---------------------------------------------- hosts
    Text { Layout.topMargin: 16; text: "Servidores"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Text {
        visible: p.hosts.length === 0
        text: "Nenhum servidor ainda. Adicione um logo abaixo."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
    }
    Repeater {
        model: p.hosts
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
                    Text { text: cartao.modelData.nome; font.family: Tema.fonteMono; font.pixelSize: 14; color: Tema.texto }
                    Text {
                        Layout.fillWidth: true
                        text: (cartao.modelData.usuario ? cartao.modelData.usuario + "@" : "") + cartao.modelData.endereco +
                              (cartao.modelData.porta !== "22" ? ":" + cartao.modelData.porta : "")
                        elide: Text.ElideRight
                        font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto3
                    }
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Botao {
                        texto: "Conectar"
                        principal: true
                        onClicado: Quickshell.execDetached(["nyx", "run", "/usr/libexec/nyxz/terminal", "-e", "ssh", cartao.modelData.nome])
                    }
                    Botao {
                        texto: "Arquivos"
                        onClicado: Quickshell.execDetached(["xdg-open", "sftp://" + cartao.modelData.nome + "/"])
                    }
                    Botao {
                        texto: p.tunelDe === cartao.modelData.nome ? "Fechar túnel…" : "Túnel…"
                        onClicado: p.tunelDe = p.tunelDe === cartao.modelData.nome ? "" : cartao.modelData.nome
                    }
                    Botao {
                        visible: p.removendo !== cartao.modelData.nome
                        texto: "Remover"
                        onClicado: p.removendo = cartao.modelData.nome
                    }
                    Botao {
                        visible: p.removendo === cartao.modelData.nome
                        texto: "Confirmar remoção"
                        perigo: true
                        onClicado: { p.fazer(["ssh", "remover", cartao.modelData.nome]); p.removendo = ""; }
                    }
                }
                // Túnel: uma porta do servidor aparece como porta local (ex.: banco remoto)
                RowLayout {
                    visible: p.tunelDe === cartao.modelData.nome
                    Layout.fillWidth: true
                    spacing: 8
                    Campo { id: remota; Layout.preferredWidth: 140; rotulo: "Porta no servidor"; validador: /^[0-9]{1,5}$/; text: "5432" }
                    Campo { id: local; Layout.preferredWidth: 140; rotulo: "Porta aqui"; validador: /^[0-9]{1,5}$/; text: "15432" }
                    Botao {
                        Layout.alignment: Qt.AlignBottom
                        texto: "Abrir túnel"
                        ativo: remota.aceito && local.aceito
                        onClicado: { p.fazer(["ssh", "tunel", cartao.modelData.nome, local.text, remota.text]); p.tunelDe = ""; }
                    }
                }
            }
        }
    }

    // Adicionar servidor
    Text { Layout.topMargin: 6; text: "Adicionar servidor"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 8
        rowSpacing: 8
        Campo { id: hNome; Layout.fillWidth: true; rotulo: "Nome (ex.: vps)"; validador: /^[A-Za-z0-9._-]{1,64}$/ }
        Campo { id: hEndereco; Layout.fillWidth: true; rotulo: "Endereço (IP ou domínio)" }
        Campo { id: hUsuario; Layout.fillWidth: true; rotulo: "Usuário"; text: "root" }
        Campo { id: hPorta; Layout.preferredWidth: 90; rotulo: "Porta"; text: "22"; validador: /^[0-9]{1,5}$/ }
    }
    Botao {
        texto: "Adicionar"
        principal: true
        ativo: hNome.aceito && hNome.text.length > 0 && hEndereco.text.length > 0 && hPorta.aceito
        onClicado: {
            p.fazer(["ssh", "adicionar", hNome.text, hEndereco.text, hUsuario.text, hPorta.text]);
            hNome.text = ""; hEndereco.text = "";
        }
    }

    // ---------------------------------------------- túneis
    Text {
        Layout.topMargin: 16
        visible: p.tuneis.length > 0
        text: "Túneis abertos"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Repeater {
        model: p.tuneis
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "localhost:" + modelData.local + "  →  " + modelData.host + ":" + modelData.remota
                font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.suave
            }
            Botao { texto: "Fechar"; onClicado: p.fazer(["ssh", "fechar", String(modelData.pid)]) }
        }
    }

    // ---------------------------------------------- chaves
    Text { Layout.topMargin: 16; text: "Chaves"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Text {
        Layout.fillWidth: true
        visible: p.chaves.length === 0
        text: "Nenhuma chave ainda. Gere uma e cole a parte pública no servidor (ou no GitHub)."
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
    }
    Repeater {
        model: p.chaves
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Text { text: modelData.nome; font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto }
            Text {
                Layout.fillWidth: true
                text: modelData.tipo + "  " + modelData.impressao
                elide: Text.ElideMiddle
                font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3
            }
            Botao { texto: "Copiar chave pública"; onClicado: Quickshell.execDetached(["wl-copy", modelData.publica]) }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: kNome; Layout.preferredWidth: 200; rotulo: "Nome da chave"; text: "id_ed25519"; validador: /^[A-Za-z0-9._-]{1,64}$/ }
        Campo { id: kComentario; Layout.fillWidth: true; rotulo: "Comentário (aparece no servidor)"; text: Quickshell.env("USER") + "@nyxz" }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: "Gerar chave"
            ativo: kNome.aceito && !p.chaves.some(c => c.nome === kNome.text)
            onClicado: p.fazer(["ssh", "gerar", kNome.text, kComentario.text])
        }
    }
}
