import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// Indicador de privacidade (ideia 32): aparece na barra só quando algum app está
// usando o microfone, a câmera ou capturando a tela. Passar o mouse mostra quem.
// Tudo vem do PipeWire, que a barra já acompanha: custo zero quando nada é usado.
Item {
    id: priv

    // Streams que estão *recebendo* algo (gravação): áudio = microfone; vídeo =
    // câmera ou captura de tela. A captura de tela pelo portal do Hyprland cria
    // uma fonte de vídeo "xdph-…".
    readonly property var nos: Pipewire.nodes.values
    readonly property var gravandoAudio: nos.filter(n => n.isStream && !n.isSink && n.audio !== null && !proprio(n))
    readonly property var gravandoVideo: nos.filter(n => n.isStream && !n.isSink && n.audio === null && !proprio(n))
    readonly property bool capturaTela: nos.some(n => !n.isStream && n.audio === null && (n.name || "").indexOf("xdph") === 0)

    readonly property bool microfone: gravandoAudio.length > 0
    readonly property bool tela: capturaTela
    readonly property bool camera: gravandoVideo.length > 0 && !capturaTela
    readonly property bool ativo: microfone || camera || tela

    function proprio(n) {
        const p = n.properties || {};
        // Não contam: medidores do próprio shell e a captura do "microfone sem ruído"
        // (nyxz-audio), que fica ligada enquanto o filtro existe. Contam os apps que
        // usam o microfone limpo.
        const nome = n.name || "";
        if (nome.indexOf("nyxz_mic_") === 0 || nome.indexOf("echo-cancel") === 0) return true;
        // O replay instantâneo grava o som do PC (não o microfone) e já tem a
        // própria marca "replay" na barra.
        const app = (p["application.name"] || "").toLowerCase();
        const bin = (p["application.process.binary"] || "").toLowerCase();
        if (app.indexOf("gpu-screen-recorder") >= 0 || bin.indexOf("gpu-screen-recorder") >= 0
                || nome.indexOf("gsr") === 0) return true;
        return app.indexOf("quickshell") >= 0;
    }
    function nomeApp(n) {
        const p = n.properties || {};
        return p["application.name"] || p["application.process.binary"] || n.description || n.name || "Um app";
    }
    function lista(nos) {
        const nomes = [];
        for (const n of nos) { const a = nomeApp(n); if (nomes.indexOf(a) < 0) nomes.push(a); }
        return nomes.join(", ");
    }

    // Os nomes dos apps só chegam com o nó acompanhado.
    PwObjectTracker { objects: priv.gravandoAudio.concat(priv.gravandoVideo) }

    visible: ativo
    implicitWidth: ativo ? fila.implicitWidth + 14 : 0
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(0.82, 0.40, 0.42, 0.14)
        border.width: 1
        border.color: Qt.rgba(0.82, 0.40, 0.42, 0.35)
    }

    Row {
        id: fila
        anchors.centerIn: parent
        spacing: 6
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6; height: 6; radius: 3
            color: Tema.erro
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: priv.ativo
                NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        Image { visible: priv.microfone; source: "icones/microfone.svg"; sourceSize: Qt.size(13, 13); anchors.verticalCenter: parent.verticalCenter }
        Image { visible: priv.camera; source: "icones/camera.svg"; sourceSize: Qt.size(13, 13); anchors.verticalCenter: parent.verticalCenter }
        Image { visible: priv.tela; source: "icones/tela.svg"; sourceSize: Qt.size(13, 13); anchors.verticalCenter: parent.verticalCenter }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
    }

    PopupWindow {
        visible: area.containsMouse && priv.ativo
        anchor.item: priv
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
        anchor.margins.top: -8
        implicitWidth: caixa.implicitWidth + 24
        implicitHeight: caixa.implicitHeight + 18
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            radius: Tema.raio
            color: Tema.painel
            border.color: Tema.bordaPainel
            border.width: 1
            Column {
                id: caixa
                anchors.centerIn: parent
                spacing: 4
                Text {
                    visible: priv.microfone
                    text: "Microfone: " + priv.lista(priv.gravandoAudio)
                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.suave
                }
                Text {
                    visible: priv.camera
                    text: "Câmera: " + priv.lista(priv.gravandoVideo)
                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.suave
                }
                Text {
                    visible: priv.tela
                    text: "Tela sendo capturada" + (priv.gravandoVideo.length ? ": " + priv.lista(priv.gravandoVideo) : "")
                    font.family: Tema.fonte; font.pixelSize: 12; color: Tema.suave
                }
            }
        }
    }
}
