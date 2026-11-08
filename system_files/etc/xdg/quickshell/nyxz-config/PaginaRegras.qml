import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Regras de janela sem editar arquivo (ideia 26): por app, em qual área de trabalho
// abre, se flutua, tela cheia, centralizada e opacidade.
// - ~/.config/nyxz/regras.json: as regras (lidas por esta tela);
// - ~/.config/hypr/nyxz/regras.lua: gerado aqui para o Hyprland.
Pagina {
    id: p
    titulo: "Regras de janela"
    descricao: "Escolha como cada app abre: em qual área de trabalho, solto (flutuante), em tela cheia, centralizado ou com transparência."

    property var abertas: []

    FileView {
        id: arquivo
        path: Quickshell.env("HOME") + "/.config/nyxz/regras.json"
        printErrors: false
        onAdapterUpdated: { writeAdapter(); p.gerarLua(); }
        JsonAdapter {
            id: cfg
            property var regras: []   // [{ classe, nome, area, flutuar, telaCheia, centralizar, opacidade }]
        }
    }
    FileView {
        id: lua
        path: Quickshell.env("HOME") + "/.config/hypr/nyxz/regras.lua"
        printErrors: false
    }
    Timer { id: recarregar; interval: 300; onTriggered: Quickshell.execDetached(["hyprctl", "reload"]) }

    // Janelas abertas agora (para criar regra a partir delas)
    Comando {
        id: clientes
        onPronto: saida => {
            try {
                const vistos = {};
                p.abertas = JSON.parse(saida)
                    .filter(c => c.class && !vistos[c.class] && (vistos[c.class] = true))
                    .map(c => ({ classe: c["class"], titulo: c.title }));
            } catch (e) { p.abertas = []; }
        }
        Component.onCompleted: rodar(["hyprctl", "clients", "-j"])
    }

    // Escapa para expressão regular. Vai numa string longa do Lua ([=[ … ]=]), que não
    // interpreta "\" — numa string comum, "\." seria erro e o arquivo inteiro cairia.
    function escapar(t) { return t.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/\]=\]/g, ""); }

    function gerarLua() {
        let t = "-- Gerado por Configurações → Regras de janela. Não edite: mude pela tela.\n" +
                "-- Cada efeito fica isolado: se um não existir nesta versão do Hyprland, os outros valem.\n" +
                "local function regra(r) pcall(hl.window_rule, r) end\n";
        cfg.regras.forEach((r, i) => {
            const base = 'name = "nyxz-regra-' + i + '-%s", match = { class = [=[^(' + escapar(r.classe) + ')$]=] }';
            const efeito = (nome, valor) => { t += "regra({ " + base.replace("%s", nome) + ", " + nome + " = " + valor + " })\n"; };
            if (r.area > 0) efeito("workspace", '"' + r.area + '"');
            if (r.flutuar) efeito("float", "true");
            if (r.flutuar && r.centralizar) efeito("center", "true");
            if (r.telaCheia) efeito("fullscreen", "true");
            if (r.opacidade < 100) efeito("opacity", '"' + (r.opacidade / 100).toFixed(2) + '"');
        });
        lua.setText(t);
        recarregar.restart();
    }

    function adicionar(classe) {
        if (cfg.regras.some(r => r.classe === classe)) return;
        const lista = cfg.regras.slice();
        lista.push({ classe: classe, area: 0, flutuar: false, telaCheia: false, centralizar: true, opacidade: 100 });
        cfg.regras = lista;
    }
    function mudar(i, chave, valor) {
        const lista = cfg.regras.slice();
        const r = Object.assign({}, lista[i]);
        r[chave] = valor;
        lista[i] = r;
        cfg.regras = lista;
    }
    function remover(i) {
        const lista = cfg.regras.slice();
        lista.splice(i, 1);
        cfg.regras = lista;
    }

    // ---------------------------------------------- regras existentes
    Text {
        visible: cfg.regras.length === 0
        text: "Nenhuma regra ainda. Crie uma a partir das janelas abertas, logo abaixo."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
    }

    Repeater {
        model: cfg.regras
        delegate: Rectangle {
            id: cartao
            required property var modelData
            required property int index
            Layout.fillWidth: true
            Layout.preferredHeight: corpo.implicitHeight + 24
            radius: 8
            color: Tema.elevado
            border.width: 1
            border.color: Tema.borda

            ColumnLayout {
                id: corpo
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: cartao.modelData.classe
                        elide: Text.ElideRight
                        font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto
                    }
                    Botao { texto: "Remover"; onClicado: p.remover(cartao.index) }
                }

                RowLayout {
                    spacing: 8
                    Text { Layout.preferredWidth: 130; text: "Área de trabalho"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
                    Repeater {
                        model: [0, 1, 2, 3, 4, 5]
                        delegate: Botao {
                            required property int modelData
                            texto: modelData === 0 ? "Qualquer" : String(modelData)
                            principal: cartao.modelData.area === modelData
                            onClicado: p.mudar(cartao.index, "area", modelData)
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 18
                    Repeater {
                        model: [
                            { chave: "flutuar", nome: "Flutuante" },
                            { chave: "centralizar", nome: "Centralizada" },
                            { chave: "telaCheia", nome: "Tela cheia" }
                        ]
                        delegate: Row {
                            required property var modelData
                            spacing: 8
                            visible: modelData.chave !== "centralizar" || cartao.modelData.flutuar
                            Interruptor {
                                anchors.verticalCenter: parent.verticalCenter
                                ligado: cartao.modelData[modelData.chave] === true
                                onAlternado: v => p.mudar(cartao.index, modelData.chave, v)
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.nome
                                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.suave
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 8
                    Text { Layout.preferredWidth: 130; text: "Opacidade"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
                    Repeater {
                        model: [100, 95, 90, 80]
                        delegate: Botao {
                            required property int modelData
                            texto: modelData + "%"
                            principal: cartao.modelData.opacidade === modelData
                            onClicado: p.mudar(cartao.index, "opacidade", modelData)
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------- janelas abertas
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 14
        Text {
            Layout.fillWidth: true
            text: "Criar regra a partir de uma janela aberta"
            font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
        }
        Botao { texto: "Atualizar lista"; onClicado: clientes.rodar(["hyprctl", "clients", "-j"]) }
    }
    Repeater {
        model: p.abertas
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 12
            Column {
                Layout.fillWidth: true
                Text {
                    width: parent.width
                    text: modelData.classe
                    elide: Text.ElideRight
                    font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.suave
                }
                Text {
                    width: parent.width
                    text: modelData.titulo
                    elide: Text.ElideRight
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                }
            }
            Botao {
                texto: cfg.regras.some(r => r.classe === modelData.classe) ? "Já tem regra" : "Criar regra"
                ativo: !cfg.regras.some(r => r.classe === modelData.classe)
                onClicado: p.adicionar(modelData.classe)
            }
        }
    }
}
