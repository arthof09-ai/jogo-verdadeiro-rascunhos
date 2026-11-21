# ESTADO-FINAL — ORDEM-PROVAS-MAPA-CORR7 (conta 1 · Opus · 21/11/2026)

**Objecto:** a correcção 7 da sentença da conferência PROVAS-MAPA — «correr o retorno 2 → 1,5 m e as recusas
`ESCALA_JUNTA_FIGURAS` / `ESCALA_BLOQUEADAS` através dos testes de servidor existentes».
**Base:** `fable/integracao-50` @ `b7ecadd`. **Ramo:** `claude1/provas-mapa-corr7`, um commit, **SEM fusão**.
Marcas: VERIFICADO (corrido e conferido nesta sessão), ACHADO (para o coordenador decidir).

## Leia primeiro — 3 achados

1. **ACHADO — o nome da recusa.** Não existe nenhum código `ESCALA_BLOQUEADAS` no servidor. O código que
   `nucleo/sala.js` emite é **`ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS`** (Ordem 62). Aparece duas vezes: em
   `mudarEscala` (grelha fixa, l. 3064) e em `mudarEscalaNoMapaInteiro` (grelha-mapa, l. 3143). Tomei
   «ESCALA_BLOQUEADAS» como abreviatura deste código. Não mudei nenhum nome.
2. **ACHADO — no retorno 2 → 1,5 m da grelha-mapa, nenhuma das duas recusas pode disparar.** As recusas só
   existem quando se passa para casas maiores (1,5 → 2 e 1 → 2 m).
   - Uma casa de 2 m tem o centro a 2 m do centro da vizinha. Duas casas de 2 m caem portanto sempre em casas de
     1,5 m distintas: 1.369 → 1.369 imagens.
   - Nenhuma das 1.326 casas livres de 2 m cai numa casa bloqueada de 1,5 m.

   Provei-o sobre o mapa inteiro e, no servidor, nas casas de risco (ver (b) e (c)). Por isso as provas (b) e (c)
   têm duas partes: a recusa a disparar **a subir** e a garantia de que **a descer** não dispara.
   Para comparar, na sonda de mapeamento (`provas/ordem-provas-mapa-corr7/sonda-mapeamento.log`, terreno actual):
   1 → 1,5 m também pode juntar figuras (3.125 colisões), mas nunca bloqueia (0 livres em bloqueadas);
   2 → 1 m e 1,5 → 1 m não podem fazer nenhuma das duas coisas (0 colisões, 0 bloqueios).
3. **ACHADO — a base `b7ecadd` já está vermelha no CI** (Testes dos rascunhos, run **44862505065**). O job que
   falha é `retoma-pc`: «PARAR: o clone nao bate com depois.txt». O `d21f734` (PROVAS-MAPA-CORRECÕES) mudou
   `rascunhos/cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd` e não refez as listas da retoma.
   - O ficheiro de teste novo que esta ordem cria também exige que as listas sejam refeitas. Corri
     `python -I retoma-i0004/actualizar-listas.py`, como mandam o script e o CI.
   - Isso põe as listas certas para os dois: o meu ficheiro e o de `d21f734`.
   - Mudam só `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt`. São registos, não lógica do jogo.
   - **Se o coordenador preferir** que a reparação da deriva do `d21f734` vá numa ordem própria, basta reverter a
     linha do `provar_terreno_servidor.gd` nas duas listas. O CI continua vermelho por essa razão até alguém a
     refazer.

**Nenhuma linha da lógica do jogo mudou.** `git diff b7ecadd -- rascunhos/servidor/nucleo rascunhos/cliente rascunhos/protocolo`
dá vazio, à excepção do ficheiro de teste novo. Nenhum teste falhou contra a lógica, por isso não houve nada para
parar.

## Onde estão os testes da ESCALA (passo 1)

| ficheiro | o que cobre |
|---|---|
| `rascunhos/servidor/testes/ordem-mapa-jogavel.test.mjs` | grelha-mapa: (a) 1,5 → 1 → 2 → **1,5** m. O último passo já é o retorno, mas só se confere «±1 casa» no fim e não se prova que a batalha continua. (e) as duas recusas, só no sentido **1 → 2 m** |
| `rascunhos/servidor/testes/ordem62-escala-bloqueadas.test.mjs` | grelha fixa 30 × 30: `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS` nas 6 mudanças, incluindo **2 → 1,5 m (5 figuras recusadas)** |
| `ordem-escala.test.mjs`, `ordem11-escala.test.mjs` | escalas válidas, 6 m em casas, persistência, privacidade, `ESCALA_INVALIDA` |
| `nucleo/sala.js` `mudarEscalaNoMapaInteiro` (l. 3112–3174) | onde `ESCALA_JUNTA_FIGURAS` (l. 3139) e `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS` (l. 3143) disparam na grelha-mapa |

**A cobertura que faltava:**
- o retorno 2 → 1,5 m **na grelha-mapa**, conferido casa a casa, com a vez e os metros, e com a batalha a continuar
  depois;
- as recusas no sentido **1,5 → 2 m**, que é o da bancada da PROVAS-MAPA;
- a batalha a continuar depois de uma recusa;
- a prova de que, a descer, as recusas não disparam.

Escrevi um ficheiro novo, no estilo de `ordem-mapa-jogavel.test.mjs` e `ordem62-…`:
**`rascunhos/servidor/testes/ordem-provas-mapa-corr7.test.mjs`**, com 6 testes.

## Comandos corridos

```
git clone ../ordem-provas-mapa/repo repo ; git checkout -b claude1/provas-mapa-corr7 b7ecadd
git config core.autocrlf false      # ver «Desvios» abaixo
cd rascunhos/servidor
node --test testes/                                       # base: 403/403
node --test testes/ordem-provas-mapa-corr7.test.mjs testes/ordem-mapa-jogavel.test.mjs \
     testes/ordem62-escala-bloqueadas.test.mjs testes/ordem-escala.test.mjs testes/ordem11-escala.test.mjs   # 42/42
node --test testes/                                       # depois: 409/409
cd ../cliente
Godot_v4.7.2-stable_win64.exe --headless --path . --import
Godot_v4.7.2-stable_win64.exe --headless --path . -s res://testes/rodar_testes.gd   # 290/290
node provas/ordem-provas-mapa-corr7/ferramentas/sonda-mapeamento.mjs <repo>         # a sonda do mapeamento
python -I retoma-i0004/actualizar-listas.py
```

Os registos com a saída real estão no commit, em `provas/ordem-provas-mapa-corr7/`, e na sede, em `registos/`:
`servidor-escala.log`, `servidor-todos.log`, `cliente-import.log`, `cliente-rodar_testes.log`, `mutacoes.log` e
`sonda-mapeamento.log`.

## Resultado por prova — VERIFICADO

### (a) o retorno 2 → 1,5 m funciona
**Âmbito:** o retorno aplica-se na **grelha-mapa**; na grelha fixa o 2 → 1,5 m recusa-se por desenho
(`ordem62-escala-bloqueadas.test.mjs`: 2 → 1,5 m recusada, 5 figuras nomeadas).

```
✔ CORR7 (a): o retorno 2 → 1,5 m a meio da batalha (1,5 → 1 → 2 → 1,5) — ninguém muda de sítio, a grelha volta a 50 × 50, a batalha continua
✔ CORR7 (a): o retorno directo 2 → 1,5 m com a heroína a meio da vez — os metros andados a 2 m ficam em metros
```
- **Primeiro teste.** A sala nasce a 1,5 m, com a heroína em (20,20), o orc e o lobo. A heroína anda 1 casa
  (1,5 m). Depois o Mestre muda 1,5 → 1 → 2 → 1,5 m.
  - **As figuras mantêm o sítio no mapa.** Em cada passo, cada figura fica **exactamente** na casa que contém o
    centro da casa de antes (a regra §0). O mesmo vale para a casa inicial.
  - **A grelha recalcula.** A grelha passa a 75² → 37² → **50² @ 1,5 m**, e a jogadora recebe-a no snapshot. O
    juízo do terreno volta a 50 × 50 @ 1,5 m.
  - **A batalha continua.** A vez fica igual (andou 1,5 m, reserva 7,5 m), e o orçamento das opções é 7,5 m.
    Ninguém fica numa casa bloqueada. O último evento `escala` tem `casaMAntes 2 → casaM 1,5`. A heroína anda e
    encerra a vez, e a vez passa.
- **Segundo teste.** A batalha está a 2 m e a heroína andou 1 casa (2 m). O retorno 2 → 1,5 m põe cada figura na
  casa do mesmo sítio. Fica `andouM 2` e `reservaM 7`, e nenhuma opção passa dos 7 m. A batalha continua.

### (b) `ESCALA_JUNTA_FIGURAS`
```
✔ CORR7 (b): ESCALA_JUNTA_FIGURAS a subir 1,5 → 2 m — recusada, a sala fica igual, e a batalha continua
✔ CORR7 (b): a descer 2 → 1,5 m, ESCALA_JUNTA_FIGURAS nunca pode disparar — vizinhas a 2 m ficam vizinhas a 1,5 m
```
- **A subir.** A heroína está em (12,10) e o orc em (13,10), a 1,5 m. As duas casas caem na casa (9,7) de 2 m.
  - O pedido 1,5 → 2 m dá `ROOM_REJECT`/`acao_invalida`, com o detalhe ao Mestre
    `ESCALA_JUNTA_FIGURAS: 2 figuras ficavam juntas com 2 m por casa — …`. As duas figuras vão nomeadas em (9,7).
  - Figuras, mapa e vez ficam iguais, e a escala fica a 1,5 m. A Party não vê o detalhe.
  - Depois da recusa, a heroína anda e encerra a vez.
- **A descer.** As 37 × 37 casas de 2 m dão 1.369 imagens distintas a 1,5 m. No servidor, a heroína em (15,15) e o
  orc em (16,15), vizinhos a 2 m: o retorno passa e cada um fica na sua casa.
- O caso 1 → 2 m continua coberto pelo `ordem-mapa-jogavel (e)`, que também passou (ver o registo).

### (c) `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS` (a «ESCALA_BLOQUEADAS» da ordem)
```
✔ CORR7 (c): ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS a subir 1,5 → 2 m — recusada, a sala fica igual, e a batalha continua
✔ CORR7 (c): a descer 2 → 1,5 m, ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS nunca pode disparar — provado por enumeração, confirmado no servidor numa amostra das casas de risco
```
- **A subir.** O orc está na casa (12,11), livre a 1,5 m. A 2 m, essa casa cai na (9,8), que é bloqueada.
  - O pedido dá `ROOM_REJECT`/`acao_invalida`, com o detalhe
    `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: 1 figura ficava em casas que o mapa bloqueia com 2 m por casa — …`. O
    orc vai nomeado em (9,8).
  - Figuras, mapa e vez ficam iguais, e a escala fica a 1,5 m. Ninguém fica numa casa bloqueada e a Party não vê
    o detalhe.
  - Depois da recusa, a batalha continua.
- **A descer.** Há 1.326 casas livres a 2 m e nenhuma cai numa casa bloqueada a 1,5 m (`caem == []` — esta é a
  prova, exaustiva).
  - Contei as casas de risco: livres a 2 m, cuja casa de 1,5 m encosta, pelas 8 vizinhas, a uma casa bloqueada.
    São 92.
  - **No servidor** corre só uma amostra de confirmação: 46 orcs (1 em cada 2 dessas casas) e a heroína numa
    batalha a 2 m, e pedi o retorno a 1,5 m.
  - Resultado: APLICADA, cada figura no mesmo sítio, nenhuma em casa bloqueada e nenhuma recusa `ESCALA_*`.
- A grelha fixa (2 → 1,5 m com 5 recusadas) continua coberta pelo `ordem62`, que também passou.
- **Estatuto da prova «a descer» (CORR7-CORRECOES, R2).** Assenta na enumeração exaustiva + a confirmação no
  servidor. A réplica `noLugar` do teste partilha a fórmula com `casaNoLugar` (`nucleo/sala.js`), por isso o teste
  verifica que o servidor **aplica** a regra do sítio, não a geometria da regra de forma independente.
- **Os números ficam presos ao terreno actual (CORR7-CORRECOES, R1/N1):** o teste exige 1.326 livres, 92 de risco
  e 46 na amostra. O guarda era `risco.length >= 20`, frouxo de propósito por causa da LAGO-MAIOR (que muda o
  terreno); agora é `=== 92`, e quando a LAGO-MAIOR fundir falha de propósito e obriga a refazer a sonda (S1).

### Os testes mordem (controlo negativo) — VERIFICADO
Fiz mutações temporárias em `nucleo/sala.js`, cada uma revertida com `git checkout` antes da seguinte. Nada disto
entrou no commit: `git status nucleo/` ficou vazio. Saída em `mutacoes.log`.

| mutação | falham |
|---|---|
| M1: sem o `throw` de `ESCALA_JUNTA_FIGURAS` | só (b) a subir |
| M2: sem a conferência de casas bloqueadas na grelha-mapa | só (c) a subir |
| M3: mudar a escala pelo índice (sem `casaNoLugar`) | os 6 |

## Suites (passo 3) — VERIFICADO

| suite | base `b7ecadd` | depois |
|---|---|---|
| servidor `node --test testes/` | **403/403** | **409/409** (403 + 6 novos), 0 falhas |
| testes da escala (5 ficheiros) | — | **42/42** |
| cliente `rodar_testes.gd` (Godot 4.7.2 headless, depois de `--import`) | 290 (a da ordem) | **290 de 290 verificações passaram**, código de saída 0, 0 «SCRIPT ERROR / Parse Error / Compile Error» |

Nada partiu.

## Desvios
- **`core.autocrlf`.** O `~/.gitconfig` desta conta tem `core.autocrlf=true`. Com isso, a primeira corrida da
  suite, no clone acabado de fazer, deu uma falha: o `fixture-mestre.test.mjs` compara com o ficheiro gerado e
  falhou por causa dos CRLF.
  - Pus `core.autocrlf=false` **só no `.git/config` do clone**, como o clone da PROVAS-MAPA já tinha, e refiz o
    checkout. Deu 403/403.
  - É ambiente, não código. O CI também corre «sem conversão de fins de linha».
- Os `.uid` que o Godot gerou no `--import` ficaram fora do commit, como nas ordens anteriores.
- As listas da retoma foram refeitas: ver o achado 3.

## O que ficou no commit
- `rascunhos/servidor/testes/ordem-provas-mapa-corr7.test.mjs` (novo): os 6 testes.
- `provas/ordem-provas-mapa-corr7/`: os 6 registos e `ferramentas/sonda-mapeamento.mjs`.
- `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt`: refeitos por `actualizar-listas.py` (o achado 3).
- `ESTADO-FINAL-ORDEM-PROVAS-MAPA-CORR7.md`: este ficheiro.

## Passagem
- **Onde parou:** as provas (a), (b) e (c) estão feitas e empurradas em `claude1/provas-mapa-corr7`, **sem fusão**.
- **Para o coordenador decidir:**
  - o nome «ESCALA_BLOQUEADAS» face a `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS` (achado 1);
  - aceitar que as recusas não se provam no retorno porque não podem acontecer nele (achado 2);
  - a reparação das listas do `d21f734` (achado 3).
- As correcções 8–10 da sentença não foram tocadas.
