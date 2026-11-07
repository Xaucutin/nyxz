import QtQuick
import QtQuick.Layouts
import Quickshell

// Sobre: versão, hardware e uso de memória (atualiza a cada 2 s).
Pagina {
    id: p
    titulo: "Sobre"
    descricao: "Versão do sistema, o seu hardware e quanto de memória está em uso."

    property string versao: "…"
    property string kernel: "…"
    property string cpu: "…"
    property string gpu: "…"
    property string disco: "…"
    property real ramUsada: 0
    property real ramTotal: 0

    function gb(bytes) {
        return (bytes / 1e9).toFixed(bytes < 1e10 ? 1 : 0).replace(".", ",") + " GB";
    }

    Comando {
        id: info
        onPronto: saida => {
            const l = saida.split("\n");
            p.versao = l[0] || "?";
            p.kernel = l[1] || "?";
            p.cpu = (l[2] || "?").replace(/^model name\s*:\s*/, "");
            p.gpu = (l[3] || "Não identificada").replace(/^.*?:\s*/, "");
            const d = (l[4] || "").trim().split(/\s+/).map(Number);
            p.disco = d.length === 2 && d[1] > 0 ? p.gb(d[0]) + " de " + p.gb(d[1]) : "?";
        }
        Component.onCompleted: rodar(["sh", "-c",
            "cat /usr/share/nyxz/versao; uname -r; grep -m1 'model name' /proc/cpuinfo; " +
            "(lspci 2>/dev/null | grep -i -m1 -E 'vga|3d|display' || echo); " +
            "df -B1 --output=used,size /var/home 2>/dev/null | tail -n1"])
    }

    Comando {
        id: memoria
        onPronto: saida => {
            const total = /MemTotal:\s+(\d+)/.exec(saida);
            const livre = /MemAvailable:\s+(\d+)/.exec(saida);
            if (total && livre) {
                p.ramTotal = total[1] / 1048576;
                p.ramUsada = (total[1] - livre[1]) / 1048576;
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memoria.rodar(["cat", "/proc/meminfo"])
    }

    Row {
        Layout.bottomMargin: 10
        spacing: 16
        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: "icones/nyxz.svg"
            sourceSize: Qt.size(64, 32)
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: "Nyxz"
                font.family: Tema.fonte
                font.pixelSize: 24
                font.weight: Font.DemiBold
                color: Tema.texto
            }
            Text {
                text: "Versão " + p.versao
                font.family: Tema.fonteMono
                font.pixelSize: 12
                color: Tema.texto3
            }
        }
    }

    // Memória em uso, com a meta da Nyxz (≤ 1 GB parado)
    Text {
        Layout.topMargin: 6
        text: "Memória em uso"
        font.family: Tema.fonte
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Tema.texto3
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Tema.trilho
            Rectangle {
                width: p.ramTotal > 0 ? parent.width * Math.min(1, p.ramUsada / p.ramTotal) : 0
                height: parent.height
                radius: 3
                color: Tema.suave
                Behavior on width {
                    NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva }
                }
            }
        }
        Text {
            text: p.ramUsada.toFixed(2).replace(".", ",") + " de " + p.ramTotal.toFixed(1).replace(".", ",") + " GB"
            font.family: Tema.fonteMono
            font.pixelSize: 12
            color: Tema.suave
        }
    }

    Item { Layout.preferredHeight: 10 }
    Linha { rotulo: "Processador"; valor: p.cpu }
    Linha { rotulo: "Placa de vídeo"; valor: p.gpu }
    Linha { rotulo: "Armazenamento"; valor: p.disco + " usados" }
    Linha { rotulo: "Kernel"; valor: p.kernel; mono: true }
    Linha { rotulo: "Base"; valor: "Fedora Atomic (bootc) · Hyprland" }

    Botao {
        Layout.topMargin: 14
        texto: "Copiar informações"
        onClicado: Quickshell.execDetached(["wl-copy",
            "Nyxz " + p.versao + "\nKernel " + p.kernel + "\nCPU: " + p.cpu + "\nGPU: " + p.gpu +
            "\nRAM em uso: " + p.ramUsada.toFixed(2) + " / " + p.ramTotal.toFixed(1) + " GB"])
    }
}
