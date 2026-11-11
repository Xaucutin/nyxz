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
            property var espacos: []   // [{ numero, nome, papel, silencio, apps }]
        }
    }

    function de(numero) {
        return cfg.espacos.find(e => e.numero === numero) || null;
    }
    function nome(numero) {
        const e = de(numero);
        return e && e.nome ? e.nome : "";
    }
    // Não perturbe por espaço: "tudo" silencia todas; "apps" só as dos apps listados
    function silenciado(numero, app) {
        const e = de(numero);
        if (!e || !e.silencio || e.silencio === "nenhum") return false;
        if (e.silencio === "tudo") return true;
        const a = String(app || "").toLowerCase();
        return !!a && String(e.apps || "").split(",").map(x => x.trim().toLowerCase()).some(x => x && a.indexOf(x) >= 0);
    }
    function papel(numero) {
        const e = de(numero);
        return e && e.papel ? e.papel : "";
    }
}
