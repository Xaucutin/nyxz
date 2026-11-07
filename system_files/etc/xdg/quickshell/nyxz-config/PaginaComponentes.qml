import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Apps e componentes: o mesmo catálogo da instalação, para adicionar ou remover depois.
Pagina {
    id: p
    titulo: "Apps e componentes"
    descricao: "Marque o que você quer e aplique. Apps Flatpak instalam na hora; apps nativos montam uma imagem personalizada no seu PC e entram no próximo boot."

    property var catalogo: null
    property var estado: null
    property var marcados: ({})

    FileView {
        path: "/usr/share/nyxz/catalogo.json"
        onLoaded: p.catalogo = JSON.parse(text())
    }

    Comando {
        id: lerEstado
        onPronto: saida => {
            try {
                p.estado = JSON.parse(saida);
                const m = {};
                for (const id in p.estado.itens) m[id] = p.estado.itens[id];
                for (const id of (p.estado.escolhidosSistema || [])) m[id] = true;
                p.marcados = m;
            } catch (e) {}
        }
    }
    Component.onCompleted: lerEstado.rodar(["/usr/libexec/nyxz/componentes", "estado"])

    Executor {
        id: executor
        onTerminouChanged: if (terminou) lerEstado.rodar(["/usr/libexec/nyxz/componentes", "estado"])
    }

    readonly property bool mudou: {
        if (!estado || !catalogo) return false;
        return catalogo.itens.some(i => !!marcados[i.id] !== !!(estado.itens[i.id] || (estado.escolhidosSistema || []).includes(i.id)));
    }

    function alternar(id) {
        const m = Object.assign({}, p.marcados);
        m[id] = !m[id];
        p.marcados = m;
    }

    // Avisos
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: aviso.implicitHeight + 24
        visible: p.estado !== null && (p.estado.reinicioPendente || executor.precisaReiniciar)
        radius: Tema.raio
        color: Tema.painel
        border.color: Tema.bordaPainel
        RowLayout {
            id: aviso
            anchors.fill: parent
            anchors.margins: 12
            Text {
                Layout.fillWidth: true
                text: "Há uma nova versão do sistema pronta. Reinicie para usar os apps nativos que você escolheu."
                font.family: Tema.fonte
                font.pixelSize: 13
                color: Tema.texto
                wrapMode: Text.Wrap
            }
            Botao {
                texto: "Reiniciar agora"
                principal: true
                onClicado: Quickshell.execDetached(["systemctl", "reboot"])
            }
        }
    }

    Text {
        visible: p.catalogo === null || p.estado === null
        text: "Lendo o que está instalado…"
        font.family: Tema.fonte
        font.pixelSize: 13
        color: Tema.texto3
    }

    ListaComponentes {
        Layout.fillWidth: true
        visible: p.catalogo !== null && p.estado !== null
        catalogo: p.catalogo
        marcados: p.marcados
        instalados: p.estado ? p.estado.itens : ({})
        onAlternar: id => p.alternar(id)
        onDefinirCategoria: (categoria, valor) => {
            const m = Object.assign({}, p.marcados);
            for (const i of p.catalogo.itens) if (i.categoria === categoria) m[i.id] = valor;
            p.marcados = m;
        }
    }

    RowLayout {
        spacing: 12
        Botao {
            texto: executor.rodando ? "Aplicando…" : "Aplicar mudanças"
            principal: true
            ativo: p.mudou && !executor.rodando
            onClicado: executor.aplicar(p.catalogo, p.marcados, p.estado)
        }
        Text {
            text: executor.rodando ? executor.passo : (executor.erro || (executor.terminou ? "Pronto." : ""))
            font.family: Tema.fonte
            font.pixelSize: 13
            color: executor.erro ? Tema.erro : Tema.suave
        }
    }
    Text {
        Layout.fillWidth: true
        visible: executor.rodando && executor.log.length > 0
        text: executor.log.length ? executor.log[executor.log.length - 1] : ""
        font.family: Tema.fonteMono
        font.pixelSize: 11
        color: Tema.texto3
        elide: Text.ElideRight
    }
}
