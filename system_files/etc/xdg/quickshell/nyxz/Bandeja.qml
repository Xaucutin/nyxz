import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray

// Ícones de segundo plano (bandeja) como no Windows: os fixados ficam na barra e
// os outros na área oculta, aberta pela seta. Na área oculta, o alfinete de cada
// ícone fixa ou tira da barra. A escolha fica por app em ~/.config/nyxz/bandeja.json.
RowLayout {
    id: bandeja
    property var janelaBarra: null
    property bool emCima: false
    spacing: 0
    // Layout dentro de layout estica por padrão: a bandeja ocupava o espaço livre
    // da barra e empurrava o indicador de privacidade para o meio.
    Layout.fillWidth: false

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/bandeja.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: cfg
            property var ocultos: []   // ids dos apps que ficam na área oculta
        }
    }

    readonly property var itens: SystemTray.items.values
    readonly property var fixados: itens.filter(i => cfg.ocultos.indexOf(i.id) < 0)
    readonly property var escondidos: itens.filter(i => cfg.ocultos.indexOf(i.id) >= 0)

    function alternarFixo(id) {
        const lista = cfg.ocultos.slice();
        const i = lista.indexOf(id);
        if (i >= 0) lista.splice(i, 1); else lista.push(id);
        cfg.ocultos = lista;
    }

    // ---------------------------------------------- seta da área oculta
    Item {
        id: seta
        visible: bandeja.itens.length > 0
        Layout.preferredWidth: 22
        Layout.preferredHeight: 30
        property bool aberta: false
        Rectangle {
            anchors.fill: parent
            radius: 6
            color: seta.aberta || areaSeta.containsMouse ? Tema.hover : "transparent"
        }
        Text {
            anchors.centerIn: parent
            text: bandeja.emCima ? (seta.aberta ? "⌃" : "⌄") : (seta.aberta ? "⌄" : "⌃")
            font.pixelSize: 13
            color: Tema.texto2
        }
        MouseArea {
            id: areaSeta
            anchors.fill: parent
            hoverEnabled: true
            onClicked: seta.aberta = !seta.aberta
        }

        PopupWindow {
            visible: seta.aberta
            anchor.item: seta
            anchor.edges: bandeja.emCima ? Edges.Bottom : Edges.Top
            anchor.gravity: bandeja.emCima ? Edges.Bottom : Edges.Top
            anchor.margins.top: bandeja.emCima ? 0 : -8
            anchor.margins.bottom: bandeja.emCima ? -8 : 0
            implicitWidth: 236
            implicitHeight: conteudo.implicitHeight + 24
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: Tema.raioPainel
                color: Tema.painel
                border.color: Tema.bordaPainel
                border.width: 1

                ColumnLayout {
                    id: conteudo
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        text: "Ícones de segundo plano"
                        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "O alfinete fixa o ícone na barra."
                        wrapMode: Text.Wrap
                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 5
                        columnSpacing: 4
                        rowSpacing: 4
                        Repeater {
                            model: bandeja.itens
                            delegate: IconeBandeja {
                                required property var modelData
                                item: modelData
                                mostrarAlfinete: true
                                fixado: cfg.ocultos.indexOf(modelData.id) < 0
                                onAlfinete: bandeja.alternarFixo(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------- fixados na barra
    Repeater {
        model: bandeja.fixados
        delegate: IconeBandeja {
            required property var modelData
            item: modelData
        }
    }

    component IconeBandeja: Item {
        id: ic
        property var item: null
        property bool mostrarAlfinete: false
        property bool fixado: true
        signal alfinete()
        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        implicitWidth: 30
        implicitHeight: 30

        Rectangle {
            anchors.fill: parent
            radius: 7
            color: area.containsMouse ? Tema.hover : "transparent"
        }
        IconImage {
            anchors.centerIn: parent
            implicitSize: 16
            source: ic.item ? ic.item.icon : ""
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: mouse => {
                const m = ic.item;
                if (!m) return;
                if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && m.onlyMenu)) {
                    if (m.hasMenu && bandeja.janelaBarra) {
                        const p = ic.mapToItem(null, 0, 0);
                        m.display(bandeja.janelaBarra, p.x, bandeja.emCima ? 48 : -8);
                    }
                } else if (mouse.button === Qt.MiddleButton) {
                    m.secondaryActivate();
                } else {
                    m.activate();
                }
            }
            onWheel: wheel => { if (ic.item) ic.item.scroll(wheel.angleDelta.y, false); }
        }
        // Alfinete (só na área oculta)
        Rectangle {
            visible: ic.mostrarAlfinete
            anchors.right: parent.right
            anchors.top: parent.top
            width: 12
            height: 12
            radius: 6
            color: ic.fixado ? Tema.suave : Tema.trilho
            border.width: 1
            border.color: Tema.painel
            Text {
                anchors.centerIn: parent
                text: "•"
                font.pixelSize: 9
                color: ic.fixado ? Tema.fundo : Tema.texto3
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                cursorShape: Qt.PointingHandCursor
                onClicked: ic.alfinete()
            }
        }
    }
}
