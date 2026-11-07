import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Servidor de notificações da Nyxz: cartões no canto superior direito.
Scope {
    id: raiz

    NotificationServer {
        id: servidor
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        bodyMarkupSupported: false
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
        }
    }

    PanelWindow {
        id: janela
        visible: servidor.trackedNotifications.values.length > 0
        anchors {
            top: true
            right: true
        }
        margins {
            top: 10
            right: 10
        }
        implicitWidth: 340
        implicitHeight: coluna.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nyxz-notificacoes"

        Column {
            id: coluna
            width: parent.width
            spacing: 8

            Repeater {
                model: servidor.trackedNotifications
                delegate: Rectangle {
                    id: cartao
                    required property var modelData
                    readonly property bool critica: modelData.urgency === NotificationUrgency.Critical
                    width: coluna.width
                    implicitHeight: conteudo.implicitHeight + 24
                    radius: Tema.raioPainel
                    color: Tema.painel
                    border.color: critica ? "#4A2A2C" : Tema.bordaPainel
                    border.width: 1
                    opacity: 0
                    x: 16

                    Component.onCompleted: {
                        opacity = 1;
                        x = 0;
                    }
                    Behavior on opacity { NumberAnimation { duration: Tema.rapido } }
                    Behavior on x {
                        NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                    }

                    // Some sozinha depois de 6 s (as críticas ficam até serem fechadas).
                    Timer {
                        running: !cartao.critica && !areaCartao.containsMouse
                        interval: 6000
                        onTriggered: cartao.modelData.expire()
                    }

                    MouseArea {
                        id: areaCartao
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: cartao.modelData.dismiss()
                    }

                    ColumnLayout {
                        id: conteudo
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            IconImage {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                visible: cartao.modelData.appIcon !== ""
                                source: cartao.modelData.appIcon !== "" ? Quickshell.iconPath(cartao.modelData.appIcon, true) : ""
                            }
                            Text {
                                Layout.fillWidth: true
                                text: cartao.modelData.summary
                                font.family: Tema.fonte
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: Tema.texto
                                elide: Text.ElideRight
                            }
                            Text {
                                text: cartao.modelData.appName
                                font.family: Tema.fonte
                                font.pixelSize: 11
                                color: "#55535F"
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: cartao.modelData.body
                            font.family: Tema.fonte
                            font.pixelSize: 12
                            color: Tema.texto2
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }
                        Row {
                            Layout.topMargin: 4
                            spacing: 4
                            visible: cartao.modelData.actions.length > 0
                            Repeater {
                                model: cartao.modelData.actions
                                delegate: Rectangle {
                                    required property var modelData
                                    width: rotulo.implicitWidth + 16
                                    height: 26
                                    radius: 6
                                    color: areaAcao.containsMouse ? Tema.hover : "transparent"
                                    Text {
                                        id: rotulo
                                        anchors.centerIn: parent
                                        text: parent.modelData.text
                                        font.family: Tema.fonte
                                        font.pixelSize: 12
                                        color: Tema.suave
                                    }
                                    MouseArea {
                                        id: areaAcao
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: parent.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
