import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Automações (ideia 23, estilo Atalhos do iPhone): "quando acontecer X, faça Y".
// O editor monta a automação com escolhas e campos; quem percebe os gatilhos é o shell
// (Automacoes.qml) e quem faz as ações é /usr/libexec/nyxz/automacoes.
Pagina {
    id: p
    titulo: "Automações"
    descricao: "Quando acontecer algo, a Nyxz faz o que você pediu. Ex.: ao conectar o fone, troca o perfil de som; às 21h, liga a luz azul. Cada automação pode ser ligada e desligada."

    readonly property string cmd: "/usr/libexec/nyxz/automacoes"
    property var d: null                 // listar
    property var rascunho: null          // automação sendo editada
    property string aviso: ""
    property bool avisoErro: false
    property string removendo: ""
    readonly property var dias: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

    function atualizar() { cmdListar.rodar([cmd, "listar"]); }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    function copia(x) { return JSON.parse(JSON.stringify(x)); }
    Component.onCompleted: atualizar()
    Timer { id: limpa; interval: 8000; onTriggered: p.aviso = "" }

    Comando { id: cmdListar; onPronto: s => { try { p.d = JSON.parse(s); } catch (e) {} } }
    Process {
        id: acao
        stdinEnabled: true
        property string ok: ""
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => {
            if (codigo === 0) { if (acao.ok) p.avisar(acao.ok, false); }
            else p.avisar(erroAcao.text.trim() || "Não deu certo.", true);
            if (codigo === 0 && acao.ok === "Automação salva.") p.rascunho = null;
            p.atualizar();
        }
        function rodar(c, msg, entrada) {
            if (running) return;
            ok = msg || ""; command = c; running = true;
            if (entrada !== undefined) write(entrada);
            closeStdin();
        }
    }

    // ------------------------------------------------ textos
    function hora(iso) { return iso ? iso.slice(8, 10) + "/" + iso.slice(5, 7) + " " + iso.slice(11, 16) : ""; }
    function textoQuando(q) {
        if (!q) return "";
        switch (q.tipo) {
        case "horario": return "Às " + q.hora + (q.dias && q.dias.length && q.dias.length < 7 ? " (" + q.dias.map(i => p.dias[i]).join(", ") + ")" : ", todo dia");
        case "ao_entrar": return "Ao entrar na sessão";
        case "app_abriu": return "Quando " + (q.app || "um app") + " abrir";
        case "app_fechou": return "Quando " + (q.app || "um app") + " fechar";
        case "jogo_comecou": return "Quando um jogo começar";
        case "jogo_terminou": return "Quando um jogo terminar";
        case "rede_conectou": return "Ao conectar " + (q.nome ? "na rede " + q.nome : "numa rede");
        case "rede_desconectou": return "Ao desconectar " + (q.nome ? "da rede " + q.nome : "de uma rede");
        case "dispositivo_conectado":
        case "dispositivo_desconectado": {
            const o = { som: "um fone ou caixa", controle: "um controle", pendrive: "um pendrive ou HD" }[q.aparelho] || "um aparelho";
            return "Quando " + (q.nome ? "\"" + q.nome + "\"" : o) + (q.tipo === "dispositivo_conectado" ? " for conectado" : " for desconectado");
        }
        case "monitor_conectado": return "Quando uma tela for conectada";
        case "bateria_baixa": return "Quando a bateria " + (q.nome ? "de " + q.nome : "de um aparelho") + " ficar abaixo de " + (q.limite || 20) + "%";
        case "ram_alta": return "Quando a memória passar de " + (q.limite || 90) + "%";
        }
        return q.tipo;
    }
    function textoAcao(a) {
        const lig = a.ligar === false ? "desligar" : "ligar";
        switch (a.tipo) {
        case "perfil_som": return "perfil de som " + (a.perfil || "?");
        case "saida_app": return "som de " + (a.app || "?") + " em " + (saidaNome(a.saida) || "?");
        case "volume": return "volume em " + (a.valor || 50) + "%";
        case "nao_perturbe": return lig + " o não perturbe";
        case "luz_azul": return lig + " a luz azul";
        case "brilho": return "brilho em " + (a.valor || 50) + "%";
        case "wallpaper": return "papel de parede";
        case "vpn": return lig + " a VPN" + (a.ligar !== false && a.vpn ? " " + vpnNome(a.vpn) : "");
        case "energia": return "energia em " + (a.perfil || "equilibrado");
        case "replay": return lig + " o replay";
        case "projeto": return (a.abrir === false ? "fechar" : "abrir") + " o projeto " + (a.projeto || "?");
        case "banco": return lig + " o banco " + (a.banco || "?");
        case "abrir": return "abrir " + (a.app || "?");
        case "notificar": return "avisar \"" + (a.texto || "") + "\"";
        case "comando": return "rodar um comando";
        }
        return a.tipo;
    }
    function saidaNome(n) { const s = p.d ? p.d.opcoes.saidas.find(x => x.nome === n) : null; return s ? s.descricao : n; }
    function vpnNome(u) { const v = p.d ? p.d.opcoes.vpns.find(x => x.uuid === u) : null; return v ? v.nome : ""; }

    // ------------------------------------------------ edição
    function novoQuando(tipo) {
        const padrao = { horario: { hora: "21:00", dias: [] }, bateria_baixa: { limite: 20, nome: "" }, ram_alta: { limite: 90 },
                         dispositivo_conectado: { aparelho: "qualquer", nome: "" }, dispositivo_desconectado: { aparelho: "qualquer", nome: "" } };
        const r = copia(p.rascunho);
        r.quando = Object.assign({ tipo: tipo }, padrao[tipo] || {});
        p.rascunho = r;
    }
    function mudarQuando(k, v) { const r = copia(p.rascunho); r.quando[k] = v; p.rascunho = r; }
    function novaAcao(tipo) {
        const padrao = { volume: { valor: 50 }, brilho: { valor: 50 }, luz_azul: { ligar: true, temperatura: 4500 },
                         energia: { perfil: "equilibrado" }, notificar: { texto: "" }, nao_perturbe: { ligar: true },
                         replay: { ligar: true }, vpn: { ligar: true, vpn: "" }, projeto: { abrir: true, projeto: "" }, banco: { ligar: true, banco: "" } };
        const r = copia(p.rascunho);
        r.fazer.push(Object.assign({ tipo: tipo }, padrao[tipo] || {}));
        p.rascunho = r;
    }
    function mudarAcao(i, k, v) { const r = copia(p.rascunho); r.fazer[i][k] = v; p.rascunho = r; }
    function tirarAcao(i) { const r = copia(p.rascunho); r.fazer.splice(i, 1); p.rascunho = r; }
    // Campos de texto: mudam o rascunho sem redesenhar (para não perder o cursor)
    function campoQuando(k, v) { if (p.rascunho) p.rascunho.quando[k] = v; }
    function campoAcao(i, k, v) { if (p.rascunho && p.rascunho.fazer[i]) p.rascunho.fazer[i][k] = v; }

    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }

    // ================================================ editor
    Rectangle {
        visible: p.rascunho !== null
        Layout.fillWidth: true
        Layout.preferredHeight: editor.implicitHeight + 32
        radius: Tema.raio
        color: Tema.elevado
        border.width: 1
        border.color: Tema.bordaPainel

        ColumnLayout {
            id: editor
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 10

            Campo {
                id: nome
                Layout.fillWidth: true
                rotulo: "Nome (opcional)"
                Component.onCompleted: if (p.rascunho) text = p.rascunho.nome || ""
                onTextChanged: if (p.rascunho) p.rascunho.nome = text
            }
            Connections {
                target: p
                function onRascunhoChanged() { if (p.rascunho && nome.text !== (p.rascunho.nome || "")) nome.text = p.rascunho.nome || ""; }
            }

            // ---------- quando
            Text { Layout.topMargin: 4; text: "Quando"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
            Escolha {
                Layout.fillWidth: true
                opcoes: p.d ? Object.keys(p.d.gatilhos).map(k => ({ t: p.d.gatilhos[k], v: k })) : []
                valor: p.rascunho && p.rascunho.quando ? p.rascunho.quando.tipo : ""
                onEscolhido: v => p.novoQuando(v)
            }
            ColumnLayout {
                id: paramsQuando
                readonly property var q: p.rascunho ? p.rascunho.quando : null
                readonly property string tipo: q ? q.tipo : ""
                visible: tipo !== ""
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: p.textoQuando(paramsQuando.q)
                    font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                }
                // Um conjunto de campos por tipo; recriado quando o tipo muda
                Loader {
                    Layout.fillWidth: true
                    active: paramsQuando.tipo !== ""
                    sourceComponent: {
                        switch (paramsQuando.tipo) {
                        case "horario": return cHorario;
                        case "app_abriu": case "app_fechou": return cApp;
                        case "rede_conectou": case "rede_desconectou": case "monitor_conectado": return cNome;
                        case "dispositivo_conectado": case "dispositivo_desconectado": return cAparelho;
                        case "bateria_baixa": return cBateria;
                        case "ram_alta": return cLimite;
                        }
                        return null;
                    }
                }
            }

            // ---------- faça
            Text { Layout.topMargin: 8; text: "Faça"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
            Repeater {
                model: p.rascunho ? p.rascunho.fazer.length : 0
                delegate: Rectangle {
                    id: cartaoAcao
                    required property int index
                    readonly property var a: p.rascunho && p.rascunho.fazer[index] ? p.rascunho.fazer[index] : ({})
                    Layout.fillWidth: true
                    Layout.preferredHeight: colAcao.implicitHeight + 20
                    radius: Tema.raio
                    color: "transparent"
                    border.width: 1
                    border.color: Tema.borda
                    ColumnLayout {
                        id: colAcao
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: (cartaoAcao.index + 1) + ". " + (p.d ? p.d.acoes[cartaoAcao.a.tipo] : "") + "  ·  " + p.textoAcao(cartaoAcao.a)
                                elide: Text.ElideRight
                                font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                            }
                            Text {
                                text: "Tirar"
                                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: p.tirarAcao(cartaoAcao.index) }
                            }
                        }
                        // Ligar / desligar
                        Escolha {
                            visible: ["nao_perturbe", "luz_azul", "vpn", "replay", "banco"].indexOf(cartaoAcao.a.tipo) >= 0
                            Layout.fillWidth: true
                            opcoes: [{ t: "Ligar", v: true }, { t: "Desligar", v: false }]
                            valor: cartaoAcao.a.ligar !== false
                            onEscolhido: v => p.mudarAcao(cartaoAcao.index, "ligar", v)
                        }
                        Escolha {
                            visible: cartaoAcao.a.tipo === "projeto"
                            Layout.fillWidth: true
                            opcoes: [{ t: "Abrir", v: true }, { t: "Fechar", v: false }]
                            valor: cartaoAcao.a.abrir !== false
                            onEscolhido: v => p.mudarAcao(cartaoAcao.index, "abrir", v)
                        }
                        // Listas vindas do sistema
                        Escolha {
                            readonly property var fonte: !p.d ? [] : ({
                                perfil_som: p.d.opcoes.perfis.map(x => ({ t: x, v: x })),
                                saida_app: p.d.opcoes.saidas.map(x => ({ t: x.descricao, v: x.nome })),
                                vpn: cartaoAcao.a.ligar === false ? [] : [{ t: "A última usada", v: "" }].concat(p.d.opcoes.vpns.map(x => ({ t: x.nome, v: x.uuid }))),
                                projeto: p.d.opcoes.projetos.map(x => ({ t: x, v: x })),
                                banco: p.d.opcoes.bancos.map(x => ({ t: x, v: x })),
                                energia: [{ t: "Economia", v: "economia" }, { t: "Equilibrado", v: "equilibrado" }, { t: "Desempenho", v: "desempenho" }]
                            })[cartaoAcao.a.tipo] || []
                            readonly property string chave: ({ perfil_som: "perfil", saida_app: "saida", vpn: "vpn", projeto: "projeto", banco: "banco", energia: "perfil" })[cartaoAcao.a.tipo] || ""
                            visible: chave !== "" && fonte.length > 0
                            Layout.fillWidth: true
                            opcoes: fonte
                            valor: cartaoAcao.a[chave]
                            onEscolhido: v => p.mudarAcao(cartaoAcao.index, chave, v)
                        }
                        Text {
                            readonly property string falta: !p.d ? "" : ({
                                perfil_som: p.d.opcoes.perfis.length ? "" : "Nenhum perfil de som salvo ainda. Crie um em Som → Perfis.",
                                projeto: p.d.opcoes.projetos.length ? "" : "Nenhum projeto no Dev Hub ainda.",
                                banco: p.d.opcoes.bancos.length ? "" : "Nenhum banco no Dev Hub ainda."
                            })[cartaoAcao.a.tipo] || ""
                            visible: falta !== ""
                            text: falta
                            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.aviso
                        }
                        // Campos de texto (o que cada ação pede)
                        Repeater {
                            model: ({
                                saida_app: [{ k: "app", r: "Nome do app (ex.: discord, spotify)" }],
                                volume: [{ k: "valor", r: "Volume (%)" }],
                                brilho: [{ k: "valor", r: "Brilho (%)" }],
                                luz_azul: cartaoAcao.a.ligar === false ? [] : [{ k: "temperatura", r: "Temperatura (mais baixo = mais quente; ex.: 4000)" }],
                                wallpaper: [{ k: "arquivo", r: "Arquivo da imagem ou vídeo (ex.: ~/Imagens/noite.jpg)" }],
                                abrir: [{ k: "app", r: "App (ex.: brave-browser, vesktop, code ~/Projetos/site)" }],
                                notificar: [{ k: "texto", r: "Texto do aviso" }],
                                comando: [{ k: "comando", r: "Comando (roda como você, ex.: ~/scripts/backup-fotos.sh)" }]
                            })[cartaoAcao.a.tipo] || []
                            delegate: Campo {
                                required property var modelData
                                Layout.fillWidth: true
                                rotulo: modelData.r
                                Component.onCompleted: text = cartaoAcao.a[modelData.k] !== undefined ? String(cartaoAcao.a[modelData.k]) : ""
                                onTextChanged: {
                                    const numero = ["valor", "temperatura"].indexOf(modelData.k) >= 0;
                                    p.campoAcao(cartaoAcao.index, modelData.k, numero ? (parseInt(text) || 0) : text);
                                }
                            }
                        }
                    }
                }
            }
            Text { text: "Adicionar ação"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
            Escolha {
                Layout.fillWidth: true
                opcoes: p.d ? Object.keys(p.d.acoes).map(k => ({ t: "+ " + p.d.acoes[k], v: k })) : []
                valor: ""
                onEscolhido: v => p.novaAcao(v)
            }

            RowLayout {
                Layout.topMargin: 6
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                Botao { texto: "Cancelar"; onClicado: p.rascunho = null }
                Botao {
                    texto: "Testar agora"
                    ativo: !acao.running && p.rascunho && p.rascunho.fazer.length > 0
                    onClicado: acao.rodar([p.cmd, "testar"], "Ações feitas.", JSON.stringify(p.rascunho))
                }
                Botao {
                    texto: "Salvar"
                    principal: true
                    ativo: !acao.running && p.rascunho && p.rascunho.quando && p.rascunho.fazer.length > 0
                    onClicado: acao.rodar([p.cmd, "salvar"], "Automação salva.", JSON.stringify(p.rascunho))
                }
            }
        }
    }

    // Campos de cada gatilho
    Component {
        id: cHorario
        ColumnLayout {
            spacing: 8
            Campo {
                Layout.preferredWidth: 160
                rotulo: "Horário (HH:MM)"
                Component.onCompleted: text = p.rascunho.quando.hora || ""
                onTextChanged: p.campoQuando("hora", text.trim())
            }
            Escolha {
                Layout.fillWidth: true
                multipla: true
                opcoes: p.dias.map((t, i) => ({ t: t, v: i }))
                valores: p.rascunho && p.rascunho.quando.dias ? p.rascunho.quando.dias : []
                onEscolhido: v => {
                    const atual = (p.rascunho.quando.dias || []).slice();
                    const i = atual.indexOf(v);
                    if (i >= 0) atual.splice(i, 1); else atual.push(v);
                    p.mudarQuando("dias", atual.sort());
                }
            }
            Text { text: "Sem nenhum dia marcado, vale todo dia."; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
        }
    }
    Component {
        id: cApp
        Campo {
            rotulo: "Nome do app (ex.: discord, steam, code)"
            Component.onCompleted: text = p.rascunho.quando.app || ""
            onTextChanged: p.campoQuando("app", text.trim())
        }
    }
    Component {
        id: cNome
        Campo {
            rotulo: "Nome (vazio = qualquer)"
            Component.onCompleted: text = p.rascunho.quando.nome || ""
            onTextChanged: p.campoQuando("nome", text.trim())
        }
    }
    Component {
        id: cAparelho
        ColumnLayout {
            spacing: 8
            Escolha {
                Layout.fillWidth: true
                opcoes: [{ t: "Qualquer", v: "qualquer" }, { t: "Fone ou caixa", v: "som" }, { t: "Controle", v: "controle" }, { t: "Pendrive ou HD", v: "pendrive" }]
                valor: p.rascunho ? (p.rascunho.quando.aparelho || "qualquer") : "qualquer"
                onEscolhido: v => p.mudarQuando("aparelho", v)
            }
            Campo {
                Layout.fillWidth: true
                rotulo: "Nome contém (vazio = qualquer; ex.: Xbox, WH-1000)"
                Component.onCompleted: text = p.rascunho.quando.nome || ""
                onTextChanged: p.campoQuando("nome", text.trim())
            }
        }
    }
    Component {
        id: cBateria
        ColumnLayout {
            spacing: 8
            Campo {
                Layout.preferredWidth: 200
                rotulo: "Abaixo de (%)"
                Component.onCompleted: text = String(p.rascunho.quando.limite || 20)
                onTextChanged: p.campoQuando("limite", parseInt(text) || 20)
            }
            Campo {
                Layout.fillWidth: true
                rotulo: "Nome do aparelho contém (vazio = qualquer)"
                Component.onCompleted: text = p.rascunho.quando.nome || ""
                onTextChanged: p.campoQuando("nome", text.trim())
            }
        }
    }
    Component {
        id: cLimite
        Campo {
            rotulo: "Acima de (%)"
            Component.onCompleted: text = String(p.rascunho.quando.limite || 90)
            onTextChanged: p.campoQuando("limite", parseInt(text) || 90)
        }
    }

    // ================================================ lista
    RowLayout {
        visible: p.rascunho === null
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: !p.d ? "" : p.d.automacoes.length ? p.d.automacoes.filter(a => a.ligada !== false).length + " de " + p.d.automacoes.length + " ligadas" : "Nenhuma automação ainda. Comece por um modelo ou crie do zero."
            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto2
        }
        Botao {
            texto: "Nova automação"
            principal: true
            onClicado: p.rascunho = { nome: "", ligada: true, quando: null, fazer: [] }
        }
    }

    Repeater {
        model: p.rascunho === null && p.d ? p.d.automacoes : []
        delegate: Rectangle {
            id: cartao
            required property var modelData
            readonly property var a: modelData
            readonly property var ultima: p.d.historico.find(h => h.id === a.id)
            Layout.fillWidth: true
            Layout.preferredHeight: linha.implicitHeight + 24
            radius: Tema.raio
            color: Tema.elevado
            border.width: 1
            border.color: Tema.borda
            opacity: a.ligada === false ? 0.6 : 1
            RowLayout {
                id: linha
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14
                spacing: 12
                Interruptor {
                    ligado: cartao.a.ligada !== false
                    onAlternado: v => acao.rodar([p.cmd, "ligar", cartao.a.id, v ? "sim" : "nao"], "")
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { Layout.fillWidth: true; text: cartao.a.nome; elide: Text.ElideRight; font.family: Tema.fonte; font.pixelSize: 14; font.weight: Font.Medium; color: Tema.texto }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: p.textoQuando(cartao.a.quando) + ": " + cartao.a.fazer.map(x => p.textoAcao(x)).join(", ") + "."
                        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
                    }
                    Text {
                        visible: !!cartao.ultima
                        text: cartao.ultima ? "Última vez: " + p.hora(cartao.ultima.quando) + (cartao.ultima.ok ? "" : "  ·  com erro: " + cartao.ultima.erros.join("; ")) : ""
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        font.family: Tema.fonte; font.pixelSize: 11; color: cartao.ultima && !cartao.ultima.ok ? Tema.erro : Tema.texto3
                    }
                }
                Botao { texto: "Testar"; ativo: !acao.running; onClicado: acao.rodar([p.cmd, "executar", cartao.a.id, "teste"], "Ações feitas.") }
                Botao { texto: "Editar"; onClicado: p.rascunho = p.copia(cartao.a) }
                Botao {
                    texto: p.removendo === cartao.a.id ? "Confirmar" : "Remover"
                    perigo: true
                    onClicado: {
                        if (p.removendo !== cartao.a.id) { p.removendo = cartao.a.id; return; }
                        p.removendo = "";
                        acao.rodar([p.cmd, "remover", cartao.a.id], "Automação removida.");
                    }
                }
            }
        }
    }

    // Modelos prontos
    Text {
        visible: p.rascunho === null
        Layout.topMargin: 14
        text: "Modelos prontos"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Escolha {
        visible: p.rascunho === null
        Layout.fillWidth: true
        opcoes: p.d ? p.d.modelos.map((m, i) => ({ t: "+ " + m.nome, v: i })) : []
        valor: -1
        onEscolhido: v => { const m = p.copia(p.d.modelos[v]); m.ligada = true; p.rascunho = m; }
    }

    // Histórico
    Text {
        visible: p.rascunho === null && p.d !== null && p.d.historico.length > 0
        Layout.topMargin: 14
        text: "O que aconteceu"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Repeater {
        model: p.rascunho === null && p.d ? p.d.historico.slice(0, 8) : []
        delegate: Text {
            required property var modelData
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: p.hora(modelData.quando) + "  ·  " + (modelData.nome || "Teste") + (modelData.motivo ? " (" + modelData.motivo + ")" : "") + (modelData.ok ? "" : "  ·  erro")
            font.family: Tema.fonte; font.pixelSize: 12; color: modelData.ok ? Tema.texto2 : Tema.erro
        }
    }

    // Fileira de escolhas (uma ou várias)
    component Escolha: Flow {
        id: esc
        property var opcoes: []
        property var valor
        property bool multipla: false
        property var valores: []
        signal escolhido(var v)
        spacing: 6
        Repeater {
            model: esc.opcoes
            delegate: Rectangle {
                required property var modelData
                readonly property bool marcado: esc.multipla ? esc.valores.indexOf(modelData.v) >= 0 : esc.valor === modelData.v
                implicitWidth: rotuloEsc.implicitWidth + 20
                implicitHeight: 26
                radius: 13
                color: marcado ? Tema.selecionado : areaEsc.containsMouse ? Tema.hover : "transparent"
                border.width: 1
                border.color: marcado ? Tema.bordaPainel : Tema.borda
                Text { id: rotuloEsc; anchors.centerIn: parent; text: parent.modelData.t; font.family: Tema.fonte; font.pixelSize: 12; color: parent.marcado ? Tema.texto : Tema.texto2 }
                MouseArea { id: areaEsc; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: esc.escolhido(parent.modelData.v) }
            }
        }
    }
}
