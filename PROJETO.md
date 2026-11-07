# Nyxz

Ícone: `design/brand/nyxz-mark.svg` (só o símbolo, sem fundo).

Distro Linux focada em programação, com visual próprio e polido, a liberdade do Linux e a praticidade do Windows.

## Decisões tomadas

| Tema | Decisão |
|---|---|
| Base | Fedora Atomic construído como imagem (bootc), começando no Fedora 44 e indo para o 45 quando o Hyprland e o Quickshell compilarem nele. Detalhes técnicos e conflitos em [ARQUITETURA.md](ARQUITETURA.md). Atualizações atômicas com rollback no boot. ISO gerada automaticamente no GitHub Actions. |
| Interface | Hyprland + shell próprio em Quickshell (barra, busca, menus, notificações, painéis). |
| Visual | Design próprio feito à mão (sem matugen). Tema bem escuro e discreto: quase monocromático (#09090D → #F4F2F8), sem cor de destaque chamativa; cores só para estado (ok/aviso/erro), dessaturadas. Fontes Geist e Geist Mono. Minimalista: janelas sem barra de título, barra de tarefas fina e sem borda, poucos separadores e rótulos, menus curtos. Temas editáveis com prévia ao vivo. |
| Animações | Rolagem e navegação estilo Lenis: suave, com inércia e easing exponencial (desacelera sem rebote). Hover e menus continuam rápidos. Sem quique, sem blur pesado, nada no estilo macOS. |
| Discord | Vesktop (com Vencord) como cliente padrão + Discord oficial (Flatpak), os dois marcados por padrão no instalador. |
| Steam | Marcada por padrão no instalador (nativa, na imagem local personalizada), atualiza sozinha. |
| Spotify | Marcado por padrão no instalador, com Spicetify (Marketplace + tema Nyxz), reaplicado automaticamente depois de cada atualização. |
| Navegador | Brave como sugestão no instalador (Firefox ou nenhum também são opções), Wayland nativo, decodificação de vídeo por hardware (VA-API) na RX 7600. Interruptores para aceleração gráfica e acesso à internet (firewall por app) no menu da barra e nas configurações. |
| IA local | Ollama **não** entra. |
| Tudo opcional | Fora o núcleo mínimo, tudo é escolhido no instalador e pode ser mudado depois em Configurações → Apps e componentes. Ver "Instalação: tudo opcional". |
| RAM | Regra fixa: o sistema parado, logo após o login e sem apps abertos, usa **menos RAM que o Windows 11** na mesma máquina. Meta ≤ 1 GB, teto 1,2 GB. Ver "Orçamento de RAM". |

## Orçamento de RAM (regra que vale para tudo)

**Como medir de forma justa:** comparar o "Em uso" do Gerenciador de Tarefas do Windows com `MemTotal − MemAvailable` no Linux (isto é, sem contar cache, que os dois sistemas usam para acelerar e liberam quando precisa). A medição é feita 2 minutos depois do login, sem nenhum app aberto. No Windows 11, esse número costuma ficar entre 3 e 4 GB num PC de 16 GB (varia; medir no próprio PC para ter a referência real).

**Meta da Nyxz:** ≤ 1 GB, com teto de 1,2 GB. Estimativa a confirmar medindo:

| Parte | Estimativa |
|---|---|
| Kernel, systemd, udev, journald | 150–250 MB |
| Hyprland | 80–150 MB |
| Shell Quickshell (barra, busca, painéis) | 100–200 MB |
| PipeWire + WirePlumber (som) | 40–60 MB |
| NetworkManager, polkit, portais | 60–120 MB |
| Coletor do Nyxz Stats (se ligado) | ≤ 10 MB |
| **Total esperado** | **~460–810 MB** |

**Regras de construção:**
- Base `fedora-bootc` mínima, **sem** a imagem do GNOME/KDE: nada de indexador de arquivos, loja de apps rodando em segundo plano, PackageKit ou serviços de desktop que não usamos.
- Tudo o que não é essencial liga **só quando é usado** (ativação por socket do systemd): Podman, o motor do Dev Hub, o servidor SSH (desligado por padrão) e o serviço do Spicetify.
- Nenhum app abre sozinho no login (Steam, Vesktop, Discord, Spotify), a não ser que o usuário marque isso.
- zram em vez de partição de swap: comprime a memória pouco usada e, na prática, aumenta a RAM disponível.
- Brave (se instalado) com economia de memória ligada por padrão.
- Toda funcionalidade nova entra com o custo de RAM anotado. Se estourar o orçamento, ela vira opcional ou sob demanda.

**Verificação automática:** o build no GitHub Actions liga a imagem numa máquina virtual (QEMU), faz login, espera 2 minutos e mede a RAM. **Se passar do teto, o build falha** e a ISO não é publicada. Além disso, conferir no PC real, porque o driver de vídeo muda um pouco o número.

## Instalação: tudo opcional

**Regra:** só o núcleo é fixo. Todo o resto é escolhido pelo usuário: pode ser desmarcado na instalação e adicionado ou removido depois, sem reinstalar. Neste documento, "pré-instalado" ou "vem instalado" quer dizer **marcado por padrão no instalador**.

**Núcleo (o mínimo para o sistema ligar e ter interface):** kernel e firmware, driver de vídeo (Mesa), systemd, rede (NetworkManager), som (PipeWire), Hyprland + shell Nyxz (barra, busca, notificações), o app de Configurações e o gerenciador de componentes. Até terminal, navegador e gerenciador de arquivos são escolhas, com a opção "nenhum".

### Como a instalação funciona
1. **Etapa básica:** idioma, teclado, disco e usuário.
2. **"O que você quer na Nyxz?":** uma caixa por categoria. Marcar a categoria abre a lista dela para escolher item por item. Desmarcar a categoria pula tudo dela.
   - **Desenvolvimento:** pergunta "Instalar pacote de desenvolvimento?". Se sim, abre a lista com tudo que é de dev.
   - **Jogos**
   - **Comunicação e mídia**
   - **Ferramentas do sistema**
   - **Área de trabalho** (navegador, terminal, arquivos)
3. **Atalhos no topo:** "Mínimo" (desmarca tudo), "Sugerido" (o perfil deste documento) e "Personalizado".
4. **Resumo antes de instalar:** tamanho do download, espaço em disco e o que abre sozinho no login (o padrão é nada).
5. **Instalação:** o núcleo é instalado offline, direto da ISO. Os componentes escolhidos são baixados na primeira inicialização, com progresso na barra, para a ISO ficar pequena e os apps virem na última versão.

**Sobre as telas:** o instalador do Fedora (Anaconda) é limitado para telas personalizadas. Plano: o Anaconda cuida da etapa básica e, na primeira inicialização, antes do desktop, abre o **Nyxz Setup** em tela cheia, com o visual da Nyxz e as etapas 2 a 4. Para o usuário fica como a continuação da instalação.

### Catálogo (✓ = marcado no perfil "Sugerido")
**Desenvolvimento**
- Editores: VS Code ✓, Neovim, Zed.
- Git: git ✓, git-lfs ✓, GitHub CLI ✓, lazygit.
- Linguagens (via mise, com escolha de versão): Node.js LTS ✓, TypeScript ✓, Python ✓, PHP ✓, Bun, Deno, Go, Rust, JDKs (8, 17, 21, 25), C/C++ (gcc, clang, cmake), .NET, Ruby.
- Modelos de projeto: React + Vite + Tailwind ✓, Next.js, bot de Discord em discord.js ✓ ou discord.py.
- Dev Hub: Serviços locais ✓ (instala o Podman), SSH ✓, Discord Studio ✓, Cliente de API ✓, Sessões de projeto ✓, Portas em uso ✓, Cofre de segredos ✓, Domínios `.test`, Túnel público.
- Apps: Bruno ✓, DBeaver ✓, Adminer.
- Bancos já baixados: nenhum por padrão (baixam no primeiro uso). Dá para marcar MariaDB, MySQL, PostgreSQL, Redis e MongoDB.

**Jogos**
- Steam ✓ (com as bibliotecas e o Vulkan de 32 bits), GameMode + MangoHud + gamescope ✓, Modo jogo automático ✓.
- Replay instantâneo ✓ (instalado, mas o replay fica **desligado** até você ligar), Controle da placa de vídeo (LACT) ✓, Streaming para celular/TV (Sunshine) ✓, LAN virtual estilo Radmin (ZeroTier) ✓, Biblioteca de jogos unificada ✓.
- Minecraft: Java 8, 17 e 21 ✓ + Prism Launcher ✓; launcher oficial.
- Roblox: Sober (desmarcado, com aviso: instável e com risco de conta não esclarecido em 2026); Vinegar (Roblox Studio).
- Bottles, Heroic, Lutris.
- Wallpaper Engine (`linux-wallpaperengine`).

**Comunicação e mídia**
- Vesktop ✓, Discord oficial ✓, Spotify ✓ + Spicetify ✓ (dá para ter o Spotify sem o Spicetify).
- Compartilhar tela pela LAN (Nyxz Share) ✓ e Voz pela LAN ✓ (os dois exigem a LAN virtual).

**Ferramentas do sistema**
- Nyxz Stats ✓, Discos ✓, VPN e proxy ✓, Brilho dos monitores ✓, Captura de tela + OCR ✓, Conta-gotas e régua ✓, Filtro de luz azul ✓, Não perturbe por workspace ✓, Medidor na barra ✓, Cola de atalhos ✓, Nyxz Sync ✓, Limpeza de disco ✓, Voltar no tempo (snapshots) ✓, Backup automático, Celular integrado (KDE Connect).
- Convivência com o Windows ✓ (só aparece se um Windows for detectado no PC).
- Automações ✓, Consumo de energia em reais ✓, Monitor da internet ✓, Regras de janela ✓, Nyxz Doctor ✓.
- Modo streamer ✓, Macros e remapeamento ✓, Espaços com nome ✓, Privacidade (indicadores e permissões) ✓, Congelar apps em segundo plano ✓, Central de controles ✓.
- Periféricos, sugeridos conforme o hardware detectado: OpenRazer/OpenRGB ✓ (teclado Razer), `headsetcontrol` ✓ (headset Logitech compatível).

**Área de trabalho**
- Navegador: Brave ✓, Firefox ou nenhum.
- Terminal: Ghostty ✓, Kitty ou Foot.
- Arquivos: Dolphin ✓, Thunar ou nenhum.

### Como fica no sistema atômico
- **Uma única imagem base** com o núcleo, sem uma imagem para cada combinação.
- **Componentes que precisam ser nativos** (Steam, VS Code, Git, Podman, compiladores) entram numa **imagem local personalizada**: o Nyxz Setup gera um Containerfile com a imagem base da Nyxz + os pacotes escolhidos, constrói no próprio PC e o sistema passa a inicializar por ela (`bootc switch`). Quando a imagem base atualiza, um timer reconstrói a personalizada com o PC ocioso. (As extensões `systemd-sysext`, do plano anterior, não são suportadas oficialmente pelo bootc; ver ARQUITETURA.md.)
- **Apps de usuário:** Flatpak (Discord, Spotify, Sober, Prism, Bruno, DBeaver, Bottles, Heroic).
- **Linguagens:** `mise`, na pasta do usuário.
- **Funções do shell** (Stats, brilho, captura etc.): interruptores. Desligadas, não carregam nada.

### Depois de instalado
Configurações → **Apps e componentes** mostra o mesmo catálogo, com marcar e desmarcar, o tamanho de cada item e o custo de RAM (normalmente 0 parado). Remover um componente apaga só ele.

## Funcionalidades

### Serviços locais (estilo XAMPP)
- Criar instâncias de MariaDB, MySQL, PostgreSQL, Redis, MongoDB escolhendo versão, porta, usuário e senha.
- Cada instância isolada em container Podman, com volume persistente.
- Iniciar/parar, logs ao vivo, copiar string de conexão, importar/exportar dump, snapshot e reset.
- Opcional: Apache/Nginx + PHP, Adminer/phpMyAdmin.
- Interface gráfica + comando de terminal.

### SSH
- Lista de hosts (lê e edita `~/.ssh/config`), conectar com um clique.
- Gerar e gerenciar chaves.
- Navegar arquivos remotos (SFTP).
- Túneis/port forwarding (ex.: acessar banco remoto como se fosse local).
- Ligar/desligar servidor SSH da máquina.

### Discord Studio
- Modelos de bot em discord.js e discord.py.
- Token guardado no cofre de senhas do sistema.
- Rodar bot com logs ao vivo e reinício ao salvar.
- Editor de embeds com prévia ao vivo, nos dois sentidos (visual → código e código → prévia).
- Gerenciar slash commands, enviar testes para servidor próprio.

### Busca estilo Raycast
- Apps, arquivos, calculadora, conversões, histórico da área de transferência, emojis.
- Ações do sistema: criar banco, abrir editor de embed, trocar saída de áudio de um app, conectar SSH.
- Sistema de plugins.

### Som
- Volume por app e saída de áudio por app.
- Perfis (ex.: "modo call").
- Microfone com supressão de ruído (RNNoise/DeepFilterNet) e equalizador feitos com os filtros do próprio PipeWire, sem processo extra. EasyEffects fica opcional.

### Barra de tarefas
- Botão direito no app: "Fechar" e **"Finalizar tarefa"** (força o encerramento do processo e dos filhos).
- **Prévia ao passar o mouse:** miniatura da janela do app sob o cursor, aparecendo o mais rápido possível.
  - Mostra na hora a última imagem guardada (sem esperar) e troca para a imagem ao vivo logo em seguida.
  - Captura via protocolo de exportação de janelas do Hyprland (`hyprland-toplevel-export`) com o `ScreencopyView` do Quickshell, em baixa resolução para ser leve.
  - Apps com várias janelas mostram uma miniatura por janela; clicar foca a janela.
  - Apps de mídia (Spotify, vídeo no Brave) ganham controles na prévia (anterior, tocar/pausar, próxima) via MPRIS.
  - Janelas em outro workspace podem mostrar só a última imagem capturada, não ao vivo (confirmar no desenvolvimento).
- **Ícones de segundo plano (bandeja) como no Windows:**
  - Fixar o ícone na barra ou deixá-lo na área oculta (botão de seta que abre um painel com os ocultos).
  - Arrastar para reordenar e para mover entre fixos e ocultos; a escolha fica salva por app.
  - Usa o protocolo StatusNotifierItem (serviço `SystemTray` do Quickshell). Para apps antigos com bandeja XEmbed (alguns apps via Wine), usar o `xembedsniproxy`.

### Várias instâncias do mesmo app (para implementar na criação; fora da maquete e do protótipo)
- Opção por app, desligada por padrão: "Permitir várias instâncias". Fica no menu do botão direito e nas configurações.
- **Por que os apps bloqueiam:** no Linux não existe o "mutex" do Windows. Cada app trava sozinho, com arquivo de trava no perfil (Chromium/Brave: `SingletonLock`), socket (Electron: `requestSingleInstanceLock`) ou nome único no D-Bus (apps GTK/KDE). A trava existe para duas cópias não escreverem nos mesmos dados ao mesmo tempo.
- **Como contornar:** abrir a nova instância com dados separados, cada uma com sua própria pasta de perfil e configuração (`--user-data-dir`, `XDG_CONFIG_HOME`/`XDG_DATA_HOME` próprios) e, quando o app usa D-Bus, uma sessão D-Bus própria (`dbus-run-session`). Se for preciso, isolar com `bubblewrap`.
- **Modos da opção:**
  - Perfil separado e permanente (ex.: Brave "trabalho" e "pessoal", dois Vesktop com contas diferentes).
  - Perfil temporário (abre limpo e é apagado ao fechar).
- **Limites:**
  - Cada instância extra tem seus próprios dados e login. Duas cópias usando exatamente o mesmo perfil não é seguro (risco de corromper os dados), por isso esse modo não existe.
  - Alguns apps não funcionam mesmo assim: Steam e jogos com anti-cheat, por exemplo.
  - Manter uma lista de compatibilidade testada por app.

### Wallpapers
- Suporte a Wallpaper Engine via `linux-wallpaperengine` (usa os wallpapers da Steam Workshop; exige ter o Wallpaper Engine na Steam; nem todo wallpaper funciona).
- **Vídeo como wallpaper, nativo:** `.mp4`, `.webm`, `.mkv` e `.gif` (com `mpvpaper`, que usa o mpv).
  - Definir pelo botão direito no arquivo, no Dolphin ("Usar como papel de parede"), arrastando o vídeo para a tela de Aparência ou pela busca.
  - Decodificação pela placa de vídeo (VA-API na RX 7600): quase não usa CPU.
  - Sempre sem som e em loop; um vídeo por monitor ou o mesmo em todos; ajuste de enquadramento (preencher, ajustar, centralizar).
  - **Pausa sozinho quando não está visível:** janela em tela cheia, jogo aberto ou área de trabalho coberta por janelas. Volta a tocar quando aparece de novo.
  - Opção de FPS menor (ex.: 30) e de resolução reduzida, para gastar menos.
  - O primeiro quadro do vídeo vira o fundo da tela de bloqueio e do login.
  - **Custo:** só existe enquanto um vídeo está definido como wallpaper (~40–80 MB de RAM e um pouco de VRAM). Com imagem parada, custa 0. Entra na conta do usuário, não no orçamento do sistema parado.

### Jogos: Vulkan, Java, Minecraft e Roblox (oferecidos no instalador)
- **Vulkan:** driver RADV do Mesa (o melhor para a RX 7600), `vulkan-loader` e `vulkan-tools`, inclusive as versões de 32 bits que a Steam, o Proton e o Wine usam. Junto: GameMode, MangoHud e gamescope.
- **Java:** Eclipse Temurin 8, 17, 21 e 25 instalados lado a lado, porque cada versão do Minecraft pede uma:
  - Java 8 até o Minecraft 1.16.
  - Java 17 do 1.17 ao 1.20.4.
  - Java 21 do 1.20.5 em diante.
  - Java 25 é o LTS mais novo, para desenvolvimento.
  - O padrão do sistema (`java`) é o 21. Dá para trocar por projeto com o `mise`.
- **Minecraft:** Prism Launcher marcado por padrão (gerencia instâncias, mods e escolhe o Java certo sozinho). O launcher oficial fica opcional.
- **Roblox:** não existe versão para Linux, e o Wine parou de funcionar com o anti-cheat do Roblox. O caminho que funciona hoje é o **Sober** (Flatpak `org.vinegarhq.Sober`), que roda a versão Android do Roblox. Ele é de terceiros e pode parar de funcionar se o Roblox mudar algo. Para o Roblox Studio, existe o Vinegar.
- **Outros jogos e apps do Windows:** Proton pela Steam, Bottles para programas Windows e Heroic para Epic e GOG.

### Steam, Discord e Spotify (oferecidos no instalador)
- **Spotify + Spicetify:**
  - O Spicetify precisa modificar os arquivos do Spotify. Num sistema atômico a parte do sistema é somente leitura, então o Spotify entra como **Flatpak no espaço do usuário** (`flatpak install --user com.spotify.Client`), onde os arquivos podem ser alterados. O `spicetify-cli` vem junto com o componente Spotify.
  - Na primeira inicialização o Spicetify já é aplicado com o Marketplace (loja de temas e extensões) e um **tema Nyxz** nas cores do sistema.
  - Cada atualização do Spotify desfaz o Spicetify. Um serviço do usuário (systemd) percebe a atualização e roda `spicetify backup apply` sozinho.
  - Se uma atualização do Spotify quebrar o Spicetify antes de sair a correção, o serviço deixa o Spotify original funcionando e avisa por notificação, em vez de deixar o app quebrado.
  - Assim como o Vencord, o Spicetify modifica o cliente, coisa que o Spotify não aprova oficialmente.
- **Steam:** pacote nativo do RPM Fusion na imagem local personalizada, com as bibliotecas de 32 bits e o Mesa/Vulkan para a RX 7600. É melhor que o Flatpak para controles e pastas de jogos. O cliente da Steam se atualiza sozinho ao abrir, então está sempre na última versão independente da data da ISO.
- **Discord:** Vesktop (com Vencord) como padrão. Ele carrega o Discord web, então está sempre na última versão do Discord sem precisar baixar atualização. Compartilha tela com áudio no Wayland.
  - **Cliente oficial do Discord também é oferecido** (marcado por padrão), via Flatpak (`com.discordapp.Discord`), que se atualiza sozinho em segundo plano (às vezes com algumas horas de atraso em relação ao lançamento). Assim não aparece o aviso de "baixe a nova versão" que o pacote .deb/.tar.gz exige.
  - Os dois convivem: Vesktop e Discord oficial são apps separados, cada um com seu login.
- **Como garantir "a última versão":**
  - A imagem é reconstruída automaticamente no GitHub Actions (diariamente), puxando as versões mais novas dos pacotes.
  - A ISO é uma foto do dia em que foi gerada. Na primeira inicialização o sistema já aplica a imagem mais recente e atualiza os Flatpaks.
  - Depois disso, atualizações automáticas em segundo plano (imagem + Flatpaks), aplicadas no próximo boot, com opção de voltar para a versão anterior.

### Ajustes da Nyxz (equivalentes aos mods do Windhawk)
No Windows, o Windhawk injeta código no Explorer para mudar o sistema. Na Nyxz a barra, a busca e os menus são nossos (Quickshell), então esses "mods" viram **opções nativas** numa tela de Ajustes, com um interruptor por item. Não há nada injetado, nada quebra com atualização e a RAM extra é praticamente zero.

| Mod do Windhawk | Na Nyxz | Padrão |
|---|---|---|
| Taskbar Fluent Media Player | Mini player na barra (capa, título, anterior/tocar/próxima, barra de progresso) para qualquer app de mídia via MPRIS | Ligado |
| Instant Taskbar Thumbnail Previews | Prévia instantânea ao passar o mouse (já planejada), com atraso de abrir/fechar ajustável | Ligado, 0 ms |
| Taskbar Volume Control | Rolar a roda do mouse sobre a barra (ou sobre o ícone de som) muda o volume; com Ctrl muda o volume do app em foco | Ligado |
| Taskbar tray system icon tweaks | Esconder individualmente os ícones do sistema (rede, som, microfone, notificações, brilho) | Todos visíveis |
| Taskbar tray icon spacing and grid | Espaçamento dos ícones de segundo plano ajustável e opção de mostrar a área oculta em grade | Espaçamento padrão |
| Disable grouping on the taskbar | Um botão por janela em vez de um por app | Desligado (agrupa) |
| Remove Taskbar Window Suffixes | Regras para limpar títulos de janela (tirar " — Brave", " - Visual Studio Code" etc.) | Regras básicas ligadas |
| Taskbar on top for Windows 11 | Barra em cima ou embaixo (e nas laterais) | Embaixo |
| Taskbar Dock Animation Plus | Ícones da barra crescem levemente sob o mouse, em estilo discreto e configurável (intensidade e alcance) | Desligado |
| Windows 11 Taskbar Styler | Temas da barra: cor, transparência, altura, cantos, posição dos itens | Tema Nyxz |
| Windows 11 Start Menu Styler | Temas da busca/menu iniciar | Tema Nyxz |
| Windows 11 Start Menu Power Buttons | Botões de desligar, reiniciar, suspender, hibernar, bloquear e sair direto na busca (e digitando "desligar") | Ligado |
| Taskbar Restart Explorer | "Reiniciar barra" no botão direito da barra: reinicia o shell em menos de 1 s sem fechar apps | Ligado |
| Customize Windows notifications placement | Canto e monitor das notificações | Canto superior direito |
| Alt+Tab per monitor | Alt+Tab mostrando só as janelas do monitor onde está o mouse | Desligado (1 monitor) |
| AltDrag | Mover janela com tecla + arrastar e redimensionar com tecla + botão direito, de qualquer ponto da janela. Nativo do Hyprland; a tecla é configurável (Super ou Alt) | Ligado com Super |
| Invisible Window Borders | Borda das janelas configurável até 0 px, mantendo cantos arredondados | Borda fina |
| Dynamic Island for Windows | "Ilha" opcional no topo da tela que reage a mídia, downloads, área de transferência e gravação de tela | Desligado |
| Disable Office Hotkeys | Não se aplica (o Linux não reserva Ctrl+Shift+Alt+Win). Todos os atalhos são configuráveis | — |
| Explorer Info Bar+ | Barra de status do gerenciador de arquivos com espaço livre do disco, tamanho da seleção e detalhes do arquivo | Ligado |
| Explorer Tags | Etiquetas coloridas em arquivos e pastas, com painel de etiquetas na lateral | Ligado |
| Explorer Visual Tweaks Dark | Tema Nyxz no gerenciador de arquivos (seleção, progresso, painel de prévia) | Ligado |
| File Hover Info | Cartão com tamanho, datas e detalhes ao parar o mouse sobre um arquivo | Ligado |
| Paste Clipboard Content to Explorer | Colar texto ou imagem da área de transferência direto como arquivo numa pasta | Ligado |
| Better file sizes in Explorer details | Tamanho das pastas na visão de detalhes, unidades legíveis e opção KiB/MiB | Ligado |

**Gerenciador de arquivos:** Dolphin, porque já faz nativamente várias coisas que no Windows precisam de mod: colar conteúdo como arquivo, etiquetas, painel de informações, dicas ao passar o mouse, tamanho de pastas e abas. Com o tema Nyxz e o indexador Baloo **desligado** por padrão (respeitando o orçamento de RAM; as etiquetas continuam funcionando sem ele). Medir a RAM com ele aberto e fechado.

A tela de Ajustes fica no app de configurações, com busca e prévia ao vivo.

### Estatísticas por app (Nyxz Stats)
Contador de uso por app e por jogo, com histórico e visão geral. Pode ser desligado inteiro, e o usuário escolhe quais apps e jogos entram.

**O que é medido, por app:**
- **Tempo:** aberto, em foco (janela ativa) e por sessão; jogos contados por jogo, não como "Steam".
- **Rede:** bytes baixados e enviados.
- **RAM:** uso médio e pico.
- **Disco:** bytes lidos e escritos, arquivos criados, sobrescritos e apagados.
- **CPU e GPU:** tempo de CPU; uso e VRAM na RX 7600 (o driver da AMD informa por processo).

**Como medir sem pesar (a maior parte dos números o kernel já conta sozinho):**
- Cada app aberto pela barra, pela busca ou pelo atalho roda no seu próprio "escopo" do systemd. O kernel já contabiliza, por escopo, CPU, RAM (atual e pico) e bytes lidos e escritos em disco (cgroups v2). O coletor só lê esses números a cada 30 s.
- Rede por app: contagem por escopo com eBPF (o mesmo mecanismo do `IPAccounting` do systemd), um contador no kernel sem copiar pacotes.
- Arquivos apagados e sobrescritos: um programa eBPF pequeno conta exclusões, renomeações e aberturas com truncamento por escopo. Só contadores, sem guardar nomes de arquivo.
- Tempo em foco: eventos do Hyprland (janela ativa, aberta, fechada) pelo socket de eventos, sem varredura.
- Jogos: cada jogo da Steam é identificado pelo ID do jogo (`SteamAppId`) no processo; jogos de outros launchers, pelo executável.
- Apps abertos pelo terminal contam dentro do terminal, a não ser que sejam abertos com `nyx run`.

**Armazenamento:**
- SQLite local, gravando em lote a cada 5 minutos (poupa o SSD).
- Detalhe por minuto guardado por 7 dias, por hora por 90 dias e por dia para sempre. Estimativa: poucos MB por ano.
- Bônus do sistema: total já escrito no SSD (dado SMART do NVMe) e saúde do disco ao longo do tempo.

**Telas:**
- **Visão geral:** hoje, semana, mês, ano e tudo, com ranking dos apps por tempo, rede, disco e RAM, e comparação com o período anterior ("+3 h de VS Code em relação à semana passada").
- **Por app:** gráficos ao longo do tempo, sessões, horários em que mais usa e picos de RAM e de rede.
- **Jogos:** horas por jogo, estilo Steam, incluindo jogos de fora da Steam.
- **Retrospectiva do ano:** resumo anual estilo "Wrapped" (apps mais usados, horas de código contra horas de jogo, quanto baixou da internet).

**Controle e privacidade:**
- Interruptor geral, pausar por um tempo, e lista de apps incluídos ou excluídos (o padrão inclui todos; o usuário tira o que não quer).
- Apagar o histórico de um app ou tudo; exportar para CSV/JSON.
- Tudo fica só no PC. Títulos de janela **não** são guardados (só o nome do app), a não ser que o usuário ative.

**Custo:** coletor em Rust, meta de ≤ 10 MB de RAM e CPU praticamente zero (lê alguns arquivos a cada 30 s). Fica dentro do orçamento de RAM; desligado, custa 0.

### VPN e proxy nativos
**VPN:**
- WireGuard nativo no kernel (o mais rápido e leve) e OpenVPN, gerenciados pelo NetworkManager. Importar um `.conf` ou `.ovpn` com um clique (funciona com Proton VPN, Mullvad, a VPN do trabalho ou um servidor próprio).
- Painel na barra: ligar e desligar, servidor atual, IP público e tráfego.
- **Kill switch:** se a VPN cair, a internet é bloqueada até ela voltar, para nada vazar.
- Conectar sozinho em redes Wi-Fi não confiáveis.
- **VPN por app (split tunnel):** escolher quais apps passam pela VPN ou quais ficam de fora (ex.: jogos fora da VPN para não aumentar o ping). Funciona com os mesmos escopos do systemd das estatísticas: o nftables marca o tráfego por escopo e a rota é escolhida por app.

**Proxy:**
- Proxy do sistema (HTTP, HTTPS e SOCKS5) aplicado de uma vez para os apps que respeitam a configuração do sistema.
- **Proxy por app**, inclusive para apps que ignoram proxy: o tráfego do app escolhido é desviado por um túnel local (sing-box) só enquanto a regra estiver ligada.
- Perfis (casa, faculdade, trabalho) com proxy e VPN juntos, ativados por rede Wi-Fi.

**DNS:**
- DNS criptografado (DNS-over-TLS) pelo systemd-resolved, com opção de DNS que bloqueia anúncios e rastreadores.

**Custo:** WireGuard roda no kernel (praticamente 0 de RAM). O sing-box só liga quando há regra de proxy ativa (~20–30 MB).

### LAN virtual para jogar com amigos (estilo Radmin VPN)
- O Radmin VPN não tem versão para Linux e é fechado. A Nyxz usa o **ZeroTier**, que cria uma rede local virtual de verdade (camada 2): a descoberta de partidas em LAN funciona como numa rede de casa (ex.: "Abrir para LAN" do Minecraft, jogos com LAN pela Steam).
- **Limitação:** quem usa Radmin não entra na mesma rede de quem usa ZeroTier. Os amigos no Windows instalam o ZeroTier (grátis, tem para Windows, macOS, Android e iOS).
- **Painel "Redes de jogo"** (junto da VPN):
  - Criar uma rede com um nome e gerar um código ou link de convite.
  - Entrar numa rede colando o código.
  - Lista de membros com nome, online/offline, IP na rede e ping; aprovar ou remover quem entra.
  - Ligar e desligar cada rede com um clique; ícone na barra enquanto alguma está ligada.
- O firewall libera o tráfego só na interface dessa rede, sem abrir nada na internet.
- **Controlador próprio por padrão** (o ZeroTier já vem com um embutido), sem depender do site, cujo plano grátis tem limite de 10 dispositivos e 1 rede. Limitação: o PC que criou a rede precisa estar ligado para alguém novo entrar.
- **Custo:** o serviço do ZeroTier só roda enquanto uma rede está ligada (~10–20 MB). Desligado, 0.
- Item do catálogo: Jogos → "LAN virtual (estilo Radmin)", marcado no perfil "Sugerido".

### Compartilhar tela pela LAN (Nyxz Share)
Transmitir a tela para amigos direto de PC para PC, pela LAN virtual, **sem servidor nosso nem de terceiros** no meio (alternativa à transmissão do Discord).

**Como funciona:**
- Quem transmite é o próprio servidor: o seu PC captura a tela, codifica o vídeo e envia direto para cada amigo pelo IP da LAN virtual (WebRTC). Como todos estão na mesma rede virtual, não precisa de servidor de conexão (STUN/TURN) nem de nada na nuvem.
- **Quem assiste não precisa ter a Nyxz:** basta estar na mesma LAN virtual (ZeroTier) e abrir o link (`http://IP-na-LAN:porta`) no navegador (Chrome, Edge, Brave, Firefox). Quem tem a Nyxz assiste num visualizador nativo, com menos atraso.

**Transmitir:**
- Escolher a tela inteira, um monitor ou só uma janela (portal de captura do Hyprland).
- **Som junto, ligado por padrão:**
  - Fonte: som do sistema inteiro, só de um app (ex.: só o jogo, sem as notificações do Discord), de vários apps escolhidos ou nenhum.
  - Qualidade do som: Opus estéreo 48 kHz, de 96 a 320 kbit/s (padrão 160).
  - Microfone opcional, desligado por padrão (a voz costuma ficar no Discord), com volume separado do som do jogo.
- **Qualidade de vídeo ajustável:**
  - Resolução: 720p, 1080p, 1440p ou a nativa da tela.
  - FPS: 30, 60, 90, 120, 144 ou 180 (até o Hz do monitor de quem transmite). Acima de 60 é recomendado para quem assiste no visualizador nativo da Nyxz; no navegador, o estável é até 60.
  - Taxa de bits em controle deslizante, com atalhos prontos: Economia, Equilibrado e Máxima.
  - Tudo pode ser mudado **durante a transmissão**, sem reiniciar.
  - Ajuste automático opcional: se a conexão de alguém piorar, a qualidade dele cai para não travar, sem afetar os outros (a RX 7600 aguenta mais de uma codificação ao mesmo tempo).
  - Codificação na placa de vídeo (H.264, HEVC ou AV1), sem pesar no jogo.
  - Quem assiste vê no canto a resolução, o FPS e o atraso atuais.
- Indicador sempre visível na barra enquanto transmite, com o botão de parar.

**Pessoas (sistema de adicionar):**
- Lista de amigos baseada nos membros das Redes de jogo: adicionar pelo código de convite, ver quem está online.
- Convidar para assistir com um clique; o amigo recebe uma notificação (ou o link, se não tiver a Nyxz).
- Controle de quem entra: aprovar cada pessoa, sala com senha ou só amigos da lista. Ver quem está assistindo e remover alguém.
- Aviso "Fulano começou a transmitir" para quem está na mesma rede, com opção de silenciar.

**Limites:**
- O limite é a velocidade de **upload** da sua internet: cada pessoa assistindo recebe a própria cópia (1080p 60 FPS ≈ 8–12 Mbit/s por pessoa). O app mostra quantos espectadores cabem na sua conexão.
- Atraso esperado: ~50–150 ms, dependendo da distância e da rota da LAN virtual.
- Quem assiste também precisa do ZeroTier (o mesmo da LAN virtual).

**Base técnica:** primeira versão com WebRTC pronto para navegador (no estilo do Screego, que roda na máquina de quem transmite). Depois, uma versão nativa com GStreamer (`webrtcbin` + codificação VA-API) para menos atraso e menos uso de CPU.

**Custo:** 0 parado. Só roda enquanto você transmite ou assiste.
- Item do catálogo: Comunicação e mídia → "Compartilhar tela pela LAN (Nyxz Share)", marcado no perfil "Sugerido" (exige a LAN virtual).

### Saúde dos discos (estilo CrystalDiskInfo)
App nativo "Discos" com tudo sobre cada SSD/HD, usando `smartmontools` e `nvme-cli`.

- **Estado geral:** Bom, Atenção ou Ruim, com a cor e a explicação do motivo (como no CrystalDiskInfo).
- **NVMe (o seu SSD de 500 GB):** temperatura (atual e máxima), vida útil consumida (%), reserva disponível, total lido e escrito (TB), horas ligado, quantas vezes foi ligado, desligamentos inesperados, erros de mídia e de integridade.
- **SATA/HD:** setores realocados, pendentes e incorrigíveis, erros de CRC, temperatura, horas ligado e todos os atributos SMART em tabela.
- **Informações do disco:** modelo, firmware, número de série (oculto por padrão), interface e velocidade do link (ex.: PCIe 3.0 x4), capacidade, partições e sistema de arquivos.
- **Histórico:** escrita por dia e temperatura ao longo do tempo, aproveitando os dados do Nyxz Stats, com previsão de vida útil no ritmo atual.
- **Alertas:** notificação se a saúde cair, se surgir erro novo ou se a temperatura passar do limite.
- **Teste de velocidade (estilo CrystalDiskMark):** leitura e escrita sequencial e aleatória (SEQ1M Q8T1, SEQ1M Q1T1, RND4K Q32T1, RND4K Q1T1) com `fio`, sob demanda, com histórico dos resultados.
- **Testes SMART:** rodar o teste curto ou o estendido do próprio disco e ver o resultado.
- **Custo:** checagem por timer (a cada 30 min e no boot), sem serviço ficando na memória. RAM parado: 0.

### VS Code (nativo)
- Componente opcional (marcado por padrão no pacote dev), pelo repositório oficial da Microsoft (RPM) na imagem local personalizada, **não** como Flatpak: o terminal integrado, os SDKs (Node, Python, Java), o Git e o Podman funcionam sem as limitações do sandbox.
- Atualizado junto com a imagem (reconstruída todo dia), então fica sempre na última versão.
- Wayland nativo ligado (texto nítido, sem desfoque no Hyprland).
- Vem com o tema Nyxz, a fonte Geist Mono e a telemetria desligada por padrão (pode religar).
- É o "Editor" da barra de tarefas.

### Git (nativo)
- `git`, `git-lfs` e GitHub CLI (`gh`) na imagem local personalizada (marcado por padrão no pacote dev), não como Flatpak.
- Se o Git for escolhido, o Nyxz Setup pede nome e e-mail do Git, cria uma chave SSH (ed25519) e, se o usuário quiser, já cadastra a chave no GitHub pelo `gh auth login`.

### Brilho dos monitores (estilo Twinkle Tray)
- Controle de brilho de monitores externos pelo próprio cabo (DDC/CI), com `ddcutil`. O módulo `i2c-dev` vem carregado e o usuário já tem permissão, sem precisar de sudo.
- Na barra: clicar no ícone de brilho abre um controle deslizante por monitor. Rolar a roda do mouse sobre o ícone ajusta o brilho.
- Brilho ligado ao horário (mais baixo à noite), junto com o filtro de luz azul.
- Depende do monitor ter DDC/CI ligado no menu dele. Confirmar no Mancer Valak.
- RAM: 0 parado. O `ddcutil` só roda quando o brilho muda.

### Ideias aprovadas (todas entram)
1. **Sessões de projeto:** abrir um projeto restaura terminal, editor, abas do Brave, bancos do Dev Hub e variáveis de ambiente. Fechar desliga os bancos e libera RAM.
2. **Portas em uso:** a busca e o Dev Hub mostram quem ocupa cada porta, com botão para encerrar, e detectam servidores de desenvolvimento rodando ("abrir localhost:5173").
3. **Domínios locais com HTTPS:** `projeto.test` aponta para a porta local com certificado válido (Caddy + mkcert), ligado só quando acessado.
4. **Túnel público com um clique:** link temporário para o localhost (Cloudflare Tunnel), para testar webhooks do Discord, de pagamentos e do GitHub.
5. **Modo jogo automático:** jogo em tela cheia ativa o perfil de som "Jogo", o não perturbe e o CPU em desempenho máximo, adia atualizações e, se marcado, pausa os bancos do Dev Hub. Tudo volta ao fechar o jogo.
6. **Medidor na barra:** CPU, RAM, GPU e temperaturas, separando RAM do sistema e RAM dos apps. Fechado por padrão.
7. **Captura de tela completa:** recorte com anotação e desfoque, gravação em vídeo/GIF e copiar texto de imagens (OCR com Tesseract, português e inglês).
8. **Conta-gotas e régua na tela:** cor em HEX/RGB/HSL e medida em pixels.
9. **Não perturbe por workspace:** silenciar notificações do Discord no workspace de código, por exemplo.
10. **Backup automático dos projetos:** cópia incremental (restic) para HD externo ou nuvem (rclone/Google Drive), em horários marcados, com restauração de arquivo por data.
11. **Filtro de luz azul:** tela mais quente no horário escolhido (hyprsunset).

Todas seguem o orçamento de RAM: ficam desligadas até serem usadas ou reagem a eventos que o sistema já recebe.

### Ideias aprovadas (segunda rodada)
12. **Convivência com o Windows (dual boot):**
    - Windows detectado e listado no menu de boot; ação "Reiniciar no Windows" no menu de energia e na busca.
    - Partições NTFS do Windows acessíveis no Dolphin (somente leitura por padrão, com opção de escrita).
    - Relógio certo nos dois sistemas: o Linux usa o relógio da placa-mãe em horário local quando há Windows, evitando o erro de 3 horas.
    - Aviso se o "Início rápido" do Windows estiver ligado (ele trava as partições NTFS).
13. **Nyxz Sync:** guarda as configurações num repositório **privado** do próprio usuário no GitHub: tema, atalhos, Ajustes, lista de componentes escolhidos, configurações do VS Code e do terminal. Numa instalação nova, entra com o GitHub e restaura tudo. Segredos e tokens **nunca** entram no Sync (ficam no cofre). Sincroniza só quando algo muda.
14. **Cola de atalhos (Super + /):** sobreposição com todos os atalhos agrupados por tema e busca, mais um editor visual para trocar qualquer atalho, com aviso de conflito.
15. **Replay instantâneo (estilo ShadowPlay):**
    - Atalho salva os últimos 30 s (duração ajustável); também grava normal e grava só o áudio do jogo.
    - Usa o codificador de vídeo da RX 7600 (`gpu-screen-recorder`), com impacto mínimo no FPS.
    - **Fácil de desligar:** interruptor no painel da barra, na busca ("desligar replay") e um atalho próprio. Ícone na barra só aparece enquanto está gravando no buffer. Desligado, não roda nada e não usa RAM.
    - Opção de ligar só quando um jogo abrir (junto com o Modo jogo) e desligar ao fechar.
16. **Controle da placa de vídeo (estilo MSI Afterburner):** LACT com tema Nyxz (o CoreCtrl teve relatos de curva de ventoinha sem efeito na RX 7600): curva das ventoinhas, limite de energia, perfis de desempenho, undervolt e perfis automáticos por jogo. Os perfis automáticos rodam só enquanto o jogo está aberto.
17. **Streaming para celular ou TV:** Sunshine (servidor, no PC) + Moonlight (no celular/TV). Painel para parear dispositivos com PIN, escolher resolução e FPS e ligar/desligar. Liga só quando ativado.
18. **Limpeza de disco para dev:** encontra `node_modules` de projetos sem uso há X dias, caches de npm/pnpm/pip/mise/cargo, imagens e volumes órfãos do Podman, cache de shaders da Steam, runtimes Flatpak sem uso, lixeira e logs antigos. Mostra quanto libera por item e pede confirmação antes de apagar.
19. **Voltar no tempo (snapshots da pasta pessoal):** Snapper com Btrfs tirando fotos da pasta pessoal a cada hora (mantém as últimas 24 de hora em hora, 7 diárias e 4 semanais). Restaurar um arquivo ou uma pasta direto no Dolphin ("Versões anteriores"). Pastas pesadas e descartáveis (`node_modules`, caches, jogos da Steam) ficam de fora.
20. **Cofre de segredos de dev:** tokens de bot, senhas de banco e chaves de API guardados criptografados no chaveiro do sistema. O Dev Hub injeta as variáveis ao rodar o projeto, gera um `.env.example` sem valores e instala uma verificação no Git que bloqueia commit com segredo.
21. **Celular integrado (KDE Connect, Android):** notificações do celular no PC, área de transferência compartilhada, envio de arquivos nos dois sentidos, controle de mídia e celular como mouse. Desmarcado no perfil "Sugerido" porque fica rodando (~30–50 MB) enquanto ligado.

### Ideias aprovadas (terceira rodada)
22. **Voz pela LAN:** chamada de voz entre amigos pela LAN virtual, com o PC de quem cria a sala como servidor (Mumble/`murmur`). Áudio Opus de baixo atraso, supressão de ruído, aperte para falar ou detecção de voz, volume por pessoa. Integrada à lista de amigos e ao Nyxz Share (assistir e conversar na mesma sala). Quem não tem a Nyxz entra com o app Mumble (Windows, Android, iOS). RAM: ~10–20 MB só durante a chamada.
23. **Automações (estilo Atalhos do iPhone):** editor visual de "quando acontecer X, faça Y".
    - Gatilhos: horário, app abriu/fechou, jogo começou, rede Wi-Fi, dispositivo conectado (headset, controle, pendrive), monitor ligado, bateria do headset baixa, RAM alta.
    - Ações: perfil de som, saída de áudio de um app, VPN/proxy, não perturbe, brilho, filtro de luz azul, wallpaper, abrir sessão de projeto, iniciar/parar serviços do Dev Hub, replay instantâneo, rodar um script.
    - Modelos prontos para começar; cada automação pode ser ligada e desligada. Roda dentro do shell, reagindo a eventos, sem serviço extra.
24. **Consumo de energia em reais:** watts do processador (RAPL) e da RX 7600 (sensor do driver), com estimativa do PC inteiro. Com a tarifa informada pelo usuário (R$/kWh, com bandeira tarifária opcional), mostra custo por hora, dia e mês e custo por app e por jogo, juntando com o Nyxz Stats. Os números são estimativas; um medidor de tomada daria o valor exato.
25. **Monitor da internet:** mede periodicamente ping, variação (jitter), perda de pacotes e velocidade; registra quedas com data, hora e duração. Gera relatório (PDF/CSV) pronto para reclamar com a operadora ou na Anatel, comparando com a velocidade contratada. RAM: 0, roda por timer.
26. **Regras de janela sem editar arquivo:** tela visual para regras por app (workspace, monitor, flutuar, tamanho e posição, sempre por cima, opacidade, tela cheia). Grava as `windowrule` do Hyprland por baixo. Botão "criar regra a partir desta janela" no botão direito.
27. **Nyxz Doctor:** diagnóstico de vídeo, som, rede, disco, atualizações, componentes e RAM, com explicação em português simples e conserto com um clique quando der. Gera um relatório para pedir ajuda, sem dados pessoais. RAM: 0 até abrir.
28. **Biblioteca de jogos unificada:** todos os jogos num lugar: Steam, Epic e GOG (via Heroic), Minecraft (Prism), Roblox (Sober), jogos do Bottles e avulsos. Capas, horas jogadas (Nyxz Stats), última vez jogado, filtros e busca. "Jogar" já liga o Modo jogo e, se configurado, o replay instantâneo. RAM: 0 até abrir.

### Ideias aprovadas (quarta rodada — lista fechada por enquanto)
29. **Modo streamer (privacidade na tela):** liga sozinho ao transmitir pelo Nyxz Share, gravar a tela ou abrir o OBS. Esconde notificações, o cofre de segredos, janelas com `.env`, IP e e-mail na barra; borra janelas escolhidas. Indicador na barra enquanto está ativo. RAM: 0.
30. **Macros e remapeamento de teclado e mouse:** trocar a função de teclas e botões, macros, perfis por app e por jogo (input-remapper; OpenRazer para o Razer Cynosa). RAM: ~5–10 MB só com algum perfil ativo.
31. **Espaços com nome:** workspaces com nome e ícone ("Código", "Jogos", "Estudo"), cada um com wallpaper, apps fixados na barra e regras próprias (não perturbe, Modo jogo). Integra com automações e sessões de projeto. RAM: 0.
32. **Privacidade: indicadores e permissões:** ponto na barra quando um app usa câmera, microfone ou captura de tela, mostrando qual app; tela de permissões por app (câmera, microfone, arquivos, rede), cobrindo Flatpaks e apps nativos via portais. RAM: 0.
33. **Congelar apps em segundo plano:** apps escolhidos são congelados (freezer do cgroup) durante jogos ou após X minutos sem uso: param de gastar CPU e a RAM deles pode ir para o zram. Voltam na hora ao clicar. Desligado por padrão para apps que precisam de rede contínua (Discord, Vesktop). Libera RAM em vez de gastar.
34. **Central de controles:** parear controles Xbox e PlayStation, bateria, remapear botões, giroscópio do controle de PS e teste de controle, também fora da Steam (InputPlumber). RAM: 0 até abrir.

**Lista de funcionalidades fechada por enquanto (2026-11-07).** Próximo passo: escolher a primeira versão (v1) e começar a construir.

## Hardware alvo (PC do dono)

| Peça | Modelo | Observação |
|---|---|---|
| CPU | Ryzen 5 5600GT | Zen 3. |
| GPU | RX 7600 8 GB (Gigabyte OC) | AMD: driver aberto no kernel/Mesa, sem driver extra. |
| RAM | 16 GB DDR4 | zram ativado. |
| Armazenamento | NVMe 500 GB | Btrfs. |
| Placa-mãe | Biostar A520M | |
| Monitor | Mancer Valak 180 Hz | Configurar 180 Hz + VRR no Hyprland. |
| Teclado | Razer Cynosa V2 | RGB via OpenRazer/OpenRGB. |
| Headset | Logitech (modelo a confirmar) | `headsetcontrol` para bateria/sidetone, se suportado. |
| Microfone | Fifine USB (modelo a confirmar) | Padrão USB, funciona sem driver. |
| Mouse | Genérico | |

## Etapas
Tudo entra na v1.0, construído em fases que terminam cada uma com uma ISO testável. Detalhes em [ARQUITETURA.md](ARQUITETURA.md).

0. Esqueleto e CI: imagem, ISO e teste de RAM automático. *(em andamento)*
1. Desktop mínimo usável: login, Hyprland, barra, busca, notificações, som, Ghostty, Dolphin, Brave.
2. Fundações: `nyxz-scoped`, `nyxz-audio`, `nyxz-netd`, catálogo, imagem local personalizada, Nyxz Setup.
3. Interface completa: prévias, bandeja, Ajustes, espaços, regras, brilho, wallpapers, animações, privacidade.
4. Desenvolvimento: Dev Hub completo e ferramentas.
5. Jogos e rede.
6. Sistema: Estatísticas, Discos, snapshots, Sync, automações e o resto.
7. PC real e polimento.

Já feito: maquete no Figma (v3 minimalista) e protótipo navegável com movimento estilo Lenis.
