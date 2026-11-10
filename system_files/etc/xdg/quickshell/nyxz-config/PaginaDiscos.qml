import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Discos (estilo CrystalDiskInfo + CrystalDiskMark): saúde, ficha, histórico, testes SMART
// e teste de velocidade. Os dados vêm do timer nyxz-discos (a cada 30 min e no boot);
// "Ler agora" pede uma leitura nova. Nada fica rodando.
Pagina {
    id: p
    titulo: "Discos"
    descricao: "A saúde de cada SSD e HD, lida do próprio disco (SMART). A Nyxz confere sozinha a cada 30 minutos e avisa se algo piorar."

    readonly property string cmd: "/usr/libexec/nyxz/discos"
    property var discos: []
    property string quando: ""
    property var velocidade: []
    property bool temFio: true
    property string aviso: ""
    property bool lendo: false
    property string progresso: ""
    property var mostrarSerie: ({})
    property var abrirAtributos: ({})

    function atualizar() { cmdEstado.rodar([cmd, "estado"]); }
    Component.onCompleted: atualizar()
    // Durante um teste SMART o andamento muda: atualiza a cada 20 s
    Timer { interval: 20000; running: p.discos.some(d => d.autoteste_andamento !== undefined); repeat: true; onTriggered: lerAgora() }

    function lerAgora() { if (!acao.running) { p.lendo = true; acao.rodar([cmd, "verificar"]); } }

    function tamanho(b) {
        if (b === undefined || b === null) return "—";
        const u = ["B", "KB", "MB", "GB", "TB", "PB"];
        let i = 0, v = b;
        while (v >= 1000 && i < u.length - 1) { v /= 1000; i++; }
        return v.toFixed(v < 10 && i > 2 ? 2 : v < 100 && i > 2 ? 1 : 0).replace(".", ",") + " " + u[i];
    }
    function hora(iso) { return iso ? iso.slice(11, 16) + " de " + iso.slice(8, 10) + "/" + iso.slice(5, 7) : "nunca"; }
    function corEstado(e) { return { bom: Tema.ok, atencao: Tema.aviso, ruim: Tema.erro }[e] || Tema.texto3; }
    function nomeEstado(e) { return { bom: "Bom", atencao: "Atenção", ruim: "Ruim" }[e] || "Sem dados"; }
    function alternar(mapa, chave) { const m = Object.assign({}, mapa); m[chave] = !m[chave]; return m; }

    Comando {
        id: cmdEstado
        onPronto: s => {
            try {
                const d = JSON.parse(s);
                p.discos = d.discos; p.quando = d.quando; p.velocidade = d.velocidade; p.temFio = d.fio;
            } catch (e) {}
            // Primeira vez (o timer ainda não rodou): lê agora
            if (!p.quando && !p.lendo) p.lerAgora();
        }
    }
    Process {
        id: acao
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => {
            p.lendo = false;
            if (codigo !== 0) p.aviso = erroAcao.text.trim() || "Não deu para ler os discos.";
            p.atualizar();
        }
        function rodar(c) { if (running) return; p.aviso = ""; command = c; running = true; }
    }
    Process {
        id: teste
        stdout: SplitParser {
            onRead: linha => {
                try {
                    const d = JSON.parse(linha);
                    if (d.progresso) p.progresso = "Testando " + d.progresso + "…";
                    if (d.fim) p.progresso = "";
                } catch (e) {}
            }
        }
        stderr: StdioCollector { id: erroTeste }
        onExited: codigo => { if (codigo !== 0) p.aviso = erroTeste.text.trim(); p.progresso = ""; p.atualizar(); }
    }

    // ---------------------------------------------- topo
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: p.lendo ? "Lendo os discos…" : "Última leitura: " + p.hora(p.quando)
            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
        }
        Botao { texto: "Ler agora"; ativo: !acao.running; onClicado: p.lerAgora() }
    }
    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.erro
    }

    // ---------------------------------------------- um cartão por disco
    Repeater {
        model: p.discos
        delegate: Rectangle {
            id: cartao
            required property var modelData
            readonly property var d: modelData
            readonly property bool nvme: d.tipo === "NVMe"
            Layout.fillWidth: true
            Layout.preferredHeight: corpo.implicitHeight + 28
            radius: Tema.raio
            color: Tema.elevado
            border.width: 1
            border.color: Tema.borda

            ColumnLayout {
                id: corpo
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                // Cabeçalho: modelo e estado
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: cartao.d.modelo; font.family: Tema.fonte; font.pixelSize: 14; font.weight: Font.Medium; color: Tema.texto }
                        Text {
                            text: [cartao.d.tipo, p.tamanho(cartao.d.capacidade), cartao.d.interface, cartao.d.disco].filter(x => x).join(" · ")
                            font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                        }
                    }
                    Rectangle {
                        implicitWidth: rotuloEstado.implicitWidth + 26
                        implicitHeight: 28
                        radius: 14
                        color: "transparent"
                        border.width: 1
                        border.color: p.corEstado(cartao.d.estado)
                        Text {
                            id: rotuloEstado
                            anchors.centerIn: parent
                            text: p.nomeEstado(cartao.d.estado) + (cartao.d.temperatura ? "  ·  " + cartao.d.temperatura + " °C" : "")
                            font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium
                            color: p.corEstado(cartao.d.estado)
                        }
                    }
                }
                Repeater {
                    model: cartao.d.motivos
                    delegate: Text {
                        required property string modelData
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: modelData
                        font.family: Tema.fonte; font.pixelSize: 12
                        color: cartao.d.estado === "bom" || cartao.d.estado === "desconhecido" ? Tema.texto2 : p.corEstado(cartao.d.estado)
                    }
                }

                // Números principais
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 18
                    rowSpacing: 10
                    Repeater {
                        model: [
                            { r: "Vida útil usada", v: cartao.d.vida_usada !== undefined && cartao.d.vida_usada !== null ? cartao.d.vida_usada + "%" : null },
                            { r: "Reserva disponível", v: cartao.d.reserva !== undefined && cartao.d.reserva !== null ? cartao.d.reserva + "%" : null },
                            { r: "Total escrito", v: cartao.d.escrito_bytes ? p.tamanho(cartao.d.escrito_bytes) : null },
                            { r: "Total lido", v: cartao.d.lido_bytes ? p.tamanho(cartao.d.lido_bytes) : null },
                            { r: "Horas ligado", v: cartao.d.horas !== undefined && cartao.d.horas !== null ? cartao.d.horas.toLocaleString(Qt.locale("pt_BR"), "f", 0) + " h" : null },
                            { r: "Vezes ligado", v: cartao.d.ligacoes !== undefined && cartao.d.ligacoes !== null ? String(cartao.d.ligacoes) : null },
                            { r: "Desligamentos inesperados", v: cartao.d.desligamentos_inesperados !== undefined && cartao.d.desligamentos_inesperados !== null ? String(cartao.d.desligamentos_inesperados) : null },
                            { r: "Erros de mídia", v: cartao.d.erros_midia !== undefined && cartao.d.erros_midia !== null ? String(cartao.d.erros_midia) : null },
                            { r: "Erros de integridade", v: cartao.d.erros_integridade !== undefined && cartao.d.erros_integridade !== null ? String(cartao.d.erros_integridade) : null },
                            { r: "Firmware", v: cartao.d.firmware || null }
                        ].filter(x => x.v !== null)
                        delegate: ColumnLayout {
                            required property var modelData
                            spacing: 1
                            Layout.fillWidth: true
                            Text { text: modelData.r; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
                            Text { text: modelData.v; font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto }
                        }
                    }
                }

                // Número de série (oculto por padrão)
                RowLayout {
                    visible: cartao.d.serie !== ""
                    spacing: 10
                    Text { text: "Número de série"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
                    Text {
                        text: p.mostrarSerie[cartao.d.disco] ? cartao.d.serie : "••••••••••"
                        font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto2
                    }
                    Text {
                        text: p.mostrarSerie[cartao.d.disco] ? "Esconder" : "Mostrar"
                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: p.mostrarSerie = p.alternar(p.mostrarSerie, cartao.d.disco) }
                    }
                }

                // Partições
                Repeater {
                    model: cartao.d.particoes
                    delegate: Text {
                        required property var modelData
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: modelData.nome + "  ·  " + p.tamanho(modelData.tamanho)
                              + (modelData.sistema ? "  ·  " + modelData.sistema : "")
                              + (modelData.rotulo ? "  ·  " + modelData.rotulo : "")
                              + (modelData.montado.length ? "  ·  " + modelData.montado.join(", ") : "")
                        font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3
                    }
                }

                // Histórico: escrita por dia e temperatura máxima (últimos 30 dias)
                ColumnLayout {
                    readonly property var escrita: cartao.d.historico ? cartao.d.historico.escrita_dia : []
                    readonly property real maior: Math.max(1, ...escrita.map(x => x.bytes))
                    visible: escrita.length >= 2
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: "Escrita por dia (30 dias)" + (cartao.d.historico && cartao.d.historico.anos_restantes
                              ? "  ·  no ritmo atual, a vida útil dura mais ~" + String(cartao.d.historico.anos_restantes).replace(".", ",") + " anos" : "")
                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                    }
                    Row {
                        id: barras
                        Layout.fillWidth: true
                        height: 40
                        spacing: 3
                        Repeater {
                            model: parent.parent.escrita
                            delegate: Rectangle {
                                required property var modelData
                                width: Math.max(4, (barras.width - 3 * 29) / 30)
                                height: Math.max(2, 40 * modelData.bytes / barras.parent.maior)
                                anchors.bottom: parent.bottom
                                radius: 2
                                color: Tema.suave
                                opacity: 0.7
                            }
                        }
                    }
                }

                // Atributos SMART completos (SATA/HD)
                ColumnLayout {
                    visible: cartao.d.atributos.length > 0
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: (p.abrirAtributos[cartao.d.disco] ? "▾ " : "▸ ") + "Todos os atributos SMART (" + cartao.d.atributos.length + ")"
                        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: p.abrirAtributos = p.alternar(p.abrirAtributos, cartao.d.disco) }
                    }
                    Repeater {
                        model: p.abrirAtributos[cartao.d.disco] ? cartao.d.atributos : []
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8
                            Text { Layout.preferredWidth: 34; text: modelData.id.toString(16).toUpperCase().padStart(2, "0"); font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3 }
                            Text { Layout.fillWidth: true; text: modelData.nome.replace(/_/g, " "); elide: Text.ElideRight; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto2 }
                            Text { Layout.preferredWidth: 110; text: modelData.valor + " / " + modelData.pior + " / " + modelData.limite; font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto3 }
                            Text { Layout.preferredWidth: 110; text: modelData.bruto; elide: Text.ElideRight; font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto }
                        }
                    }
                }

                // Testes do próprio disco
                RowLayout {
                    visible: cartao.d.estado !== "desconhecido"
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: cartao.d.autoteste_andamento !== undefined ? "Teste do disco em andamento: " + cartao.d.autoteste_andamento + "%"
                              : cartao.d.autoteste ? "Último teste do disco: " + cartao.d.autoteste.resultado : "O disco ainda não fez nenhum teste."
                        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
                    }
                    Botao { texto: "Teste curto (~2 min)"; ativo: !acao.running && cartao.d.autoteste_andamento === undefined; onClicado: acao.rodar([p.cmd, "teste", "curto", cartao.d.disco]) }
                    Botao { texto: "Teste completo"; ativo: !acao.running && cartao.d.autoteste_andamento === undefined; onClicado: acao.rodar([p.cmd, "teste", "longo", cartao.d.disco]) }
                }
            }
        }
    }

    // ---------------------------------------------- teste de velocidade
    Text {
        Layout.topMargin: 16
        text: "Teste de velocidade"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Leitura e escrita sequencial e aleatória, como no CrystalDiskMark. Leva cerca de 1 minuto e usa um arquivo temporário de 512 MB na pasta escolhida (apagado no fim)."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: pastaTeste; Layout.fillWidth: true; rotulo: "Pasta no disco a testar"; text: Quickshell.env("HOME") }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: teste.running ? "Testando…" : "Testar velocidade"
            principal: true
            ativo: p.temFio && !teste.running
            onClicado: { teste.command = [p.cmd, "velocidade", pastaTeste.text.trim()]; teste.running = true; }
        }
    }
    Text {
        visible: p.progresso !== ""
        text: p.progresso
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
    }
    // Último resultado em tabela (MB/s)
    GridLayout {
        readonly property var ultimo: p.velocidade.length ? p.velocidade[p.velocidade.length - 1] : null
        visible: ultimo !== null
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 18
        rowSpacing: 6
        Text { text: parent.ultimo ? "Em " + parent.ultimo.pasta : ""; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
        Text { text: "Leitura"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
        Text { text: "Escrita"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
        Repeater {
            model: parent.ultimo ? parent.ultimo.testes : []
            delegate: Text {
                required property var modelData
                required property int index
                Layout.row: index + 1
                Layout.column: 0
                text: modelData.nome
                font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto2
            }
        }
        Repeater {
            model: parent.ultimo ? parent.ultimo.testes : []
            delegate: Text {
                required property var modelData
                required property int index
                Layout.row: index + 1
                Layout.column: 1
                text: modelData.leitura !== null ? modelData.leitura.toLocaleString(Qt.locale("pt_BR"), "f", 1) + " MB/s" : "—"
                font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto
            }
        }
        Repeater {
            model: parent.ultimo ? parent.ultimo.testes : []
            delegate: Text {
                required property var modelData
                required property int index
                Layout.row: index + 1
                Layout.column: 2
                text: modelData.escrita !== null ? modelData.escrita.toLocaleString(Qt.locale("pt_BR"), "f", 1) + " MB/s" : "—"
                font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto
            }
        }
    }
}
