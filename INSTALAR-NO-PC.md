# Instalar a Nyxz no PC (ao lado do Windows, sem pendrive)

PC: BIOSTAR A520MH, Ryzen 5 5600GT, RX 7600, NVMe PNY 500 GB (Windows no C:).
Plano: Windows continua igual; a Nyxz fica com **29 GB** (o máximo que o Windows deixou encolher ligado; o índice do NTFS trava o resto); o instalador mora numa
partição de **4 GB** ("NYXZ") que depois volta para o Windows.

Disco depois do preparo:

```
[boot EFI 100 MB][reservada][Windows C:][NYXZ 4 GB][livre 29 GB → Nyxz][recuperação]
```

Ensaiado numa VM com o mesmo desenho (partição de boot de 100 MB, "Windows" NTFS,
NYXZ de 4 GB, espaço livre): o instalador liga pela NYXZ, acha a imagem da Nyxz nela,
instala só no espaço livre e não toca no Windows.

---

## Parte 1 — no Windows (você, ~5 min)

### 1. Desligar o Início rápido
Ele deixa o disco do Windows "meio desligado" e atrapalha o Linux.

1. Menu Iniciar → digite **Painel de Controle** → **Hardware e Sons** → **Opções de Energia**.
2. À esquerda: **Escolher a função dos botões de energia**.
3. **Alterar configurações não disponíveis no momento**.
4. Desmarque **Ligar inicialização rápida (recomendado)** → **Salvar alterações**.

### 2. Desligar a memória virtual por um boot
O arquivo dela (`pagefile.sys`, 23 GB) fica no fim do C: e impede o Windows de encolher.
Ela volta logo depois (eu religo).

1. Tecla **Windows + R** → digite `SystemPropertiesPerformance` → Enter.
2. Aba **Avançado** → em Memória virtual, **Alterar…**
3. Desmarque **Gerenciar automaticamente o tamanho do arquivo de paginação**.
4. Selecione **C:** → marque **Sem arquivo de paginação** → **Definir** → **Sim** no aviso → **OK** → **OK**.
5. **Reinicie o PC** e volte aqui na conversa.

## Parte 2 — eu faço (com o seu "Sim" no aviso de permissão)

1. Encolher o C: em 33 GB (feito em 11/11).
2. Criar a partição **NYXZ** (4 GB, FAT32) logo depois do C:.
3. Copiar a ISO para ela e trocar o nome no menu de boot (`EFI/BOOT/grub.cfg`).
4. Religar a memória virtual automática.
5. Criar a opção **"Instalador Nyxz"** no boot do PC e marcá-la **só para o próximo boot**
   (`bcdedit`), sem mexer na ordem: se der qualquer problema, o PC volta para o Windows sozinho.

## Parte 3 — a instalação (você, ~20 min)

**Cabo de rede ligado** (o Setup baixa os apps no primeiro boot).

1. **Reinicie.** O menu da Nyxz aparece → **Install Nyxz 44** (Enter).
   - Se em vez disso o Windows abrir: reinicie e aperte **F9** várias vezes ao ligar
     (menu de boot da BIOSTAR) → escolha **Instalador Nyxz** (ou "UEFI: … NYXZ").
   - Se aparecer erro de *Secure Boot*: ao ligar, **Del** → Boot/Security → Secure Boot
     **Disabled** → F10 salvar. (Pode religar depois.)
2. No resumo da instalação:
   - **Destino da instalação** → o disco **PNY 500 GB** já marcado → **Automática** →
     **NÃO** marque "Libere espaço removendo ou reduzindo partições" → deve mostrar
     ~29 GB livres → **Pronto**.
   - Aparece "**Aviso** ao verificar configuração de armazenamento" (a partição de boot
     tem menos de 500 MB). **É normal**, é só aviso: a Nyxz usa a mesma partição de boot
     do Windows.
   - **Criação de usuário** → seu nome, usuário e senha (essa senha também destrava o
     chaveiro e serve como senha de administrador) → **Pronto**.
3. **Iniciar a instalação** → ~10–15 min → **Reiniciar o sistema**.

## Parte 4 — primeiro boot

1. Entre com sua senha. O **Nyxz Setup** abre: escolha os apps (Brave, Discord, Steam…);
   eles baixam com progresso na barra.
2. A partir do segundo boot, o menu ao ligar mostra **Nyxz** e **Windows** (e "Reiniciar
   no Windows" fica na busca). O relógio já fica certo nos dois.
3. Configurações → **Nyxz Doctor** → "Verificar" (tem que dar tudo certo).
4. Me chame aqui para a lista de testes do PC real e para os ajustes.

## Parte 5 — devolver os 4 GB ao Windows (depois que tudo estiver bem)

No Windows: **Gerenciamento de Disco** → botão direito em **NYXZ** → **Excluir volume**;
botão direito no **C:** → **Estender volume** → avançar até o fim. (Eu removo a opção
"Instalador Nyxz" do boot.)

---

**Se algo der errado no meio da instalação:** o Windows não é tocado em nenhum passo. Basta
reiniciar; o PC volta para o Windows e a gente vê o que houve.
