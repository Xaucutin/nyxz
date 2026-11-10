pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Se alguma VPN está ligada (ícone na barra, interruptor no painel rápido) e se a
// LAN virtual tem rede ligada (interface zt* existe).
// "nmcli monitor" avisa de qualquer mudança na rede; só então a lista é conferida.
Singleton {
    property bool ligada: false
    property string nome: ""
    property bool temVpn: false     // há alguma VPN salva
    property bool lan: false        // alguma rede de jogo (ZeroTier) ligada

    function conferir() {
        if (!ativas.running) ativas.running = true;
        if (!salvas.running) salvas.running = true;
        if (!interfaces.running) interfaces.running = true;
    }
    function alternar() {
        Quickshell.execDetached(["/usr/libexec/nyxz/rede", "vpn", "alternar"]);
    }

    Process {
        id: ativas
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.split("\n").filter(x => /:(wireguard|vpn)$/.test(x));
                ligada = l.length > 0;
                nome = ligada ? l[0].replace(/:(wireguard|vpn)$/, "").replace(/\:/g, ":") : "";
            }
        }
    }
    Process {
        id: salvas
        command: ["nmcli", "-t", "-f", "TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: temVpn = this.text.split("\n").some(x => x === "wireguard" || x === "vpn")
        }
    }
    Process {
        id: interfaces
        command: ["ls", "/sys/class/net"]
        stdout: StdioCollector {
            onStreamFinished: lan = /(^|\s)zt/.test(this.text)
        }
    }
    // A interface do ZeroTier nem sempre gera aviso no NetworkManager
    Timer { interval: 10000; running: true; repeat: true; onTriggered: interfaces.running = true }
    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: _ => espera.restart() }
    }
    // Várias linhas chegam juntas numa troca de rede: confere uma vez só
    Timer { id: espera; interval: 600; onTriggered: conferir() }
    Component.onCompleted: conferir()
}
