import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Celular integrado (ideia 21) pelo KDE Connect. Desligado, nada roda.
// Por baixo: /usr/libexec/nyxz/celular + serviço do usuário nyxz-celular.
Pagina {
    id: p
    titulo: "Celular"
    descricao: "Com o app KDE Connect no Android e os dois na mesma rede: notificações do celular aparecem aqui, o copiar e colar vale nos dois, dá para mandar arquivos para lá e para cá, controlar a música e fazer o celular tocar para achá-lo."

    readonly property string cmd: "/usr/libexec/nyxz/celular"
    property var e: null
    property string aviso: ""
    property bool avisoErro: false

    function atualizar() { cmdEstado.rodar([cmd, "estado"]); }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    Component.onCompleted: atualizar()
    Timer { interval: 4000; running: p.e !== null && p.e.ligado; repeat: true; onTriggered: p.atualizar() }
    Timer { id: limpa; interval: 7000; onTriggered: p.aviso = "" }

    Comando { id: cmdEstado; onPronto: s => { try { p.e = JSON.parse(s); } catch (x) {} } }
    Process {
        id: acao
        stdinEnabled: true
        property string ok: ""
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => { p.avisar(codigo === 0 ? acao.ok : (erroAcao.text.trim() || "Não deu certo."), codigo !== 0); p.atualizar(); }
        function rodar(c, msg, entrada) {
            if (running) return;
            ok = msg; command = c; running = true;
            if (entrada !== undefined) write(entrada);
            closeStdin();
        }
    }

    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }

    // ------------------------------------------------ ligar
    RowLayout {
        visible: p.e !== null
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: "Celular integrado"; font.family: Tema.fonte; font.pixelSize: 14; color: Tema.texto }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: p.e && !p.e.instalado ? "Instale primeiro em Apps e componentes → \"Celular integrado (KDE Connect)\"."
                      : p.e && p.e.ligado ? "Ligado (~30–50 MB enquanto ligado)." : "Desligado: não gasta nada."
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
            }
        }
        Botao {
            visible: p.e && !p.e.instalado
            texto: "Abrir Apps e componentes"
            onClicado: Quickshell.execDetached(["/usr/libexec/nyxz/configuracoes", "componentes"])
        }
        Interruptor {
            visible: p.e && p.e.instalado
            ligado: p.e ? p.e.ligado : false
            onAlternado: v => acao.rodar([p.cmd, v ? "ligar" : "desligar"], v ? "Ligado. Abra o KDE Connect no celular." : "Desligado.")
        }
    }

    // ------------------------------------------------ aparelhos
    Text {
        visible: p.e && p.e.ligado && p.e.aparelhos.length === 0
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Nenhum celular encontrado ainda. Instale o KDE Connect no Android (Play Store ou F-Droid), abra o app com o celular na mesma rede Wi-Fi e ele aparece aqui."
        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto2
    }
    Repeater {
        model: p.e && p.e.ligado ? p.e.aparelhos : []
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
            ColumnLayout {
                id: col
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 14
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: cartao.a.nome; font.family: Tema.fonte; font.pixelSize: 14; font.weight: Font.Medium; color: Tema.texto }
                        Text {
                            text: !cartao.a.pareado ? (cartao.a.pedindo ? "Confirme no celular" : "Não pareado")
                                  : !cartao.a.alcancavel ? "Pareado, fora de alcance"
                                  : "Conectado" + (cartao.a.bateria !== null ? "  ·  bateria " + cartao.a.bateria + "%" : "")
                            font.family: Tema.fonte; font.pixelSize: 12; color: cartao.a.pareado && cartao.a.alcancavel ? Tema.ok : Tema.texto3
                        }
                    }
                    Botao {
                        visible: !cartao.a.pareado
                        texto: "Parear"
                        principal: true
                        onClicado: acao.rodar([p.cmd, "parear", cartao.a.id], "Pedido enviado: aceite no celular.")
                    }
                    Botao {
                        visible: cartao.a.pareado
                        texto: "Esquecer"
                        perigo: true
                        onClicado: acao.rodar([p.cmd, "desparear", cartao.a.id], "Celular esquecido.")
                    }
                }
                Flow {
                    visible: cartao.a.pareado && cartao.a.alcancavel
                    Layout.fillWidth: true
                    spacing: 8
                    Botao { texto: "Fazer tocar"; onClicado: acao.rodar([p.cmd, "tocar", cartao.a.id], "Tocando no celular.") }
                    Botao { texto: "Mandar o que está copiado"; onClicado: { colar.alvo = cartao.a.id; colar.running = true; } }
                }
                RowLayout {
                    visible: cartao.a.pareado && cartao.a.alcancavel
                    Layout.fillWidth: true
                    spacing: 8
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: arquivo.implicitHeight
                        Campo { id: arquivo; width: parent.width; rotulo: "Arquivo ou link para mandar (ou arraste aqui)" }
                        DropArea {
                            anchors.fill: parent
                            onDropped: d => { if (d.hasUrls) arquivo.text = decodeURIComponent(d.urls[0].toString().replace("file://", "")); }
                        }
                    }
                    Botao {
                        Layout.alignment: Qt.AlignBottom
                        texto: "Mandar"
                        ativo: arquivo.text.trim() !== ""
                        onClicado: { acao.rodar([p.cmd, "enviar", cartao.a.id, arquivo.text.trim()], "Enviado para o celular."); arquivo.text = ""; }
                    }
                }
            }
        }
    }
    // Área de transferência atual → celular
    Process {
        id: colar
        property string alvo: ""
        command: ["wl-paste", "--no-newline", "--type", "text"]
        stdout: StdioCollector { onStreamFinished: if (this.text) acao.rodar([p.cmd, "texto", colar.alvo], "Texto enviado.", this.text) }
    }

    Text {
        visible: p.e && p.e.ligado
        Layout.topMargin: 8
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Arquivos que o celular manda vão para Downloads. A música do PC aparece no celular para controlar, e as notificações do celular aparecem aqui (dá para silenciá-las por espaço em Espaços)."
        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
    }
}
