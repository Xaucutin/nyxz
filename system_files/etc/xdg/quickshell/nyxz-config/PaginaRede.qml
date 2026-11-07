import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Rede: conexões ativas, Wi-Fi (ligar, listar e conectar com senha).
// Usa o NetworkManager (nmcli) por baixo; a senha vai pela entrada padrão,
// nunca na linha de comando.
Pagina {
    id: p
    titulo: "Rede"
    descricao: "Cabo e Wi-Fi. VPN, proxy e LAN virtual chegam nas próximas fases."

    property var dispositivos: []
    property var redes: []
    property bool wifiLigado: false
    property bool temWifi: dispositivos.some(d => d.tipo === "wifi")
    property string redeEscolhida: ""
    property string mensagem: ""
    property bool conectando: false

    // nmcli -t separa campos por ":" e escapa ":" dentro do valor como "\:".
    function campos(linha) {
        const r = [];
        let atual = "";
        for (let i = 0; i < linha.length; i++) {
            const c = linha[i];
            if (c === "\\" && i + 1 < linha.length) { atual += linha[++i]; continue; }
            if (c === ":") { r.push(atual); atual = ""; continue; }
            atual += c;
        }
        r.push(atual);
        return r;
    }

    function nomeTipo(t) {
        return { ethernet: "Cabo", wifi: "Wi-Fi", wireguard: "VPN (WireGuard)", loopback: "Local" }[t] || t;
    }

    function atualizar() {
        cmdDisp.rodar(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]);
        cmdRadio.rodar(["nmcli", "radio", "wifi"]);
        cmdRedes.rodar(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]);
    }
    Component.onCompleted: atualizar()
    Timer { interval: 8000; running: true; repeat: true; onTriggered: p.atualizar() }

    Comando {
        id: cmdDisp
        onPronto: saida => {
            p.dispositivos = saida.trim().split("\n").filter(l => l).map(l => {
                const c = p.campos(l);
                return { nome: c[0], tipo: c[1], estado: c[2], conexao: c[3] };
            }).filter(d => d.tipo !== "loopback" && !d.tipo.startsWith("wifi-p2p"));
        }
    }
    Comando {
        id: cmdRadio
        onPronto: saida => p.wifiLigado = saida.trim() === "enabled"
    }
    Comando {
        id: cmdRedes
        onPronto: saida => {
            const vistas = {};
            p.redes = saida.trim().split("\n").filter(l => l).map(l => {
                const c = p.campos(l);
                return { ativa: c[0] === "*", ssid: c[1], sinal: parseInt(c[2]) || 0, seguranca: c[3] };
            }).filter(r => r.ssid && !vistas[r.ssid] && (vistas[r.ssid] = true))
              .sort((a, b) => b.ativa - a.ativa || b.sinal - a.sinal);
        }
    }

    Process {
        id: conectar
        stdinEnabled: true
        stdout: StdioCollector { id: saidaConexao }
        onExited: codigo => {
            p.conectando = false;
            p.mensagem = codigo === 0 ? "Conectado a " + p.redeEscolhida + "." : "Não foi possível conectar. Confira a senha e tente de novo.";
            if (codigo === 0) { p.redeEscolhida = ""; senha.text = ""; }
            p.atualizar();
        }
    }
    function conectarRede(ssid, pw) {
        p.conectando = true;
        p.mensagem = "Conectando…";
        conectar.command = ["nmcli", "--ask", "device", "wifi", "connect", ssid];
        conectar.running = true;
        conectar.write(pw + "\n");
    }

    // ------------------------------------------------ conexões
    Text { text: "Conexões"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
    Repeater {
        model: p.dispositivos
        delegate: Linha {
            required property var modelData
            rotulo: p.nomeTipo(modelData.tipo)
            valor: modelData.estado === "connected" ? "Conectado · " + modelData.conexao
                 : modelData.estado === "disconnected" ? "Desconectado"
                 : modelData.estado === "unavailable" ? "Indisponível" : modelData.estado
        }
    }

    // ------------------------------------------------ Wi-Fi
    RowLayout {
        Layout.topMargin: 18
        Layout.fillWidth: true
        visible: p.temWifi
        Text { Layout.fillWidth: true; text: "Wi-Fi"; font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3 }
        Botao {
            texto: p.wifiLigado ? "Desligar Wi-Fi" : "Ligar Wi-Fi"
            onClicado: {
                Quickshell.execDetached(["nmcli", "radio", "wifi", p.wifiLigado ? "off" : "on"]);
                p.wifiLigado = !p.wifiLigado;
            }
        }
    }
    Text {
        visible: !p.temWifi
        Layout.topMargin: 18
        text: "Este computador não tem Wi-Fi."
        font.family: Tema.fonte
        font.pixelSize: 13
        color: Tema.texto3
    }
    Repeater {
        model: p.temWifi && p.wifiLigado ? p.redes : []
        delegate: Rectangle {
            id: rede
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 6
            color: modelData.ativa ? "#16161B" : areaRede.containsMouse ? Tema.elevado : "transparent"
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                Text {
                    Layout.fillWidth: true
                    text: rede.modelData.ssid
                    font.family: Tema.fonte
                    font.pixelSize: 13
                    color: rede.modelData.ativa ? Tema.texto : Tema.texto2
                    elide: Text.ElideRight
                }
                Text {
                    text: (rede.modelData.seguranca && rede.modelData.seguranca !== "--" ? "protegida · " : "aberta · ") + rede.modelData.sinal + "%"
                    font.family: Tema.fonteMono
                    font.pixelSize: 11
                    color: "#55535F"
                }
            }
            MouseArea {
                id: areaRede
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (rede.modelData.ativa) return;
                    p.redeEscolhida = rede.modelData.ssid;
                    p.mensagem = "";
                    if (!rede.modelData.seguranca || rede.modelData.seguranca === "--")
                        p.conectarRede(rede.modelData.ssid, "");
                    else
                        senha.forceActiveFocus();
                }
            }
        }
    }

    // Senha da rede escolhida
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        visible: p.redeEscolhida.length > 0
        spacing: 8
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 6
            color: "#0B0B0F"
            border.color: senha.activeFocus ? "#3A3A44" : Tema.borda
            TextInput {
                id: senha
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                font.family: Tema.fonte
                font.pixelSize: 13
                color: Tema.texto
                onAccepted: p.conectarRede(p.redeEscolhida, text)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: senha.text.length === 0
                    text: "Senha de " + p.redeEscolhida
                    font: senha.font
                    color: Tema.texto3
                }
            }
        }
        Botao {
            texto: "Conectar"
            principal: true
            ativo: !p.conectando
            onClicado: p.conectarRede(p.redeEscolhida, senha.text)
        }
    }
    Text {
        Layout.fillWidth: true
        visible: p.mensagem.length > 0
        text: p.mensagem
        font.family: Tema.fonte
        font.pixelSize: 13
        color: Tema.suave
        wrapMode: Text.Wrap
    }
}
