import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Backup automático (ideia 10): restic para um HD externo ou para a nuvem (Google Drive
// pelo rclone), em horário marcado, com restauração de arquivo por data.
// Por baixo: /usr/libexec/nyxz/backup. A senha do backup fica no Cofre.
Pagina {
    id: p
    titulo: "Backup"
    descricao: "Cópia dos seus projetos e documentos para um HD externo ou para a nuvem, todo dia no horário escolhido. Só o que mudou é enviado, e dá para recuperar um arquivo de qualquer dia guardado."

    readonly property string cmd: "/usr/libexec/nyxz/backup"
    property var e: null
    property var pastas: []
    property string tipo: "pasta"
    property string aviso: ""
    property bool avisoErro: false
    property string progresso: ""
    property string senha: ""
    property var achados: []
    property var discos: []

    function atualizar() { cmdEstado.rodar([cmd, "estado"]); cmdDiscos.running = true; }
    function avisar(t, erro) { aviso = t; avisoErro = !!erro; limpa.restart(); }
    Component.onCompleted: atualizar()
    Timer { id: limpa; interval: 9000; onTriggered: p.aviso = "" }

    Comando {
        id: cmdEstado
        onPronto: s => {
            try {
                p.e = JSON.parse(s);
                p.pastas = p.e.pastas.slice();
                p.tipo = p.e.destino.tipo || "pasta";
                caminho.text = p.e.destino.caminho || "";
                hora.text = p.e.hora;
            } catch (x) {}
        }
    }
    // HDs e pendrives montados (sugestões de destino)
    Process {
        id: cmdDiscos
        command: ["sh", "-c", "ls -d /run/media/$USER/* 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: p.discos = this.text.split("\n").filter(x => x) }
    }
    Comando { id: cmdProcurar; onPronto: s => { try { p.achados = JSON.parse(s); } catch (x) { p.achados = []; } } }
    Process {
        id: acao
        property string ok: ""
        stdout: SplitParser {
            onRead: l => {
                try { const d = JSON.parse(l); if (d.progresso) p.progresso = d.progresso; } catch (x) { acao._ultima = l; }
            }
        }
        property string _ultima: ""
        stderr: StdioCollector { id: erro }
        onExited: codigo => {
            p.progresso = "";
            if (codigo === 0) { if (acao.ok) p.avisar(acao.ok.replace("%s", acao._ultima), false); }
            else p.avisar(erro.text.trim() || "Não deu certo.", true);
            p.atualizar();
        }
        function rodar(c, msg) { if (running) return; ok = msg || ""; _ultima = ""; command = c; running = true; }
    }
    Process {
        id: salvar
        stdinEnabled: true
        command: [p.cmd, "configurar"]
        stderr: StdioCollector { id: erroSalvar }
        onExited: codigo => { p.avisar(codigo === 0 ? "Salvo." : (erroSalvar.text.trim() || "Não deu para salvar."), codigo !== 0); p.atualizar(); }
    }
    Process {
        id: cmdSenha
        command: [p.cmd, "senha"]
        stdout: StdioCollector { onStreamFinished: p.senha = this.text.trim() }
    }
    function gravarConfig(ligado) {
        salvar.running = true;
        salvar.write(JSON.stringify({ destino: { tipo: p.tipo, caminho: caminho.text.trim() }, pastas: p.pastas,
                                      hora: hora.text.trim(), ligado: ligado }));
        salvar.closeStdin();
    }
    function data(iso) { return iso ? iso.slice(8, 10) + "/" + iso.slice(5, 7) + " às " + iso.slice(11, 16) : "nunca"; }
    function tamanho(b) {
        const u = ["B", "KB", "MB", "GB", "TB"]; let i = 0, x = b || 0;
        while (x >= 1000 && i < 4) { x /= 1000; i++; }
        return x.toFixed(i ? 1 : 0).replace(".", ",") + " " + u[i];
    }

    Text {
        visible: p.e !== null && !p.e.restic
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "O backup não está instalado nesta versão. Atualize a Nyxz."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.aviso
    }

    // ------------------------------------------------ situação
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Rectangle {
            width: 8; height: 8; radius: 4
            color: !p.e || !p.e.ultimo.quando ? Tema.texto4 : p.e.ultimo.ok ? Tema.ok : Tema.erro
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: !p.e ? "" : !p.e.ultimo.quando ? "Nenhum backup feito ainda."
                : (p.e.ultimo.ok ? "Último backup " + p.data(p.e.ultimo.quando) + ": " + p.e.ultimo.novos + " arquivos novos, " + p.e.ultimo.mudados + " mudados, " + p.tamanho(p.e.ultimo.enviado) + " enviados."
                                 : "O último backup falhou (" + p.data(p.e.ultimo.quando) + "): " + p.e.ultimo.erro)
            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
        }
    }
    Text {
        visible: p.progresso !== "" || p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.progresso ? "Fazendo backup… " + p.progresso : p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro && !p.progresso ? Tema.erro : Tema.texto2
    }

    // ------------------------------------------------ onde guardar
    Text { Layout.topMargin: 12; text: "Onde guardar"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: [{ id: "pasta", nome: "HD externo ou pasta" }, { id: "nuvem", nome: "Google Drive" }]
            delegate: Rectangle {
                required property var modelData
                readonly property bool ativo: p.tipo === modelData.id
                implicitWidth: rotuloTipo.implicitWidth + 22
                implicitHeight: 28
                radius: 14
                color: ativo ? Tema.selecionado : areaTipo.containsMouse ? Tema.hover : "transparent"
                border.width: 1
                border.color: ativo ? Tema.bordaPainel : Tema.borda
                Text { id: rotuloTipo; anchors.centerIn: parent; text: parent.modelData.nome; font.family: Tema.fonte; font.pixelSize: 12; color: parent.ativo ? Tema.texto : Tema.texto2 }
                MouseArea { id: areaTipo; anchors.fill: parent; hoverEnabled: true; onClicked: p.tipo = parent.modelData.id }
            }
        }
    }
    ColumnLayout {
        visible: p.tipo === "pasta"
        Layout.fillWidth: true
        spacing: 6
        Campo { id: caminho; Layout.fillWidth: true; rotulo: "Pasta no HD (o backup fica em Backup-Nyxz dentro dela)" }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: p.discos
                delegate: Botao { required property string modelData; texto: modelData.split("/").pop(); onClicado: caminho.text = modelData }
            }
        }
    }
    RowLayout {
        visible: p.tipo === "nuvem"
        Layout.fillWidth: true
        spacing: 10
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: p.e && p.e.nuvem_conectada ? "Google Drive conectado. A Nyxz só enxerga a pasta Backup-Nyxz que ela mesma cria lá."
                : "Abre o navegador para você entrar na conta Google e autorizar. A Nyxz só vai enxergar a pasta que ela mesma criar."
            font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
        }
        Botao {
            visible: !(p.e && p.e.nuvem_conectada)
            texto: "Conectar ao Google Drive"
            ativo: !acao.running
            onClicado: acao.rodar([p.cmd, "nuvem"], "Google Drive conectado.")
        }
    }

    // ------------------------------------------------ o que e quando
    Text { Layout.topMargin: 12; text: "O que copiar"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Repeater {
        model: p.pastas
        delegate: RowLayout {
            required property string modelData
            required property int index
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: modelData; font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.texto }
            Botao { texto: "Tirar"; onClicado: { const l = p.pastas.slice(); l.splice(index, 1); p.pastas = l; } }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: novaPasta; Layout.fillWidth: true; rotulo: "Adicionar pasta (ex.: ~/Imagens)" }
        Botao {
            Layout.alignment: Qt.AlignBottom
            texto: "Adicionar"
            ativo: novaPasta.text.trim() !== ""
            onClicado: { p.pastas = p.pastas.concat([novaPasta.text.trim()]); novaPasta.text = ""; }
        }
    }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Ficam de fora: node_modules, caches, ambientes virtuais, pastas de build, Steam e containers. Guarda 7 cópias diárias, 4 semanais e 6 mensais."
        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Campo { id: hora; Layout.preferredWidth: 120; rotulo: "Horário"; validador: /^([01]\d|2[0-3]):[0-5]\d$/ }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text { text: "Backup automático todo dia"; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Se o PC estiver desligado no horário, faz quando ligar."
                font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
            }
        }
        Interruptor {
            ligado: p.e ? p.e.ligado : false
            onAlternado: p.gravarConfig(!(p.e && p.e.ligado))
        }
    }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        Botao { texto: "Salvar"; ativo: hora.aceito && !salvar.running; onClicado: p.gravarConfig(p.e ? p.e.ligado : false) }
        Botao { texto: acao.running && p.progresso ? "Fazendo backup…" : "Fazer backup agora"; principal: true; ativo: !acao.running; onClicado: acao.rodar([p.cmd, "agora"], "Backup feito.") }
        Botao { texto: p.senha ? "Esconder a senha" : "Mostrar a senha do backup"; ativo: !ModoStreamer.ativo || p.senha !== ""; onClicado: { if (p.senha) p.senha = ""; else cmdSenha.running = true; } }
    }
    Text {
        visible: p.senha !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Senha do backup: " + (ModoStreamer.ativo ? "oculta (modo streamer)" : p.senha) + "\nAnote num papel e guarde. Sem ela, ninguém (nem você, se o Cofre se perder) consegue abrir o backup."
        font.family: Tema.fonteMono; font.pixelSize: 12; color: Tema.aviso
    }

    // ------------------------------------------------ recuperar
    Text { Layout.topMargin: 14; text: "Recuperar um arquivo"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Campo { id: busca; Layout.fillWidth: true; rotulo: "Nome do arquivo (ou parte dele)"; onConfirmado: if (text.trim()) cmdProcurar.rodar([p.cmd, "procurar", text.trim()]) }
        Botao { Layout.alignment: Qt.AlignBottom; texto: "Procurar"; ativo: busca.text.trim() !== ""; onClicado: cmdProcurar.rodar([p.cmd, "procurar", busca.text.trim()]) }
    }
    Repeater {
        model: p.achados.slice(0, 40)
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: modelData.caminho + "  ·  " + modelData.modificado + (modelData.tipo === "file" ? "  ·  " + p.tamanho(modelData.tamanho) : "")
                elide: Text.ElideMiddle
                font.family: Tema.fonteMono; font.pixelSize: 11; color: Tema.texto2
            }
            Botao { texto: "Restaurar"; ativo: !acao.running; onClicado: acao.rodar([p.cmd, "restaurar", modelData.copia, modelData.caminho], "Restaurado em %s") }
        }
    }
}
