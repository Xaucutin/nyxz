import QtQuick
import QtQuick.Layouts
import Quickshell

// Domínios .test com HTTPS (ideia 3) e túnel público (ideia 4).
// - loja.test → localhost:5173 com certificado válido (mkcert + Caddy da sua conta);
// - túnel: link temporário *.trycloudflare.com para uma porta local (webhooks etc.).
Pagina {
    id: p
    titulo: "Domínios e túnel"
    descricao: "Dê um endereço com HTTPS ao seu projeto (ex.: https://loja.test) ou abra um link público temporário para testar webhooks do Discord, de pagamentos e do GitHub."

    readonly property string cmd: "/usr/libexec/nyxz/nyxz-dev"
    property var dominios: []
    property bool ligado: false
    property bool pronto: true
    property var tuneis: []
    property string erro: ""
    property string aviso: ""
    property bool ocupado: false

    function atualizar() {
        lerDominios.rodar([cmd, "dominios", "listar"]);
        lerTuneis.rodar([cmd, "tunel", "listar"]);
    }
    Component.onCompleted: atualizar()
    Timer { interval: 4000; repeat: true; running: true; onTriggered: p.atualizar() }

    Comando {
        id: lerDominios
        onPronto: s => {
            try { const d = JSON.parse(s); p.dominios = d.dominios; p.ligado = d.ligado; p.pronto = d.pronto; } catch (e) {}
        }
    }
    Comando { id: lerTuneis; onPronto: s => { try { p.tuneis = JSON.parse(s); } catch (e) { p.tuneis = []; } } }
    Comando {
        id: acao
        onPronto: (saida, codigo) => {
            p.ocupado = false;
            if (codigo === 0) { p.erro = ""; if (saida.trim().indexOf("https://") === 0) p.aviso = "Link do túnel: " + saida.trim(); }
            else p.erro = saida.trim() || "A ação não deu certo.";
            p.atualizar();
        }
    }
    function fazer(args) { ocupado = true; acao.rodar(["sh", "-c", '"$0" "$@" 2>&1', cmd].concat(args)); }

    Text {
        Layout.fillWidth: true
        visible: p.erro !== ""
        text: p.erro
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.erro
    }
    Text {
        Layout.fillWidth: true
        visible: p.aviso !== ""
        text: p.aviso
        wrapMode: Text.Wrap
        font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.ok
    }

    // ---------------------------------------------- domínios .test
    RowLayout {
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: "Domínios .test"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
        Text {
            visible: p.dominios.length > 0
            text: p.ligado ? "ligados" : "desligados"
            font.family: Tema.fonteMono; font.pixelSize: 11; color: p.ligado ? Tema.ok : Tema.texto3
        }
        Botao {
            visible: p.dominios.length > 0
            texto: p.ligado ? "Desligar" : "Ligar"
            onClicado: p.fazer(["dominios", p.ligado ? "desligar" : "ligar"])
        }
    }
    Text {
        Layout.fillWidth: true
        visible: !p.pronto
        text: "Esta versão da Nyxz ainda não tem o Caddy e o mkcert. Atualize o sistema para usar domínios .test."
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.aviso
    }
    Repeater {
        model: p.dominios
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Text { text: modelData.url; font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto }
            Text {
                Layout.fillWidth: true
                text: "→ localhost:" + modelData.porta
                font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto3
            }
            Botao { texto: "Abrir"; ativo: p.ligado; onClicado: Quickshell.execDetached(["xdg-open", modelData.url]) }
            Botao { texto: "Remover"; onClicado: p.fazer(["dominios", "remover", modelData.nome]) }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: dNome; Layout.preferredWidth: 220; rotulo: "Nome (vira nome.test)"; validador: /^[a-z0-9][a-z0-9-]{0,40}$/ }
        Campo { id: dPorta; Layout.preferredWidth: 120; rotulo: "Porta do projeto"; text: "5173"; validador: /^[0-9]{2,5}$/ }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: p.ocupado ? "Aguarde…" : "Adicionar"
            principal: true
            ativo: p.pronto && !p.ocupado && dNome.aceito && dNome.text.length > 0 && dPorta.aceito
            onClicado: { p.fazer(["dominios", "adicionar", dNome.text, dPorta.text]); dNome.text = ""; }
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Pede a senha de administrador para registrar o nome. Na primeira vez, cria uma autoridade de certificados só deste computador e deixa o Brave, o Firefox e o sistema confiarem nela."
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
    }

    // ---------------------------------------------- túnel público
    Text { Layout.topMargin: 18; text: "Túnel público"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Repeater {
        model: p.tuneis
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Text { text: "localhost:" + modelData.porta; font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto3 }
            Text {
                Layout.fillWidth: true
                text: modelData.link || "abrindo…"
                elide: Text.ElideMiddle
                font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto
            }
            Botao { texto: "Copiar link"; ativo: !!modelData.link; onClicado: Quickshell.execDetached(["wl-copy", modelData.link]) }
            Botao { texto: "Fechar"; onClicado: p.fazer(["tunel", "fechar", String(modelData.porta)]) }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: tPorta; Layout.preferredWidth: 140; rotulo: "Porta local"; text: "3000"; validador: /^[0-9]{2,5}$/ }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: p.ocupado ? "Abrindo…" : "Abrir túnel"
            principal: true
            ativo: !p.ocupado && tPorta.aceito
            onClicado: p.fazer(["tunel", "abrir", tPorta.text])
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Qualquer pessoa com o link acessa essa porta enquanto o túnel estiver aberto. Feche quando terminar. Usa o Cloudflare Tunnel sem conta (baixado na primeira vez)."
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.aviso
    }
}
