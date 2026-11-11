# Nyxz — arquitetura técnica

Como cada parte do [PROJETO.md](PROJETO.md) vai ser construída, onde as funções se cruzam e o que fazer para não brigarem entre si. Escrito em 2026-11-07, depois de pesquisar os pontos de maior risco (fontes no fim).

---

## 1. O que a pesquisa mudou no plano

| Plano anterior | Problema encontrado | Nova decisão |
|---|---|---|
| Componentes nativos opcionais como `systemd-sysext` | O bootc marcou sysext/confext como **não suportados** na documentação; o projeto da comunidade é experimental. | **Imagem local personalizada**: o Nyxz Setup gera um Containerfile `FROM ghcr.io/<usuário>/nyxz:latest` + os pacotes escolhidos, constrói com `podman` (como root) e troca para ela com `bootc switch --transport containers-storage`. Um timer reconstrói quando a imagem base atualiza e limpa as imagens antigas. É o caminho documentado pelo bootc e usado pela comunidade Universal Blue. |
| Hyprland do repositório oficial do Fedora | O Hyprland **saiu dos repositórios oficiais** depois do Fedora 42; só existe via COPR. O Quickshell também é COPR e já quebrou por versão do Qt. | **COPR próprio da Nyxz** que compila Hyprland, Quickshell e afins contra a versão exata do Fedora usada. Os COPRs da comunidade (`ashbuk/Hyprland-Fedora`, `errornointernet/quickshell`) servem de ponto de partida até o nosso existir. |
| Base Fedora 45 | O Fedora 45 acabou de sair (3/11/2026); os COPRs costumam levar semanas para acompanhar. | **Começar no Fedora 44** e trocar para o 45 quando o Hyprland e o Quickshell estiverem compilando nele. No bootc a troca é só mudar a tag da imagem base. |
| CoreCtrl para a RX 7600 | Relatos de curva de ventoinha sem efeito na RX 7600; firmware mantém o modo 0 RPM. | **LACT** como principal (curva, limite de energia, overclock/undervolt). Desligar o 0 RPM exige kernel 6.13+ (o Fedora 44 já tem). O serviço `lactd` só fica ligado se o usuário aplicar algum perfil. |
| EasyEffects para o microfone | Fica rodando o tempo todo e gasta ~50–100 MB, estourando o orçamento de RAM. | **Filtros do próprio PipeWire** (`filter-chain` com RNNoise/DeepFilterNet e equalizador), sem processo extra. EasyEffects vira opcional para quem quiser a interface dele. |
| ZeroTier pelo site | Plano grátis: **10 dispositivos e 1 rede**. | **Controlador próprio** como padrão (o ZeroTier já vem com um embutido). Limitação: o PC que criou a rede precisa estar ligado para alguém novo entrar. |
| Sober (Roblox) marcado por padrão | Instável em 2026, relatos de erros 401/403 e risco de conta não esclarecido. | **Oferecido com aviso e desmarcado** no perfil "Sugerido". |
| Codificação H.264/HEVC na placa | O Mesa do Fedora vem com H.264 e HEVC **desligados** por patente. Só AV1 funciona. | Trocar para `mesa-va-drivers-freeworld` do RPM Fusion na imagem. Sem isso, Nyxz Share, replay e gravação ficam só com AV1. |
| ISO com o instalador Anaconda | O tipo `anaconda-iso` está sendo substituído por `bootc-generic-iso`, e o padrão instala sem perguntar no primeiro disco. | Testar a geração da ISO **logo na fase 0**, com um kickstart interativo. Se o Anaconda não servir, usar uma ISO live com instalador próprio (mais trabalho). |

---

## 2. Fundações compartilhadas

Quase todas as funções dependem de poucas peças. Construindo essas peças primeiro, cada função nova fica pequena e sem conflito.

### 2.1 Cada app no seu próprio "escopo" (base de 7 funções)
- Todo app aberto pela barra, busca, atalho, automação ou `nyx run` é iniciado com **uwsm/app2unit** como um escopo do systemd (`app-<nome>-<id>.scope`).
- Usam isso: **Estatísticas**, **VPN/proxy por app**, **bloqueio de internet por app**, **congelar apps**, **várias instâncias**, **privacidade por app** e **medidor de RAM por app**.
- **Jogos da Steam:** a Steam abre os jogos dentro do escopo dela. O `nyxz-scoped` (serviço de usuário) detecta o processo com `SteamAppId` e o move para um escopo próprio pelo D-Bus do systemd (`StartTransientUnit` com os PIDs).
- **Risco:** o uwsm deixa a abertura de apps um pouco mais lenta; o `app2unit` é a alternativa rápida. Medir.

### 2.2 `nyxz-scoped`: quem sabe o que está rodando
Serviço de usuário pequeno (Rust) que acompanha escopos (criados e encerrados), janelas (socket de eventos do Hyprland) e jogos, e publica tudo num barramento D-Bus `org.nyxz.Apps`. Estatísticas, Modo jogo, automações, congelamento e rede consultam este serviço em vez de cada um varrer o sistema sozinho.

### 2.3 `nyxz-netd`: um único dono das regras de rede
- Serviço de sistema que é o **único** a escrever as regras da Nyxz no nftables, numa tabela própria (`inet nyxz`).
- Problema técnico: a regra `socket cgroupv2` resolve o caminho do escopo **na hora em que é carregada**, então falha se o app ainda não abriu. O `nyxz-netd` escuta o `nyxz-scoped` e aplica a regra quando o escopo nasce (mesma ideia do `systemd-cgroup-nftables-policy-manager` e do split tunnel do Mullvad).
- Ordem fixa das regras: **bloqueio de internet → VPN/proxy por app → kill switch → resto**.

### 2.4 `nyxz-audio`: um único dono do roteamento de som
- Painel de som, perfis, automações, Modo jogo e Nyxz Share **não mexem no PipeWire direto**: pedem ao `nyxz-audio`, que grava regras do WirePlumber e cria os filtros.
- Evita duas funções trocando a saída de um app ao mesmo tempo.
- **Como ficou (08/11/2026):** em vez de serviço residente, o `nyxz-audio` é um comando único (`/usr/libexec/nyxz/nyxz-audio`): estado, microfone sem ruído (módulo echo-cancel do PipeWire com WebRTC, numa instância própria que só existe enquanto ligado), saída por app (`target.object`, lembrada pelo WirePlumber) e perfis. Mesmo papel de "único dono", custo zero parado.

### 2.5 Configuração em camadas (evita sobrescrever o usuário)
```
/usr/share/nyxz/hypr/padrao.lua     ← padrões da Nyxz (vêm na imagem, atualizam sozinhos)
~/.config/hypr/nyxz/<função>.lua    ← gerado por cada função (regras de janela, espaços, atalhos)
~/.config/hypr/user.lua             ← do usuário, nunca tocado pela Nyxz
```
Cada função é dona de um arquivo só. O `hyprland.lua` do usuário apenas carrega os três níveis, nessa ordem. **O Hyprland 0.57 abandonou o formato `.conf`** e só aceita Lua; o script `/usr/libexec/nyxz/hypr-config`, rodado antes de cada sessão, cria o que faltar e troca a configuração automática que o Hyprland gera quando não acha nenhuma.

### 2.6 Interface: Quickshell em pedaços
- **Barra, busca, notificações, menus e painéis rápidos** num único processo Quickshell.
- Cada painel carrega **só quando abre** (`Loader` sob demanda) e é descarregado depois. Sem isso, "tudo na v1" estoura o orçamento de RAM.
- **Apps grandes em processos separados**, que não existem enquanto fechados: Dev Hub, Estatísticas, Discos, Biblioteca de jogos, Configurações, Nyxz Setup.

### 2.7 Imagem e componentes
- **Imagem base** (núcleo) construída no GitHub Actions todo dia → `ghcr.io/<usuário>/nyxz`.
- **Componentes nativos escolhidos** → imagem local personalizada (seção 1).
- **Apps de usuário** → Flatpak (remoto Flathub declarado em `/etc/flatpak/remotes.d`).
- **Linguagens** → `mise` na pasta do usuário.
- **Catálogo** → um arquivo YAML por componente (tipo, pacotes, tamanho, custo de RAM, conflitos, dependências). O Nyxz Setup e o "Apps e componentes" leem o mesmo catálogo.

---

## 3. Conflitos entre funções e como contornar

### 3.1 Captura de tela e codificação de vídeo
**Quem usa:** prévia da barra, Nyxz Share, replay instantâneo, captura de tela/gravação, Sunshine, OBS, Vesktop/Discord, modo streamer.
- **Codificador da placa compartilhado:** replay + Share + gravação ao mesmo tempo = três codificações. A RX 7600 aguenta mais de uma sessão, mas com perda.
  → Se o replay estiver ligado e o Share começar, o Share **reaproveita** a mesma captura; aviso quando houver 3+ codificações.
- **Bug conhecido do driver AMD:** depois de tocar vídeo com VA-API, a codificação pode ficar mais lenta (documentado no gpu-screen-recorder).
  → Wallpaper em vídeo usa decodificação por software em resolução reduzida **quando o replay está ligado**; medir no PC real.
- **Prévias da barra** usam `hyprland-toplevel-export` (não passam pelo codificador): sem conflito.
- **Modo streamer** precisa saber de **toda** captura: o `nyxz-scoped` detecta streams de captura no PipeWire e liga o modo, venha de onde vier.

### 3.2 Som
**Quem usa:** painel de som, perfis, automações, Modo jogo, Nyxz Share (áudio por app), Voz pela LAN, supressão de ruído, Vesktop.
- **Supressão de ruído em dobro:** filtro da Nyxz + supressão do Mumble/Discord deixam a voz robótica.
  → Ao entrar na Voz pela LAN, a Nyxz desliga a supressão do Mumble se a dela estiver ativa (e avisa no Discord).
- **Perfil trocando sozinho no meio da chamada:** o Modo jogo troca para o perfil "Jogo".
  → Perfis têm prioridade: chamada ativa (Voz/Discord com microfone aberto) **trava** o perfil até acabar.
- **Áudio do Vesktop no Hyprland:** há relatos de tela preta/atraso e de fontes de áudio faltando no compartilhamento.
  → Testar cedo; portal `xdg-desktop-portal-hyprland` + `rtkit` ativos; plano B é encaminhar o áudio do jogo para um dispositivo virtual compartilhável.

### 3.3 Rede
**Quem usa:** VPN e kill switch, proxy por app (sing-box), bloqueio de internet por app, LAN virtual (ZeroTier), Nyxz Share e Voz (pela LAN), Sunshine, túnel público, domínios `.test`, Podman, DNS criptografado, monitor da internet.
- **Kill switch derruba a LAN virtual:** ao bloquear tudo fora da VPN, o ZeroTier também cai.
  → O kill switch libera sempre a interface `zt*`, a rede local e o endereço do servidor VPN.
- **Túnel do sing-box captura tudo:** o modo "tun" desvia todo o tráfego, inclusive ZeroTier e VPN.
  → Rotas do sing-box só para os escopos marcados; sub-redes do ZeroTier e endpoints de VPN excluídos.
- **Briga pelo DNS:** sing-box, VPN e systemd-resolved querem ser o DNS.
  → O systemd-resolved é o único resolvedor; VPN e sing-box entregam o DNS para ele.
- **App fora da VPN sai com o IP errado:** ao rotear um app por fora do túnel, o endereço de origem continua o da VPN.
  → Marcação + tabela de rotas própria + NAT de origem (modelo do Mullvad).
- **Vários donos do nftables:** firewalld (Fedora), Podman (netavark), ZeroTier, sing-box e o `nyxz-netd`.
  → Cada um na sua tabela; o `nyxz-netd` nunca apaga regras dos outros; o Nyxz Doctor confere a ordem.
- **Domínios `.test`:** o systemd-resolved não serve zonas próprias.
  → O Dev Hub escreve as entradas `.test` num arquivo de hosts gerenciado e o Caddy atende as portas.
- **Serviços expostos sem querer:** Sunshine, Nyxz Share, Voz e o servidor do Podman só escutam na **interface da LAN virtual e em localhost**, nunca na internet.

### 3.4 Processos e memória
**Quem usa:** congelar apps, Estatísticas, Modo jogo, várias instâncias, Nyxz Share, Voz.
- **Congelar quem está sendo usado:** congelar um app que está tocando som, sendo transmitido ou com chamada aberta.
  → Nunca congela escopos com stream ativo no PipeWire, com captura ativa ou na lista "rede contínua" (Discord, Vesktop, Steam).
- **Tempo de uso inflado:** app congelado aparece como aberto.
  → As Estatísticas contam "aberto", "em foco" e "congelado" separados.
- **Várias instâncias de apps Flatpak:** o Flatpak fixa a pasta de dados em `~/.var/app/<id>`.
  → Para Flatpak, a instância extra usa uma pasta de dados alternativa só quando o app aceita `--user-data-dir` (Brave, Electron); os outros ficam marcados como "não suportado" na lista de compatibilidade.

### 3.5 Janelas e atalhos
**Quem usa:** regras de janela, Espaços, automações, Modo jogo, várias instâncias, cola de atalhos, macros, Ajustes.
- **Regras duplicadas ou contraditórias:** com camadas (seção 2.5) e prioridade fixa (usuário > função > padrão).
- **Atalho repetido:** a cola de atalhos lê a configuração **final** e o editor avisa conflito antes de salvar.
- **Atalhos globais do Discord no Wayland** só funcionam com a janela em foco.
  → Usar o portal de atalhos globais do Hyprland quando o app suportar; senão, criar o atalho do lado da Nyxz (ex.: mutar o microfone pelo `nyxz-audio`).

### 3.6 Energia e desempenho
**Quem usa:** Modo jogo, LACT, automações, consumo de energia.
- **Três gerenciadores de energia:** GameMode, `tuned-ppd`/power-profiles-daemon e automações mudando o perfil da CPU.
  → Um caminho só: tudo passa pelo `tuned-ppd`; o GameMode é configurado para chamá-lo.
- **Perfil da GPU no lugar errado:** LACT por jogo e Modo jogo.
  → O Modo jogo pede o perfil ao LACT pelo `nyxz-scoped`, e não grava sozinho no sysfs.

### 3.7 Atualizações
**Quem usa:** imagem base, imagem local personalizada, Flatpaks, Spicetify, Steam, Modo jogo ("adiar atualizações").
- **Reconstrução da imagem local no meio do jogo** (CPU, disco e RAM).
  → Só roda com o PC ocioso, nunca com o Modo jogo ativo; prioridade baixa (`nice`/`ionice`).
- **Spotify atualiza e o Spicetify some.**
  → Unidade `.path` do systemd vigia a pasta do Spotify e reaplica; se falhar, deixa o Spotify original e avisa.
- **Atualização quebrada:** rollback do bootc no menu de boot + teste de RAM e de boot no CI antes de publicar.

### 3.8 Disco
**Quem usa:** snapshots (Snapper), backup (restic), limpeza de disco, Estatísticas (arquivos apagados), replay em disco, Steam.
- **Limpeza que não libera espaço:** apagar `node_modules` não libera nada enquanto houver snapshot com ele.
  → A limpeza mostra "libera agora" e "libera quando os snapshots expirarem", com opção de apagar também dos snapshots.
- **Snapshots ocupando muito:** Steam, caches e `~/.var` em **subvolumes separados** do Btrfs, fora dos snapshots. `node_modules` não dá para separar por projeto; fica nos snapshots, mas expira em até 4 semanas.
- **Desgaste do SSD:** banco das Estatísticas grava em lote; replay usa RAM por padrão (30 s a 50 Mbit/s ≈ 190 MB) com opção de disco; snapshots e backup em horários espaçados.

### 3.9 Privacidade e segredos
**Quem usa:** cofre, Nyxz Sync, modo streamer, Nyxz Doctor, Estatísticas.
- **Segredo vazando pelo Sync:** o Sync tem uma lista de bloqueio fixa (`.env`, cofre, chaves SSH, tokens) e roda uma verificação de segredos antes de cada envio.
- **Relatório do Doctor com dados pessoais:** o relatório remove nomes de usuário, IPs, números de série e e-mails antes de gerar.

### 3.10 Entrada (teclado, mouse e controles)
**Quem usa:** macros (input-remapper), central de controles (InputPlumber), Steam Input, OpenRazer, atalhos do Hyprland.
- **Controle remapeado duas vezes** (InputPlumber + Steam Input).
  → Quando o InputPlumber assume um controle, a Nyxz avisa para desligar o Steam Input naquele jogo (ou esconde o dispositivo original).
- **InputPlumber sem interface pronta e com pouca documentação:** a Central de controles é escrita do zero sobre a API D-Bus dele; risco médio.

### 3.11 Tela
**Quem usa:** brilho DDC/CI, filtro de luz azul, wallpaper em vídeo, Wallpaper Engine, VRR 180 Hz, Sunshine.
- **Dois wallpapers ao mesmo tempo** (mpvpaper, linux-wallpaperengine, fundo do Quickshell).
  → Um gerenciador de wallpaper só, que liga um provedor por monitor.
- **Pausar o vídeo quando coberto:** o `--auto-pause` do mpvpaper só detecta tela cheia/maximizado.
  → O gerenciador de wallpaper usa os eventos do Hyprland ("workspace tem janelas") e pausa pelo socket do mpv.
- **Wallpaper Engine sobre as janelas** no Hyprland (relatos antigos).
  → Regra de camada; marcado como experimental.

### 3.12 Boot e dual boot
- **Windows no menu de boot:** o bootc gera o menu do GRUB do jeito dele; o `os-prober` pode não rodar.
  → Gerar uma entrada fixa do Windows (via `bootupd`/configuração própria) quando o Windows for detectado. Testar em VM com Windows.
- **Relógio:** com Windows detectado, o Linux usa o relógio da placa em horário local.

### 3.13 Orçamento de RAM com "tudo ligado"
Serviços que ficam residentes **se ligados**: Quickshell (100–200 MB), `nyxz-scoped` (~5 MB), coletor das Estatísticas (≤ 10 MB), `nyxz-netd` (~5 MB), `nyxz-audio` (~5 MB), `lactd` (se houver perfil), input-remapper (se houver perfil), ZeroTier (se houver rede ligada), KDE Connect (se ligado).
→ O teste de RAM do CI roda **duas vezes**: com o perfil "Mínimo" e com o perfil "Sugerido". Os dois precisam ficar abaixo de 1,2 GB.

---

## 4. Como cada função será construída

Legenda de risco: 🟢 baixo · 🟡 médio · 🔴 alto.

### Base e interface
| Função | Como | Risco |
|---|---|---|
| Imagem e atualizações | `fedora-bootc:44` + COPR próprio; GitHub Actions diário; rollback do bootc | 🟡 COPRs |
| Instalador + Nyxz Setup | ISO via bootc-image-builder com kickstart interativo; Nyxz Setup em Quickshell no primeiro boot | 🔴 ISO interativa |
| Componentes opcionais | Imagem local personalizada + Flatpak + mise; catálogo YAML | 🟡 tempo de reconstrução |
| Barra, busca, notificações, menus | Quickshell (QML); busca com plugins em QML | 🟡 volume de trabalho |
| Prévia na barra | `ScreencopyView` do Quickshell com `hyprland-toplevel-export`; último quadro em cache | 🟢 |
| Bandeja fixa/oculta | `SystemTray` do Quickshell (StatusNotifierItem) + `xembedsniproxy` | 🟢 |
| Ajustes (mods do Windhawk) | Opções da barra/busca no Quickshell; regras do Hyprland; Dolphin configurado | 🟢 |
| Mini player | MPRIS do Quickshell | 🟢 |
| Som por app e perfis | `nyxz-audio` (WirePlumber + filter-chain) | 🟡 |
| Animações estilo Lenis | Curvas exponenciais no Hyprland e no QML; rolagem com inércia em `Flickable` customizado | 🟢 |
| Finalizar tarefa | `systemctl --user kill --signal=SIGKILL` no escopo do app | 🟢 |
| Várias instâncias | Pasta de perfil própria + `dbus-run-session`/`bubblewrap`; lista de compatibilidade | 🟡 |
| Espaços, regras de janela, cola de atalhos | Arquivos gerados em `~/.config/hypr/nyxz/` | 🟢 |
| Brilho e luz azul | `ddcutil` (i2c-dev) + `hyprsunset` | 🟢 (depende do monitor) |
| Wallpaper imagem/vídeo/Wallpaper Engine | Gerenciador próprio + `mpvpaper` + `linux-wallpaperengine` | 🟡 / 🔴 WE |
| Privacidade (indicadores e permissões) | Streams do PipeWire + portais + permissões do Flatpak | 🟡 apps nativos |

### Desenvolvimento
| Função | Como | Risco |
|---|---|---|
| Dev Hub (app) | App separado (QML ou Tauri — decidir na fase 4) | 🟡 volume |
| Serviços locais | Podman com ativação por socket, volumes nomeados, snapshots com `podman volume export` | 🟢 |
| SSH | `~/.ssh/config`, `ssh-keygen`, SFTP via Dolphin (`sftp://`), túneis com `ssh -L` gerenciados | 🟢 |
| Discord Studio | Modelos discord.js/discord.py; prévia renderizada no app; código ↔ visual com parser de `EmbedBuilder` | 🟡 parser |
| Cliente de API | Integrar Bruno (Flatpak) ou cliente próprio simples | 🟢 |
| Portas em uso | `ss -ltnp` + escopos | 🟢 |
| `.test` com HTTPS | Caddy + mkcert + hosts gerenciado | 🟢 |
| Túnel público | `cloudflared` modo rápido | 🟢 |
| Sessões de projeto | Arquivo por projeto (apps, pastas, serviços, variáveis) restaurado pelo `nyxz-scoped` | 🟡 |
| Cofre de segredos | Secret Service (gnome-keyring ou KeePassXC) + hook de pré-commit (gitleaks) | 🟢 |
| Limpeza de disco | Varredura com regras por tipo + integração com Snapper | 🟢 |
| VS Code, Git, linguagens | Componentes da imagem local; `mise` | 🟢 |

### Jogos
| Função | Como | Risco |
|---|---|---|
| Steam, Vulkan, GameMode, MangoHud, gamescope | RPM Fusion na imagem local | 🟢 |
| Java + Prism, Sober, Bottles, Heroic | Temurin (repositório Adoptium) + Flatpaks | 🟢 / 🔴 Sober |
| Modo jogo automático | `nyxz-scoped` detecta o jogo → `tuned-ppd`, `nyxz-audio`, não perturbe, LACT | 🟢 |
| Replay instantâneo | `gpu-screen-recorder -r`, salvar com SIGUSR1, buffer em RAM | 🟢 |
| Controle da GPU | LACT | 🟡 0 RPM |
| Streaming (Sunshine) | Sunshine (COPR lizardbyte/stable) na imagem local, serviço `nyxz-streaming` só quando ligado; restringir à LAN virtual fica com o `nyxz-netd` | 🟡 |
| LAN virtual | ZeroTier com controlador próprio + painel | 🟡 |
| Biblioteca de jogos | Ler bibliotecas da Steam (VDF), Heroic, Prism, Sober e Bottles | 🟡 |
| Central de controles | Kernel direto (joydev, bateria no sysfs, bluetoothctl) + Configurações → Controles. InputPlumber não tem pacote no Fedora 44: remapear fica com o Steam Input e o input-remapper | 🟢 |
| Macros e remapeamento | input-remapper + OpenRazer | 🟡 |

### Rede e comunicação
| Função | Como | Risco |
|---|---|---|
| VPN, kill switch, DNS | NetworkManager (WireGuard/OpenVPN) + `nyxz-netd` + systemd-resolved | 🟡 |
| VPN/proxy por app | `nyxz-netd` v1 (Python): duas fatias fixas do systemd por usuário (sem internet, fora da VPN), uma regra `socket cgroupv2` por fatia, marca 0x7700 → tabela 7700 + NAT. Proxy por app (sing-box) ainda falta | 🟡 |
| Nyxz Share | v1: WebRTC no navegador (estilo Screego) servido pelo próprio PC; v2: GStreamer `webrtcbin` + VA-API | 🟡 |
| Voz pela LAN | `murmur` (servidor Mumble) sob demanda + cliente Mumble | 🟢 |
| Monitor da internet | Timer com ping/jitter/perda + teste de velocidade; relatório PDF/CSV | 🟢 |

### Sistema
| Função | Como | Risco |
|---|---|---|
| Estatísticas | Coletor Rust: cgroups v2 + eBPF (rede e arquivos) + eventos do Hyprland → SQLite | 🟡 eBPF |
| Consumo em reais | RAPL + sensor `amdgpu` → coletor das Estatísticas | 🟢 |
| Discos | `smartctl`/`nvme-cli` por timer + `fio` sob demanda | 🟢 |
| Snapshots | Snapper na pasta pessoal (Btrfs) + "Versões anteriores" no Dolphin | 🟡 |
| Backup | restic + rclone, timer | 🟢 |
| Nyxz Sync | Repositório Git privado + lista de bloqueio + verificação de segredos | 🟢 |
| Automações | Motor no shell (`Automacoes.qml`: Hyprland, Modo jogo, udev, conferência a cada 20 s) + ações em `/usr/libexec/nyxz/automacoes` | ✅ |
| Congelar apps | `cgroup.freeze` nos escopos com as exceções da seção 3.4 | 🟡 |
| Modo streamer | Detecção de captura + regras de ocultar no shell | 🟡 |
| Nyxz Doctor | `/usr/libexec/nyxz/doctor` (Python, só com a página aberta) + `nyxz-doctor-root` (pkexec) + página nas Configurações | ✅ |
| Dual boot | Entrada do Windows no GRUB, NTFS, relógio local, aviso do Início rápido | 🟡 |

---

## 5. Ordem de construção

Tudo entra na v1.0, mas construído em fases. **Cada fase termina com uma ISO que dá para testar**, para não acumular problemas.

**Fase 0 — Esqueleto e CI** *(começando agora)*
- Containerfile `fedora-bootc:44`, COPRs, RPM Fusion e codecs.
- GitHub Actions: construir e publicar a imagem; gerar a ISO; ligar numa VM e medir a RAM.
- Meta: instalar numa VM e entrar num Hyprland com terminal.

**Fase 1 — Desktop mínimo usável**
- Login **gráfico** da Nyxz (greeter em Quickshell sobre o greetd), sessão com uwsm, configuração em camadas, tema, fontes.
- Quickshell: barra, busca básica, notificações, painel de som simples, menu de energia.
- App de Configurações com as primeiras telas: Rede (Wi-Fi), Som, Telas, Teclado e mouse, Atualizações e Sobre.
- Ghostty, Dolphin, Brave. Teste de RAM passando.

**Regra que vale para todas as fases:** nada exige terminal. Uma função só conta como pronta quando tudo dela pode ser feito pela interface, e todo erro aparece como notificação explicada, com botão para resolver (ver PROJETO.md, "Regra: nada exige terminal").

**Fase 2 — Fundações**
- `nyxz-scoped`, catálogo de componentes (JSON), imagem local personalizada, Nyxz Setup e "Apps e componentes", janela de senha própria, Spicetify e linguagens pelo `mise`.
- **Decisão (07/11/2026):** o `nyxz-audio` e o `nyxz-netd` passam a ser construídos junto com a primeira função que usa cada um, para nascerem testáveis: `nyxz-audio` na Fase 3 (perfis de som e painel completo) e `nyxz-netd` na Fase 5 (bloqueio de internet e VPN por app). O catálogo ficou em um JSON único em vez de um YAML por componente: o Quickshell lê JSON direto, sem conversor.

**Fase 3 — Interface completa**
- `nyxz-audio`. Prévias, bandeja, mini player, Ajustes (mods), finalizar tarefa, espaços, regras de janela, cola de atalhos, brilho, luz azul, wallpapers, animações estilo Lenis, privacidade.

**Fase 4 — Desenvolvimento**
- Dev Hub completo, VS Code, Git, linguagens, `.test`, túnel, cofre, sessões, portas, limpeza.

**Fase 5 — Jogos e rede**
- `nyxz-netd`. Steam e companhia, Modo jogo, replay, LACT, biblioteca, controles, macros, Sunshine, VPN/proxy/DNS, LAN virtual, Nyxz Share, Voz.

**Fase 6 — Sistema**
- Estatísticas, consumo, Discos, snapshots, backup, Sync, automações, congelar, modo streamer, Doctor, dual boot, várias instâncias.

**Fase 7 — PC real e polimento**
- Instalação no seu PC, medições de RAM reais, ajustes de desempenho, correções.

---

## 6. Fontes da pesquisa
- [bootc: sysext/confext marcados como não suportados](https://discussion.fedoraproject.org/t/unsupported-systemd-confext-and-sysext-on-bootc/202199) · [fedora-sysexts (experimental)](https://travier.github.io/fedora-sysexts)
- [bootc: inicializar imagens locais](https://containers.github.io/bootc/booting-local-builds.html) · [imagem local com reconstrução automática (Universal Blue)](https://universal-blue.discourse.group/t/locally-built-automatically-updating-custom-bootc-image/11706) · [guia de imagem local (Fedora)](https://discussion.fedoraproject.org/t/fedora-atomic-a-simple-guide-to-creating-a-custom-local-bootc-image/181729) · [build local precisa ser como root](https://universal-blue.discourse.group/t/local-builds-and-rebase/8714)
- [Hyprland fora dos repositórios oficiais desde o F42](https://dev.to/ashbuk/why-hyprland-on-fedora-needs-vendored-dependencies-0550-edition-4alo) · [COPR ashbuk/Hyprland-Fedora](https://copr.fedorainfracloud.org/coprs/ashbuk/Hyprland-Fedora/)
- [Quickshell: instalação](https://quickshell.org/docs/v0.3.0/guide/install-setup) · [problema de versão do Qt no COPR](https://github.com/end-4/dots-hyprland/discussions/2411) · [ScreencopyView](https://quickshell.org/docs/types/Quickshell.Wayland/ScreencopyView)
- [Protocolo hyprland-toplevel-export](https://wayland.app/protocols/hyprland-toplevel-export-v1)
- [uwsm](https://github.com/Vladimir-csp/uwsm) · [Hyprland: início com systemd](https://wiki.hypr.land/Useful-Utilities/Systemd-start/)
- [Fedora 45 lançado](https://phoronix.com/news/Fedora-45-Released)
- [nftables + cgroups v2 por app](https://blog.fraggod.net/2021/08/31/easy-control-over-applications-network-access-using-nftables-and-systemd-cgroup-v2-tree.html) · [split tunnel do Mullvad](https://www.mintlify.com/mullvad/mullvadvpn-app/architecture/system/routing)
- [ZeroTier: preços](https://www.zerotier.com/pricing)
- [Sober / Roblox no Linux em 2026](https://www.omgubuntu.co.uk/2026/10/play-roblox-linux-sober) · [Roblox após o banimento de clientes modificados](https://devforum.roblox.com/t/roblox-on-linux-after-the-modified-client-ban/3649937)
- [gpu-screen-recorder (manual)](https://man.archlinux.org/man/gpu-screen-recorder.1.en)
- [CoreCtrl e RX 7600](https://gamingonlinux.com/2024/09/corectrl-adds-power-profiles-support-for-amd-rx-7600) · [curva de ventoinha RDNA3](https://gabmus.org/posts/rdna3_fan_control_in_linux/) · [LACT](https://github.com/ilya-zlobintsev/LACT)
- [mpvpaper (manual)](https://manpages.opensuse.org/Tumbleweed/mpvpaper/mpvpaper.1.en.html) · [linux-wallpaperengine no Hyprland](https://github.com/hyprwm/Hyprland/discussions/1432)
- [Spicetify: instalação](https://spicetify.app/docs/advanced-usage/installation)
- [Vesktop no Hyprland: problemas de compartilhamento](https://github.com/Vencord/Vesktop/issues/1012)
- [bootc-image-builder e kickstart](https://osbuild.org/docs/bootc/) · [ISO com Anaconda instala sem perguntar](https://discussion.fedoraproject.org/t/how-to-build-isos-from-bootable-oci-containers/132835)
