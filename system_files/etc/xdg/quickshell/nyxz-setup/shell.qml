//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Nyxz Setup: abre no primeiro login e deixa escolher o que entra no sistema.
// Nada é obrigatório; tudo pode ser mudado depois em Configurações → Apps e componentes.
// Tema, Botao, ListaComponentes, Executor e icones/ são ligados no build.
ShellRoot {
    id: raiz

    property int etapa: 0            // 0 boas-vindas, 1 perfil, 2 escolher, 3 resumo, 4 instalando
    property var catalogo: null
    property var estado: null
    property var marcados: ({})
    property string perfil: "sugerido"

    readonly property var escolhidos: catalogo ? catalogo.itens.filter(i => marcados[i.id]) : []
    readonly property int tamanhoTotal: escolhidos.reduce((s, i) => s + (estado && estado.itens[i.id] ? 0 : i.tamanho_mb), 0)
    readonly property bool temNativos: escolhidos.some(i => i.tipo === "rpm")

    FileView {
        path: "/usr/share/nyxz/catalogo.json"
        onLoaded: {
            raiz.catalogo = JSON.parse(text());
            raiz.usarPerfil("sugerido");
        }
    }
    Process {
        command: ["/usr/libexec/nyxz/componentes", "estado"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { raiz.estado = JSON.parse(this.text); } catch (e) {} } }
    }

    // Marca o Setup como feito (não abre de novo no próximo login).
    FileView {
        id: marcaFeito
        path: Quickshell.env("HOME") + "/.config/nyxz/setup.json"
    }
    function concluir() {
        marcaFeito.setText(JSON.stringify({ feito: true, perfil: raiz.perfil, data: new Date().toISOString() }));
    }

    function usarPerfil(p) {
        raiz.perfil = p;
        const m = {};
        if (raiz.catalogo)
            for (const i of raiz.catalogo.itens) m[i.id] = p !== "minimo" && i.padrao === true;
        raiz.marcados = m;
    }

    Executor { id: executor }

    function escolherPerfil(id) {
        usarPerfil(id === "minimo" ? "minimo" : "sugerido");
        perfil = id;
        etapa = id === "personalizado" ? 2 : 3;
    }

    function instalar() {
        if (!escolhidos.length) { concluir(); Qt.quit(); return; }
        etapa = 4;
        executor.aplicar(catalogo, marcados, estado);
    }

    function avancar() {
        if (etapa === 0) etapa = 1;
        else if (etapa === 1) escolherPerfil("sugerido");
        else if (etapa === 2) etapa = 3;
        else if (etapa === 3) instalar();
        else if (etapa === 4 && executor.terminou) { concluir(); Qt.quit(); }
    }

    function voltar() {
        if (etapa === 1) etapa = 0;
        else if (etapa === 2) etapa = 1;
        else if (etapa === 3) etapa = perfil === "personalizado" ? 2 : 1;
    }

    FloatingWindow {
        id: janela
        title: "Nyxz Setup"
        implicitWidth: 960
        implicitHeight: 680
        color: Tema.fundo
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()

        Item {
            anchors.fill: parent

            // Teclado: Enter avança, Esc volta, 1/2/3 escolhem o perfil.
            Shortcut {
                sequences: ["Return", "Enter"]
                onActivated: raiz.avancar()
            }
            Shortcut {
                sequence: "Esc"
                onActivated: raiz.voltar()
            }
            Shortcut { sequence: "1"; enabled: raiz.etapa === 1; onActivated: raiz.escolherPerfil("sugerido") }
            Shortcut { sequence: "2"; enabled: raiz.etapa === 1; onActivated: raiz.escolherPerfil("minimo") }
            Shortcut { sequence: "3"; enabled: raiz.etapa === 1; onActivated: raiz.escolherPerfil("personalizado") }

            // ------------------------------------------------ 0: boas-vindas
            Etapa {
                indice: 0
                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(520, parent.width - 64)
                    spacing: 0
                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 36
                        source: "icones/nyxz.svg"
                        sourceSize: Qt.size(120, 60)
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Bem-vindo à Nyxz"
                        font.family: Tema.fonte
                        font.pixelSize: 30
                        font.weight: Font.DemiBold
                        color: Tema.texto
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        Layout.bottomMargin: 36
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: "Escolha o que você quer no sistema. Nada é obrigatório, e dá para mudar tudo depois em Configurações → Apps e componentes."
                        font.family: Tema.fonte
                        font.pixelSize: 14
                        color: Tema.texto3
                    }
                    Botao {
                        Layout.alignment: Qt.AlignHCenter
                        texto: "Começar"
                        principal: true
                        onClicado: raiz.etapa = 1
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 16
                        text: "Pular e ficar só com o essencial"
                        font.family: Tema.fonte
                        font.pixelSize: 12
                        color: Tema.texto3
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: { raiz.concluir(); Qt.quit(); }
                        }
                    }
                }
            }

            // ------------------------------------------------ 1: perfil
            Etapa {
                indice: 1
                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(640, parent.width - 64)
                    spacing: 10
                    Titulo { texto: "Como você quer começar?" }
                    Repeater {
                        model: [
                            { id: "sugerido", nome: "Sugerido", desc: "Brave, Ghostty, Dolphin, VS Code, Git, Steam, Minecraft, Discord, Vesktop e Spotify. Dá para ajustar depois." },
                            { id: "minimo", nome: "Mínimo", desc: "Só o essencial: a área de trabalho da Nyxz, sem apps extras." },
                            { id: "personalizado", nome: "Personalizado", desc: "Escolher item por item, por categoria." }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: cartao.implicitHeight + 28
                            radius: Tema.raio
                            color: areaPerfil.containsMouse ? Tema.elevado : Tema.painel
                            border.color: modelData.id === "sugerido" ? "#3A3A44" : Tema.bordaPainel
                            Behavior on color { ColorAnimation { duration: Tema.rapido } }
                            ColumnLayout {
                                id: cartao
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 16
                                spacing: 4
                                Text {
                                    text: parent.parent.modelData.nome + (parent.parent.modelData.id === "sugerido" ? "  ·  recomendado" : "")
                                    font.family: Tema.fonte
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
                                    color: Tema.texto
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: parent.parent.modelData.desc
                                    font.family: Tema.fonte
                                    font.pixelSize: 13
                                    color: Tema.texto3
                                    wrapMode: Text.Wrap
                                }
                            }
                            MouseArea {
                                id: areaPerfil
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: raiz.escolherPerfil(parent.modelData.id)
                            }
                        }
                    }
                    Voltar { onClicado: raiz.etapa = 0 }
                }
            }

            // ------------------------------------------------ 2: escolher
            Etapa {
                indice: 2
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 40
                    spacing: 12
                    Titulo { texto: "Escolha os apps" }
                    Flickable {
                        id: rolagemEscolha
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: listaEscolha.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickDeceleration: 1800
                        ListaComponentes {
                            id: listaEscolha
                            // No Flickable, "parent" é o contentItem; a largura vem do próprio Flickable.
                            width: rolagemEscolha.width
                            catalogo: raiz.catalogo
                            marcados: raiz.marcados
                            instalados: raiz.estado ? raiz.estado.itens : ({})
                            onAlternar: id => {
                                const m = Object.assign({}, raiz.marcados);
                                m[id] = !m[id];
                                raiz.marcados = m;
                            }
                            onDefinirCategoria: (categoria, valor) => {
                                const m = Object.assign({}, raiz.marcados);
                                for (const i of raiz.catalogo.itens) if (i.categoria === categoria) m[i.id] = valor;
                                raiz.marcados = m;
                            }
                        }
                    }
                    RowLayout {
                        Voltar { onClicado: raiz.etapa = 1 }
                        Item { Layout.fillWidth: true }
                        Botao { texto: "Continuar"; principal: true; onClicado: raiz.etapa = 3 }
                    }
                }
            }

            // ------------------------------------------------ 3: resumo
            Etapa {
                indice: 3
                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(640, parent.width - 64)
                    spacing: 10
                    Titulo { texto: raiz.escolhidos.length ? "Pronto para instalar" : "Nada extra para instalar" }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: raiz.escolhidos.length ? raiz.escolhidos.map(i => i.nome).join(", ") : "Você vai começar só com o essencial. Dá para adicionar apps quando quiser."
                        font.family: Tema.fonte
                        font.pixelSize: 14
                        color: Tema.suave
                    }
                    Text {
                        Layout.topMargin: 6
                        visible: raiz.escolhidos.length > 0
                        text: "Download estimado: " + (raiz.tamanhoTotal >= 1000 ? (raiz.tamanhoTotal / 1000).toFixed(1).replace(".", ",") + " GB" : raiz.tamanhoTotal + " MB")
                        font.family: Tema.fonteMono
                        font.pixelSize: 12
                        color: Tema.texto3
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        visible: raiz.temNativos
                        wrapMode: Text.Wrap
                        text: "Os apps nativos (como Steam e VS Code) montam uma versão personalizada do sistema no seu PC. Vai pedir a sua senha, leva alguns minutos e entra no próximo boot."
                        font.family: Tema.fonte
                        font.pixelSize: 13
                        color: Tema.texto3
                    }
                    RowLayout {
                        Layout.topMargin: 14
                        Voltar { onClicado: raiz.etapa = raiz.perfil === "personalizado" ? 2 : 1 }
                        Item { Layout.fillWidth: true }
                        Botao { texto: "Ajustar"; visible: raiz.perfil !== "personalizado"; onClicado: raiz.etapa = 2 }
                        Botao {
                            texto: raiz.escolhidos.length ? "Instalar" : "Concluir"
                            principal: true
                            onClicado: raiz.instalar()
                        }
                    }
                }
            }

            // ------------------------------------------------ 4: instalando
            Etapa {
                indice: 4
                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(640, parent.width - 64)
                    spacing: 10
                    Titulo { texto: executor.terminou ? (executor.erro ? "Quase tudo pronto" : "Tudo pronto") : "Instalando…" }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: executor.terminou
                              ? (executor.erro || (executor.precisaReiniciar ? "Os apps Flatpak já estão prontos. Os apps nativos entram depois de reiniciar." : "Seus apps estão prontos."))
                              : executor.passo
                        font.family: Tema.fonte
                        font.pixelSize: 14
                        color: executor.erro ? Tema.erro : Tema.suave
                    }
                    // Barra indeterminada (movimento contínuo e suave)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        radius: 2
                        color: Tema.trilho
                        visible: !executor.terminou
                        clip: true
                        Rectangle {
                            id: faixa
                            width: parent.width * 0.3
                            height: parent.height
                            radius: 2
                            color: Tema.suave
                            NumberAnimation on x {
                                from: -faixa.width; to: faixa.parent.width
                                duration: 1400
                                loops: Animation.Infinite
                                easing.type: Easing.InOutCubic
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !executor.terminou && executor.log.length > 0
                        text: executor.log.length ? executor.log[executor.log.length - 1] : ""
                        font.family: Tema.fonteMono
                        font.pixelSize: 11
                        color: Tema.texto3
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        Layout.topMargin: 14
                        visible: executor.terminou
                        Item { Layout.fillWidth: true }
                        Botao {
                            texto: "Começar a usar"
                            principal: !executor.precisaReiniciar
                            onClicado: { raiz.concluir(); Qt.quit(); }
                        }
                        Botao {
                            visible: executor.precisaReiniciar
                            texto: "Reiniciar agora"
                            principal: true
                            onClicado: { raiz.concluir(); Quickshell.execDetached(["systemctl", "reboot"]); }
                        }
                    }
                }
            }
        }
    }

    // Etapa com transição suave (estilo Lenis): sobe e aparece.
    component Etapa: Item {
        property int indice: 0
        readonly property bool ativa: raiz.etapa === indice
        anchors.fill: parent
        visible: opacity > 0
        opacity: ativa ? 1 : 0
        transform: Translate { y: ativa ? 0 : 14 }
        Behavior on opacity { NumberAnimation { duration: Tema.rapido } }
    }
    component Titulo: Text {
        property string texto: ""
        Layout.bottomMargin: 8
        text: texto
        font.family: Tema.fonte
        font.pixelSize: 22
        font.weight: Font.Medium
        color: Tema.texto
    }
    component Voltar: Botao { texto: "Voltar" }
}
