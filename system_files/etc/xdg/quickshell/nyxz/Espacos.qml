pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Espaços com nome (ideia 31): cada área de trabalho pode ter nome e papel de parede
// próprio. Gravados pelas Configurações → Espaços em ~/.config/nyxz/espacos.json.
Singleton {
    id: espacos

    readonly property var lista: cfg.espacos

    FileView {
        path: Quickshell.env("HOME") + "/.config/nyxz/espacos.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        JsonAdapter {
            id: cfg
            property var espacos: []   // [{ numero, nome, papel }]
        }
    }

    function de(numero) {
        return cfg.espacos.find(e => e.numero === numero) || null;
    }
    function nome(numero) {
        const e = de(numero);
        return e && e.nome ? e.nome : "";
    }
    function papel(numero) {
        const e = de(numero);
        return e && e.papel ? e.papel : "";
    }
}
