import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Ajustes: os "mods" do Windhawk como opções nativas (PROJETO.md, "Ajustes da Nyxz").
// Nada é injetado: cada item é uma opção do próprio shell ou do Hyprland.
// - ~/.config/nyxz/ajustes.json: lido pelo shell (muda na hora);
// - ~/.config/hypr/nyxz/ajustes.lua: gerado aqui para o Hyprland (borda, tecla de arrastar).
Pagina {
    id: p
    titulo: "Ajustes"
    descricao: "Pequenas mudanças no jeito da barra, das janelas e das notificações. Valem na hora."

    property string filtro: ""

    FileView {
        id: arquivo
        path: Quickshell.env("HOME") + "/.config/nyxz/ajustes.json"
        printErrors: false
        onAdapterUpdated: { writeAdapter(); p.gerarLua(); }
        JsonAdapter {
            id: cfg
            property bool miniPlayer: true
            property bool previa: true
            property int atrasoPrevia: 0
            property bool volumeNaRoda: true
            property bool titulosLimpos: true
            property bool privacidade: true
            property bool barraEmCima: false
            property bool iconesCrescem: false
            property bool medidor: false
            property string cantoNotificacoes: "superior-direito"
            property int bordaJanela: 1
            property string teclaArrastar: "SUPER"
        }
    }

    FileView {
        id: lua
        path: Quickshell.env("HOME") + "/.config/hypr/nyxz/ajustes.lua"
        printErrors: false
    }

    function gerarLua() {
        let t = "-- Gerado por Configurações → Ajustes. Não edite: mude pela tela.\n" +
                "hl.config({ general = { border_size = " + cfg.bordaJanela + " } })\n";
        if (cfg.teclaArrastar === "ALT")
            t += "hl.bind(\"ALT + mouse:272\", hl.dsp.window.drag(), { mouse = true })\n" +
                 "hl.bind(\"ALT + mouse:273\", hl.dsp.window.resize(), { mouse = true })\n";
        lua.setText(t);
        recarregar.restart();
    }
    // Recarrega o Hyprland uma vez só, mesmo se vários ajustes mudarem juntos.
    Timer { id: recarregar; interval: 300; onTriggered: Quickshell.execDetached(["hyprctl", "reload"]) }

    // Cada item: grupo, nome, explicação, chave e tipo ("bool" ou lista de opções)
    readonly property var itens: [
        { grupo: "Barra", nome: "Mini player", texto: "Capa, título e controles de qualquer app de mídia (Spotify, vídeo no Brave).", chave: "miniPlayer" },
        { grupo: "Barra", nome: "Prévia ao passar o mouse", texto: "Miniatura ao vivo da janela sobre o ícone do app.", chave: "previa" },
        { grupo: "Barra", nome: "Atraso da prévia", texto: "Quanto esperar antes de mostrar a prévia.", chave: "atrasoPrevia",
          opcoes: [{ v: 0, n: "Na hora" }, { v: 150, n: "150 ms" }, { v: 400, n: "400 ms" }] },
        { grupo: "Barra", nome: "Volume na roda do mouse", texto: "Rolar sobre o ícone de som muda o volume.", chave: "volumeNaRoda" },
        { grupo: "Barra", nome: "Indicador de privacidade", texto: "Ponto vermelho quando um app usa microfone, câmera ou captura a tela.", chave: "privacidade" },
        { grupo: "Barra", nome: "Barra em cima", texto: "Coloca a barra no topo da tela.", chave: "barraEmCima" },
        { grupo: "Barra", nome: "Ícones crescem sob o mouse", texto: "Aumento leve do ícone do app, estilo dock.", chave: "iconesCrescem" },
        { grupo: "Barra", nome: "Medidor na barra", texto: "CPU, RAM, placa de vídeo e temperatura. Passe o mouse para ver os detalhes (RAM do sistema e dos apps).", chave: "medidor" },
        { grupo: "Janelas", nome: "Títulos sem o nome do app", texto: "Tira \" — Brave\", \" - Visual Studio Code\" e parecidos do fim dos títulos.", chave: "titulosLimpos" },
        { grupo: "Janelas", nome: "Borda das janelas", texto: "Espessura da borda em volta das janelas.", chave: "bordaJanela",
          opcoes: [{ v: 0, n: "Sem borda" }, { v: 1, n: "Fina" }, { v: 2, n: "Média" }] },
        { grupo: "Janelas", nome: "Mover janela segurando", texto: "Tecla + arrastar move; tecla + botão direito redimensiona, de qualquer ponto da janela.", chave: "teclaArrastar",
          opcoes: [{ v: "SUPER", n: "Super" }, { v: "ALT", n: "Alt" }] },
        { grupo: "Notificações", nome: "Canto das notificações", texto: "Onde os avisos aparecem.", chave: "cantoNotificacoes",
          opcoes: [{ v: "superior-direito", n: "Em cima, à direita" }, { v: "superior-esquerdo", n: "Em cima, à esquerda" },
                   { v: "inferior-direito", n: "Embaixo, à direita" }] }
    ]

    readonly property var visiveis: itens.filter(it => {
        const f = p.filtro.trim().toLowerCase();
        return !f || (it.nome + " " + it.texto + " " + it.grupo).toLowerCase().indexOf(f) >= 0;
    })

    // ---------------------------------------------- busca
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.bottomMargin: 6
        radius: Tema.raio
        color: Tema.elevado
        border.width: 1
        border.color: busca.activeFocus ? Tema.texto4 : Tema.borda
        TextInput {
            id: busca
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            font.family: Tema.fonte
            font.pixelSize: 13
            color: Tema.texto
            clip: true
            onTextChanged: p.filtro = text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: busca.text.length === 0
                text: "Procurar ajuste"
                font: busca.font
                color: Tema.texto4
            }
        }
    }

    Text {
        visible: p.visiveis.length === 0
        text: "Nenhum ajuste com esse nome."
        font.family: Tema.fonte; font.pixelSize: 12; color: Tema.texto3
    }

    Repeater {
        model: p.visiveis
        delegate: ColumnLayout {
            id: linha
            required property var modelData
            required property int index
            readonly property bool novoGrupo: index === 0 || p.visiveis[index - 1].grupo !== modelData.grupo
            Layout.fillWidth: true
            spacing: 0

            Text {
                visible: linha.novoGrupo
                Layout.topMargin: linha.index === 0 ? 0 : 14
                Layout.bottomMargin: 4
                text: linha.modelData.grupo
                font.family: Tema.fonte; font.pixelSize: 12; font.weight: Font.Medium; color: Tema.texto3
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                spacing: 16
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: linha.modelData.nome
                        font.family: Tema.fonte; font.pixelSize: 13; color: Tema.texto
                    }
                    Text {
                        Layout.fillWidth: true
                        text: linha.modelData.texto
                        wrapMode: Text.Wrap
                        font.family: Tema.fonte; font.pixelSize: 11; color: Tema.texto3
                    }
                }
                Interruptor {
                    visible: !linha.modelData.opcoes
                    ligado: !linha.modelData.opcoes && cfg[linha.modelData.chave] === true
                    onAlternado: v => cfg[linha.modelData.chave] = v
                }
                Row {
                    visible: !!linha.modelData.opcoes
                    spacing: 6
                    Repeater {
                        model: linha.modelData.opcoes || []
                        delegate: Botao {
                            required property var modelData
                            texto: modelData.n
                            principal: cfg[linha.modelData.chave] === modelData.v
                            onClicado: cfg[linha.modelData.chave] = modelData.v
                        }
                    }
                }
            }
        }
    }
}
