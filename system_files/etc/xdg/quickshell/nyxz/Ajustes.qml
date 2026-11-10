pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Ajustes da Nyxz (os "mods" do Windhawk como opções nativas, PROJETO.md).
// Gravados pelas Configurações → Ajustes em ~/.config/nyxz/ajustes.json; o shell
// acompanha o arquivo e muda na hora, sem reiniciar nada.
Singleton {
    readonly property bool miniPlayer: cfg.miniPlayer
    readonly property bool previa: cfg.previa
    readonly property int atrasoPrevia: cfg.atrasoPrevia
    readonly property bool volumeNaRoda: cfg.volumeNaRoda
    readonly property bool titulosLimpos: cfg.titulosLimpos
    readonly property bool privacidade: cfg.privacidade
    readonly property bool barraEmCima: cfg.barraEmCima
    readonly property bool iconesCrescem: cfg.iconesCrescem
    readonly property bool medidor: cfg.medidor
    readonly property string cantoNotificacoes: cfg.cantoNotificacoes

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/ajustes.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        JsonAdapter {
            id: cfg
            // Padrões: os mesmos da tabela de Ajustes no PROJETO.md.
            property bool miniPlayer: true
            property bool previa: true
            property int atrasoPrevia: 0
            property bool volumeNaRoda: true
            property bool titulosLimpos: true
            property bool privacidade: true
            property bool barraEmCima: false
            property bool iconesCrescem: false
            property bool medidor: false
            property string cantoNotificacoes: "superior-direito"
            // Lidos só pelo Hyprland (ajustes.lua), guardados aqui para a tela
            property int bordaJanela: 1
            property string teclaArrastar: "SUPER"
        }
    }
}
