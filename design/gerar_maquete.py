"""Gera design/maquete.html: telas estáticas da interface da Nyxz.

Cada tela é um <section class="screen"> de 1920x1080, enviada ao Figma
(uma tela por frame) e também abrível direto no navegador.
"""
from pathlib import Path

# ---------------------------------------------------------------- tokens
C = {
    "bg0": "#09090D", "bg1": "#0E0E12", "bg2": "#131318", "bg3": "#19191F",
    "line": "#1E1E25", "line2": "#2A2A32",
    "tx": "#F4F2F8", "tx2": "#A09EAA", "tx3": "#64626E",
    "ok": "#7FB894", "warn": "#C9A86A", "err": "#D0676A", "info": "#8EA6C8",
}

# ---------------------------------------------------------------- marca
MARK = ('<path d="M72 221.893L107.902 196.312L148.293 221.893V275.746L72 345.307V221.893Z"/>'
        '<path d="M125.854 164.449H196.312L426.536 347.551H339.024L141.561 185.99L105.658 185.093L125.854 164.449Z"/>'
        '<path d="M163.103 274.4L185.542 253.756L214.264 273.502L276.195 314.79L244.781 346.205L163.103 274.4Z"/>'
        '<path d="M361.463 164.449H440L334.536 260.039L294.146 226.38L361.463 164.449Z"/>')


def mark(w=28, color=C["tx"], opacity=1.0, extra=""):
    h = round(w / 2, 1)
    return (f'<svg width="{w}" height="{h}" viewBox="72 164 368 184" fill="{color}" fill-opacity="{opacity}" {extra}>'
            f'{MARK}</svg>')


# ---------------------------------------------------------------- ícones
P = {
    "search": '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    "terminal": '<path d="m4 17 6-5-6-5"/><path d="M12 19h8"/>',
    "code": '<path d="m16 18 6-6-6-6"/><path d="m8 6-6 6 6 6"/>',
    "folder": '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
    "globe": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a14 14 0 0 1 0 18a14 14 0 0 1 0-18"/>',
    "shield": '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
    "chat": '<path d="M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12z"/>',
    "db": '<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v14c0 1.7 3.6 3 8 3s8-1.3 8-3V5"/><path d="M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>',
    "volume": '<path d="M11 5 6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/>',
    "mic": '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3"/>',
    "headphones": '<path d="M3 14v-2a9 9 0 0 1 18 0v2"/><rect x="3" y="14" width="4" height="7" rx="1.5"/><rect x="17" y="14" width="4" height="7" rx="1.5"/>',
    "monitor": '<rect x="2" y="4" width="20" height="13" rx="2"/><path d="M8 21h8"/><path d="M12 17v4"/>',
    "network": '<rect x="9" y="2" width="6" height="6" rx="1"/><rect x="2" y="16" width="6" height="6" rx="1"/><rect x="16" y="16" width="6" height="6" rx="1"/><path d="M5 16v-3h14v3"/><path d="M12 8v5"/>',
    "bell": '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
    "sliders": '<path d="M4 21v-7"/><path d="M4 10V3"/><path d="M12 21v-9"/><path d="M12 8V3"/><path d="M20 21v-5"/><path d="M20 12V3"/><path d="M1 14h6"/><path d="M9 8h6"/><path d="M17 16h6"/>',
    "key": '<circle cx="7.5" cy="15.5" r="4.5"/><path d="m21 2-9.6 9.6"/><path d="m15.5 7.5 3 3L22 7l-3-3"/>',
    "box": '<path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="M3 8l9 5 9-5"/><path d="M12 13v8"/>',
    "send": '<path d="M22 2 11 13"/><path d="M22 2 15 22l-4-9-9-4z"/>',
    "copy": '<rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "chev": '<path d="m9 18 6-6-6-6"/>',
    "chevdown": '<path d="m6 9 6 6 6-6"/>',
    "music": '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
    "game": '<path d="M6 11h4M8 9v4"/><path d="M15 12h.01M18 10h.01"/><rect x="2" y="6" width="20" height="12" rx="6"/>',
    "ext": '<path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M21 14v5a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5"/>',
    "check": '<path d="M20 6 9 17l-5-5"/>',
    "eye": '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    "more": '<circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/>',
    "braces": '<path d="M8 3H7a2 2 0 0 0-2 2v5a2 2 0 0 1-2 2 2 2 0 0 1 2 2v5a2 2 0 0 0 2 2h1"/><path d="M16 21h1a2 2 0 0 0 2-2v-5a2 2 0 0 1 2-2 2 2 0 0 1-2-2V5a2 2 0 0 0-2-2h-1"/>',
    "file": '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/>',
}


def ic(name, size=17, color=C["tx2"], sw=1.6):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{color}" '
            f'stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round">{P[name]}</svg>')


# ---------------------------------------------------------------- CSS
CSS = """
*{box-sizing:border-box;margin:0;padding:0}
body{background:#050507;font-family:'Geist',sans-serif;color:#F4F2F8;padding:40px;display:flex;flex-direction:column;gap:80px;align-items:flex-start}
.screen{width:1920px;height:1080px;position:relative;overflow:hidden;background:#09090D;flex:none}
.mono{font-family:'Geist Mono',monospace}
.abs{position:absolute}
.row{display:flex;align-items:center}
.col{display:flex;flex-direction:column}
.nw{white-space:nowrap}
.wall{position:absolute;left:0;top:0;width:1920px;height:1080px;background:radial-gradient(1400px 900px at 50% 0%,#101016,#09090D 70%)}
.dim{position:absolute;left:0;top:0;width:1920px;height:1080px;background:rgba(4,4,6,0.6)}
.taskbar{position:absolute;left:10px;right:10px;bottom:10px;height:40px;background:#0C0C10;border-radius:8px;display:flex;align-items:center;padding:0 6px;gap:2px}
.ws{display:flex;margin:0 4px 0 8px}
.ws div{width:24px;height:30px;display:flex;align-items:center;justify-content:center;font-family:'Geist Mono',monospace;font-size:12px;color:#4C4A55;position:relative}
.ws .occ{color:#8A8894}
.ws .on{color:#F4F2F8}
.vsep{width:12px}
.app{width:34px;height:34px;border-radius:7px;display:flex;align-items:center;justify-content:center;position:relative}
.app.focus{background:#17171C}
.app .ind{position:absolute;bottom:1px;left:15px;width:4px;height:2px;border-radius:1px;background:#4C4A55}
.app.focus .ind{left:12px;width:10px;background:#F4F2F8}
.tray{display:flex;align-items:center}
.tray .t{width:30px;height:30px;border-radius:7px;display:flex;align-items:center;justify-content:center}
.tray .t.on{background:#17171C}
.clock{display:flex;align-items:baseline;gap:10px;padding:0 6px 0 4px;white-space:nowrap}
.clock b{font-size:13px;font-weight:500;color:#F4F2F8}
.clock span{display:none}
.win{position:absolute;background:#0E0E12;border:1px solid #17171D;border-radius:8px;overflow:hidden;display:flex;flex-direction:column}
.win.focus{border-color:#26262E}
.win-h{display:none;height:32px;flex:none;display:flex;align-items:center;padding:0 14px;font-size:12px;color:#64626E}
.term{padding:22px 26px;font-family:'Geist Mono',monospace;font-size:13.5px;line-height:1.7;color:#CFCDD6}
.u{color:#9FB0C8}.d{color:#5A5864}.g{color:#7FB894}.y{color:#C9A86A}.w{color:#F4F2F8}
.kw{color:#B6A4D6}.s{color:#A3BE9C}.n{color:#D2B488}.pr{color:#9DB3D3}.cm{color:#55535F}
.panel{position:absolute;background:#0F0F13;border:1px solid #23232A;border-radius:10px;box-shadow:0 20px 50px rgba(0,0,0,0.5)}
.menu{position:absolute;width:230px;background:#111116;border:1px solid #25252C;border-radius:8px;padding:5px;box-shadow:0 16px 40px rgba(0,0,0,0.55)}
.mi{height:32px;border-radius:5px;display:flex;align-items:center;gap:10px;padding:0 10px;font-size:13px;color:#CFCDD6;white-space:nowrap}
.mi .hint{margin-left:auto;font-size:12px;color:#55535F;white-space:nowrap}
.msep{height:1px;background:#1E1E25;margin:4px 6px}
.lbl{font-size:12px;font-weight:500;color:#64626E;white-space:nowrap}
.btn{height:32px;border-radius:6px;padding:0 12px;display:flex;align-items:center;gap:7px;font-size:13px;background:#16161B;border:1px solid #26262D;color:#E4E2EA;flex:none;white-space:nowrap}
.btn.pri{background:#F4F2F8;border-color:#F4F2F8;color:#09090D;font-weight:500}
.btn.ghost{background:transparent;border-color:transparent;color:#A09EAA;padding:0 8px}
.st{display:flex;align-items:center;gap:7px;font-size:13px;white-space:nowrap}
.dot{width:6px;height:6px;border-radius:3px;flex:none}
.track{height:3px;border-radius:2px;background:#24242B;position:relative;flex:1}
.fill{position:absolute;left:0;top:0;height:3px;border-radius:2px;background:#CFCDD6}
.knob{position:absolute;top:-4px;width:11px;height:11px;border-radius:6px;background:#F4F2F8}
.tog{width:30px;height:17px;border-radius:9px;background:#25252C;position:relative;flex:none}
.tog .k{position:absolute;top:3px;left:3px;width:11px;height:11px;border-radius:6px;background:#6E6C78}
.tog.on{background:#E4E2EA}
.tog.on .k{left:16px;background:#09090D}
.hr{height:1px;background:#1A1A20}
"""


def tog(on):
    return f'<div class="tog{" on" if on else ""}"><div class="k"></div></div>'


# ---------------------------------------------------------------- peças
def wallpaper(dim=False):
    return '<div class="wall"></div>' + ('<div class="dim"></div>' if dim else "")


APPS = [("terminal", "Terminal"), ("folder", "Arquivos"), ("shield", "Brave"), ("code", "Editor"),
        ("chat", "Vesktop"), ("game", "Steam"), ("braces", "Dev Hub"), ("music", "Spotify")]


def taskbar(focus="Terminal", tray_on=None):
    apps = ""
    for icon, name in APPS:
        cls = "app focus" if name == focus else "app"
        apps += f'<div class="{cls}">{ic(icon, 19, C["tx"] if name == focus else C["tx2"])}<div class="ind"></div></div>'
    tray = "".join(f'<div class="{"t on" if t == tray_on else "t"}">{ic(t, 16, C["tx"] if t == tray_on else C["tx3"])}</div>'
                   for t in ["network", "volume", "mic", "bell"])
    return f'''
<div class="taskbar">
  <div class="row" style="width:34px;height:34px;justify-content:center">{mark(26)}</div>
  <div class="ws"><div class="on"><span style="border-bottom:2px solid #F4F2F8;padding:0 1px 3px">1</span></div><div class="occ">2</div><div class="occ">3</div><div>4</div><div>5</div></div>
  <div class="vsep"></div>
  {apps}
  <div style="flex:1"></div>
  <div class="tray">{tray}</div>
  <div class="vsep"></div>
  <div class="clock"><span>sáb 7 nov</span><b>14:32</b></div>
</div>'''


def slider(pct):
    return (f'<div class="track"><div class="fill" style="width:{pct}%"></div>'
            f'<div class="knob" style="left:calc({pct}% - 5px)"></div></div>')


# ---------------------------------------------------------------- 01 desktop
def tela_desktop():
    ff = [("os", "Nyxz 0.1"), ("base", "Fedora Atomic · bootc"), ("wm", "Hyprland"),
          ("term", "Ghostty · fish"), ("cpu", "Ryzen 5 5600GT"), ("gpu", "Radeon RX 7600 8 GB"),
          ("mem", "3,4 / 15,5 GiB"), ("tela", "1920×1080 · 180 Hz"), ("disco", "48 / 476 GiB · btrfs")]
    ff_html = "".join(f'<div class="row"><span class=d style="width:72px;flex:none">{k}</span><span>{v}</span></div>' for k, v in ff)
    prompt = '<span class=u>~/projetos/loja</span> <span class=y>main</span> <span class=w>›</span>'
    term = f'''
<div class="win focus" style="left:10px;top:10px;width:935px;height:1010px">
  <div class="term">
    <div>{prompt} fastfetch</div>
    <div class="row" style="gap:48px;margin:22px 0 24px 8px">
      <div>{mark(190)}</div>
      <div class="col">{ff_html}</div>
    </div>
    <div>{prompt} nyx db start mariadb-loja</div>
    <div>mariadb-loja <span class=g>rodando</span> em localhost:3307 <span class=d>· MariaDB 11.4</span></div>
    <div style="margin-top:4px">{prompt} npm run dev</div>
    <div class=d style="white-space:pre">  VITE ready in 312 ms</div>
    <div style="white-space:pre">  Local   <span class=u>http://localhost:5173/</span></div>
    <div style="margin-top:4px">{prompt} <span style="display:inline-block;width:8px;height:17px;background:#CFCDD6;vertical-align:middle"></span></div>
  </div>
</div>'''
    code = [
        '<span class=kw>import</span> mysql <span class=kw>from</span> <span class=s>"mysql2/promise"</span>;',
        '',
        '<span class=kw>export const</span> db = mysql.<span class=pr>createPool</span>({',
        '  host: <span class=s>"localhost"</span>,',
        '  port: <span class=n>3307</span>,',
        '  user: <span class=s>"root"</span>,',
        '  password: process.env.DB_PASS,',
        '  database: <span class=s>"loja"</span>,',
        '});',
        '',
        '<span class=kw>export async function</span> <span class=pr>produtos</span>() {',
        '  <span class=kw>const</span> [rows] = <span class=kw>await</span> db.<span class=pr>query</span>(',
        '    <span class=s>"SELECT id, nome, preco FROM produtos LIMIT 50"</span>',
        '  );',
        '  <span class=kw>return</span> rows;',
        '}',
    ]
    lines = "".join(f'<div class="row"><span class=d style="width:30px;text-align:right;margin-right:20px">{i+1}</span><span style="white-space:pre">{l or " "}</span></div>'
                    for i, l in enumerate(code))
    editor = f'''
<div class="win" style="left:955px;top:10px;width:955px;height:1010px">
  <div class="term" style="font-size:13px">{lines}</div>
</div>'''
    toast = f'''
<div class="panel" style="right:26px;top:26px;width:340px;padding:14px 16px 10px">
  <div class="row" style="gap:8px"><span class="dot" style="background:{C["ok"]}"></span><span style="font-size:13px;font-weight:500;flex:1">mariadb-loja iniciado</span><span style="font-size:11px;color:#55535F">agora</span></div>
  <div class="mono" style="font-size:12px;color:#64626E;margin:4px 0 8px 14px">localhost:3307</div>
  <div class="row" style="gap:2px;margin-left:6px"><div class="btn ghost" style="height:26px;font-size:12px;color:#CFCDD6">Copiar conexão</div><div class="btn ghost" style="height:26px;font-size:12px">Abrir no Dev Hub</div></div>
</div>'''
    menu = f'''
<div class="menu" style="left:252px;bottom:58px">
  <div style="padding:8px 10px 6px;font-size:12px;color:#64626E">Brave</div>
  <div class="mi">Nova janela</div>
  <div class="msep"></div>
  <div class="mi">Aceleração gráfica <span style="margin-left:auto"></span>{tog(True)}</div>
  <div class="mi">Acesso à internet <span style="margin-left:auto"></span>{tog(True)}</div>
  <div class="msep"></div>
  <div class="mi">Fechar</div>
  <div class="msep"></div>
  <div class="mi" style="background:#1A1215;color:{C["err"]}">Finalizar tarefa</div>
</div>'''
    return f'<section class="screen" data-name="01 · Desktop">{wallpaper()}{term}{editor}{toast}{taskbar("Brave")}{menu}</section>'


# ---------------------------------------------------------------- 02 busca
def tela_busca():
    def row(icon, title, sub, right="", sel=False):
        bg = "background:#17171C;" if sel else ""
        return f'''<div class="row nw" style="height:46px;border-radius:6px;padding:0 12px;gap:14px;{bg}">
  {ic(icon, 16, C["tx"] if sel else C["tx3"])}
  <span style="font-size:14px;color:{C["tx"] if sel else "#CFCDD6"}">{title}</span>
  <span style="font-size:13px;color:#55535F">{sub}</span>
  <span style="margin-left:auto;font-size:12px;color:#55535F">{right}</span></div>'''

    res = f'''
<div class="lbl" style="padding:12px 12px 6px">Ações</div>
{row("plus", "Criar instância MySQL", "versão, porta e senha", "Enter", True)}
{row("db", "Abrir mariadb-loja no Adminer", "rodando em :3307")}
{row("copy", "Copiar string de conexão", '<span class="mono">mysql://root@localhost:3307/loja</span>')}
<div class="lbl" style="padding:14px 12px 6px">Aplicativos</div>
{row("db", "DBeaver", "", "App")}
{row("braces", "Dev Hub", "serviços locais", "Nyxz")}
<div class="lbl" style="padding:14px 12px 6px">Arquivos</div>
{row("file", "backup-loja-2026-11-02.sql", "~/projetos/loja/db")}'''
    panel = f'''
<div class="panel" style="left:610px;top:220px;width:700px;overflow:hidden">
  <div class="row" style="height:58px;padding:0 18px;gap:14px">
    {ic("search", 18, C["tx3"])}
    <div class="row" style="font-size:18px;color:#F4F2F8">mysql<span style="width:1.5px;height:21px;background:#F4F2F8;margin-left:2px"></span></div>
  </div>
  <div class="hr"></div>
  <div style="padding:4px 6px 8px">{res}</div>
</div>'''
    return f'<section class="screen" data-name="02 · Busca">{wallpaper(dim=True)}{panel}{taskbar("Terminal")}</section>'


# ---------------------------------------------------------------- 03 som
def tela_som():
    def dev(icon, name, sub, sel):
        return f'''<div class="row nw" style="height:40px;border-radius:6px;padding:0 10px;gap:12px;{"background:#16161B;" if sel else ""}">{ic(icon, 16, C["tx"] if sel else C["tx3"])}
<span style="font-size:13px;color:{C["tx"] if sel else C["tx2"]}">{name}</span><span style="font-size:12px;color:#55535F">{sub}</span>
<span style="margin-left:auto">{ic("check", 15, C["tx"]) if sel else ""}</span></div>'''

    def app(icon, name, out, pct, muted=False):
        op = "opacity:0.4;" if muted else ""
        return f'''<div class="col" style="gap:10px;padding:10px 10px 12px;{op}">
<div class="row" style="gap:12px">{ic(icon, 16, C["tx2"])}<span style="font-size:13px;flex:1">{name}</span>
  <span class="row nw" style="gap:4px;font-size:12px;color:#8A8894">{out} {ic("chevdown", 12, C["tx3"])}</span></div>
<div class="row" style="gap:12px;padding-left:28px">{slider(0 if muted else pct)}<span class="mono" style="font-size:11px;color:#8A8894;width:32px;text-align:right">{"mudo" if muted else pct}</span></div>
</div>'''

    bars = "".join(f'<div style="width:5px;height:10px;border-radius:1px;background:{"#CFCDD6" if i < 12 else "#25252C"}"></div>'
                   for i in range(30))
    perfis = "".join(f'<span class="nw" style="font-size:12.5px;padding:5px 10px;border-radius:5px;{"background:#1C1C22;color:#F4F2F8" if on else "color:#8A8894"}">{n}</span>'
                     for n, on in [("Normal", False), ("Chamada", True), ("Jogo", False)])
    panel = f'''
<div class="panel" style="right:10px;bottom:58px;width:400px;padding:14px 12px 10px">
  <div class="row" style="padding:0 6px 12px"><span style="font-size:14px;font-weight:500;flex:1">Som</span><div class="row" style="gap:2px">{perfis}</div></div>
  <div class="lbl" style="padding:4px 10px 6px">Saída</div>
  {dev("headphones", "Headset Logitech", "USB", True)}
  {dev("monitor", "Monitor Valak", "DisplayPort", False)}
  <div class="row" style="gap:12px;padding:12px 10px 8px">{ic("volume", 15, C["tx3"])}{slider(72)}<span class="mono" style="font-size:11px;color:#8A8894;width:32px;text-align:right">72</span></div>
  <div class="hr" style="margin:8px 6px"></div>
  <div class="lbl" style="padding:4px 10px 0">Por aplicativo</div>
  {app("chat", "Vesktop", "Headset", 85)}
  {app("music", "Spotify", "Monitor", 40)}
  {app("shield", "Brave", "Headset", 60)}
  {app("game", "Steam", "Headset", 100, muted=True)}
  <div class="hr" style="margin:4px 6px 10px"></div>
  <div class="row" style="gap:12px;padding:0 10px">{ic("mic", 16, C["tx2"])}<span style="font-size:13px;flex:1">Fifine USB</span><span class="mono" style="font-size:11px;color:#55535F">−18 dB</span></div>
  <div class="row" style="gap:3px;padding:10px 10px 10px 38px">{bars}</div>
  <div class="row" style="height:34px;padding:0 10px"><span style="font-size:13px;flex:1;color:#CFCDD6">Supressão de ruído</span>{tog(True)}</div>
  <div class="row" style="height:34px;padding:0 10px"><span style="font-size:13px;flex:1;color:#CFCDD6">Ouvir o próprio microfone</span>{tog(False)}</div>
  <div class="row" style="height:34px;padding:0 10px"><span style="font-size:13px;flex:1;color:#CFCDD6">Equalizador</span><span style="font-size:12px;color:#8A8894">Voz</span></div>
</div>'''
    return f'<section class="screen" data-name="03 · Som">{wallpaper()}{panel}{taskbar("Spotify", tray_on="volume")}</section>'


# ---------------------------------------------------------------- Dev Hub
def devhub(active, main_html):
    nav = [("db", "Serviços locais"), ("key", "SSH"), ("chat", "Discord Studio"),
           ("send", "Cliente de API"), ("box", "Containers"), ("sliders", "Variáveis")]
    items = "".join(
        f'<div class="row nw" style="height:34px;border-radius:6px;padding:0 10px;gap:11px;{"background:#16161B;" if n == active else ""}">'
        f'<span style="font-size:13px;color:{C["tx"] if n == active else C["tx2"]}">{n}</span></div>'
        for i, n in nav)
    projs = "".join(f'<div class="row" style="height:30px;padding:0 10px"><span style="font-size:13px;color:#8A8894">{n}</span></div>'
                    for n in ["loja", "tcc-api", "bot-atlas"])
    side = f'''
<div class="col" style="width:200px;flex:none;padding:18px 10px">
  <div class="row" style="gap:10px;padding:2px 10px 22px">{mark(22)}<span style="font-size:14px;font-weight:500">Dev Hub</span></div>
  <div class="col" style="gap:1px">{items}</div>
</div>'''
    return f'''
<div class="win focus" style="left:10px;top:10px;width:1900px;height:1010px;flex-direction:row">
  {side}
  <div class="col" style="flex:1;min-width:0">{main_html}</div>
</div>'''


def status(on):
    return (f'<span class="st"><span class="dot" style="background:{C["ok"]}"></span><span style="color:#CFCDD6">Rodando</span></span>' if on
            else '<span class="st"><span class="dot" style="background:#3A3A42"></span><span style="color:#64626E">Parado</span></span>')


# ---------------------------------------------------------------- 04 serviços
def tela_servicos():
    rows = [("mariadb-loja", "MariaDB 11.4", "3307", True, "182 MB", True),
            ("postgres-tcc", "PostgreSQL 16", "5433", False, "", False),
            ("redis-cache", "Redis 7.4", "6379", True, "9 MB", False),
            ("php-apache-loja", "PHP 8.3 + Apache", "8080", True, "64 MB", False)]
    trs = "".join(f'''<div class="row nw" style="height:48px;padding:0 14px;border-radius:6px;{"background:#14141A;" if sel else ""}">
  <span style="width:260px;font-size:13.5px;color:{C["tx"]}">{name}</span>
  <span style="width:200px;font-size:13px;color:#8A8894">{tipo}</span>
  <span class="mono" style="width:110px;font-size:12.5px;color:#CFCDD6">{porta}</span>
  <div class="row" style="width:140px">{status(on)}</div>
  <span class="mono" style="width:90px;font-size:12px;color:#64626E">{mem}</span>
  <div style="flex:1"></div>{ic("more", 15, C["tx3"])}</div>''' for name, tipo, porta, on, mem, sel in rows)
    head = "".join(f'<span class="lbl" style="width:{w}px">{t}</span>' for t, w in
                   [("Nome", 260), ("Tipo", 200), ("Porta", 110), ("Estado", 140), ("Memória", 90)])
    modelos = "".join(f'<div class="row" style="height:36px;padding:0 12px;gap:8px;border:1px solid #1E1E25;border-radius:6px">{ic("plus", 13, C["tx3"])}<span class="nw" style="font-size:13px;color:#CFCDD6">{n}</span></div>'
                      for n in ["MariaDB", "MySQL", "PostgreSQL", "MongoDB", "Redis", "PHP + Apache"])
    lista = f'''
<div class="col" style="flex:1;padding:22px 26px;min-width:0">
  <div class="row" style="padding:0 14px 10px">{head}</div>
  <div class="hr" style="margin-bottom:6px"></div>
  <div class="col" style="gap:1px">{trs}</div>
  <div class="lbl" style="padding:36px 0 12px">Novo a partir de</div>
  <div class="row" style="gap:8px">{modelos}</div>
</div>'''
    kv = "".join(f'<div class="row" style="height:28px"><span style="width:90px;font-size:12.5px;color:#64626E">{k}</span><span class="mono" style="font-size:12.5px;color:#CFCDD6;flex:1">{v}</span>{x}</div>'
                 for k, v, x in [("Host", "localhost", ""), ("Porta", "3307", ""), ("Usuário", "root", ""),
                                 ("Senha", "••••••••••", ic("eye", 14, C["tx3"])), ("Banco", "loja", "")])
    snaps = "".join(f'''<div class="row nw" style="height:40px"><span style="font-size:13px;color:#CFCDD6;width:170px">{n}</span>
<span class="mono" style="font-size:11.5px;color:#55535F;flex:1">{d}</span><div class="btn" style="height:26px;font-size:12px;padding:0 10px">Restaurar</div></div>'''
                    for n, d in [("antes-da-migracao", "02/11 14:10"), ("base-limpa", "28/10 09:42")])
    logs = "".join(f'<div class="nw"><span class=d>{t}</span>  {m}</div>' for t, m in [
        ("14:31:56", "Starting MariaDB 11.4 server"),
        ("14:31:57", "InnoDB: Buffer pool(s) load completed"),
        ("14:31:57", "Server socket created on IP: '::'"),
        ("14:31:58", "mariadbd: ready for connections."),
        ("14:31:58", "Version: '11.4'  port: 3307"),
    ])
    detalhe = f'''
<div class="col" style="width:460px;flex:none;border-left:1px solid #1A1A20;padding:22px 24px;gap:22px">
  <div class="col" style="gap:6px">
    <div class="row" style="gap:10px"><span style="font-size:16px;font-weight:500;flex:1">mariadb-loja</span>{status(True)}</div>
    <span style="font-size:12.5px;color:#64626E">MariaDB 11.4 · projeto loja</span>
  </div>
  <div class="row" style="gap:6px"><div class="btn">Parar</div><div class="btn">Reiniciar</div><div class="btn">Adminer {ic("ext", 13, C["tx3"])}</div></div>
  <div class="col">
    <div class="row" style="margin-bottom:6px"><span class="lbl" style="flex:1">Conexão</span><span class="nw" style="font-size:12px;color:#8A8894">Copiar .env</span></div>
    {kv}
    <div class="row" style="margin-top:10px;height:36px;border-radius:6px;background:#0B0B0F;border:1px solid #1E1E25;padding:0 10px 0 12px;gap:8px">
      <span class="mono nw" style="font-size:12px;color:#8A8894;flex:1">mysql://root:••••@localhost:3307/loja</span>{ic("copy", 14, C["tx3"])}</div>
  </div>
  <div class="col">
    <div class="row" style="margin-bottom:2px"><span class="lbl" style="flex:1">Snapshots</span><span class="nw" style="font-size:12px;color:#8A8894">Tirar snapshot</span></div>
    {snaps}
  </div>
  <div class="col" style="flex:1">
    <span class="lbl" style="margin-bottom:8px">Logs</span>
    <div class="mono" style="font-size:11.5px;line-height:1.8;color:#8A8894;white-space:pre">{logs}</div>
  </div>
  <div class="row" style="gap:6px"><div class="btn">Exportar dump</div><div style="flex:1"></div><div class="btn" style="color:{C["err"]}">Resetar banco</div></div>
</div>'''
    main = f'''
<div class="row" style="height:64px;flex:none;padding:0 26px;gap:12px">
  <span style="font-size:18px;font-weight:500;flex:1">Serviços locais</span>
  <div class="row" style="width:240px;height:32px;border-radius:6px;background:#121217;border:1px solid #1E1E25;padding:0 10px;gap:8px">{ic("search", 14, C["tx3"])}<span style="font-size:13px;color:#55535F">Filtrar</span></div>
  <div class="btn pri">Novo serviço</div>
</div>
<div class="row" style="flex:1;align-items:stretch;min-height:0">{lista}{detalhe}</div>'''
    return f'<section class="screen" data-name="04 · Dev Hub — Serviços locais">{wallpaper()}{devhub("Serviços locais", main)}{taskbar("Dev Hub")}</section>'


# ---------------------------------------------------------------- 05 discord
def tela_discord():
    code = [
        '<span class=kw>import</span> { EmbedBuilder, <span class=kw>type</span> GuildMember } <span class=kw>from</span> <span class=s>"discord.js"</span>;',
        '',
        '<span class=kw>export const</span> <span class=pr>boasVindas</span> = (membro: GuildMember) =&gt;',
        '  <span class=kw>new</span> EmbedBuilder()',
        '    .<span class=pr>setColor</span>(<span class=n>0x9db3d3</span>)',
        '    .<span class=pr>setAuthor</span>({ name: <span class=s>"Servidor Dev BR"</span> })',
        '    .<span class=pr>setTitle</span>(<span class=s>`Bem-vindo(a), ${membro.displayName}!`</span>)',
        '    .<span class=pr>setDescription</span>(',
        '      <span class=s>"Leia as regras em #regras e escolha seus cargos em #cargos."</span>',
        '    )',
        '    .<span class=pr>setThumbnail</span>(membro.<span class=pr>displayAvatarURL</span>())',
        '    .<span class=pr>addFields</span>(',
        '      { name: <span class=s>"Membro nº"</span>, value: <span class=s>"1.284"</span>, inline: <span class=kw>true</span> },',
        '      { name: <span class=s>"Entrou em"</span>, value: <span class=s>"07/11/2026"</span>, inline: <span class=kw>true</span> },',
        '      { name: <span class=s>"Cargo"</span>, value: <span class=s>"@novato"</span>, inline: <span class=kw>true</span> },',
        '    )',
        '    .<span class=pr>setFooter</span>({ text: <span class=s>"Atlas · boas-vindas"</span> })',
        '    .<span class=pr>setTimestamp</span>();',
    ]
    lines = "".join(f'<div class="row" style="{"background:#121217;" if i == 6 else ""}"><span class=d style="width:42px;text-align:right;margin-right:20px">{i+1}</span>'
                    f'<span style="white-space:pre">{l or " "}</span></div>' for i, l in enumerate(code))
    files = "".join(f'<div class="row" style="height:30px;border-radius:5px;padding:0 10px;{"background:#16161B;" if on else ""}"><span class="mono" style="font-size:12.5px;color:{C["tx"] if on else "#8A8894"}">{n}</span></div>'
                    for n, on in [("boasVindas.ts", True), ("regras.ts", False), ("ticket.ts", False), ("ban.ts", False)])
    fields = "".join(f'<div class="col" style="gap:2px;flex:1"><span style="font-size:12px;font-weight:700;color:#F2F3F5">{n}</span><span style="font-size:14px;color:#DBDEE1">{v}</span></div>'
                     for n, v in [("Membro nº", "1.284"), ("Entrou em", "07/11/2026"), ("Cargo", '<span style="color:#C9CDFB">@novato</span>')])
    preview = f'''
<div class="col" style="width:580px;flex:none;border-left:1px solid #1A1A20">
  <div class="row nw" style="height:44px;padding:0 18px;gap:14px">
    <span class="lbl" style="flex:1">Prévia</span>
    <span class="st" style="font-size:12px;color:#8A8894"><span class="dot" style="background:{C["ok"]}"></span>sincronizada</span>
    <span style="font-size:12px;color:#8A8894">Editor visual</span>
  </div>
  <div class="col" style="margin:4px 18px 18px;border-radius:8px;background:#313338;overflow:hidden">
    <div class="row" style="height:40px;padding:0 16px;gap:8px;border-bottom:1px solid #26272B;font-size:14px;color:#F2F3F5;font-weight:600"><span style="color:#80848E;font-size:18px">#</span> testes</div>
    <div class="row" style="padding:16px 16px 20px;gap:14px;align-items:flex-start">
      <div style="width:40px;height:40px;border-radius:20px;background:#3F4147;flex:none;display:flex;align-items:center;justify-content:center;font-weight:600;color:#DBDEE1">A</div>
      <div class="col" style="gap:6px">
        <div class="row nw" style="gap:6px"><span style="font-size:15px;font-weight:600;color:#F2F3F5">Atlas</span>
          <span style="font-size:10px;font-weight:700;color:#fff;background:#5865F2;border-radius:3px;padding:1px 5px">APP</span>
          <span style="font-size:12px;color:#949BA4;margin-left:2px">Hoje às 14:32</span></div>
        <div class="row" style="width:430px;border-radius:4px;background:#2B2D31;align-items:stretch;overflow:hidden">
          <div style="width:4px;background:#9DB3D3;flex:none"></div>
          <div class="col" style="padding:10px 14px 14px;gap:8px;flex:1">
            <div class="row" style="align-items:flex-start;gap:14px">
              <div class="col" style="gap:7px;flex:1">
                <span style="font-size:13px;font-weight:600;color:#F2F3F5">Servidor Dev BR</span>
                <span style="font-size:16px;font-weight:700;color:#F2F3F5">Bem-vindo(a), Marina!</span>
                <span style="font-size:14px;line-height:1.4;color:#DBDEE1">Leia as regras em <span style="color:#C9CDFB">#regras</span> e escolha seus cargos em <span style="color:#C9CDFB">#cargos</span>.</span>
              </div>
              <div style="width:80px;height:80px;border-radius:6px;background:#4E5058;flex:none"></div>
            </div>
            <div class="row" style="gap:10px;align-items:flex-start;margin-top:2px">{fields}</div>
            <span style="font-size:12px;color:#B5BAC1;margin-top:4px">Atlas · boas-vindas · Hoje às 14:32</span>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="row mono nw" style="gap:20px;padding:0 20px;font-size:11.5px;color:#64626E"><span>título 22/256</span><span>descrição 60/4096</span><span>campos 3/25</span><span>total 151/6000</span></div>
  <div style="flex:1"></div>
  <div class="row" style="gap:6px;padding:14px 18px;border-top:1px solid #1A1A20">
    <div class="btn pri">Enviar para #testes</div><div class="btn">Copiar JSON</div>
  </div>
</div>'''
    editor = f'''
<div class="col" style="flex:1;min-width:0;background:#0B0B0F">
  <div class="row" style="height:38px;border-bottom:1px solid #1A1A20;padding:0 8px;gap:2px">
    <div class="row" style="height:28px;padding:0 12px;border-radius:5px;background:#131318"><span class="mono" style="font-size:12px">boasVindas.ts</span></div>
    <div class="row" style="height:28px;padding:0 12px"><span class="mono" style="font-size:12px;color:#55535F">index.ts</span></div>
  </div>
  <div class="mono" style="padding:14px 0;font-size:13px;line-height:1.75;color:#CFCDD6">{lines}</div>
  <div style="flex:1"></div>
  <div class="row mono nw" style="height:28px;border-top:1px solid #1A1A20;padding:0 16px;gap:18px;font-size:11px;color:#55535F"><span>TypeScript</span><span>7:42</span><span>sem erros</span></div>
</div>'''
    arquivos = f'''
<div class="col" style="width:190px;flex:none;border-right:1px solid #1A1A20;padding:12px 8px;gap:1px">
  <span class="lbl" style="padding:4px 10px 8px">embeds</span>
  {files}
  <div class="row" style="height:30px;padding:0 10px;margin-top:4px"><span style="font-size:12.5px;color:#64626E">+ Novo embed</span></div>
</div>'''
    tabs = "".join(f'<div class="row" style="height:40px;font-size:13px;color:{C["tx"] if on else "#64626E"};{"border-bottom:1.5px solid #F4F2F8;" if on else ""}">{t}</div>'
                   for t, on in [("Embeds", True), ("Comandos", False), ("Eventos", False), ("Logs", False)])
    main = f'''
<div class="row" style="height:72px;flex:none;padding:0 26px;gap:12px">
  <div class="col" style="gap:4px;flex:1">
    <div class="row" style="gap:12px"><span style="font-size:18px;font-weight:500">Atlas</span>{status(True)}</div>
    <span class="nw" style="font-size:12.5px;color:#64626E">discord.js 14 · TypeScript · 38 ms · token no cofre do sistema</span>
  </div>
  <div class="btn">Reiniciar</div><div class="btn">Parar</div>
</div>
<div class="row" style="padding:0 26px;gap:22px;border-bottom:1px solid #1A1A20">{tabs}</div>
<div class="row" style="flex:1;align-items:stretch;min-height:0">{arquivos}{editor}{preview}</div>'''
    return f'<section class="screen" data-name="05 · Dev Hub — Discord Studio">{wallpaper()}{devhub("Discord Studio", main)}{taskbar("Dev Hub")}</section>'


# ---------------------------------------------------------------- 00 marca
def tela_marca():
    cores = [("bg", C["bg0"]), ("surface", C["bg1"]), ("raised", C["bg2"]), ("line", C["line"]),
             ("text", C["tx"]), ("text-2", C["tx2"]), ("text-3", C["tx3"]),
             ("ok", C["ok"]), ("warn", C["warn"]), ("err", C["err"])]
    sw = "".join(f'<div class="col" style="gap:8px;width:120px"><div style="height:64px;border-radius:6px;background:{h};border:1px solid #23232A"></div>'
                 f'<span class="mono" style="font-size:11.5px;color:#8A8894">{n}</span><span class="mono" style="font-size:11.5px;color:#55535F">{h}</span></div>'
                 for n, h in cores)
    return f'''<section class="screen" data-name="00 · Marca" style="padding:120px 140px">
<div class="row" style="gap:120px;margin-bottom:140px">
  {mark(420)}
  <div class="col" style="gap:14px">
    <span style="font-size:64px;font-weight:600;letter-spacing:-0.03em">Nyxz</span>
    <span class="nw" style="font-size:16px;color:#64626E">Hyprland · Fedora Atomic</span>
  </div>
</div>
<div class="row" style="gap:16px;margin-bottom:56px">{sw}</div>
<div class="row nw" style="gap:80px">
  <span style="font-size:15px;color:#A09EAA">Geist — interface</span>
  <span class="mono" style="font-size:15px;color:#A09EAA">Geist Mono — terminal, código, portas</span>
</div>
</section>'''


html = f'''<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><title>Nyxz — maquete</title>
<style>{CSS}</style></head><body>
{tela_marca()}
{tela_desktop()}
{tela_busca()}
{tela_som()}
{tela_servicos()}
{tela_discord()}
</body></html>'''

out = Path(__file__).with_name("maquete.html")
out.write_text(html, encoding="utf-8")
print(out, len(html))
