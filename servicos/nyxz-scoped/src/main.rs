//! nyxz-scoped — sabe o que está rodando (ARQUITETURA.md, seções 2.1 e 2.2).
//!
//! Serviço de usuário que acompanha:
//! - apps: escopos `app-*.scope` do systemd (cada app aberto pela Nyxz tem o seu);
//! - janelas: eventos do Hyprland (socket2), ligadas ao escopo pelo PID;
//! - jogos da Steam: a Steam abre os jogos dentro do escopo dela; aqui o jogo
//!   (processo `reaper SteamLaunch AppId=N` e filhos) é movido para um escopo
//!   próprio `app-steam-jogo-N.scope`, para Estatísticas, Modo jogo e rede por app.
//!
//! Publica tudo em D-Bus: serviço `org.nyxz.Apps`, objeto `/org/nyxz/Apps`,
//! interface `org.nyxz.Apps1` (métodos `Lista` e `Jogo`, sinais `Mudou`,
//! `JogoIniciou` e `JogoTerminou`). Teste: `busctl --user call org.nyxz.Apps
//! /org/nyxz/Apps org.nyxz.Apps1 Lista`.

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use futures_util::StreamExt;
use serde::Serialize;
use tokio::io::{AsyncBufReadExt, AsyncReadExt, AsyncWriteExt, BufReader, Lines};
use tokio::net::UnixStream;
use zbus::object_server::SignalEmitter;
use zbus::zvariant::{OwnedObjectPath, Value};

const CAMINHO: &str = "/org/nyxz/Apps";

// ------------------------------------------------------------------ estado

#[derive(Serialize, Clone, Default)]
struct Janela {
    endereco: String,
    classe: String,
    titulo: String,
    pid: u32,
}

#[derive(Serialize, Clone)]
struct App {
    unidade: String,
    nome: String,
    inicio: u64,
    jogo: Option<String>,
    janelas: Vec<Janela>,
}

#[derive(Default)]
struct Estado {
    apps: BTreeMap<String, App>,
    /// janelas sem escopo conhecido (ex.: abertas antes do serviço, fora do app.slice)
    soltas: Vec<Janela>,
    jogo: Option<(String, String)>, // (appid, unidade)
}

impl Estado {
    fn json(&self) -> String {
        #[derive(Serialize)]
        struct Saida<'a> {
            apps: Vec<&'a App>,
            soltas: &'a Vec<Janela>,
            jogo: Option<&'a str>,
        }
        serde_json::to_string(&Saida {
            apps: self.apps.values().collect(),
            soltas: &self.soltas,
            jogo: self.jogo.as_ref().map(|j| j.0.as_str()),
        })
        .unwrap_or_else(|_| "{}".into())
    }

    fn remover_janela(&mut self, endereco: &str) {
        for app in self.apps.values_mut() {
            app.janelas.retain(|j| j.endereco != endereco);
        }
        self.soltas.retain(|j| j.endereco != endereco);
    }
}

fn agora() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0)
}

fn eh_app(unidade: &str) -> bool {
    unidade.starts_with("app-") && unidade.ends_with(".scope")
}

/// "app-Hyprland-steam-1a2b3c.scope" / "app-graphical-steam@1a2b.scope" → "steam"
fn nome_do_escopo(unidade: &str) -> String {
    let mut s = unidade.trim_start_matches("app-").trim_end_matches(".scope");
    for prefixo in ["Hyprland-", "graphical-", "hyprland-"] {
        s = s.strip_prefix(prefixo).unwrap_or(s);
    }
    let s = s.split('@').next().unwrap_or(s);
    match s.rsplit_once('-') {
        Some((antes, fim)) if !antes.is_empty() && fim.chars().all(|c| c.is_ascii_hexdigit()) => antes.to_string(),
        _ => s.to_string(),
    }
}

// ------------------------------------------------------------------ D-Bus: o que publicamos

struct Servico {
    estado: Arc<Mutex<Estado>>,
}

#[zbus::interface(name = "org.nyxz.Apps1")]
impl Servico {
    /// Apps abertos (escopos), com as janelas de cada um, em JSON.
    fn lista(&self) -> String {
        self.estado.lock().map(|e| e.json()).unwrap_or_default()
    }

    /// AppId da Steam do jogo aberto agora, ou "" se nenhum.
    fn jogo(&self) -> String {
        self.estado
            .lock()
            .ok()
            .and_then(|e| e.jogo.as_ref().map(|j| j.0.clone()))
            .unwrap_or_default()
    }

    #[zbus(signal)]
    async fn mudou(emissor: &SignalEmitter<'_>) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn jogo_iniciou(emissor: &SignalEmitter<'_>, appid: &str) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn jogo_terminou(emissor: &SignalEmitter<'_>, appid: &str) -> zbus::Result<()>;
}

// ------------------------------------------------------------------ D-Bus: systemd do usuário

#[zbus::proxy(
    interface = "org.freedesktop.systemd1.Manager",
    default_service = "org.freedesktop.systemd1",
    default_path = "/org/freedesktop/systemd1"
)]
trait Systemd {
    fn subscribe(&self) -> zbus::Result<()>;

    fn list_units(
        &self,
    ) -> zbus::Result<
        Vec<(String, String, String, String, String, String, OwnedObjectPath, u32, String, OwnedObjectPath)>,
    >;

    fn start_transient_unit(
        &self,
        name: &str,
        mode: &str,
        properties: &[(&str, Value<'_>)],
        aux: &[(&str, &[(&str, Value<'_>)])],
    ) -> zbus::Result<OwnedObjectPath>;

    #[zbus(signal)]
    fn unit_new(&self, id: String, unit: OwnedObjectPath) -> zbus::Result<()>;

    #[zbus(signal)]
    fn unit_removed(&self, id: String, unit: OwnedObjectPath) -> zbus::Result<()>;
}

// ------------------------------------------------------------------ Hyprland

fn pasta_hyprland() -> Option<PathBuf> {
    let runtime = std::env::var("XDG_RUNTIME_DIR").ok()?;
    let base = Path::new(&runtime).join("hypr");
    if let Ok(assinatura) = std::env::var("HYPRLAND_INSTANCE_SIGNATURE") {
        let p = base.join(assinatura);
        if p.join(".socket2.sock").exists() {
            return Some(p);
        }
    }
    // Serviço iniciado sem a variável: usa a instância mais recente.
    std::fs::read_dir(&base)
        .ok()?
        .flatten()
        .filter(|e| e.path().join(".socket2.sock").exists())
        .max_by_key(|e| e.metadata().and_then(|m| m.modified()).ok())
        .map(|e| e.path())
}

async fn conectar_eventos() -> Option<Lines<BufReader<UnixStream>>> {
    let pasta = pasta_hyprland()?;
    let s = UnixStream::connect(pasta.join(".socket2.sock")).await.ok()?;
    Some(BufReader::new(s).lines())
}

/// PID da janela pelo `j/clients` do Hyprland (o evento openwindow não traz o PID).
async fn pid_da_janela(endereco: &str) -> u32 {
    let Some(pasta) = pasta_hyprland() else { return 0 };
    let Ok(mut s) = UnixStream::connect(pasta.join(".socket.sock")).await else { return 0 };
    if s.write_all(b"j/clients").await.is_err() {
        return 0;
    }
    let mut texto = String::new();
    if s.read_to_string(&mut texto).await.is_err() {
        return 0;
    }
    let alvo = format!("0x{endereco}");
    serde_json::from_str::<serde_json::Value>(&texto)
        .ok()
        .and_then(|v| {
            v.as_array()?.iter().find(|c| c["address"] == alvo.as_str())?["pid"].as_u64()
        })
        .unwrap_or(0) as u32
}

/// Escopo (unidade) de um processo, pelo /proc/<pid>/cgroup.
fn escopo_do_pid(pid: u32) -> Option<String> {
    let texto = std::fs::read_to_string(format!("/proc/{pid}/cgroup")).ok()?;
    let caminho = texto.lines().find_map(|l| l.strip_prefix("0::"))?;
    caminho.split('/').rev().find(|p| p.ends_with(".scope")).map(String::from)
}

// ------------------------------------------------------------------ jogos da Steam

/// Pasta do cgroup de uma unidade do usuário (procura nas fatias de app comuns).
fn cgroup_da_unidade(unidade: &str) -> Option<PathBuf> {
    // Raiz do systemd do usuário, a partir do cgroup deste próprio serviço:
    // "0::/user.slice/user-1000.slice/user@1000.service/app.slice/nyxz-scoped.service"
    let proprio = std::fs::read_to_string("/proc/self/cgroup").ok()?;
    let caminho = proprio.lines().find_map(|l| l.strip_prefix("0::"))?;
    let fim = caminho.find(".service/").map(|i| i + ".service".len())?;
    let base = PathBuf::from(format!("/sys/fs/cgroup{}", &caminho[..fim]));
    for fatia in ["app.slice", "app.slice/app-graphical.slice", "app-graphical.slice", "session.slice"] {
        let p = base.join(fatia).join(unidade);
        if p.is_dir() {
            return Some(p);
        }
    }
    None
}

fn pai(pid: u32) -> u32 {
    // /proc/<pid>/stat: "pid (nome) estado ppid ..." — o nome pode ter espaços.
    std::fs::read_to_string(format!("/proc/{pid}/stat"))
        .ok()
        .and_then(|s| s.rsplit_once(')').map(|(_, r)| r.split_whitespace().nth(1).unwrap_or("0").to_string()))
        .and_then(|p| p.parse().ok())
        .unwrap_or(0)
}

/// Procura `reaper SteamLaunch AppId=N` no escopo da Steam; devolve (appid, PIDs do jogo).
fn achar_jogo(cgroup: &Path) -> Option<(String, Vec<u32>)> {
    let pids: Vec<u32> = std::fs::read_to_string(cgroup.join("cgroup.procs"))
        .ok()?
        .lines()
        .filter_map(|l| l.trim().parse().ok())
        .collect();
    for &pid in &pids {
        let Ok(bruto) = std::fs::read(format!("/proc/{pid}/cmdline")) else { continue };
        let args: Vec<String> = bruto.split(|b| *b == 0).map(|a| String::from_utf8_lossy(a).into_owned()).collect();
        if !args.iter().any(|a| a == "SteamLaunch") {
            continue;
        }
        let Some(appid) = args.iter().find_map(|a| a.strip_prefix("AppId=")) else { continue };
        // O reaper e todos os descendentes dele que ainda estão no escopo da Steam.
        let mut jogo = vec![pid];
        for &outro in &pids {
            let mut p = outro;
            for _ in 0..32 {
                p = pai(p);
                if p == pid {
                    jogo.push(outro);
                    break;
                }
                if p <= 1 {
                    break;
                }
            }
        }
        return Some((appid.to_string(), jogo));
    }
    None
}

async fn mover_jogo(systemd: &SystemdProxy<'_>, steam: &str, appid: &str, pids: &[u32]) -> Option<String> {
    let unidade = format!("app-steam-jogo-{appid}.scope");
    let fatia = cgroup_da_unidade(steam)
        .and_then(|p| p.parent().and_then(|f| f.file_name()).map(|n| n.to_string_lossy().into_owned()))
        .filter(|f| f.ends_with(".slice"))
        .unwrap_or_else(|| "app.slice".into());
    let descricao = format!("Jogo da Steam {appid}");
    let props: Vec<(&str, Value<'_>)> = vec![
        ("PIDs", Value::from(pids.to_vec())),
        ("Slice", Value::from(fatia.as_str())),
        ("Description", Value::from(descricao.as_str())),
        ("CollectMode", Value::from("inactive-or-failed")),
    ];
    match systemd.start_transient_unit(&unidade, "fail", &props, &[]).await {
        Ok(_) => Some(unidade),
        Err(e) => {
            eprintln!("nyxz-scoped: não foi possível mover o jogo {appid}: {e}");
            None
        }
    }
}

// ------------------------------------------------------------------ laço principal

#[tokio::main(flavor = "current_thread")]
async fn main() -> zbus::Result<()> {
    let estado = Arc::new(Mutex::new(Estado::default()));
    let conn = zbus::connection::Builder::session()?
        .name("org.nyxz.Apps")?
        .serve_at(CAMINHO, Servico { estado: estado.clone() })?
        .build()
        .await?;
    let emissor = SignalEmitter::new(&conn, CAMINHO)?;

    let systemd = SystemdProxy::new(&conn).await?;
    systemd.subscribe().await?;
    let mut novas = systemd.receive_unit_new().await?;
    let mut removidas = systemd.receive_unit_removed().await?;

    {
        let mut e = estado.lock().unwrap();
        for u in systemd.list_units().await? {
            if eh_app(&u.0) && u.3 == "active" {
                e.apps.insert(
                    u.0.clone(),
                    App { unidade: u.0.clone(), nome: nome_do_escopo(&u.0), inicio: agora(), jogo: None, janelas: vec![] },
                );
            }
        }
    }

    let mut eventos = conectar_eventos().await;
    let mut relogio = tokio::time::interval(Duration::from_secs(3));
    eprintln!("nyxz-scoped: pronto (Hyprland {})", if eventos.is_some() { "conectado" } else { "aguardando" });

    loop {
        let mut mudou = false;
        tokio::select! {
            Some(sinal) = novas.next() => {
                if let Ok(a) = sinal.args() {
                    let id = a.id().to_string();
                    if eh_app(&id) {
                        let jogo = id.strip_prefix("app-steam-jogo-").map(|r| r.trim_end_matches(".scope").to_string());
                        estado.lock().unwrap().apps.insert(
                            id.clone(),
                            App { unidade: id.clone(), nome: nome_do_escopo(&id), inicio: agora(), jogo, janelas: vec![] },
                        );
                        mudou = true;
                    }
                }
            }
            Some(sinal) = removidas.next() => {
                if let Ok(a) = sinal.args() {
                    let id = a.id().to_string();
                    let mut terminou = None;
                    {
                        let mut e = estado.lock().unwrap();
                        if e.apps.remove(&id).is_some() {
                            mudou = true;
                        }
                        if e.jogo.as_ref().is_some_and(|j| j.1 == id) {
                            terminou = e.jogo.take().map(|j| j.0);
                        }
                    }
                    if let Some(appid) = terminou {
                        eprintln!("nyxz-scoped: jogo {appid} fechado");
                        let _ = Servico::jogo_terminou(&emissor, &appid).await;
                    }
                }
            }
            linha = async {
                match eventos.as_mut() {
                    Some(l) => l.next_line().await,
                    None => std::future::pending().await,
                }
            } => {
                match linha {
                    Ok(Some(l)) => mudou = tratar_evento(&estado, &l).await,
                    _ => eventos = None, // Hyprland fechou ou reiniciou: reconecta no relógio
                }
            }
            _ = relogio.tick() => {
                if eventos.is_none() {
                    eventos = conectar_eventos().await;
                }
                // Jogo da Steam novo dentro do escopo da Steam?
                let steam: Vec<String> = {
                    let e = estado.lock().unwrap();
                    if e.jogo.is_some() { vec![] } else {
                        e.apps.keys().filter(|u| u.to_lowercase().contains("steam") && !u.contains("steam-jogo")).cloned().collect()
                    }
                };
                for unidade in steam {
                    let Some(cg) = cgroup_da_unidade(&unidade) else { continue };
                    let Some((appid, pids)) = achar_jogo(&cg) else { continue };
                    if let Some(nova) = mover_jogo(&systemd, &unidade, &appid, &pids).await {
                        eprintln!("nyxz-scoped: jogo {appid} movido para {nova} ({} processos)", pids.len());
                        estado.lock().unwrap().jogo = Some((appid.clone(), nova));
                        let _ = Servico::jogo_iniciou(&emissor, &appid).await;
                        mudou = true;
                        break;
                    }
                }
            }
        }
        if mudou {
            let _ = Servico::mudou(&emissor).await;
        }
    }
}

/// Eventos do socket2: "openwindow>>end,ws,classe,título", "closewindow>>end",
/// "windowtitlev2>>end,título". Devolve true se a lista mudou.
async fn tratar_evento(estado: &Arc<Mutex<Estado>>, linha: &str) -> bool {
    let Some((evento, dados)) = linha.split_once(">>") else { return false };
    match evento {
        "openwindow" => {
            let mut partes = dados.splitn(4, ',');
            let endereco = partes.next().unwrap_or("").to_string();
            let _ws = partes.next();
            let classe = partes.next().unwrap_or("").to_string();
            let titulo = partes.next().unwrap_or("").to_string();
            let pid = pid_da_janela(&endereco).await;
            let janela = Janela { endereco, classe, titulo, pid };
            let escopo = if pid > 0 { escopo_do_pid(pid) } else { None };
            let mut guarda = estado.lock().unwrap();
            let e = &mut *guarda;
            match escopo.and_then(|u| e.apps.get_mut(&u)) {
                Some(app) => app.janelas.push(janela),
                None => e.soltas.push(janela),
            }
            true
        }
        "closewindow" => {
            estado.lock().unwrap().remover_janela(dados);
            true
        }
        "windowtitlev2" => {
            let Some((endereco, titulo)) = dados.split_once(',') else { return false };
            let mut guarda = estado.lock().unwrap();
            let e = &mut *guarda;
            for j in e.apps.values_mut().flat_map(|a| a.janelas.iter_mut()).chain(e.soltas.iter_mut()) {
                if j.endereco == endereco {
                    j.titulo = titulo.to_string();
                }
            }
            false // título muda o tempo todo; não vale um sinal
        }
        _ => false,
    }
}
