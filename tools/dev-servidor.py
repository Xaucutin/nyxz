"""Servidor de desenvolvimento do shell da Nyxz.

Empacota system_files/etc/xdg/quickshell/nyxz em shell.tgz a cada pedido e serve em
http://127.0.0.1:80/shell.tgz. Dentro da VM do VirtualBox (rede NAT), o PC aparece
como 10.0.2.2, então `nyx dev` baixa e recarrega o shell sem esperar o build.

Uso: python tools/dev-servidor.py
"""
import io
import tarfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SHELL = RAIZ / "system_files" / "etc" / "xdg" / "quickshell" / "nyxz"


LOGIN = SHELL.parent / "nyxz-login"


def empacotar(pastas) -> bytes:
    """Junta as pastas (a última vence) num .tgz com caminhos relativos."""
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        for pasta, filtro in pastas:
            for arq in sorted(pasta.rglob("*")):
                rel = str(arq.relative_to(pasta)).replace("\\", "/")
                if arq.is_file() and filtro(rel):
                    info = tar.gettarinfo(arq, arcname=rel)
                    # No Windows não há bit de execução: scripts e binários saem como 0755.
                    info.mode = 0o755 if rel.startswith(("libexec/", "bin/")) else 0o644
                    info.uid = info.gid = 0
                    info.uname = info.gname = "root"
                    with open(arq, "rb") as f:
                        tar.addfile(info, f)
    return buf.getvalue()


ROTAS = {
    "/shell.tgz": lambda: empacotar([(SHELL, lambda r: True)]),
    # Tela de login: os arquivos dela + Tema.qml e icones/ do shell principal
    "/login.tgz": lambda: empacotar([
        (SHELL, lambda r: r == "Tema.qml" or r.startswith("icones/")),
        (LOGIN, lambda r: True),
    ]),
    # Configurações: os arquivos dela + Tema.qml, Deslizante.qml e icones/
    "/config.tgz": lambda: empacotar([
        (SHELL, lambda r: r in ("Tema.qml", "Deslizante.qml") or r.startswith("icones/")),
        (SHELL.parent / "nyxz-config", lambda r: True),
    ]),
    # Nyxz Setup: os arquivos dele + tema, ícones e componentes das Configurações
    "/setup.tgz": lambda: empacotar([
        (SHELL, lambda r: r == "Tema.qml" or r.startswith("icones/")),
        (SHELL.parent / "nyxz-config", lambda r: r in ("Botao.qml", "ListaComponentes.qml", "Executor.qml", "Comando.qml")),
        (SHELL.parent / "nyxz-setup", lambda r: True),
    ]),
    # Dev Hub: os arquivos dele + tema, ícones e componentes das Configurações
    "/dev.tgz": lambda: empacotar([
        (SHELL, lambda r: r == "Tema.qml" or r.startswith("icones/")),
        (SHELL.parent / "nyxz-config", lambda r: r in ("Botao.qml", "Pagina.qml", "Linha.qml", "Comando.qml", "Interruptor.qml")),
        (SHELL.parent / "nyxz-dev", lambda r: True),
    ]),
    # Scripts e dados de /usr (nyx dev usr): vão para um /usr temporário (bootc usr-overlay)
    "/usr.tgz": lambda: empacotar([
        (RAIZ / "system_files" / "usr", lambda r: r.startswith(("libexec/nyxz/", "share/nyxz/", "share/kio/", "bin/", "lib/systemd/user/"))),
    ]),
}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        rota = ROTAS.get(self.path.rstrip("/"))
        if rota is None:
            self.send_error(404)
            return
        dados = rota()
        self.send_response(200)
        self.send_header("Content-Type", "application/gzip")
        self.send_header("Content-Length", str(len(dados)))
        self.end_headers()
        self.wfile.write(dados)

    def log_message(self, fmt, *args):
        print("[dev]", self.address_string(), fmt % args, flush=True)


if __name__ == "__main__":
    print(f"Servindo {SHELL} em http://127.0.0.1:80/shell.tgz", flush=True)
    ThreadingHTTPServer(("127.0.0.1", 80), Handler).serve_forever()
