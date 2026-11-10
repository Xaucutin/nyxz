import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Estatísticas por app (Nyxz Stats): tempo em foco e aberto, processador, disco, RAM e
// energia por app e por jogo, com comparação com o período anterior. Coletor:
// nyxz-stats (serviço do usuário, lê o kernel a cada 30 s). Tudo fica só neste PC.
Pagina {
    id: p
    titulo: "Estatísticas"
    descricao: "Quanto tempo você passa em cada app e jogo, e quanto cada um usa do PC. Tudo fica só neste computador; títulos de janela e nomes de arquivo não são guardados."

    readonly property string cmd: "/usr/libexec/nyxz/estatisticas"
    property string periodo: "semana"
    property string metrica: "foco_s"
    property var r: null                // resumo
    property var cfg: null
    property string aberto: ""          // app com o detalhe aberto
    property var detalhe: null
    property string aviso: ""
    property bool confirmarApagar: false

    readonly property var periodos: [
        { id: "hoje", nome: "Hoje" }, { id: "semana", nome: "7 dias" }, { id: "mes", nome: "30 dias" },
        { id: "ano", nome: "Ano" }, { id: "tudo", nome: "Tudo" }
    ]
    readonly property var metricas: [
        { id: "foco_s", nome: "Em foco" }, { id: "aberto_s", nome: "Aberto" }, { id: "cpu_s", nome: "Processador" },
        { id: "escrito", nome: "Disco" }, { id: "ram_pico", nome: "RAM" }, { id: "energia_wh", nome: "Energia" }
    ]
    readonly property var lista: r ? r.apps.filter(a => !a.jogo).slice().sort((a, b) => b[metrica] - a[metrica]).filter(a => a[metrica] > 0) : []
    readonly property var jogos: r ? r.apps.filter(a => a.jogo).sort((a, b) => b.foco_s - a.foco_s) : []
    readonly property real maior: lista.length ? Math.max(1, lista[0][metrica]) : 1

    function atualizar() { cmdResumo.rodar([cmd, "resumo", periodo]); cmdConfig.rodar([cmd, "config"]); }
    onPeriodoChanged: { atualizar(); if (aberto) abrirApp(aberto); }
    Component.onCompleted: atualizar()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: p.atualizar() }

    Comando { id: cmdResumo; onPronto: s => { try { p.r = JSON.parse(s); } catch (e) {} } }
    Comando { id: cmdConfig; onPronto: s => { try { p.cfg = JSON.parse(s); } catch (e) {} } }
    Comando { id: cmdDetalhe; onPronto: s => { try { p.detalhe = JSON.parse(s); } catch (e) {} } }
    Process {
        id: acao
        property string ok: ""
        stdout: StdioCollector { id: saidaAcao }
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => {
            p.aviso = codigo === 0 ? acao.ok.replace("%s", saidaAcao.text.trim()) : (erroAcao.text.trim() || "Não deu certo.");
            limpa.restart();
            p.atualizar();
        }
        function rodar(c, msg) { if (running) return; ok = msg || ""; command = c; running = true; }
    }
    Timer { id: limpa; interval: 6000; onTriggered: p.aviso = "" }

    function abrirApp(id) {
        if (aberto === id && !detalhe) return;
        aberto = id; detalhe = null;
        cmdDetalhe.rodar([cmd, "app", id, periodo === "hoje" ? "semana" : periodo]);
    }

    // ------------------------------------------------ formatos
    function tempo(s) {
        if (!s) return "0 min";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return h ? h + " h" + (m ? " " + m + " min" : "") : m + " min";
    }
    function bytes(b) {
        const u = ["B", "KB", "MB", "GB", "TB"]; let i = 0, v = b || 0;
        while (v >= 1000 && i < 4) { v /= 1000; i++; }
        return v.toFixed(v < 10 && i > 1 ? 1 : 0).replace(".", ",") + " " + u[i];
    }
    function reais(v) { return "R$ " + (v || 0).toFixed(2).replace(".", ","); }
    function kwh(wh) { return wh >= 1000 ? (wh / 1000).toFixed(2).replace(".", ",") + " kWh" : Math.round(wh || 0) + " Wh"; }
    function valor(a, m) {
        if (m === "foco_s" || m === "aberto_s") return tempo(a[m]);
        if (m === "cpu_s") return tempo(a[m]) + " de CPU";
        if (m === "escrito") return bytes(a.escrito) + " escritos · " + bytes(a.lido) + " lidos";
        if (m === "ram_pico") return bytes(a.ram_pico) + " no pico · " + bytes(a.ram_media) + " em média";
        return kwh(a.energia_wh) + " · " + reais(a.custo);
    }
    function diferenca(agora, antes) {
        if (!r || r.periodo === "tudo" || !antes) return "";
        const d = agora - antes;
        if (Math.abs(d) < 600) return "igual ao período anterior";
        return (d > 0 ? "+" : "−") + tempo(Math.abs(d)) + " que o período anterior";
    }
    function nome(a) {
        if (a.nome) return a.nome;
        const e = DesktopEntries.byId(a.id) || DesktopEntries.heuristicLookup(a.id);
        return e ? e.name : a.id;
    }

    // ------------------------------------------------ topo: período e estado da coleta
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: p.periodos
            delegate: Chip { required property var modelData; texto: modelData.nome; ativo: p.periodo === modelData.id; onClicado: p.periodo = modelData.id }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: !p.cfg ? "" : !p.cfg.ligado ? "Coleta desligada" : p.cfg.pausado_ate * 1000 > Date.now()
                  ? "Pausado até " + Qt.formatTime(new Date(p.cfg.pausado_ate * 1000), "HH:mm") : "Coletando"
            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
        }
        Botao {
            visible: p.cfg && p.cfg.ligado
            texto: p.cfg && p.cfg.pausado_ate * 1000 > Date.now() ? "Retomar" : "Pausar 1 h"
            onClicado: acao.rodar(p.cfg.pausado_ate * 1000 > Date.now() ? [p.cmd, "retomar"] : [p.cmd, "pausar", "60"], "")
        }
    }
    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
    }

    // ------------------------------------------------ números do período
    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        columns: width > 620 ? 3 : 1
        columnSpacing: 10
        rowSpacing: 10
        Bloco {
            rotulo: "Em foco no total"
            valor: p.r ? p.tempo(p.r.foco_total) : "—"
            detalhe: p.r ? p.diferenca(p.r.foco_total, p.r.foco_total_anterior) : ""
        }
        Bloco {
            rotulo: "Energia do PC (estimada)"
            valor: p.r ? p.kwh(p.r.energia.pc_wh) + " · " + p.reais(p.r.energia.custo) : "—"
            detalhe: p.r && p.r.periodo !== "tudo" ? "Período anterior: " + p.reais(p.r.energia.custo_anterior) : ""
        }
        Bloco {
            rotulo: "Apps e jogos usados"
            valor: p.r ? String(p.r.apps.filter(a => a.foco_s > 0).length) : "—"
            detalhe: p.r ? (p.r.dias_com_dados === 1 ? "1 dia com dados" : p.r.dias_com_dados + " dias com dados") : ""
        }
    }

    // Tempo em foco por dia
    ColumnLayout {
        readonly property var dias: p.r ? p.r.por_dia : []
        readonly property real teto: Math.max(1, ...dias.map(d => d.foco_s))
        visible: dias.length > 1
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 4
        Row {
            id: barrasDia
            Layout.fillWidth: true
            height: 54
            spacing: 3
            Repeater {
                model: parent.parent.dias
                delegate: Rectangle {
                    required property var modelData
                    width: Math.max(3, (barrasDia.width - 3 * (barrasDia.parent.dias.length - 1)) / barrasDia.parent.dias.length)
                    height: Math.max(2, 54 * modelData.foco_s / barrasDia.parent.teto)
                    anchors.bottom: parent.bottom
                    radius: 2
                    color: Tema.suave
                    opacity: 0.75
                }
            }
        }
        Text { text: "Tempo em foco por dia"; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4 }
    }

    // ------------------------------------------------ ranking de apps
    Text { Layout.topMargin: 14; text: "Apps"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: p.metricas
            delegate: Chip { required property var modelData; texto: modelData.nome; ativo: p.metrica === modelData.id; onClicado: p.metrica = modelData.id }
        }
    }
    Text {
        visible: p.r !== null && p.lista.length === 0
        text: p.cfg && !p.cfg.ligado ? "A coleta está desligada. Ligue em Privacidade, no fim da página." : "Ainda não há dados neste período. Os números aparecem alguns minutos depois de usar os apps."
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
    }
    Repeater {
        model: p.lista.slice(0, 15)
        delegate: ColumnLayout {
            id: linhaApp
            required property var modelData
            readonly property bool aberto: p.aberto === modelData.id
            Layout.fillWidth: true
            spacing: 4

            Item {
                Layout.fillWidth: true
                implicitHeight: linhaRanking.implicitHeight + 6
                RowLayout {
                    id: linhaRanking
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        Layout.preferredWidth: 140
                        text: p.nome(linhaApp.modelData)
                        elide: Text.ElideRight
                        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Tema.trilho
                        Rectangle {
                            width: parent.width * linhaApp.modelData[p.metrica] / p.maior
                            height: parent.height; radius: 3; color: Tema.suave
                            Behavior on width { NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva } }
                        }
                    }
                    Text {
                        Layout.preferredWidth: 190
                        horizontalAlignment: Text.AlignRight
                        text: p.valor(linhaApp.modelData, p.metrica)
                        elide: Text.ElideLeft
                        font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto2
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: linhaApp.aberto ? p.aberto = "" : p.abrirApp(linhaApp.modelData.id)
                }
            }

            // Detalhe: comparação, horas do dia e ações
            ColumnLayout {
                visible: linhaApp.aberto
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.bottomMargin: 8
                spacing: 6
                Text {
                    text: [p.diferenca(linhaApp.modelData.foco_s, linhaApp.modelData.anterior.foco_s),
                           "aberto " + p.tempo(linhaApp.modelData.aberto_s),
                           "RAM até " + p.bytes(linhaApp.modelData.ram_pico)].filter(x => x).join(" · ")
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                }
                Row {
                    id: horas
                    readonly property var dados: p.detalhe && p.detalhe.app === linhaApp.modelData.id ? p.detalhe.horas : []
                    readonly property real teto: Math.max(1, ...dados)
                    visible: dados.length === 24
                    height: 36
                    spacing: 3
                    Repeater {
                        model: horas.dados
                        delegate: Rectangle {
                            required property var modelData
                            width: 10
                            height: Math.max(2, 36 * modelData / horas.teto)
                            anchors.bottom: parent.bottom
                            radius: 2
                            color: Tema.texto4
                        }
                    }
                }
                Text {
                    visible: horas.visible
                    text: "Horas do dia em que mais usa (0 h → 23 h)"
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
                }
                RowLayout {
                    spacing: 8
                    Botao { texto: "Não contar este app"; onClicado: acao.rodar([p.cmd, "excluir", linhaApp.modelData.id], "Esse app não será mais contado.") }
                    Botao { texto: "Apagar o histórico dele"; perigo: true; onClicado: { acao.rodar([p.cmd, "apagar", linhaApp.modelData.id], "Histórico apagado."); p.aberto = ""; } }
                }
            }
        }
    }

    // ------------------------------------------------ jogos
    Text {
        visible: p.jogos.length > 0
        Layout.topMargin: 14
        text: "Jogos"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Repeater {
        model: p.jogos
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Text { Layout.fillWidth: true; text: p.nome(modelData); elide: Text.ElideRight; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text {
                text: p.tempo(modelData.foco_s) + "  ·  " + p.reais(modelData.custo) + " de energia"
                font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto2
            }
        }
    }

    // ------------------------------------------------ energia
    Text {
        Layout.topMargin: 18
        text: "Energia"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Estimativa: processador e placa de vídeo pelos sensores, mais o resto do PC e a perda da fonte. Um medidor de tomada daria o valor exato."
              + (p.r && !p.r.energia.medido_cpu ? " O processador está sendo estimado pelo uso (o sensor dele não está liberado)." : "")
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
    }
    Campo {
        id: tarifa
        Layout.preferredWidth: 220
        rotulo: "Tarifa (R$ por kWh, Enter salva)"
        text: p.cfg ? String(p.cfg.tarifa).replace(".", ",") : ""
        validador: /^\d+([,.]\d+)?$/
        onConfirmado: if (aceito) acao.rodar([p.cmd, "tarifa", text, p.cfg ? p.cfg.bandeira : "verde"], "Tarifa salva.")
    }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: [{ id: "verde", nome: "Bandeira verde" }, { id: "amarela", nome: "Amarela" }, { id: "vermelha1", nome: "Vermelha 1" }, { id: "vermelha2", nome: "Vermelha 2" }]
            delegate: Chip {
                required property var modelData
                texto: modelData.nome
                ativo: p.cfg && p.cfg.bandeira === modelData.id
                onClicado: if (tarifa.aceito) acao.rodar([p.cmd, "tarifa", tarifa.text, modelData.id], "Tarifa salva.")
            }
        }
    }
    RowLayout {
        visible: p.cfg && p.cfg.tem_rapl && !p.cfg.rapl
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "Para medir o processador de verdade, libere o sensor de energia dele. O Linux o deixa fechado por precaução (um ataque raro consegue deduzir o que o processador faz pelo consumo); num PC pessoal o risco é pequeno."
            font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
        }
        Botao { texto: "Liberar o sensor"; onClicado: acao.rodar([p.cmd, "energia", "liberar"], "Sensor liberado: a partir de agora o processador é medido.") }
    }

    // ------------------------------------------------ privacidade
    Text {
        Layout.topMargin: 18
        text: "Privacidade"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: "Coletar estatísticas"; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Desligada, o coletor não roda e não ocupa memória."; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
        }
        Interruptor {
            ligado: p.cfg ? p.cfg.ligado : true
            onAlternado: acao.rodar([p.cmd, p.cfg && p.cfg.ligado ? "desligar" : "ligar"], "")
        }
    }
    Repeater {
        model: p.cfg ? p.cfg.excluidos : []
        delegate: RowLayout {
            required property string modelData
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "Não contado: " + p.nome({ id: modelData, nome: "" }); font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2 }
            Botao { texto: "Voltar a contar"; onClicado: acao.rodar([p.cmd, "incluir", modelData], "") }
        }
    }
    RowLayout {
        spacing: 8
        Botao { texto: "Exportar (CSV)"; onClicado: acao.rodar([p.cmd, "exportar"], "Exportado para %s") }
        Botao { visible: !p.confirmarApagar; texto: "Apagar tudo"; perigo: true; onClicado: p.confirmarApagar = true }
        Botao { visible: p.confirmarApagar; texto: "Confirmar: apagar todo o histórico"; perigo: true; onClicado: { acao.rodar([p.cmd, "apagar"], "Histórico apagado."); p.confirmarApagar = false; } }
    }

    // ------------------------------------------------ componentes
    component Chip: Rectangle {
        property string texto: ""
        property bool ativo: false
        signal clicado()
        implicitWidth: rotuloChip.implicitWidth + 20
        implicitHeight: 26
        radius: 13
        color: ativo ? Tema.selecionado : areaChip.containsMouse ? Tema.hover : "transparent"
        border.width: 1
        border.color: ativo ? Tema.bordaPainel : Tema.borda
        Text { id: rotuloChip; anchors.centerIn: parent; text: parent.texto; font.family: Tema.fonte; font.pixelSize: 12; color: parent.ativo ? Tema.texto : Tema.texto2 }
        MouseArea { id: areaChip; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicado() }
    }
    component Bloco: Rectangle {
        property string rotulo: ""
        property string valor: ""
        property string detalhe: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 78
        radius: Tema.raio
        color: Tema.elevado
        border.width: 1
        border.color: Tema.borda
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 3
            Text { text: parent.parent.rotulo; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
            Text { text: parent.parent.valor; font.family: Tema.fonte; font.pixelSize: 17; font.weight: Font.Medium; color: Tema.texto }
            Text { Layout.fillWidth: true; text: parent.parent.detalhe; elide: Text.ElideRight; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
        }
    }
}
