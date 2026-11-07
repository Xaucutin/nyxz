import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Busca estilo Raycast: apps, calculadora e ações do sistema (Super + Espaço).
PanelWindow {
    id: busca

    visible: Estado.buscaAberta || caixa.opacity > 0
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Estado.buscaAberta ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "nyxz-busca"

    property int selecionado: 0
    readonly property var resultados: calcular(campo.text)

    function normalizar(s) {
        return (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
    }

    function calcular(texto) {
        const q = texto.trim();
        const termo = normalizar(q);
        const lista = [];

        // Calculadora: "12*3+4", "2^10", "15% de 200" não; só expressões simples.
        if (/^[\d\s+\-*/().,%^]+$/.test(q) && /\d/.test(q) && /[+\-*/^%]/.test(q)) {
            try {
                const v = Function('"use strict";return (' + q.replace(/,/g, ".").replace(/\^/g, "**") + ")")();
                if (typeof v === "number" && isFinite(v)) {
                    const r = String(+v.toFixed(10)).replace(".", ",");
                    lista.push({ grupo: "Calculadora", nome: "= " + r, detalhe: "Enter copia", icone: "icones/calculadora.svg",
                                 executar: () => Estado.executar(["wl-copy", r]) });
                }
            } catch (e) {}
        }

        // Apps instalados
        const apps = DesktopEntries.applications.values
            .filter(a => !termo || normalizar(a.name + " " + a.genericName + " " + a.keywords.join(" ")).includes(termo))
            .sort((a, b) => {
                const pa = normalizar(a.name).startsWith(termo) ? 0 : 1;
                const pb = normalizar(b.name).startsWith(termo) ? 0 : 1;
                return pa - pb || a.name.localeCompare(b.name);
            })
            .slice(0, 40);
        for (const a of apps)
            lista.push({ grupo: "Aplicativos", nome: a.name, detalhe: a.genericName || a.comment, iconeApp: a.icon,
                         executar: () => Estado.abrirApp(a) });

        // Energia
        const energia = [
            { nome: "Bloquear a tela", chaves: "bloquear travar lock", cmd: ["loginctl", "lock-session"] },
            { nome: "Suspender", chaves: "suspender dormir suspend", cmd: ["systemctl", "suspend"] },
            { nome: "Reiniciar", chaves: "reiniciar reboot restart", cmd: ["systemctl", "reboot"] },
            { nome: "Desligar", chaves: "desligar shutdown poweroff", cmd: ["systemctl", "poweroff"] },
            { nome: "Sair da sessão", chaves: "sair logout encerrar", cmd: ["uwsm", "stop"] },
        ];
        for (const e of energia)
            if (termo && normalizar(e.nome + " " + e.chaves).includes(termo))
                lista.push({ grupo: "Sistema", nome: e.nome, detalhe: "", icone: "icones/energia.svg",
                             executar: () => Estado.executar(e.cmd) });

        return lista;
    }

    function executarSelecionado() {
        const r = resultados[selecionado];
        if (!r) return;
        Estado.buscaAberta = false;
        r.executar();
    }

    Connections {
        target: Estado
        function onBuscaAbertaChanged() {
            if (Estado.buscaAberta) {
                campo.text = "";
                busca.selecionado = 0;
                campo.forceActiveFocus();
            }
        }
    }

    // Fundo escurecido: clicar fora fecha.
    Rectangle {
        anchors.fill: parent
        color: "#040406"
        opacity: Estado.buscaAberta ? 0.6 : 0
        Behavior on opacity { NumberAnimation { duration: Tema.rapido } }
        MouseArea {
            anchors.fill: parent
            onClicked: Estado.buscaAberta = false
        }
    }

    Rectangle {
        id: caixa
        width: Math.min(640, busca.width - 48)
        height: Math.min(coluna.implicitHeight, busca.height * 0.7)
        anchors.horizontalCenter: parent.horizontalCenter
        y: busca.height * 0.16 + (Estado.buscaAberta ? 0 : 8)
        opacity: Estado.buscaAberta ? 1 : 0
        radius: Tema.raioPainel
        color: Tema.painel
        border.color: Tema.bordaPainel
        border.width: 1
        clip: true

        Behavior on opacity { NumberAnimation { duration: Tema.rapido } }
        Behavior on y {
            NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
        }

        MouseArea { anchors.fill: parent } // não deixa o clique atravessar para o fundo

        ColumnLayout {
            id: coluna
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 14

                Image {
                    source: "icones/busca.svg"
                    sourceSize: Qt.size(18, 18)
                }
                TextInput {
                    id: campo
                    Layout.fillWidth: true
                    font.family: Tema.fonte
                    font.pixelSize: 18
                    color: Tema.texto
                    selectionColor: Tema.selecionado
                    cursorDelegate: Rectangle { width: 1.5; color: Tema.texto }
                    onTextChanged: busca.selecionado = 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: campo.text.length === 0
                        text: "Buscar apps, contas ou ações"
                        font: campo.font
                        color: Tema.texto3
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            Estado.buscaAberta = false;
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            busca.selecionado = Math.min(busca.selecionado + 1, busca.resultados.length - 1);
                            lista.positionViewAtIndex(busca.selecionado, ListView.Contain);
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            busca.selecionado = Math.max(busca.selecionado - 1, 0);
                            lista.positionViewAtIndex(busca.selecionado, ListView.Contain);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            busca.executarSelecionado();
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#1A1A20"
                visible: busca.resultados.length > 0
            }

            ListView {
                id: lista
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight + 12, 420)
                Layout.bottomMargin: 6
                topMargin: 6
                clip: true
                model: busca.resultados
                boundsBehavior: Flickable.StopAtBounds
                // Rolagem com inércia (estilo Lenis)
                flickDeceleration: 1800
                maximumFlickVelocity: 3500

                delegate: Rectangle {
                    id: linha
                    required property var modelData
                    required property int index
                    readonly property bool ativo: index === busca.selecionado
                    width: lista.width - 12
                    x: 6
                    height: 44
                    radius: 6
                    color: ativo ? Tema.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 90 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            IconImage {
                                anchors.fill: parent
                                visible: linha.modelData.iconeApp !== undefined
                                source: linha.modelData.iconeApp !== undefined ? Quickshell.iconPath(linha.modelData.iconeApp, "application-x-executable") : ""
                            }
                            Image {
                                anchors.centerIn: parent
                                visible: linha.modelData.icone !== undefined
                                source: linha.modelData.icone || ""
                                sourceSize: Qt.size(16, 16)
                            }
                        }
                        Text {
                            text: linha.modelData.nome
                            font.family: Tema.fonte
                            font.pixelSize: 14
                            color: linha.ativo ? Tema.texto : Tema.suave
                        }
                        Text {
                            Layout.fillWidth: true
                            text: linha.modelData.detalhe || ""
                            font.family: Tema.fonte
                            font.pixelSize: 13
                            color: "#55535F"
                            elide: Text.ElideRight
                        }
                        Text {
                            text: linha.modelData.grupo
                            font.family: Tema.fonte
                            font.pixelSize: 12
                            color: "#55535F"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: busca.selecionado = linha.index
                        onClicked: busca.executarSelecionado()
                    }
                }
            }
        }
    }
}
