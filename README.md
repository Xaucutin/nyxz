# Nyxz

Distro Linux pessoal focada em programação e jogos: Hyprland com interface própria, visual escuro e minimalista, tudo opcional na instalação e menos RAM que o Windows.

- **O que a Nyxz vai ter:** [PROJETO.md](PROJETO.md)
- **Como cada parte é construída, conflitos e ordem de construção:** [ARQUITETURA.md](ARQUITETURA.md)
- **Visual:** [design/](design/) (maquete e protótipo navegável)

## Estado

**Fase 0 — esqueleto e CI: concluída (07/11/2026).** A imagem base (núcleo) e a ISO são geradas pelo GitHub Actions e foram testadas numa VM do VirtualBox:

- Instalador interativo em português; só mexe no disco depois de confirmar.
- Login (provisório, em texto) → Hyprland 0.57 com a configuração da Nyxz em Lua.
- Atualização pelo `bootc upgrade` funcionando (baixa só o que mudou).
- **RAM: 599 MB em uso** com o Hyprland e um terminal abertos (meta: ≤ 1 GB; teto: 1,2 GB). zram ativo.
- Pendente conhecido: `systemd-remount-fs.service` falha em instalações feitas pelo Anaconda (problema conhecido do bootc, sem efeito visível).

**Fase 1 — desktop mínimo usável: concluída (07/11/2026).** Testada na VM, a partir da imagem:

- Login gráfico (Quickshell + greetd no cage), com aviso de senha incorreta e nova tentativa → sessão Hyprland com o shell da Nyxz abrindo sozinho.
- Barra (logo, workspaces, apps abertos, bandeja, som, relógio), busca (Super + Espaço: apps, calculadora, energia), notificações, painel de som e menu do botão direito (Fechar, Finalizar tarefa).
- Configurações: Rede, Som, Telas, Teclado e mouse, Atualizações e Sobre. Ctrl+↓/↑ trocam de página.
- Ajustes das Configurações aplicados na hora (ex.: Telas em 1600×900 via `~/.config/hypr/nyxz/telas.lua`).
- Atualizações só baixam em segundo plano; nunca reiniciam o PC sozinhas.
- **RAM logo após o login: 681 MB** com a área de trabalho completa e um terminal aberto (Hyprland 157 MB, shell 78 MB, Xwayland 70 MB, portais ~86 MB).

**Passou para a Fase 2:** Ghostty, Dolphin e Brave são componentes opcionais e chegam pelo Nyxz Setup e pela imagem local personalizada.

**Pendentes conhecidos:**
- `systemd-remount-fs.service` falha em instalações pelo Anaconda (conhecido, sem efeito visível).
- Xwayland (70 MB) inicia junto com a sessão; avaliar iniciar só quando um app X11 abrir.
- Teste de RAM automático no CI (hoje medido à mão na VM).

**Fase 2 — fundações: em andamento.** Catálogo de componentes, motor `/usr/libexec/nyxz/componentes` (Flatpak na conta do usuário + imagem local personalizada para apps nativos), Nyxz Setup no primeiro login e Configurações → Apps e componentes.

Testado na VM (perfil Sugerido, 11 itens): Brave, Discord, Spotify, Vesktop e Prism instalados por Flatpak; Ghostty, VS Code, Steam, Dolphin, Git/gh e GameMode/MangoHud na imagem local, montada com podman e ativada no boot seguinte. **RAM depois do login continua em 683 MB** (os apps não pesam parados). Disco: 17 de 38 GB.

**Conferido na VM depois (imagem 9ed4520):** janela de senha própria em português (senha errada avisa e deixa tentar de novo), `nyxz-scoped` rodando com 4 MB e listando apps e janelas, Node.js e Python pelo mise, página Data e hora, relógio em Brasília, sistema em pt_BR (a base não tinha o pacote de português; instalações antigas são ajustadas sozinhas no boot), sem o aviso amarelo. **RAM depois do login: 675 MB.**

**Pendentes da Fase 2:**
- Ainda não conferidos na VM: Spicetify (precisa do Spotify instalado), Ghostty com `LIBGL_ALWAYS_SOFTWARE` (o snapshot de teste não tem o Ghostty) e a separação de jogos da Steam em escopo próprio (precisa de um jogo).
- A camada de apps nativos ficou com 3,6 GB; ver o que puxa tanto (Steam 32 bits, dependências KDE do Dolphin).
- `nyxz-audio` vai para a Fase 3 e `nyxz-netd` para a Fase 5, junto das funções que usam cada um (ver ARQUITETURA.md).

**Fase 3 — interface completa: em andamento.** Na barra: mini player (MPRIS), prévia ao vivo das janelas ao passar o mouse, indicador de privacidade (microfone, câmera, captura de tela) e painel rápido com brilho por tela (DDC/CI) e filtro de luz azul com horário. Papel de parede: imagem desenhada pelo shell (0 MB extra) ou vídeo pelo mpvpaper; página Configurações → Aparência com galeria; "Usar como papel de parede" no Dolphin; dois papéis de parede da Nyxz. Conferido na VM: prévia, painel rápido, Aparência e papel de parede de imagem. Falta conferir: mini player (precisa de um app de mídia), indicador de privacidade (precisa do pipewire-utils da próxima imagem), brilho real (a VM não tem DDC/CI) e vídeo de fundo (mpvpaper chega na próxima imagem).

Também feitos: **Ajustes** (Configurações → Ajustes, com busca: mini player, prévia e atraso, volume na roda, indicador de privacidade, barra em cima, ícones que crescem, títulos sem o nome do app, borda das janelas, tecla para mover janelas, canto das notificações) e **cola de atalhos** (Super + /, com busca). Conferido na VM: cola de atalhos e busca, barra em cima aplicada na hora, prévia abrindo para baixo e a página Ajustes abrindo.

Também feitos: **bandeja** com fixar/ocultar (seta com os ícones ocultos e alfinete por app) e **Regras de janela** (Configurações → Regras de janela: a partir das janelas abertas; área de trabalho, flutuante, centralizada, tela cheia e opacidade; também no botão direito do app na barra). A janela de Configurações agora cabe em telas pequenas. Conferido na VM: página de regras listando as janelas abertas e o formato das regras aplicado no Hyprland (janela flutuante, centralizada e 90% de opacidade).

Também feitos e conferidos na VM (imagem 2081d44): **espaços com nome** (a barra mostra "Código", "Jogos"…; papel de parede próprio por espaço, trocando ao mudar), **nyxz-audio** (microfone sem ruído com o WebRTC do PipeWire, saída por app, perfis como "Call" em um clique no painel de som; gestão em Configurações → Som), **luz azul** (hyprsunset ou, sem ele, gammastep) e **mpvpaper** compilado na imagem. O indicador de privacidade ignora o próprio filtro de ruído. RAM com o filtro de ruído ligado: 697 MB.

**Pendentes da Fase 3:** conferir a bandeja com um app que tenha ícone (Discord, Steam); conferir o papel de parede em vídeo com um arquivo de vídeo; conferir o brilho num monitor com DDC/CI.

**Testes na VM:** com desenho por software, a prévia ao vivo tomava o processador e a digitação pelo VBoxManage embaralhava (agora ela atualiza 2x por segundo nesse caso). Voltar do tty para a sessão gráfica deixa a tela congelada no VirtualBox; para comandar a sessão a partir do tty, use `hyprctl -i 0 dispatch 'hl.dsp.exec_cmd("...")'`.

**Fase 4 — desenvolvimento: em andamento.** Dev Hub (app em QML, só ocupa memória aberto; busca → "Dev Hub"): **Bancos locais** (PostgreSQL, MariaDB, MySQL, Redis, MongoDB em containers Podman da conta do usuário, só em 127.0.0.1, com dados em volume; ligar/parar, copiar conexão, logs, remover guardando ou apagando os dados) e **Portas em uso** (quem usa cada porta, "Abrir no navegador" para servidores de desenvolvimento, encerrar processos da própria conta, bancos do Dev Hub identificados). Por baixo: `/usr/libexec/nyxz/nyxz-dev` (também usável no terminal). Conferido na VM: PostgreSQL 17 criado pelo Dev Hub e respondendo a consultas; página de portas com servidor de teste e o banco.

Também feitos e conferidos na VM (imagem bb2a50c): **SSH** no Dev Hub (servidor SSH do computador agora vem desligado; hosts do `~/.ssh/config` com conectar, arquivos via SFTP, túnel e remover; gerar e copiar chaves) e **Cofre** (segredos no chaveiro do sistema, destravado no login; a lista só mostra nomes; as senhas dos bancos novos vão para lá). RAM com o chaveiro: 677 MB.

Também feito: **Discord Studio** no Dev Hub. "Bots do Discord" cria projetos em discord.js ou discord.py (`~/Projetos/Discord/<nome>`, com /ping e /exemplo), guarda o token no cofre (nunca em arquivo do projeto), roda como serviço do usuário com logs ao vivo e reinicia ao salvar; "Embeds" é um editor com prévia no visual do Discord, JSON editável nos dois sentidos, cópia para discord.js/discord.py e envio de teste por webhook. Conferido na VM: bot criado, `npm install` automático, token do cofre chegando ao bot (TokenInvalid com token de mentira) e reinício ao salvar; editor de embeds com a prévia certa.

Também feitos e conferidos na VM (imagem 00d28fa): **domínios `.test` com HTTPS** (`loja.test` → `localhost:3000`, certificado do mkcert aceito pelo sistema sem avisos, Caddy na conta do usuário só enquanto há domínios ligados, senha pedida para registrar o nome) e **túnel público** (link `*.trycloudflare.com` acessado de fora pela internet; ao fechar, o link para de responder).

Também feitos e conferidos na VM: **sessões de projeto** (Dev Hub → Projetos: abrir liga os bancos, abre o VS Code, roda o comando de desenvolvimento com os segredos do cofre como variáveis e abre os links; fechar desliga tudo; "Proteger segredos no Git" bloqueia commit que contenha um valor do cofre e gera `.env.example`) e **limpeza de disco para dev** (node_modules de projetos parados, caches de npm/pip/pnpm/bun/cargo/go/mise, imagens sem uso do Podman, shaders da Steam, Flatpaks órfãos e lixeira; mostra o tamanho e só apaga o que for marcado).

**Fase 4 concluída.** Pendentes dela: conectar um bot do Discord com token real e enviar um embed por webhook real (dependem de conta do usuário).

**Fase 5 — jogos e rede: em andamento.** **Modo jogo automático**: liga sozinho quando um jogo da Steam abre e desliga quando ele fecha (pelo `nyxz-scoped`), ou pelo painel rápido. Ele troca o som para o perfil "Jogo", silencia as notificações, põe a energia em desempenho, adia as atualizações automáticas e, se você quiser, pausa os bancos do Dev Hub e liga o replay. Ao sair, tudo volta como estava (`~/.config/nyxz/modo-jogo.json` guarda as escolhas). **Replay instantâneo** (gpu-screen-recorder): Alt+F10 salva os últimos 30 segundos em `~/Vídeos/Replays` e Alt+Shift+F10 liga ou desliga. A barra mostra um controle no Modo jogo e a marca "replay" enquanto grava; o indicador de privacidade não conta o replay, que grava o som do PC e não o microfone. Conferido na VM: Modo jogo liga e desliga voltando o estado, ícones na barra e indicador de privacidade. Falta conferir no PC real: a captura do replay (a VM não oferece captura KMS) e o perfil de energia "desempenho" (não existe em VM).

Também feitos: **biblioteca de jogos** (busca → "Jogos"; app separado, 0 MB fechado). Junta os jogos da Steam (com capas, horas e última vez jogado), Epic e GOG pelo Heroic, instâncias do Minecraft no Prism, Roblox pelo Sober, programas do Bottles e jogos avulsos (qualquer comando ou AppImage). Tem busca (Enter abre o primeiro), filtros por loja, ordem por recentes, nome ou mais jogados, capa própria, ocultar e abrir a pasta. "Jogar" liga o Modo jogo; nos jogos fora da Steam, ele desliga quando o jogo fecha, e o tempo jogado fica anotado. Por baixo: `/usr/libexec/nyxz/jogos`, que lê os arquivos das próprias lojas. **LACT** no catálogo (Jogos → "LACT"), para curva das ventoinhas, limite de energia e undervolt; o `lactd` só é ligado em quem escolher o LACT. Conferido na VM com jogos de mentira: lista, filtros, busca, jogo avulso abrindo com o Modo jogo e o tempo anotado. Falta conferir com lojas reais (Steam, Heroic) e o LACT na RX 7600.

Também feitos: **Central de controles** (Configurações → Controles, ou busca → "Controles"): controles ligados com tipo, conexão e bateria; teste de botões e analógicos (mostra drift); pareamento por Bluetooth com as instruções de cada marca. Sem serviço: lê o kernel por `/usr/libexec/nyxz/controles`. A imagem ganhou o **Bluetooth** (`bluez`, que antes faltava) e as regras `steam-devices`, que liberam controles sem a Steam. O InputPlumber não tem pacote no Fedora 44; remapear fica com o Steam Input e o input-remapper. No catálogo: **Macros e remapeamento** (input-remapper), **OpenRGB** (luzes RGB, inclusive teclados Razer) e **Sunshine** (jogar no celular ou na TV pelo Moonlight; liga e desliga no painel rápido, com "Parear um aparelho (PIN)"; enquanto ligado, o indicador de privacidade mostra a tela compartilhada). Conferido na VM: página Controles, filtro que ignora mouse e mesa digitalizadora, leitura dos botões e aviso de "sem Bluetooth". Falta conferir com controle e Bluetooth reais e o Sunshine com o Moonlight.

Também feitos: **VPN, kill switch e DNS criptografado** (Configurações → VPN e DNS). Importa o `.conf` (WireGuard) ou `.ovpn` (OpenVPN, com usuário e senha) que o serviço fornece, arrastando o arquivo ou digitando o caminho. Mostra o IP público, liga e desliga a VPN (também no painel rápido, que liga a última usada) e põe um escudo na barra enquanto ela está ligada. **Kill switch:** uma tabela própria do nftables deixa sair para a internet só o que vai pela VPN; a rede de casa, a LAN virtual e a reconexão da VPN continuam liberadas, e ele volta sozinho no boot antes da rede subir. **DNS:** da rede, Cloudflare, Quad9, AdGuard ou Mullvad, os quatro com DNS-over-TLS pelo systemd-resolved. O que precisa de administrador passa pelo `nyxz-net-root` (primeira parte do `nyxz-netd`), que só aceita opções fixas e não pede senha a quem está na sessão. Conferido na VM: importar WireGuard, ligar e desligar, escudo na barra, kill switch bloqueando a internet e liberando a rede local, os três perfis de DNS resolvendo e a troca sem senha.

Também feita: **LAN virtual, "Redes de jogo"** (Configurações → Redes de jogo, ou busca → "Redes de jogo"), estilo Radmin VPN sobre o ZeroTier com o **controlador do próprio PC**: sem conta, sem site e sem o limite de 10 aparelhos do plano grátis. Criar uma rede gera um código de 16 letras; os amigos (Windows, Mac ou celular com o ZeroTier grátis) entram com ele e aparecem para você aprovar, com IP na rede, online/offline, ping e apelido. Entrar na rede de um amigo, ligar e desligar cada rede, ícone na barra enquanto alguma está ligada. O serviço só roda com rede ligada (desligado, 0 MB). Vem do repositório oficial do ZeroTier (não há pacote no Fedora) e está no catálogo, marcado no perfil Sugerido. Conferido na VM: criar rede sem senha, IP 10.147.x.y atribuído, ícone na barra, página com a rede e este PC, código inválido recusado e o serviço parando ao desligar a última rede. Falta conferir com um amigo de verdade entrando (aprovar, ping) e um jogo em LAN.

Também feita: **Voz pela LAN** (dentro de Redes de jogo). Em cada rede ligada aparece "Abrir sala de voz": o próprio PC vira o servidor (Mumble), só enquanto a sala está aberta, escutando só no IP da LAN virtual e sem anúncio na rede de casa. As salas abertas na rede aparecem sozinhas com quantas pessoas estão nelas (a Nyxz manda um ping do Mumble para cada endereço da rede) e "Entrar na conversa" abre o Mumble já na sala. Quem não tem a Nyxz entra pelo app Mumble no IP da sala. O Mumble cuida do aperte para falar, da detecção de voz e do volume por pessoa. A Nyxz gera o certificado da sala porque o Mumble 1.4 não consegue gerar o dele com o OpenSSL 3 do Fedora. No catálogo: Comunicação → "Voz pela LAN", no perfil Sugerido. Conferido na VM: sala aberta só no IP da LAN, achada pela busca, Mumble conectado com a mensagem de boas-vindas e a contagem "1 pessoa". Na primeira vez, o Mumble mostra o assistente de áudio e pergunta se confia no certificado da sala. Falta: conversa com outra pessoa de verdade e desligar a supressão de ruído do Mumble quando a da Nyxz estiver ligada (para a voz não ficar robótica).

Também feito: **Nyxz Share v1** (compartilhar a tela pela LAN, dentro de Redes de jogo → "Transmitir a tela"). O próprio PC serve as páginas e passa os recados entre quem transmite e quem assiste; o vídeo e o som vão direto de PC para PC pela LAN virtual (WebRTC, sem STUN/TURN nem servidor de terceiros). Transmitir: página no navegador deste PC (só abre por `127.0.0.1`), com a tela inteira, um monitor ou uma janela (portal do Hyprland), resolução, FPS e taxa de bits (Economia, Equilibrado, Máxima) mudáveis durante a transmissão, som do sistema ou de um app (pelo "Monitor" da saída) e microfone opcional com volumes separados, Opus estéreo de 96 a 320 kbit/s, nome e senha da sala, lista de quem assiste com taxa e ping e botão de remover. Assistir: qualquer navegador da rede, sem instalar nada (`http://IP:8787`), com resolução, FPS e atraso no canto; volta sozinho se a transmissão recomeçar. A Nyxz mostra as transmissões abertas na rede com "Assistir", e a barra mostra "ao vivo". O servidor só escuta na LAN virtual e em `127.0.0.1`. Conferido: transmissão de teste de ponta a ponta no navegador (1280×720, ~30 FPS, ~8 ms), remover alguém, senha e, na VM, servidor só na LAN, busca, bloqueio da página de transmitir para quem vem de fora e "ao vivo" na barra. Falta conferir no PC real: capturar a tela pelo portal no Brave e o som pelo "Monitor". A versão nativa (GStreamer, com codificação na placa e menos atraso) fica para depois.

Também feita: **internet por app** (Configurações → VPN e DNS → Internet por app). Para cada app: Normal, **Fora da VPN** (sai direto pela conexão normal mesmo com a VPN ligada, ex.: jogos para não aumentar o ping) ou **Sem internet** (a rede de casa e a LAN virtual continuam). O `nyx run` abre o app numa de duas fatias do systemd (`nyxz-semnet.slice`, `nyxz-direto.slice`), e o **`nyxz-netd`** (serviço root pequeno, ligado só enquanto existe alguma regra) mantém uma tabela própria do nftables com uma regra por fatia, mais a rota direta no modelo do Mullvad (marca, tabela de rotas própria e NAT de origem). O kill switch deixa passar o que é "fora da VPN", e os jogos da Steam herdam a regra da Steam. Conferido na VM: app "sem internet" sem acesso à internet e com a rede local; com uma VPN de mentira que segurava todo o tráfego, app normal sem internet e app "fora da VPN" saindo direto, inclusive com o kill switch ligado; o app aberto pelo `nyx run` na fatia certa e o `nyxz-netd` desligando sozinho sem regras. Falta: proxy por app (o sing-box não tem pacote no Fedora) e o modo "só este app pela VPN".

**Fase 5 concluída no código.** Pendentes dela (dependem de hardware, contas ou pessoas reais): captura do replay e perfil "desempenho" no PC real, lojas reais na biblioteca, LACT na RX 7600, controle e Bluetooth reais, Sunshine com o Moonlight, VPN de verdade, amigo entrando na LAN virtual, conversa na Voz, captura de tela pelo Brave no Share. Também ficaram para depois: proxy por app, "só este app pela VPN", supressão de ruído do Mumble e o Nyxz Share nativo (GStreamer).

**Fase 6 — sistema: em andamento.** **Discos** (Configurações → Discos, ou busca → "Discos"), estilo CrystalDiskInfo: ficha de cada SSD/HD com estado Bom, Atenção ou Ruim e o motivo, temperatura, vida útil, reserva, total lido e escrito, horas ligado, desligamentos inesperados, erros, firmware, número de série oculto, interface (ex.: PCIe 3.0 x4) e partições; todos os atributos SMART nos discos SATA; escrita por dia e previsão de vida útil; teste curto e completo do próprio disco; teste de velocidade estilo CrystalDiskMark (fio). Um timer de sistema lê o SMART a cada 30 min e no boot (o smartd fica desligado: nada na memória), e um aviso aparece se a saúde piorar, surgir erro novo ou a temperatura passar do limite. **Medidor na barra** (Ajustes → "Medidor na barra", desligado por padrão): CPU e temperatura, RAM e uso da placa de vídeo AMD com temperatura; ao passar o mouse, RAM dos apps × do sistema, zram e memória de vídeo. Lê /proc e /sys a cada 2 s, sem abrir processos. Conferido na VM: página Discos (o disco virtual não tem SMART e aparece como "Sem dados"), partições, teste de velocidade (SEQ1M Q8T1 ≈ 600 MB/s de leitura na VM) e medidor com o painel de detalhes. Falta conferir: o NVMe e a RX 7600 de verdade.

Também feitas: **Estatísticas por app** (Configurações → Estatísticas, ou busca → "Estatísticas"). O coletor `nyxz-stats` (serviço do usuário, ~5 MB, desligável) lê a cada 30 s o que o kernel já conta por escopo de app: tempo de processador, RAM (média e pico) e disco lido e escrito; o tempo em foco vem dos eventos de janela ativa do Hyprland; jogos da Steam contam por jogo. Grava um arquivo por dia a cada 5 min. A página mostra Hoje, 7 dias, 30 dias, Ano e Tudo, com tempo em foco, energia e apps usados comparados com o período anterior, tempo por dia, ranking por foco, tempo aberto, processador, disco, RAM ou energia, detalhe por app (horas do dia em que mais usa) e jogos. **Consumo em reais:** placa de vídeo AMD pelo sensor do driver, processador pelo RAPL (liberado só se a pessoa pedir, com a explicação do porquê) ou estimado pelo uso, mais o resto do PC; tarifa e bandeira tarifária, custo por período e por app. Privacidade: desligar, pausar 1 h, não contar um app, apagar o histórico de um app ou tudo e exportar CSV; títulos de janela e nomes de arquivo não são guardados. Conferido na VM: coletor contando o app em foco e os abertos, página nas larguras estreitas. Falta: rede por app (precisa de eBPF ou das regras do `nyxz-netd`), retrospectiva do ano e o coletor em Rust.

Também feitos: **Voltar no tempo** (Configurações → Voltar no tempo, ou no Dolphin: botão direito → "Versões anteriores"). Fotos da pasta pessoal pelo Snapper no Btrfs: 24 de hora em hora, 7 diárias e 4 semanais. Ligar pede a senha uma vez; depois o próprio usuário lista, tira fotos e restaura sem senha. `~/.cache`, a Steam e os containers do Podman viram subvolumes próprios e ficam fora das fotos. Para qualquer arquivo ou pasta (inclusive apagados), mostra as versões diferentes e restaura como cópia ao lado ou substitui (a atual vai para a lixeira). **Backup** (Configurações → Backup): restic para um HD externo/pasta ou para o Google Drive (rclone, só com acesso aos arquivos que a própria Nyxz cria), das pastas escolhidas (padrão: Projetos e Documentos), todo dia no horário escolhido (se o PC estava desligado, faz ao ligar), sem node_modules, caches, builds, Steam e containers; guarda 7 diárias, 4 semanais e 6 mensais. A senha do backup é gerada e guardada no Cofre, com botão para mostrar e anotar. Procura um arquivo nas cópias e restaura em `~/Restaurado-<data>`. Aviso se o backup falhar ou se o HD não estiver conectado. Conferido na VM: ligar o Voltar no tempo, separar as pastas pesadas, achar e restaurar a versão anterior de um arquivo, "Versões anteriores" abrindo a página já com o arquivo; backup numa pasta, backup incremental (só o que mudou), busca e restauração, horário agendado. Falta conferir: Google Drive com uma conta de verdade e um HD externo.

**Achado no teste:** o pedido de senha do chaveiro (gnome-keyring) apareceu em inglês e o chaveiro não estava destravado depois do login. Fica para o Nyxz Doctor e para conferir no PC real.

## Ferramentas de desenvolvimento

- `tools/dev-servidor.py`: serve o shell, o login e as Configurações em `http://127.0.0.1/` (na VM: `10.0.2.2`). Na VM, `nyx dev` baixa o shell e reinicia; `nyx dev limpar` volta ao da imagem.
- `nyx dev usr` (na VM): copia os scripts e dados de `/usr` do PC para um `/usr` temporário (`bootc usr-overlay`), que volta ao da imagem no próximo boot. Testa scripts sem esperar o build.
- `tools/vm-digitar.ps1`: digita texto na VM `Nyxz-Teste` (teclado ABNT2) pelo VBoxManage.
- VirtualBox no Windows: deixe o "cache de E/S do hospedeiro" ligado no controlador SATA (`VBoxManage storagectl <vm> --name SATA --hostiocache on`). Sem ele, com pouca RAM livre no PC, o disco virtual parou de responder (`AHCI#0: Port 0 reset` no VBox.log) e tudo na VM parecia travado.

## Estrutura

| Caminho | O que é |
|---|---|
| `Containerfile` | Receita da imagem base, a partir do `fedora-bootc:44` |
| `build_files/build.sh` | Instala pacotes, codecs, fontes, Flathub e configura serviços |
| `build_files/packages/` | Listas de pacotes: obrigatórios, se disponível e COPRs |
| `system_files/` | Arquivos copiados para o sistema (login, sessão, `nyx`, padrões do Hyprland) |
| `disk_config/iso.toml` | Configuração do instalador da ISO |
| `.github/workflows/build.yml` | Constrói e publica a imagem todo dia e a cada mudança |
| `.github/workflows/iso.yml` | Gera a ISO sob demanda |

## Como rodar o build (primeira vez)

1. Criar um repositório no GitHub (de preferência **público**: o Actions e o armazenamento das ISOs são gratuitos em repositórios públicos) e enviar esta pasta.
2. O workflow **Imagem** roda sozinho e publica em `ghcr.io/<seu-usuário>/nyxz`.
3. Em **Actions → ISO → Run workflow**, gerar a ISO e baixar pelo artefato.
4. Testar numa máquina virtual (Hyper-V já vem no Windows 11 Pro; VirtualBox também serve).

## Teste rápido numa VM

- Instalar pela ISO, entrar com o usuário criado.
- Deve abrir o Hyprland com fundo `#09090D`.
- `Super + Enter` abre o terminal; `Super + Espaço` abre o lançador provisório; `Super + Shift + E` sai.
- No terminal: `nyx versao` e `free -m` (anotar a RAM usada).
