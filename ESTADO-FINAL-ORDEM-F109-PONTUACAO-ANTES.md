# ESTADO-FINAL — Ordem F109 (J9-antes: pontuação antes da palavra do meio, da sentença da F88–F96)

**Estado: FEITA, pela rota 1 (fechar).** A rede apanha agora a pontuação **antes** da palavra do meio: **«X, du Y»
passa de rc=0 a rc=3**. O auto-teste ganhou o caso de guarda e passa de **29/29 para 30/30** (ver §0: a base na
partida era 29/29, não 28/28). Os casos já fechados não mudaram. A reprodução continua **10/11, com a mesma linha 6**,
o canário continua **26/26** e igual byte a byte, e o CI da ponta da obra deu ****10/10 jobs verdes + Sonda verde****.

- **Executor:** Claude (opus, esforço médio), PC do cunhado, conta 2. **Data:** 23/11/2026.
- **Linha:** `fable/integracao-50`, trabalho directo, sem ramos laterais. Clone novo e limpo em
  `ordem-f109-pontuacao-antes-pc/repo`.
- **`HEAD` de partida:** `a7e027b` (o ESTADO-FINAL da F125). Antes do push, o remoto tinha avançado um commit, para
  `1e6c56e` (a nota do CI da F125, que só acrescenta 8 linhas ao ESTADO-FINAL da F125). Pus o commit da obra por
  cima, sem merge, e voltei a correr o auto-teste (30/30). **A obra assenta em `1e6c56e`.**
- **A ponta traz** a F114 (`5554637`), a F116 (`209bbf8`), a F52 (`5a906cf`, `697f90c`) e a F125 (`307b6e7`).
- **Biblioteca (GameDev Kit):** não construí nada de raiz. A obra alarga um padrão que já existe e junta 1 caso ao
  auto-teste que já existe.
- **A sentença** (`~/workspace/conferencias/f88-f96-redigir-nomes/SENTENCA-F88-F96-REDIGIR-NOMES.md`) e o JUIZ **não
  estão neste PC**: não há `~/workspace`, como as F52, F108 e F116 já registaram. Segui o resumo da ordem e o §7.4
  do `ESTADO-FINAL-ORDEM-F88-F96-REDIGIR-NOMES.md` («A pontuação antes dela, como em «X, du Y», não é apanhada»).
  Ver o ponto aberto 1.

## 0. A base na partida: 29/29, não 28/28

A ordem esperava 28/28 (a base da F114). Na ponta `a7e027b` o auto-teste deu **29 de 29**, rc=0. A diferença é a
F116 (`209bbf8`), que juntou depois da F114 o caso da linha só de espaços (28 → 29). A F125 não mexeu no auto-teste
(o ESTADO-FINAL dela diz 29/29). A ordem pede **1 caso a mais**, por isso o total passa a **30/30**, e não a 29/29.
Não é uma decisão nova: o número da ordem foi escrito antes da F116. Fica registado para o coordenador confirmar
(ponto aberto 2).

## 1. A rota e porquê

**Rota 1 (fechar).** O alargamento é directo. O lado de **depois** da palavra do meio já aceitava «pontuação colada,
e a seguir no máximo um `\n`». Bastou dar ao lado de **antes** a mesma alternativa. Mediu-se primeiro, numa cópia, e
nada mais mudou:

- os casos já fechados dão as mesmas contagens (tabela do §3);
- a linha em branco e a linha só de espaços continuam barradas;
- no corpus, nada mudou: **1388 ficheiros de texto** do repo (todos os do `git ls-files` que não são binários), com
  **0 variantes com o padrão antigo e 0 com o novo**, e nenhum ficheiro mudou de contagem;
- nos 11 registos crus da F25, a rede continua a dar 0 nos 11.

Não marquei nada como «AINDA ABERTO»: **a rota 2 ficou de fora**.

## 2. O padrão, antes e depois

`provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs`, função `reVariantesFora`.

**Antes** (linha 162 da `1e6c56e`):

```js
    res.push(new RegExp(`(?<!\\p{L})${antes}${S}[\\p{L}'’]+(?:-[\\p{L}'’]+)*(?:\\p{P}+[^\\S\\n]*\\n?[^\\S\\n]*|${S})${depois}(?!\\p{L})`, 'giu'));
```

**Depois** (linhas 163–166 da `8ac126c`: 2 linhas de comentário, a constante `P` e o padrão):

```js
    // F109 (J9-antes, sentença da F88–F96): a pontuação também pode vir ANTES da palavra do meio («X, du Y»), com a
    // mesma forma da de depois (pontuação colada, e a seguir no máximo um `\n`).
    const P = '\\p{P}+[^\\S\\n]*\\n?[^\\S\\n]*';
    res.push(new RegExp(`(?<!\\p{L})${antes}(?:${P}|${S})[\\p{L}'’]+(?:-[\\p{L}'’]+)*(?:${P}|${S})${depois}(?!\\p{L})`, 'giu'));
```

A pontuação do lado de depois é o mesmo texto que estava escrito à mão: só passou para a constante `P`. O `S` da F114
(linha 161) não mudou. Também acertei três comentários do mesmo ficheiro:

- o cabeçalho da saída 3 (linha 22);
- a nota do J9 na F94 (linhas 134–135);
- a lista das dependências das fichas da F96 (linhas 344–345).

## 3. O que mudou e o que ficou igual (medido)

Montei os casos em memória, a partir das fichas, com o padrão antigo (`1e6c56e`) e com o novo. A tabela dá as
contagens da rede sobre o texto já redigido: inteiros | variantes | cortes | sem a preposição, e a linha. O guião
está no `tmp/` da ordem e só imprime etiquetas e números.

| caso | antigo | novo |
|---|---|---|
| **«X, du Y»** (o caso da ordem) | 0\|0\|0\|0 | **0\|1\|0\|0, linha 1** |
| «X,du Y» (sem espaço) | 0 | **1**, linha 1 |
| «X; du Y» | 0 | **1**, linha 1 |
| «X. Du Y» | 0 | **1**, linha 1 |
| «X, du, Y» (pontuação nos dois lados) | 0 | **1**, linha 1 |
| «X, ⟨preposição verdadeira⟩ Y» | 0 | **1**, linha 1 |
| «X,» no fim da linha e «du Y» na seguinte | 0 | **1**, na linha onde começa |
| «X,», linha em branco, «du Y» | 0 | **0** (a travagem da F114 vale também aqui) |
| «X, », linha só de espaços, «du Y» | 0 | **0** (a guarda da F116 vale também aqui) |
| «X , du Y» (espaço antes da vírgula) | 0 | 0 (ponto aberto 3) |
| J9: «X du, Y», «X d. Y», «X du;Y» | 1 por caso | 1 por caso |
| J10: «X» \n «⟨prep⟩ Y»; «X du» \n «Y» | 1 por caso | 1 por caso |
| F66: «X du Y» | 1 | 1 |
| F89 AINDA ABERTO: «X du la Y» | 0 | 0 |
| o nome público, vírgula, palavra corrente | 0 | 0 |

**A linha de comandos.** Fiz uma entrada de 1 linha em `tmp/`:

| entrada | ferramenta velha | ferramenta nova |
|---|---|---|
| «X, du Y» | **rc=0** | **rc=3** (a linha de contagens diz «1 variante(s) de preposição fora da lista (linhas 1)») |
| «X du, Y» (J9 depois) | rc=3 | rc=3 |
| «X du Y» | rc=3 | rc=3 |

## 4. O caso novo e o que afirma

No auto-teste, linhas 381–384, logo a seguir ao caso da F116. Monta-se em memória a partir das fichas, como os outros:
`x «<início do nome n.º 1>, du <apelido>» y`.

**O que afirma:**

- o texto **não se redige** (fica igual);
- a rede dá **0 inteiros, 1 variante, 0 cortes, na linha 1**;
- há suspeitos, ou seja, **saída 3**.

A descrição no auto-teste: «F109 (J9-antes): a variante do nome n.º 1 com pontuação antes da palavra do meio
(«X, du Y») não se redige, mas a rede apanha-a: 1 variante, linha 1 → saída 3».

**O caso tem dentes.** Fiz um mutante fora do repo (`tmp/mutante.mjs`): a ferramenta nova, com o lado de antes do
padrão posto como era (`${antes}${S}`). Deu **29 de 30**, e só falha o caso novo. Com a ferramenta cometida dá
**30 de 30**, rc=0.

## 5. O README

Em `provas/ordem-caixa-relato/README.md`:

- **no J9** (linhas 526–529): «**Desde a F109** (sentença da F88–F96), também com a pontuação logo **antes** da
  palavra do meio («X, du Y», «X,du Y», «X; du Y»): a pontuação vem colada ao que está antes, e a seguir pode vir no
  máximo uma quebra de linha, como depois»;
- nos usos, «corre **30** verificações» (eram 29);
- na lista do que o auto-teste cobre, uma linha «desde a F109 (J9-antes)»;
- na lista das dependências das fichas (F96), o caso novo também precisa de o nome n.º 1 ter uma preposição da lista
  no meio.

## 6. Os números, antes e depois

| prova | antes (`a7e027b` / `1e6c56e`) | depois (`8ac126c`) |
|---|---|---|
| auto-teste do `redigir-nomes` (PC) | **29/29**, rc=0 (§0) | **30/30**, rc=0 |
| «X, du Y» pela linha de comandos (PC) | rc=0 | **rc=3** |
| reprodução da F51 (`reproduzir-redaccao-f25.sh`, PC) | 10/11, linha 6 (3500 contra 3473 bytes), rc=1; a rede dá 0 nos 11 | **10/11, a mesma linha 6** (3500 contra 3473 bytes), rc=1; a rede dá 0 nos 11. A saída do guião é **idêntica** à de antes, linha a linha (tirando a linha «base:») |
| canário `teste_nomes_relato.gd` (PC, Godot 4.7.2 Windows) | 26/26 (F125) | **26/26**, rc=0, 0 `SCRIPT ERROR`/`Parse Error`/`Compile Error` |
| a saída do canário redigida contra o registo limpo (PC) | igual (3473; 3437 sem os CR) | **igual byte a byte (3473 bytes; 3437 sem os CR)** |
| corpus (todos os ficheiros de texto do repo) | 0 variantes | **0 variantes** (1388 ficheiros, nenhum muda) |
| `rodar_testes` (CI, `cliente` e `godot-cliente`) | 321/321 | **321/321** nos dois |
| `caixa_janela` (CI) | 123/123 | **123/123** |
| `caixa_jogadora` (CI) | 70/70 | **70/70** |
| mutação da CAIXA-JANELA-CI (CI) | 114/123 | **«114 de 123»**, «MUTACAO APANHADA: 9 falhas, todas do assert B6» |
| CI | Testes 45187552764 + Sonda 45187552486 (ponta `1e6c56e`, verdes) | **Testes 45188278676 + Sonda 45188278485: 10/10 jobs verdes e a Sonda verde** |

**Não exigi 11/11 nem mudei o alvo da comparação**, como a ordem manda: o ponto aberto 2 da F97 é do coordenador
(F122).

**Uma nota sobre o canário.** No PC, a saída crua do canário dá «0 redigidas, 0 nomes inteiros». É igual, sem os CR,
à saída crua que a F125 guardou no `tmp/` dela. Também a F116 obteve o mesmo, por isso não vem da mudança feita aqui.

**O CI da ponta da obra (`8ac126c`).** Os 10 jobs verdes são `servidor`, `validador-glb`, `motor-real`,
`protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`. Li o
log do job `cliente` (job 137739524739, 2154 linhas). O passo da F51 correu:

- «auto-teste do redigir-nomes: **30 de 30** verificações passaram»;
- o registo da COBERTURA-CORRECOES-6 «**igual byte a byte** ao redigido (3437 bytes, sem os CR)»;
- o canário deu «26 de 26».

O log tem 13 linhas com «FALHA», as mesmas 13 do log da F125: 9 são da mutação esperada (o assert B6, «8/12/16
figuras … os 4 slots»), e 4 são linhas «ok» cujo texto diz que a varredura ou o canário «FALHA».

**Nomes inteiros nos logs do CI:** 0 + 0 no log do `cliente` e 0 + 0 no do `godot-cliente` (job 137739524202). Contei
os dois nomes das fichas, sem distinguir maiúsculas, nos logs descarregados para o `tmp/`, fora do repo.

## 7. A privacidade, re-derivada

- **0 nomes verdadeiros inteiros** nos ficheiros cometidos por esta ordem: a ferramenta, o README e este
  ESTADO-FINAL. Contei com o `suspeitos()` da ferramenta.
- **0 valores de PIN.** Esta ordem não usa PIN: não arranquei o servidor, e não há nenhum `--pin=` com valor nestes
  ficheiros.
- **O conferidor** (`conferir-registo.mjs`, critério alargado / antigo):
  - a ferramenta dá **2/2** e o README **34/30**, os mesmos números da ponta de partida (medi as cópias de antes,
    no `tmp/`);
  - este ESTADO-FINAL dá **0/0**. Para lá chegar reescrevi três frases em que palavras correntes batiam, a cavalo
    de palavras, com 4 letras seguidas de um nome das fichas.
- **Ficou fora do repo**, no `tmp/` da pasta da ordem:
  - as cópias de antes da ferramenta e do README;
  - os guiões de medida e o mutante;
  - as entradas de 1 linha;
  - os registos crus da reprodução (com os nomes);
  - os logs do canário e os do CI.

**SHAs e listas da retoma.** Mudaram dois ficheiros: `redigir-nomes.mjs` e o README do `ordem-caixa-relato`. Procurei
no repo os sha256 e os blobs de antes dos dois (`dd9efdb8…`/`609ef453…` e `6d5ddc94…`/`75f02faf…`) e não os
encontrei. O `MANIFESTO-SHA256.txt` e as listas da retoma não citam nenhum dos dois. **Não havia nada a sincronizar.**

## 8. Pontos abertos

1. **A sentença da F88–F96 e o JUIZ não estão neste PC.** Li o D-J5 pelo resumo da ordem: «pontuação antes da
   palavra do meio», «X, du Y» → rc=3. Se a sentença pedir mais (por exemplo, o espaço antes da pontuação, ponto 3),
   o coordenador confirma.
2. **A base era 29/29, não 28/28** (§0). O caso novo leva o total a 30/30. Se o coordenador quiser outra contagem, é
   ele que decide.
3. **«X , du Y» (espaço antes da vírgula) continua a dar 0.** O lado de depois tem o mesmo limite: «X du , Y» também
   dá 0 desde a F94. Fechei «X, du Y» com a mesma forma do lado de depois (a pontuação colada), como a ordem pede.
   Alargar os dois lados ao espaço antes da pontuação seria outra ordem. Não o marquei «AINDA ABERTO» no README, para
   não misturar as duas rotas no mesmo buraco. Se a conferência o quiser marcado ou fechado, é uma linha.
4. **A reprodução continua 10/11** (o ponto aberto 2 da F97; a decisão do alvo é da F122).

## 9. Commits

1. `8ac126c`: a obra (o padrão, o caso novo, os comentários e o README), sobre `1e6c56e`.
2. Este ESTADO-FINAL, sobre `8ac126c`.
3. A nota do CI da ponta do commit 2, acrescentada no fim deste ficheiro.
