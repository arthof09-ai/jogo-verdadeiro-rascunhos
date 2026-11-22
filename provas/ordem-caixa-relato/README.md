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
  (21:02) ficaram fora: são da base `7c97b48` e, no essencial, iguais a estas (1,0 % de diferença no §4 da HUD).
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
  relatos cometidos traziam «Bruto de Bancada» e «Lobo de Bancada», os valores-canário. Agora lêem o `nomePublico`
  («Bruto», «Lobo»), ou o id quando não há nome público. Além disso, o canário estende-se ao relato: em cada passagem
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
