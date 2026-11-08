import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// Fundo da área de trabalho em cada monitor.
// - imagem: desenhada aqui mesmo (sem processo extra);
// - vídeo: quem desenha é o mpvpaper (camada de fundo); aqui fica transparente;
// - cor: a cor de fundo da Nyxz.
// A escolha fica em ~/.config/nyxz/papel-de-parede.json (gravada pelas
// Configurações ou pelo Dolphin, via /usr/libexec/nyxz/papel-de-parede).
Scope {
    id: raiz

    // Espaço com papel de parede próprio (Configurações → Espaços) vence o geral.
    readonly property int espacoAtual: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    readonly property string papelDoEspaco: Espacos.papel(espacoAtual)
    readonly property string tipo: papelDoEspaco ? "imagem" : cfg.tipo
    readonly property string arquivoAtual: papelDoEspaco || cfg.arquivo

    FileView {
        id: arquivo
        path: Quickshell.env("HOME") + "/.config/nyxz/papel-de-parede.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        JsonAdapter {
            id: cfg
            property string tipo: "cor"
            property string arquivo: ""
            property string ajuste: "preencher"
        }
    }

    // No login, religa o vídeo se for o caso.
    Component.onCompleted: Quickshell.execDetached(["/usr/libexec/nyxz/papel-de-parede", "aplicar"])

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "nyxz-papel-de-parede"
            // Com vídeo, o mpvpaper desenha por baixo: esta janela some.
            visible: raiz.tipo !== "video"
            color: Tema.fundo

            Image {
                id: imagem
                anchors.fill: parent
                visible: raiz.tipo === "imagem"
                source: raiz.tipo === "imagem" && raiz.arquivoAtual ? "file://" + raiz.arquivoAtual : ""
                asynchronous: true
                cache: false
                // Decodifica no tamanho da tela, não no tamanho original do arquivo (RAM).
                // (o Qt respeita o modo de encaixe ao reduzir; "centralizar" usa o tamanho original).
                sourceSize: cfg.ajuste === "centralizar" ? undefined : Qt.size(width, height)
                fillMode: cfg.ajuste === "ajustar" ? Image.PreserveAspectFit
                        : cfg.ajuste === "centralizar" ? Image.Pad
                        : Image.PreserveAspectCrop
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Tema.medio; easing.type: Easing.BezierSpline; easing.bezierCurve: Tema.curva } }
            }
        }
    }
}
