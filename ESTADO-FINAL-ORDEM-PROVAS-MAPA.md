# ESTADO FINAL — ORDEM PROVAS-MAPA (Claude conta 2, PC · 20/11/2026)

Ordem: correr as duas provas que a MAPA-JOGÁVEL deixou por correr (o §4 do ESTADO-FINAL dela). **Não houve
construção**: nenhuma linha do jogo (servidor ou cliente) mudou. Base: `fable/integracao-50` @ `c9c176f` (com as
capturas fundidas). Ramo: `claude2/provas-mapa` (sem fusão). Regime: PC em uso LEVE (Steam aberto, CPU ~3 %); só
Godot `--headless` (CPU), sem GPU, corridas curtas. *(Correcção 5: as durações «~70 s / ~40 s» que aqui estavam não
tinham carimbo de tempo e foram tiradas. Na re-corrida das correcções, com carimbos nos registos, a prova 1 levou
**84 s** (original) e **80 s** (cópia); a bancada não foi re-corrida e não tem duração registada.)* O regime não
chegou a EM_USO pesado e não houve paragens.
Marcas: VERIFICADO (corrido e conferido nesta sessão), PROPOSTO, PENDENTE, [FALTA].

**Resultado em curto:**
- **Prova 1 (servidor × arena, casa a casa):** 17 das 18 grelhas concordam a 100 % com a ferramenta original. A
  única que diverge, a 50×50 @ 1 m, é **defeito da ferramenta e não do jogo**: o servidor serve 75×75 e a ferramenta
  desenhava 50×50. Com a cópia adaptada passam as **18 de 18**, com **0 divergências** em todas.
- **Prova 2 (batalha de bancada, servidor + cliente, 1,5 → 1 → 2 m):** **tudo passou**. A jogadora Godot fez
  **44 de 44** verificações e o lado do Mestre e do espectador passou também. As figuras ficaram no mesmo sítio do
  mapa, o caminho e o alcance continuaram certos e a privacidade deu **0 achados**.

---

## 1. Prova 1 — `provar_terreno_servidor.gd`, servidor × arena, casa a casa — VERIFICADO

**Como se correu.** `godot --headless --path cliente --import` (o clone era novo) e depois
`godot --headless --path cliente -s res://cenas/arena/ferramentas/provar_terreno_servidor.gd -- --json=…`. Para cada
grelha, a ferramenta chama o servidor de verdade (`servidor/ferramentas/juizo-terreno.mjs`: o núcleo `sala.js` com
o `terreno-floresta.json`) e abre a arena do jogo. Depois compara, casa a casa:
- a altura do centro e o pé da figura, bit a bit;
- se a casa está bloqueada (a água conta como pisável), o motivo e a cobertura;
- as figuras desenhadas;
- as recusas do servidor;
- as casas de mover;
- os marcos do mapa.

**As «12 grelhas» são hoje 18.** A ordem fala em 12, que são as da Ordem 48 (linhas 1–12 abaixo). A Ordem 59
acrescentou 6 grelhas que tocam a fronteira do mapa só nalguns lados (linhas 13–18). Corri as 18 e registo todas.

### 1a. A ferramenta original (como estava em `b62a887`): 17 grelhas a 100 %, 1 diverge — 9 falhas, todas na mesma grelha

*(Correcção 1: a ferramenta original foi corrigida no commit das correcções e voltou a correr nas 18 grelhas, com
TUDO PASSOU e código de saída 0. Ver §5. Esta tabela é a corrida de `b62a887`, guardada em
`provar-terreno-servidor-b62a887.log`.)*

| # | grelha | casas | água | bloq. (srv) | juízo ≠ | motivo ≠ | cobertura ≠ | desvio altura / pé | figuras (desvio) | recusas | mover (bloq. no cliente) | marcos |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 30×30 @ 1,5 | 900 | 17 | 26 | 0 | 0 | 0 | 0 / 0 | 15 (0) | 3 | 41 (0) | 6/6 |
| 2 | 30×30 @ 2 | 900 | 12 | 30 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 0 | 30 (0) | 4/4 |
| 3 | 20×20 @ 1,5 | 400 | 0 | 0 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 0 | 47 (0) | 0/0 |
| 4 | 25×25 @ 1,5 | 625 | 2 | 8 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 8 | 52 (0) | 0/0 |
| 5 | 25×25 @ 1 | 625 | 0 | 0 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 0 | 91 (0) | 0/0 |
| 6 | 25×25 @ 2 | 625 | 13 | 28 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 28 | 21 (0) | 5/5 |
| 7 | 21×17 @ 1 | 357 | 0 | 0 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 0 | 90 (0) | 0/0 |
| 8 | 33×27 @ 2 | 891 | 13 | 35 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 35 | 30 (0) | 7/7 |
| 9 | 44×20 @ 1,5 | 880 | 0 | 11 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 11 | 52 (0) | 2/2 |
| 10 | **50×50 @ 1,5 (o mapa)** | 2500 | 21 | 67 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 67 | 52 (0) | 14/14 |
| **11** | **50×50 @ 1 pedida → servida 75×75 @ 1** | 5625 | 50 | 156 | **336** | **184** | **631** | **4,43 m / 4,43 m** | 10 (**3,47 m**) | 156 (**0 batem**) | 110 (**15**) | **0/9** |
| 12 | **37×37 @ 2 (o mapa)** | 1369 | 13 | 43 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 43 | 31 (0) | 9/9 |
| 13 | 49×49 @ 1,5 | 2401 | 21 | 67 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 67 | 52 (0) | 14/14 |
| 14 | 50×20 @ 1,5 | 1000 | 0 | 11 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 11 | 52 (0) | 2/2 |
| 15 | 20×50 @ 1,5 | 1000 | 0 | 10 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 10 | 52 (0) | 2/2 |
| 16 | 49×30 @ 1,5 | 1470 | 17 | 43 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 43 | 51 (0) | 10/10 |
| 17 | 37×20 @ 2 | 740 | 5 | 15 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 15 | 31 (0) | 3/3 |
| 18 | 35×37 @ 2 | 1295 | 13 | 43 | 0 | 0 | 0 | 0 / 0 | 10 (0) | 43 | 31 (0) | 9/9 |

Em todas as grelhas, a faixa da fronteira do mapa tem a cobertura toda afirmada e 0 casas diferentes. As «recusas»
são só as das figuras pedidas: nas grelhas «auto» são todas as bloqueadas; nas 1–3 são as casas escolhidas à mão.

**O que cada coluna conta (correcções 2 e 5).** As regras estão escritas no cabeçalho de `tabela-grelhas.md`, que sai
de `ferramentas/tabela_grelhas.py`.
- **«cobertura ≠»** conta **só a cobertura afirmada**: as casas em que o servidor dá um número (≠ null) e o cliente
  tem outro (`coberturaAfirmadaDiferente`). É o portão da ferramenta, e o «0 divergências» é verdadeiro dentro desse
  portão.
- **A cobertura não afirmada (o resíduo nulo).** São as casas da faixa da borda em que o servidor diz `null`. Estão
  registadas na ferramenta mas não julgadas (`coberturaNaoAfirmada` e `coberturaNaoAfirmadaClienteDifereDaReferencia`).
  Por grelha, de 1 a 18: 99 (1), 107 (0), 76 (1), 91 (2), 184 (2), 42 (3), 87 (0), 112 (4), 120 (3), 0, 0, 0, 97 (0),
  96 (1), 88 (0), 112 (1), 65 (1), 74 (0). Entre parênteses está quantas delas o cliente tem com outra cobertura que
  a do mapa de referência: **de 0 a 4 por grelha**. As três grelhas-mapa (10–12) não têm nenhuma.
- **«água»** conta as casas do juízo do servidor com `agua`. Não está nos JSON: o gerador recalcula-a correndo
  `juizo-terreno.mjs` com a grelha pedida e a escala, sem figuras.
- **«marcos»** conta os marcos que o mapa do cliente bloqueia com o próprio nome e que caem no centro de uma casa do
  jogo (as entradas `marcos` do JSON). «ok» quer dizer casa bloqueada no servidor; a ferramenta exige também o mesmo
  nome.
- **As 15 figuras da grelha 1.** Foram pedidas 17 casas à mão. O servidor recusou 3: (1,0) e (3,2), que são menires,
  e (28,28), um santuário. Ficam 14 criaturas, mais a heroína, que o `juizo-terreno.mjs` põe sempre: 15. Nas grelhas
  «auto» entram 9 casas livres mais a heroína, e por isso são 10.

### 1b. A grelha 11 — porque diverge, e porque é a ferramenta e não o jogo
- **O que a ferramenta faz.** O `juizo-terreno.mjs` monta a sala com o tamanho pedido (50×50), que nasce a 1,5 m, e
  depois pede `escala 1`. A arena do Godot é aberta com o tamanho que a ferramenta pediu (50×50 @ 1 m, canto NO em
  −25 m).
- **O que o servidor faz, que é o jogo como a MAPA-JOGÁVEL o deixou.** 50×50 @ 1,5 m **é** a grelha-mapa. Na
  grelha-mapa, mudar a escala para 1 m dá **75×75 @ 1 m**, com o canto NO em −37,5 m e ninguém a mudar de sítio no
  mapa (§0 da MAPA-JOGÁVEL, regra PROPOSTA ao Mestre).
- **A consequência.** A ferramenta compara a arena 50×50 com o juízo 75×75, com origens desencontradas (−25 contra
  −37,5 m). Daí os 336 juízos diferentes, a altura 4,43 m ao lado e os 9 marcos que não batem. As 9 falhas são todas
  desta grelha e todas desta causa: a primeira linha da grelha já diz «FALHA grelha 50×50 de 1.0 m: o servidor julga
  esta grelha».
- **A condição (correcção 3).** Esta obsolescência **assenta na regra §0 da MAPA-JOGÁVEL**: a mudança de escala na
  grelha-mapa guarda o sítio no mapa. Essa regra está **ainda PROPOSTA ao Mestre**. Se ele a rejeitar, a sala a 1 m
  deixa de servir 75×75 e **o caso reabre**: a ferramenta e esta prova têm de voltar a ser julgadas. A fusão não faz
  da obsolescência uma coisa incondicional.
- **Conclusão.** O caso `[50, 50, 1.0]` da ferramenta ficou obsoleto com a MAPA-JOGÁVEL (sob a condição acima). Uma grelha 50×50 @ 1 m
  deixou de existir no jogo: a sala nasce sempre a 1,5 m e uma 50×50 a 1,5 m é a grelha-mapa. Não é defeito do jogo,
  por isso não parei. Fiz a cópia adaptada abaixo; a ferramenta original foi depois corrigida nas correcções da conferência (ver §5).

### 1c. A cópia adaptada (fora de `cliente/`): 18/18, TUDO PASSOU — 0 divergências
`provas/ordem-mapa-jogavel/provas-bancada/ferramentas/provar_terreno_servidor_mapa.gd` muda uma coisa só: a arena
abre a grelha que o servidor devolve (`juizo.largura/altura`) e não a pedida, e o relatório guarda as duas. O resto é
o original, linha a linha. Corre-se com `-s <caminho absoluto>`. Resultado: todas as grelhas iguais às da tabela 1a,
e a 11 passa a:

| # | pedida → servida | casas (dentro/fora da zona livre) | água | bloq. | juízo ≠ | motivo ≠ | cobertura ≠ | desvio altura / pé | figuras | recusas | mover (bloq. no cliente) | marcos |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 11 | 50×50 @ 1 → **75×75 @ 1** | 5625 (841/4784) | 50 | 156 | 0 | 0 | 0 | 0 / 0 (bit a bit) | 10 (0) | 156, todas com o mesmo motivo no cliente | 110 (0) | 14/14 |

**As três grelhas-mapa (50 / 75 / 37) batem casa a casa com o servidor.** As casas de água (21 / 50 / 13) são as
mesmas da MAPA-JOGÁVEL, e o servidor não oferece nenhuma casa de mover que o cliente desenhe bloqueada.

**Sugestão ao coordenador (feita nas correcções, ver §5):** trocar o caso `[50, 50, 1.0]` do original pela leitura da
grelha servida, como faz a cópia, ou documentá-lo como «75×75 @ 1 m». A mudança é na ferramenta do cliente
(`cenas/arena/ferramentas/`) e fica fora do âmbito desta ordem.

---

## 2. Prova 2 — a batalha de bancada real com a grelha-mapa e a escala a mudar a meio — VERIFICADO

**Como foi montada.** Tudo ficou fora de `cliente/` e `servidor/`, em `provas-bancada/ferramentas/`:
- **Servidor** (`bancada-servidor.mjs`): o `sala.js` de verdade, atrás do adaptador WebSocket do repo, com o
  pacote do terreno, o motor falso e o modo manual. A config **não leva `mapa`**, por isso a sala nasce com a
  grelha-mapa, 50×50 @ 1,5 m.
- **Jogadora** (`bancada_jogadora_mapa.gd`): o **cliente Godot de verdade**. A Rede liga-se pela WebSocket como a
  heroína (a senha é a fictícia) e o Estado e a **arena do jogo** (`arena.tscn`) correm sem janela.
- **Mestre e espectador** (`bancada-mestre.mjs`): clientes WebSocket em Node. O Mestre faz o lobby, começa, põe o
  orc **dentro do lago** e muda a escala depois de cada passo da heroína. O espectador recebe o que a Party recebe.
- Guião: `correr-bancada.sh`.
- **Figuras:** a heroína nasce **em terra**, a norte do lago (38,4); o orc está **no lago** (38,11), numa casa de água.
- **Escala:** 1,5 → 1 → 2 m, a meio da vez dela.

**O que se confere em cada escala:**
1. **O mesmo sítio do mapa.** O nó desenhado de cada figura antes e depois da mudança fica a ≤ meia casa nova, em x e
   em z, e a casa nova é a que contém o ponto de antes.
2. **O caminho.** As casas de mover que o servidor oferece são comparadas com um BFS de 4 vizinhos refeito no
   cliente, com o **terreno da arena** (a água pisa-se) e as figuras a bloquear. O custo é passos × casaM e a
   reserva continua em metros.
3. **O alcance.** O orc está nos ataques se e só se o caminho das casas for ≤ max(1, 9 m / casaM), com o chicote de
   9 m da ficha fictícia.
4. **Um passo.** A heroína dá um passo: o servidor tem de o aplicar e a figura tem de ficar desenhada no pé da casa
   nova.

| escala | grelha (canto NO) | figuras antes → depois (m, x/z do nó) | desvio | caminho: servidor / BFS do cliente (diferenças) | alcance (orc) | passo |
|---|---|---|---|---|---|---|
| 1,5 m | 50×50 (−37,5) | heroína (38,4) em terra · orc (38,11) na água | — | 80 / 80 (0 · 0 · 0), 4 casas de água, reserva 9 m = 6 casas | 7 passos > 6 casas → **fora**; o servidor também não o oferece | → (38,5), 1,5 m, APLICADA |
| 1 m | **75×75** (−37,5) | heroína (20,25; −29,25) → (20,00; −29,00), casa (57,8) · orc (20,25; −20,25) → (20,00; −20,00), casa (57,17), **na água** | 0,25 / 0,25 ≤ 0,5 | 112 / 112 (0 · 0 · 0), 9 de água, reserva **7,5 m** = 7 casas | 9 passos ≤ 9 casas → **ao alcance**; o servidor oferece-o | → (57,9), 1 m, APLICADA |
| 2 m | **37×37** (−37) | heroína (20; −28) → (20; −28), casa (28,4) · orc (20; −20) → (20; −20), casa (28,8), **na água** | 0 / 0 ≤ 1 | 24 / 24 (0 · 0 · 0), 4 de água, reserva **6,5 m** = 3 casas | 4 passos ≤ 4,5 casas → **ao alcance**; o servidor oferece-o | → (28,6), **casa de água**, 4 m, APLICADA |

- A reserva no fim é 9 − 6,5 = **2,5 m**. O Mestre vê nos movimentos os custos 1,5 / 1 / 4 m e a reserva
  7,5 / 6,5 / 2,5 m.
- O alcance muda com a escala, como manda a regra das casas: a 1,5 m o orc está fora, a 1 m e a 2 m está dentro.
  O servidor e o cliente concordam nos três casos.
- **Mestre:** as 5 ordens foram todas APLICADA (LOBBY_SET, START, PLACE no lago, escala 1, escala 2). O evento
  `escala` chega-lhe com `soMestre`: `casaMAntes`, `grelhaAntes` 50×50 → `grelha` 75×75 e depois 75×75 → 37×37, e a
  `vez` com `reservaM` 7,5 / 6,5 e `casasQuePaga` 7 / 3. O Mestre vê as figuras nas mesmas casas que a jogadora:
  (57,8)/(57,17) e (28,4)/(28,8).
- **0** «SCRIPT ERROR» no Godot.
- **A floresta varia de carga para carga (correcção 6).** Os resumos `[floresta] pronta em … | {…}` dos registos trazem
  `casas_bloqueadas` diferentes conforme a carga. Na prova 1 foram 173, 146, 128, 173, 164, 188, 141, 204, 125, 157,
  88, 88, 88, 151, 141, 122, 133 e 91; na bancada, 173, 88 e 88. **Isto não é falha.** É a contagem da grelha própria
  da floresta (50×50 casas de 1,5 m, `campo_floresta.gd`), e a floresta tira árvores, rochas e estrato de dentro da
  zona jogável da grelha que a arena abriu (`zona_tirados_*` no mesmo resumo). Por isso o número depende da grelha
  aberta: a grelha-mapa inteira dá sempre 88. Repete-se de corrida para corrida: a re-corrida das correcções deu a
  mesma sequência, grelha a grelha. A prova não lê esse número: compara o juízo do servidor com a grelha da arena,
  casa a casa.

### 2a. Privacidade — VERIFICADO
- **Sonda da batalha, na jogadora Godot:** varri as **22 mensagens** que chegaram à Rede dela, à procura de três
  tipos de canário:
  - números do orc: 7777, 313 e 9137;
  - textos: `ESCALA_`, `CANARIO-FANTASMA`, `CANARIO-DESGRACA`, `CANARIO-SENHA`, `Orc Verdadeiro` e o PIN;
  - chaves só do Mestre: `casaMAntes`, `grelhaAntes`, `casasQuePaga` e `soMestre`.

  Deu **0 achados** e **0 mensagens de Mestre**. Ela recebeu os três mapas (50×50 @ 1,5, 75×75 @ 1, 37×37 @ 2) e
  mais nada sobre a mudança.
- **Sonda da batalha, no espectador (Node):** 12 mensagens e **0 achados**, com os mesmos canários e ainda os números
  da heroína (5551, 5150, 4040), que são dela e não do espectador. Os eventos `escala` chegam-lhe **vazios** (`{}`).
- **Sanidade:** o Mestre recebe o `grelhaAntes`. A sonda procura algo que existe de verdade, só que noutro sítio.
- **A sonda do CI** (o grep dos e-mails pessoais) está **limpa** no repo com os ficheiros novos.
- **`canario_privacidade.gd`: 10/10.**

### 2b. Limites desta bancada (registados, não escondidos)
- **Quem faz de Mestre.** O Mestre é um cliente Node, não o ecrã do Mestre em Godot. A ordem pedia «servidor +
  cliente», e o cliente do jogo aqui é o da **jogadora**, com a arena real. O ecrã do Mestre com a grelha-mapa foi
  visto nas capturas (ordem CAPTURAS-MAPA) e continua sem bancada de rede.
- **O registo das figuras do lado do Mestre.** As figuras «antes/depois» que o Mestre guarda vêm do último snapshot
  dele. Os passos chegam-lhe como eventos `movimento` (no JSON: custo e reserva). A prova do sítio no mapa é a da
  jogadora, nos nós desenhados.
- **Uma só batalha.** Correu uma vez, com uma heroína e um orc e o motor falso. Não há ataque nem cartão: a prova
  era a do sítio, do caminho, do alcance e da privacidade.
- **Fora do pedido.** A volta 2 → 1,5 m e as recusas `ESCALA_JUNTA_FIGURAS` e `…_BLOQUEADAS` não entraram aqui. Estão
  nos testes do servidor (`ordem-mapa-jogavel.test.mjs` (a)/(e)), que não corri nesta sessão.

---

## 3. O que ficou no repositório (ramo `claude2/provas-mapa`)
`provas/ordem-mapa-jogavel/provas-bancada/`:
- `provar-terreno-servidor.log` e `terreno-servidor-arena.json`: a ferramenta original (9 falhas, todas da grelha 11);
- `provar-terreno-servidor-adaptada.log` e `terreno-servidor-arena-adaptada.json`: a cópia (TUDO PASSOU);
- `tabela-grelhas.md`: as duas tabelas, geradas por `ferramentas/tabela_grelhas.py`;
- `bancada-jogadora.log/.json`, `bancada-mestre.log/.json` e `bancada-servidor.log`: a batalha;
- `canario-privacidade.log` e `sonda-ci.txt`;
- `ferramentas/`:
  - `provar_terreno_servidor_mapa.gd`: a cópia adaptada;
  - `bancada-servidor.mjs`, `bancada-mestre.mjs`, `bancada_jogadora_mapa.gd` e `correr-bancada.sh`: a bancada;
  - `tabela_grelhas.py`.

**Sem mudança** em `rascunhos/` (servidor, cliente, protocolo) em `b62a887` (nas correcções mudou só a ferramenta de prova `cenas/arena/ferramentas/provar_terreno_servidor.gd`, §5), nem no workflow, na paleta, nas cores da caixa e do
retrato, na iniciativa e nas figuras. O `--import` gerou `.uid` não rastreados no clone, que não entraram no commit.

## 4. Passagem

**Onde parou:** ordem cumprida. As duas provas foram corridas e registadas, e o commit `b62a887` está no ramo
`claude2/provas-mapa`, empurrado para o `origin`, **sem fusão**.

**Para voltar a correr** (num clone, a partir de `rascunhos/`):
1. `godot --headless --path cliente --import`;
2. a prova 1: `godot --headless --path cliente -s <abs>/provas-bancada/ferramentas/provar_terreno_servidor_mapa.gd -- --json=<abs>.json`
   (o original corre com `-s res://cenas/arena/ferramentas/provar_terreno_servidor.gd`);
3. a prova 2: `GODOT=<godot console> bash provas/ordem-mapa-jogavel/provas-bancada/ferramentas/correr-bancada.sh [porta]`.

É preciso Node ≥ 22 no PATH.

**O que falta conferir (coordenador / Mestre):**
1. **A ferramenta original tinha um caso obsoleto**: o `[50, 50, 1.0]` passou a ser servido como 75×75 @ 1 m (§1b).
   **Corrigido nas correcções** (§5): a original passou a TUDO PASSOU. A condição da regra §0 mantém-se.
2. **Continua da MAPA-JOGÁVEL, sem mudança:**
   - [FALTA] o custo da água (hoje igual a uma casa seca);
   - PROPOSTO: a mudança de escala na grelha-mapa guardar o sítio no mapa (esta bancada confirma que funciona como
     descrito, servidor e cliente, pela rede);
   - o mapa sem árvores e rochas dentro da grelha.
3. **PENDENTE, fora desta ordem:**
   - uma bancada de rede com o **ecrã do Mestre em Godot** na grelha-mapa;
   - a ponta-a-ponta do CI continua a 20×20.
- `git ls-remote`: claude2/provas-mapa = b62a8870fc28747f484a2dc7d78083b290d1462a; fable/integracao-50 = c9c176f (intocado).

## 5. Correcções da conferência (ORDEM-PROVAS-MAPA-CORRECOES, sentença «FUNDE COM CORRECÇÕES — 800/1000»)
São as seis que bloqueiam a fusão, aplicadas no ramo com um commit novo e sem fusão. O registo completo está em
`ESTADO-FINAL-ORDEM-PROVAS-MAPA-CORRECOES.md`, na sede.
1. **A ferramenta original foi corrigida.** É `rascunhos/cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd`, a
   única linha fora de `provas/` em todo o ramo. É uma ferramenta de prova; o jogo não muda. Recebeu a mesma mudança
   da cópia: a arena abre a grelha que o servidor devolve, e o relatório guarda `pedida` e `grelha`. Voltou a correr
   nas 18 grelhas: **TUDO PASSOU, código 0**, com a grelha 11 pedida 50×50 → servida 75×75 @ 1 m e 0 divergências.
   O registo está em `provar-terreno-servidor.log` / `terreno-servidor-arena.json`, e a corrida antiga em
   `provar-terreno-servidor-b62a887.log`. **VERIFICADO.**
2. **O resíduo nulo** está registado em §1a, e a tabela gerada define o que «cobertura ≠» conta.
3. **A condição da obsolescência** (a regra §0, ainda PROPOSTA ao Mestre) está em §1b.
4. **A proveniência está alinhada.** O JSON adaptado nomeia agora a cópia (`"prova": "provas/…/provar_terreno_servidor_mapa.gd
   (cópia adaptada de …)"`), porque a cópia foi corrigida e voltou a correr (TUDO PASSOU). Este ESTADO-FINAL é o mesmo
   ficheiro na sede e no commit, byte a byte, com a linha de verificação do push de `b62a887`.
5. **O que não se re-deriva.** As durações sem carimbo saíram (cabeçalho), e os registos novos têm `# início` /
   `# fim`. As regras de contagem da água e dos marcos estão no gerador e na tabela, e as 15 figuras da grelha 1
   estão explicadas em §1a.
6. **A variância da floresta por carga** está explicada em §2.
