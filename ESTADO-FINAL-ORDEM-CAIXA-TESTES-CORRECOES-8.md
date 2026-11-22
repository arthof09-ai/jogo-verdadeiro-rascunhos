# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-8 (Claude conta 2, PC) · 22/11/2026

Fecha as correcções **B1–B3** da sentença da CAIXA-TESTES-CORRECOES-7. Só mudou texto: o comentário de `historicoVida`
em `rascunhos/servidor/testes/privacidade.test.mjs`, o `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-7.md`, as listas da
retoma e este ficheiro. Nenhuma linha de código mudou. Não toquei em código do jogo, no HUD, nas cores, no protocolo nem
na prova.

- **Base:** `origin/fable/integracao-50` @ `8267dc3` (a ponta à hora do lançamento; a CORRECOES-7 já está lá, em
  `ba56b7e`). Clone novo, `core.autocrlf=false`.
- **Ramo:** `claude2/caixa-testes-correcoes-8`, **não fundido** (a fusão é do coordenador).
- **Commits, por ordem:**
  1. `a7d89b0`: o comentário do teste e o ESTADO-FINAL-7.
  2. As listas da retoma e este ficheiro. Corri `actualizar-listas.py` depois do commit 1.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-7/` não está neste PC. Trabalhei pelo texto da
  ordem, que traz as frases exactas, e conferi cada afirmação no código.

## Ponto a ponto

### B1: a frase da fixture (ESTADO-FINAL-7, ponto 2 para o coordenador)
**Prova:**
- `testes/fixture-mestre.test.mjs`, teste 1 («o ficheiro guardado é o que o servidor gera hoje»):
  `assert.equal(guardado, texto)`, com `texto = JSON.stringify(gerar(), null, 1) + '\n'`. Compara a string JSON
  inteira, por isso uma mudança só de valor também a faz falhar. «Não o valor» era falso.
- `gerar()` guarda as mensagens da jogadora só do `cenarioDesgraca()` (`jogadora: { mensagens: d.jogadora }`). Medido
  em `dados-exemplo/mesa-mestre.json`: 14 mensagens da heroína, das quais **1** `ROOM_SNAPSHOT`. «Qualquer chave nova»
  era demasiado largo: fora desse cenário a fixture não vê nada.

**Corrigido:** o texto antigo ficou riscado e, por baixo, com nota datada, a frase da sentença: «a fixture compara o
ficheiro inteiro do cenário da desgraça — qualquer mudança (chave ou valor) nas mensagens da jogadora aí guardadas
fá-la falhar; fora desse cenário não vê nada; e não distingue fuga de mudança legítima, por isso não é guarda.» A
conclusão (não é guarda) fica igual.

### B2: o 51 no inventário do comentário
**Prova:** o inventário da CORRECOES-7 (ESTADO-FINAL-7, B2) já registava o 51 em `vidaActual`, só nas mensagens da
própria aliada, no guião da M51b. O histórico da aliada nesse guião é `51, 1227, 2403, 3579`. O 51 é o único valor do
histórico abaixo de 100.

**Corrigido:** no comentário de `historicoVida`, a seguir à lista das colisões, entrou: «e o 51 (`vidaActual`), só nas
mensagens da própria aliada no guião da M51b — é dela, não é colisão (CAIXA-TESTES-CORRECOES-8, B2).»

### B3: «emite só `revertido` (`{ ateSeq }`)»
**Prova** (`nucleo/sala.js`, só leitura):
- `voltar` (l. 3190): emite `cartao_fechado` para os cartões abertos nascidos depois de `ateSeq` (l. 3208),
  `revertido` (l. 3212) e `cartao` para os cartões reabertos (l. 3227). Não chama `emitirEstado`.
- `recomecarBatalha` (l. 2887): emite `recomeco` (l. 2920). Também fecha os cartões abertos (`fecharCartoesAbertos`,
  `cartao_fechado`) e abre a vez (`iniciarVez`, `turno`). O `emitirEstado` de `iniciarVez` só corre para uma figura
  `caido`, e a `novaFigura` (l. 549) põe `caido: false`. O fogo é limpo antes, por isso o tick não deita ninguém.
  Nenhum `estado`.
- O `revertido` sai com `tx.emitir('revertido', {}, { ateSeq })`: os dados do evento são `{}`. O `(`{ ateSeq }`)` do
  texto antigo também não era exacto. Saiu.

**Corrigido**, nos dois sítios:
- **ESTADO-FINAL-7, B3:** as duas linhas antigas ficaram riscadas. Por baixo, com nota datada: «o «voltar» emite
  `revertido` (mais `cartao_fechado`/`cartao` para os cartões) e o «recomeçar» emite `recomeco`, nenhum emite
  `estado`».
- **Comentário de `historicoVida`:** «emitem só `revertido` / `recomeco`» passou a «o «voltar» emite `revertido` (mais
  `cartao_fechado`/`cartao` para os cartões) e o «recomeçar» emite `recomeco`, nenhum emite `estado`». O resto do
  parágrafo (porque é que hoje não abre buraco no histórico) fica.

**Privacidade:** não houve fuga nem mutação nesta ordem. Os números citados (51, 1227, 2403, 3579, 5150) são os
valores-canário de bancada das fichas de teste.

## Números das corridas (PC, Node 26.13.0, sobre `8267dc3` + `a7d89b0`)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` | **420/420**, 0 falhas, 0 cancelados, 0 saltados |
| `node --test --test-isolation=none testes/privacidade.test.mjs` | **10/10** |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (não tocada) |
| `actualizar-listas.py` depois do commit 1 | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)`; mudaram `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt` (a linha do `privacidade.test.mjs`) |

## Pontos para o coordenador

1. **B1–B3 são só texto.** A suite fica 420/420, como na base.
2. **B3, mais um pormenor:** o «recomeçar» também emite `cartao_fechado` (cartões abertos) e `turno` (a vez nova).
   Usei a frase da sentença, que não nega isto. A afirmação operativa (nenhum `estado`) verifica-se no código.
3. O CI deste ramo não está registado aqui, porque o commit das listas é o último, como a ordem pede.
4. O `ORDEM.md` da sede não foi tocado, como na C5–C7: a última linha é a instrução que contém «Estado: NOVA».
