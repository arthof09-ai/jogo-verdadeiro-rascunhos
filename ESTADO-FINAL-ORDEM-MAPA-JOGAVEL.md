# ESTADO FINAL — ORDEM MAPA-JOGÁVEL (Claude conta 2, PC · 20/11/2026)

Ordem: **«Eu quero que todo o mapa seja jogável»** (palavra do Mestre, 20/11/2026) — sem zonas decorativas nem fora
de jogo, **água incluída**. Base: `fable/integracao-50` @ `cb3a99a` (com a ESCALA). Ramo: `claude2/mapa-jogavel`.
Marcas: VERIFICADO (conferido nesta sessão), PROPOSTO (escolha minha, por confirmar), PENDENTE (com a razão),
[FALTA] (sem fonte). Regime: EM_USO (o PC estava a ser usado para jogar) — código e testes leves; Godot só
`--headless` (CPU); **nenhuma captura** (GPU).

## 0. A decisão escala × malha (o ponto crítico) — VERIFICADO

**O que já existia.** O mapa é uma malha de **50 × 50 casas de 1,5 m = 75 m** (de −37,5 a +37,5 m nos dois eixos;
`grelha_floresta.CASA_M`, `relevo_floresta.CASA_M`). O pacote do servidor (`terreno-floresta.json`, formato
`terreno/2`, Ordem 48) **já é o mapa inteiro**: tabela de origens por escala até à maior grelha que cabe
(`ladoMax` = **75 / 50 / 37**), redes de alturas e pés por escala, e o bloqueio/cobertura das 50 × 50 casas da malha.
A regra de assento é a de sempre: **cada casa da batalha leva o terreno da casa da malha que contém o seu centro**
(`colunaMapa`/`linhaMapa` no servidor = `Assentamento.casa_do_mapa` no cliente); a altura e o pé vêm das redes,
bit a bit iguais aos do cliente.

**A decisão.** A grelha da batalha é **o maior quadrado de casas que cabe no mapa na escala viva**:

| escala | grelha | origem (canto NO) | cobre | fica de fora | casa da batalha × casa da malha |
|---|---|---|---|---|---|
| 1 m   | **75 × 75** | −37,5 m | −37,5 … +37,5 (o mapa todo) | nada | 2 casas de 1 m em cada 3 de 1,5 m num eixo; cada casa leva a casa da malha debaixo do centro |
| 1,5 m | **50 × 50** | −37,5 m | o mapa todo | nada | **a mesma casa** (1 : 1) |
| 2 m   | **37 × 37** | −37 m   | −37 … +37 (74 m) | **faixa de 0,5 m em cada borda** (menos do que uma casa: não cabe nenhuma) | 4 casas de 2 m em cada 3 de 1,5 m; a casa da malha debaixo do centro |

- A 1 m e a 2 m a casa da batalha **não coincide** com a casa do relevo: a regra «a casa da malha debaixo do centro»
  decide o bloqueio, a cobertura e o motivo (é a regra que o pacote e as arenas já usam desde a Ordem 44/48 — não é
  nova). A altura e o pé de cada casa vêm das redes do pacote, calculados no centro da casa da batalha (exactos).
- **Não exige mexer na malha nem no `terreno-floresta.json`**: o pacote já serve estas três grelhas (`para(75,75,1)`,
  `para(50,50,1.5)`, `para(37,37,2)`). Os 6 ficheiros-fonte do terreno ficaram intocados (o teste «o terreno do
  servidor está em dia com as fontes do cliente: 6 fontes iguais» passa).
- **A faixa de 0,5 m a 2 m** é a única parte do mapa fora da grelha. Não é uma zona de jogo perdida: não cabe lá
  nenhuma casa de 2 m. Fazer a grelha de 2 m chegar à borda exigiria 37,5 casas — impossível sem mudar o tamanho do
  mapa (a malha). Registado; não improvisado.
- **A sala nasce com a grelha-mapa**: com terreno e sem tamanho na config, a sala nasce a 50 × 50 de 1,5 m. Um
  tamanho dado na config continua a valer (as bancadas e as provas das Ordens 44/48/62 usam 20 × 20, 25 × 25, 30 × 30).

**A escala muda a meio — ninguém muda de sítio no mapa (PROPOSTO, para o Mestre confirmar).** Com a grelha = o
mapa, mudar a escala muda o **tamanho** da grelha (50 → 75 → 37). A regra da Ordem 8 dizia «as posições guardam-se
em casas: nenhuma figura mexe (x, y ficam)». Com o canto NO fixo, guardar o índice atirava todas as figuras para o
canto NO (e a 2 m deixava de fora quem estivesse além da casa 36). Li a regra no mapa: **cada figura passa para a
casa nova que contém o centro da casa em que estava** — no mapa, ninguém se mexe (no máximo meia casa nova). O mesmo
para a casa inicial, a casa de colocação do «Recomeçar» e as casas a arder (duas que caiam na mesma ficam uma, com o
combustível maior). Recusas nomeadas ao Mestre, e a sala fica como estava:
`ESCALA_JUNTA_FIGURAS` (duas figuras colocadas cairiam na mesma casa ao passar a casas maiores) e
`ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS` (Ordem 62). A reserva da vez continua em metros. Uma grelha que **não** é o
mapa inteiro (tamanho dado na config) muda de escala exactamente como antes (índices ficam).

**A água (o lago).** O pacote marca o lago como 21 casas bloqueadas por «água funda» e não pode mudar (preso por SHA).
O servidor e as arenas passam a ler esse motivo como **casa de água**: entra-se, ocupa-se e atravessa-se.
**A regra do custo — [FALTA]:** o único sítio do repositório que fala do cânone da água é o comentário de
`relevo_floresta.gd` («no cânone é terreno difícil, não parede … é decisão do servidor»), sem número. Não há regra de
terreno difícil no servidor nem nos documentos do repo. **Segue-se com o custo igual** a uma casa seca (provado nos 6 m
sobre a água). Se o Mestre disser «custa o dobro» (ou outro número), é uma linha no `sala.js` (o custo do passo para
uma casa com `t.agua(x, y)`).

## 1. O que mudou (ficheiro a ficheiro)

### Servidor — VERIFICADO
- `rascunhos/servidor/nucleo/terreno.js`: `MOTIVOS_DE_AGUA = ['água funda']` (exportado); na grelha recortada,
  `bloqueada` deixa de contar a água, `motivo` é null nela, e há `agua(x, y)` e `casasDeAgua()`.
- `rascunhos/servidor/nucleo/sala.js`: o tamanho por omissão com terreno é o `ladoMax` da escala com que a sala nasce
  (50); `ladoDoMapa`, `grelhaEoMapa`, `casaNoLugar` e `mudarEscalaNoMapaInteiro` (a escala na grelha-mapa, acima);
  o evento `escala` leva ao Mestre (soMestre) `grelhaAntes` e `grelha`; o juízo do terreno (depuração) leva `agua`.
- `rascunhos/servidor/testes/ordem-mapa-jogavel.test.mjs` (novo, 14 testes).
- `ordem44-terreno.test.mjs`, `ordem48-terreno-qualquer-grelha.test.mjs`, `ordem62-escala-bloqueadas.test.mjs`: os
  números que contavam o lago como bloqueado. Em cada um, **bloqueadas + água = o número de antes** (43 = 26 + 17;
  10 = 8 + 2; 41 = 28 + 13; 48 = 35 + 13; Ordem 62: 7 → 4, as 3 do lago fora; 10 → 6, 8 → 5, 9 → 5).
- `rascunhos/servidor/dados/README.md`: a secção da ordem.

### Cliente Godot — VERIFICADO
- `cenas/arena/campo_da_mesa.gd`: `MOTIVOS_DE_AGUA` (a mesma lista, amarrada ao servidor por teste); `recusa_do_pe`
  não recusa a água (o menir, a escarpa… continuam a recusar); `casa_de_agua`; `seguir_na_agua` (a figura mexe o lago
  — salpico, anéis, calma da ÁGUA-REAÇÃO —, idempotente, religa-se a um lago de um mapa refeito).
- `cenas/arena/arena.gd` e `cenas/mestre/arena_mestre.gd`: uma linha cada — `seguir_na_agua` na sincronização das
  figuras. **As figuras (marcadores) não mudaram**: nem forma, nem pé, nem cor.
- `mapa/floresta/lago_floresta.gd`: `avancar` confere o nó **antes** de o atribuir a uma variável tipada. Defeito que a
  ligação revelou (59 «SCRIPT ERROR: previously freed instance» no `pecas_mestre`, 1 no `hud_acoes`, com as figuras
  libertadas a meio); a intenção já estava lá («os nós libertados saem»), uma linha tarde de mais. Não é fonte do
  terreno (o SHA do pacote não depende dele).
- `cenas/arena/ferramentas/provar_terreno_servidor.gd`: compara o servidor com a arena lendo a água como pisável.
- `cenas/arena/ferramentas/medir_mapa_jogavel.gd` (nova): a arena real, headless, nas 4 grelhas (ver §2 (e)).
- `testes/rodar_testes.gd`: `_teste_mapa_jogavel_geometria` e `_teste_mapa_jogavel_agua` (25 verificações; correm no
  CI no passo que já existia — **sem mudança no workflow**).
- **Não tocados:** `grelha_floresta.gd`, `relevo_floresta.gd`, `campo_floresta.gd`, `formas_floresta.gd`,
  `assentamento.gd`, `exportar_terreno.gd`, `terreno-floresta.json`; a paleta (as 6 [FALTA]); as 3 cores da
  caixa/retrato; a iniciativa; as figuras; `dados/apresentacao.gd`.

### Repositório
- `provas/ordem-mapa-jogavel/suites/` (as suites desta sessão) e `provas/ordem-mapa-jogavel/medicao/` (a arena e a
  água acima do pé). `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt` refeitos com `actualizar-listas.py`.

## 2. As provas (com números)

### (a) Suites — VERIFICADO
- Servidor, todas: **403/403** (389 de antes + 14 novas), 0 falhas (`suites/servidor-todos.txt`); a prova da ESCALA
  continua **9/9** (`suites/servidor-ordem-escala.log`).
- Schemas com o tráfego de todos os testes: **0 falhas nas mensagens que saem** (`suites/conferir-schemas.txt`).
- Cliente headless (Godot 4.7.2, depois de `--import`): `rodar_testes` **290/290** (265 + 25), 0 «SCRIPT ERROR»;
  `abrir_scripts` 105 scripts, 0 falhas; `abrir_mestre` 67/67; `pecas_mestre` 286/286; `hud_acoes` 50/50;
  `canario_privacidade` 10/10; `caixa_jogadora` 16/16; `abrir_clareira` 22/22; `medir_mestre` e
  `medir_painel_config` 0 falhas; arranque «pronto», 0 erros.
- **CI verde** em `b8293b3`: Testes dos rascunhos run **44817005435** — 9/9 jobs (servidor, protocolo, motor-real,
  ponta-a-ponta, retoma-pc, cliente, godot-cliente, foto-mestre, validador-glb); Sonda de privacidade run
  **44817005227** — verde.

### (b) Uma figura atravessa o mapa inteiro e entra no lago, em cada escala — VERIFICADO (`ordem-mapa-jogavel.test.mjs`)

| escala | grelha | casas | pisáveis | de água | bloqueadas | opções de mover de (0,0) | canto NO → canto SE | → meio do lago |
|---|---|---|---|---|---|---|---|---|
| 1 m   | 75 × 75 | 5625 | 5469 | 50 | 156 | **todas as pisáveis − 2 ocupadas** | APLICADA | APLICADA (54,14), casa de água |
| 1,5 m | 50 × 50 | 2500 | 2433 | 21 | 67  | **todas as pisáveis − 2 ocupadas** | APLICADA | APLICADA (36,9), casa de água |
| 2 m   | 37 × 37 | 1369 | 1326 | 13 | 43  | **todas as pisáveis − 2 ocupadas** | APLICADA | APLICADA (27,6), casa de água |

Nenhuma casa pisável fica inalcançável por desenho (a lista das que faltam é vazia nas três escalas); todas as casas
de água estão nas opções. O custo do caminho até ao canto SE é ≥ a distância de Manhattan × escala. A 1,5 m as 21
casas de água são exactamente as 21 «água funda» do pacote.

### (c) A prova dos 6 m sobre a água — VERIFICADO
Heroína com 6 m de deslocamento a partir do meio do lago, a andar para sul **só por casas de água** (a corrida de água
para sul é 6 / 4 / 3 casas — a prova inteira é dentro do lago):

| escala | 6 m cobrem | cada casa de água custa | N casas | N + 1 | técnica de 6 m a N | a N + 1 |
|---|---|---|---|---|---|---|
| 1 m   | **6 casas** | k × 1 m   | APLICADA, andou 6 m | fora das opções e recusada | ao alcance | fora |
| 1,5 m | **4 casas** | k × 1,5 m | APLICADA, andou 6 m | fora das opções e recusada | ao alcance | fora |
| 2 m   | **3 casas** | k × 2 m   | APLICADA, andou 6 m | fora das opções e recusada | ao alcance | fora |

### (d) O ataque de oportunidade pela grelha-mapa — VERIFICADO
Nas três escalas: heroína no meio do lago, orc na casa de água a sul; ela sai para a casa mais longe das opções →
**1** chamada ao motor com `ataqueDeOportunidade`.

### (a)/(e) A escala na grelha-mapa — VERIFICADO
- A sala nasce 50 × 50 @ 1,5 m e a jogadora recebe-o; sem terreno, 20 × 20 como sempre; um tamanho dado vale.
- 1,5 → 1 → 2 → 1,5 m: a grelha é 75 / 37 / 50 a cada passo; cada figura fica na casa nova que contém o centro da de
  antes; de volta a 1,5 m a heroína está a ±1 casa de onde começou (25,25).
- Recusas: duas figuras a 1 m em (42,42) e (43,42) → 2 m recusado com `ESCALA_JUNTA_FIGURAS`, nada mexe; com o orc em
  (46,42) passa (21,21) e (23,21); uma figura numa casa livre a 1 m cujo sítio a 2 m é bloqueado → recusado com
  `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS`, nada mexe.

### (c) Privacidade — VERIFICADO
- `canario_privacidade.gd` 10/10; `privacidade.test.mjs` dentro dos 403; o grep da sonda do CI limpo localmente e no CI.
- Teste (f): depois de 1,5 → 1 m, jogadora e espectador recebem `mapa` = 75 × 75 @ 1 e o evento `escala` vazio; o
  varrimento (números do orc, `ESCALA_`, `casaMAntes`, `grelhaAntes`, `casasQuePaga`) dá **0 achados**; o Mestre
  recebe o `grelhaAntes` (sanidade). Nada de vida/pontos de alma à jogadora.

### (e) A arena real, sem janela — VERIFICADO (`medicao/arena-mapa-jogavel.json`, `medir_mapa_jogavel.gd`)

| grelha | zona jogável (m) | linhas da grelha cobrem (m) | construção | figura no meio do lago |
|---|---|---|---|---|
| 20 × 20 @ 1,5 (antes) | −15 … 15 | 30 × 30 | 2,3 s | — (o lago fica fora) |
| 50 × 50 @ 1,5 | −37,5 … 37,5 | **75 × 75** | 3,5 s | de pé, **sem recusa**, casa de água, **mexe o lago** |
| 75 × 75 @ 1   | −37,5 … 37,5 | **75 × 75** | 0,5 s (mesma zona: o molde) | idem |
| 37 × 37 @ 2   | −37 … 37     | **74 × 74** | 3,4 s | idem |

## 3. O que a grelha-mapa muda no mapa desenhado — VERIFICADO (medido), para o olho do Mestre
O mapa é construído para a zona jogável e **não planta dentro dela nada que ocupe uma casa sem o servidor saber**
(regra da Ordem 42). Com a zona = o mapa inteiro, o mapa tira de dentro dele o que antes ficava fora dos 30 × 30 m:

| | zona 20 × 20 (antes) | zona = o mapa |
|---|---|---|
| árvores tiradas pela zona | 2 | **39** |
| rochas no mapa | 94 | **45** (66 tiradas) |
| estrato (arbustos, fetos…) tirado | 5 | **168** |
| tronco tombado | 12,7 m | **4,1 m** |
| casas bloqueadas na grelha do cliente | 173 | **88** = as 67 do servidor + as 21 de água |

Ficam as 24 árvores da arena, os marcos (menires, santuário, lanternas), as escarpas, o relevo, o lago e a orla
(250 árvores) e o anel. **Isto é exactamente o que o servidor já julgava** (o pacote foi gerado com uma zona de 84 m,
maior do que o mapa): a arena passa a desenhar a verdade do servidor. Manter as árvores e as rochas **dentro** do mapa
como obstáculos exigiria pô-las no pacote como casas bloqueadas — **refazer o `terreno-floresta.json` (outra ordem)**.
Ponto exacto para o Mestre, não improvisado.

## 4. O que NÃO foi medido
- **Capturas — [PENDENTE] PC LIVRE.** A grelha sobre o mapa todo, o lago dentro dela, as grelhas a 1 m e a 2 m (o
  olho do Mestre, pendente da ESCALA). Regime EM_USO: nenhuma captura, nenhuma imagem inventada. Fazer com o PC livre
  (as cenas e as 4 grelhas de `medir_mapa_jogavel.gd` são o guião: abrir a arena com GPU nessas grelhas e com a figura
  no lago).
- `provar_terreno_servidor.gd` (servidor × arena casa a casa, 12 grelhas): adaptado à água, **não corrido** (abre a
  arena 12 vezes; pesado para o PC em uso). A coerência está provada pelos números: 88 = 67 + 21, e o teste do cliente
  conta 50 / 21 / 13 casas de água com a geometria da arena = o servidor.
- O custo da arena com GPU com a grelha 75 × 75 (linhas, destaques); a câmara a enquadrar 75 m (a câmara recebe o
  tamanho da grelha, como antes, mas não foi vista).
- Uma batalha de bancada real (servidor + cliente) com a grelha-mapa e a escala a mudar a meio; a ponta-a-ponta do
  CI continua a 20 × 20 (a config dela dá o tamanho).

## 5. Passagem

**Onde parou:** ordem cumprida, menos as capturas: decisão escrita (§0), código, provas, CI verde em `b8293b3` e
fusão **fast-forward** `cb3a99a..b8293b3 -> fable/integracao-50` (conferida com `git ls-remote` antes e depois);
depois este ESTADO FINAL nas duas pontas.

**Próximo passo:** com o PC LIVRE, as capturas (§4) — a arena da jogadora e a do Mestre nas grelhas 50 × 50 @ 1,5,
75 × 75 @ 1 e 37 × 37 @ 2, com uma figura no lago. Depois, a palavra do Mestre nos pontos abaixo.

**O que falta conferir (coordenador / Mestre):**
1. **[FALTA] O custo da água.** Hoje: igual a uma casa seca. O cânone (citado no relevo) diz «terreno difícil, não
   parede», sem número. O Mestre/servidor decide o número; é uma linha no servidor.
2. **PROPOSTO — a mudança de escala na grelha-mapa** mantém o sítio no mapa (não o índice). Se o Mestre preferir o
   índice (a regra antiga à letra), é o ramo `grelhaEoMapa` do `mudarEscala`.
3. **O mapa sem árvores/rochas dentro dele (§3)** — a consequência da regra da Ordem 42 com a zona = o mapa. Se o
   Mestre quiser a floresta dentro do campo, é preciso refazer o pacote do terreno com árvores e rochas como casas
   bloqueadas (outra ordem: mexe na fonte do terreno e no `terreno-floresta.json`).
4. **PENDENTE — a figura na parte funda.** A água fica 0,45–2,0 m acima do pé (mediana ~1 m;
   `medicao/agua-acima-do-pe.txt`); o marcador mede 1,7 m — nas casas mais fundas fica submerso. O pé é o `peM` do
   servidor (Ordem 44: pé do cliente = pé do servidor), por isso boiar/nadar (`LagoFloresta.pe_na_agua`, o NADO)
   mexe no pé dos dois lados e nas figuras (o esqueleto é da A2). Não feito: fronteira desta ordem.
5. A grelha por omissão da arena **antes** do primeiro snapshot continua 20 × 20 (`apresentacao.gd`
   `GRELHA_*_PADRAO`): o snapshot manda sempre e traz a grelha-mapa. Não mudei a tabela (o teste da ESCALA mede a
   geometria com ela e a construção inicial ficaria mais pesada sem ganho).
6. As configs de bancada (`autojogo/cenario-bancada.json`, `e2e/servidor-e2e.mjs`, `dados-exemplo/mesa-mestre.json`)
   dão 20 × 20 explícito e ficam assim. A config real do Mestre (fora do repo) **deve omitir `sala.mapa`** para ter o
   mapa inteiro; se tiver 20 × 20, fica 20 × 20.
7. Continuam (não eram desta ordem): as 6 cores [FALTA] da paleta, as 3 cores da caixa/retrato, quem roda a
   iniciativa, o `caixa_jogadora.gd` fora do CI, se a jogadora vê a escala escrita no HUD.
