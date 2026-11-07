//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
import QtQuick
import Quickshell
import Quickshell.Io

// Shell da Nyxz: barra, busca, notificações e painéis.
ShellRoot {
    Variants {
        model: Quickshell.screens
        Barra {
            required property var modelData
            screen: modelData
        }
    }

    Busca {}
    Notificacoes {}
    PainelSom {}
    MenuTarefa {}

    // Atalhos do Hyprland chamam estas funções:
    //   qs -c nyxz ipc call busca alternar
    IpcHandler {
        target: "busca"
        function alternar(): void {
            const abrir = !Estado.buscaAberta;
            Estado.fecharTudo();
            Estado.buscaAberta = abrir;
        }
    }

    IpcHandler {
        target: "som"
        function alternar(): void {
            const abrir = !Estado.somAberto;
            Estado.fecharTudo();
            Estado.somAberto = abrir;
        }
    }
}
