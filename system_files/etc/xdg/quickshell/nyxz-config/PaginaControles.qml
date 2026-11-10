import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Central de controles (ideia 34): controles ligados com bateria, teste de botões e
// pareamento por Bluetooth. Sem serviço: lê o kernel por /usr/libexec/nyxz/controles.
// Remapear botões fica com a Steam (nos jogos dela) ou com o input-remapper (Macros).
Pagina {
    id: p
    titulo: "Controles"
    descricao: "Controles de Xbox, PlayStation, Nintendo, 8BitDo e genéricos funcionam ao conectar, sem instalar nada. Aqui você vê a bateria, testa os botões e pareia controles sem fio."

    readonly property string cmd: "/usr/libexec/nyxz/controles"
    property var controles: []
    property bool temBluetooth: false
    property string testando: ""          // jsN em teste
    property var estado: ({ botoes: [], eixos: [] })
    property var achados: []
    property bool procurando: false
    property string pareando: ""
    property string aviso: ""

    function atualizar() { listar.rodar([cmd, "listar"]); }
    Component.onCompleted: atualizar()
    // Controles entram e saem a qualquer hora: confere a cada 3 s enquanto a página está aberta
    Timer { interval: 3000; running: true; repeat: true; onTriggered: p.atualizar() }

    Comando {
        id: listar
        onPronto: s => {
            try {
                const d = JSON.parse(s);
                p.controles = d.controles;
                p.temBluetooth = d.bluetooth;
            } catch (e) { p.controles = []; }
            if (p.testando !== "" && !p.controles.some(c => c.id === p.testando)) p.testando = "";
        }
    }
    Comando {
        id: procura
        onPronto: s => {
            p.procurando = false;
            try {
                const d = JSON.parse(s);
                p.achados = d.dispositivos || [];
                p.aviso = d.erro || (p.achados.length ? "" : "Nenhum dispositivo encontrado. Deixe o controle no modo de pareamento e procure de novo.");
            } catch (e) { p.aviso = "A busca falhou."; }
        }
    }
    Process {
        id: pareia
        stderr: StdioCollector { id: erroPareia }
        onExited: codigo => {
            p.aviso = codigo === 0 ? "Pareado e conectado." : (erroPareia.text.trim() || "Não deu para parear.");
            p.pareando = "";
            p.achados = [];
            p.atualizar();
        }
    }
    Process {
        id: teste
        running: p.testando !== ""
        command: [p.cmd, "testar", p.testando]
        stdout: SplitParser {
            onRead: linha => { try { p.estado = JSON.parse(linha); } catch (e) {} }
        }
        onRunningChanged: if (!running) p.estado = { botoes: [], eixos: [] }
    }

    function icone(c) {
        return { xbox: "Xbox", playstation: "PlayStation", nintendo: "Nintendo", "8bitdo": "8BitDo", steam: "Steam", logitech: "Logitech" }[c.tipo] || "Controle";
    }
    function bateria(c) {
        if (c.bateria !== null && c.bateria !== undefined) return c.bateria + "%" + (c.carregando ? " · carregando" : "");
        const n = { Full: "cheia", High: "alta", Normal: "média", Low: "baixa", Critical: "acabando" }[c.nivel];
        return n ? "Bateria " + n : "";
    }

    // ---------------------------------------------- controles ligados
    Text {
        text: p.controles.length ? "Conectados" : "Nenhum controle conectado. Ligue um pelo cabo USB ou pareie um sem fio abaixo."
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Repeater {
        model: p.controles
        delegate: Rectangle {
            id: cartao
            required property var modelData
            readonly property bool emTeste: p.testando === modelData.id
            Layout.fillWidth: true
            Layout.preferredHeight: coluna.implicitHeight + 24
            radius: Tema.raio
            color: Tema.elevado
            border.width: 1
            border.color: Tema.borda

            ColumnLayout {
                id: coluna
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Image { source: "icones/controle.svg"; sourceSize: Qt.size(22, 22) }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: cartao.modelData.nome
                            elide: Text.ElideRight
                            font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                        }
                        Text {
                            text: [p.icone(cartao.modelData), cartao.modelData.conexao, p.bateria(cartao.modelData)].filter(x => x).join(" · ")
                            font.family: Tema.fonte; font.pixelSize: 11
                            color: cartao.modelData.bateria !== null && cartao.modelData.bateria <= 15 && !cartao.modelData.carregando ? Tema.aviso : Tema.texto3
                        }
                    }
                    Botao {
                        texto: cartao.emTeste ? "Parar o teste" : "Testar botões"
                        onClicado: p.testando = cartao.emTeste ? "" : cartao.modelData.id
                    }
                }

                // Teste: botões acendem ao apertar, eixos mostram a posição
                Flow {
                    Layout.fillWidth: true
                    visible: cartao.emTeste
                    spacing: 6
                    Repeater {
                        model: cartao.emTeste ? Math.max(p.estado.botoes.length, cartao.modelData.botoes.length) : 0
                        delegate: Rectangle {
                            required property int index
                            readonly property bool apertado: p.estado.botoes[index] === 1
                            width: Math.max(38, rotuloBotao.implicitWidth + 16)
                            height: 28
                            radius: 6
                            color: apertado ? Tema.texto : Tema.fundo
                            border.width: 1
                            border.color: apertado ? Tema.texto : Tema.borda
                            Behavior on color { ColorAnimation { duration: 80 } }
                            Text {
                                id: rotuloBotao
                                anchors.centerIn: parent
                                text: cartao.modelData.botoes[index] || String(index + 1)
                                font.family: Tema.fonte; font.pixelSize: 11
                                color: parent.apertado ? Tema.fundo : Tema.texto2
                            }
                        }
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    visible: cartao.emTeste && p.estado.eixos.length > 0
                    columns: 2
                    columnSpacing: 18
                    rowSpacing: 6
                    Repeater {
                        model: cartao.emTeste ? p.estado.eixos.length : 0
                        delegate: RowLayout {
                            required property int index
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.preferredWidth: 56
                                text: cartao.modelData.eixos[index] || ("Eixo " + (index + 1))
                                font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: 3
                                color: Tema.trilho
                                // Marcador na posição do eixo (-32767 a 32767)
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: (parent.width - width) * ((p.estado.eixos[index] || 0) + 32767) / 65534
                                    color: Tema.texto
                                }
                            }
                        }
                    }
                }
                Text {
                    visible: cartao.emTeste
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: "Aperte os botões e mexa os analógicos. Se um analógico se mexe sozinho parado, é desgaste (drift)."
                    font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto4
                }
            }
        }
    }

    // ---------------------------------------------- Bluetooth
    Text {
        Layout.topMargin: 18
        text: "Parear um controle sem fio"
        font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
    }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: p.temBluetooth
            ? "Deixe o controle no modo de pareamento. Xbox: segure o botão de parear (em cima) até a luz piscar rápido. PlayStation: segure PS + Create (ou Share). Nintendo: segure o botão de sincronizar."
            : "Este computador não tem Bluetooth (ou ele está desligado na BIOS). Um adaptador USB resolve."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto2
    }
    RowLayout {
        spacing: 10
        visible: p.temBluetooth
        Botao {
            texto: p.procurando ? "Procurando…" : "Procurar controles"
            principal: true
            ativo: !p.procurando && p.pareando === ""
            onClicado: { p.procurando = true; p.aviso = ""; p.achados = []; procura.rodar([p.cmd, "procurar", "15"]); }
        }
        Text {
            text: p.aviso
            visible: p.aviso !== ""
            font.family: Tema.fonte; font.pixelSize: 12
            color: p.aviso.indexOf("Pareado") === 0 ? Tema.ok : Tema.texto2
        }
    }
    Repeater {
        model: p.achados
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 10
            Text {
                Layout.fillWidth: true
                text: modelData.nome + (modelData.controle ? "" : "  (talvez não seja um controle)")
                elide: Text.ElideRight
                font.family: Tema.fonte; font.pixelSize: 13
                color: modelData.controle ? Tema.texto : Tema.texto3
            }
            Text {
                visible: modelData.conectado
                text: "Conectado"
                font.family: Tema.fonte; font.pixelSize: 12; color: Tema.ok
            }
            Botao {
                visible: !modelData.conectado
                texto: p.pareando === modelData.mac ? "Pareando…" : "Parear"
                ativo: p.pareando === ""
                onClicado: {
                    p.pareando = modelData.mac;
                    pareia.command = [p.cmd, "parear", modelData.mac];
                    pareia.running = true;
                }
            }
            Botao {
                visible: modelData.pareado
                texto: "Esquecer"
                onClicado: { Quickshell.execDetached([p.cmd, "esquecer", modelData.mac]); p.achados = p.achados.filter(d => d.mac !== modelData.mac); }
            }
        }
    }

    // ---------------------------------------------- dicas
    Text {
        Layout.topMargin: 18
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Trocar a função dos botões: nos jogos da Steam, use o Steam Input (botão do controle no jogo → Configuração do controle). Fora da Steam, instale \"Macros e remapeamento\" em Apps e componentes."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
    }
}
