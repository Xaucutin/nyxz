import QtQuick
import QtQuick.Layouts
import Quickshell

// Atualizações: versão atual, versão pronta para o próximo boot,
// procurar agora e voltar para a versão anterior. Nada exige terminal.
Pagina {
    id: p
    titulo: "Atualizações"
    descricao: "A Nyxz baixa as atualizações sozinha em segundo plano e aplica no próximo boot. Ela nunca reinicia o PC sem você pedir."

    property var atual: null
    property var proxima: null
    property var anterior: null
    property string estado: ""      // "", "procurando", "voltando"
    property string mensagem: ""

    function dataDe(d) {
        if (!d || !d.timestamp) return "";
        return new Date(d.timestamp * 1000).toLocaleString(Qt.locale("pt_BR"), "d 'de' MMMM, HH:mm");
    }

    function versaoDe(d) {
        return d ? (d.version || d["container-image-reference-digest"] || "?") : "";
    }

    Comando {
        id: status
        onPronto: (saida, codigo) => {
            try {
                const lista = JSON.parse(saida).deployments || [];
                const iBoot = lista.findIndex(d => d.booted);
                p.atual = iBoot >= 0 ? lista[iBoot] : null;
                p.proxima = iBoot > 0 ? lista[0] : null;
                p.anterior = iBoot >= 0 && iBoot + 1 < lista.length ? lista[iBoot + 1] : null;
            } catch (e) {
                p.mensagem = "Não foi possível ler o estado das atualizações.";
            }
        }
    }
    Component.onCompleted: status.rodar(["rpm-ostree", "status", "--json"])

    Comando {
        id: acao
        onPronto: (saida, codigo) => {
            if (p.estado === "procurando")
                p.mensagem = codigo === 0
                    ? (saida.includes("No changes") || saida.includes("No update") || saida.includes("No upgrade") ? "Você já está na versão mais nova." : "Atualização baixada. Reinicie para aplicar.")
                    : "Não foi possível procurar atualizações. Verifique a internet e tente de novo.";
            else if (p.estado === "voltando")
                p.mensagem = codigo === 0 ? "Pronto: a versão anterior volta no próximo boot. Reinicie para aplicar." : "Não foi possível voltar a versão.";
            p.estado = "";
            status.rodar(["rpm-ostree", "status", "--json"]);
        }
    }

    // Versão atual
    Text {
        text: "Versão em uso"
        font.family: Tema.fonte
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Tema.texto3
    }
    Linha { rotulo: "Versão"; valor: p.versaoDe(p.atual); mono: true }
    Linha { rotulo: "Instalada em"; valor: p.dataDe(p.atual) }

    // Próxima versão (já baixada)
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.preferredHeight: proximaCol.implicitHeight + 28
        visible: p.proxima !== null
        radius: Tema.raio
        color: Tema.painel
        border.color: Tema.bordaPainel
        border.width: 1
        ColumnLayout {
            id: proximaCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 6
            Text {
                text: "Nova versão pronta: " + p.versaoDe(p.proxima)
                font.family: Tema.fonte
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Tema.texto
            }
            Text {
                text: "Ela entra no próximo boot. Seus arquivos e apps continuam como estão."
                font.family: Tema.fonte
                font.pixelSize: 12
                color: Tema.texto3
            }
            Botao {
                Layout.topMargin: 4
                texto: "Reiniciar agora"
                principal: true
                onClicado: Quickshell.execDetached(["systemctl", "reboot"])
            }
        }
    }

    RowLayout {
        Layout.topMargin: 16
        spacing: 8
        Botao {
            texto: p.estado === "procurando" ? "Procurando…" : "Procurar atualizações"
            ativo: p.estado === ""
            onClicado: {
                p.estado = "procurando";
                p.mensagem = "";
                // Com apps nativos escolhidos, o rpm-ostree baixa só o que mudou e reaplica os apps.
                acao.rodar(["pkexec", "/usr/libexec/nyxz/atualizar"]);
            }
        }
        Botao {
            texto: "Voltar para a versão anterior"
            ativo: p.estado === "" && p.anterior !== null
            onClicado: {
                p.estado = "voltando";
                p.mensagem = "";
                acao.rodar(["pkexec", "bootc", "rollback"]);
            }
        }
    }
    Text {
        Layout.fillWidth: true
        Layout.topMargin: 4
        visible: p.mensagem.length > 0
        text: p.mensagem
        font.family: Tema.fonte
        font.pixelSize: 13
        color: Tema.suave
        wrapMode: Text.Wrap
    }
    Text {
        Layout.fillWidth: true
        Layout.topMargin: 8
        visible: p.anterior !== null
        text: "Versão anterior disponível: " + p.versaoDe(p.anterior) + " (" + p.dataDe(p.anterior) + "). Se algo der errado depois de atualizar, dá para voltar para ela aqui ou no menu de boot."
        font.family: Tema.fonte
        font.pixelSize: 12
        color: Tema.texto3
        wrapMode: Text.Wrap
    }
}
