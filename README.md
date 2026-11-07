# Nyxz

Distro Linux pessoal focada em programação e jogos: Hyprland com interface própria, visual escuro e minimalista, tudo opcional na instalação e menos RAM que o Windows.

- **O que a Nyxz vai ter:** [PROJETO.md](PROJETO.md)
- **Como cada parte é construída, conflitos e ordem de construção:** [ARQUITETURA.md](ARQUITETURA.md)
- **Visual:** [design/](design/) (maquete e protótipo navegável)

## Estado

**Fase 0 — esqueleto e CI.** A imagem base (núcleo) e a ISO são geradas pelo GitHub Actions. Ainda não foi testada: use só em máquina virtual.

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
