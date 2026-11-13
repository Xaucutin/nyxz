import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

// Barra de tarefas: logo, workspaces, apps abertos, bandeja, som e relógio.
PanelWindow {
    id: barra

    // Ajuste "barra em cima ou embaixo"
    anchors {
        left: true
        right: true
        top: Ajustes.barraEmCima
        bottom: !Ajustes.barraEmCima
    }
    margins {
        left: 10
        right: 10
        top: Ajustes.barraEmCima ? 10 : 0
        bottom: Ajustes.barraEmCima ? 0 : 10
    }
    implicitHeight: 40
    exclusiveZone: 40
    color: "transparent"
    WlrLayershell.namespace: "nyxz-barra"

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    PreviaJanela { id: previa; atrasoAbrir: Ajustes.atrasoPrevia; emCima: Ajustes.barraEmCima }

    Rectangle {
        anchors.fill: parent
        radius: Tema.raio
        color: Tema.barra

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 8
            spacing: 2

            // ---------------------------------------------- logo (abre a busca)
            Item {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: areaLogo.containsMouse ? Tema.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: Tema.rapido } }
                }
                Image {
                    anchors.centerIn: parent
                    source: "icones/nyxz.svg"
                    sourceSize: Qt.size(26, 13)
                    smooth: true
                }
                MouseArea {
                    id: areaLogo
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const abrir = !Estado.buscaAberta;
                        Estado.fecharTudo();
                        Estado.buscaAberta = abrir;
                    }
                }
            }

            // ---------------------------------------------- workspaces 1 a 5
            Row {
                Layout.leftMargin: 8
                Layout.rightMargin: 12
                spacing: 0

                Repeater {
                    model: 5
                    Item {
                        required property int index
                        readonly property int numero: index + 1
                        readonly property var ws: Hyprland.workspaces.values.find(w => w.id === numero)
                        readonly property bool ativo: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === numero
                        readonly property bool ocupado: ws !== undefined && ws.toplevels.values.length > 0
                        // Espaço com nome (Configurações → Espaços): mostra o nome no lugar do número
                        readonly property string nome: Espacos.nome(numero)
                        width: nome ? rotuloEspaco.implicitWidth + 16 : 24
                        height: 30
                        Behavior on width {
                            NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                        }

                        Text {
                            id: rotuloEspaco
                            anchors.centerIn: parent
                            text: parent.nome || parent.numero
                            font.family: parent.nome ? Tema.fonte : Tema.fonteMono
                            font.pixelSize: 12
                            color: parent.ativo ? Tema.texto : parent.ocupado ? "#8A8894" : Tema.texto4
                            Behavior on color { ColorAnimation { duration: Tema.rapido } }
                        }
                        Rectangle {
                            width: parent.ativo ? 8 : 0
                            height: 2
                            radius: 1
                            color: Tema.texto
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            Behavior on width {
                                NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Estado.irParaWorkspace(parent.numero)
                        }
                    }
                }

                WheelHandler {
                    onWheel: event => Estado.despachar(
                        "hl.dsp.focus({ workspace = '" + (event.angleDelta.y < 0 ? "e+1" : "e-1") + "' })",
                        "workspace " + (event.angleDelta.y < 0 ? "e+1" : "e-1"))
                }
            }

            // ---------------------------------------------- apps abertos
            Row {
                spacing: 2
                Repeater {
                    model: ToplevelManager.toplevels
                    delegate: Item {
                        id: tarefa
                        required property var modelData
                        readonly property var entrada: DesktopEntries.heuristicLookup(modelData.appId)
                        width: 34
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            radius: 7
                            color: tarefa.modelData.activated ? Tema.hover : areaTarefa.containsMouse ? Tema.elevado : "transparent"
                            Behavior on color { ColorAnimation { duration: Tema.rapido } }
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 19
                            // Ajuste "ícones crescem sob o mouse" (discreto)
                            scale: Ajustes.iconesCrescem && areaTarefa.containsMouse ? 1.16 : 1
                            Behavior on scale {
                                NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                            }
                            source: Quickshell.iconPath(tarefa.entrada ? tarefa.entrada.icon : tarefa.modelData.appId, "application-x-executable")
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            width: tarefa.modelData.activated ? 10 : 4
                            height: 2
                            radius: 1
                            color: tarefa.modelData.activated ? Tema.texto : Tema.texto4
                            Behavior on width {
                                NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                            }
                        }
                        MouseArea {
                            id: areaTarefa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onEntered: if (!Estado.menuAberto && Ajustes.previa) previa.mostrar(tarefa.modelData, tarefa)
                            onExited: previa.agendarFechar()
                            onClicked: mouse => {
                                previa.esconder();
                                if (mouse.button === Qt.RightButton) {
                                    const p = tarefa.mapToItem(null, 0, 0);
                                    Estado.fecharTudo();
                                    Estado.menuToplevel = tarefa.modelData;
                                    Estado.menuX = p.x + barra.margins.left - 20;
                                    Estado.menuAberto = true;
                                } else if (mouse.button === Qt.MiddleButton) {
                                    tarefa.modelData.close();
                                } else {
                                    Estado.restaurarOuAtivar(tarefa.modelData);
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------- mini player (só com mídia)
            MiniPlayer {
                visible: Ajustes.miniPlayer && temPlayer
                Layout.leftMargin: 8
            }

            Item { Layout.fillWidth: true }

            // ---------------------------------------------- privacidade (só em uso)
            Privacidade {
                visible: Ajustes.privacidade && ativo
                Layout.rightMargin: 6
            }

            // ---------------------------------------------- VPN (só quando ligada)
            Item {
                visible: VpnEstado.ligada
                Layout.preferredWidth: 26
                Layout.preferredHeight: 30
                Image { anchors.centerIn: parent; source: "icones/escudo.svg"; sourceSize: Qt.size(16, 16); opacity: 0.85 }
                MouseArea {
                    anchors.fill: parent
                    // Clique abre a página da VPN (o nome aparece lá)
                    onClicked: Quickshell.execDetached(["/usr/libexec/nyxz/configuracoes", "vpn"])
                }
            }

            // ---------------------------------------------- LAN virtual (só com rede ligada)
            Item {
                visible: VpnEstado.lan
                Layout.preferredWidth: 26
                Layout.preferredHeight: 30
                Image { anchors.centerIn: parent; source: "icones/lan.svg"; sourceSize: Qt.size(16, 16); opacity: 0.85 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["/usr/libexec/nyxz/configuracoes", "lan"])
                }
            }

            // ---------------------------------------------- Modo jogo e replay (só quando ligados)
            Item {
                visible: JogoEstado.modoJogo
                Layout.preferredWidth: 26
                Layout.preferredHeight: 30
                Image { anchors.centerIn: parent; source: "icones/controle.svg"; sourceSize: Qt.size(17, 17); opacity: 0.85 }
            }
            Rectangle {
                id: botaoReplay
                visible: JogoEstado.replay
                Layout.preferredWidth: rotuloReplay.implicitWidth + 24
                Layout.preferredHeight: 24
                Layout.rightMargin: 4
                radius: 12
                color: areaReplay.containsMouse ? Tema.hover : Tema.elevado
                border.width: 1
                border.color: Tema.borda
                Rectangle {
                    x: 9; anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: Tema.erro
                }
                Text {
                    id: rotuloReplay
                    x: 19; anchors.verticalCenter: parent.verticalCenter
                    text: "replay"
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto2
                }
                // Clique salva os últimos segundos (o mesmo que Alt+F10)
                MouseArea { id: areaReplay; anchors.fill: parent; hoverEnabled: true; onClicked: JogoEstado.salvarReplay() }
            }
            // Gravando a tela (Super+Shift+R): clique para parar
            Rectangle {
                id: pilulaGravando
                property bool ativo: false
                visible: ativo
                Layout.preferredWidth: rotuloGravando.implicitWidth + 24
                Layout.preferredHeight: 24
                Layout.rightMargin: 4
                radius: 12
                color: areaGravando.containsMouse ? Tema.hover : Tema.elevado
                border.width: 1
                border.color: Tema.borda
                FileView {
                    id: marcaGravando
                    path: Quickshell.env("XDG_RUNTIME_DIR") + "/nyxz-gravando.json"
                    printErrors: false
                    onLoaded: pilulaGravando.ativo = true
                    onLoadFailed: pilulaGravando.ativo = false
                }
                Timer { interval: 1500; running: true; repeat: true; onTriggered: marcaGravando.reload() }
                Rectangle {
                    x: 9; anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: Tema.erro
                }
                Text {
                    id: rotuloGravando
                    x: 19; anchors.verticalCenter: parent.verticalCenter
                    text: "gravando"
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto2
                }
                MouseArea { id: areaGravando; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["/usr/libexec/nyxz/captura", "parar"]) }
            }
            // Modo streamer ativo: clique desliga
            Rectangle {
                visible: Streamer.ativo
                Layout.preferredWidth: rotuloStreamer.implicitWidth + 24
                Layout.preferredHeight: 24
                Layout.rightMargin: 4
                radius: 12
                color: areaStreamer.containsMouse ? Tema.hover : Tema.elevado
                border.width: 1
                border.color: Tema.borda
                Rectangle {
                    x: 9; anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: Tema.aviso
                }
                Text {
                    id: rotuloStreamer
                    x: 19; anchors.verticalCenter: parent.verticalCenter
                    text: "streamer"
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto2
                }
                MouseArea { id: areaStreamer; anchors.fill: parent; hoverEnabled: true; onClicked: Streamer.alternar() }
            }
            // Nyxz Share transmitindo: clique abre o painel (com o botão de parar)
            Rectangle {
                visible: JogoEstado.share
                Layout.preferredWidth: rotuloShare.implicitWidth + 24
                Layout.preferredHeight: 24
                Layout.rightMargin: 4
                radius: 12
                color: areaShare.containsMouse ? Tema.hover : Tema.elevado
                border.width: 1
                border.color: Tema.borda
                Rectangle {
                    x: 9; anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: Tema.erro
                }
                Text {
                    id: rotuloShare
                    x: 19; anchors.verticalCenter: parent.verticalCenter
                    text: "ao vivo"
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto2
                }
                MouseArea {
                    id: areaShare
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8787/transmitir"])
                }
            }

            // ---------------------------------------------- medidor (Ajustes; desligado por padrão)
            Loader {
                active: Ajustes.medidor
                visible: active
                sourceComponent: Medidor { emCima: Ajustes.barraEmCima }
            }

            // ---------------------------------------------- bandeja (fixar/ocultar como no Windows)
            Bandeja {
                janelaBarra: barra
                emCima: Ajustes.barraEmCima
            }

            // ---------------------------------------------- brilho e luz azul
            Item {
                id: botaoRapido
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                property int acumulado: 0
                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: Estado.rapidoAberto || areaRapido.containsMouse ? Tema.hover : "transparent"
                }
                Image {
                    anchors.centerIn: parent
                    source: LuzAzul.ativo ? "icones/lua.svg" : "icones/brilho.svg"
                    sourceSize: Qt.size(16, 16)
                }
                // Rolar ajusta o brilho de todas as telas; junta os giros para o DDC/CI (lento).
                Timer {
                    id: brilhoRoda
                    interval: 350
                    onTriggered: {
                        Quickshell.execDetached(["/usr/libexec/nyxz/brilho", "ajustar", String(botaoRapido.acumulado)]);
                        botaoRapido.acumulado = 0;
                    }
                }
                MouseArea {
                    id: areaRapido
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const abrir = !Estado.rapidoAberto;
                        Estado.fecharTudo();
                        Estado.rapidoAberto = abrir;
                    }
                    onWheel: wheel => {
                        botaoRapido.acumulado += wheel.angleDelta.y > 0 ? 5 : -5;
                        brilhoRoda.restart();
                    }
                }
            }

            // ---------------------------------------------- som
            Item {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                readonly property var saida: Pipewire.defaultAudioSink
                readonly property bool mudo: saida !== null && saida.audio !== null && saida.audio.muted

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: Estado.somAberto || areaSom.containsMouse ? Tema.hover : "transparent"
                }
                Image {
                    anchors.centerIn: parent
                    source: parent.mudo ? "icones/mudo.svg" : "icones/volume.svg"
                    sourceSize: Qt.size(16, 16)
                }
                MouseArea {
                    id: areaSom
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const abrir = !Estado.somAberto;
                        Estado.fecharTudo();
                        Estado.somAberto = abrir;
                    }
                    // Rolar a roda do mouse muda o volume (mod "Taskbar Volume Control")
                    onWheel: wheel => {
                        if (!Ajustes.volumeNaRoda) return;
                        const s = Pipewire.defaultAudioSink;
                        if (!s || !s.audio) return;
                        const passo = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        s.audio.volume = Math.max(0, Math.min(1, s.audio.volume + passo));
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                color: Tema.borda
            }

            // ---------------------------------------------- relógio
            SystemClock {
                id: relogio
                precision: SystemClock.Minutes
            }
            Text {
                text: Qt.formatDateTime(relogio.date, "HH:mm")
                font.family: Tema.fonte
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Tema.texto
            }
        }
    }
}
