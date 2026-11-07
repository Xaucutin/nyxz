import QtQuick
import Quickshell.Io

// Roda um comando e entrega a saída inteira em "pronto(saida, codigo)".
Process {
    id: comando
    signal pronto(string saida, int codigo)
    property string _saida: ""

    stdout: StdioCollector {
        onStreamFinished: comando._saida = this.text
    }
    onExited: (codigo, status) => comando.pronto(comando._saida, codigo)

    function rodar(cmd) {
        if (running) return;
        _saida = "";
        command = cmd;
        running = true;
    }
}
