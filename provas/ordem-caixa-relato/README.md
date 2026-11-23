# Provas — Ordem CAIXA-RELATO (B7b da conferência da CAIXA-HUD-JOGADORA · 21/11/2026, Claude conta 2, PC)

**O defeito:** no §4 do relato da prova da caixa, a linha «a caixa que lhe chegou só tem ligada, ordemPor e
ordemDinamica …» imprimia `Estado.caixa` — o JSON do último ROOM_SNAPSHOT (`"fechada":false`, 3 figuras) — logo abaixo
de «fechada: true», sem dizer que os eventos recebidos depois desse snapshot já tinham adiantado a caixa. O JSON velho
passava por actual.

**A correcção (só nas ferramentas das provas; nada de código do jogo):** a linha diz sempre de que snapshot é o JSON
(seq, revisão, hora a que chegou, quantos eventos chegaram depois) e compara-o com a caixa ACTUAL dela (o modelo do HUD,
`hud.ordem_turnos`, que os eventos adiantam). Se forem diferentes: «JSON DESACTUALIZADO (…)» antes do JSON velho e, na
mesma linha, «a caixa ACTUAL dela (revisão N): {…}». Se forem iguais: «JSON actual (…)». Só ids opacos e os campos da
caixa da Party — nenhum nome verdadeiro, vida, alma ou PA.

## Ficheiros
- `ferramentas/relato_caixa.gd` — o ajudante sem estado (a linha, a caixa actual, a comparação).
- `ferramentas/teste_relato_caixa.gd` — o teste do registo sem servidor nem ecrã, com o modelo real do HUD:
  **15/15** (`teste-relato.log`).
- `ferramentas/correr-prova-caixa-relato.sh` — corre o teste e as duas provas vivas com as ferramentas corrigidas
  (`provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd` e
  `provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd`, que carregam o ajudante).
- `cliente-hud/` — a prova da CAIXA-HUD-JOGADORA: **38/38** (as 36 de antes + 2 novas: §4 o relato marca o JSON como
  DESACTUALIZADO e a caixa actual que imprime é a do servidor; §5 o JSON da reentrada sai como actual).
- `cliente-manequim/` — a prova da CAIXA-MANEQUIM: **48/48** (46 + as mesmas 2).
- `suites/` — as suites do cliente e do servidor que cobrem a caixa.

Servidor de mesa real (`provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs`, semente 7, motor VLAB
real sha256 `a91c021c…`, cenário `7703320c…`, fichas `3c498137…`), Godot 4.7.2 Windows, RTX 4060. As capturas das duas
corridas não entram no ramo (não são o objecto desta ordem; o lançador move-as para a pasta tmp).

Correr de novo (Git Bash, na raiz do repo; num clone novo, primeiro `godot --headless --path rascunhos/cliente --import`):
`bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`

---

# Correcções B1–B6 da conferência (Ordem CAIXA-RELATO-CORRECOES · 21/11/2026, Claude conta 2, PC)

As corridas das correcções estão em **`correcoes/`** (as de cima, da ordem CAIXA-RELATO, ficam como estavam — são o
registo do que se viu nessa altura).

- **B1 — a frase dos eventos diz a verdade.** O contador ouve agora a APLICAÇÃO no Estado (`Estado.snapshot_aplicado`
  / `Estado.evento_aplicado`), não a recepção na Rede (`Rede.snapshot_recebido` / `Rede.evento_recebido`): um snapshot
  velho que o Estado recusa ou um evento repetido já não lhe mexem. Conta todos os eventos aplicados e, à parte, os
  **de actor** (`OrdemTurnos.actor_do_evento` ≠ ""), os únicos que podem adiantar a caixa. O `turno` que um `encerrar`
  produz não tem actor. A linha deixou de dizer «que a adiantaram»: diz «N evento(s) aplicado(s) depois dele [tipos],
  K de actor (só esses podem adiantá-la)». A contagem está em `ferramentas/relato_caixa.gd` (`novo_snap`,
  `anotar_evento`), e as provas e o teste usam a mesma.
- **B2 — o número de eventos é verificado.** Os tipos ficam na linha. A prova viva tem uma verificação nova no §4: a
  contagem e os tipos do relato têm de ser **exactamente** os que o Estado aplicou desde o snapshot
  (`Estado.eventos_desde_snapshot`), com 2 de actor e 2 `turno` (as duas vezes jogadas). No caso vivo foram
  `[movimento, turno, ataque, estado, turno]`: 5 eventos, 2 de actor. O teste ganhou o caso exacto de um `encerrar` (só
  um `turno`) que não muda a caixa: 1 evento, 0 de actor, «JSON actual».
- **B3 — a hora leva milissegundos** (`HH:MM:SS.mmm`, segundos e milissegundos lidos do mesmo instante). O snapshot do
  §1 e o do §4 continuam a chegar com o mesmo `seq 13, revisão 10`, mas agora distinguem-se sempre pela hora. O teste
  confere que dois snapshots iguais a 5 ms um do outro dão linhas diferentes.
- **B4 — `caixa_actual` só vale em modo dinâmico.** Fica escrito no comentário: em iniciativa o HUD mostra
  `Estado.iniciativa`/`vezId`, que o ajudante não lê. Também fica escrito que `ligada`/`ordemPor` do «actual» vêm do
  SNAPSHOT e que só a `ordemDinamica` vem do modelo do HUD.
- **B5 — as capturas entram no ramo (decisão).** As 10 capturas das duas corridas das correcções estão em
  `correcoes/cliente-hud/` e `correcoes/cliente-manequim/` (≈11,6 MB). O motivo para não as incluir era que o
  conteúdo seria «quase igual ao das ordens antigas, nada de HUD mudou». Isso não se confirmou. As capturas da
  HUD-JOGADORA no ramo (`provas/ordem-caixa-hud-jogadora/cliente/`) são de antes da PALETA-C ponto 2 (as cores da
  caixa), do LAGO-MAIOR e da CAIXA-JANELA. A caixa e o lago de hoje já não são os dessas imagens: 35–44 % dos píxeis
  diferem (limiar 0,06 por canal RGB). Nas do MANEQUIM diferem 2–19 %. Esta ordem não mudou nada no HUD, mas a linha
  mudou, e sem as capturas novas o ramo não teria nenhuma imagem da caixa como ela é hoje. As da corrida CAIXA-RELATO
  (21:02) ficaram fora: são da base `7c97b48`. Não são iguais a estas nas 5 capturas da HUD: diferem 20,2 % (§1),
  3,2 % (§2), 1,4 % (§3), 1,0 % (§4) e 13,7 % (§5). Só do §2 ao §4 ficam perto; o 1,0 % é só o §4.
  *Emenda (CAIXA-RELATO-CORRECOES-4, B4):* aqui dizia «no essencial, iguais a estas (1,0 % de diferença no §4 da
  HUD)», o que valia para o §4 e não para as 5. Os números são de `correcoes-3/comparacao-caixa-relato-vs-correcoes.log`
  (método `ferramentas/comparar_capturas.gd`). As 5 capturas dessa corrida entraram depois no ramo, em
  `cliente-hud/` (CORRECOES-3, B5).
  *Emenda (CAIXA-RELATO-CORRECOES-2, B4):* os intervalos que aqui estavam (54–65 %, 7–38 %, 2,7 %) não se
  reproduziam. Vinham de um script não cometido que somava os três canais. O método está agora em
  `ferramentas/comparar_capturas.gd` (ver a secção CORRECOES-2, abaixo).
- **B6 — cosmético e cobertura.** Corrigi a numeração do §5 do `ESTADO-FINAL-ORDEM-CAIXA-RELATO.md`. O teste de
  privacidade varre agora as 4 linhas que o teste gera (3 «JSON actual» e a do §4), não só a do §4.

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7):
- teste do registo `correcoes/teste-relato.log`: **21/21** (eram 15);
- prova HUD-JOGADORA `correcoes/cliente-hud/relato.txt`: **39/39** (eram 38);
- prova MANEQUIM `correcoes/cliente-manequim/relato.txt`: **49/49** (eram 48);
- suites `correcoes/suites/`: servidor 418/418, prova da caixa do servidor PROVA OK, rodar_testes 290/290,
  caixa_jogadora 18/18, caixa_janela 69/69, hud_acoes 50/50, canario_privacidade 10/10, abrir_scripts 107 / 0 falhas.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js>
<pasta-tmp> "$PWD/provas/ordem-caixa-relato/correcoes"`. O lançador continua a mover as capturas para a pasta tmp; as
desta pasta foram copiadas de lá à mão.

---

# Correcções B1–B6 da conferência da CAIXA-RELATO-CORRECOES (Ordem CAIXA-RELATO-CORRECOES-2 · 21/11/2026, Claude conta 1, PC)

As corridas estão em **`correcoes-2/`** (as de `correcoes/` e as de cima ficam como estavam).

- **B1 — os nomes do relato são os públicos, e o canário varre o relato.** `_nome()` e a linha «bancada: …» das duas
  provas vivas (`prova_caixa_jogadora.gd`, `prova_caixa_manequim.gd`) liam o `nome` da vista do Mestre, e por isso os
  relatos cometidos traziam os nomes verdadeiros n.º 1 e n.º 2 (os valores-canário). Agora lêem o `nomePublico`
  (as primeiras palavras deles), ou o id quando não há nome público. Além disso, o canário estende-se ao relato: em cada passagem
  (§1, §4, §5) confere que nenhuma linha escrita até ali traz um nome verdadeiro (os que diferem do público), e em
  `_fim()` confere o relato inteiro. Com a mutação «voltar a ler `nome`», a prova HUD dá 39/43 (as 4 verificações
  novas falham).
- **B2 — o teste varre as 6 linhas.** As 2 linhas do caso da hora passam a entrar na varredura: 6 linhas, 5 «JSON
  actual». Uma fuga que só aparecesse nessas linhas passava 21/21 no teste antigo e agora falha.
- **B3 — proibidas:** juntam-se `"master"`, `"caixaMestre"` e `"pa"`.
- **B4 — a comparação ao píxel tem método cometido** (`ferramentas/comparar_capturas.gd`) e os intervalos foram
  emendados nos dois sítios: HUD **35–44 %**, MANEQUIM **2–19 %** (`correcoes-2/comparacao-capturas.log`). Os números
  antigos vinham da soma dos canais (`--metodo=soma`, `correcoes-2/comparacao-capturas-soma.log`).
- **B5 — a hora do caso B3.** Os dois snapshots ficam agora a 20 ms um do outro, e a hora (HH:MM:SS) confere-se contra
  a hora LOCAL do sistema, lida antes e depois. Com `bias` a zero, o teste dá 22/23 neste PC (UTC−3).
- **B6 — um `estado` no §4 do teste.** Traz `figuraId` mas não é de actor: 7 eventos, 3 de actor. Com a mutação
  «contar `estado` como de actor», o teste dá 21/23.

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7):
- teste do registo `correcoes-2/teste-relato.log`: **23/23** (eram 21);
- prova HUD-JOGADORA `correcoes-2/cliente-hud/relato.txt`: **43/43** (eram 39);
- prova MANEQUIM `correcoes-2/cliente-manequim/relato.txt`: **53/53** (eram 49);
- suites `correcoes-2/suites/`: servidor 418/418, prova da caixa do servidor PROVA OK, rodar_testes 290/290,
  caixa_jogadora 18/18, caixa_janela 69/69, hud_acoes 50/50, canario_privacidade 10/10, abrir_scripts 107 / 0 falhas.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js>
<pasta-tmp> "$PWD/provas/ordem-caixa-relato/correcoes-2"`. Comparar as capturas:
`godot --headless -s provas/ordem-caixa-relato/ferramentas/comparar_capturas.gd -- <pasta-a> <pasta-b>`. As capturas
desta corrida não entram no ramo: a ordem não as pede e o lançador move-as para a pasta tmp.

---

# Correcções B1–B4 da sentença da CAIXA-RELATO-B7 (Ordem CAIXA-RELATO-B7-CORRECOES · 22/11/2026, Claude conta 2, PC)

Só registo e teste; nada do código do jogo muda. As corridas estão em **`b7-correcoes/`**.

- **B2 — a varredura de privacidade cobre o caso do `limpar()`.** O `_caso_limpar` (B7) corria depois da varredura do
  B6 e não era varrido. Agora gera a linha do relato em cada um dos 4 passos (como as provas a escrevem) e varre-as
  com a mesma lista (`PROIBIDAS`, partilhada). Teste: **30/30** (eram 28 na linha integrada).
  - Mutação «sem a correcção B7» (`eventos_desde_snapshot = []` do `limpar()` tirado): **27/30**, as 3 falhas da B7
    (`b7-correcoes/mutacao-1-sem-B7.log`).
  - Mutação «canário na caixa do snapshot do caso» (`"nome": "Canario-Bancada"`): **29/30**, a varredura nova acusa
    `["nome", "nome"]` (`b7-correcoes/mutacao-2-canario.log`).
- **B3** — «o snapshot **deste caso**» no comentário do teste.
- **B1, B3, B4** — no `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7.md` (raiz).

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7): teste `b7-correcoes/teste-relato.log`
**30/30**; prova HUD-JOGADORA `b7-correcoes/cliente-hud/relato.txt` **43/43**; prova MANEQUIM
`b7-correcoes/cliente-manequim/relato.txt` **53/53**; suites `b7-correcoes/suites/`: caixa_janela 69/69,
caixa_jogadora 18/18.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js>
<pasta-tmp> "$PWD/provas/ordem-caixa-relato/b7-correcoes"`. **O 4.º argumento tem de ser absoluto:** relativo, o
`--saida` da prova é resolvido pelo Godot a partir de `rascunhos/cliente/` (aconteceu nesta corrida; os `relato.txt`
foram movidos à mão para `b7-correcoes/` e as capturas para a pasta tmp — nada ficou em `rascunhos/`).
# Correcções B1–B7 da sentença da CAIXA-RELATO-CORRECOES-2 (Ordem CAIXA-RELATO-CORRECOES-3 · 22/11/2026, Claude conta 1, PC)

As corridas estão em **`correcoes-3/`**. As de cima ficam como estavam.

- **B1 — a varredura final cobre o ficheiro todo.** Em `_fim()`, as 3 linhas finais (a verificação, a linha em branco e
  o resumo) compõem-se primeiro e a varredura corre sobre o relato mais essas 3. A contagem diz agora esse tamanho:
  **68 linhas** na HUD e **78** no manequim, que são as do ficheiro (antes dizia 65 e 75). Depois de **todas** as
  `_linha()`, o relato volta a ser varrido; se aí aparecer um nome, entra uma linha FALHA e a prova sai com 1.
  Mutações: com um canário no resumo, a HUD dá 42/43 e o manequim 52/53. Com um canário na linha em branco (que só
  a re-varredura vê), dá 43/44 e rc=1. Na base, as três passavam 43/43 e 53/53.
- **B2 — o canário não distingue maiúsculas.** Há um `to_lower()` dos dois lados em `_nomes_no_relato` (agora
  `_nomes_em`) e na varredura dos textos da caixa. Mutações: com o nome verdadeiro em minúsculas no relato, a HUD dá
  39/43; com ele num texto da caixa, dá 36/43. Na base, as duas passavam 43/43.
- **B3 — o cabeçalho do §1 usa o nome público.** Usa `_nome(vista, figuraId)` → `_nome_publico`, guardado no fim da
  montagem, e não o `nome` do cenário (que é o do lugar, o login). Prova: um cenário em que a espadachim tem
  `nomePublico` «Espadachim» (diferente do `nome`) dá «== 1. a jogadora (Espadachim) …» e 43/43 e 53/53; na base, dá
  39/43 e 49/53, porque o cabeçalho trazia o nome verdadeiro.
- **B4 — só comentário**, em `teste_relato_caixa.gd`. Diz que a eficácia de `"master"`/`"caixaMestre"`/`"pa"` assenta
  nas mutações do executor, e que o `"pa"` sozinho nunca migra para o canário vivo: ocorre 23× como substring no
  relato vivo («Espadachim», «aparelho», «PA», …).
- **B5 — o «1,0 %» tem prova no ramo (caminho a).** Cometi as 10 capturas da corrida CORRECOES-2
  (`correcoes-2/cliente-hud/`, `correcoes-2/cliente-manequim/`; os SHA-256 batem com os da pasta tmp dessa ordem) e a
  comparação `correcoes/` ↔ `correcoes-2/` (`correcoes-3/comparacao-correcoes-vs-correcoes-2.log`). **Essa comparação
  não dá 1,0 %:** no §4 da HUD dá **0,6 %**, e o intervalo é 0,4–32,1 % na HUD e 0,6–23,8 % no manequim. O 1,0 % é da
  corrida **CAIXA-RELATO (21:02) ↔ `correcoes/`**, como o texto do §4.2 diz. Por isso cometi também as 5 capturas da
  HUD dessa corrida (`cliente-hud/*.png`, ao lado do relato dela, que lhes corresponde) e a comparação
  `correcoes-3/comparacao-caixa-relato-vs-correcoes.log`, que dá **4-religada-avancou.png 1,0 %** (7519 de 740160
  píxeis). Os 1,0 % do §4.2 e da B5 ficam como estão.
- **B6 — a hora com fuso injectável.** `hora_ms(unix, bias_min)` aceita um instante e um fuso; sem argumentos usa os do
  sistema, como antes. O teste ganhou uma verificação com bias −180 e +330 (valores esperados escritos à mão) que não
  depende do fuso da máquina. Mutação «`hora_ms()` sem o fuso» com o aparelho simulado em UTC (o caso do CI): o teste
  da base dava **23/23** (cego) e o novo dá **23/24**. Não há remendo ao workflow.
- **B7 — `correcoes-3/mutacoes.log`.** Estão lá as caudas das mutações, na base e no código novo. As 6 da ordem
  anterior reproduzem, na base, **B1 39/43, B2 22/23, B3 ×3 22/23, B5 22/23, B6 21/23**. Para correr de novo:
  `bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes.sh <godot.exe> <vlab-completo.js> <pasta-tmp> <base|novo> <registo.log>`.
  As mutações estão escritas em `ferramentas/mutacoes.mjs`.

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7):
- teste do registo `correcoes-3/teste-relato.log`: **24/24** (eram 23; +1 do fuso injectado);
- prova HUD-JOGADORA `correcoes-3/cliente-hud/relato.txt`: **43/43**, 68 linhas varridas = 68 no ficheiro;
- prova MANEQUIM `correcoes-3/cliente-manequim/relato.txt`: **53/53**, 78 = 78;
- suites `correcoes-3/suites/`: servidor 418/418, prova da caixa do servidor PROVA OK, rodar_testes 290/290,
  caixa_jogadora 18/18, caixa_janela 69/69, hud_acoes 50/50, canario_privacidade 10/10, abrir_scripts 107 / 0 falhas.

---

# Correcções B1–B4 da sentença da CAIXA-RELATO-B7-CORRECOES (Ordem CAIXA-RELATO-B7-CORRECOES-2 · 22/11/2026, Claude conta 2, PC)

Só o teste do registo; nada do código do jogo muda. As corridas estão em **`b7-correcoes-2/`**.

- **B1 — `"propria"` entra em `PROIBIDAS`.** Nenhuma linha legítima de `relato_caixa.linha()` a traz (palavras fixas,
  rótulos, tipos de evento, campos da caixa, ids hexadecimais). Mutação «`propria` na caixa do snapshot do caso»:
  **29/30** (`mutacao-1-propria.log`); o teste antigo dava **30/30** (`mutacao-1-propria-teste-antigo.log`).
- **B2 — nenhum eco antes da varredura.** As linhas (do §B6 e do caso do `limpar()`) só se imprimem depois de
  varridas, e uma linha com palavras proibidas fica RETIDA (sai o rótulo e as palavras, não a linha). Mutação «nome-
  canário na caixa do caso»: **29/30** e o valor **0 vezes** no log (`mutacao-2-canario-eco.log`); no teste antigo, o
  valor saía **2 vezes**, antes da FALHA (`mutacao-2-canario-eco-teste-antigo.log`).
- **B4 — as 4 linhas do caso presas.** Rótulo «B7-1:»…«B7-4:» e origem (seq 1, 0, 0, 5); a B7-2 e a B7-3 têm o mesmo
  corpo, o que o teste também confere. Mutação «a linha B7-1 perde-se e a última repete-se»: **29/30**
  (`mutacao-3-sem-B7-1.log`); o teste antigo dava **30/30** (`mutacao-3-sem-B7-1-teste-antigo.log`).
- **B3** — no `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES.md` (raiz).

Números (Godot 4.7.2 Windows, Node 26.13.0, motor VLAB real `a91c021c…`, semente 7): teste `teste-relato.log`
**30/30**; prova HUD-JOGADORA **43/43**; prova MANEQUIM **53/53**; suites `suites/`: servidor **418/418**, prova da
caixa do servidor **PROVA OK**. Os logs de mutação foram feitos com cópias do teste na pasta `ferramentas/`, apagadas
antes do commit.

---

# Correcções B1–B4 da sentença da CAIXA-RELATO-CORRECOES-3 (Ordem CAIXA-RELATO-CORRECOES-4 · 22/11/2026, Claude conta 1, PC)

Só as ferramentas das provas; nada do código do jogo, do HUD nem das cores muda. As corridas estão em
**`correcoes-4/`**; as mutações, executadas, em `correcoes-4/mutacoes.log` (modo `base4` = os ficheiros de `da6683e`,
modo `novo` = o código desta ordem).

- **B1 — a re-varredura falhada não acrescenta linhas.** Em `_fim()` (as duas provas vivas), se a re-varredura do
  relato escrito achar um nome, a verificação do fim passa a FALHA e o resumo é refeito, os dois **no sítio**
  (`_reescrever`, que troca a linha e regrava o ficheiro). A contagem continua a ser a do ficheiro e há um só resumo.
  Mutação «canário na linha em branco final»: na base, o relato fica com **70 linhas e 2 resumos** («43 de 43» e
  «43 de 44»), e a linha do fim continua a dizer 68; com o código novo, fica com **68 linhas, 1 resumo, 42/43**, rc=1.
  No manequim: 80 linhas e 2 resumos («53 de 53», «53 de 54») passam a **78 linhas, 1 resumo, 52/53**.
- **B2 — as linhas FALHA não ecoam nomes.** Os achados dizem «nome verdadeiro n.º K na linha L» (o n.º em
  `_canarios_nomes`) e, nos textos da caixa, «canário n.º K (nome|número) no texto n.º J da caixa». Nunca dizem o
  valor nem o texto que o traz. Contagem dos nomes verdadeiros nas linhas FALHA (relato / consola), da base para o
  novo: `B1-nome-verdadeiro` 34/68 → 0/0; `N-B2-canario-minusculas-relato` 34/68 → 0/0;
  `N-B2-canario-minusculas-caixa` 21/42 → 0/0. Esta última passa de **36/43 para 40/43**: as 4 falhas em cascata
  vinham do eco da linha FALHA para o relato e desaparecem. Como defesa extra, o `correr-mutacoes.sh` lê agora a cauda
  do `relato.txt` e troca qualquer nome verdadeiro por «‹nome verdadeiro›» antes de a escrever no registo cometido.
- **B3 — o portão do `_fim()` falha sem canários.** Com `_canarios_nomes` vazio, sai «FALHA fim: a varredura do relato
  inteiro não tem nenhum nome verdadeiro para procurar …». Mutação «o canário não junta nomes»: na base, HUD
  **42/42 rc=0** e manequim **52/52 rc=0** (a verificação nem aparece); com o código novo, **42/43** e **52/53**, rc=1.
- **B4** — a frase do §B5 da secção CORRECOES ficou com os números das 5 capturas (20,2 / 3,2 / 1,4 / 1,0 / 13,7 %);
  já não diz «no essencial, iguais».

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7): teste `correcoes-4/teste-relato.log`
**31/31**; prova HUD-JOGADORA `correcoes-4/cliente-hud/relato.txt` **43/43**, 68 linhas = 68 no ficheiro; prova
MANEQUIM `correcoes-4/cliente-manequim/relato.txt` **53/53**, 78 = 78.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js>
<pasta-tmp> "$PWD/provas/ordem-caixa-relato/correcoes-4"` e, para as mutações,
`bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes.sh <godot.exe> <vlab-completo.js> <pasta-tmp> <base4|novo> <registo.log>`.
# Correcções B1–B5 da sentença da CAIXA-RELATO-B7-CORRECOES-2 (Ordem CAIXA-RELATO-B7-CORRECOES-3 · 22/11/2026, Claude conta 2, PC)

Só o teste do registo; nada do código do jogo muda. As corridas estão em **`b7-correcoes-3/`**; as mutações, em
**`b7-correcoes-3/mutacoes/`** (`mutacoes.log` é o resumo), feitas por `ferramentas/correr-mutacoes-b7-correcoes-3.sh`.

- **B1 (R1) — a retenção por listas PERMITIDAS.** Uma linha só se ecoa se não tiver nenhuma proibida E tiver só chaves
  JSON de `CHAVES_PERMITIDAS` (`ligada`, `ordemPor`, `ordemDinamica`, `ordem`, `fechada`, `ultimo`) e só palavras de
  `PALAVRAS_PERMITIDAS` (as fixas de `linha()`/`_origem()`, os valores da caixa, os tipos de evento, os rótulos),
  números e ids hexadecimais de 17. O que está fora conta-se e não se imprime. Mutação `"alcunha": "Canario-R1"`:
  teste novo **30/31**, valor **0 vezes** no log; teste antigo **31/31**, valor **2 vezes**.
- **B2 — sem acentos.** `_normal` (minúsculas, letras acentuadas → base, marcas combinantes U+0300–U+036F fora) dos
  dois lados. Mutações `"própria"` e `"pro◌́pria"` (acento à parte): teste novo **30/31**, a `PROIBIDAS` acusa
  `propria`, **0 ecos**; teste antigo **31/31**, **2 ecos** cada.
- **B3** — o comentário de "propria" aponta `estado.gd:57`.
- **B4 (registo)** — a B7-2/B7-3 só pelo rótulo, sem âncora inventada. Mutação «o passo 3 sem o evento à espera»
  (duplicação do passo 2): **31/31** nos dois testes — o limite inerente aos dados, escrito no teste.
- **B5 — o total afirmado** (`TOTAL_ESPERADO := 31`). Mutação «sem uma verificação»: teste novo **30 de 30 + FALHA do
  total, código 1**; teste antigo **30 de 30, código 0** (passava calado). São **31**, não 30: a `fable/integracao-50`
  juntou as 30 da B7-CORRECOES-2 à verificação do fuso injectado da CORRECOES-3 (B6); o teste da base dá 31/31.

Números (Godot 4.7.2 Windows, Node 26.13.0, motor VLAB real `a91c021c…`, semente 7): teste `teste-relato.log`
**31/31**; prova HUD-JOGADORA **43/43**; prova MANEQUIM **53/53**; suites `suites/`: servidor **419/419**, prova da
caixa do servidor **PROVA OK**.

---

# Correcções B1–B3 da sentença da CAIXA-RELATO-CORRECOES-4 (Ordem CAIXA-RELATO-CORRECOES-5 · 22/11/2026, Claude conta 2, PC)

Só o harness das mutações, o registo e um conferidor novo; as provas vivas, o teste, o código do jogo, o HUD e as
cores não mudam. As corridas limpas estão em **`correcoes-5/`**; o registo das mutações foi **regenerado no mesmo
sítio**, `correcoes-4/mutacoes.log` (é a mesma experiência, com o mesmo código das provas; o antigo tinha fragmentos).

- **B1 — filtrar antes de cortar.** O `correr-mutacoes.sh` cortava as linhas FALHA com `cut -c1-400` **antes** do
  filtro. No locale C do Git Bash o `cut` conta bytes, e os 400 bytes acabavam a meio de um nome; o filtro procura o
  nome inteiro e deixava passar o pedaço (o registo antigo tinha um fragmento de 14 de 15 caracteres e outro de 7 de
  16, em 4 linhas). Agora a linha passa **inteira** pelo `filtrar` e só depois pelo `cortar 400`, que conta caracteres
  (pontos de código) e não parte um carácter a meio. O filtro e o corte são em node: não dependem do locale, o nome é
  texto literal (sem metacaracteres de sed) e as maiúsculas não contam também fora do ASCII.
- **B2 — o título da mutação também passa pelo filtro.** O `diz` (e a linha «NÃO APLICOU») passa pelo `filtrar` com
  os nomes verdadeiros das fichas cometidas. Os 4 títulos que traziam um nome verdadeiro dizem agora
  «‹nome verdadeiro›». «Espadachim de Bancada» (títulos do `N-B3-heroina-nome-publico-hud`) fica: nas fichas é o nome
  público.
- **Conferidor novo:** `ferramentas/conferir-registo.mjs <registo> [<fichas.json>]` confere linha a linha que não há
  nenhum nome verdadeiro (nome ≠ nomePublico), nem inteiro nem num pedaço de 4 ou mais letras seguidas de uma das suas
  palavras, sem distinguir maiúsculas. Só exclui as ocorrências dentro dos nomes que são públicos por inteiro. Não
  repete o texto achado. No registo antigo dá 18 achados, em 10 linhas: as 8 da sentença e 2 do cabeçalho escrito à mão; no
  regenerado, **0**. Serve para o registo; nos relatos acusaria os nomes públicos curtos, que lá estão por direito.
- **B3** — no `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-4.md` §3.2 (raiz), emendado.

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7): teste `correcoes-5/teste-relato.log`
**31/31**; prova HUD-JOGADORA `correcoes-5/cliente-hud/relato.txt` **43/43**, 68 linhas = 68 no ficheiro; prova
MANEQUIM `correcoes-5/cliente-manequim/relato.txt` **53/53**, 78 = 78. Mutações regeneradas: 18 `base4` + 18 `novo`,
com os mesmos resultados, um a um, do registo da CORRECOES-4.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js>
<pasta-tmp> "$PWD/provas/ordem-caixa-relato/correcoes-5"`; as mutações como na secção anterior; e
`node provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs provas/ordem-caixa-relato/correcoes-4/mutacoes.log`.

---

# Correcções B1–B5 da sentença da CAIXA-RELATO-B7-CORRECOES-3 (Ordem CAIXA-RELATO-B7-CORRECOES-4 · 22/11/2026, Claude conta 1, PC)

Só o teste do registo, os dois scripts das ferramentas (o das mutações, novo, e o lançador das provas) e as corridas
em **`b7-correcoes-4/`**. Nada do código do jogo, do HUD nem das cores.

- **B1 (D1) — a forma dos valores.** As listas permitidas viam as chaves e as palavras, não o valor: «"ultimo":
  "turno"» e «"ultimo": 42» passavam 31/31 e ecoavam. O limite fica escrito ao lado de `CHAVES_PERMITIDAS` e fecha-se
  com `_forma_fora`: cada objecto JSON da linha lê-se e percorre-se. Em cima só pode haver `ligada` (booleano),
  `ordemPor` (só `"dinamico"`) e `ordemDinamica` (um objecto). Dentro dele só pode haver `ordem` (lista de ids de
  17 hex), `fechada` (booleano) e `ultimo` (id de 17 hex). Também conta uma chave no nível errado, um objecto que não
  se lê, e uma chave «"k":» escrita fora de qualquer objecto. O que não tem a forma conta-se («valor(es) fora da forma:
  N»), retém a linha e não se imprime. O total continua **31**.
- **B2 (D2) — o limite dos 17 hex**, escrito ao lado de `RE_ID`: qualquer 17-hex passa por id. A mutação
  `b2-ultimo-17hex` dá 31/31, com eco, nos dois testes.
- **B3 (D3) — o PIN.** O `correr-prova-caixa-relato.sh` deixa de copiar o `servidor-info.json` e o `servidor.log` para a
  pasta de saída: ficam na pasta tmp. `b7-correcoes-4/` não os tem. Os das ordens anteriores ficam como estavam.
- **B4 (D4) — o script de mutações** `ferramentas/correr-mutacoes-b7-correcoes-4.sh`. Usa uma pasta própria por
  corrida (`mktemp -d`), com a cópia mutada e o `relato_caixa.gd` da mesma versão; nada se escreve em `ferramentas/`.
  Cada mutação tem um resultado esperado. O script sai com 0 só se tudo bater; sai com 1 se alguma não bater (a linha
  leva `NAO-BATE`) e com 2–9 se a própria corrida falhar.
- **B5 (D5) — os acentos.** O `_SEM_ACENTO` passa a cobrir o latim-1 e o latim alargado A, incluindo o s longo U+017F.
  As marcas combinantes caem em 5 blocos (U+0300–036F, 1AB0–1AFF, 1DC0–1DFF, 20D0–20FF, FE20–FE2F). Isto não é uma
  normalização Unicode completa, e fica documentado. A rede de segurança é a lista permitida. Um carácter não-ASCII que
  sobre depois de `_normal` (fora o «—» e o «·» das palavras fixas) deixou de servir de separador: antes, «1ȷe» dava
  «1» e «e», as duas permitidas, e ecoava.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes-b7-correcoes-4.sh <godot.exe> <pasta-saída>
[<base> (c847966)] [<base-r1> (a12b905)]`; as provas vivas como acima, com `"$PWD/provas/ordem-caixa-relato/b7-correcoes-4"`.
Os números estão no `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-4.md`, na raiz.

---

# Correcções B1–B4 da sentença da CAIXA-RELATO-CORRECOES-5 (Ordem CAIXA-RELATO-CORRECOES-6 · 22/11/2026, Claude conta 1, PC)

Só as ferramentas desta pasta, as corridas em **`correcoes-6/`** e uma emenda ao ESTADO-FINAL da CORRECOES-5 (raiz).
Nada do código do jogo, do HUD nem das cores. O registo `correcoes-4/mutacoes.log` não muda.

- **B1** — `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-5.md`, linha 55: o marcador aparece em 28 linhas (92 ocorrências).
- **B2** — `conferir-registo.mjs` gera também os pedaços **a cavalo de palavras**: todo o pedaço contíguo do nome
  inteiro com 4 ou mais letras (os espaços entram no pedaço, não contam para as 4). `--velho` corre o critério antigo,
  para comparar. O registo regenerado dá **0** nos dois critérios (151 pedaços no alargado, 26 no antigo). O registo
  antigo dá 18 nos dois. Numa linha sintética com um pedaço a cavalo de palavras, o alargado acha-o e o antigo não.
- **B3** — o `cortar` do `correr-mutacoes.sh` conta **pontos de código**, não grafemas, e passa a cortar **só entre
  grafemas** (`Intl.Segmenter`). Um grafema que não cabe inteiro fica de fora, por isso uma linha pode sair com menos
  de 400 pontos de código, mas nunca com mais. O registo cometido passa por ele sem mudar um byte.
- **B4** — `mutacoes.mjs`: os dois títulos que traziam o nome verdadeiro (inteiro e em minúsculas) dizem agora «o nome
  verdadeiro n.º 1». O n.º é o mesmo do conferidor.

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7): teste `correcoes-6/teste-relato.log` **31/31**;
prova HUD-JOGADORA `correcoes-6/cliente-hud/relato.txt` **43/43**, 68 linhas = 68 no ficheiro; prova MANEQUIM
`correcoes-6/cliente-manequim/relato.txt` **53/53**, 78 = 78.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js>
<pasta-tmp> "$PWD/provas/ordem-caixa-relato/correcoes-6"`; `node provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs
[--velho] provas/ordem-caixa-relato/correcoes-4/mutacoes.log`. Para as mutações, a pasta tmp tem de ser um **caminho
absoluto**: o `--saida` da prova é lido a partir de `rascunhos/cliente`.

---

# Correcções B1–B6 da sentença da CAIXA-RELATO-CORRECOES-6 (Ordem CAIXA-RELATO-CORRECOES-7 · 22/11/2026, Claude conta 1, PC)

Só as ferramentas desta pasta, o registo regenerado, as corridas em **`correcoes-7/`**, este README e emendas aos
ESTADO-FINAL da CORRECOES-4 e da CORRECOES-6 (raiz). Nada do código do jogo, do HUD nem das cores.

- **B1** — o registo `correcoes-4/mutacoes.log` foi **regenerado com a fonte actual** (36 corridas: 18 `base4` + 18
  `novo`, em `66da920`). Os 4 títulos das duas mutações do nome verdadeiro dizem agora «o nome verdadeiro n.º 1»,
  como o `mutacoes.mjs`. Os resumos «N de M» são os mesmos da regeneração anterior. A única outra diferença é na
  parte `novo`: nas mutações do teste, as linhas FALHA da varredura de palavras trazem a cláusula que a linha B7 juntou
  ao `teste_relato_caixa.gd` depois da CORRECOES-4. O conferidor dá **0** nos dois critérios (251 linhas).
- **B2** — os relatos das provas vivas têm **0 nomes verdadeiros inteiros** (varredura do jogo). O conferidor
  estrito dá 48 (HUD), 46 (manequim) e 4 (`teste-relato.log`), todos artefactos: os nomes públicos das fichas, a
  palavra que dá nome ao cenário dos testes, uma palavra corrente. São os mesmos números na CORRECOES-5, na CORRECOES-6 e aqui. O
  ESTADO-FINAL da CORRECOES-6 (§2) foi emendado com esta qualificação.
- **B3** — o exemplo no comentário do `conferir-registo.mjs` usa letras de marcação («x de Y»), não um pedaço real.
- **B4** — tirei os nomes inteiros que ainda estavam neste README (a secção da CORRECOES-2), no §3.2 do ESTADO-FINAL
  da CORRECOES-4 e no comentário do `correr-mutacoes.sh` (o fragmento da CORRECOES-5). Dizem agora o n.º do nome.
- **B5** — o `correr-mutacoes.sh` e o `correr-prova-caixa-relato.sh` **absolutizam a pasta tmp à entrada**. O
  segundo absolutiza também a pasta de saída. Um caminho relativo conta a partir da pasta de onde se chamou o script,
  e o script avisa no stderr. Antes, o Godot (que corre com `--path rascunhos/cliente` e muda para lá a pasta de
  trabalho) escrevia o `--saida` em `rascunhos/cliente/<pasta>/`, e o script lia o relato em `<raiz>/<pasta>/`.
- **B6** — o ESTADO-FINAL da CORRECOES-6, §3 ponto 4, foi emendado: a regra é `rascunhos/cliente/<pasta-tmp>/`;
  `rascunhos/tmp/` era o caso particular de `<pasta-tmp>` = `../tmp`.

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7): teste `correcoes-7/teste-relato.log` **31/31**;
prova HUD-JOGADORA `correcoes-7/cliente-hud/relato.txt` **43/43**, 68 linhas = 68 no ficheiro; prova MANEQUIM
`correcoes-7/cliente-manequim/relato.txt` **53/53**, 78 = 78. Nas duas provas, 0 nomes verdadeiros inteiros
(varredura do jogo); o conferidor estrito dá 48/46/4, todos artefactos.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js>
<pasta-tmp> provas/ordem-caixa-relato/correcoes-7`; `bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes.sh
<godot.exe> <vlab-completo.js> <pasta-tmp> <base4|novo> <registo.log>`; `node
provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs [--velho] provas/ordem-caixa-relato/correcoes-4/mutacoes.log`.

# Correcções B1–B6 da conferência da B7-CORRECOES-4 (Ordem CAIXA-RELATO-B7-CORRECOES-5 · 22/11/2026, Claude conta 1, PC)

As corridas estão em **`b7-correcoes-5/`** (as de cima ficam como estavam).

- **B1 (D1) — o PIN de bancada foi rodado, e só depois se apagaram os ficheiros com o antigo.** O valor novo é
  aleatório, de 20 dígitos (não é uma data). Tem de ser só de dígitos: a sala exige `/^\d{6,}$/` para o PIN do Mestre
  (E-P9, `rascunhos/servidor/nucleo/sala.js`), e o código do servidor não é desta ordem. Está só como literal em
  `rascunhos/servidor/autojogo/cenario-bancada.json` e nos 4 `.gd` das provas (`prova_caixa_jogadora.gd`,
  `prova_caixa_janela.gd`, `prova_caixa_manequim.gd`, `prova_caixa_reentrar.gd`), nunca em logs cometidos. Depois de
  rodar, saíram do ramo os **58** `servidor-info.json` + `servidor.log` (29 + 29) que traziam o antigo, aqui e nas pastas
  `provas/ordem-caixa*/`. As referências antigas a `servidor-info.json` nos README dessas ordens ficam como registo; o
  histórico do git guarda o valor antigo, que já não abre nada.
- **B2 (D2) — os logs das mutações saem sem a pasta temporária.** `ferramentas/correr-mutacoes-b7-correcoes-5.sh` troca a
  pasta (nas três grafias) por `<tmp>` em cada log, e sai com 6 se algum log ainda levar a pasta, a casa ou o nome do
  utilizador.
- **B3 (D3) — o lançador já não imprime o PIN.** O `correr-prova-caixa-relato.sh` imprime o info do servidor sem a chave
  `"pin"` (antes era `cat` do ficheiro).
- **B4 (D4) — argumentos validados no início:** em falta, a mais ou um `<godot>` que não existe → código 2; uma base que o
  git não conhece → 3.
- **B5 (D5) — uma corrida que morre a meio não é «NAO-BATE».** Código do Godot ≠ 0 e ≠ 1, log vazio ou sem a linha «N de M
  verificações passaram» → a linha diz `FALHA-DA-CORRIDA (motivo)` e o script sai com 4. Com um Godot cujo log se corta
  e que sai com 1, o script antigo chegava a dar **13 BATE falsos**; o novo dá 34 `FALHA-DA-CORRIDA`
  (`b7-correcoes-5/antes/b5-*.log`). A correcção do separador não-ASCII da B7-CORRECOES-4 conta como parte da B5.
- **B6 (D6 + D7)** — corrigidos no `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-4.md`: 8 → 2 ecos (com a nota da
  primeira corrida) e 36 → 38 ficheiros com o caminho da casa do PC.

Correr de novo: `bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes-b7-correcoes-5.sh <godot.exe> <pasta-saída>
[<base> (c847966)] [<base-r1> (a12b905)]`; as provas vivas como acima, com `"$PWD/provas/ordem-caixa-relato/b7-correcoes-5"`.
Os números estão no `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-5.md`, na raiz.

---

# Correcções B1–B5 da sentença da B7-CORRECOES-5 (Ordem CAIXA-RELATO-B7-CORRECOES-6 · 22/11/2026, Claude conta 1, PC)

As corridas estão em **`b7-correcoes-6/`**. A rotação da -5 não fechava o D1: o PIN novo ficava em claro em 5 ficheiros
seguidos. Agora **não há PIN nenhum no repositório**.

- **B1 (D1)** — o `pin` saiu do `cenario-bancada.json` e os 4 `.gd` das provas ficaram sem literal (`var _pin := ""`).
  Cada lançador gera um **PIN fresco por corrida** (20 dígitos de `crypto.randomInt`) e passa-o por `--pin=` ao servidor
  e à prova. Os dois `servidor-bancada-prova.mjs` exigem `--pin=` e saem com 2 sem ele, antes de lerem o cenário. As 4
  provas `.gd` também saem com 2. O autojogo (`servidor-autojogo.mjs` + `autojogo.gd`) lia o PIN do mesmo cenário:
  agora o `autojogo.gd` gera-o por partida (`Crypto`) e passa-o por `--pin=`.
- **B2 (D2)** — os 3 lançadores externos (HUD-JOGADORA, JANELA, MANEQUIM) e o `correr-prova-caixa.sh` deixaram de fazer
  `cat` do info: imprimem-no sem a chave `"pin"`. Os 3 externos deixaram de copiar o info/log do servidor para a pasta
  cometida. O servidor já não põe o `pin` no info nem na linha `pronto-…`. Saíram do ramo os 2 ficheiros que a
  CAIXA-JANELA-COBERTURA-CORRECOES-5 tinha voltado a cometer com o PIN antigo (`cobertura-correcoes-5/cliente/`).
- **B3/B4** — emendados o `b7-correcoes-5/verificacao-pin.log` e o `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-5.md`
  (o PIN antigo sem o valor; a frase da ordem das validações).
- **B5** — o histórico fica como está. O PIN antigo está morto. O PIN novo de 20 dígitos é público e nunca se reutiliza.

Verificar: `bash provas/ordem-caixa-relato/ferramentas/verificar-pin-b7-correcoes-6.sh [<godot.exe>]`. Só imprime
contagens: tira os dois valores dos objectos do git e nunca os escreve. O registo está em
`b7-correcoes-6/verificacao-pin.log`. As provas vivas correm como acima, com `"$PWD/provas/ordem-caixa-relato/b7-correcoes-6"`.
Os números estão no `ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-6.md`, na raiz.

# Correcções B1–B5 da sentença da CAIXA-RELATO-CORRECOES-7 (Ordem CAIXA-RELATO-CORRECOES-8 · 22/11/2026, Claude conta 1, PC)

Só as ferramentas desta pasta, as corridas em **`correcoes-8/`**, este README e emendas de texto a ESTADO-FINAL antigos
(raiz: CORRECOES-2, -3, -4 e -7). Nada do código do jogo, do HUD nem das cores.

- **B1** — o ESTADO-FINAL da CORRECOES-7 (§1 B1) dizia «os 36 resumos». O registo tem 36 blocos, 36 `rc=` e **38**
  linhas-resumo. Ficou emendado com uma nota (¹).
- **B2** — no §3.2 do ESTADO-FINAL da CORRECOES-4, as linhas 105 e 109 já não têm os pedaços de 12 caracteres. Dizem
  «o nome verdadeiro n.º 1 e um nome público», como a linha 106.
- **B3** — os dois scripts usam agora a mesma função, **`ferramentas/absolutizar.sh`**, para os caminhos da linha de
  comandos. Os casos de canto passam a ser tratados assim:
  - `~` e `~/…` → `$HOME/…`;
  - `\pasta\…` → a raiz da unidade da pasta de onde se chamou o script;
  - `\servidor\…` e `//…` (rede), `C:pasta` (relativo à pasta corrente de uma unidade) e `~utilizador` →
    **falham** com mensagem e rc=2, antes de se escrever o que quer que seja;
  - o resto, como antes.

  Antes, `C:pasta` e `//…` passavam por absolutos. `~/…`, `\\servidor\…` e `\pasta\…` iam parar debaixo da pasta de
  onde se chamou o script: havia o aviso de «relativa», mas o sítio estava errado. Com `C:pasta`, o script antigo
  criou uma pasta `Cpasta` (o MSYS troca o `:`). O Godot falhou ao criar `rascunhos/cliente/C:pasta`, a prova deu
  0 de 2, e o script saiu com 0. O registo, dado como `tmp/…`, não ficou escrito: contava a partir da raiz do clone,
  onde não há `tmp/` (é a B4). Foi medido; ver o ESTADO-FINAL da CORRECOES-8.
- **B4** — o `<registo.log>` do `correr-mutacoes.sh` também passa pela `absolutizar`. Antes contava a partir da raiz do
  clone.

**Decisão de âmbito (sentença da CORRECOES-7).** O critério estrito (`conferir-registo.mjs`, critério alargado)
aplica-se **ao registo** (`correcoes-4/mutacoes.log`) **e à fonte** (ferramentas, README, ESTADO-FINAL). **Não se
aplica** à saída do jogo (os `relato.txt` e os `teste-relato.log` das corridas), nem ao diff que a inclui. Na saída, os
achados do conferidor são artefactos: os nomes públicos, a palavra do cenário, palavras correntes. Foram medidos e
classificados um a um, e **0 são nomes verdadeiros inteiros** (ESTADO-FINAL-6 §2; secção CORRECOES-7 acima). Quem
contar os achados num diff que traga relatos novos vai achar dezenas, e não são fugas.

Números (Godot 4.7.2 Windows, motor VLAB real `a91c021c…`, semente 7): teste `correcoes-8/teste-relato.log` **31/31**;
prova HUD-JOGADORA `correcoes-8/cliente-hud/relato.txt` **43/43**, 68 linhas; prova MANEQUIM
`correcoes-8/cliente-manequim/relato.txt` **53/53**, 78 linhas. Os relatos são iguais aos da CORRECOES-7, tirando as
horas. Registo `correcoes-4/mutacoes.log`: conferidor **0/0** (critério alargado e `--velho`).

# Redacção da saída nova do canário (Ordem F51 da sentença da F25 · 23/11/2026, Claude conta 1, PC)

**Para que serve.** Desde a F25, os 11 registos limpos (os `teste-nomes-relato.log` da CAIXA-JANELA e os dois
`mutacoes.log`) já não são a saída crua do Godot: os nomes verdadeiros passaram a «nome n.º 1» / «nome n.º 2». A
saída crua do canário (`provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd`) continua a trazê-los por
desenho. Para comparar uma corrida nova com um registo limpo, byte a byte, aplica-se primeiro à saída nova a mesma
redacção do §2 da F25 (o ponto 5 do §7 do ESTADO-FINAL da F25).

**A ferramenta:** `ferramentas/redigir-nomes.mjs`. Lê os nomes das fichas em todas as corridas, por isso não há nenhum nome
no código. A numeração é a da O1 e do `conferir-registo.mjs`, ou seja a ordem dos nomes verdadeiros nas fichas. Redige
as quatro formas do §2:
- o nome inteiro, sem distinguir maiúsculas, passa a `nome n.º N`;
- a forma toda em minúsculas passa a `nome n.º N em minúsculas`;
- o canário mudado (a preposição do meio mudada) passa a `nome n.º N com a preposição mudada`;
- o nome cortado na origem passa a `nome n.º N (cortado na origem)`. Conta como corte a linha que acaba num pedaço
  inicial do nome maior do que o nome público. O nome público sozinho não se redige;
- **desde a F97** (F71+F87+F89), uma 5.ª forma: o nome sem a preposição, na forma exacta de um só espaço
  «1.ª parte + última parte», com fronteira de palavra dos dois lados, passa a `nome n.º N sem a preposição` (com
  contador próprio na linha de contagens). Uma forma por preposição no meio do nome. Não há nenhuma no
  corpus: 0 no relato antigo, cru e redigido, e 0 no registo limpo, por isso nenhuma comparação byte a byte muda.

Nenhuma linha é acrescentada nem tirada e os fins de linha ficam como estavam. A ferramenta sai com 3 se sobrar um nome
inteiro. **Desde a F66** (sentença da F51), a saída 3 cobre também o que a redacção do §2 não redige, sem mudar a
redacção. Procura-se só no texto já redigido e diz só contagens e n.ºs de linha:
- **a variante de preposição fora da lista de 5:** o nome com a palavra da preposição substituída por outra palavra
  qualquer, ou com mais de um espaço à volta dela;
- **o corte a meio da linha:** um pedaço inicial do nome com a medida do corte na origem (maior do que o nome público,
  sem acabar em espaço, a começar numa fronteira de palavra) a que se segue um carácter que não é letra. No fim da
  linha o corte redige-se, como no §2; a meio só se aponta.

**Desde a F94** (sentença da F66+F68), a rede fecha mais três buracos, também sem mudar a redacção:
- **J9:** a variante com pontuação logo a seguir à palavra substituída («X du, Y», «X d. Y», «X du;Y») conta como
  variante. **Desde a F109** (sentença da F88–F96), também com a pontuação logo **antes** da palavra do meio
  («X, du Y», «X,du Y», «X; du Y»): a pontuação vem colada ao que está antes, e a seguir pode vir no máximo uma
  quebra de linha, como depois. Com espaço antes da pontuação («X , du Y» e o gémeo «X du , Y») continua 0 — «AINDA ABERTO» (alargar os dois lados é outra ordem);
- **J10:** a variante (ou o próprio nome) partida por quebra de linha, quando o pedaço que fica no fim da linha é
  demasiado curto para se redigir como corte na origem: a variante procura-se no texto todo, e o espaço à volta da
  palavra do meio pode ser uma quebra de linha (LF ou CRLF). Conta como variante, na linha onde começa.
  **Travado desde a F114** (opção 1 da F108): qualquer separador à volta da palavra do meio casa no máximo uma quebra de
  linha. A quebra de linha pode estar antes ou depois da palavra do meio, ou nos dois lados (o nome partido por 3
  linhas continua a contar), **nunca uma linha em branco** (nem uma linha só de espaços): partido por uma linha em
  branco, deixa de contar. Desde a F132, **o tabulador conta como espaço em branco** (não é quebra de linha): uma
  linha só com um tabulador é uma linha só de espaços;
- **J8:** o corte colado a uma letra (o pedaço do nome seguido logo de outra letra) conta como corte quando o pedaço
  tem pelo menos 2 palavras inteiras do nome e acaba a meio de uma palavra do nome. Com menos, o nome público seguido
  de uma palavra que começa pela letra da preposição dispararia a rede.

**Desde a F97** (F71+F87+F89):
- **F87 — o nome sem a preposição:** o padrão «1.ª parte, um ou mais espaços, última parte», com fronteira de palavra,
  conta como resto e dá saída 3. Apanha o que a 5.ª forma exacta não redige: dois espaços, um tabulador, a quebra de
  linha (conta na linha onde começa). A forma de um espaço não se exclui aqui, para que um falhanço da redacção saia
  ainda com 3. A linha de contagens diz «N nome(s) sem a preposição».
- **F89 — a palavra hifenizada:** a palavra substituta da variante fora da lista é **«uma palavra de letras, com ou sem hífenes»**
  («X du-la Y» conta como variante). **Mais de uma palavra** no lugar da preposição («X du la Y») continua
  fora: duas ou três palavras já não são «a preposição substituída», são palavras inseridas. **Os dígitos** também
  continuam fora: um número não é uma palavra, e não há caso realista de preposição escrita como dígito.
- **Fronteira com a F94 (registada, não fechada aqui):** a substituta colada ao apelido (falta o espaço) e a
  substituta seguida de pontuação continuam com a F94.

**F93:** uma ocorrência conta uma vez só. O nome inteiro tal e qual é só da contagem dos inteiros, e as 5 variantes
da lista com um espaço só não contam como variante fora da lista, porque a redacção já as trocou. Um corte que começa
dentro de uma variante não conta como corte. Por isso a função `suspeitos()` só se deve chamar sobre o texto já
redigido, como a ferramenta faz.

Não há nenhum caso destes no corpus: os 11 registos e a saída do canário dão 0 variantes, 0 cortes e 0 nomes sem a
preposição. O auto-teste cobre-os com casos montados.

**Limite (F97).** A redacção apanha o nome sem a preposição (5.ª forma) e a rede aponta-o. A rede não apanha um pedaço que não comece no início do nome — só o apelido sozinho fica de fora: a última palavra é palavra corrente — 75 ocorrências no relato antigo, 47 ainda no relato antigo redigido, 6 no registo limpo (a contar sem distinguir maiúsculas) — e apanhá-la marcaria o registo limpo como sujo.

**Limite (F114, J10).** A variante partida por quebra de linha só conta se a quebra de linha estiver antes ou depois da palavra do meio, ou nos dois lados, **nunca uma linha em branco**. Desde a F116 (sentença da F108), **uma linha só com espaços conta como linha em branco**, antes da palavra do meio ou antes do apelido. A variante partida por uma linha em branco não dá suspeito: a variante não atravessa a linha em branco. Antes da palavra do meio, o pedaço no fim da linha de cima é demasiado curto para corte; antes do apelido, com a preposição verdadeira, o pedaço é redigido como corte na origem; com a variante «du», nada se redige. O auto-teste afirma-o (0 variantes), e desde a F116 também para a linha só de espaços (0 variantes nas duas posições).

O auto-teste marca o que fica aberto como «AINDA ABERTO» (F95): o pedaço que começa a meio do nome («de Y» ou só «Y»)
e, desde a F97, duas palavras no lugar da preposição (F89). Os casos passam enquanto o buraco está aberto; quem o
fechar tem de virar o caso para afirmar a saída 3, e é essa a prova do fecho. O caso do nome sem a preposição já virou
(F97): afirma agora a rede.

Usos (na raiz do repo):
- `node provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs <saída-crua.log> --saida=<redigido.log>` escreve a
  saída redigida.
- `node provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs <saída-crua.log> --comparar=<registo.log> [--ignorar-cr]`
  compara o redigido com o registo, byte a byte. Diz só «igual» ou o n.º da 1.ª linha diferente, nunca o texto. Sai
  com 0 se for igual e 1 se não for. `--ignorar-cr` tira os CR dos dois lados: o Godot do CI, em Linux, escreve LF, e
  os registos cometidos são CRLF (escritos no Windows). No PC compara-se sem `--ignorar-cr`.
- `node provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs --auto-teste` corre 31 verificações com casos montados
  em memória a partir das fichas:
  - as quatro formas, o nome público intacto, os fins de linha e a idempotência;
  - desde a F66/F68: a variante do nome n.º 1 fora da lista, o corte mínimo do nome n.º 2 a meio da linha, a rede
    calada no que está limpo e a guarda dos 2 nomes;
  - desde a F93–F95: J8, J9, J10, a contagem única e o pedaço a meio do nome «AINDA ABERTO»;
  - desde a F97: o nome n.º 1 sem a preposição com dois espaços, um tabulador ou partido por quebra de linha (e a
    forma de um espaço crua) → a rede sai com 3 (é o caso da F95 que virou); a 5.ª forma no nome n.º 1 a meio da
    linha e no nome n.º 2 no fim da linha; a variante hifenizada → saída 3; e duas palavras no lugar da preposição
    «AINDA ABERTO»;
  - desde a F114 (J10 travado): o nome n.º 1 partido por 3 linhas → a rede sai com 3; partido por uma linha em branco
    → 0 variantes (não conta);
  - desde a F116: o nome n.º 1 partido por uma linha só de espaços (antes da palavra do meio, ou a variante «du»
    antes do apelido) → 0 variantes nas duas posições (conta como linha em branco);
  - desde a F109 (J9-antes): a variante do nome n.º 1 com pontuação antes da palavra do meio («X, du Y») → 1
    variante, a rede sai com 3.

  Com 1 nome verdadeiro, falha com 1; com 0, sai com 2 antes do auto-teste (F90).

  **As verificações dependem das fichas (F96):**
  - a 13.ª (a variante «du»), as de J9, J10 e F93 e as dos buracos ainda abertos precisam de o nome n.º 1 ter uma
    preposição da lista no meio;
  - a 5.ª precisa do mesmo no nome n.º 2, e a 15.ª nos dois nomes;
  - a 14.ª precisa de o nome n.º 2 ser maior do que o mínimo do corte;
  - a de J8 precisa de o nome n.º 2 ter 3 palavras ou mais;
  - (F97) a do nome sem a preposição na rede, a da 5.ª forma no nome n.º 1 e as duas da F89 precisam de o nome n.º 1
    ter uma preposição da lista no meio; a da 5.ª forma no nome n.º 2 precisa do mesmo no nome n.º 2;
  - (F114) as duas do J10 travado (3 linhas e linha em branco), (F116) a da linha só de espaços e (F109) a do
    J9-antes precisam de o nome n.º 1 ter uma preposição da lista no meio.

  Se as fichas mudarem e uma destas condições deixar de valer, o caso falha. Falhar alto é o certo, e a dependência
  fica escrita aqui e no código.
- `--fichas=<fichas.json>` muda as fichas (por omissão `rascunhos/servidor/autojogo/fichas-bancada.json`).

**No CI:** o passo está no job `cliente` desde `74f5fa9` (F65), logo a seguir ao passo do canário. Corre o auto-teste
e compara a saída do canário com `provas/ordem-caixa-janela/cobertura-correcoes-6/teste-nomes-relato.log`. Se a
ferramenta sair com 3, o passo fica vermelho.

**A guarda do log cru (F97, F71).** O passo do canário corre o Godot com `tee`: o que ele imprime vai para o ficheiro
**e** para o log público do run. Por isso as descrições do `teste_nomes_relato.gd` deixaram de trazer nomes (dizem
«nome n.º 1» / «nome n.º 2»; as comparações, que usam os valores literais, não mudaram), e entre o passo do canário e o
da redacção entra o passo «Guarda: 0 nomes inteiros no log cru do canário (F71)», `if: always()` — está no remendo
`provas/ordem-f97-rede-redaccao/remendo-ci-testes.yml.patch` (o token do PC não tem o âmbito `workflow`; o coordenador
aplica-o, como na F51/F65). Conta os nomes inteiros
no log cru com o `sobram` desta ferramenta (que lê os nomes das fichas e só imprime a contagem) e falha se for > 0. Só
lê o ficheiro: não redige o fluxo nem toca na comparação. O registo limpo da COBERTURA-CORRECOES-6 foi regenerado na
F97 (a linha do caso 1 diz agora o tamanho do array): 3473 bytes, 3437 sem os CR.

**A prova de que reproduz o §2:** `provas/ordem-f51-mutacao/reproduzir-redaccao-f25.sh <pasta-tmp>` tira do histórico
os 11 registos de antes da limpeza (o pai de `081304e`) e redige-os. Os 11 ficam iguais byte a byte aos limpos da ponta
(`provas/ordem-f51-mutacao/reproducao-f25.log`). As contagens batem com a tabela do §2 da F25: 69 linhas, 188
ocorrências (5 em minúsculas), 5 cortes na origem e 1 canário mudado.
