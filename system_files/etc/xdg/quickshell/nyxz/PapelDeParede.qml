import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Fundo da área de trabalho em cada monitor.
// - imagem: desenhada aqui mesmo (sem processo extra);
// - vídeo: quem desenha é o mpvpaper (camada de fundo); aqui fica transparente;
// - cor: a cor de fundo da Nyxz.
// A escolha fica em ~/.config/nyxz/papel-de-parede.json (gravada pelas
// Configurações ou pelo Dolphin, via /usr/libexec/nyxz/papel-de-parede).
Scope {
    id: raiz

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
            visible: cfg.tipo !== "video"
            color: Tema.fundo

            Image {
                id: imagem
                anchors.fill: parent
                visible: cfg.tipo === "imagem"
                source: cfg.tipo === "imagem" && cfg.arquivo ? "file://" + cfg.arquivo : ""
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
