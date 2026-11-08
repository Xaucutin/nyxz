import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Cofre de segredos (ideia 20): tokens de bot, chaves de API e senhas guardados no
// chaveiro do sistema (criptografado, destravado no login). A lista só mostra nomes.
// Os valores entram pela entrada padrão e saem direto para a área de transferência:
// nunca aparecem na tela nem na linha de comando.
Pagina {
    id: p
    titulo: "Cofre"
    descricao: "Tokens de bot, chaves de API e senhas, guardados criptografados no chaveiro do sistema. Ele se destrava sozinho quando você entra na Nyxz. As senhas dos bancos locais também ficam aqui."

    readonly property string cmd: "/usr/libexec/nyxz/nyxz-dev"
    property bool disponivel: true
    property var itens: []
    property string removendo: ""
    property string aviso: ""

    function atualizar() { listar.rodar([cmd, "cofre", "listar"]); }
    Component.onCompleted: atualizar()

    Comando {
        id: listar
        onPronto: s => {
            try { const d = JSON.parse(s); p.disponivel = d.disponivel; p.itens = d.itens; } catch (e) { p.itens = []; }
        }
    }
    Comando { id: acao; onPronto: p.atualizar() }

    // Guardar: o valor vai pela entrada padrão do processo
    Process {
        id: guardar
        stdinEnabled: true
        onRunningChanged: if (!running) { p.aviso = "Guardado."; p.atualizar(); limpar.restart(); }
    }
    Timer { id: limpar; interval: 2500; onTriggered: p.aviso = "" }

    Text {
        Layout.fillWidth: true
        visible: !p.disponivel
        text: "O chaveiro do sistema não está instalado nesta versão. Atualize a Nyxz para usar o cofre."
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.aviso
    }

    // ---------------------------------------------- guardar novo
    Text { text: "Guardar um segredo"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: nome; Layout.preferredWidth: 240; rotulo: "Nome (ex.: DISCORD_TOKEN)"; validador: /^[A-Za-z0-9._-]{1,64}$/ }
        Campo { id: valor; Layout.fillWidth: true; rotulo: "Valor"; oculto: true }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: "Guardar"
            principal: true
            ativo: p.disponivel && nome.aceito && nome.text.length > 0 && valor.text.length > 0 && !guardar.running
            onClicado: {
                guardar.command = [p.cmd, "cofre", "guardar", nome.text];
                guardar.running = true;
                guardar.write(valor.text);
                guardar.closeStdin();
                nome.text = ""; valor.text = "";
            }
        }
    }
    Text {
        visible: p.aviso !== ""
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.ok
    }

    // ---------------------------------------------- segredos guardados
    Text {
        Layout.topMargin: 14
        text: p.itens.length ? "Guardados" : "Nenhum segredo guardado ainda."
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Repeater {
        model: p.itens
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Text { text: "••••"; font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto4 }
            Text {
                Layout.fillWidth: true
                text: modelData.nome
                font.family: Tema.fonteMono; font.pixelSize: 13; color: Tema.texto
            }
            Botao {
                texto: "Copiar"
                // O valor vai do cofre direto para a área de transferência
                onClicado: {
                    Quickshell.execDetached(["sh", "-c", '"$0" cofre ler "$1" | wl-copy', p.cmd, modelData.nome]);
                    p.aviso = "Copiado. Cole onde precisar.";
                    limpar.restart();
                }
            }
            Botao {
                visible: p.removendo !== modelData.nome
                texto: "Remover"
                onClicado: p.removendo = modelData.nome
            }
            Botao {
                visible: p.removendo === modelData.nome
                texto: "Confirmar remoção"
                perigo: true
                onClicado: { acao.rodar([p.cmd, "cofre", "remover", modelData.nome]); p.removendo = ""; }
            }
        }
    }
}
