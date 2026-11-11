# Plano de correções — teste no PC real (11/11/2026)

Fonte: `testes/teste-pc-real-2026-11-11.txt`. Organizado por lote, na ordem em que vou corrigir.
Cada lote termina conferido na VM, com commit; o PC real recebe tudo pela atualização automática.

## Decisão principal: janelas no estilo Windows 11

O Hyprland é, por padrão, um gerenciador "lado a lado" (tiling): sem minimizar, sem botões
no topo, com janelas se encaixando sozinhas. O teste deixou claro que isso não serve. Decisão:
**continuar no Hyprland** (barra, busca, efeitos e tudo da Nyxz dependem dele), mas com um
**modo Windows por padrão**:

- Todo app abre **em janela** (flutuante, centralizado, tamanho bom), nunca encaixado nem em tela cheia.
- **Botões no topo de toda janela: Minimizar | Maximizar | Fechar**, desenhados pelo próprio
  Hyprland (plugin oficial `hyprbars`) para valer em qualquer app. Apps que já desenham a
  própria barra (GTK/Electron) ficam com a deles, sem barra dupla.
- **Maximizar** = ocupa a tela menos a barra de tarefas; clicar de novo volta à janela normal.
- **Tela cheia (F11)** separada do maximizar; Esc/F11 sempre sai (resolve o Spotify preso).
- **Minimizar** de verdade: a janela some e volta pela barra de tarefas.
- Arrastar pela barra do topo, encostar na borda para metade da tela (como o Snap do Windows).
- O modo "lado a lado" continua existindo como opção em Configurações, para quem quiser.

Se o `hyprbars` não compilar para o Hyprland 0.57, o plano B é ligar as barras dos próprios
apps (Chromium/Electron/Qt) e o menu da janela pelo botão direito na barra de tarefas.

## Lote 1 — Janelas (o mais importante)
1. Modo Windows: janelas flutuantes por padrão, tamanho e posição iniciais bons.
2. Barra com Minimizar | Maximizar | Fechar em todo app (hyprbars ou plano B).
3. Maximizar (mantém a barra), tela cheia F11 separada, sair sempre com Esc/F11.
4. Minimizar para a barra de tarefas e restaurar ao clicar no app.
5. Super+D: minimizar tudo / voltar tudo.
6. Encaixar na metade/canto ao arrastar até a borda.
7. Configurações → Janelas: modo Windows ou lado a lado.

## Lote 2 — Teclado e área de trabalho
1. Tecla Super sozinha abre a busca (como o Iniciar).
2. Alt+Tab com prévia das janelas (e Alt+Shift+Tab).
3. Áreas de trabalho (1–5) opcionais: padrão é uma área só, sem números na barra.
4. Configurações → Atalhos: ver e mudar os atalhos (minimizar, maximizar, print…).
5. Fixar apps na barra de tarefas (botão direito → Fixar).

## Lote 3 — Visual
1. Tela de boot limpa: só o NX animado (Plymouth), sem texto do sistema; também ao desligar.
2. Ícones: pacote de ícones completo (Papirus escuro) + ícones próprios para os apps da Nyxz
   (hoje aparecem como o quadriculado roxo/preto).
3. Gerenciador de arquivos com tema escuro e visual moderno (Dolphin com Breeze escuro e
   cores da Nyxz; avaliar um visual mais próximo do Explorer do Windows 11).
4. Fontes, símbolos e emojis completos (Noto completo, símbolos, CJK, fontes compatíveis com Windows).

## Lote 4 — Apps
1. Vencord e Spicetify: descobrir por que não aplicam e corrigir (Discord/Vesktop e Spotify Flatpak).
2. Sober (Roblox): permissões do Flatpak já aplicadas na instalação.
3. Claude Code como componente opcional no Nyxz Setup e em Apps e componentes.
4. `sudo` instalado e funcionando para o usuário administrador.
5. Terminal: Ctrl+C copia (se houver seleção) e Ctrl+V cola, sem Shift.

## Lote 5 — Produtividade
1. Histórico da área de transferência (Super+V), como no Windows.
2. Print: Ctrl+C copia e fecha a tela do print (comportamento configurável).
3. Apps padrão e tipos de arquivo: Configurações → Apps padrão (navegador, e-mail, música,
   vídeo, imagens…) e por extensão, como no Windows.

## Seções do teste ainda vazias
Instalação, rede/som/tela e desempenho ficaram sem anotação. Depois do Lote 1, peço uma
segunda rodada curta só dessas partes (e a medição de RAM no PC real).
