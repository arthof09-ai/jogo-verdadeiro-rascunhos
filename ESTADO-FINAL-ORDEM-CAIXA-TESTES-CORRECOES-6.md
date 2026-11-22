# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-6 (Claude conta 1, PC) · 22/11/2026

Fecha as correcções **B1–B6** da sentença da CAIXA-TESTES-CORRECOES-5. Em `rascunhos/` mudou só
`privacidade.test.mjs`; `caixa-hud-jogadora.test.mjs` e `ajudantes.mjs` não precisaram de mudar. Fora de `rascunhos/`
mudaram `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-4.md` (B4, B5), `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-5.md`
(B4, B6), as listas da retoma e este ficheiro. Não toquei em código do jogo, HUD, cores, protocolo nem na prova.

- **Base:** `origin/fable/integracao-50` @ `8894caa` (a ponta à hora do lançamento, já com a CORRECOES-5). Clone novo,
  `core.autocrlf=false`.
- **Ramo:** `claude1/caixa-testes-correcoes-6`, **não fundido** (a fusão é do coordenador).
- **Commits, por ordem:**
  1. `04b7a54`: o teste e os dois ESTADO-FINAL antigos.
  2. As listas da retoma e este ficheiro. Corri `actualizar-listas.py` depois do commit 1; mudaram
     `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt`.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-5/` não está neste PC nem no repositório. Trabalhei
  pelo resumo da ordem e conferi cada afirmação dela com uma execução (abaixo).
- **Mutações:** executadas com `tmp/mutar.py` na sede, fora do repo. As saídas estão em `tmp/mutar.log` (antiga = a
  base `8894caa`) e em `tmp/mutar-2140e6b.log` (antiga = `2140e6b`, a de antes da CORRECOES-5, para a B4). Cada mutação
  aplica-se, corre a suite nova inteira, a `privacidade` nova e a **antiga** (com a mesma mutação de guião), e é
  revertida. As duas corridas acabaram com `nucleo limpo: True` e `teste novo reposto: True`.

## Ponto a ponto

### B1 (obrigatória): o corte `x >= 100` em `historicoVida` deixava calada a fuga de um intermédio baixo
- **Corrigido:** `historicoVida` filtra só o `0` (`x !== 0`). O 0 é o único valor que colide de facto: é o de quem
  cai, e aparece em contadores e coordenadas. O comentário foi reescrito. Diz porque é que o corte saiu (a M51b) e
  regista que, se um valor baixo colidir um dia com um número legítimo, a falha é **alta**: muda-se o guião e não se
  volta ao corte.
- **Também (opcional, recomendado):** `historicoVida(m, k, { proprias })` passou ao nível do módulo e a M51b entrou na
  suite. O guião ganhou a opção `guiao({ m51b: true })`; o guião de sempre não muda. Teste novo: «canários: a Vida
  baixa de um intermédio (51, depois «voltar») não chega à outra jogadora nem ao espectador».
  - O caminho: uma volta inteira, em que o orc acerta na aliada (2403 → 1227). Na volta seguinte o lobo, já ao pé,
    acerta-lhe primeiro (1227 → **51**). O RESYNC dos três papéis é feito logo aí, antes de o orc jogar (o golpe dele
    levava-a a −1125). Depois, `MASTER_SUPERVISOR voltar` ao fim do guião, o que a põe de novo em **2403**.
  - Prende quatro coisas:
    - o «voltar» repôs o 2403;
    - a aliada foi fotografada com o 51;
    - o histórico da aliada tem 51, 1227, 2403 e 3579;
    - nem a heroína nem o espectador vêem nenhum desses valores.
- **A fuga da M51b**, construída para esta ordem porque a conferência não está no PC: `M51`, em `sala.js`
  `mensagemSnapshot`, põe `fugaB1` no topo de cada ROOM_SNAPSHOT da Party. O `fugaB1` leva a `vidaActual` das jogadoras
  **à beira da morte** (`vidaActual * 10 < vidaTotal`, o mesmo limiar da «gravemente ferida» de `sala.js`, REF_7 §5).
  Só o 51 é fotografado com fuga; o 1227 e o 2403 nunca vão na `fugaB1`.
- **Prova (regressão executada):**

  | Mutação | `privacidade` nova | `privacidade` antiga (`8894caa`) | Suite nova |
  |---|---|---|---|
  | **M51b**: M51 + o caminho (51, RESYNC, «voltar» a 2403) | **falha, 8/10**: o teste da Vida («heroina viu uma Vida actual de aliada (51,1227,2403,3579)») e o teste novo da M51b | **passa calada, 9/9** — a fuga viva da sentença | 417/420 |
  | M51b-sem-fuga (só o caminho) | 10/10 | 9/9 | 420/420 |
  | M51-controlo (a fuga M51 no guião de sempre) | 9/10: só o teste novo da M51b (o único com alguém à beira da morte) | 9/9 | 418/420 |
  | corte-100 (o `>= 100` de volta, só no novo) | **9/10**: o teste novo falha, «o histórico da aliada tem o 51 (1227,2403,3579)» | — | 419/420 |

  O «deve falhar 8/9» da ordem é o ficheiro sem o teste novo, em que só falha o teste da Vida. Com o teste novo, o
  ficheiro tem 10 testes e a M51b falha em dois (8/10). A última linha mostra que o teste novo prende o filtro: se o
  corte voltar, a suite deixa de estar verde.

### B2 (obrigatória): a sanidade «último snapshot `propria` == Vida actual»
- **Re-ancorada:** cada `propria` de cada snapshot da jogadora tem de ser uma Vida que **a sala registou** para ela: a
  de partida, um evento `estado` do journal ou a do fim. É `historicoVida(m, k, { proprias: false })`; sem as próprias
  `propria`, porque assim a verificação seria circular. Acrescentei mais uma sanidade, ainda sem âncora no último
  snapshot: algum snapshot da aliada mostra-lhe uma Vida abaixo da máxima. Ou seja, a exclusão não lhe tira a Vida dela.
- **Escrito no comentário:** o guião **pode acabar sem RESYNC**. Uma acção depois do último snapshot muda a Vida sem
  snapshot novo, e a sanidade antiga falhava em falso positivo sem fuga nenhuma.
- **Prova (executada):**

  | Mutação | `privacidade` nova | `privacidade` antiga (`8894caa`) | Suite nova |
  |---|---|---|---|
  | **M20-semRESYNC** (o 2.º golpe, 2403 → 1227, sem snapshot depois, sem fuga) | **10/10** (o 9/9 da ordem, mais o teste novo) | **falha 8/9** em falso positivo: «aliada: vê a Vida actual dela» | 420/420 |
  | M20-semRESYNC + M18 (com fuga) | falha 8/10, «heroina viu uma Vida actual de aliada (1227,2403,3579)» | falha 8/9 | 417/420 |
  | M20-controlo (o 2.º golpe com o RESYNC da aliada, sem fuga) | 10/10 | 9/9 | 420/420 |

### B3: a sanidade do histórico com uma Vida final < 100, depois da B1
- **Verificado (executado):** a M51-fim faz o caminho até 51 **sem** «voltar», e a aliada acaba o guião com 51.

  | Mutação | Teste da Vida, novo | Teste da Vida, antigo (`8894caa`) |
  |---|---|---|
  | **M51-fim** (Vida final 51, sem fuga) | **passa** | **falha** em falso positivo: «o histórico da Vida da aliada tem a de partida e a do fim (1227,2403,3579)», porque o 51 era cortado |
  | M51-fim + M51 (com fuga) | **falha**, «heroina viu uma Vida actual de aliada (51,1227,2403,3579)» | falha, pela mesma sanidade |

  Com a B1, a sanidade do histórico aguenta uma Vida final < 100 e o valor continua varrido.
- **Nota:** na M51-fim, o teste «nada do Mestre» falha nas duas versões, na sanidade da B2 da CORRECOES-2: «heroina: a
  ordem no snapshot do escolherCaixa». Essa sanidade assume que nada mexe na ordem da Party depois das escolhas da
  caixa, e duas voltas a mais sem «voltar» mexem. Não tem nada a ver com a Vida. É por isso que a suite nova dá 419/420
  na M51-fim. Ver o ponto 3 para o coordenador.

### B4: a célula «M20 antiga 9/9» e a chave da `fugaB1`
- **Re-executado** contra a `privacidade` de `2140e6b`, a «antiga» da CORRECOES-5 (`tmp/mutar-2140e6b.log`):

  | Mutação | `privacidade` antiga (`2140e6b`) |
  |---|---|
  | M20 com a chave **`fugaB1`** (array no topo do snapshot) | **9/9, passa calada** (o número da CORRECOES-5 reproduz-se) |
  | M20v com a chave **`vidaActual`** no topo do snapshot | **falha 8/9 pela forma (2)**: «heroina: só a Vida actual dela, em `propria`» |

- **Corrigido:**
  - No ESTADO-FINAL-4, a linha da M18 na tabela-resumo dizia «`vidaActual` da jogadora ferida (2403) no topo do
    snapshot», o que se lê como a chave. Ficou riscada, com «`fugaB1: [2403]` … numa chave que **não** é
    `vidaActual`», e há uma nota datada da CORRECOES-6 a seguir à tabela, com os dois números acima.
  - No ESTADO-FINAL-5, a célula «passa calada (9/9)» da M20 (na tabela da B4 e na tabela-resumo) diz agora que só vale
    com a chave `fugaB1`, e que com `vidaActual` a antiga falha 8/9 pela forma (2). A linha da M18 da tabela-resumo foi
    corrigida da mesma maneira.
  - O texto original fica legível (riscado mais correcção).

### B5: «na B1» → «na B2» no ESTADO-FINAL-4 (l. 149)
- Na linha da M18b da tabela-resumo: «nota da CORRECOES-5 na ~~B1~~ B2». O âmbito da M18b foi a B2 da CORRECOES-5.

### B6: «l. 63» → «l. 63–68» no ESTADO-FINAL-5
- O título da B5 do ESTADO-FINAL-5 passou a «`ajudantes.mjs`, ~~l. 63~~ l. 63–68». O comentário começa na 63 e o
  `export const TEXTOS_HEROINA` está na 68 (conferido na base).

**Privacidade:** não há fuga viva. As fugas M18, M18v e M51 foram temporárias e revertidas (`nucleo limpo: True`).
Os números são os valores-canário de bancada das fichas de teste.

## Números das corridas (PC, Node 26.13.0, sobre `8894caa` + este ramo)

| Corrida | Resultado |
|---|---|
| Servidor na base, antes de mexer | 419/419 |
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` | **420/420**, 0 saltados (`privacidade` 10/10: +1, o teste da M51b) |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (11 passos; não tocada) |
| `actualizar-listas.py` depois do commit 1 | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados)` |

### As mutações (resumo; todas executadas, `tmp/mutar.log`)

| | Mutação | Suite nova | `privacidade` nova / antiga (`8894caa`) |
|---|---|---|---|
| M18 | `fugaB1` = Vida das feridas no topo do snapshot | 417/420 | 8/10 / 8/9 |
| M18v | a mesma fuga, com a chave `vidaActual` | 417/420 | 8/10 / 8/9 |
| M20 | M18 + 2.º golpe + RESYNC da aliada | 417/420 | 8/10 / 8/9 (a antiga `2140e6b`: 9/9 calada) |
| M20v | M18v + 2.º golpe + RESYNC da aliada | 417/420 | 8/10 / 8/9 (a antiga `2140e6b`: 8/9 pela forma) |
| M20-controlo | 2.º golpe + RESYNC, sem fuga | 420/420 | 10/10 / 9/9 |
| M20-semRESYNC | 2.º golpe sem snapshot depois, sem fuga | 420/420 | **10/10 / 8/9 (falso positivo)** |
| M20-semRESYNC+M18 | o mesmo, com fuga | 417/420 | 8/10 / 8/9 |
| M51-controlo | fuga M51 no guião de sempre | 418/420 | 9/10 / 9/9 |
| M51b-sem-fuga | 51, RESYNC, «voltar», sem fuga | 420/420 | 10/10 / 9/9 |
| **M51b** | M51 + 51, RESYNC, «voltar» a 2403 | 417/420 | **8/10 / 9/9 (calada)** |
| M51-fim | Vida final 51, sem fuga | 419/420 | 9/10 / 7/9 (ver a B3) |
| M51-fim+M51 | Vida final 51, com fuga | 416/420 | 7/10 / 7/9 |
| corte-100 | o `>= 100` de volta, só no novo | 419/420 | 9/10 / — |

## Pontos para o coordenador

1. **A M51b foi construída por mim**, porque a conferência não está no PC. O caminho é o da sentença (1227 → 51,
   fotografada num RESYNC, «voltar» a 2403). A fuga é a M51: `fugaB1` só de quem está à beira da morte. Os números
   batem com a sentença: a antiga passa calada (9/9) e a nova falha no teste da Vida (o «8/9» da ordem, que dá 8/10
   com o teste novo). Se a M51b da conferência usar outra fuga, vale a pena correr essa contra este ramo.
2. **B2 foi por re-ancorar, não por tirar.** A sanidade de exclusão fica, contra o que a sala registou (journal) e não
   contra o último snapshot. O guião pode acabar sem RESYNC, e a M20-semRESYNC dá 10/10.
3. **Fragilidade do guião, fora do âmbito, não mexi:** a sanidade da B2 da CORRECOES-2 («a ordem no snapshot do
   escolherCaixa» = `ordemDinamicaParty` do fim) parte se o guião avançar voltas depois das escolhas da caixa sem
   «voltar» (M51-fim). Hoje não é defeito. O teste novo da M51b não a toca, porque usa o «voltar» e corre noutro teste.
   Quem acrescentar voltas ao fim do guião de sempre vai dar com ela.
4. **O ESTADO-FINAL-4 l. 42** («No último snapshot, cada jogadora vê a Vida actual dela») descreve a sanidade antiga
   como era na CORRECOES-4. É registo histórico e não o emendei; a sanidade nova está descrita na B2 acima.
5. `caixa-hud-jogadora.test.mjs` e `ajudantes.mjs` não mudaram: nenhuma das correcções lhes tocava.
6. O `ORDEM.md` da sede não foi tocado. Já termina com a linha do estado.
7. O CI deste ramo não está registado aqui, porque o commit das listas é o último, como a ordem pede.
