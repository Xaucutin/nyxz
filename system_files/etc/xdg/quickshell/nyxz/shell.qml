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

    PapelDeParede {}
    Busca {}
    Notificacoes {}
    PainelSom {}
    PainelRapido {}
    ColaAtalhos {}
    MenuTarefa {}

    // Janela de senha de administrador (polkit). Fica num Loader: se o Quickshell
    // instalado não tiver o módulo de polkit, só ela falha, e o agente antigo
    // (/usr/libexec/nyxz/polkit-agent) é ligado como reserva.
    Loader {
        id: senha
        source: "AgenteSenha.qml"
    }
    Timer {
        interval: 4000
        running: true
        onTriggered: {
            if (senha.status !== Loader.Ready || !senha.item.registrado) {
                console.warn("[nyxz] agente de senha próprio indisponível; usando o de reserva");
                Quickshell.execDetached(["/usr/libexec/nyxz/polkit-agent"]);
            }
        }
    }

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
        target: "atalhos"
        function alternar(): void {
            const abrir = !Estado.atalhosAberto;
            Estado.fecharTudo();
            Estado.atalhosAberto = abrir;
        }
    }

    IpcHandler {
        target: "rapido"
        function alternar(): void {
            const abrir = !Estado.rapidoAberto;
            Estado.fecharTudo();
            Estado.rapidoAberto = abrir;
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
