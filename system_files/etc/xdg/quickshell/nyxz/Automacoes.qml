import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Motor das Automações (ideia 23): percebe os gatilhos dentro do próprio shell, sem
// serviço extra, e chama /usr/libexec/nyxz/automacoes executar <id> para fazer as ações.
// Eventos: Hyprland (apps e telas), Modo jogo, udev (aparelhos); o resto é conferido
// a cada 20 s (horário, rede, memória) ou 2 min (baterias). Sem automações ligadas,
// nada disso roda.
Scope {
    id: motor
    readonly property string cmd: "/usr/libexec/nyxz/automacoes"
    property var lista: []
    readonly property var ligadas: lista.filter(a => a.ligada !== false)
    readonly property bool ativo: ligadas.length > 0
    function usa(tipo) { return ligadas.some(a => a.quando && a.quando.tipo === tipo); }

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/automacoes.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { motor.lista = JSON.parse(text()).automacoes || []; } catch (e) { motor.lista = []; } }
        onLoadFailed: motor.lista = []
    }

    function disparar(a, motivo) {
        console.log("[nyxz] automação:", a.nome, "(" + motivo + ")");
        Quickshell.execDetached([cmd, "executar", a.id, motivo]);
    }
    function contem(texto, procurado) {
        return !procurado || String(texto).toLowerCase().indexOf(String(procurado).toLowerCase()) >= 0;
    }
    // Dispara todas as automações ligadas de um tipo que aceitarem o evento
    function evento(tipo, aceita, motivo) {
        for (const a of ligadas)
            if (a.quando && a.quando.tipo === tipo && aceita(a.quando)) disparar(a, motivo);
    }

    // ------------------------------------------------ ao entrar
    property bool entrou: false
    Timer {
        interval: 6000; running: motor.ativo && !motor.entrou
        onTriggered: { motor.entrou = true; motor.evento("ao_entrar", q => true, "entrou na sessão"); }
    }

    // ------------------------------------------------ horário, rede, memória (a cada 20 s)
    property string ultimoMinuto: ""
    property var redes: null            // conexões ativas da última conferida
    property var ramAcima: ({})          // id -> já disparou (volta a valer abaixo do limite - 5)
    Timer {
        interval: 20000; running: motor.ativo; repeat: true; triggeredOnStart: true
        onTriggered: {
            const agora = new Date();
            const hm = Qt.formatTime(agora, "HH:mm");
            if (hm !== motor.ultimoMinuto) {
                motor.ultimoMinuto = hm;
                const dia = agora.getDay();     // 0 = domingo
                motor.evento("horario", q => q.hora === hm && (!q.dias || !q.dias.length || q.dias.indexOf(dia) >= 0), "às " + hm);
            }
            if (motor.usa("rede_conectou") || motor.usa("rede_desconectou")) redesProc.running = true;
            if (motor.usa("ram_alta")) meminfo.reload();
        }
    }
    Process {
        id: redesProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const agora = this.text.split("\n").filter(x => x && x !== "lo");
                const antes = motor.redes;
                motor.redes = agora;
                if (antes === null) return;      // primeira conferida: só guarda
                for (const n of agora.filter(x => antes.indexOf(x) < 0))
                    motor.evento("rede_conectou", q => motor.contem(n, q.nome), "conectou em " + n);
                for (const n of antes.filter(x => agora.indexOf(x) < 0))
                    motor.evento("rede_desconectou", q => motor.contem(n, q.nome), "desconectou de " + n);
            }
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: {
            const t = text();
            const total = parseInt((t.match(/MemTotal:\s+(\d+)/) || [0, 1])[1]);
            const livre = parseInt((t.match(/MemAvailable:\s+(\d+)/) || [0, 0])[1]);
            const uso = Math.round(100 * (total - livre) / total);
            const m = Object.assign({}, motor.ramAcima);
            for (const a of motor.ligadas) {
                if (!a.quando || a.quando.tipo !== "ram_alta") continue;
                const limite = a.quando.limite || 90;
                if (uso >= limite && !m[a.id]) { m[a.id] = true; motor.disparar(a, "memória em " + uso + "%"); }
                else if (uso < limite - 5) m[a.id] = false;
            }
            motor.ramAcima = m;
        }
    }

    // ------------------------------------------------ baterias (a cada 2 min)
    property var bateriaBaixa: ({})
    Timer {
        interval: 120000; running: motor.usa("bateria_baixa"); repeat: true; triggeredOnStart: true
        onTriggered: bateriasProc.running = true
    }
    Process {
        id: bateriasProc
        command: [motor.cmd, "baterias"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lista = [];
                try { lista = JSON.parse(this.text); } catch (e) { return; }
                const m = Object.assign({}, motor.bateriaBaixa);
                for (const a of motor.ligadas) {
                    if (!a.quando || a.quando.tipo !== "bateria_baixa") continue;
                    const limite = a.quando.limite || 20;
                    for (const b of lista.filter(b => motor.contem(b.nome, a.quando.nome))) {
                        const chave = a.id + "|" + b.nome;
                        if (b.bateria <= limite && !m[chave]) { m[chave] = true; motor.disparar(a, b.nome + " com " + b.bateria + "%"); }
                        else if (b.bateria > limite + 5) m[chave] = false;
                    }
                }
                motor.bateriaBaixa = m;
            }
        }
    }

    // ------------------------------------------------ apps e telas (eventos do Hyprland)
    property var janelas: ({})          // endereço -> classe
    function contar(classe) {
        let n = 0;
        for (const k in janelas) if (janelas[k] === classe) n++;
        return n;
    }
    Process {
        id: clientes
        running: motor.usa("app_abriu") || motor.usa("app_fechou")
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                try { for (const c of JSON.parse(this.text)) m[c.address.replace(/^0x/, "")] = c.class; } catch (e) {}
                motor.janelas = m;
            }
        }
    }
    Connections {
        target: Hyprland
        enabled: motor.ativo
        function onRawEvent(ev) {
            if (ev.name === "openwindow") {
                const p = ev.data.split(",");
                const classe = p[2] || "";
                const m = Object.assign({}, motor.janelas);
                const primeira = motor.contar(classe) === 0;
                m[p[0]] = classe;
                motor.janelas = m;
                if (primeira && classe) motor.evento("app_abriu", q => motor.contem(classe, q.app) && !!q.app, classe + " abriu");
            } else if (ev.name === "closewindow") {
                const classe = motor.janelas[ev.data];
                if (classe === undefined) return;
                const m = Object.assign({}, motor.janelas);
                delete m[ev.data];
                motor.janelas = m;
                if (motor.contar(classe) === 0) motor.evento("app_fechou", q => motor.contem(classe, q.app) && !!q.app, classe + " fechou");
            } else if (ev.name === "monitoraddedv2" || ev.name === "monitoradded") {
                const nome = ev.name === "monitoraddedv2" ? ev.data.split(",").slice(1).join(" ") : ev.data;
                if (ev.name === "monitoradded" && motor.usouV2) return;
                if (ev.name === "monitoraddedv2") motor.usouV2 = true;
                motor.evento("monitor_conectado", q => motor.contem(nome, q.nome), "tela " + nome);
            }
        }
    }
    property bool usouV2: false

    // ------------------------------------------------ Modo jogo
    Connections {
        target: JogoEstado
        enabled: motor.ativo
        function onModoJogoChanged() {
            if (JogoEstado.modoJogo) motor.evento("jogo_comecou", q => true, "jogo começou");
            else motor.evento("jogo_terminou", q => true, "jogo terminou");
        }
    }

    // ------------------------------------------------ aparelhos (udev)
    property var aparelhos: null
    Process {
        id: udev
        running: motor.usa("dispositivo_conectado") || motor.usa("dispositivo_desconectado")
        command: ["udevadm", "monitor", "--udev", "-s", "input", "-s", "block", "-s", "sound", "-s", "bluetooth"]
        stdout: SplitParser {
            onRead: linha => { if (/\s(add|remove)\s/.test(linha)) esperaUdev.restart(); }
        }
        onRunningChanged: if (running) aparelhosProc.running = true
    }
    // Um aparelho gera vários eventos seguidos: espera acalmar e compara a lista
    Timer { id: esperaUdev; interval: 2500; onTriggered: aparelhosProc.running = true }
    Process {
        id: aparelhosProc
        command: [motor.cmd, "dispositivos"]
        stdout: StdioCollector {
            onStreamFinished: {
                let agora = [];
                try { agora = JSON.parse(this.text); } catch (e) { return; }
                const antes = motor.aparelhos;
                motor.aparelhos = agora;
                if (antes === null) return;
                const chave = d => d.tipo + "|" + d.nome;
                const ka = antes.map(chave), kn = agora.map(chave);
                const aceita = d => q => (!q.aparelho || q.aparelho === "qualquer" || q.aparelho === d.tipo) && motor.contem(d.nome, q.nome);
                for (const d of agora.filter(d => ka.indexOf(chave(d)) < 0))
                    motor.evento("dispositivo_conectado", aceita(d), d.nome + " conectado");
                for (const d of antes.filter(d => kn.indexOf(chave(d)) < 0))
                    motor.evento("dispositivo_desconectado", aceita(d), d.nome + " desconectado");
            }
        }
    }
}
