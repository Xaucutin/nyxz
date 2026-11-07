import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Teclado e mouse: layout do teclado, velocidade e aceleração do mouse.
// Guarda as escolhas em ~/.config/nyxz/entrada.json e gera
// ~/.config/hypr/nyxz/entrada.lua, que o Hyprland carrega.
Pagina {
    id: p
    titulo: "Teclado e mouse"
    descricao: "As mudanças valem na hora."

    readonly property string home: Quickshell.env("HOME")
    readonly property var layouts: [
        { id: "br", variante: "", nome: "Português (Brasil, ABNT2)" },
        { id: "us", variante: "", nome: "Inglês (EUA)" },
        { id: "us", variante: "intl", nome: "Inglês (EUA, internacional com acentos)" },
        { id: "pt", variante: "", nome: "Português (Portugal)" }
    ]

    FileView {
        id: dados
        path: p.home + "/.config/nyxz/entrada.json"
        printErrors: false
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: cfg
            property string layout: "br"
            property string variante: ""
            property real sensibilidade: 0
            property bool aceleracao: false
        }
    }

    FileView {
        id: lua
        path: p.home + "/.config/hypr/nyxz/entrada.lua"
        printErrors: false
    }

    function aplicar() {
        lua.setText(
            "-- Gerado por Configurações → Teclado e mouse.\n" +
            "hl.config({ input = {\n" +
            '    kb_layout = "' + cfg.layout + '",\n' +
            '    kb_variant = "' + cfg.variante + '",\n' +
            "    sensitivity = " + cfg.sensibilidade.toFixed(2) + ",\n" +
            '    accel_profile = "' + (cfg.aceleracao ? "adaptive" : "flat") + '",\n' +
            "} })\n");
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    Text { text: "Layout do teclado"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Repeater {
        model: p.layouts
        delegate: Rectangle {
            id: opc
            required property var modelData
            readonly property bool atual: cfg.layout === modelData.id && cfg.variante === modelData.variante
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 6
            color: atual ? "#16161B" : areaOpc.containsMouse ? Tema.elevado : "transparent"
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
                text: opc.modelData.nome
                font.family: Tema.fonte
                font.pixelSize: 13
                color: opc.atual ? Tema.texto : Tema.texto2
            }
            MouseArea {
                id: areaOpc
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    cfg.layout = opc.modelData.id;
                    cfg.variante = opc.modelData.variante;
                    p.aplicar();
                }
            }
        }
    }

    Text {
        Layout.topMargin: 18
        text: "Velocidade do mouse"
        font.family: Tema.fonte
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Tema.texto3
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        spacing: 12
        Text { text: "Lenta"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        Deslizante {
            Layout.fillWidth: true
            valor: (cfg.sensibilidade + 1) / 2
            onMudou: v => cfg.sensibilidade = v * 2 - 1
        }
        Text { text: "Rápida"; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
    }
    Timer {
        // Aplica depois que você solta o controle (evita recarregar a cada pixel).
        id: atraso
        interval: 400
        onTriggered: p.aplicar()
    }
    Connections {
        target: cfg
        function onSensibilidadeChanged() { atraso.restart(); }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.preferredHeight: 40
        radius: 6
        color: areaAcel.containsMouse ? Tema.elevado : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            Text {
                Layout.fillWidth: true
                text: "Aceleração do mouse"
                font.family: Tema.fonte
                font.pixelSize: 13
                color: Tema.suave
            }
            Rectangle {
                width: 30
                height: 17
                radius: 9
                color: cfg.aceleracao ? "#E4E2EA" : "#25252C"
                Behavior on color { ColorAnimation { duration: Tema.rapido } }
                Rectangle {
                    y: 3
                    x: cfg.aceleracao ? 16 : 3
                    width: 11
                    height: 11
                    radius: 6
                    color: cfg.aceleracao ? Tema.fundo : "#6E6C78"
                    Behavior on x {
                        NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                    }
                }
            }
        }
        MouseArea {
            id: areaAcel
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                cfg.aceleracao = !cfg.aceleracao;
                p.aplicar();
            }
        }
    }
    Text {
        Layout.leftMargin: 12
        text: "Desligada é melhor para jogos: o cursor anda sempre a mesma distância."
        font.family: Tema.fonte
        font.pixelSize: 12
        color: Tema.texto3
    }
}
