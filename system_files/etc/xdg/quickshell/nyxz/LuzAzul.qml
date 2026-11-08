pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Filtro de luz azul (ideia 11): desligado, ligado ou no horário escolhido.
// Guarda a escolha em ~/.config/nyxz/painel.json; quem liga é /usr/libexec/nyxz/luz-azul.
Singleton {
    id: luz

    readonly property string modo: cfg.modo
    readonly property int temperatura: cfg.temperatura
    readonly property string inicio: cfg.inicio
    readonly property string fim: cfg.fim
    property bool ativo: false

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/painel.json"
        printErrors: false
        onAdapterUpdated: writeAdapter()
        onLoaded: luz.aplicar()
        JsonAdapter {
            id: cfg
            property string modo: "desligado"   // desligado | ligado | horario
            property int temperatura: 4500
            property string inicio: "20:00"
            property string fim: "06:30"
        }
    }

    function minutos(hhmm) {
        const p = (hhmm || "0:0").split(":");
        return parseInt(p[0]) * 60 + parseInt(p[1] || 0);
    }

    function deveLigar() {
        if (cfg.modo === "ligado") return true;
        if (cfg.modo !== "horario") return false;
        const d = new Date();
        const agora = d.getHours() * 60 + d.getMinutes();
        const a = minutos(cfg.inicio), b = minutos(cfg.fim);
        // Faixa que passa da meia-noite (ex.: 20:00 → 06:30)
        return a <= b ? (agora >= a && agora < b) : (agora >= a || agora < b);
    }

    function aplicar() {
        const ligar = deveLigar();
        if (ligar) Quickshell.execDetached(["/usr/libexec/nyxz/luz-azul", "ligar", String(cfg.temperatura)]);
        else Quickshell.execDetached(["/usr/libexec/nyxz/luz-azul", "desligar"]);
        ativo = ligar;
    }

    function definirModo(m) {
        cfg.modo = m;
        aplicar();
    }

    function definirTemperatura(t) {
        cfg.temperatura = t;
        temperaturaNova.restart();
    }

    // Arrastar o controle manda muitos valores: aplica um pouco depois de parar.
    Timer {
        id: temperaturaNova
        interval: 150
        onTriggered: if (luz.ativo) luz.aplicar()
    }

    // No modo "horário", confere uma vez por minuto.
    Timer {
        interval: 60000
        repeat: true
        running: cfg.modo === "horario"
        onTriggered: if (luz.deveLigar() !== luz.ativo) luz.aplicar()
    }
}
