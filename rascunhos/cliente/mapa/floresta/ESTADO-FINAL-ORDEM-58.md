# Ordem 58: os pés nas casas bloqueadas do mapa. ESTADO FINAL

*Fecho da ordem, 2026-11-15, Claude conta 1 (Opus 5.5), uma só sessão. Godot 4.7.2 e Node, nesta máquina. Trabalhei
na worktree `C:\Users\txcga\fable-servidor-wt`, no ramo novo `fable/pes-58`. O ramo nasceu da ponta da linha
juntada, `ac2676b` (`fable/integracao-50`). Tudo o que aparece como «provado» abaixo corri-o eu. Os registos brutos
estão em `C:\Users\txcga\fable-mapa\_tmp\o58\`, fora do repositório; os que contam estão em `provas/ordem-58-pes/`.
Não toquei na árvore do clone `fable-mapa\repo` (a superfície da Ordem 57), no clone `fable-ciclo`, em `main`
(`2383737`) nem em `.github`. A `mesa-mestre.json` não entrou em nenhum commit.*

## O que mudou (commits)

| commit | o quê |
|---|---|
| `dcef8ef` | **A medição de antes.** A prova nova `cenas/arena/ferramentas/provar_pes_bloqueadas.gd`, sozinha, antes da correcção. Neste commit sai com 15 falhas: são os números de antes. |
| `b554ff2` | **A correcção.** `CampoDaMesa.recusa_do_pe` no módulo partilhado, e as duas arenas a chamá-la. A prova da Ordem 45 conta as recusadas à parte; `pecas_mestre` ganha 3 verificações e `hud_acoes` 4. |
| `8feb196` | As provas (`provas/ordem-58-pes/`) e este ESTADO, ainda sem a parte B. |
| `ae1e574` | As listas da retoma e o MANIFESTO refeitos. É a ponta de `fable/pes-58`, empurrada no fecho da parte A. |
| `e79384d` | **A fusão:** `fable/pes-58` entra em `fable/integracao-50` (ponta `ac2676b`), empurrada no fecho da parte B. |
| *(este)* | Este ESTADO, completo, em `fable/integracao-50`. |
| *(o seguinte)* | As listas da retoma e o MANIFESTO refeitos outra vez, porque este documento está dentro de `rascunhos/`. |

## 1. A medição de antes: a reserva reproduz-se

Este é o texto da reserva 3 da Ordem 45, tal como está em `ESTADO-FINAL-ORDEM-45.md`, na raiz:

> **O pé fora da zona livre.** Na 30 × 30, nas 5 casas bloqueadas pelo mapa (menires, santuário, água) o plano
> fica até 0,30 m do relevo. O servidor recusa essas casas (Ordem 44), e é igual no jogador.

A reserva reproduz-se, com os mesmos números. Primeiro corri a prova da Ordem 45 (`provar_mestre_no_relevo.gd`) na
ponta de partida, tal como estava: na 30 × 30, «nas 5 bloqueadas pelo mapa (o servidor recusa-as): enterra 0,304 /
flutua 0,311 m» (raio da pegada). Depois corri a prova nova, no commit `dcef8ef`. Ela mede as duas arenas e pergunta
ao servidor de verdade que casas estão bloqueadas. As 5 casas são estas, iguais no Mestre e na jogadora:

| casa (30 × 30 de 1,5 m) | o que a bloqueia (servidor) | encosta | antes: a figura | plano da base − relevo, raio da pegada 0,42 m |
|---|---|---|---|---|
| (27, 0) | água funda | 6,7° | **de pé** | enterra 0,007 / flutua 0,007 m |
| (27, 3) | água funda | 10,0° | **de pé** | enterra 0,004 / flutua 0,004 m |
| (27, 24) | escarpa | 55,1° | **de pé** | **enterra 0,304 / flutua 0,311 m** |
| (24, 27) | escarpa | 67,3° | **de pé** | **enterra 0,287 / flutua 0,290 m** |
| (1, 0) | menir | 1,5° | **de pé** | enterra 0,003 / flutua 0,003 m |

O defeito tem duas faces. Nas duas escarpas, o pé fica a 0,30 m do chão. Nas outras três, o pé assenta bem, mas a
figura está de pé em cima de água funda ou de um menir, onde o mapa diz que não se pode estar. A reserva da Ordem 45
dizia «menires, santuário, água». Na medição saem água funda, escarpa e menir; nenhuma destas 5 casas é do
santuário.

Também pus uma figura em cada casa da grelha. O defeito é maior do que as 5 casas:

| grelha | casas bloqueadas com figura | de pé, antes (Mestre · jogadora) | pior plano da base − relevo nelas |
|---|---|---|---|
| 20 × 20 de 1,5 m (a zona livre) | 0 | 0 · 0 | — |
| 30 × 30 de 1,5 m | 43 | 43 · 43 | enterra 0,304 / flutua 0,311 m |
| 30 × 30 de 2 m | 42 | 42 · 42 | enterra 0,377 / flutua 0,359 m |
| 25 × 25 de 1 m | 0 | 0 · 0 | — |

## 2. A correcção (`b554ff2`)

**Onde fica.** Está no caminho partilhado das duas arenas, `cenas/arena/campo_da_mesa.gd`:

- `CampoDaMesa.recusa_do_pe(mapa, origem, casa_m, c)` devolve "" se a figura se pode pôr de pé na casa `c`. Se a casa
  do mapa que contém o centro da casa do jogo (`Assentamento.casa_do_mapa`) estiver bloqueada, devolve
  `FLORESTA-E08-CASA-BLOQUEADA: (x,y) motivo`. É a mesma regra do terreno do servidor. A Ordem 48 já tinha provado,
  em 12 grelhas (`provar_terreno_servidor`), que o cliente e o servidor dão o mesmo juízo e o mesmo motivo, casa a
  casa.
- `CampoDaMesa.anotar_recusa` guarda a recusa e escreve um aviso na consola (`push_warning`). O aviso sai uma vez,
  quando a recusa é nova ou muda, e não a cada snapshot.

As duas arenas chamam a mesma função: a do jogador em `_sincronizar_figuras` e a do Mestre em `aplicar_vista`. A
figura recusada não se desenha na arena 3D, e cada arena mostra as suas recusas em `pes_recusados()`
(figuraId → texto). No Mestre, a vez numa figura recusada não tem anel. A figura continua na folha do Mestre e no
Estado da jogadora; só não fica de pé no mapa.

**A escolha: recusa com nome, não ajuste.** Escolhi a recusa porque é o que o resto do sistema faz quando alguém
tenta pôr uma figura numa casa bloqueada:

- o servidor recusa `MASTER_PLACE` numa casa bloqueada com `CASA_BLOQUEADA: (x,y) motivo` (`sala.js`, `recusaCasa`);
- a grelha do mapa recusa `ocupar` com `FLORESTA-E08-CASA-BLOQUEADA` e deixa a casa como estava
  (`grelha_floresta.gd`). O cabeçalho dela diz que «as recusas devolvem um erro NOMEADO, nunca calam».

O ajuste para a parte legal seria desenhar a figura na casa livre mais próxima. Não o escolhi, porque **a posição é
do servidor**: o cliente nunca decide regra. Uma figura desenhada numa casa onde o servidor não a tem engana o
jogador. O toque nela daria outra casa, e os destaques, o alcance e a adjacência do servidor deixariam de bater
com o que se vê. Os ajustes que existem no sistema (`MASTER_START`, «Recomeçar» → `casaLivreMaisProxima`) são o
servidor a mudar a posição no seu próprio estado. Quando isso acontece, o cliente já recebe a casa nova.

Não toquei em `assentamento.gd` nem no pacote do terreno. O `exportar_terreno --conferir` continua «EM DIA» e as
fontes com SHA não mudaram.

## 3. As provas de depois

### As mesmas 5 casas

A prova é `provar_pes_bloqueadas.gd`, corrida na ponta do ramo, com o resultado TUDO PASSOU. O registo está em
`provas/ordem-58-pes/pes-depois.txt`.

| casa | Mestre | jogadora |
|---|---|---|
| (27, 0) | recusada «FLORESTA-E08-CASA-BLOQUEADA: (27,0) água funda» | igual |
| (27, 3) | recusada «FLORESTA-E08-CASA-BLOQUEADA: (27,3) água funda» | igual |
| (27, 24) | recusada «FLORESTA-E08-CASA-BLOQUEADA: (27,24) escarpa» | igual |
| (24, 27) | recusada «FLORESTA-E08-CASA-BLOQUEADA: (24,27) escarpa» | igual |
| (1, 0) | recusada «FLORESTA-E08-CASA-BLOQUEADA: (1,0) menir» | igual |

Ficam de pé em casas bloqueadas **0 de 5**, nas duas arenas. Nenhuma figura fica com o pé fora do chão numa casa
bloqueada, porque nenhuma fica de pé nessas casas.

### O conjunto geral, sem regressão

Comparei as posições desenhadas, os 8 bytes de x, y e z, antes e depois (`pes-antes.json` e `pes-depois.json`):

| grelha (figuras) | de pé em bloqueadas, antes → depois | recusas com o nome e o motivo do servidor | figuras nas casas que se pisam: posição igual à de antes, bit a bit |
|---|---|---|---|
| 20 × 20 de 1,5 m, conjunto da Ordem 45 (54) | 0 → 0 | 0 | 54 de 54, nas duas arenas |
| 30 × 30 de 1,5 m, conjunto da Ordem 45 (105) | 5 → **0** | 5 | 100 de 100, nas duas arenas |
| 20 × 20 de 1,5 m, uma em cada casa (400) | 0 → 0 | 0 | 400 de 400 |
| 30 × 30 de 1,5 m, uma em cada casa (900) | 43 → **0** | 43 | 857 de 857 |
| 30 × 30 de 2 m, uma em cada casa (900) | 42 → **0** | 42 | 858 de 858 |
| 25 × 25 de 1 m, uma em cada casa (625) | 0 → 0 | 0 | 625 de 625 |

- Todas as figuras de pé estão no pé da casa: `pe_figura`, igual ao `peM` do servidor bit a bit. As recusas são uma
  por cada casa que o servidor julga bloqueada, nenhuma noutras, com o motivo dele.
- **Entrar e sair.** Na 30 × 30, a figura A começa na escarpa (27,24) e a B na (29,24), que se pisa; depois trocam.
  Nas duas arenas, a que sai da escarpa põe-se de pé no pé da casa nova e perde a recusa. A que entra deixa de estar
  de pé e fica recusada. O anel da vez do Mestre só aparece com A de pé.
- **A prova da Ordem 45**, `provar_mestre_no_relevo.gd`, dá TUDO PASSOU. Comparei os JSON de antes e depois. As
  figuras nas casas que se pisam têm as mesmas medidas (54 de 54 e 100 de 100). Também não mudaram o pior plano da
  base nas outras casas (0,025 / 0,024 m na 20 × 20; 0,053 / 0,053 m na 30 × 30), as 6 da encosta, o toque nos três
  modos, as camadas coladas ao chão nem as 43 bloqueadas Mestre = jogador = servidor.

**O que se vê fora deste defeito não muda.** A zona livre (20 × 20 de 1,5 m) não tem casas bloqueadas, por isso
nada muda ali, nas duas arenas. As figuras nas casas que se pisam estão onde estavam, bit a bit. A grelha, os
destaques, o fogo e o céu não passam por este código. As fotos do CI (`foto-mestre`) são da fixture, na 20 × 20.

### Suites da linha (ponta `b554ff2`, sem janela, Godot 4.7.2)

| suite | resultado |
|---|---|
| `abrir_scripts` | 74 scripts, 0 falhas (os 73 da Ordem 54 mais a prova nova) |
| `rodar_testes` | 177/177 |
| `pecas_mestre` | **268/268** (265 mais as 3 da Ordem 58) |
| `hud_acoes` | **46/46** (42 mais as 4 da Ordem 58) |
| `abrir_mestre` · `abrir_clareira` · `canario_privacidade` · `clima_forte` | 67/67 · 22/22 · 10/10 · 119/119 |
| `medir_mestre` · `medir_painel_config` | saída 0 |
| `provar_assentamento` · `provar_terreno_servidor` · `provar_mestre_no_relevo` · `provar_pes_bloqueadas` | TUDO PASSOU |
| `exportar_terreno --conferir` | o terreno do servidor está EM DIA |
| `provar_molde_54` | 0 falhas |
| arranque `--quit-after 600` | «pronto», 0 erros |

Nenhuma suite deu SCRIPT ERROR, Parse Error nem Compile Error.

**Servidor** (`npm test`, não lhe toquei): 355 testes, 354 passam. O que falha é `fixture-mestre.test.mjs`, e falha
só nesta cópia local. A `dados-exemplo/mesa-mestre.json` está com fins de linha CRLF aqui (o resíduo da Ordem 44); no
repositório está com LF. Converti a cópia local para LF, corri esse teste e deu 2/2; depois repus a cópia CRLF. O
ficheiro não entrou em commit.

## 4. A fusão em `fable/integracao-50`

- **Antes de fundir, a ponta do ramo `fable/pes-58`.** Empurrei-o no fecho da parte A, na ponta `ae1e574`. CI
  «Testes dos rascunhos», run 43727718651: **verde nos 9 jobs** (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `retoma-pc`, `foto-mestre`). «Sonda de privacidade»,
  run 43727718716: verde.
- **A ponta registada.** Fiz o fetch e o `ls-remote` às 12:04 e outra vez às 12:05 (-0300), logo antes de fundir.
  `fable/integracao-50` estava em **`ac2676b`**, a ponta de partida desta ordem: a fusão do relógio da Ordem 57 ainda
  não tinha aterrado. Por isso não houve ponta nova sobre que fundir, e as provas desta ordem valem como estão.
- **A fusão.** `e79384d`, com `--no-ff` e um commit nomeado, sem conflitos. A árvore é **idêntica, byte a byte**, à
  de `ae1e574`, onde tudo foi provado: o `git diff ae1e574 e79384d` sai vazio.
- **Como a fiz.** `fable/integracao-50` está aberta no clone `fable-mapa\repo`, que é a superfície da Ordem 57. Para
  não mexer nessa árvore, fiz a fusão nesta worktree, numa HEAD destacada sobre `origin/fable/integracao-50`, e
  empurrei com `git push origin HEAD:fable/integracao-50`, um push normal, sem força. Não mexi no ref local
  `fable/integracao-50`: o clone da 57 vê a ponta nova no próximo fetch.
- **CI da fusão** (`e79384d`): «Testes dos rascunhos», run 43727971374, **verde nos 9 jobs**. «Sonda de
  privacidade», run 43727971430: verde.
- O commit deste ESTADO e o das listas da retoma vão por cima, na mesma linha. Esses dois commits não mudam código. O
  CI do último deles está registado no fecho da sessão, não aqui, porque este documento não pode citar o run do
  commit que o contém.

## Reservas, sem rodeios

1. **A figura recusada desaparece da arena 3D.** A jogadora também pode deixar de ver a sua própria figura no mapa.
   É a consequência da recusa: a figura não fica de pé num sítio bloqueado, e não a desenho noutro. A figura
   continua no Estado, no HUD e na folha do Mestre. O aviso fica na consola, mas **no ecrã ninguém é avisado**: não
   há mensagem ao Mestre nem à jogadora. Não acrescentei UI, porque a ordem pedia que nada mudasse no que se vê fora
   do defeito.
2. **O servidor pode deixar figuras em casas bloqueadas.** A sonda `provas/ordem-58-pes/sonda-escala-bloqueadas.mjs`
   pôs 214 criaturas na 30 × 30 de 1,5 m, todas em casas livres. Depois mudou a escala para 2 m. O servidor aceitou
   (`ROOM_RECEIPT`) e 7 figuras ficaram em casas bloqueadas: (6,4) menir, (22,4), (24,4) e (24,6) água funda,
   (22,22) e (28,24) escarpa, e (6,28) tronco tombado. A regra da Ordem 8 diz que «as posições guardam-se em
   casas: nenhuma figura mexe», e a mudança de escala não volta a conferir o terreno. Este é o caminho real em que a
   recusa nova actua. Esta ordem corrigiu a colocação nas arenas e não toquei no servidor. Fica por decidir se a
   mudança de escala se recusa com nome quando deixa figuras em casas bloqueadas, ou se as move para a casa livre
   mais próxima.
3. **A medição usa colocações feitas pela prova.** As figuras de 3 em 3 casas, como na Ordem 45, ou uma em cada
   casa, vêm de vistas e snapshots que a prova monta. Não são jogo pelo servidor. O servidor nunca as colocaria em
   casas bloqueadas por `MASTER_PLACE` (recusa-as). Só lá chegam por um caminho como o da reserva 2.
4. **Raio só da pegada.** A régua das casas bloqueadas é a da Ordem 44, no raio da pegada (0,42 m). Depois da
   correcção já não há figuras de pé nessas casas, por isso não há o que medir no raio da sombra nem no do anel.
5. **O aviso na consola** (`push_warning`) sai uma vez por figura e por recusa. No Godot, cada aviso leva o rasto
   da pilha. Nas provas com 900 figuras isto enche o registo (172 avisos numa corrida), mas não falha nada: o CI só
   procura SCRIPT ERROR, Parse Error e Compile Error.
6. **A prova nova não corre no CI**, porque precisa do Node ao lado do Godot e não toquei em `.github`. O CI guarda
   a regra com as 3 verificações do `pecas_mestre` e as 4 do `hud_acoes`. As casas (27,24) e (29,24) desses testes
   foram escolhidas com o juízo do servidor, mas os testes não perguntam ao servidor.
