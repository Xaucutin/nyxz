//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Biblioteca de jogos da Nyxz (ideia 28): Steam, Epic e GOG (Heroic), Minecraft (Prism),
// Roblox (Sober), Bottles e jogos avulsos num lugar só. App separado: 0 MB fechado.
// Os dados vêm de /usr/libexec/nyxz/jogos, que lê os arquivos das próprias lojas.
ShellRoot {
    id: raiz

    readonly property string cmd: "/usr/libexec/nyxz/jogos"
    property var jogos: []
    property var fontes: ({})
    property bool carregado: false
    property string filtro: "todos"
    property string ordem: "recentes"
    property string busca: ""
    property string abrindo: ""
    property var menuJogo: null      // jogo com o menu do botão direito aberto
    property string dialogo: ""      // "", "adicionar" ou "capa"

    readonly property var origens: ({
        steam: "Steam", epic: "Epic", gog: "GOG", minecraft: "Minecraft",
        roblox: "Roblox", bottles: "Bottles", avulso: "Avulso"
    })
    // Filtros: só aparecem as origens que têm jogos
    readonly property var filtros: {
        const f = [{ id: "todos", nome: "Todos" }];
        for (const o of Object.keys(origens))
            if (jogos.some(j => j.origem === o && !j.oculto)) f.push({ id: o, nome: origens[o] });
        if (jogos.some(j => j.oculto)) f.push({ id: "ocultos", nome: "Ocultos" });
        return f;
    }
    readonly property var visiveis: {
        const b = busca.trim().toLowerCase();
        let l = jogos.filter(j => (filtro === "ocultos" ? j.oculto : !j.oculto)
            && (filtro === "todos" || filtro === "ocultos" || j.origem === filtro)
            && (!b || j.nome.toLowerCase().indexOf(b) >= 0));
        if (ordem === "nome") l.sort((a, c) => a.nome.localeCompare(c.nome));
        else if (ordem === "horas") l.sort((a, c) => c.minutos - a.minutos || a.nome.localeCompare(c.nome));
        else l.sort((a, c) => c.ultima - a.ultima || a.nome.localeCompare(c.nome));
        return l;
    }

    function atualizar() { listar.rodar([cmd, "listar"]); }
    Component.onCompleted: atualizar()

    function jogar(j) {
        abrindo = j.id;
        Quickshell.execDetached([cmd, "jogar", j.id]);
        fechar.restart();   // o jogo assume; a biblioteca sai da memória
    }
    Timer { id: fechar; interval: 1800; onTriggered: Qt.quit() }

    function tempo(m) {
        if (!m) return "";
        if (m < 60) return m + " min";
        const h = Math.round(m / 6) / 10;
        return (h % 1 === 0 ? h.toFixed(0) : h.toFixed(1).replace(".", ",")) + " h";
    }
    function quando(t) {
        if (!t) return "Nunca jogado";
        const dias = Math.floor((Date.now() / 1000 - t) / 86400);
        if (dias <= 0) return "Hoje";
        if (dias === 1) return "Ontem";
        if (dias < 30) return "Há " + dias + " dias";
        return Qt.formatDate(new Date(t * 1000), "dd/MM/yyyy");
    }
    function capa(c) {
        if (!c) return "";
        return c.indexOf("http") === 0 ? c : "file://" + c;
    }

    Comando {
        id: listar
        onPronto: s => {
            try {
                const d = JSON.parse(s);
                raiz.jogos = d.jogos;
                raiz.fontes = d.fontes;
            } catch (e) { raiz.jogos = []; }
            raiz.carregado = true;
            if (!raiz.filtros.some(f => f.id === raiz.filtro)) raiz.filtro = "todos";
        }
    }
    Comando { id: acao; onPronto: raiz.atualizar() }
    Process {
        id: adicionar
        stdinEnabled: true
        command: [raiz.cmd, "adicionar"]
        onRunningChanged: if (!running) raiz.atualizar()
    }

    // Atualizar a lista de fora: qs -c nyxz-jogos ipc call jogos atualizar
    IpcHandler {
        target: "jogos"
        function atualizar(): void { raiz.atualizar(); }
    }

    FloatingWindow {
        id: janela
        title: "Jogos"
        readonly property var tela: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        implicitWidth: tela ? Math.min(1120, tela.width - 60) : 1120
        implicitHeight: tela ? Math.min(720, tela.height - 100) : 720
        color: Tema.fundo
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()

        Shortcut {
            sequence: "Esc"
            onActivated: {
                if (raiz.dialogo !== "") raiz.dialogo = "";
                else if (raiz.menuJogo) raiz.menuJogo = null;
                else Qt.quit();
            }
        }
        Shortcut { sequence: "Ctrl+F"; onActivated: campoBusca.forceActiveFocus() }
        Shortcut { sequence: "F5"; onActivated: raiz.atualizar() }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16

            // ------------------------------------------------ topo
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Image {
                    source: "icones/controle.svg"
                    sourceSize: Qt.size(22, 22)
                }
                Text {
                    text: "Jogos"
                    font.family: Tema.fonte; font.pixelSize: 18; font.weight: Font.DemiBold; color: Tema.texto
                }
                Text {
                    visible: raiz.carregado
                    text: raiz.jogos.filter(j => !j.oculto).length + (raiz.jogos.length === 1 ? " jogo" : " jogos")
                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 34
                    radius: Tema.raio
                    color: Tema.elevado
                    border.width: 1
                    border.color: campoBusca.activeFocus ? Tema.texto4 : Tema.borda
                    Image {
                        id: lupa
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        source: "icones/busca.svg"
                        sourceSize: Qt.size(14, 14)
                        opacity: 0.6
                    }
                    TextInput {
                        id: campoBusca
                        anchors.fill: parent
                        anchors.leftMargin: 32
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                        clip: true
                        focus: true
                        onTextChanged: raiz.busca = text
                        // Enter abre o primeiro jogo da lista
                        Keys.onReturnPressed: if (raiz.visiveis.length) raiz.jogar(raiz.visiveis[0])
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: campoBusca.text.length === 0
                            text: "Procurar jogo"
                            font: campoBusca.font
                            color: Tema.texto4
                        }
                    }
                }
                Botao { texto: "Adicionar jogo"; onClicado: raiz.dialogo = "adicionar" }
            }

            // ------------------------------------------------ filtros e ordem
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: raiz.jogos.length > 0
                Repeater {
                    model: raiz.filtros
                    delegate: Chip {
                        required property var modelData
                        texto: modelData.nome
                        ativo: raiz.filtro === modelData.id
                        onClicado: raiz.filtro = modelData.id
                    }
                }
                Item { Layout.fillWidth: true }
                Text { text: "Ordenar"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
                Repeater {
                    model: [{ id: "recentes", nome: "Recentes" }, { id: "nome", nome: "Nome" }, { id: "horas", nome: "Mais jogados" }]
                    delegate: Chip {
                        required property var modelData
                        texto: modelData.nome
                        ativo: raiz.ordem === modelData.id
                        onClicado: raiz.ordem = modelData.id
                    }
                }
            }

            // ------------------------------------------------ grade
            GridView {
                id: grade
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: raiz.visiveis.length > 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                // Colunas que cabem com cartões de 150 a 190 px
                readonly property int colunas: Math.max(2, Math.floor(width / 170))
                cellWidth: Math.floor(width / colunas)
                cellHeight: (cellWidth - 14) * 1.5 + 60
                model: raiz.visiveis
                // Cartão de cada jogo (não é componente à parte: precisa ver raiz e menu)
                delegate: Item {
                    id: cartao
                    required property var modelData
                    readonly property var jogo: modelData
                    width: grade.cellWidth - 14
                    readonly property bool abrindo: raiz.abrindo === jogo.id
                    height: capaJogo.height + 52

                    Rectangle {
                        id: capaJogo
                        width: parent.width
                        height: width * 1.5
                        radius: Tema.raio
                        color: Tema.elevado
                        border.width: 1
                        border.color: areaCartao.containsMouse ? Tema.texto4 : Tema.borda
                        clip: true
                        scale: areaCartao.containsMouse ? 1.03 : 1
                        Behavior on scale { NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva } }
                        Behavior on border.color { ColorAnimation { duration: Tema.rapido } }

                        // Sem capa: inicial grande e a origem
                        Text {
                            anchors.centerIn: parent
                            visible: imagem.status !== Image.Ready
                            text: (cartao.jogo.nome || "?").charAt(0).toUpperCase()
                            font.family: Tema.fonte; font.pixelSize: 54; font.weight: Font.Light; color: Tema.texto4
                        }
                        Image {
                            id: imagem
                            anchors.fill: parent
                            anchors.margins: 1
                            source: raiz.capa(cartao.jogo.capa)
                            sourceSize.width: 380
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Tema.medio } }
                        }

                        // Botão "Jogar" que sobe ao passar o mouse
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            height: 34
                            radius: 6
                            color: Tema.texto
                            opacity: areaCartao.containsMouse || cartao.abrindo ? 1 : 0
                            transform: Translate { y: areaCartao.containsMouse || cartao.abrindo ? 0 : 8 }
                            Behavior on opacity { NumberAnimation { duration: Tema.rapido } }
                            Text {
                                anchors.centerIn: parent
                                text: cartao.abrindo ? "Abrindo…" : "Jogar"
                                font.family: Tema.fonte; font.pixelSize: 13; font.weight: Font.Medium; color: Tema.fundo
                            }
                        }
                    }

                    Text {
                        anchors.top: capaJogo.bottom
                        anchors.topMargin: 10
                        width: parent.width
                        text: cartao.jogo.nome || ""
                        elide: Text.ElideRight
                        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                    }
                    Text {
                        anchors.top: capaJogo.bottom
                        anchors.topMargin: 29
                        width: parent.width
                        elide: Text.ElideRight
                        text: {
                            const partes = [raiz.origens[cartao.jogo.origem] || ""];
                            if (cartao.jogo.minutos) partes.push(raiz.tempo(cartao.jogo.minutos));
                            partes.push(raiz.quando(cartao.jogo.ultima));
                            return partes.join(" · ");
                        }
                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                    }

                    MouseArea {
                        id: areaCartao
                        anchors.fill: capaJogo
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: e => {
                            if (e.button === Qt.RightButton) {
                                const p = mapToItem(null, e.x, e.y);
                                menu.px = p.x; menu.py = p.y;
                                raiz.menuJogo = cartao.jogo;
                            } else {
                                raiz.jogar(cartao.jogo);
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------ vazio
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: raiz.carregado && raiz.visiveis.length === 0
                spacing: 10
                Item { Layout.fillHeight: true }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: raiz.jogos.length ? "Nenhum jogo com esse nome." : "Nenhum jogo instalado ainda."
                    font.family: Tema.fonte; font.pixelSize: 15; color: Tema.texto2
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 520
                    visible: raiz.jogos.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "Instale jogos pela Steam, pelo Heroic (Epic e GOG), pelo Prism Launcher (Minecraft) ou pelo Bottles e eles aparecem aqui sozinhos. Também dá para adicionar qualquer jogo pelo comando que o abre."
                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
                }
                Botao {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    visible: raiz.jogos.length === 0
                    texto: "Instalar lojas de jogos"
                    onClicado: { Quickshell.execDetached(["/usr/libexec/nyxz/configuracoes", "componentes"]); }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // ------------------------------------------------ menu do botão direito
        MouseArea {
            anchors.fill: parent
            visible: raiz.menuJogo !== null
            onClicked: raiz.menuJogo = null
        }
        Rectangle {
            id: menu
            visible: raiz.menuJogo !== null
            property real px: 0
            property real py: 0
            x: Math.min(px, janela.width - width - 8)
            y: Math.min(py, janela.height - height - 8)
            width: 200
            height: opcoes.implicitHeight + 10
            radius: Tema.raio
            color: Tema.painel
            border.color: Tema.bordaPainel
            border.width: 1
            ColumnLayout {
                id: opcoes
                anchors.fill: parent
                anchors.margins: 5
                spacing: 0
                ItemMenu {
                    texto: "Jogar"
                    onClicado: { const j = raiz.menuJogo; raiz.menuJogo = null; raiz.jogar(j); }
                }
                ItemMenu {
                    texto: "Abrir a pasta do jogo"
                    visible: raiz.menuJogo !== null && raiz.menuJogo.pasta !== ""
                    onClicado: { Quickshell.execDetached(["xdg-open", raiz.menuJogo.pasta]); raiz.menuJogo = null; }
                }
                ItemMenu {
                    texto: "Trocar a capa"
                    onClicado: { campoCapa.text = ""; raiz.dialogo = "capa"; }
                }
                ItemMenu {
                    texto: raiz.menuJogo && raiz.menuJogo.oculto ? "Mostrar na biblioteca" : "Ocultar"
                    onClicado: {
                        acao.rodar([raiz.cmd, raiz.menuJogo.oculto ? "mostrar" : "ocultar", raiz.menuJogo.id]);
                        raiz.menuJogo = null;
                    }
                }
                ItemMenu {
                    texto: "Remover da biblioteca"
                    perigo: true
                    visible: raiz.menuJogo !== null && raiz.menuJogo.origem === "avulso"
                    onClicado: { acao.rodar([raiz.cmd, "remover", raiz.menuJogo.id]); raiz.menuJogo = null; }
                }
            }
        }

        // ------------------------------------------------ diálogos
        Rectangle {
            anchors.fill: parent
            visible: raiz.dialogo !== ""
            color: Qt.rgba(0.035, 0.035, 0.05, 0.75)
            MouseArea { anchors.fill: parent; onClicked: raiz.dialogo = "" }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 60, 520)
                height: conteudo.implicitHeight + 44
                radius: Tema.raioPainel
                color: Tema.painel
                border.color: Tema.bordaPainel
                border.width: 1
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: conteudo
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 12

                    // Adicionar jogo avulso
                    ColumnLayout {
                        visible: raiz.dialogo === "adicionar"
                        Layout.fillWidth: true
                        spacing: 12
                        Text { text: "Adicionar jogo"; font.family: Tema.fonte; font.pixelSize: 15; font.weight: Font.Medium; color: Tema.texto }
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: "Para jogos que não vêm de uma loja: um AppImage, um emulador ou um jogo nativo. O Modo jogo liga ao abrir e desliga quando o jogo fecha."
                            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
                        }
                        Campo { id: campoNome; Layout.fillWidth: true; rotulo: "Nome" }
                        Campo { id: campoComando; Layout.fillWidth: true; rotulo: "Comando ou arquivo (ex.: ~/Jogos/Celeste.AppImage)" }
                        Campo { id: campoCapaNova; Layout.fillWidth: true; rotulo: "Capa (opcional): caminho de uma imagem em pé" }
                        RowLayout {
                            Layout.fillWidth: true
                            Item { Layout.fillWidth: true }
                            Botao { texto: "Cancelar"; onClicado: raiz.dialogo = "" }
                            Botao {
                                texto: "Adicionar"
                                principal: true
                                ativo: campoNome.text.trim() !== "" && campoComando.text.trim() !== ""
                                onClicado: {
                                    adicionar.running = true;
                                    adicionar.write(JSON.stringify({ nome: campoNome.text, comando: campoComando.text, capa: campoCapaNova.text }));
                                    adicionar.closeStdin();
                                    campoNome.text = ""; campoComando.text = ""; campoCapaNova.text = "";
                                    raiz.dialogo = "";
                                }
                            }
                        }
                    }

                    // Trocar a capa
                    ColumnLayout {
                        visible: raiz.dialogo === "capa"
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: "Capa de " + (raiz.menuJogo ? raiz.menuJogo.nome : "")
                            font.family: Tema.fonte; font.pixelSize: 15; font.weight: Font.Medium; color: Tema.texto
                        }
                        Campo { id: campoCapa; Layout.fillWidth: true; rotulo: "Caminho de uma imagem em pé (600×900 fica perfeita)" }
                        RowLayout {
                            Layout.fillWidth: true
                            Botao {
                                texto: "Usar a da loja"
                                onClicado: { acao.rodar([raiz.cmd, "capa", raiz.menuJogo.id]); raiz.dialogo = ""; raiz.menuJogo = null; }
                            }
                            Item { Layout.fillWidth: true }
                            Botao { texto: "Cancelar"; onClicado: { raiz.dialogo = ""; raiz.menuJogo = null; } }
                            Botao {
                                texto: "Salvar"
                                principal: true
                                ativo: campoCapa.text.trim() !== ""
                                onClicado: {
                                    acao.rodar([raiz.cmd, "capa", raiz.menuJogo.id, campoCapa.text.trim()]);
                                    raiz.dialogo = ""; raiz.menuJogo = null;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------- componentes
    component Chip: Rectangle {
        property string texto: ""
        property bool ativo: false
        signal clicado()
        implicitWidth: rotuloChip.implicitWidth + 22
        implicitHeight: 28
        radius: 14
        color: ativo ? Tema.selecionado : areaChip.containsMouse ? Tema.elevado : "transparent"
        border.width: 1
        border.color: ativo ? Tema.bordaPainel : Tema.borda
        Behavior on color { ColorAnimation { duration: Tema.rapido } }
        Text {
            id: rotuloChip
            anchors.centerIn: parent
            text: parent.texto
            font.family: Tema.fonte; font.pixelSize: 12
            color: parent.ativo ? Tema.texto : Tema.texto2
        }
        MouseArea { id: areaChip; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicado() }
    }

    component ItemMenu: Rectangle {
        property string texto: ""
        property bool perigo: false
        signal clicado()
        Layout.fillWidth: true
        implicitHeight: 32
        radius: 6
        color: areaItem.containsMouse ? Tema.hover : "transparent"
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            text: parent.texto
            font.family: Tema.fonte; font.pixelSize: 13
            color: parent.perigo ? Tema.erro : Tema.suave
        }
        MouseArea { id: areaItem; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicado() }
    }
}
