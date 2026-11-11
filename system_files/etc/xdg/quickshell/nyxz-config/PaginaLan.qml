import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Redes de jogo (LAN virtual estilo Radmin, sobre o ZeroTier com controlador próprio).
// Por baixo: /usr/libexec/nyxz/lan. O serviço só roda com alguma rede ligada.
Pagina {
    id: p
    titulo: "Redes de jogo"
    descricao: "Uma rede local de mentira pela internet: os jogos acham uns aos outros como se estivessem na mesma casa (Minecraft \"Abrir para LAN\", jogos com LAN). Seus amigos no Windows, Mac ou celular instalam o ZeroTier (grátis) e entram com o código."

    readonly property string cmd: "/usr/libexec/nyxz/lan"
    property bool carregado: false
    property bool instalado: true
    property bool ligado: false
    property string endereco: ""
    property var redes: []
    property string aviso: ""
    property bool avisoErro: false
    property string removendo: ""
    property string nomeando: ""

    function atualizar() { cmdEstado.rodar([cmd, "estado"]); }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    // Voz pela LAN: sala aberta aqui e salas achadas nas redes ligadas
    property bool vozInstalada: false
    property bool vozAberta: false
    property string vozIp: ""
    property var salas: []
    property var _achadas: []

    Component.onCompleted: { atualizar(); cmdVoz.rodar(["/usr/libexec/nyxz/voz", "estado"]); }
    Timer {
        interval: 4000; running: true; repeat: true
        onTriggered: { p.atualizar(); cmdVoz.rodar(["/usr/libexec/nyxz/voz", "estado"]); }
    }
    Comando {
        id: cmdVoz
        onPronto: s => {
            try { const d = JSON.parse(s); p.vozInstalada = d.instalado; p.vozAberta = d.aberta; p.vozIp = d.ip; } catch (e) {}
        }
    }
    // Procura salas a cada 8 s em todas as redes ligadas (um ping UDP por endereço, ~1 s)
    Process {
        id: procura
        stdout: SplitParser {
            onRead: linha => { try { p._achadas = p._achadas.concat(JSON.parse(linha)); } catch (e) {} }
        }
        onExited: { p.salas = p._achadas; p._achadas = []; }
    }
    Timer {
        interval: 8000; running: p.vozInstalada; repeat: true; triggeredOnStart: true
        onTriggered: {
            const ips = p.redes.filter(r => r.ligada && r.status === "OK" && r.ip).map(r => r.ip.split(",")[0].trim());
            if (!ips.length || procura.running) { if (!ips.length) p.salas = []; return; }
            procura.command = ["sh", "-c", 'for ip; do /usr/libexec/nyxz/voz procurar "$ip"; done', "sh"].concat(ips);
            procura.running = true;
        }
    }
    // Nyxz Share: servidor ligado aqui e transmissões achadas nas redes ligadas
    property bool shareLigado: false
    property string shareIp: ""
    property bool shareTransmitindo: false
    property var transmissoes: []
    property var _transmissoes: []
    Comando {
        id: cmdShare
        onPronto: s => {
            try { const d = JSON.parse(s); p.shareLigado = d.ligado; p.shareIp = d.ip; p.shareTransmitindo = d.transmitindo; } catch (e) {}
        }
    }
    Process {
        id: procuraShare
        stdout: SplitParser {
            onRead: linha => { try { p._transmissoes = p._transmissoes.concat(JSON.parse(linha)); } catch (e) {} }
        }
        onExited: { p.transmissoes = p._transmissoes; p._transmissoes = []; }
    }
    Timer {
        interval: 8000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            cmdShare.rodar(["/usr/libexec/nyxz/share", "estado"]);
            const ips = p.redes.filter(r => r.ligada && r.status === "OK" && r.ip).map(r => r.ip.split(",")[0].trim());
            if (!ips.length || procuraShare.running) { if (!ips.length) p.transmissoes = []; return; }
            procuraShare.command = ["sh", "-c", 'for ip; do /usr/libexec/nyxz/share procurar "$ip"; done', "sh"].concat(ips);
            procuraShare.running = true;
        }
    }
    Timer { id: limpa; interval: 7000; onTriggered: p.aviso = "" }

    Comando {
        id: cmdEstado
        onPronto: s => {
            try {
                const d = JSON.parse(s);
                p.instalado = d.instalado; p.ligado = d.ligado; p.endereco = d.endereco; p.redes = d.redes;
            } catch (e) {}
            p.carregado = true;
        }
    }
    Process {
        id: acao
        property string ok: ""
        stdout: StdioCollector { id: saidaAcao }
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => {
            if (codigo === 0) { if (acao.ok) p.avisar(acao.ok.replace("%s", saidaAcao.text.trim()), false); }
            else p.avisar(erroAcao.text.trim() || "Não deu certo.", true);
            p.atualizar();
        }
        function rodar(comando, mensagem) {
            if (running) return;
            ok = mensagem || "";
            command = comando;
            running = true;
        }
    }

    function situacao(r) {
        if (!r.ligada) return "Desligada";
        const s = { OK: "Conectada", REQUESTING_CONFIGURATION: "Conectando…",
                    ACCESS_DENIED: "Esperando o dono da rede aprovar você",
                    NOT_FOUND: "Rede não encontrada (o PC de quem criou está desligado?)",
                    PORT_ERROR: "Erro na interface da rede", CLIENT_TOO_OLD: "ZeroTier desatualizado" }[r.status];
        return (s || r.status || "Conectando…") + (r.ip ? " · seu IP " + ModoStreamer.ip(r.ip) : "");
    }

    // ---------------------------------------------- não instalada
    ColumnLayout {
        visible: p.carregado && !p.instalado
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "A LAN virtual não está instalada. Ela ocupa uns 10 MB e só roda com uma rede ligada."
            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto2
        }
        Botao {
            texto: "Instalar em Apps e componentes"
            principal: true
            onClicado: Quickshell.execDetached(["/usr/libexec/nyxz/configuracoes", "componentes"])
        }
    }

    ColumnLayout {
        visible: p.instalado
        Layout.fillWidth: true
        spacing: 10

        Text {
            visible: p.aviso !== ""
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: p.aviso
            font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
        }

        // ------------------------------------------ criar e entrar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Campo { id: nomeRede; Layout.fillWidth: true; rotulo: "Criar uma rede (nome, ex.: Amigos do Minecraft)" }
            Botao {
                Layout.alignment: Qt.AlignBottom
                texto: acao.running ? "Aguarde…" : "Criar"
                principal: true
                ativo: nomeRede.text.trim() !== "" && !acao.running
                onClicado: { acao.rodar([p.cmd, "criar", nomeRede.text.trim()], "Rede criada. Passe o código %s para os amigos."); nomeRede.text = ""; }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Campo { id: codigo; Layout.fillWidth: true; rotulo: "Entrar na rede de um amigo (código de 16 letras)"; validador: /^\s*[0-9a-fA-F]{16}\s*$/ }
            Botao {
                Layout.alignment: Qt.AlignBottom
                texto: "Entrar"
                ativo: codigo.text.trim() !== "" && codigo.aceito && !acao.running
                onClicado: { acao.rodar([p.cmd, "entrar", codigo.text.trim()], "Pedido enviado. Quem criou a rede precisa aprovar você."); codigo.text = ""; }
            }
        }

        // ------------------------------------------ redes
        Text {
            Layout.topMargin: 12
            text: p.redes.length ? "Suas redes" : "Nenhuma rede ainda."
            font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
        }
        Repeater {
            model: p.redes
            delegate: Rectangle {
                id: cartao
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: colunaRede.implicitHeight + 24
                radius: Tema.raio
                color: Tema.elevado
                border.width: 1
                border.color: Tema.borda

                ColumnLayout {
                    id: colunaRede
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
                            color: cartao.modelData.ligada && cartao.modelData.status === "OK" ? Tema.ok
                                 : cartao.modelData.ligada ? Tema.aviso : Tema.texto4
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: cartao.modelData.nome
                                elide: Text.ElideRight
                                font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                            }
                            Text {
                                Layout.fillWidth: true
                                text: (cartao.modelData.minha ? "Criada por você · " : "") + p.situacao(cartao.modelData)
                                elide: Text.ElideRight
                                font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                            }
                        }
                        Botao {
                            texto: "Copiar código"
                            onClicado: { Quickshell.execDetached(["wl-copy", cartao.modelData.id]); p.avisar("Código " + cartao.modelData.id + " copiado.", false); }
                        }
                        Botao {
                            texto: cartao.modelData.ligada ? "Desligar" : "Ligar"
                            principal: !cartao.modelData.ligada
                            ativo: !acao.running
                            onClicado: acao.rodar([p.cmd, cartao.modelData.ligada ? "desligar" : "ligar", cartao.modelData.id], "")
                        }
                        Botao {
                            visible: p.removendo !== cartao.modelData.id
                            texto: "Remover"
                            onClicado: p.removendo = cartao.modelData.id
                        }
                        Botao {
                            visible: p.removendo === cartao.modelData.id
                            texto: cartao.modelData.minha ? "Apagar a rede" : "Sair de vez"
                            perigo: true
                            onClicado: { acao.rodar([p.cmd, "remover", cartao.modelData.id], "Rede removida."); p.removendo = ""; }
                        }
                    }

                    // Membros (só nas redes criadas aqui: este PC é o controlador)
                    Repeater {
                        model: cartao.modelData.membros
                        delegate: RowLayout {
                            id: membro
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: 18
                            spacing: 10
                            Rectangle { width: 6; height: 6; radius: 3; color: membro.modelData.online ? Tema.ok : Tema.texto4 }
                            Text {
                                visible: p.nomeando !== membro.modelData.id
                                Layout.fillWidth: true
                                text: (membro.modelData.nome || membro.modelData.id)
                                      + (membro.modelData.ip ? "  ·  " + ModoStreamer.ip(membro.modelData.ip) : "")
                                      + (membro.modelData.online && !membro.modelData.eu && membro.modelData.ping >= 0 ? "  ·  " + membro.modelData.ping + " ms" : "")
                                      + (!membro.modelData.autorizado ? "  ·  quer entrar" : "")
                                elide: Text.ElideRight
                                font.family: Tema.fonte; font.pixelSize: 12
                                color: membro.modelData.autorizado ? Tema.texto2 : Tema.aviso
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !membro.modelData.eu
                                    cursorShape: Qt.IBeamCursor
                                    onClicked: { p.nomeando = membro.modelData.id; apelido.text = membro.modelData.nome; }
                                }
                            }
                            Campo {
                                id: apelido
                                visible: p.nomeando === membro.modelData.id
                                Layout.fillWidth: true
                                rotulo: "Apelido de " + membro.modelData.id + " (Enter salva)"
                                onConfirmado: { acao.rodar([p.cmd, "nomear", membro.modelData.id, apelido.text], ""); p.nomeando = ""; }
                            }
                            Botao {
                                visible: !membro.modelData.autorizado
                                texto: "Aprovar"
                                principal: true
                                onClicado: acao.rodar([p.cmd, "aprovar", cartao.modelData.id, membro.modelData.id], "Aprovado.")
                            }
                            Botao {
                                visible: membro.modelData.autorizado && !membro.modelData.eu
                                texto: "Remover"
                                onClicado: acao.rodar([p.cmd, "bloquear", cartao.modelData.id, membro.modelData.id], "Removido da rede.")
                            }
                        }
                    }
                    Text {
                        visible: cartao.modelData.minha && cartao.modelData.ligada && cartao.modelData.membros.length <= 1
                        Layout.leftMargin: 18
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: "Ninguém entrou ainda. Mande o código para os amigos; quando alguém pedir para entrar, aparece aqui para você aprovar. Clique no código de alguém para dar um apelido."
                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
                    }

                    // ------------------------------ Nyxz Share (tela pela LAN)
                    ColumnLayout {
                        id: share
                        readonly property string meuIp: cartao.modelData.ip.split(",")[0].trim()
                        readonly property string prefixo: meuIp.split(".").slice(0, 3).join(".") + "."
                        readonly property var lista: p.transmissoes.filter(t => t.ip.indexOf(prefixo) === 0 && !t.minha)
                        readonly property bool meu: p.shareLigado && p.shareIp === meuIp
                        visible: cartao.modelData.ligada && cartao.modelData.status === "OK" && meuIp !== ""
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 6

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Tema.borda }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Image { source: "icones/tela.svg"; sourceSize: Qt.size(15, 15); opacity: 0.8 }
                            Text {
                                Layout.fillWidth: true
                                text: share.meu ? (p.shareTransmitindo ? "Você está transmitindo a tela" : "Nyxz Share ligado: escolha a tela no navegador")
                                    : share.lista.length ? "Transmissões nesta rede" : "Compartilhar a tela com quem está nesta rede"
                                elide: Text.ElideRight
                                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
                            }
                            Botao {
                                visible: !share.meu
                                texto: "Transmitir a tela"
                                ativo: !acao.running
                                onClicado: acao.rodar(["/usr/libexec/nyxz/share", "iniciar", share.meuIp], "Escolha a tela no navegador. O link para os amigos é http://" + share.meuIp + ":8787")
                            }
                            Botao {
                                visible: share.meu
                                texto: "Abrir o painel"
                                onClicado: Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8787/transmitir?ip=" + share.meuIp])
                            }
                            Botao {
                                visible: share.meu
                                texto: "Desligar"
                                perigo: true
                                onClicado: acao.rodar(["/usr/libexec/nyxz/share", "parar"], "Nyxz Share desligado.")
                            }
                        }
                        Repeater {
                            model: share.lista
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.leftMargin: 25
                                spacing: 10
                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData.nome || "Tela de " + modelData.ip) + "  ·  "
                                          + (modelData.espectadores === 1 ? "1 assistindo" : modelData.espectadores + " assistindo")
                                          + (modelData.protegida ? "  ·  com senha" : "")
                                    elide: Text.ElideRight
                                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto
                                }
                                Botao {
                                    texto: "Assistir"
                                    principal: true
                                    onClicado: Quickshell.execDetached(["/usr/libexec/nyxz/share", "assistir", modelData.ip])
                                }
                            }
                        }
                    }

                    // ------------------------------ Voz pela LAN (rede ligada e com IP)
                    ColumnLayout {
                        id: voz
                        readonly property string meuIp: cartao.modelData.ip.split(",")[0].trim()
                        readonly property string prefixo: meuIp.split(".").slice(0, 3).join(".") + "."
                        readonly property var salas: p.salas.filter(s => s.ip.indexOf(prefixo) === 0)
                        readonly property bool minhaAberta: p.vozAberta && p.vozIp === meuIp
                        visible: cartao.modelData.ligada && cartao.modelData.status === "OK" && meuIp !== "" && p.vozInstalada
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 6

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Tema.borda }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Image { source: "icones/microfone.svg"; sourceSize: Qt.size(15, 15); opacity: 0.8 }
                            Text {
                                Layout.fillWidth: true
                                text: voz.minhaAberta ? "Sua sala de voz está aberta" : voz.salas.length ? "Salas de voz nesta rede" : "Nenhuma sala de voz aberta nesta rede"
                                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
                            }
                            Botao {
                                visible: !voz.minhaAberta
                                texto: "Abrir sala de voz"
                                ativo: !acao.running
                                onClicado: acao.rodar(["/usr/libexec/nyxz/voz", "abrir", voz.meuIp, cartao.modelData.nome], "Sala aberta. Os amigos da rede já veem ela aqui (ou entram pelo Mumble em %s).".replace("%s", voz.meuIp))
                            }
                            Botao {
                                visible: voz.minhaAberta
                                texto: "Fechar a sala"
                                perigo: true
                                onClicado: acao.rodar(["/usr/libexec/nyxz/voz", "fechar"], "Sala fechada.")
                            }
                        }
                        Repeater {
                            model: voz.salas
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.leftMargin: 25
                                spacing: 10
                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData.minha ? "Sua sala" : "Sala em " + modelData.ip) + "  ·  "
                                          + (modelData.pessoas === 1 ? "1 pessoa" : modelData.pessoas + " pessoas")
                                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto
                                }
                                Botao {
                                    texto: "Entrar na conversa"
                                    principal: true
                                    onClicado: Quickshell.execDetached(["/usr/libexec/nyxz/voz", "entrar", modelData.ip])
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            Layout.topMargin: 14
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "Quem criou a rede precisa estar com o PC ligado para alguém novo entrar; quem já entrou joga normalmente. Com todas as redes desligadas, o serviço para e não ocupa memória."
            font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
        }
    }
}
