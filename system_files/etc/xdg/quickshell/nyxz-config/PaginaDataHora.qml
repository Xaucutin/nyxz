import QtQuick
import QtQuick.Layouts
import Quickshell

// Data e hora: fuso horário e acerto automático pela internet (timedatectl).
// Mudar o fuso pede a senha de administrador uma vez; depois o shell é reiniciado
// para o relógio da barra usar o fuso novo.
Pagina {
    id: p
    titulo: "Data e hora"
    descricao: "Fuso horário e acerto automático do relógio pela internet."

    property string fuso: ""
    property bool automatico: true
    property string agora: ""
    property string erro: ""

    readonly property var fusos: [
        { id: "America/Sao_Paulo",   nome: "Brasília (SP, RJ, MG, Sul, GO, DF)" },
        { id: "America/Bahia",       nome: "Bahia" },
        { id: "America/Fortaleza",   nome: "Fortaleza (CE, RN, PB, PI, MA)" },
        { id: "America/Recife",      nome: "Recife (PE)" },
        { id: "America/Maceio",      nome: "Maceió (AL, SE)" },
        { id: "America/Belem",       nome: "Belém (PA, AP)" },
        { id: "America/Araguaina",   nome: "Tocantins" },
        { id: "America/Cuiaba",      nome: "Cuiabá (MT)" },
        { id: "America/Campo_Grande", nome: "Campo Grande (MS)" },
        { id: "America/Manaus",      nome: "Manaus (AM)" },
        { id: "America/Porto_Velho", nome: "Porto Velho (RO)" },
        { id: "America/Boa_Vista",   nome: "Boa Vista (RR)" },
        { id: "America/Rio_Branco",  nome: "Rio Branco (AC)" },
        { id: "America/Noronha",     nome: "Fernando de Noronha" },
        { id: "Europe/Lisbon",       nome: "Lisboa" },
        { id: "UTC",                 nome: "UTC (sem fuso)" }
    ]

    function ler() { estado.rodar(["timedatectl", "show", "-p", "Timezone", "-p", "NTP"]) }

    Comando {
        id: estado
        onPronto: saida => {
            const tz = /Timezone=(.*)/.exec(saida);
            const ntp = /NTP=(.*)/.exec(saida);
            p.fuso = tz ? tz[1].trim() : "";
            p.automatico = ntp ? ntp[1].trim() === "yes" : true;
        }
        Component.onCompleted: p.ler()
    }

    Comando {
        id: mudar
        onPronto: (saida, codigo) => {
            p.erro = codigo === 0 ? "" : "Não foi possível mudar. A senha foi cancelada?";
            p.ler();
            // O shell (barra) guarda o fuso de quando abriu: reinicia só ele.
            if (codigo === 0) Quickshell.execDetached(["sh", "-c",
                "pkill -x -f 'qs -c nyxz'; sleep 0.3; setsid -f nyx run /usr/libexec/nyxz/shell >/dev/null 2>&1"]);
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        // Sempre em português, mesmo se o idioma da sessão vier diferente.
        onTriggered: p.agora = new Date().toLocaleString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM 'de' yyyy · HH:mm:ss")
    }

    Text {
        Layout.bottomMargin: 8
        text: p.agora
        font.family: Tema.fonteMono
        font.pixelSize: 13
        color: Tema.suave
    }

    Linha { rotulo: "Fuso atual"; valor: (p.fusos.find(f => f.id === p.fuso) || { nome: p.fuso }).nome }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 14
        spacing: 12
        Text {
            Layout.preferredWidth: 150
            text: "Acertar pela internet"
            font.family: Tema.fonte
            font.pixelSize: 13
            color: Tema.texto3
        }
        Botao {
            texto: p.automatico ? "Ligado" : "Desligado"
            principal: p.automatico
            onClicado: mudar.rodar(["timedatectl", "set-ntp", p.automatico ? "false" : "true"])
        }
    }

    Text {
        text: "Escolha o fuso"
        font.family: Tema.fonte
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Tema.texto3
    }

    Repeater {
        model: p.fusos
        delegate: Rectangle {
            id: item
            required property var modelData
            readonly property bool escolhido: modelData.id === p.fuso
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            color: escolhido ? Tema.trilho : (area.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent")
            Behavior on color { ColorAnimation { duration: Tema.rapido } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.nome
                font.family: Tema.fonte
                font.pixelSize: 13
                color: item.escolhido ? Tema.texto : Tema.suave
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: item.escolhido ? "em uso" : ""
                font.family: Tema.fonteMono
                font.pixelSize: 11
                color: Tema.texto3
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (!item.escolhido) mudar.rodar(["timedatectl", "set-timezone", item.modelData.id])
            }
        }
    }

    Text {
        visible: p.erro !== ""
        Layout.topMargin: 8
        text: p.erro
        font.family: Tema.fonte
        font.pixelSize: 12
        color: Tema.texto3
    }
}
