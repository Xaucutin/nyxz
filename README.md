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

## Ferramentas de desenvolvimento

- `tools/dev-servidor.py`: serve o shell, o login e as Configurações em `http://127.0.0.1/` (na VM: `10.0.2.2`). Na VM, `nyx dev` baixa o shell e reinicia; `nyx dev limpar` volta ao da imagem.
- `tools/vm-digitar.ps1`: digita texto na VM `Nyxz-Teste` (teclado ABNT2) pelo VBoxManage.

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
