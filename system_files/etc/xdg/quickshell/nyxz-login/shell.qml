//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// Tela de login da Nyxz (roda pelo greetd dentro do cage).
// Tema.qml e icones/ vêm da pasta do shell principal (ligados no build).
ShellRoot {
    id: raiz

    property var usuarios: []
    property int indiceUsuario: 0
    readonly property var usuario: usuarios.length > 0 ? usuarios[indiceUsuario] : null
    property string mensagem: ""
    property bool ocupado: false
    property string senhaPendente: ""

    // Usuários de verdade (UID 1000 a 59999) a partir do /etc/passwd.
    FileView {
        path: "/etc/passwd"
        onLoaded: {
            const lista = [];
            for (const linha of text().split("\n")) {
                const c = linha.split(":");
                const uid = parseInt(c[2]);
                if (c.length >= 7 && uid >= 1000 && uid < 60000 && !c[6].endsWith("nologin")) {
                    const nome = (c[4] || "").split(",")[0];
                    lista.push({ login: c[0], nome: nome || c[0] });
                }
            }
            raiz.usuarios = lista;
        }
    }

    function entrar(senha) {
        if (!raiz.usuario || raiz.ocupado) return;
        raiz.ocupado = true;
        raiz.mensagem = "";
        raiz.senhaPendente = senha;
        Greetd.createSession(raiz.usuario.login);
    }

    Connections {
        target: Greetd
        function onAuthMessage(mensagem, erro, precisaResposta, eco) {
            if (precisaResposta) {
                Greetd.respond(raiz.senhaPendente);
                raiz.senhaPendente = "";
            } else if (erro) {
                raiz.mensagem = mensagem;
            }
        }
        function onReadyToLaunch() {
            Greetd.launch(["/usr/libexec/nyxz/session"], [], true);
        }
        // Depois de uma falha, a sessão antiga é cancelada e a nova tentativa só é
        // liberada um instante depois. Sem isso, tentar de novo rápido demais dava
        // "Connection refused" (visto no teste em VM).
        function onAuthFailure(mensagem) {
            raiz.mensagem = "Senha incorreta";
            janela.errou();
            Greetd.cancelSession();
            liberar.restart();
        }
        function onError(erro) {
            console.warn("greetd: " + erro);
            raiz.mensagem = "Não foi possível entrar. Tente de novo.";
            Greetd.cancelSession();
            liberar.restart();
        }
    }

    Timer {
        id: liberar
        interval: 800
        onTriggered: raiz.ocupado = false
    }

    FloatingWindow {
        id: janela
        color: Tema.fundo
        visible: true

        signal errou()

        SystemClock {
            id: relogio
            precision: SystemClock.Minutes
        }

        // Símbolo da Nyxz gigante e quase invisível, como na maquete
        Image {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: -parent.width * 0.06
            anchors.bottomMargin: parent.height * 0.04
            width: parent.width * 0.62
            height: width / 2
            source: "icones/nyxz.svg"
            sourceSize: Qt.size(width, height)
            opacity: 0.025
        }

        ColumnLayout {
            id: centro
            anchors.centerIn: parent
            width: Math.min(340, parent.width - 48)
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(relogio.date, "HH:mm")
                font.family: Tema.fonte
                font.pixelSize: 64
                font.weight: Font.DemiBold
                color: Tema.texto
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 40
                text: relogio.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM")
                font.family: Tema.fonte
                font.pixelSize: 14
                color: Tema.texto3
            }

            // Usuário (clique para trocar quando houver mais de um)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: Tema.raio
                color: areaUsuario.containsMouse && raiz.usuarios.length > 1 ? Tema.hover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: raiz.usuario ? raiz.usuario.nome : "Nenhum usuário"
                    font.family: Tema.fonte
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: Tema.texto
                }
                MouseArea {
                    id: areaUsuario
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: if (raiz.usuarios.length > 1) raiz.indiceUsuario = (raiz.indiceUsuario + 1) % raiz.usuarios.length
                }
            }

            // Senha
            Rectangle {
                id: caixaSenha
                Layout.fillWidth: true
                Layout.topMargin: 12
                Layout.preferredHeight: 44
                radius: Tema.raio
                color: Tema.painel
                border.color: senha.activeFocus ? "#3A3A44" : Tema.bordaPainel
                border.width: 1

                transform: Translate { id: tremor; x: 0 }
                SequentialAnimation {
                    id: animTremor
                    NumberAnimation { target: tremor; property: "x"; to: -8; duration: 50 }
                    NumberAnimation { target: tremor; property: "x"; to: 8; duration: 70 }
                    NumberAnimation { target: tremor; property: "x"; to: -4; duration: 60 }
                    NumberAnimation { target: tremor; property: "x"; to: 0; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                }
                Connections {
                    target: janela
                    function onErrou() {
                        animTremor.restart();
                        senha.text = "";
                        senha.forceActiveFocus();
                    }
                }

                TextInput {
                    id: senha
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    font.family: Tema.fonte
                    font.pixelSize: 15
                    color: Tema.texto
                    focus: true
                    enabled: !raiz.ocupado
                    cursorDelegate: Rectangle { width: 1.5; color: Tema.texto }
                    Component.onCompleted: forceActiveFocus()
                    onAccepted: raiz.entrar(text)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: senha.text.length === 0
                        text: raiz.ocupado ? "Entrando…" : "Senha"
                        font: senha.font
                        color: Tema.texto3
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: centro.width
                Layout.topMargin: 12
                Layout.preferredHeight: 36
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: raiz.mensagem
                font.family: Tema.fonte
                font.pixelSize: 13
                color: Tema.erro
            }
        }

        // Energia no canto inferior direito
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 24
            spacing: 4
            Repeater {
                model: [
                    { nome: "Reiniciar", cmd: ["systemctl", "reboot"] },
                    { nome: "Desligar", cmd: ["systemctl", "poweroff"] }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: rotulo.implicitWidth + 24
                    height: 32
                    radius: 6
                    color: areaEnergia.containsMouse ? Tema.hover : "transparent"
                    Text {
                        id: rotulo
                        anchors.centerIn: parent
                        text: parent.modelData.nome
                        font.family: Tema.fonte
                        font.pixelSize: 13
                        color: Tema.texto2
                    }
                    MouseArea {
                        id: areaEnergia
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Quickshell.execDetached(parent.modelData.cmd)
                    }
                }
            }
        }
    }
}
