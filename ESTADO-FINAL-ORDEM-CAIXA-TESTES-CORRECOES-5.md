# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-5 (Claude conta 1, PC) · 22/11/2026

Fecha as correcções **B1–B5** da sentença da CAIXA-TESTES-CORRECOES-4. Em `rascunhos/` mudaram só `ajudantes.mjs`,
`caixa-hud-jogadora.test.mjs` e `privacidade.test.mjs`. Fora de `rascunhos/` mudaram
`ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-4.md` (B1 e B2), as listas da retoma e este ficheiro. Nenhum código do jogo,
do HUD, das cores ou do protocolo foi tocado, e a prova também não.

- **Base:** `origin/fable/integracao-50` @ `2140e6b` (a ponta à hora do lançamento; já traz a CORRECOES-4). Clone novo,
  `core.autocrlf=false`.
- **Ramo:** `claude1/caixa-testes-correcoes-5`, **não fundido** (a fusão é do coordenador).
- **Commits, por ordem:**
  1. `81110fe`: os testes, `ajudantes.mjs` e o ESTADO-FINAL da CORRECOES-4.
  2. As listas da retoma (`actualizar-listas.py`, corrido depois do 1: mudaram `MANIFESTO-SHA256.txt` e
     `retoma-i0004/depois.txt`) e este ficheiro.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-4/` não está neste PC nem no repositório. Trabalhei
  pelo resumo da ordem e conferi cada número dela contra o código (abaixo).
- **Mutações:** executadas com `tmp/mutar.py` na sede (fora do repo; saída em `tmp/mutar.log`). Cada uma aplica-se,
  corre a suite nova inteira, os dois ficheiros novos e os dois **antigos** (os da base `2140e6b`, com a mesma mutação
  de teste quando a há), e reverte. Fim: `nucleo limpo: True`, `testes novos repostos: True`.

## Ponto a ponto

### B1: os números dos snapshots no ESTADO-FINAL da CORRECOES-4
- **Contado** (guião de `privacidade`, papel a papel, sobre `2140e6b`): heroína, aliada e espectador recebem cada um
  **6** `ROOM_SNAPSHOT` — `lobby`, depois 5 de `combate`: **1 do lobby + 3 da caixa** (iniciativa, desligada,
  dinâmico) **+ 2 do RESYNC** (`lastSeq: 0` e sem `lastSeq`). **18 no total.**
- **Corrigido:** a frase «o guião de `privacidade` dá 5 snapshots a cada papel da Party» está riscada, com a correcção
  por baixo. Os «15 snapshots, 5 ao espectador» da sentença da CORRECOES-3 ficam qualificados: contam **só os da
  batalha** (3 + 2 = 5 por papel, 15 nos três), sem o do lobby.

### B2: o âmbito da M18b
- **Registado** no ESTADO-FINAL da CORRECOES-4: na linha da M18b da tabela da B1 (e na tabela-resumo), com uma nota
  logo a seguir. A M18b põe `vidaActual` na figura pública **só nas figuras com `lado === 'jogadora'`**, porque o que se
  quer provar é a fuga da Vida de uma jogadora para a outra.
- **O porquê, re-executado (não só lido):**

  | Mutação (`projecao.js` `figuraPublica`) | `privacidade` nova | Suite nova | O que rebenta a mais |
  |---|---|---|---|
  | **M18b**: `...(fig.lado === 'jogadora' ? { vidaActual } : {})` | **7/9** | **415/419** | (c), «outra jogadora», o teste da B1, a fixture do ecrã do Mestre |
  | **M18b-todas** (a implementação natural): `vidaActual` em **todas** as figuras | **6/9** | **408/419** | + «nada do Mestre» (`vazamento para heroina: … vidaActual 6601 …, 4848`) + 6 testes: CORR8 (a) × 2, CORR8 (b) × 2, MAPA-JOGÁVEL (f), ordem ESCALA (d) |

  Os números da ordem (6/9 e 408/419; 7/9 e 415/419; o 6601 do orc em «nada do Mestre» + 6 testes) batem.

### B3: a guarda B6 da (c) prende também o caminho (`caixa-hud-jogadora.test.mjs`, l. 265–279)
- A BFS de `distanciaCasas` depende das pontas **e** de tudo o que bloqueia: as outras figuras vivas colocadas e as
  casas passáveis (`passavel`: o tamanho do mapa e o terreno). O `deepEqual` passou a ter, além de `casaM`, `alcanceM`,
  H, A e orc:
  - `lobo: [12, 12]`;
  - `vivasColocadas: [[2,2], [2,4], [2,6], [12,12]]` (uma figura nova no mapa muda o caminho);
  - `mapa: { largura: 20, altura: 20, casaM: 1.5 }`;
  - `terreno: null` (`depuracao.juizoTerreno()`: esta mesa não tem pacote de terreno).
- **Prova (mutações de teste, executadas):**

  | Mutação (só na (c)) | (c) nova | (c) antiga (`2140e6b`) | Suite nova |
  |---|---|---|---|
  | **M21**: o lobo em (12,13) | **falha** (8/9), «B6: a geometria do ataque (6 passos = 6 casas, no limite) mudou…» | **passa calada** (9/9) | 418/419 |
  | **M22**: o mapa 21 × 20 | **falha** (8/9), a mesma mensagem | **passa calada** (9/9) | 418/419 |

  (Nenhuma das duas parte o ataque hoje — é exactamente por isso que a guarda antiga as deixava passar: prendia as
  pontas, não o que o caminho atravessa.)

### B4: a guarda (1) da B1 varre também os valores intermédios (`privacidade.test.mjs`, l. 153–180)
- **Antes:** a guarda (1) lia só a `vidaActual` do **fim** do guião. Cobria tudo só porque a aliada se fere num único
  passo (3579 → 2403) — hipótese que não estava escrita.
- **Agora:** `historicoVida(k)` junta todos os valores que a Vida actual de cada jogadora teve: a de partida (a
  `vidaTotal` da ficha), cada evento `estado` do journal com a `vidaActual` dessa figura, a `propria` de cada snapshot
  que a própria recebeu, e a do fim. Varre-se cada um em tudo o que a outra jogadora e o espectador receberam. Valores
  < 100 ficam de fora (colidem com contadores, coordenadas e o 0 de quem cai; as Vidas das fichas de teste estão todas
  acima). A hipótese do passo único fica escrita no comentário, com o porquê.
- **Sanidades novas:** o histórico da aliada tem a de partida e a do fim (hoje `[2403, 3579]`), e o journal tem um
  evento `estado` da aliada com o 2403 (a fonte dos intermédios não está morta).
- **Prova (executada):** a M20 junta a M18 (a fuga de `fugaB1` no topo de todo o snapshot da Party) a uma mutação do
  guião: no fim, depois dos RESYNC, uma volta inteira em que o orc volta a acertar na aliada (**2403 → 1227**), e só a
  aliada faz RESYNC. Os snapshots da heroína e do espectador ficam com o **2403** que fugiu, e o fim é 1227.

  | Mutação | `privacidade` nova | `privacidade` antiga (`2140e6b`) | Suite nova |
  |---|---|---|---|
  | **M20-controlo**: só o segundo golpe (sem fuga) | 9/9 (sem falso positivo) | 9/9 | 419/419 |
  | **M20**: M18 + o segundo golpe | **falha**, 8/9, l. 178: «heroina viu uma Vida actual de aliada (1227,2403,3579)» | **passa calada** (9/9) | 417/419: o teste da B1 e a fixture do ecrã do Mestre |
  | **M18** (a da conferência, sem segundo golpe) | falha, 8/9 | falha, 8/9 | 417/419 |

### B5: a substring nua `'8642'` em `TEXTOS_HEROINA` (`ajudantes.mjs`, l. 63)
- Fica a substring **nua**, de propósito: apanha a perícia em qualquer texto (`'1d20+8642'`, `'perícia 8642'`,
  `'+8642'`), e `'1d20+8642'` só apanhava a forma da ficha. O comentário regista o **risco conhecido e aceite**: é um
  `includes` sobre todas as strings, por isso um texto legítimo com estes quatro dígitos (p. ex. `'18642'`, um id ou um
  carimbo) dá falso positivo. A falha é alta, não calada; se acontecer, muda-se o canário da ficha ou estreita-se ali,
  nunca se tira a guarda.
- Não há mutação: a lista não mudou. A suite passa com ela (sem falso positivo hoje).

**Privacidade:** não há fuga viva. As fugas das mutações foram temporárias e revertidas (`nucleo limpo: True`). Os
números e os nomes são os valores-canário de bancada das fichas de teste.

## Números das corridas (PC, Node 26.13.0, sobre `2140e6b` + este ramo)

| Corrida | Resultado |
|---|---|
| Servidor na base, antes de mexer | 419/419 |
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` (sem `--permission`) | **419/419**, 0 saltados (`caixa-hud-jogadora` 9/9, `privacidade` 9/9; nenhum teste novo, só guardas mais apertadas) |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (11 passos; não tocada) |
| `actualizar-listas.py` depois do commit 1 | `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados)` |

### As mutações (resumo; todas executadas)

| | Mutação | Suite nova | `privacidade` nova / antiga | (c) nova / antiga |
|---|---|---|---|---|
| M18 | `vidaActual` da ferida (2403) no topo do snapshot da Party | 417/419 | 8/9 / 8/9 | 9/9 / 9/9 |
| M18b | `vidaActual` na figura pública, só `lado === 'jogadora'` | 415/419 | 7/9 / 7/9 | 8/9 / 8/9 |
| M18b-todas | `vidaActual` na figura pública de todas as figuras | 408/419 | 6/9 / 6/9 | 8/9 / 8/9 |
| M20-controlo | segundo golpe na aliada, sem fuga | 419/419 | 9/9 / 9/9 | 9/9 / 9/9 |
| M20 | M18 + segundo golpe (fuga de um intermédio) | 417/419 | **8/9 / 9/9 (calada)** | 9/9 / 9/9 |
| M21 | o lobo em (12,13) na (c) | 418/419 | 9/9 / 9/9 | **8/9 / 9/9 (calada)** |
| M22 | o mapa 21 × 20 na (c) | 418/419 | 9/9 / 9/9 | **8/9 / 9/9 (calada)** |

## Pontos para o coordenador

1. **B4 foi pela via forte** (varrer o histórico), não só pelo comentário; a hipótese do passo único fica escrita na
   mesma. A M20 prova a diferença: a guarda antiga cala, a nova apanha; e o controlo dá 9/9 (sem falso positivo).
2. **B4, de passagem:** com um segundo golpe **sem** snapshot a seguir, a sanidade antiga «no último snapshot a
   jogadora vê a Vida actual dela» falha (a última `propria` ainda tem o 2403). Não é defeito hoje — o guião acaba num
   RESYNC —, mas quem acrescentar acções ao fim do guião tem de acabar noutro snapshot. Por isso a M20 faz o RESYNC da
   aliada.
3. **B3 foi pela via forte** (o lobo, as figuras vivas, o mapa e o terreno no `deepEqual`). O guião de `privacidade`
   tem a mesma geometria e continua só com a guarda implícita do `exigirAplicada` (não mexi, como na CORRECOES-4).
4. **B5 ficou com a substring nua** e o risco registado, em vez de estreitar: estreitar para `'1d20+8642'` perdia a
   perícia noutros textos.
5. **B1/B2 corrigidos no ESTADO-FINAL da CORRECOES-4** (riscado + nota datada da CORRECOES-5), não reescritos: o texto
   original fica legível.
6. A conferência da CORRECOES-4 não está neste PC; trabalhei pelo resumo da ordem e todos os números dele bateram.
7. O `ORDEM.md` da sede não foi tocado (já termina com a linha do estado).
8. O CI deste ramo não está registado aqui: o commit das listas é o último, como a ordem pede.
