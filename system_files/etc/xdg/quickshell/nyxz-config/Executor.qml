import QtQuick
import Quickshell.Io

// Aplica escolhas de componentes: primeiro os Flatpaks (na conta do usuário),
// depois os apps nativos (imagem local, com senha de administrador via pkexec).
// Lê o protocolo de /usr/libexec/nyxz/componentes: PASSO|texto, LOG|texto, FIM|ok|erro.
QtObject {
    id: ex

    property string passo: ""
    property var log: []
    property bool rodando: false
    property bool terminou: false
    property string erro: ""
    property bool precisaReiniciar: false

    property var _fila: []
    property bool _sistemaNaFila: false

    function aplicar(catalogo, marcados, estado) {
        const itens = catalogo.itens;
        const instalados = estado ? estado.itens : {};
        // Flatpaks e extras da conta do usuário (ex.: Spicetify) vão no mesmo passo, sem senha.
        const doUsuario = i => i.tipo === "flatpak" || i.tipo === "usuario";
        const instalar = itens.filter(i => doUsuario(i) && marcados[i.id] && !instalados[i.id]).map(i => i.id);
        const remover = itens.filter(i => doUsuario(i) && !marcados[i.id] && instalados[i.id]).map(i => i.id);
        const nativos = itens.filter(i => i.tipo === "rpm" && marcados[i.id]).map(i => i.id).sort();
        // Situação atual dos nativos: o que foi escolhido antes, ou o que está instalado.
        const antes = (estado && estado.escolhidosSistema && estado.escolhidosSistema.length
                       ? estado.escolhidosSistema
                       : itens.filter(i => i.tipo === "rpm" && instalados[i.id]).map(i => i.id)).slice().sort();

        _fila = [];
        if (instalar.length || remover.length)
            _fila.push(["/usr/libexec/nyxz/componentes", "usuario", "--instalar", instalar.join(","), "--remover", remover.join(",")]);
        _sistemaNaFila = JSON.stringify(nativos) !== JSON.stringify(antes);
        if (_sistemaNaFila)
            _fila.push(["pkexec", "/usr/libexec/nyxz/componentes", "sistema", nativos.join(",")]);

        log = [];
        erro = "";
        terminou = false;
        precisaReiniciar = false;
        rodando = true;
        _proximo();
    }

    function _proximo() {
        if (_fila.length === 0) {
            rodando = false;
            terminou = true;
            passo = erro ? "Terminou com problemas" : "Pronto";
            return;
        }
        const cmd = _fila.shift();
        processo.command = cmd;
        processo.running = true;
    }

    function _linha(l) {
        const partes = l.split("|");
        if (partes[0] === "PASSO") {
            passo = partes.slice(1).join("|");
        } else if (partes[0] === "LOG") {
            const novo = log.concat([partes.slice(1).join("|")]);
            log = novo.slice(-200);
        } else if (partes[0] === "FIM") {
            if (partes[1] === "erro") erro = partes.slice(2).join("|");
        }
    }

    property Process processo: Process {
        stdout: SplitParser { onRead: dados => ex._linha(dados) }
        stderr: SplitParser { onRead: dados => ex._linha("LOG|" + dados) }
        onExited: (codigo, status) => {
            const eraSistema = command.length > 0 && command[0] === "pkexec";
            if (codigo === 126 || codigo === 127) {
                // pkexec: senha cancelada ou negada
                ex.erro = "A senha de administrador não foi confirmada; os apps nativos não foram alterados.";
            } else if (codigo !== 0 && !ex.erro) {
                ex.erro = "Algo deu errado (código " + codigo + ").";
            } else if (codigo === 0 && eraSistema) {
                ex.precisaReiniciar = true;
            }
            ex._proximo();
        }
    }
}
