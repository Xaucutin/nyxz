import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Congelar apps em segundo plano (ideia 33). Apps escolhidos param de rodar depois de
// alguns minutos sem uso ou durante jogos, e voltam na hora quando você clica neles.
// Por baixo: /usr/libexec/nyxz/congelar (freezer do cgroup) + Congelar.qml no shell.
Pagina {
    id: p
    titulo: "Congelar apps"
    descricao: "Apps que você escolher são pausados quando ficam um tempo sem uso ou durante um jogo: param de gastar processador e parte da memória deles vai para a memória comprimida. Voltam na hora quando você clica neles."

    readonly property string cmd: "/usr/libexec/nyxz/congelar"
    property var e: null
    property string aviso: ""
    property bool avisoErro: false

    function atualizar() { cmdEstado.rodar([cmd, "estado"]); }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    Component.onCompleted: atualizar()
    Timer { interval: 5000; running: true; repeat: true; onTriggered: p.atualizar() }
    Timer { id: limpa; interval: 7000; onTriggered: p.aviso = "" }

    function tam(b) { return b >= 1e9 ? (b / 1e9).toFixed(1).replace(".", ",") + " GB" : Math.round(b / 1e6) + " MB"; }

    Comando { id: cmdEstado; onPronto: s => { try { p.e = JSON.parse(s); } catch (x) {} } }
    Process {
        id: salvar
        stdinEnabled: true
        command: [p.cmd, "configurar"]
        stderr: StdioCollector { id: erroSalvar }
        onExited: codigo => { if (codigo !== 0) p.avisar(erroSalvar.text.trim() || "Não deu para salvar.", true); p.atualizar(); }
    }
    function gravar(mudanca) {
        if (!p.e || salvar.running) return;
        const c = { ligado: p.e.ligado, minutos: p.e.minutos, noJogo: p.e.noJogo, apps: p.e.apps };
        Object.assign(c, mudanca);
        p.e = Object.assign({}, p.e, mudanca);
        salvar.running = true;
        salvar.write(JSON.stringify(c));
        salvar.closeStdin();
    }
    function alternarApp(nome) {
        const lista = (p.e.apps || []).slice();
        const i = lista.indexOf(nome);
        if (i >= 0) lista.splice(i, 1); else lista.push(nome);
        gravar({ apps: lista });
    }
    Process {
        id: acao
        property string ok: ""
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => { p.avisar(codigo === 0 ? acao.ok : (erroAcao.text.trim() || "Não deu certo."), codigo !== 0); p.atualizar(); }
        function rodar(c, msg) { if (running) return; ok = msg; command = c; running = true; }
    }

    // ------------------------------------------------ ajustes
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: "Congelar apps em segundo plano"; font.family: Tema.fonte; font.pixelSize: 14; color: Tema.texto }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: p.e && p.e.ligado && !p.e.apps.length ? "Ligado, mas nenhum app escolhido ainda: marque abaixo quais podem ser congelados." : "Desligado por padrão. Só os apps que você marcar são congelados."
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
            }
        }
        Interruptor { ligado: p.e ? p.e.ligado : false; onAlternado: v => p.gravar({ ligado: v }) }
    }
    RowLayout {
        visible: p.e && p.e.ligado
        Layout.fillWidth: true
        spacing: 12
        Campo {
            id: minutos
            Layout.preferredWidth: 220
            rotulo: "Congelar depois de (minutos sem uso)"
            Component.onCompleted: text = "15"
            onConfirmado: p.gravar({ minutos: parseInt(text) || 15 })
        }
        Botao { Layout.alignment: Qt.AlignBottom; texto: "Salvar"; ativo: (parseInt(minutos.text) || 0) > 0; onClicado: { p.gravar({ minutos: parseInt(minutos.text) || 15 }); p.avisar("Salvo.", false); } }
        Item { Layout.fillWidth: true }
    }
    Connections {
        target: p
        function onEChanged() { if (p.e && !minutos.activeFocus) minutos.text = String(p.e.minutos); }
    }
    RowLayout {
        visible: p.e && p.e.ligado
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { Layout.fillWidth: true; text: "Congelar na hora quando um jogo abrir"; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text { text: "E soltar quando ele fechar."; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        }
        Interruptor { ligado: p.e ? p.e.noJogo : true; onAlternado: v => p.gravar({ noJogo: v }) }
    }

    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }

    // ------------------------------------------------ apps abertos
    Text { Layout.topMargin: 12; text: "Apps abertos"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Repeater {
        model: p.e ? p.e.abertos.filter(a => a.bloqueio !== "faz parte do sistema") : []
        delegate: RowLayout {
            id: linha
            required property var modelData
            readonly property var a: modelData
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.preferredWidth: 18
                text: linha.a.congelado ? "❄" : ""
                font.pixelSize: 14; color: "#9FC3E6"
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { Layout.fillWidth: true; text: linha.a.nome; elide: Text.ElideRight; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: p.tam(linha.a.ram) + "  ·  " + (
                        linha.a.congelado ? "congelado" + (linha.a.liberado >= 1e6 ? ", liberou " + p.tam(linha.a.liberado) : "") + ". Clique na janela para voltar."
                        : linha.a.som ? "tocando som ou transmitindo: não congela agora"
                        : linha.a.bloqueio ? linha.a.bloqueio + ": só congela se você marcar"
                        : linha.a.semUsoMin !== null ? "sem uso há " + linha.a.semUsoMin + " min" : "em uso")
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                }
            }
            // Marcar: pode ser congelado sozinho
            Rectangle {
                implicitWidth: rotuloMarca.implicitWidth + 20
                implicitHeight: 26
                radius: 13
                color: linha.a.escolhido ? Tema.selecionado : areaMarca.containsMouse ? Tema.hover : "transparent"
                border.width: 1
                border.color: linha.a.escolhido ? Tema.bordaPainel : Tema.borda
                Text {
                    id: rotuloMarca
                    anchors.centerIn: parent
                    text: linha.a.escolhido ? "Congela sozinho" : "Pode congelar"
                    font.family: Tema.fonte; font.pixelSize: 12; color: linha.a.escolhido ? Tema.texto : Tema.texto2
                }
                MouseArea { id: areaMarca; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: p.alternarApp(linha.a.nome) }
            }
            Botao {
                texto: linha.a.congelado ? "Descongelar" : "Congelar agora"
                ativo: !acao.running && (linha.a.congelado || !linha.a.som)
                onClicado: acao.rodar([p.cmd, linha.a.congelado ? "soltar" : "agora", linha.a.nome],
                                      linha.a.congelado ? linha.a.nome + " voltou." : linha.a.nome + " congelado.")
            }
        }
    }

    // Escolhidos que não estão abertos
    Text {
        readonly property var fechados: p.e ? p.e.apps.filter(n => !p.e.abertos.some(a => a.nome === n)) : []
        visible: fechados.length > 0
        Layout.topMargin: 12
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Também marcados (fechados agora): " + fechados.join(", ")
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
    }
    Text {
        Layout.topMargin: 12
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Nunca são congelados: o app em uso, quem está tocando som, gravando ou transmitindo e, a não ser que você marque, apps que precisam de rede o tempo todo (Discord, Steam, chamadas, torrents)."
        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
    }
}
