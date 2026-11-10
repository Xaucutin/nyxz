import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Medidor na barra (ideia 6): CPU, RAM, placa de vídeo e temperatura. Desligado por
// padrão (Ajustes → "Medidor na barra"); a barra só cria este item quando ligado.
// Lê direto do kernel a cada 2 s (/proc e /sys), sem abrir processos.
Item {
    id: medidor
    property bool emCima: false

    implicitWidth: linha.implicitWidth + 16
    implicitHeight: 30

    // ------------------------------------------------ números
    property real cpu: 0
    property real ramUsada: 0          // bytes (total − disponível)
    property real ramTotal: 0
    property real ramApps: 0           // apps abertos pela Nyxz (fatias de app do usuário)
    property real swapUsada: 0
    property real gpu: -1              // % (−1: sem placa AMD com o contador)
    property real vramUsada: 0
    property real vramTotal: 0
    property real tempCpu: -1
    property real tempGpu: -1
    property var _cpuAntes: null

    // Caminhos descobertos uma vez (variam entre PCs)
    property string pastaGpu: ""
    property string sensorCpu: ""
    property string sensorGpu: ""
    property string cgroupUsuario: ""

    Process {
        running: true
        command: ["sh", "-c",
            // placa de vídeo AMD com o contador de uso; sensores de CPU (k10temp/coretemp) e GPU
            'for c in /sys/class/drm/card*/device; do [ -r "$c/gpu_busy_percent" ] && { echo "gpu $c"; break; }; done; ' +
            'for h in /sys/class/hwmon/hwmon*; do n=$(cat "$h/name" 2>/dev/null); ' +
            'case "$n" in k10temp|coretemp|zenpower) echo "cpu $h/temp1_input";; amdgpu) echo "gputemp $h/temp1_input";; esac; done; ' +
            'echo "cg $(sed -n "s|^0::\\(/user.slice/user-[0-9]*.slice/user@[0-9]*.service\\).*|\\1|p" /proc/self/cgroup)"']
        stdout: SplitParser {
            onRead: l => {
                const [k, v] = [l.slice(0, l.indexOf(" ")), l.slice(l.indexOf(" ") + 1)];
                if (k === "gpu" && !medidor.pastaGpu) medidor.pastaGpu = v;
                else if (k === "cpu" && !medidor.sensorCpu) medidor.sensorCpu = v;
                else if (k === "gputemp" && !medidor.sensorGpu) medidor.sensorGpu = v;
                else if (k === "cg" && v) medidor.cgroupUsuario = "/sys/fs/cgroup" + v;
            }
        }
    }

    FileView { id: stat; path: "/proc/stat"; printErrors: false }
    FileView { id: meminfo; path: "/proc/meminfo"; printErrors: false }
    FileView { id: memApps; path: medidor.cgroupUsuario ? medidor.cgroupUsuario + "/app.slice/memory.stat" : ""; printErrors: false }
    FileView { id: memNyxz; path: medidor.cgroupUsuario ? medidor.cgroupUsuario + "/nyxz.slice/memory.stat" : ""; printErrors: false }
    FileView { id: gpuUso; path: medidor.pastaGpu ? medidor.pastaGpu + "/gpu_busy_percent" : ""; printErrors: false }
    FileView { id: vramUso; path: medidor.pastaGpu ? medidor.pastaGpu + "/mem_info_vram_used" : ""; printErrors: false }
    FileView { id: vramTot; path: medidor.pastaGpu ? medidor.pastaGpu + "/mem_info_vram_total" : ""; printErrors: false }
    FileView { id: tCpu; path: medidor.sensorCpu; printErrors: false }
    FileView { id: tGpu; path: medidor.sensorGpu; printErrors: false }

    function campo(texto, nome) {
        const m = texto.match(new RegExp("^" + nome + ":?\\s+(\\d+)", "m"));
        return m ? Number(m[1]) : 0;
    }
    function ler() {
        for (const f of [stat, meminfo, memApps, memNyxz, gpuUso, vramUso, vramTot, tCpu, tGpu]) if (f.path) f.reload();
        // CPU: tempo ocupado / tempo total desde a leitura anterior
        const c = (stat.text().split("\n")[0] || "").trim().split(/\s+/).slice(1).map(Number);
        if (c.length >= 4) {
            const ocioso = c[3] + (c[4] || 0), total = c.reduce((a, b) => a + b, 0);
            if (_cpuAntes) {
                const dt = total - _cpuAntes.total;
                if (dt > 0) cpu = Math.max(0, Math.min(100, 100 * (1 - (ocioso - _cpuAntes.ocioso) / dt)));
            }
            _cpuAntes = { ocioso, total };
        }
        const mi = meminfo.text();
        ramTotal = campo(mi, "MemTotal") * 1024;
        ramUsada = ramTotal - campo(mi, "MemAvailable") * 1024;
        swapUsada = (campo(mi, "SwapTotal") - campo(mi, "SwapFree")) * 1024;
        // RAM dos apps: memória própria (anon) + compartilhada, sem o cache de arquivos
        let apps = 0;
        for (const f of [memApps, memNyxz]) if (f.path) apps += campo(f.text(), "anon") + campo(f.text(), "shmem");
        ramApps = Math.min(apps, ramUsada);
        if (pastaGpu) {
            gpu = Number(gpuUso.text()) || 0;
            vramUsada = Number(vramUso.text()) || 0;
            vramTotal = Number(vramTot.text()) || 0;
        }
        tempCpu = sensorCpu ? (Number(tCpu.text()) || 0) / 1000 : -1;
        tempGpu = sensorGpu ? (Number(tGpu.text()) || 0) / 1000 : -1;
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: medidor.ler() }

    function gb(b) { return (b / 1073741824).toFixed(1).replace(".", ",") + " GB"; }
    function pct(v) { return Math.round(v) + "%"; }

    // Linhas e barrinhas do painel de detalhes
    component Item2: RowLayout {
        property string rotulo: ""
        property string valor: ""
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: parent.rotulo; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        Text { text: parent.valor; font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto }
    }
    component Barra2: Rectangle {
        property real fracao: 0
        property real fracao2: 0     // segunda parte (ex.: apps dentro da RAM usada)
        Layout.fillWidth: true
        Layout.preferredHeight: 4
        radius: 2
        color: Tema.trilho
        Rectangle { width: parent.width * Math.min(1, parent.fracao); height: parent.height; radius: 2; color: Tema.texto4 }
        Rectangle { width: parent.width * Math.min(1, parent.fracao2); height: parent.height; radius: 2; color: Tema.suave }
    }

    // ------------------------------------------------ na barra
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        radius: 6
        color: area.containsMouse ? Tema.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Tema.rapido } }
    }
    Row {
        id: linha
        anchors.centerIn: parent
        spacing: 12
        Repeater {
            model: [
                { r: "CPU", v: medidor.pct(medidor.cpu) + (medidor.tempCpu > 0 ? " " + Math.round(medidor.tempCpu) + "°" : "") },
                { r: "RAM", v: medidor.gb(medidor.ramUsada) },
                { r: "GPU", v: medidor.gpu >= 0 ? medidor.pct(medidor.gpu) + (medidor.tempGpu > 0 ? " " + Math.round(medidor.tempGpu) + "°" : "") : "" }
            ].filter(x => x.v)
            delegate: Row {
                required property var modelData
                spacing: 5
                Text { text: modelData.r; font.family: Tema.fonte; font.pixelSize: 10; color: Tema.texto3; anchors.verticalCenter: parent.verticalCenter }
                Text { text: modelData.v; font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto2; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true }

    // ------------------------------------------------ detalhes ao passar o mouse
    PopupWindow {
        visible: area.containsMouse
        anchor.item: medidor
        anchor.edges: medidor.emCima ? Edges.Bottom : Edges.Top
        anchor.gravity: medidor.emCima ? Edges.Bottom : Edges.Top
        anchor.margins.top: medidor.emCima ? 0 : -8
        anchor.margins.bottom: medidor.emCima ? -8 : 0
        implicitWidth: 260
        implicitHeight: detalhes.implicitHeight + 28
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Tema.raioPainel
            color: Tema.painel
            border.color: Tema.bordaPainel
            border.width: 1

            ColumnLayout {
                id: detalhes
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 7

                Item2 { rotulo: "Processador"; valor: medidor.pct(medidor.cpu) + (medidor.tempCpu > 0 ? " · " + Math.round(medidor.tempCpu) + " °C" : "") }
                Barra2 { fracao2: medidor.cpu / 100 }
                Item2 { Layout.topMargin: 6; rotulo: "Memória"; valor: medidor.gb(medidor.ramUsada) + " de " + medidor.gb(medidor.ramTotal) }
                Barra2 { fracao: medidor.ramTotal ? medidor.ramUsada / medidor.ramTotal : 0; fracao2: medidor.ramTotal ? medidor.ramApps / medidor.ramTotal : 0 }
                Item2 { rotulo: "   Apps"; valor: medidor.gb(medidor.ramApps) }
                Item2 { rotulo: "   Sistema (barra, serviços, kernel)"; valor: medidor.gb(Math.max(0, medidor.ramUsada - medidor.ramApps)) }
                Item2 { visible: medidor.swapUsada > 0; rotulo: "   Comprimida (zram)"; valor: medidor.gb(medidor.swapUsada) }
                Item2 {
                    visible: medidor.gpu >= 0
                    Layout.topMargin: 6
                    rotulo: "Placa de vídeo"
                    valor: medidor.pct(medidor.gpu) + (medidor.tempGpu > 0 ? " · " + Math.round(medidor.tempGpu) + " °C" : "")
                }
                Barra2 { visible: medidor.gpu >= 0; fracao2: medidor.gpu / 100 }
                Item2 { visible: medidor.vramTotal > 0; rotulo: "   Memória de vídeo"; valor: medidor.gb(medidor.vramUsada) + " de " + medidor.gb(medidor.vramTotal) }
            }
        }
    }
}
