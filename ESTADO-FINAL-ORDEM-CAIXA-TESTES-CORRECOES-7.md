# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-7 (Claude conta 1, PC) · 22/11/2026

Fecha as correcções **B1–B3** da sentença da CAIXA-TESTES-CORRECOES-6. Em `rascunhos/` mudou só o comentário de
`historicoVida` em `privacidade.test.mjs`; nenhuma linha de código mudou. Fora de `rascunhos/` mudaram
`ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-6.md` (B1, B2), as listas da retoma e este ficheiro. Não toquei em código do
jogo, HUD, cores, protocolo nem na prova.

- **Base:** `origin/fable/integracao-50` @ `7ce6df3` (a ponta à hora do lançamento). Clone novo, `core.autocrlf=false`.
- **Ramo:** `claude1/caixa-testes-correcoes-7`, **não fundido** (a fusão é do coordenador).
- **Commits, por ordem:**
  1. `cee6b39`: o comentário do teste e o ESTADO-FINAL-6.
  2. As listas da retoma e este ficheiro. Corri `actualizar-listas.py` depois do commit 1.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-6/` não está neste PC nem no repositório. Trabalhei
  pelo resumo da ordem e conferi cada número com uma execução.
- **Guiões e logs** (na sede, fora do repo, `tmp/`):
  - `mutar.py`: o da CORRECOES-6, apontado para esta sede, com a «antiga» = `a12b905` (a de antes da CORRECOES-6 nesta
    linha), mais a lista das falhas da suite inteira e as variantes «c» da B1;
  - `mutar.log`: as 14 mutações da CORRECOES-6, re-medidas;
  - `mutar-condicional.log`: as 8 linhas com fuga, na variante «c»;
  - `inventario-anexo.mjs` e `inventario.log`: o inventário da B2.
- Os dois `mutar` acabaram com `nucleo limpo: True` e `teste novo reposto: True`. O ficheiro temporário do inventário
  foi apagado e `git status` ficou limpo.

## Ponto a ponto

### B1: a coluna «Suite nova» das linhas com fuga, na tabela das mutações do ESTADO-FINAL-6
**Os números escritos aguentam-se.** São os do log do PC, e re-medi-os pelo mesmo método (`tmp/mutar.log`):

| Linha | Escrito no ESTADO-FINAL-6 | Re-medido (PC, a mesma fuga) | Chave só com valor | Medido pela conferência |
|---|---|---|---|---|
| M18 | 417/420 | 417/420 | 418/420 | 418/420 |
| M18v | 417/420 | 417/420 | 418/420 | — |
| M20 | 417/420 | 417/420 | 418/420 | — |
| M20v | 417/420 | 417/420 | 418/420 | — |
| M20-semRESYNC+M18 | 417/420 | 417/420 | 418/420 | — |
| M51-controlo | 418/420 | 418/420 | 419/420 | 419/420 |
| M51b | 417/420 | 417/420 | 418/420 | 418/420 |
| M51-fim+M51 | 416/420 | 416/420 | 417/420 | 417/420 |

As linhas sem fuga dão o mesmo que estava escrito: base, M20-controlo, M20-semRESYNC e M51b-sem-fuga 420/420; M51-fim e
corte-100 419/420.

**A fuga real, e a diferença de 1.** Em todas as linhas com fuga, a suite do PC tem **mais uma falha, que não é da
privacidade**: `fixture-mestre.test.mjs`, «fixture do ecrã do Mestre: o ficheiro guardado é o que o servidor gera
hoje». A fuga do `mutar.py` (`sala.js`, `mensagemSnapshot`) junta a chave `fugaB1` (ou `vidaActual`) a **todos** os
ROOM_SNAPSHOT da Party, mesmo quando o array vai vazio (`fugaB1: []`). Isso muda as mensagens da jogadora que a fixture
`mesa-mestre.json` guarda.

Na variante «c» (`...(_fuga.length ? { fugaB1: _fuga } : {})`, a chave só quando há valor), a fixture passa. A suite
dá então os quatro valores da conferência, e as falhas são só as da privacidade (`tmp/mutar-condicional.log`):
- 418: o teste da Vida e o da M51b;
- 419: só o da M51b;
- 417: «nada do Mestre», o teste da Vida e o da M51b.

A `privacidade` nova e a antiga dão os mesmos números nas duas variantes, linha a linha.

**Corrigido no ESTADO-FINAL-6:**
- os números ficam (são os do log), marcados com (¹);
- há uma nota datada (¹) abaixo da tabela-resumo, com a fuga real, a falha da fixture e a tabela das duas variantes;
- as tabelas da B1 e da B2 do ESTADO-FINAL-6 remetem para essa nota.

Como a sentença diz, era defeito do relatório e não do ramo: a suite está a 420/420.

### B2: o parágrafo do filtro, reescrito com o inventário medido
**O inventário** (`tmp/inventario.log`; todos os números < 100 que chegam a cada papel, nos dois guiões, `guiao()` e
`guiao({ m51b: true })`):

| Valor | Chaves não-isentas que o levam às jogadoras |
|---|---|
| **0** | `geral` (em **6/6** snapshots de cada jogadora no guião de sempre; **8/8** no da M51b) |
| 2 | `custoPA`, `protocolo`, `v` |
| 3 | `custoM` |
| 6 | `custoM` |
| 9 | `alcanceM`, `custoM`, `deslocamentoBase`, `orcamentoM` |
| 14 | `constituicao` |
| 18 | `faces` |
| 20 | `altura`, `largura` |
| 23 | `total` |

Há também não-inteiros (1.5, 2.625, 4.5, 7.5). O 51 aparece em `vidaActual`, mas só nas mensagens da própria aliada,
no guião da M51b. O espectador recebe só 1.5, 2 e 20, e nenhum `geral`. Sob as chaves isentas (`seq`, `revision`,
`rodada`, `x`, `y`) chegam de 0 a 38, e o varredor isenta-as abaixo de 100.

**Corrigido:** «o 0 é o único valor que colide» não aguenta o inventário. O 2, 3, 6, 9, 14, 18, 20 e 23 também
colidem. O 0 é só o único que **tem de ser excluído**, por duas razões que se juntam:
- é uma Vida alcançável (a de quem cai);
- o `geral: 0` vai em todos os snapshots das jogadoras, por isso com o 0 no histórico a guarda falhava sempre.

Os outros só colidem se a Vida de uma jogadora passar por eles, e hoje não passa (o histórico é `5150` para a heroína e
`2403, 3579` ou `51, 1227, 2403, 3579` para a aliada). Os contadores e coordenadas a 0 não colidem: são isentos.

O parágrafo foi reescrito no comentário de `historicoVida` (`privacidade.test.mjs`) e riscado e corrigido, com nota
datada, no ESTADO-FINAL-6 (B1). Fica a regra: se um valor baixo colidir, a falha é alta e muda-se o guião, não o corte.

### B3: «regista cada mudança da Vida»
**Verificado em `nucleo/sala.js`** (só leitura):
- ~~`voltar` emite só `revertido` (`{ ateSeq }`), mais um `cartao_fechado` para os cartões que nasceram depois. Repõe a
  Vida do checkpoint sem `estado`.~~
- ~~`recomecar` emite só `recomeco` (`{}`). Repõe a Vida máxima pela `novaFigura`, sem `estado`.~~
- **Corrigido na CAIXA-TESTES-CORRECOES-8 (B3), 22/11/2026:** o «voltar» emite `revertido` (mais
  `cartao_fechado`/`cartao` para os cartões) e o «recomeçar» emite `recomeco`, nenhum emite `estado`. O «voltar» repõe a
  Vida do checkpoint; o «recomeçar» repõe a Vida máxima pela `novaFigura`.
- O `estado` vem de `emitirEstado`, chamado pelas acções do jogo.

**Corrigido:** o comentário já não diz que o `estado` regista cada mudança. Diz que o «voltar» e o «recomeçar» mudam a
Vida sem `estado`, e porque é que hoje isso não abre buraco no histórico: o «voltar» repõe a Vida de um instante
anterior do guião, o «recomeçar» repõe a máxima (que é a de partida, já no histórico), e a Vida do fim entra sempre pelo
estado da sala.

**Privacidade:** não há fuga viva. As fugas M18, M18v e M51 (e as variantes «c») foram temporárias e revertidas
(`nucleo limpo: True`). Os números são os valores-canário de bancada das fichas de teste.

## Números das corridas (PC, Node 26.13.0, sobre `7ce6df3` + este ramo)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` | **420/420**, 0 falhas, 0 saltados |
| `node --test --test-isolation=none testes/privacidade.test.mjs` | **10/10** |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (não tocada) |
| `actualizar-listas.py` depois do commit 1 | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados)`; mudaram `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt` (a linha do `privacidade.test.mjs`) |

## Pontos para o coordenador

1. **B1 foi fechada pelos logs, sem mudar números.** A diferença de 1 para a conferência é a fixture do Mestre, que a
   fuga «chave sempre presente» do `mutar.py` também parte. Ficam as duas colunas no ESTADO-FINAL-6. Se a M18/M51 da
   conferência puser a chave só quando há valor, a conferência e o PC batem certo, linha a linha.
2. **A fixture como detector, só de passagem.** ~~`fixture-mestre` apanha qualquer chave nova no snapshot da jogadora,
   mesmo vazia, mas não o valor. Não é guarda de privacidade e não conta como tal.~~
   **Corrigido na CAIXA-TESTES-CORRECOES-8 (B1), 22/11/2026:** a fixture compara o ficheiro inteiro do cenário da
   desgraça — qualquer mudança (chave ou valor) nas mensagens da jogadora aí guardadas fá-la falhar; fora desse cenário
   não vê nada; e não distingue fuga de mudança legítima, por isso não é guarda.
3. **A fragilidade do guião** (duas voltas sem «voltar» partem «a ordem no snapshot do escolherCaixa») fica, como
   decidido, para uma ordem futura. Aparece outra vez aqui, na M51-fim e na M51-fim+M51.
4. **O ESTADO-FINAL-4 l. 42** fica como registo histórico, como decidido.
5. O CI deste ramo não está registado aqui, porque o commit das listas é o último, como a ordem pede.
6. O `ORDEM.md` da sede não foi tocado. Já termina com a linha do estado.
