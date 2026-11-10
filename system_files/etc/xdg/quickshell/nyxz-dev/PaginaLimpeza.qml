import QtQuick
import QtQuick.Layouts
import Quickshell

// Limpeza de disco para dev (ideia 18): node_modules de projetos parados, caches de
// pacotes, imagens do Podman sem uso, cache de shaders da Steam, Flatpaks órfãos e
// lixeira. Mostra quanto cada item libera e só apaga o que for marcado.
Pagina {
    id: p
    titulo: "Limpeza"
    descricao: "O que dá para apagar sem perder trabalho: tudo aqui é baixado ou gerado de novo quando precisar. Marque o que quiser e confirme. Os bancos do Dev Hub nunca entram."

    readonly property string cmd: "/usr/libexec/nyxz/nyxz-dev"
    property var itens: []
    property var marcados: ({})
    property int dias: 30
    property bool analisando: false
    property bool confirmando: false
    property string resultado: ""

    function analisar() {
        analisando = true;
        resultado = "";
        marcados = {};
        ler.rodar([cmd, "limpeza", "analisar", String(dias)]);
    }
    Component.onCompleted: analisar()

    function legivel(b) {
        if (b < 0) return "?";
        const u = ["B", "KB", "MB", "GB"];
        let i = 0, v = b;
        while (v >= 1024 && i < u.length - 1) { v /= 1024; i++; }
        return (i >= 2 ? v.toFixed(1).replace(".", ",") : Math.round(v)) + " " + u[i];
    }
    readonly property var escolhidos: itens.filter(i => marcados[i.id])
    readonly property real totalEscolhido: escolhidos.reduce((t, i) => t + Math.max(0, i.bytes), 0)

    Comando {
        id: ler
        onPronto: s => {
            p.analisando = false;
            try { p.itens = JSON.parse(s).itens; } catch (e) { p.itens = []; }
        }
    }
    Comando {
        id: apagar
        onPronto: s => {
            try { p.resultado = "Liberado: " + p.legivel(JSON.parse(s).liberado) + "."; } catch (e) { p.resultado = "Limpeza feita."; }
            p.confirmando = false;
            p.analisar();
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text { text: "Projetos parados há"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        Repeater {
            model: [7, 30, 90]
            delegate: Botao {
                required property int modelData
                texto: modelData + " dias"
                principal: p.dias === modelData
                onClicado: { p.dias = modelData; p.analisar(); }
            }
        }
        Item { Layout.fillWidth: true }
        Botao { texto: p.analisando ? "Analisando…" : "Analisar de novo"; ativo: !p.analisando; onClicado: p.analisar() }
    }

    Text {
        visible: p.resultado !== ""
        text: p.resultado
        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.ok
    }
    Text {
        visible: !p.analisando && p.itens.length === 0
        text: "Nada para limpar agora."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
    }

    Repeater {
        model: p.itens
        delegate: ColumnLayout {
            id: linha
            required property var modelData
            required property int index
            readonly property bool novoGrupo: index === 0 || p.itens[index - 1].grupo !== modelData.grupo
            Layout.fillWidth: true
            spacing: 2
            Text {
                visible: linha.novoGrupo
                Layout.topMargin: linha.index === 0 ? 4 : 12
                text: linha.modelData.grupo
                font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 6
                color: area.containsMouse ? Tema.hover : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10
                    // Caixa de marcar
                    Rectangle {
                        width: 16; height: 16; radius: 4
                        color: p.marcados[linha.modelData.id] ? Tema.suave : "transparent"
                        border.width: 1
                        border.color: p.marcados[linha.modelData.id] ? Tema.suave : Tema.texto4
                        Text {
                            anchors.centerIn: parent
                            visible: !!p.marcados[linha.modelData.id]
                            text: "✓"
                            font.pixelSize: 11
                            color: Tema.fundo
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: linha.modelData.nome
                        elide: Text.ElideMiddle
                        font.family: linha.modelData.id.indexOf("pasta:") === 0 && linha.modelData.grupo.indexOf("node_modules") === 0 ? Tema.fonteMono : Tema.fonte
                        font.pixelSize: 12; color: Tema.suave
                    }
                    Text {
                        text: p.legivel(linha.modelData.bytes)
                        font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto2
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const m = Object.assign({}, p.marcados);
                        m[linha.modelData.id] = !m[linha.modelData.id];
                        p.marcados = m;
                        p.confirmando = false;
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        spacing: 8
        Text {
            Layout.fillWidth: true
            text: p.escolhidos.length ? "Selecionado: " + p.legivel(p.totalEscolhido) : "Marque o que quer apagar."
            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
        }
        Botao {
            visible: !p.confirmando
            texto: "Apagar selecionados"
            ativo: p.escolhidos.length > 0 && !apagar.running
            onClicado: p.confirmando = true
        }
        Botao {
            visible: p.confirmando
            texto: "Confirmar: apagar " + p.legivel(p.totalEscolhido)
            perigo: true
            onClicado: apagar.rodar([p.cmd, "limpeza", "apagar"].concat(p.escolhidos.map(i => i.id)))
        }
        Botao { visible: p.confirmando; texto: "Cancelar"; onClicado: p.confirmando = false }
    }
}
