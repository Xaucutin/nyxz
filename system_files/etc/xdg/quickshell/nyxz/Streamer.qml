pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Modo streamer (ideia 29): liga sozinho quando a tela está sendo transmitida ou gravada
// (captura pelo portal, Nyxz Share) ou com o OBS aberto; também dá para ligar
// na mão. Enquanto ativo: guarda as notificações, cobre janelas com segredos (VeuStreamer)
// e as Configurações escondem IPs e senhas (marca $XDG_RUNTIME_DIR/nyxz-streamer).
Singleton {
    id: s

    property bool manual: false
    // Captura de tela pelo portal do Hyprland: fonte de vídeo "xdph-…"
    readonly property bool capturando: Pipewire.nodes.values.some(n => !n.isStream && n.audio === null && (n.name || "").indexOf("xdph") === 0)
    readonly property bool obs: ToplevelManager.toplevels.values.some(t => /obs/i.test(t.appId || ""))
    readonly property bool automatico: cfg.auto && (capturando || obs || JogoEstado.share)
    // Desligado na mão enquanto a captura continua: fica desligado até ela acabar
    property bool pausado: false
    onAutomaticoChanged: if (!automatico) pausado = false
    readonly property bool ativo: manual || (automatico && !pausado)
    readonly property string motivo: manual ? "ligado na mão" : obs ? "OBS aberto" : JogoEstado.share ? "Nyxz Share" : capturando ? "tela sendo capturada" : ""

    readonly property bool ocultaNotificacoes: ativo && cfg.notificacoes
    readonly property var palavras: cfg.palavras
    readonly property var janelas: cfg.janelas

    function alternar() {
        if (ativo) { manual = false; pausado = automatico; }
        else { manual = true; pausado = false; }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/streamer.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        JsonAdapter {
            id: cfg
            property bool auto: true
            property bool notificacoes: true
            // Títulos de janela que são cobertos (sem diferenciar maiúsculas)
            property var palavras: [".env", "senha", "password", "cofre", "secret", "token", "keepass", "bitwarden", "1password", "chaveiro"]
            // Apps sempre cobertos (classe da janela contém…)
            property var janelas: ["keepassxc", "bitwarden", "seahorse"]
        }
    }

    // As Configurações (outro processo) olham esta marca para esconder IPs e senhas
    onAtivoChanged: {
        const marca = Quickshell.env("XDG_RUNTIME_DIR") + "/nyxz-streamer";
        Quickshell.execDetached(["sh", "-c", ativo ? "echo \"$2\" > \"$1\"" : "rm -f \"$1\"", "sh", marca, motivo]);
    }
    Component.onCompleted: Quickshell.execDetached(["rm", "-f", Quickshell.env("XDG_RUNTIME_DIR") + "/nyxz-streamer"])
}
