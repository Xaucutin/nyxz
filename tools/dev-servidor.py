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


def empacotar() -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        for arq in sorted(SHELL.rglob("*")):
            if arq.is_file():
                tar.add(arq, arcname=str(arq.relative_to(SHELL)).replace("\\", "/"))
    return buf.getvalue()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.rstrip("/") != "/shell.tgz":
            self.send_error(404)
            return
        dados = empacotar()
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
