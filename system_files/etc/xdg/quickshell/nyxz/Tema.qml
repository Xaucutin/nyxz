pragma Singleton
import QtQuick
import Quickshell

// Tokens visuais da Nyxz (mesmos da maquete e do protótipo).
Singleton {
    readonly property color fundo: "#09090D"
    readonly property color barra: "#0C0C10"
    readonly property color painel: "#0F0F13"
    readonly property color elevado: "#131318"
    readonly property color hover: "#17171C"
    readonly property color selecionado: "#1C1C22"
    readonly property color borda: "#1E1E25"
    readonly property color bordaPainel: "#23232A"
    readonly property color texto: "#F4F2F8"
    readonly property color texto2: "#A09EAA"
    readonly property color texto3: "#64626E"
    readonly property color texto4: "#4C4A55"
    readonly property color suave: "#CFCDD6"
    readonly property color trilho: "#24242B"
    readonly property color ok: "#7FB894"
    readonly property color aviso: "#C9A86A"
    readonly property color erro: "#D0676A"
    readonly property color perigoFundo: "#1A1215"

    readonly property string fonte: "Geist"
    readonly property string fonteMono: "Geist Mono"

    readonly property int raio: 8
    readonly property int raioPainel: 10

    // Movimento estilo Lenis: curva exponencial, chega rápido e assenta sem rebote.
    readonly property var curva: [0.16, 1, 0.3, 1, 1, 1]
    readonly property int rapido: 140
    readonly property int medio: 450
}
