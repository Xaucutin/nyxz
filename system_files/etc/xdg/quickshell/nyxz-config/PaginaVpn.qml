import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// VPN e DNS: VPNs do NetworkManager (WireGuard e OpenVPN), kill switch e DNS
// criptografado. Por baixo: /usr/libexec/nyxz/rede (e o nyxz-net-root para o que
// precisa de administrador, sem pedir senha na sessão ativa).
Pagina {
    id: p
    titulo: "VPN e DNS"
    descricao: "Importe a VPN que você usa (Proton VPN, Mullvad, a do trabalho ou um servidor próprio) com o arquivo .conf ou .ovpn que o serviço fornece. O WireGuard roda dentro do sistema e quase não gasta memória."

    readonly property string cmd: "/usr/libexec/nyxz/rede"
    property var vpns: []
    property bool killswitch: false
    property string dns: "automatico"
    property string ip: ""
    property string pais: ""
    property string aviso: ""
    property bool avisoErro: false
    property string ocupado: ""        // uuid da VPN conectando/desconectando
    property string removendo: ""

    readonly property bool algumaLigada: vpns.some(v => v.ligada)
    readonly property var perfisDns: [
        { id: "automatico", nome: "Da rede", detalhe: "O DNS do roteador ou do provedor, sem criptografia." },
        { id: "cloudflare", nome: "Cloudflare", detalhe: "Rápido e criptografado (1.1.1.1)." },
        { id: "quad9", nome: "Quad9", detalhe: "Criptografado e bloqueia sites de golpe e vírus." },
        { id: "adguard", nome: "AdGuard", detalhe: "Criptografado e bloqueia anúncios e rastreadores." },
        { id: "mullvad", nome: "Mullvad", detalhe: "Criptografado, bloqueia anúncios e não guarda registros." }
    ]

    function atualizar() { cmdEstado.rodar([cmd, "estado"]); }
    function avisar(texto, erro) { aviso = texto; avisoErro = !!erro; limpaAviso.restart(); }
    Component.onCompleted: { atualizar(); cmdIp.rodar([cmd, "ip"]); cmdApps.rodar([cmd, "apps"]); }

    // Internet por app: { "id-do-app": "semnet" | "direto" }
    property var regras: ({})
    property string buscaApp: ""
    readonly property var modos: [
        { id: "normal", nome: "Normal" }, { id: "direto", nome: "Fora da VPN" }, { id: "semnet", nome: "Sem internet" }
    ]
    Comando {
        id: cmdApps
        onPronto: s => { try { p.regras = JSON.parse(s).apps; } catch (e) {} }
    }
    function definirApp(app, modo) {
        const r = Object.assign({}, p.regras);
        if (modo === "normal") delete r[app]; else r[app] = modo;
        p.regras = r;
        acao.rodar([cmd, "apps", "definir", app, modo], "Vale na próxima vez que o app abrir (feche e abra de novo se ele estiver aberto).");
    }
    function nomeApp(id) {
        const e = DesktopEntries.byId(id);
        return e ? e.name : id;
    }
    readonly property var candidatos: {
        const b = buscaApp.trim().toLowerCase();
        if (!b) return [];
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !(e.id in p.regras) && (e.name.toLowerCase().indexOf(b) >= 0 || e.id.toLowerCase().indexOf(b) >= 0))
            .slice(0, 6);
    }
    // A VPN pode cair ou ser ligada pelo painel rápido: confere a cada 4 s
    Timer { interval: 4000; running: true; repeat: true; onTriggered: p.atualizar() }
    Timer { id: limpaAviso; interval: 6000; onTriggered: p.aviso = "" }
    // Depois de ligar ou desligar a VPN, o IP público muda
    Timer { id: atualizaIp; interval: 2500; onTriggered: cmdIp.rodar([p.cmd, "ip"]) }

    Comando {
        id: cmdEstado
        onPronto: s => {
            try {
                const d = JSON.parse(s);
                p.vpns = d.vpns; p.killswitch = d.killswitch; p.dns = d.dns;
            } catch (e) {}
        }
    }
    Comando {
        id: cmdIp
        onPronto: s => { try { const d = JSON.parse(s); p.ip = d.ip; p.pais = d.pais; } catch (e) {} }
    }
    // Ações com resposta (erro aparece no aviso)
    Process {
        id: acao
        property string ok: ""
        stderr: StdioCollector { id: erroAcao }
        onExited: codigo => {
            if (codigo === 0) { if (acao.ok) p.avisar(acao.ok, false); }
            else p.avisar(erroAcao.text.trim() || "Não deu certo.", true);
            p.ocupado = "";
            p.atualizar();
            atualizaIp.restart();
        }
        function rodar(comando, mensagem) {
            if (running) return;
            ok = mensagem || "";
            command = comando;
            running = true;
        }
    }
    Process {
        id: importar
        stdinEnabled: true
        stderr: StdioCollector { id: erroImportar }
        onExited: codigo => {
            if (codigo === 0) {
                p.avisar("VPN importada. Ligue quando quiser.", false);
                arquivo.text = ""; usuario.text = ""; senha.text = "";
            } else p.avisar(erroImportar.text.trim() || "Não deu para importar.", true);
            p.atualizar();
        }
    }

    // ---------------------------------------------- situação
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Rectangle {
            width: 8; height: 8; radius: 4
            color: p.algumaLigada ? Tema.ok : Tema.texto4
        }
        Text {
            Layout.fillWidth: true
            text: (p.algumaLigada ? "Protegido pela VPN" : "Sem VPN") + (p.ip ? " · IP público " + ModoStreamer.ip(p.ip) + (p.pais ? " (" + p.pais + ")" : "") : "")
            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
        }
    }
    Text {
        visible: p.aviso !== ""
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.aviso
        font.family: Tema.fonte; font.pixelSize: 12; color: p.avisoErro ? Tema.erro : Tema.ok
    }

    // ---------------------------------------------- VPNs salvas
    Text {
        Layout.topMargin: 10
        text: p.vpns.length ? "Suas VPNs" : "Nenhuma VPN salva ainda."
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Repeater {
        model: p.vpns
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Rectangle { width: 6; height: 6; radius: 3; color: modelData.ligada ? Tema.ok : Tema.texto4 }
            Text {
                Layout.fillWidth: true
                text: modelData.nome
                elide: Text.ElideRight
                font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
            }
            Text { text: modelData.tipo; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
            Botao {
                texto: p.ocupado === modelData.uuid ? "Aguarde…" : modelData.ligada ? "Desligar" : "Ligar"
                principal: !modelData.ligada
                ativo: p.ocupado === ""
                onClicado: {
                    p.ocupado = modelData.uuid;
                    acao.rodar([p.cmd, "vpn", modelData.ligada ? "desligar" : "ligar", modelData.uuid],
                               modelData.ligada ? "VPN desligada." : "VPN ligada.");
                }
            }
            Botao {
                visible: p.removendo !== modelData.uuid
                texto: "Remover"
                onClicado: p.removendo = modelData.uuid
            }
            Botao {
                visible: p.removendo === modelData.uuid
                texto: "Confirmar remoção"
                perigo: true
                onClicado: { acao.rodar([p.cmd, "vpn", "remover", modelData.uuid], "VPN removida."); p.removendo = ""; }
            }
        }
    }

    // ---------------------------------------------- importar
    Text {
        Layout.topMargin: 14
        text: "Importar uma VPN"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Item {
        Layout.fillWidth: true
        implicitHeight: arquivo.implicitHeight
        Campo {
            id: arquivo
            width: parent.width
            rotulo: "Arquivo .conf ou .ovpn (arraste do gerenciador de arquivos ou digite o caminho)"
        }
        // Arrastar o arquivo do Dolphin preenche o caminho
        DropArea {
            anchors.fill: parent
            onDropped: drop => {
                if (drop.hasUrls) arquivo.text = decodeURIComponent(drop.urls[0].toString().replace("file://", ""));
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: arquivo.text.toLowerCase().endsWith(".ovpn")
        Campo { id: usuario; Layout.fillWidth: true; rotulo: "Usuário da VPN (se o serviço pedir)" }
        Campo { id: senha; Layout.fillWidth: true; rotulo: "Senha da VPN"; oculto: true }
    }
    Botao {
        texto: "Importar"
        principal: true
        ativo: arquivo.text.trim() !== "" && !importar.running
        onClicado: {
            importar.command = [p.cmd, "vpn", "importar", arquivo.text.trim()];
            importar.running = true;
            importar.write(JSON.stringify({ usuario: usuario.text, senha: senha.text }));
            importar.closeStdin();
        }
    }

    // ---------------------------------------------- kill switch
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 18
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: "Kill switch"; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Sem VPN ligada, nada sai para a internet: se ela cair, nada vaza. A rede de casa, a LAN virtual e a reconexão da VPN continuam funcionando."
                font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
            }
        }
        Interruptor {
            ligado: p.killswitch
            onAlternado: {
                const novo = !p.killswitch;
                p.killswitch = novo;
                acao.rodar([p.cmd, "killswitch", novo ? "ligar" : "desligar"],
                           novo ? (p.algumaLigada ? "Kill switch ligado." : "Kill switch ligado: a internet só volta com a VPN ligada.") : "Kill switch desligado.");
            }
        }
    }

    // ---------------------------------------------- DNS
    Text {
        Layout.topMargin: 18
        text: "DNS"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "O DNS traduz os nomes dos sites. Os criptografados (DNS-over-TLS) impedem que o provedor veja e mude o que você acessa."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
    }
    Repeater {
        model: p.perfisDns
        delegate: Rectangle {
            required property var modelData
            readonly property bool escolhido: p.dns === modelData.id
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: Tema.raio
            color: escolhido ? Tema.selecionado : areaDns.containsMouse ? Tema.hover : "transparent"
            border.width: 1
            border.color: escolhido ? Tema.bordaPainel : Tema.borda
            Behavior on color { ColorAnimation { duration: Tema.rapido } }
            ColumnLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 2
                Text { text: modelData.nome; font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto }
                Text { text: modelData.detalhe; font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3 }
            }
            MouseArea {
                id: areaDns
                anchors.fill: parent
                hoverEnabled: true
                onClicked: if (!parent.escolhido) {
                    p.dns = modelData.id;
                    acao.rodar([p.cmd, "dns", modelData.id], "DNS trocado para " + modelData.nome + ".");
                }
            }
        }
    }

    // ---------------------------------------------- internet por app
    Text {
        Layout.topMargin: 18
        text: "Internet por app"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "\"Fora da VPN\": o app sai direto pela sua conexão mesmo com a VPN ligada (ex.: jogos, para não aumentar o ping). \"Sem internet\": o app não acessa a internet, mas a rede de casa e a LAN virtual continuam. Vale para apps abertos pela Nyxz."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
    }
    Repeater {
        model: Object.keys(p.regras)
        delegate: RowLayout {
            id: linhaApp
            required property string modelData
            Layout.fillWidth: true
            spacing: 6
            Text {
                Layout.fillWidth: true
                text: p.nomeApp(linhaApp.modelData)
                elide: Text.ElideRight
                font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
            }
            Repeater {
                model: p.modos
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool ativo: (p.regras[linhaApp.modelData] || "normal") === modelData.id
                    implicitWidth: rotuloModo.implicitWidth + 20
                    implicitHeight: 26
                    radius: 13
                    color: ativo ? Tema.selecionado : areaModo.containsMouse ? Tema.hover : "transparent"
                    border.width: 1
                    border.color: ativo ? Tema.bordaPainel : Tema.borda
                    Text {
                        id: rotuloModo
                        anchors.centerIn: parent
                        text: parent.modelData.nome
                        font.family: Tema.fonte; font.pixelSize: 12
                        color: parent.ativo ? Tema.texto : Tema.texto2
                    }
                    MouseArea {
                        id: areaModo
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (!parent.ativo) p.definirApp(linhaApp.modelData, parent.modelData.id)
                    }
                }
            }
        }
    }
    Campo {
        Layout.fillWidth: true
        rotulo: "Adicionar um app (procure pelo nome)"
        onTextChanged: p.buscaApp = text
    }
    Repeater {
        model: p.candidatos
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: modelData.name
                elide: Text.ElideRight
                font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto2
            }
            Botao { texto: "Fora da VPN"; onClicado: p.definirApp(modelData.id, "direto") }
            Botao { texto: "Sem internet"; onClicado: p.definirApp(modelData.id, "semnet") }
        }
    }
}
