//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Configurações da Nyxz. App separado: só ocupa memória enquanto está aberto.
// Tema.qml, Deslizante.qml e icones/ vêm do shell principal (ligados no build).
ShellRoot {
    id: raiz

    readonly property var paginas: [
        { id: "rede", nome: "Rede" },
        { id: "vpn", nome: "VPN e DNS" },
        { id: "lan", nome: "Redes de jogo" },
        { id: "som", nome: "Som" },
        { id: "telas", nome: "Telas" },
        { id: "teclado", nome: "Teclado e mouse" },
        { id: "controles", nome: "Controles" },
        { id: "aparencia", nome: "Aparência" },
        { id: "ajustes", nome: "Ajustes" },
        { id: "regras", nome: "Regras de janela" },
        { id: "espacos", nome: "Espaços" },
        { id: "componentes", nome: "Apps e componentes" },
        { id: "discos", nome: "Discos" },
        { id: "datahora", nome: "Data e hora" },
        { id: "atualizacoes", nome: "Atualizações" },
        { id: "sobre", nome: "Sobre" }
    ]
    property int atual: 0

    function abrir(id) {
        const i = paginas.findIndex(p => p.id === id);
        if (i >= 0) atual = i;
    }

    // Abrir numa página: /usr/libexec/nyxz/configuracoes som
    IpcHandler {
        target: "config"
        function abrir(pagina: string): void { raiz.abrir(pagina); }
    }

    FloatingWindow {
        id: janela
        title: "Configurações"
        // 900×600, mas nunca maior que a tela (notebooks 1366×768, VMs pequenas).
        readonly property var tela: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        implicitWidth: tela ? Math.min(900, tela.width - 60) : 900
        implicitHeight: tela ? Math.min(600, tela.height - 100) : 600
        color: Tema.fundo
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Teclado: Ctrl+↓/Ctrl+↑ (ou Ctrl+Tab/Ctrl+Shift+Tab) trocam de página; Esc fecha.
            // Atalhos da janela inteira: funcionam mesmo com o foco num campo de texto.
            Shortcut {
                sequences: ["Ctrl+Down", "Ctrl+Tab", "Ctrl+PgDown"]
                onActivated: raiz.atual = (raiz.atual + 1) % raiz.paginas.length
            }
            Shortcut {
                sequences: ["Ctrl+Up", "Ctrl+Shift+Tab", "Ctrl+PgUp"]
                onActivated: raiz.atual = (raiz.atual + raiz.paginas.length - 1) % raiz.paginas.length
            }
            Shortcut {
                sequence: "Esc"
                onActivated: Qt.quit()
            }

            // ------------------------------------------------ menu lateral
            ColumnLayout {
                Layout.preferredWidth: 210
                Layout.maximumWidth: 210
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.margins: 10
                spacing: 1

                Row {
                    Layout.leftMargin: 10
                    Layout.topMargin: 6
                    Layout.bottomMargin: 18
                    spacing: 10
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "icones/nyxz.svg"
                        sourceSize: Qt.size(22, 11)
                    }
                    Text {
                        text: "Configurações"
                        font.family: Tema.fonte
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Tema.texto
                    }
                }

                Repeater {
                    model: raiz.paginas
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool ativa: raiz.atual === index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 6
                        color: ativa ? "#16161B" : areaMenu.containsMouse ? Tema.elevado : "transparent"
                        Behavior on color { ColorAnimation { duration: Tema.rapido } }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: parent.modelData.nome
                            font.family: Tema.fonte
                            font.pixelSize: 13
                            color: parent.ativa ? Tema.texto : Tema.texto2
                        }
                        MouseArea {
                            id: areaMenu
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: raiz.atual = parent.index
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: "#1A1A20"
            }

            // ------------------------------------------------ páginas
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Repeater {
                    model: raiz.paginas
                    delegate: Loader {
                        required property var modelData
                        required property int index
                        readonly property bool ativa: raiz.atual === index
                        anchors.fill: parent
                        // Cada página só carrega quando é aberta (economiza RAM).
                        active: ativa
                        opacity: ativa ? 1 : 0
                        source: {
                            const mapa = { rede: "PaginaRede.qml", vpn: "PaginaVpn.qml", lan: "PaginaLan.qml", som: "PaginaSom.qml", telas: "PaginaTelas.qml",
                                           teclado: "PaginaTeclado.qml", controles: "PaginaControles.qml", aparencia: "PaginaAparencia.qml", ajustes: "PaginaAjustes.qml", regras: "PaginaRegras.qml", espacos: "PaginaEspacos.qml", componentes: "PaginaComponentes.qml", discos: "PaginaDiscos.qml", datahora: "PaginaDataHora.qml",
                                           atualizacoes: "PaginaAtualizacoes.qml", sobre: "PaginaSobre.qml" };
                            return mapa[modelData.id];
                        }
                        transform: Translate { y: ativa ? 0 : 10 }
                        Behavior on opacity { NumberAnimation { duration: Tema.rapido } }
                    }
                }
            }
        }
    }
}
