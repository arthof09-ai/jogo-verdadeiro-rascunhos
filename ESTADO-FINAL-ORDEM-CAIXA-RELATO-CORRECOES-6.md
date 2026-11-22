# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-6 (as correcções B1–B4 da sentença da CAIXA-RELATO-CORRECOES-5)

**Quem:** Claude, conta 1, no PC (22/11/2026). **Ramo:** `claude1/caixa-relato-correcoes-6`, a partir de `f231847`
(a ponta de `fable/integracao-50` quando clonei). **Não fundi.**
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-6\`. O clone está em `repo\`, a pasta
tmp em `tmp\`.
**Commits:** `acd3c82` tem as correcções e as corridas, com o CI verde: 10/10 jobs, retoma-pc incluído, e a sonda de
privacidade verde. A seguir vem o commit deste ESTADO-FINAL.

A conferência não está neste PC (`~/workspace/conferencias/` não existe aqui). Trabalhei pelo texto da ordem, que
traz os ficheiros e as linhas.

Este ficheiro não cita os nomes verdadeiros nem pedaços deles. Diz só o n.º do nome, a linha e o comprimento.
O conferidor, no critério alargado, dá 0 achados neste ficheiro e na secção nova do README.

## 1. Ponto a ponto

### B1 — a contagem do marcador no ESTADO-FINAL-5 — FEITO, PROVADO (medido)
- **Medido** no registo `provas/ordem-caixa-relato/correcoes-4/mutacoes.log`, que não mudou:
  `grep -c '‹nome verdadeiro›'` → **28** linhas; `grep -o '‹nome verdadeiro›' | wc -l` → **92** ocorrências.
- **Correcção:** `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-5.md`, linha 55. Passa a dizer «aparece em 28 linhas
  (92 ocorrências)», com uma nota de emenda (CORRECOES-6, B1) que diz o que lá estava e como se mediu.

### B2 — o conferidor gera também os pedaços a cavalo de palavras — FEITO, PROVADO (executado)
- **Correcção** (`provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`): aos pedaços que já se geravam (o nome
  inteiro e os pedaços de ≥4 letras dentro de uma palavra só) juntam-se **todos os pedaços contíguos do nome inteiro
  com 4 ou mais letras**, incluindo os que atravessam um espaço. As letras contam-se com `\p{L}`. Os espaços entram no
  pedaço tal como estão no nome, mas não contam para as 4. Com `--velho`, o conferidor usa o critério antigo, para
  comparar. A linha final diz qual dos critérios correu e quantos pedaços gerou.
- **Prova:**

  | ficheiro | critério alargado | critério antigo (`--velho`) |
  |---|---|---|
  | registo regenerado (`correcoes-4/mutacoes.log`, 248 linhas) | **0 achados, rc=0** (151 pedaços) | **0, rc=0** (26 pedaços) |
  | registo antigo (`7ce6df3`, 243 linhas) | 18 achados, rc=1 | 18, rc=1 |
  | linha sintética, em tmp, com um pedaço a cavalo de palavras (o fim de uma palavra, « de », a primeira letra da seguinte) | **4 achados, rc=1** (2 linhas × 2 nomes) | **0, rc=0** — o furo da D2 |

  - Os 18 achados do registo antigo são os mesmos nos dois critérios. A aritmética da sentença continua a fechar.
  - As linhas com os nomes públicos por inteiro continuam a dar 0 nos dois critérios.

### B3 — o `cortar` e os grafemas — FEITO, PROVADO (executado)
- **Correcção** (`correr-mutacoes.sh`, função `cortar`):
  - Documentado: o limite conta **pontos de código, não grafemas**.
  - O corte passa a cair **só entre grafemas** (`Intl.Segmenter("pt", {granularity: "grapheme"})`). Um grafema que não
    cabe inteiro no limite fica todo de fora. A linha nunca passa dos 400 pontos de código, mas pode ficar com menos.
  - Escolhi tornar o corte seguro em vez de só o documentar. Assim o limite continua a ser o mesmo número que o
    cabeçalho e o ESTADO-FINAL-5 dão.
- **Prova:** com as duas funções isoladas (a de `f231847` e a nova) e uma linha de 399 `x` + `e`+U+0301 + `fim`:
  - a antiga dá 400 pontos e termina num `e` **sem** a marca, ou seja, parte o grafema (sem `�`);
  - a nova dá 399 pontos e deixa o grafema todo de fora;
  - nenhuma das duas dá `�`, e a segunda linha passa intacta.
  - Numa linha de 190 `á` + 150 `e`+U+0301, a nova dá exactamente 400 pontos e termina com a marca.
  - O registo cometido, passado pelo `cortar 400` novo, sai igual byte a byte (`cmp`).

### B4 — os `diz` limpos na fonte — FEITO, PROVADO (executado)
- **Correcção** (`provas/ordem-caixa-relato/ferramentas/mutacoes.mjs`), nas linhas 37 e 49 da base (40 e 52 agora,
  depois de 3 linhas de comentário no cabeçalho):
  - `B1-nome-verdadeiro`: «… — o relato traz o nome verdadeiro n.º 1»;
  - `N-B2-canario-minusculas-relato`: «… o relato traz o nome verdadeiro n.º 1 em minúsculas».
  - O n.º 1 é a numeração do conferidor: a ordem do nome entre as fichas com nome ≠ nomePublico.
- **Prova:**
  - `node mutacoes.mjs diz novo|base4 <id>` imprime os textos novos.
  - `mutacoes.mjs` pelo conferidor: antes, 12 achados, 2 deles com o nome inteiro (as linhas 37 e 49). Depois, 8
    achados e **nenhum com o nome inteiro**. Os que ficam são pedaços curtos (4 a 7 caracteres): uma palavra corrente
    do português e o caminho do ficheiro das fichas (`FICHAS`), que não são nomes. O critério estrito acusa-os de
    propósito; o ficheiro é código, não é o registo.
  - Um grep sem distinguir maiúsculas pelas duas primeiras palavras dos nomes verdadeiros dá **0 linhas** no
    `mutacoes.mjs`.
  - **Uma corrida real** das duas mutações, pelo `correr-mutacoes.sh` mudado (modo `novo`, `SO=…`, registo da
    amostra só em tmp):
    - os títulos saem «o nome verdadeiro n.º 1» e «… n.º 1 em minúsculas»;
    - as duas dão **39/43, rc=1**, os mesmos números do registo cometido;
    - o conferidor dá **0 achados** no registo da amostra;
    - os ficheiros tocados voltaram todos ao que eram (`git status` limpo).

## 2. As corridas (Godot 4.7.2 Windows, `Godot_v4.7.2-stable_win64_console.exe`, motor VLAB real `a91c021c…3261`, semente 7)

| Corrida | Resultado | Ficheiro |
|---|---|---|
| Teste do relato | **31/31**, rc=0 | `provas/ordem-caixa-relato/correcoes-6/teste-relato.log` |
| Prova HUD-JOGADORA | **43/43**, rc=0; 68 linhas varridas = 68 no ficheiro; 0 nomes verdadeiros | `correcoes-6/cliente-hud/relato.txt` |
| Prova MANEQUIM | **53/53**, rc=0; 78 = 78; 0 nomes verdadeiros | `correcoes-6/cliente-manequim/relato.txt` |
| Conferidor, critério alargado, registo regenerado | **0 achados**, rc=0, 248 linhas | `correcoes-4/mutacoes.log` |
| Conferidor, critério antigo (`--velho`), registo regenerado | **0 achados**, rc=0 | idem |
| Mutações de amostra (B4) | `B1-nome-verdadeiro` 39/43 · `N-B2-canario-minusculas-relato` 39/43; conferidor 0 | só em tmp |
| CI em `acd3c82` | **10/10 jobs verdes** (servidor, cliente, motor-real, foto-mestre, godot-cliente, protocolo, ponta-a-ponta, provas-mapa, validador-glb, **retoma-pc**); sonda de privacidade verde | — |

O lançador é o de sempre: `correr-prova-caixa-relato.sh … "$PWD/provas/ordem-caixa-relato/correcoes-6"`. Não copia
o PIN nem as capturas para a pasta de saída.

`actualizar-listas` (`python retoma-i0004/actualizar-listas.py`) correu antes do commit `acd3c82` e outra vez antes
do commit deste ficheiro. As duas vezes deu «0 novos, 0 tirados», e o `git status` não mudou. O ramo não toca em
`rascunhos/`.

## 3. Pontos para o coordenador
1. **O registo cometido não foi regenerado.** Os títulos das linhas 17/137 e 55/175 continuam a dizer
   «‹nome verdadeiro›», o marcador do filtro. Uma regeneração nova diria «o nome verdadeiro n.º 1». Os dois estão
   limpos, e a ordem só pedia que o registo continuasse a dar 0, o que dá. Regenerar são 36 corridas, e os
   resultados da amostra batem com os do registo. Se quiseres o registo alinhado com a fonte, é uma ordem pequena.
2. **A base andou durante a ordem.** Clonei com a ponta em `f231847`. Depois entraram `37654b0` e `30a16b5`
   (CAIXA-TESTES-CORRECOES-8: `privacidade.test.mjs`, `retoma-i0004/depois.txt`, …). Não tocam nos meus ficheiros;
   `git merge-tree` com a ponta actual dá zero conflitos. O `depois.txt` da retoma vai ser o dessa linha. Neste ramo
   não mudou.
3. **Ficam textos-fonte com os nomes inteiros, fora do território desta ordem:** o README desta pasta (secção da
   CORRECOES-2, linha 96) e o §3.2 do ESTADO-FINAL da CORRECOES-4 citam-nos. São valores-canário fictícios, e a ordem
   nomeou só o `mutacoes.mjs`. Não lhes toquei.
4. **Cuidado ao correr as mutações:** a pasta tmp tem de ser um caminho **absoluto**. O `--saida` da prova é lido a
   partir de `rascunhos/cliente`; com um caminho relativo, as saídas vão parar a `rascunhos/tmp/`. Aconteceu-me numa
   primeira tentativa. Apaguei essa pasta (não estava no git) e corri de novo. Ficou escrito no README.
5. **Fronteira:** mexi só em `provas/ordem-caixa-relato/` (`conferir-registo.mjs`, `correr-mutacoes.sh`,
   `mutacoes.mjs`, README, `correcoes-6/` nova), na linha 55 do ESTADO-FINAL da CORRECOES-5 e neste ficheiro. Não mexi
   no código do jogo, no HUD, nas cores, no workflow nem em `rascunhos/`. Não mexi no `ORDEM.md` da sede.
