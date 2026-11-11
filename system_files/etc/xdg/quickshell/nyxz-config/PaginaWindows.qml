import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Convivência com o Windows (ideia 12): reiniciar no Windows, entrada no menu de boot,
// relógio certo nos dois sistemas e partições NTFS (só leitura por padrão, aviso do
// Início rápido). Por baixo: /usr/libexec/nyxz/nyxz-dualboot-root (pkexec, sem senha).
Pagina {
    id: p
    titulo: "Windows (dual boot)"
    descricao: "Para quem tem o Windows no mesmo computador: reiniciar direto nele, escolher no menu de boot, relógio certo nos dois e acesso às partições do Windows pelo Dolphin."

    readonly property var root: ["pkexec", "/usr/libexec/nyxz/nyxz-dualboot-root"]
    property var e: null
    property string aviso: ""
    property bool avisoErro: false
    property bool confirmarReinicio: false

    function atualizar() { cmd.rodar(root.concat(["verificar"])); }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    Component.onCompleted: atualizar()
    Timer { id: limpa; interval: 8000; onTriggered: p.aviso = "" }
    function tam(b) { return (b / 1e9).toFixed(0) + " GB"; }

    Process {
        id: cmd
        property string ok: ""
        stdout: StdioCollector { id: saida }
        stderr: StdioCollector { id: erro }
        onExited: codigo => {
            if (codigo === 0) {
                try { const t = saida.text.trim(); if (t) p.e = JSON.parse(t.split("\n").pop()); } catch (x) {}
                if (cmd.ok) p.avisar(cmd.ok, false);
            } else p.avisar(erro.text.trim() || "Não deu certo.", true);
        }
        function rodar(c, msg) { if (running) return; ok = msg || ""; command = c; running = true; }
    }

    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }
    Text {
        visible: p.e === null
        text: "Procurando o Windows…"
        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto3
    }

    // ------------------------------------------------ Windows
    RowLayout {
        visible: p.e !== null
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: p.e && p.e.windows ? "Windows encontrado" : "Nenhum Windows neste computador"; font.family: Tema.fonte; font.pixelSize: 15; font.weight: Font.Medium; color: Tema.texto }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: p.e && p.e.windows ? "\"Reiniciar no Windows\" também aparece na busca (Super)." : "Se instalar o Windows depois, esta página encontra sozinha."
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
            }
        }
        Botao {
            visible: p.e && p.e.windows && !p.confirmarReinicio
            texto: "Reiniciar no Windows"
            principal: true
            onClicado: p.confirmarReinicio = true
        }
        Botao {
            visible: p.confirmarReinicio
            texto: "Confirmar (salve o que estiver aberto)"
            perigo: true
            onClicado: { p.confirmarReinicio = false; cmd.rodar(p.root.concat(["reiniciar-windows"]), "Reiniciando…"); }
        }
    }

    // ------------------------------------------------ ajustes
    ColumnLayout {
        visible: p.e !== null && p.e.windows
        Layout.topMargin: 8
        Layout.fillWidth: true
        spacing: 12
        Opcao {
            titulo: "Windows no menu de boot"
            detalhe: "Mostra o menu ao ligar o PC por alguns segundos, com a opção \"Windows\"."
            ligado: p.e ? p.e.grub : false
            onAlternado: v => cmd.rodar(p.root.concat(["grub", v ? "ligar" : "desligar"]), v ? "O Windows aparece no menu de boot." : "Entrada do Windows removida.")
        }
        Opcao {
            titulo: "Relógio em horário local"
            detalhe: "O Windows guarda a hora local na placa-mãe. Ligado, a hora fica certa nos dois sistemas (sem o erro de 3 horas)."
            ligado: p.e ? p.e.relogioLocal : false
            onAlternado: v => cmd.rodar(p.root.concat(["relogio", v ? "local" : "utc"]), "Relógio ajustado.")
        }
        Opcao {
            titulo: "Gravar nas partições do Windows"
            detalhe: "Desligado, o Dolphin abre as partições do Windows só para leitura (mais seguro). Ligado, dá para copiar arquivos para elas."
            ligado: p.e ? p.e.escrita : false
            onAlternado: v => cmd.rodar(p.root.concat(["escrita", v ? "ligar" : "desligar"]), "Vale na próxima vez que abrir a partição.")
        }
    }

    // ------------------------------------------------ partições NTFS
    Text {
        visible: p.e !== null && p.e.ntfs.length > 0
        Layout.topMargin: 12
        text: "Partições do Windows"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Repeater {
        model: p.e ? p.e.ntfs : []
        delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: (modelData.rotulo || modelData.caminho) + "  ·  " + p.tam(modelData.tamanho) + (modelData.montada.length ? "  ·  aberta em " + modelData.montada[0] : "")
                font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
            }
            Text {
                visible: modelData.estado !== ""
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: modelData.estado === "hibernado"
                      ? "O \"Início rápido\" do Windows está ligado: a partição fica travada e só abre para leitura. No Windows: Painel de Controle → Opções de energia → \"Escolher a função dos botões de energia\" → desmarque \"Ligar inicialização rápida\"."
                      : "O Windows não fechou direito esta partição. Abra o Windows e desligue normalmente (ou rode chkdsk) antes de gravar nela."
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.aviso
            }
        }
    }

    component Opcao: RowLayout {
        id: o
        property string titulo: ""
        property string detalhe: ""
        property bool ligado: false
        signal alternado(bool v)
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { Layout.fillWidth: true; text: o.titulo; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: o.detalhe; font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3 }
        }
        Interruptor { ligado: o.ligado; onAlternado: v => o.alternado(v) }
    }
}
