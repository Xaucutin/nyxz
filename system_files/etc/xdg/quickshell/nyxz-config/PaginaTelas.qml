import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Telas: resolução, taxa de atualização (Hz) e escala de cada monitor.
// Grava ~/.config/hypr/nyxz/telas.lua e pede para o Hyprland recarregar.
// Depois de aplicar, volta sozinho em 15 s se você não confirmar (como no Windows).
Pagina {
    id: p
    titulo: "Telas"
    descricao: "Resolução, taxa de atualização e escala. Depois de aplicar, você tem 15 segundos para confirmar; se não confirmar, volta como estava."

    readonly property string arquivo: Quickshell.env("HOME") + "/.config/hypr/nyxz/telas.lua"
    property var monitores: []
    property var escolhas: ({})     // nome do monitor -> { resolucao, hz, escala }
    property string anterior: ""
    property int contagem: 0

    Comando {
        id: lerMonitores
        onPronto: saida => {
            try {
                const lista = JSON.parse(saida);
                const esc = {};
                for (const m of lista)
                    esc[m.name] = { resolucao: m.width + "x" + m.height, hz: Math.round(m.refreshRate), escala: m.scale };
                p.escolhas = esc;
                p.monitores = lista;
            } catch (e) {}
        }
    }
    Component.onCompleted: lerMonitores.rodar(["hyprctl", "monitors", "all", "-j"])

    FileView {
        id: arq
        path: p.arquivo
        printErrors: false
        onLoaded: p.anterior = text()
        onLoadFailed: p.anterior = ""
    }

    function modosDe(m) {
        const mapa = {};
        for (const modo of (m.availableModes || [])) {
            const r = /^(\d+)x(\d+)@([\d.]+)/.exec(modo);
            if (!r) continue;
            const res = r[1] + "x" + r[2];
            (mapa[res] = mapa[res] || []).push(Math.round(parseFloat(r[3])));
        }
        return mapa;
    }

    function escolher(nome, campo, valor) {
        const e = Object.assign({}, p.escolhas);
        e[nome] = Object.assign({}, e[nome]);
        e[nome][campo] = valor;
        p.escolhas = e;
    }

    function gerar() {
        let s = "-- Gerado por Configurações → Telas. Para mudanças manuais, use ~/.config/hypr/user.lua.\n";
        for (const m of p.monitores) {
            const e = p.escolhas[m.name];
            s += 'hl.monitor({ output = "' + m.name + '", mode = "' + e.resolucao + "@" + e.hz +
                 '", position = "auto", scale = ' + e.escala + " })\n";
        }
        return s;
    }

    function aplicar(conteudo) {
        arq.setText(conteudo);
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    Timer {
        id: voltar
        interval: 1000
        repeat: true
        onTriggered: {
            p.contagem -= 1;
            if (p.contagem <= 0) {
                stop();
                p.aplicar(p.anterior);
                lerMonitores.rodar(["hyprctl", "monitors", "all", "-j"]);
            }
        }
    }

    Repeater {
        model: p.monitores
        delegate: ColumnLayout {
            id: mon
            required property var modelData
            readonly property var modos: p.modosDe(modelData)
            readonly property var escolha: p.escolhas[modelData.name] || {}
            Layout.fillWidth: true
            Layout.bottomMargin: 18
            spacing: 8

            Text {
                text: [((mon.modelData.make || "") + " " + (mon.modelData.model || "")).trim() || mon.modelData.description || "Monitor",
                       mon.modelData.name].filter(s => s).join("  ·  ")
                font.family: Tema.fonte
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Tema.texto
            }

            Text { text: "Resolução"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Object.keys(mon.modos).sort((a, b) => parseInt(b) - parseInt(a))
                    delegate: Escolha {
                        required property var modelData
                        texto: modelData
                        marcado: mon.escolha.resolucao === modelData
                        onClicado: {
                            p.escolher(mon.modelData.name, "resolucao", modelData);
                            p.escolher(mon.modelData.name, "hz", Math.max(...mon.modos[modelData]));
                        }
                    }
                }
            }

            Text { text: "Taxa de atualização"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [...new Set(mon.modos[mon.escolha.resolucao] || [])].sort((a, b) => b - a)
                    delegate: Escolha {
                        required property var modelData
                        texto: modelData + " Hz"
                        marcado: mon.escolha.hz === modelData
                        onClicado: p.escolher(mon.modelData.name, "hz", modelData)
                    }
                }
            }

            Text { text: "Escala"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [1, 1.25, 1.5, 2]
                    delegate: Escolha {
                        required property var modelData
                        texto: Math.round(modelData * 100) + "%"
                        marcado: Math.abs(mon.escolha.escala - modelData) < 0.01
                        onClicado: p.escolher(mon.modelData.name, "escala", modelData)
                    }
                }
            }
        }
    }

    RowLayout {
        spacing: 8
        visible: !voltar.running
        Botao {
            texto: "Aplicar"
            principal: true
            ativo: p.monitores.length > 0
            onClicado: {
                p.aplicar(p.gerar());
                p.contagem = 15;
                voltar.start();
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: confirmar.implicitHeight + 28
        visible: voltar.running
        radius: Tema.raio
        color: Tema.painel
        border.color: Tema.bordaPainel
        ColumnLayout {
            id: confirmar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 8
            Text {
                text: "Manter estas configurações? Voltando em " + p.contagem + " s."
                font.family: Tema.fonte
                font.pixelSize: 13
                color: Tema.texto
            }
            RowLayout {
                spacing: 8
                Botao {
                    texto: "Manter"
                    principal: true
                    onClicado: { voltar.stop(); p.anterior = p.gerar(); }
                }
                Botao {
                    texto: "Voltar como estava"
                    onClicado: { p.contagem = 0; voltar.triggered(); }
                }
            }
        }
    }

    component Escolha: Rectangle {
        id: esc
        property string texto: ""
        property bool marcado: false
        signal clicado()
        width: rot.implicitWidth + 22
        height: 30
        radius: 6
        color: marcado ? Tema.selecionado : areaEsc.containsMouse ? Tema.elevado : "transparent"
        border.color: marcado ? "#3A3A44" : Tema.borda
        Text {
            id: rot
            anchors.centerIn: parent
            text: esc.texto
            font.family: Tema.fonteMono
            font.pixelSize: 12
            color: esc.marcado ? Tema.texto : Tema.texto2
        }
        MouseArea {
            id: areaEsc
            anchors.fill: parent
            hoverEnabled: true
            onClicked: esc.clicado()
        }
    }
}
