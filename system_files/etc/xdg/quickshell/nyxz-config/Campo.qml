import QtQuick
import QtQuick.Layouts

// Campo de texto com rótulo e validação simples (Dev Hub).
//   oculto: true esconde o texto (senhas e segredos)
ColumnLayout {
    id: campo
    property string rotulo: ""
    property alias text: entrada.text
    property var validador: null
    property bool oculto: false
    readonly property bool aceito: !validador || validador.test(entrada.text)
    spacing: 4
    // Layout dentro de layout estica por padrão e ignora a largura pedida:
    // aqui só estica quem pedir (Layout.fillWidth: true na hora de usar).
    Layout.fillWidth: false

    Text { text: campo.rotulo; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        radius: Tema.raio
        color: Tema.elevado
        border.width: 1
        border.color: entrada.text.length > 0 && !campo.aceito ? Tema.erro : entrada.activeFocus ? Tema.texto4 : Tema.borda
        TextInput {
            id: entrada
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            font.family: Tema.fonteMono
            font.pixelSize: 12
            color: Tema.texto
            clip: true
            selectByMouse: true
            activeFocusOnTab: true   // Tab passa de campo em campo
            echoMode: campo.oculto ? TextInput.Password : TextInput.Normal
        }
    }
}
