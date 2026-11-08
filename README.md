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

**Próximos da Fase 4:** domínios `.test` com HTTPS, túnel público, sessões de projeto (com o cofre injetando as variáveis) e limpeza de disco para dev.

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
