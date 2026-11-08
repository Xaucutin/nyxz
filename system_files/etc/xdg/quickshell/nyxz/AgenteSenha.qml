import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit

// Janela de senha de administrador (agente polkit) no estilo da Nyxz.
// Substitui o mate-polkit, que era claro e em inglês. Se este arquivo não carregar
// (Quickshell sem o módulo de polkit), o shell.qml liga o agente antigo como reserva.
Scope {
    id: raiz
    readonly property bool registrado: agente.isRegistered
    readonly property var fluxo: agente.flow

    PolkitAgent { id: agente }

    // Mensagens próprias para as ações da Nyxz; as outras vêm do polkit (já em pt_BR).
    function titulo() {
        const f = raiz.fluxo;
        if (!f) return "";
        const m = f.message || "";
        if (m.indexOf("/usr/libexec/nyxz/componentes") >= 0) return "Instalar ou remover apps do sistema";
        if (m.indexOf("/usr/libexec/nyxz/atualizar") >= 0) return "Atualizar o sistema";
        if (f.actionId.indexOf("org.freedesktop.timedate1") === 0) return "Mudar data e hora";
        if (f.actionId.indexOf("org.freedesktop.NetworkManager") === 0) return "Mudar a rede";
        return "Permissão de administrador";
    }

    PanelWindow {
        id: janela
        visible: agente.isActive && raiz.fluxo !== null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nyxz-senha"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: if (visible) { campo.text = ""; campo.forceActiveFocus(); }

        // Fundo escurecido
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.035, 0.035, 0.05, 0.72)
            opacity: janela.visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Tema.rapido } }
        }

        Rectangle {
            id: cartao
            anchors.centerIn: parent
            width: 420
            height: coluna.implicitHeight + 48
            radius: Tema.raioPainel
            color: Tema.painel
            border.color: Tema.bordaPainel
            border.width: 1

            // Entrada estilo Lenis: sobe e aparece
            opacity: janela.visible ? 1 : 0
            transform: Translate { y: janela.visible ? 0 : 12 }
            Behavior on opacity { NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva } }

            // Tremida curta quando a senha está errada
            SequentialAnimation {
                id: tremer
                NumberAnimation { target: cartao; property: "anchors.horizontalCenterOffset"; to: -8; duration: 50 }
                NumberAnimation { target: cartao; property: "anchors.horizontalCenterOffset"; to: 8; duration: 70 }
                NumberAnimation { target: cartao; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
            }
            Connections {
                target: raiz.fluxo
                ignoreUnknownSignals: true
                function onFailedChanged() { if (raiz.fluxo.failed) { tremer.start(); campo.text = ""; } }
            }

            ColumnLayout {
                id: coluna
                anchors.fill: parent
                anchors.margins: 24
                spacing: 10

                Text {
                    text: raiz.titulo()
                    font.family: Tema.fonte
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    color: Tema.texto
                }
                Text {
                    Layout.fillWidth: true
                    text: raiz.fluxo ? raiz.fluxo.message : ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font.family: Tema.fonte
                    font.pixelSize: 12
                    color: Tema.texto3
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.preferredHeight: 40
                    radius: Tema.raio
                    color: Tema.elevado
                    border.width: 1
                    border.color: campo.activeFocus ? Tema.texto4 : Tema.borda

                    TextInput {
                        id: campo
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: raiz.fluxo && raiz.fluxo.responseVisible ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        enabled: raiz.fluxo !== null && raiz.fluxo.isResponseRequired
                        font.family: Tema.fonte
                        font.pixelSize: 14
                        color: Tema.texto
                        clip: true
                        Keys.onReturnPressed: confirmar()
                        Keys.onEnterPressed: confirmar()
                        Keys.onEscapePressed: cancelar()

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: campo.text.length === 0
                            text: "Senha"
                            font: campo.font
                            color: Tema.texto4
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: {
                        const f = raiz.fluxo;
                        if (!f) return "";
                        if (f.failed) return "Senha incorreta. Tente de novo.";
                        return f.supplementaryMessage || "";
                    }
                    wrapMode: Text.Wrap
                    font.family: Tema.fonte
                    font.pixelSize: 12
                    color: raiz.fluxo && (raiz.fluxo.failed || raiz.fluxo.supplementaryIsError) ? Tema.erro : Tema.texto3
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 8
                    Item { Layout.fillWidth: true }
                    BotaoSenha { texto: "Cancelar"; onClicado: cancelar() }
                    BotaoSenha { texto: "Confirmar"; principal: true; onClicado: confirmar() }
                }
            }
        }
    }

    function confirmar() {
        if (!raiz.fluxo || !raiz.fluxo.isResponseRequired) return;
        raiz.fluxo.submit(campo.text);
        campo.text = "";
    }
    function cancelar() {
        if (raiz.fluxo) raiz.fluxo.cancelAuthenticationRequest();
    }

    component BotaoSenha: Rectangle {
        id: b
        property string texto: ""
        property bool principal: false
        signal clicado()
        implicitWidth: rotulo.implicitWidth + 28
        implicitHeight: 34
        radius: Tema.raio
        color: principal ? (area.containsMouse ? "#FFFFFF" : Tema.texto) : (area.containsMouse ? Tema.hover : Tema.elevado)
        border.width: principal ? 0 : 1
        border.color: Tema.borda
        Behavior on color { ColorAnimation { duration: Tema.rapido } }
        Text {
            id: rotulo
            anchors.centerIn: parent
            text: b.texto
            font.family: Tema.fonte
            font.pixelSize: 13
            font.weight: Font.Medium
            color: b.principal ? Tema.fundo : Tema.suave
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: b.clicado()
        }
    }
}
