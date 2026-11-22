# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-9 (Claude conta 2, PC) · 22/11/2026

Fecha as correcções **B1–B3** da sentença da CAIXA-TESTES-CORRECOES-8. Só mudou texto: o comentário de `historicoVida`
em `rascunhos/servidor/testes/privacidade.test.mjs`, o `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-7.md`, o
`ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-8.md`, as listas da retoma e este ficheiro. Nenhuma linha de código mudou.
Não toquei em código do jogo, no HUD, nas cores, no protocolo nem na prova.

- **Base:** `origin/fable/integracao-50` @ `6148f79` (a ponta à hora do lançamento; a CORRECOES-8 já está lá, em
  `37654b0` + `30a16b5`). Clone novo, `core.autocrlf=false`.
- **Ramo:** `claude2/caixa-testes-correcoes-9`, **não fundido** (a fusão é do coordenador).
- **Commits, por ordem:**
  1. `2eee882`: o comentário do teste, o ESTADO-FINAL-7 e o ESTADO-FINAL-8.
  2. As listas da retoma e este ficheiro. Corri `actualizar-listas.py` depois do commit 1.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-8/` não está neste PC. Trabalhei pelo texto da
  ordem, que traz as frases exactas, e conferi cada afirmação no código (`nucleo/sala.js`, só leitura).

## Ponto a ponto

### B1 (D1): o que o «recomeçar» emite, nos dois sítios
**Prova** (`recomecarBatalha`, l. 2887):
- `fecharCartoesAbertos(tx)` (l. 2854) → `fecharCartao(tx, c, 'revertido')` para cada cartão `aberto`: emite
  `cartao_fechado` só quando há cartões abertos.
- `tx.emitir('recomeco', {}, null)` e logo `iniciarVez(...)` (l. 1414), que emite `turno` (l. 1429) sempre: o fogo foi
  limpo antes (`m.fogo = Amb.fogoVazio()`), por isso o `tickAmbiente` não devolve `'caiu'` e não salta o `turno`.
- Nenhum `estado` (ver B2 para o porquê dentro de `iniciarVez`).

**Corrigido:**
- **Comentário de `historicoVida`:** passou a «o «voltar» emite `revertido` (mais `cartao_fechado`/`cartao` para os
  cartões) e o «recomeçar» emite `recomeco` (mais `cartao_fechado` para os cartões abertos e `turno` para a vez nova),
  nenhum emite `estado`». O cabeçalho do parágrafo regista «e na CAIXA-TESTES-CORRECOES-9 (B1)».
- **ESTADO-FINAL-7, B3:** a frase da CORRECOES-8 ficou riscada (as duas frases sobre o que cada um repõe ficam). Por
  baixo, com nota datada («Completado na CAIXA-TESTES-CORRECOES-9 (B1), 22/11/2026»), a frase completa da ordem.

### B2 (D2): a justificação do ESTADO-FINAL-8, B3
**Prova:**
- `novaFigura` (l. 543–554; a l. 549 tem `vidaActual: ficha.vidaTotal, paGasto: 0, vivo: true, caido: false,
  estadoMorte: null`).
- Em `iniciarVez` há dois caminhos para `emitirEstado`: o da figura caída (`if (f.caido)`, `emitirEstado` na l. 1447) e
  o do teste de morte (`f.lado === 'jogadora' && f.estadoMorte?.fase === 'aMorrer'` → `testeDeMorte`, que chama
  `emitirEstado(tx, f, true)` na l. 1494). O `caido: false` fecha o primeiro; o `estadoMorte: null` fecha o segundo. O
  ramo `jogadoraForaDeCombate` não emite nada.

**Corrigido:** no ESTADO-FINAL-8, B3, a frase «O `emitirEstado` de `iniciarVez` só corre para uma figura `caido`, e a
`novaFigura` (l. 549) põe `caido: false`.» ficou riscada. Por baixo, com nota datada («Corrigido na
CAIXA-TESTES-CORRECOES-9 (B2), 22/11/2026»): a `novaFigura` repõe `caido: false` **e** `estadoMorte: null`, fechando
também o caminho do teste de morte (`sala.js` l. 1494).

### B3 (D3): a frase da fixture (ESTADO-FINAL-7, ponto 2 para o coordenador)
**Prova:**
- `testes/fixture-mestre.test.mjs`, teste 1: `assert.equal(guardado, texto)`, com `texto = JSON.stringify(gerar(),
  null, 1) + '\n'`. Compara o ficheiro inteiro.
- `gerar()` guarda 5 cenários: `mestre` (desgraça + `cartoes.ia` + `cartoes.dados`), `lobby`, `agir`, e
  `jogadora: { mensagens: d.jogadora }`, só do `cenarioDesgraca()`. Chaves de topo de `dados-exemplo/mesa-mestre.json`:
  `origem, canarios, mestre, lobby, agir, jogadora`. «Fora desse cenário não vê nada» só vale para as mensagens da
  jogadora.

  **Precisado na CAIXA-TESTES-CORRECOES-10 (B2), 22/11/2026:** a enumeração acima lê-se como 4 itens. Os 5 cenários
  são as 5 funções que `gerar()` corre:
  1. `cenarioDesgraca()`, guardado em `mestre.vista`, `mestre.snapshot` e `mestre.cartoes.desgraca`;
  2. `cenarioIA()`, guardado em `mestre.cartoes.ia`;
  3. `cenarioDados()`, guardado em `mestre.cartoes.dados`;
  4. `cenarioLobby()`, guardado em `lobby`;
  5. `cenarioAgir()`, guardado em `agir`.

  O `mestre` conta por 3: a desgraça, mais `cartoes.ia` e `cartoes.dados`. A chave `jogadora` não é um sexto cenário.
  Guarda as mensagens da heroína no cenário 1.

**Corrigido:** a frase da CORRECOES-8 ficou riscada. Por baixo, com nota datada («Apertado na
CAIXA-TESTES-CORRECOES-9 (B3), 22/11/2026»), a frase da ordem: «a fixture compara o ficheiro inteiro — qualquer mudança
(chave ou valor) nas mensagens da jogadora do cenário da desgraça aí guardadas fá-la falhar; mensagens da jogadora fora
desse cenário não são guardadas, por isso não as vê; e não distingue fuga de mudança legítima, por isso não é guarda.»
A conclusão (não é guarda) fica igual.

**Privacidade:** não houve fuga nem mutação nesta ordem. Nenhum número novo: só os valores-canário de bancada já citados.

## Números das corridas (PC, Node 26.13.0, sobre `6148f79` + `2eee882`)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` | **420/420**, 0 falhas, 0 cancelados, 0 saltados, 0 todo |
| `node --test --test-isolation=none testes/privacidade.test.mjs` | **10/10** |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (não tocada) |
| `actualizar-listas.py` depois do commit 1 | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)`; mudaram `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt` (a linha do `privacidade.test.mjs`) |

## Pontos para o coordenador

1. **B1–B3 são só texto.** A suite fica 420/420, como na base.
2. **O corpo do ESTADO-FINAL-8 ainda cita as frases antigas** (B1 «Corrigido: … do cenário da desgraça …; fora desse
   cenário não vê nada» e B3 «Corrigido, nos dois sítios: … o «recomeçar» emite `recomeco`, …»). São o registo do que
   a CORRECOES-8 escreveu, e a ordem só manda corrigir a justificação do B3. Não lhes toquei; o ponto 2 do ESTADO-FINAL-8
   já regista o `cartao_fechado` + `turno`.
3. O CI deste ramo não está registado aqui, porque o commit das listas é o último, como a ordem pede.
4. O `ORDEM.md` da sede não foi tocado, como na C5–C8: a última linha é a instrução que contém «Estado: NOVA».
