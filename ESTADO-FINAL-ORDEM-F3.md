# ESTADO-FINAL — ORDEM-F3 (a corrida de tempo na leitura do «antes»: o desvio de 0,0004 m)

**Estado: FEITA.** A correcção já estava na linha. Medi-a e provei-a outra vez sobre a ponta de hoje.

- **Executor:** Claude (opus), PC (conta 2). **Data:** 24/11/2026, das ~03:55 às ~04:50 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo, sem ramo. A `main` não foi tocada.
- **Ponta de partida:** `3d8c187` (`3d8c187d8868da63e3d1ddc214f6c6a766dcf6ef`), medida por `git fetch` + `git ls-remote`.
- **Rota: (a).** A bancada espera que os nós fiquem quietos antes de ler. O comparador e o jogo não mudam.

## Leia primeiro

1. **A correcção pedida já existia.** Foi feita por uma corrida anterior desta ordem, de 21/11, no commit
   `73975d6` («o «antes» da bancada só se lê com os nós quietos»), e foi fundida na linha em `d6348d5` (21/11).
   - Faltavam na linha este ESTADO-FINAL e o README das provas. O relatório de então ficou só no clone desse dia.
   - Esta corrida **não muda nenhuma ferramenta da bancada**. Volta a medir a causa e a provar a correcção sobre a
     ponta `3d8c187`, porque a arena e a bancada mudaram muito desde 21/11 (o lago maior, a F1, a F2 e a D-AUD-16).
2. **A causa está medida e é a que a F2 escreveu.** A arena leva a figura ao pé da casa com um **tween linear de
   0,25 s** (`arena.gd:715-717`, sem mudança). O «assente» aceita o nó a ≤ 1e-3 m do pé, por isso um frame que caia no
   último ~0,1-0,25 ms do tween grava o «antes» ainda a deslizar.
3. **No CI, depois do conserto, o defeito nunca mais apareceu.** Houve **322 runs** do «Testes dos rascunhos» desde a
   fusão (21/11 11:54 UTC → hoje). Só 2 tiveram o `provas-mapa` vermelho, e foi por outra causa (§4). Nenhum run
   precisou de 2.ª tentativa.
4. **5 corridas seguidas no PC: 5/5 `REPETE-SE` 461/461 e 73/73.** Numa delas (r2, no guião do CI), o «assente»
   apanhou um resto natural de 0,00059 m no passo de 1 m. É precisamente o caso que alimenta o campo
   `2 m: figuras` e que deixou o CI vermelho. O desvio saiu `(0, 0)`.

## 1. Onde se lê o «antes» e porque se mexia

Tudo em `provas/ordem-mapa-jogavel/provas-bancada/ferramentas/bancada_jogadora_mapa.gd`, na ponta:

- **l. 280–283, o `assente`:** é verdadeiro quando `est.casa_de(heroína) == alvo` e
  `no.position.distance_to(pe_figura(alvo)) <= 1e-3`.
- **l. 293–295:** grava-se `antes[id] = (no.position.x, no.position.z)`. Na fase seguinte, `desvioXZ = noXZ − antes`
  entra no campo `bancada <casaM> m: figuras` do comparador, que o compara **à letra**. O mesmo valor entra também no
  hash de bits `jogadora: nós desenhados`, porque leva `antesXZ`.
- **Antes de 21/11 (`b481122`),** a l. 295 vinha logo a seguir ao `assente`, sem nenhum frame de espera.
  - Num passo de 1 m, o nó anda a 4 m/s, por isso 1e-3 m equivale a 0,25 ms antes do fim do tween.
  - Num passo de 1,5 m, anda a 6 m/s, e 1e-3 m equivale a 0,17 ms.
- **Desde `73975d6`, l. 85–118 e 284–290:** `_esperar_quietos` lê a posição de cada nó, frame a frame, até ela ser
  **exactamente igual em 3 leituras seguidas** (`QUIETO_FRAMES := 3`). Cada frame faz avançar o tween, por isso um nó
  que ainda desliza muda sempre.
  - A espera também se aplica depois da «pronta» (l. 180).
  - O resto apanhado e os frames que foi preciso esperar ficam no registo `quietos` do JSON, que o comparador não lê.
  - Se os nós não sossegam em 10 s, a bancada regista uma FALHA.

## 2. A medição na ponta `3d8c187` (`provas/ordem-f3/ponta-3d8c187/medicao/`)

**Como se mede (`ferramentas/medir-ponta.sh`):**
- O modo `sem` é a bancada da linha com `QUIETO_FRAMES := 1`, gerada por `sed`. Com uma só leitura, a espera sai na
  1.ª volta, por isso o «antes» é a posição do frame do «assente». É o comportamento de antes do conserto, e o
  registo `quietos` traz o resto.
- O modo `padrao` é a bancada tal como está na linha.

| ensaio | corridas | «assente» com o nó a deslizar | «antes» com resto (desvio ≠ exacto) |
|---|---|---|---|
| **forçado `--fixed-fps 2001`, `sem`** | 2 | 2 de 2. Passo de 1,5 m: resto z −0,000750 m. Passo de 1 m: −0,000500 m | **2 de 2**: `1 m` desvio (−0.25, **0.2507495880126953**) e `2 m` desvio (0, **0.000499725341796875**). 49/49 verificações passam: as verificações têm folga de meia casa e não o vêem, só o comparador |
| **forçado `--fixed-fps 2001`, `padrao`** | 2 | 2 de 2, os mesmos restos. A espera demorou 3 frames | **0 de 2**: `1 m` (−0.25, 0.25) e `2 m` (0, 0), exactos |
| natural, `sem` | 30 | 1, no passo de 2 m (resto z 0,00088 m) | 0. O «antes» do passo de 2 m já não se compara, porque não há fase depois |
| natural, `padrao` | 30 | 4: 1,5 m (−0,000565), 2 m (0,000534), 1 m (−0,000792) e 2 m (0,000542) | **0 de 30** |
| as 5 seguidas (§3), bancada padrão + guião do CI | 10 | 2: r1 bancada, passo de 2 m; r2 guião do CI, passo de 1 m (−0,000589) | **0 de 10** |

**O que os números dizem:**
- **A janela é real.** No PC, o «assente» apanhou o nó a deslizar em **7 de 210 passos** (3,3 %). Desses passos, 3
  eram de 1,5 m ou de 1 m, que são os que alimentam um «antes» comparado. Sem a correcção, cada um desses 3 dava
  `NÃO SE REPETE` (460/461 nos números e 72/73 nos bits).
  - Em 21/11 tinha sido 1 em 30 corridas no PC. No CI (Linux), os frames são mais curtos e tinha sido 2 em 4.
- **A correcção apaga o resto inteiro.** O desvio sai exacto em todos os casos, forçados e naturais, em que o resto
  foi apanhado: as 2 forçadas, as 4 naturais e as 2 das cinco seguidas.
- **Porque 2001 fps e não 3001, como em 21/11.** Com 3001 fps, o passo de 1,5 m esgotava os 10 s de relógio da espera
  do «assente»: são 750 frames, e a arena da ponta desenha cada frame mais devagar. Com 2001 fps, o tween dura 500,25
  frames, o frame 500 cai 0,125 ms antes do fim, e as 49 verificações passam. O registo da tentativa a 3001 fps não
  entrou nas provas: a 1.ª verificação falhou por tempo, e com isso o «antes» de 1,5 m ficou lido a meio do caminho.

## 3. As 5 corridas seguidas (`provas/ordem-f3/ponta-3d8c187/cinco-seguidas/`)

O guião é `ferramentas/cinco-seguidas-ponta.sh`. Cada corrida faz três coisas:
- a bancada padrão, `correr-bancada.sh 8821 <pasta>`;
- o guião do CI, `correr-provas-mapa.sh <pasta> 8822`;
- o comparador, à letra como no passo «Repetição» do CI (`primeira=provas/ordem-mapa-jogavel/provas-bancada`).

Correu das 04:19:07 às 04:35:47. O Godot é o 4.7.2.stable.official.ed1daf0bf (win64) e o Node o v26.13.0.

| corrida | bancada padrão | guião do CI | comparador | resto apanhado no `quietos` |
|---|---|---|---|---|
| r1 | saída 0 · 49/49 · sonda do fio TUDO PASSOU | saída 0 (terreno 0/0, Mestre 0, jogadora 0, fio 0, erros 0) · 49/49 | **REPETE-SE 461/461, 73/73** | bancada: 2 m, (0, −0,000110, 0,000534), 3 frames |
| r2 | idem | idem | **REPETE-SE 461/461, 73/73** | **guião do CI: 1 m, (0, 0,0000396, −0,000589), 3 frames → `2 m` desvio (0, 0)** |
| r3 | idem | idem | **REPETE-SE 461/461, 73/73** | nenhum |
| r4 | idem | idem | **REPETE-SE 461/461, 73/73** | nenhum |
| r5 | idem | idem | **REPETE-SE 461/461, 73/73** | nenhum |

O registo termina em `== fim 04:35:47 — 5/5 corridas com bancada 0, guião do CI 0 e REPETE-SE 461/461 e 73/73`.

## 4. O CI desde a correcção (medido com `gh run list` / `gh run view`)

- Desde a fusão `d6348d5` (21/11, 11:54 UTC) até à ponta `3d8c187`, houve **322 runs** do «Testes dos rascunhos», em
  todos os ramos: **311 verdes e 11 vermelhos, todos à 1.ª tentativa** (nenhum `attempt > 1`).
- Dos 11 vermelhos, 9 foram só em outros jobs: 7 com `retoma-pc`, 2 com `cliente` e 1 com `servidor` + `protocolo` (um
  run pode ter mais de um).
- Só **2** tiveram o `provas-mapa` vermelho: 44901330020 (`d6348d5`) e 44901395254 (`3a98be4`), os dois de
  21/11 ~11:55 UTC.
  - Deram 284/461, por causa do **terreno pós-LAGO**: `bloq. srv`, os marcos e a marca `água` das figuras. A referência
    só foi regenerada depois, no `3c0c43a`.
  - **Nos dois, os desvios saíram exactos**: `1 m` (−0.25, 0.25) e `2 m` (0, 0). O hash `jogadora: nós desenhados` foi
    igual (`9efe237b91d09495`).
- **Conclusão:** não houve nenhum desvio de «antes» no CI desde a correcção.

## 5. Porque a rota (a) e não a (b)

1. **A (b) não chegava.** O mesmo resto entra também no campo de bits `jogadora: nós desenhados`, que é o hash de
   `noXZ` e `antesXZ`. Nas duas falhas do CI de 21/11 esse campo deu 72/73. Uma tolerância só no campo dos números
   deixava os bits a falhar, e a aceitação pede 73/73.
2. **A (a) remove a causa.** O «antes» passa a ser a posição final exacta do tween, que é o valor que a primeira
   corrida gravou. Com a (b), o número continuaria a variar e o comparador só passaria a fechar os olhos.
3. **A (a) não toca no comparador.** A série K continua a morder sem mudar uma linha:
   `controlo-comparador.mjs` dá **«TODOS OS CONTROLOS DÃO O ESPERADO (9 controlos)»** na ponta, saída 0
   (`medicao/controlo-comparador.log`). A aceitação só exige este controlo para a rota (b); corri-o à mesma.

## 6. Perímetro

`git diff --stat 3d8c187 HEAD -- rascunhos .github provas/ordem-mapa-jogavel provas/ordem-provas-mapa-corr9` está
**vazio**. O jogo, a bancada, o comparador e o CI não mudam nesta corrida.

Entra só isto:
- este ficheiro;
- `provas/ordem-f3/README.md`;
- três ferramentas de medição novas em `provas/ordem-f3/ferramentas/`: `medir-ponta.sh`, `resumir-jogadora.mjs` e
  `cinco-seguidas-ponta.sh`;
- as provas em `provas/ordem-f3/ponta-3d8c187/`.

Nada em `rascunhos/` muda. Mesmo assim, corri `python3 retoma-i0004/actualizar-listas.py` depois do commit: ver §7.

Só se usaram as fichas fictícias de bancada.

## 7. Commits e CI

- `7bca758`: as provas, as ferramentas de medição, o README e este ESTADO-FINAL.
- Listas da retoma: corri `actualizar-listas.py` (Python 3.12; este PC não tem `python3` no PATH) depois do
  `7bca758`. Deu «antes.txt: 38 · depois.txt: 434 · MANIFESTO: 477 ficheiros (0 novos, 0 tirados)» e a árvore ficou
  limpa, por isso não há commit de listas. Nada em `rascunhos/` mudou.
- O commit da nota do CI, a seguir a este.

### Nota do CI (no `3a3497e`)

- **«Testes dos rascunhos», run 45349563092: verde, os 10 jobs**, à 1.ª tentativa: godot-cliente, cliente,
  provas-mapa, foto-mestre, retoma-pc, motor-real, protocolo, validador-glb, servidor e ponta-a-ponta.
  - No `provas-mapa`: `terreno-original=0 terreno-adaptada=0 Mestre/espectador=0 jogadora=0 sonda-do-fio=0
    erros-de-script=0`, e **`REPETE-SE — números 461/461, bits 73/73`**.
  - `1 m: figuras` deu desvio (−0.25, 0.25) e `2 m: figuras` deu desvio (0, 0).
- **«Sonda de privacidade», run 45349563091: verde.**
