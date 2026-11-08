import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Editor de embeds do Discord com prévia ao vivo, nos dois sentidos:
// mexer nos campos reescreve o JSON; editar o JSON (válido) atualiza campos e prévia.
// Sai como JSON, código discord.js ou discord.py, ou vai para um canal por webhook.
Pagina {
    id: p
    titulo: "Embeds"
    descricao: "Monte o embed nos campos ou cole o JSON: a prévia mostra como fica no Discord. Depois copie o código para o seu bot ou envie um teste por webhook."

    readonly property string cmd: "/usr/libexec/nyxz/nyxz-dev"
    property var embed: ({
        title: "Olá da Nyxz",
        description: "Embeds com **negrito**, *itálico* e `código`.\nEdite à esquerda ou no JSON abaixo.",
        color: 0x5865F2,
        url: "",
        author: { name: "" },
        footer: { text: "Feito no Dev Hub" },
        thumbnail: { url: "" },
        image: { url: "" },
        fields: [
            { name: "Campo", value: "Valor", inline: true },
            { name: "Outro campo", value: "Outro valor", inline: true }
        ]
    })
    property string erroJson: ""
    property string aviso: ""

    // ---------------------------------------------- modelo → JSON e código
    function limpo() {
        // Só o que tem conteúdo (o Discord recusa objetos vazios)
        const e = {};
        const t = embed;
        if (t.title) e.title = t.title;
        if (t.description) e.description = t.description;
        if (t.url) e.url = t.url;
        if (t.color !== undefined && t.color !== null) e.color = t.color;
        if (t.author && t.author.name) e.author = { name: t.author.name };
        if (t.footer && t.footer.text) e.footer = { text: t.footer.text };
        if (t.thumbnail && t.thumbnail.url) e.thumbnail = { url: t.thumbnail.url };
        if (t.image && t.image.url) e.image = { url: t.image.url };
        const f = (t.fields || []).filter(x => x.name || x.value);
        if (f.length) e.fields = f.map(x => ({ name: x.name || "​", value: x.value || "​", inline: !!x.inline }));
        return e;
    }
    function json() { return JSON.stringify(limpo(), null, 2); }
    function hex(c) { return "0x" + ("000000" + (c >>> 0).toString(16)).slice(-6); }
    function codigoJs() {
        const e = limpo(), s = JSON.stringify;
        let t = "const embed = new EmbedBuilder()";
        if (e.title) t += "\n  .setTitle(" + s(e.title) + ")";
        if (e.description) t += "\n  .setDescription(" + s(e.description) + ")";
        if (e.color !== undefined) t += "\n  .setColor(" + hex(e.color) + ")";
        if (e.url) t += "\n  .setURL(" + s(e.url) + ")";
        if (e.author) t += "\n  .setAuthor({ name: " + s(e.author.name) + " })";
        if (e.thumbnail) t += "\n  .setThumbnail(" + s(e.thumbnail.url) + ")";
        if (e.image) t += "\n  .setImage(" + s(e.image.url) + ")";
        if (e.fields) t += "\n  .addFields(\n" + e.fields.map(f => "    { name: " + s(f.name) + ", value: " + s(f.value) + ", inline: " + f.inline + " },").join("\n") + "\n  )";
        if (e.footer) t += "\n  .setFooter({ text: " + s(e.footer.text) + " })";
        return t + ";\n";
    }
    function codigoPy() {
        const e = limpo(), s = JSON.stringify;
        const args = [];
        if (e.title) args.push("title=" + s(e.title));
        if (e.description) args.push("description=" + s(e.description));
        if (e.color !== undefined) args.push("color=" + hex(e.color));
        if (e.url) args.push("url=" + s(e.url));
        let t = "embed = discord.Embed(" + args.join(", ") + ")";
        if (e.author) t += "\nembed.set_author(name=" + s(e.author.name) + ")";
        if (e.thumbnail) t += "\nembed.set_thumbnail(url=" + s(e.thumbnail.url) + ")";
        if (e.image) t += "\nembed.set_image(url=" + s(e.image.url) + ")";
        (e.fields || []).forEach(f => t += "\nembed.add_field(name=" + s(f.name) + ", value=" + s(f.value) + ", inline=" + (f.inline ? "True" : "False") + ")");
        if (e.footer) t += "\nembed.set_footer(text=" + s(e.footer.text) + ")";
        return t + "\n";
    }

    // ---------------------------------------------- edição
    function mudar(caminho, valor) {
        const e = JSON.parse(JSON.stringify(embed));
        const partes = caminho.split(".");
        let o = e;
        for (let i = 0; i < partes.length - 1; i++) { o[partes[i]] = o[partes[i]] || {}; o = o[partes[i]]; }
        o[partes[partes.length - 1]] = valor;
        embed = e;
        if (!campoJson.activeFocus) campoJson.text = json();
    }
    function mudarCampo(i, chave, valor) {
        const f = (embed.fields || []).slice();
        f[i] = Object.assign({}, f[i]);
        f[i][chave] = valor;
        mudar("fields", f);
    }
    function corDeTexto(t) {
        const m = /^#?([0-9a-fA-F]{6})$/.exec(t.trim());
        return m ? parseInt(m[1], 16) : null;
    }
    function copiar(texto, msg) {
        Quickshell.execDetached(["wl-copy", texto]);
        aviso = msg;
        limpaAviso.restart();
    }
    Timer { id: limpaAviso; interval: 2500; onTriggered: p.aviso = "" }

    Process {
        id: enviar
        stdinEnabled: true
        stdout: StdioCollector { onStreamFinished: if (this.text.trim()) { p.aviso = this.text.trim(); limpaAviso.restart(); } }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim()) { p.aviso = this.text.trim(); limpaAviso.restart(); } }
    }

    Component.onCompleted: campoJson.text = json()

    // ---------------------------------------------- editor + prévia
    RowLayout {
        Layout.fillWidth: true
        spacing: 20

        // Campos
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: 8
            Campo { Layout.fillWidth: true; rotulo: "Título"; text: p.embed.title || ""; onTextChanged: if (text !== (p.embed.title || "")) p.mudar("title", text) }
            AreaTexto { Layout.fillWidth: true; rotulo: "Descrição (aceita **negrito**, *itálico*, `código`)"; texto: p.embed.description || ""; onEditado: t => p.mudar("description", t) }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Campo {
                    id: campoCor
                    Layout.preferredWidth: 120
                    rotulo: "Cor"
                    validador: /^#?[0-9a-fA-F]{6}$/
                    text: "#" + ("000000" + ((p.embed.color || 0) >>> 0).toString(16)).slice(-6).toUpperCase()
                    onTextChanged: { const c = p.corDeTexto(text); if (c !== null && c !== p.embed.color) p.mudar("color", c); }
                }
                Campo { Layout.fillWidth: true; rotulo: "Link do título"; text: p.embed.url || ""; onTextChanged: if (text !== (p.embed.url || "")) p.mudar("url", text) }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Campo { Layout.fillWidth: true; rotulo: "Autor"; text: (p.embed.author || {}).name || ""; onTextChanged: if (text !== ((p.embed.author || {}).name || "")) p.mudar("author.name", text) }
                Campo { Layout.fillWidth: true; rotulo: "Rodapé"; text: (p.embed.footer || {}).text || ""; onTextChanged: if (text !== ((p.embed.footer || {}).text || "")) p.mudar("footer.text", text) }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Campo { Layout.fillWidth: true; rotulo: "Miniatura (URL)"; text: (p.embed.thumbnail || {}).url || ""; onTextChanged: if (text !== ((p.embed.thumbnail || {}).url || "")) p.mudar("thumbnail.url", text) }
                Campo { Layout.fillWidth: true; rotulo: "Imagem (URL)"; text: (p.embed.image || {}).url || ""; onTextChanged: if (text !== ((p.embed.image || {}).url || "")) p.mudar("image.url", text) }
            }
            Text { Layout.topMargin: 4; text: "Campos"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
            Repeater {
                model: (p.embed.fields || []).length
                delegate: RowLayout {
                    required property int index
                    readonly property var f: (p.embed.fields || [])[index] || {}
                    Layout.fillWidth: true
                    spacing: 6
                    Campo { Layout.fillWidth: true; rotulo: "Nome"; text: parent.f.name || ""; onTextChanged: if (text !== (parent.f.name || "")) p.mudarCampo(parent.index, "name", text) }
                    Campo { Layout.fillWidth: true; rotulo: "Valor"; text: parent.f.value || ""; onTextChanged: if (text !== (parent.f.value || "")) p.mudarCampo(parent.index, "value", text) }
                    Botao {
                        Layout.alignment: Qt.AlignBottom
                        texto: parent.f.inline ? "Lado a lado" : "Em linha"
                        principal: !!parent.f.inline
                        onClicado: p.mudarCampo(parent.index, "inline", !parent.f.inline)
                    }
                    Botao {
                        Layout.alignment: Qt.AlignBottom
                        texto: "×"
                        onClicado: { const f = p.embed.fields.slice(); f.splice(parent.index, 1); p.mudar("fields", f); }
                    }
                }
            }
            Botao {
                texto: "Adicionar campo"
                ativo: (p.embed.fields || []).length < 25
                onClicado: p.mudar("fields", (p.embed.fields || []).concat([{ name: "Campo", value: "Valor", inline: true }]))
            }
        }

        // Prévia no visual do Discord
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: previa.implicitHeight + 32
            radius: 8
            color: "#313338"   // fundo de mensagem do Discord (tema escuro)
            Rectangle {
                id: previa
                x: 16; y: 16
                width: Math.min(parent.width - 32, 520)
                implicitHeight: conteudo.implicitHeight + 24
                radius: 4
                color: "#2B2D31"
                clip: true
                Rectangle {
                    width: 4; height: parent.height
                    color: p.embed.color !== undefined && p.embed.color !== null ? "#" + ("000000" + (p.embed.color >>> 0).toString(16)).slice(-6) : "#1E1F22"
                }
                Image {
                    id: miniatura
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    width: visible ? 80 : 0
                    height: 80
                    visible: !!(p.embed.thumbnail || {}).url
                    source: (p.embed.thumbnail || {}).url || ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
                ColumnLayout {
                    id: conteudo
                    x: 16; y: 10
                    width: previa.width - 32 - (miniatura.visible ? 96 : 0)
                    spacing: 6
                    Text {
                        visible: !!(p.embed.author || {}).name
                        text: (p.embed.author || {}).name || ""
                        font.family: Tema.fonte; font.pixelSize: 13; font.weight: Font.Medium; color: "#F2F3F5"
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !!p.embed.title
                        text: p.embed.title || ""
                        wrapMode: Text.Wrap
                        font.family: Tema.fonte; font.pixelSize: 15; font.weight: Font.DemiBold
                        color: p.embed.url ? "#00A8FC" : "#F2F3F5"
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !!p.embed.description
                        text: p.embed.description || ""
                        textFormat: Text.MarkdownText
                        wrapMode: Text.Wrap
                        font.family: Tema.fonte; font.pixelSize: 13; color: "#DBDEE1"
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: (p.embed.fields || []).length > 0
                        Repeater {
                            model: p.embed.fields || []
                            delegate: Column {
                                required property var modelData
                                width: modelData.inline ? Math.floor((conteudo.width - 16) / 3) : conteudo.width
                                spacing: 2
                                Text { width: parent.width; text: modelData.name || ""; wrapMode: Text.Wrap; font.family: Tema.fonte; font.pixelSize: 13; font.weight: Font.DemiBold; color: "#F2F3F5" }
                                Text { width: parent.width; text: modelData.value || ""; textFormat: Text.MarkdownText; wrapMode: Text.Wrap; font.family: Tema.fonte; font.pixelSize: 13; color: "#DBDEE1" }
                            }
                        }
                    }
                    Image {
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? Math.min(300, implicitHeight * width / Math.max(1, implicitWidth)) : 0
                        visible: !!(p.embed.image || {}).url
                        source: (p.embed.image || {}).url || ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    Text {
                        visible: !!(p.embed.footer || {}).text
                        text: (p.embed.footer || {}).text || ""
                        font.family: Tema.fonte; font.pixelSize: 11; color: "#B5BAC1"
                    }
                }
            }
        }
    }

    // ---------------------------------------------- JSON (edição nos dois sentidos)
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        Text { Layout.fillWidth: true; text: "JSON do embed"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
        Text {
            visible: p.erroJson !== ""
            text: p.erroJson
            font.family: Tema.fonte; font.pixelSize: 11; color: Tema.erro
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 220
        radius: Tema.raio
        color: Tema.fundo
        border.width: 1
        border.color: p.erroJson ? Tema.erro : campoJson.activeFocus ? Tema.texto4 : Tema.borda
        Flickable {
            anchors.fill: parent
            anchors.margins: 10
            contentHeight: campoJson.implicitHeight
            clip: true
            TextEdit {
                id: campoJson
                width: parent.width
                font.family: Tema.fonteMono
                font.pixelSize: 11
                color: Tema.texto2
                selectByMouse: true
                wrapMode: TextEdit.WrapAnywhere
                onTextChanged: {
                    if (!activeFocus) return;
                    try {
                        const e = JSON.parse(text);
                        const obj = e.embeds ? e.embeds[0] : e;   // aceita {"embeds":[...]} também
                        p.embed = Object.assign({ author: {}, footer: {}, thumbnail: {}, image: {}, fields: [] }, obj);
                        p.erroJson = "";
                    } catch (err) {
                        p.erroJson = "JSON inválido: a prévia volta quando ele estiver certo";
                    }
                }
            }
        }
    }

    // ---------------------------------------------- saídas
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Botao { texto: "Copiar JSON"; onClicado: p.copiar(JSON.stringify({ embeds: [p.limpo()] }, null, 2), "JSON copiado.") }
        Botao { texto: "Copiar para discord.js"; onClicado: p.copiar(p.codigoJs(), "Código discord.js copiado.") }
        Botao { texto: "Copiar para discord.py"; onClicado: p.copiar(p.codigoPy(), "Código discord.py copiado.") }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: webhook; Layout.preferredWidth: 240; rotulo: "Webhook (nome no cofre)"; text: "DISCORD_WEBHOOK" }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: "Enviar teste"
            principal: true
            ativo: webhook.text.length > 0 && !enviar.running
            onClicado: {
                enviar.command = [p.cmd, "discord", "webhook", webhook.text];
                enviar.running = true;
                enviar.write(JSON.stringify({ embeds: [p.limpo()] }));
                enviar.closeStdin();
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            text: p.aviso || "Canal → Editar canal → Integrações → Webhooks → Copiar URL; guarde a URL no Cofre com esse nome."
            wrapMode: Text.Wrap
            font.family: Tema.fonte; font.pixelSize: 11
            color: p.aviso ? Tema.ok : Tema.texto3
        }
    }

    // Texto de várias linhas com rótulo (descrição)
    component AreaTexto: ColumnLayout {
        id: area
        property string rotulo: ""
        property string texto: ""
        signal editado(string t)
        spacing: 4
        Layout.fillWidth: false
        Text { text: area.rotulo; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(70, edicao.implicitHeight + 16)
            radius: Tema.raio
            color: Tema.elevado
            border.width: 1
            border.color: edicao.activeFocus ? Tema.texto4 : Tema.borda
            TextEdit {
                id: edicao
                anchors.fill: parent
                anchors.margins: 8
                text: area.texto
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto
                onTextChanged: if (activeFocus && text !== area.texto) area.editado(text)
            }
        }
    }
}
