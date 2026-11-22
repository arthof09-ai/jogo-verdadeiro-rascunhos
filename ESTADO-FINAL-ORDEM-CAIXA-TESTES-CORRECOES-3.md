# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-3 (Claude conta 2, PC do cunhado) · 22/11/2026

Fecha as correcções **B1–B7** da sentença da CAIXA-TESTES-CORRECOES-2. Só testes e um ESTADO-FINAL antigo:
`git diff --stat 6a87b9e..HEAD -- rascunhos` mostra só `ajudantes.mjs`, `caixa-hud-jogadora.test.mjs` e
`privacidade.test.mjs` (mais as listas da retoma, fora de `rascunhos/`, e a nota ¹ de `ESTADO-FINAL-ORDEM-CAIXA-TESTES.md`).
Não mudou nenhum código do jogo, do HUD, das cores ou do protocolo. A prova `prova-servidor.mjs` não foi tocada.

- **Base:** `origin/fable/integracao-50` @ `6a87b9e` (a ponta à hora do lançamento, e ainda a ponta à hora do commit).
  Clone novo, `core.autocrlf=false`.
- **Ramo:** `claude2/caixa-testes-correcoes-3`, **não fundido** (a fusão é do coordenador).
- **Commits** (corrigido pela Ordem CAIXA-TESTES-CORRECOES-4, B4: as listas **não** são o último commit), por esta
  ordem: `38f0c48` (os testes, a nota ¹ e este ESTADO-FINAL), `eb74bb7` (as listas da retoma, `actualizar-listas.py`)
  e `c835986` (o resultado do CI neste ESTADO-FINAL; só toca neste ficheiro). Depois da publicação, o ramo foi
  reescrito por cima de `15eab43` (o rebase do coordenador, com as mesmas datas de autor): no ramo e em
  `fable/integracao-50` são hoje `8870275`, `ae62dd9` e `f049089`, pela mesma ordem.
- A conferência (`~/workspace/conferencias/caixa-testes-correcoes-2/`) não está neste PC nem no repositório. Trabalhei
  pelo resumo dos defeitos que vem na ordem.

## Ponto a ponto

### B1: a semente e o 6601 passam a vivos na (c) (`caixa-hud-jogadora.test.mjs`)
- **O defeito:** o guião da (c) só fazia mover, encerrar, caixa e voltar, sem nenhuma resolução. Por isso
  `sortearSemente` nunca era chamada e o orc ficava com 7777. `SEMENTE` e `6601` não existiam em lado nenhum da sala, e
  uma fuga deles no snapshot do «voltar» não tinha o que mostrar. A afirmação do ESTADO-FINAL anterior («B3 tornou a
  semente viva») era **falsa**: a `rngSemente: () => SEMENTE` só diz que semente sai *quando* se sorteia uma.
- **Agora:** **antes do ponto** (do checkpoint), a heroína ataca o orc com o chicote:
  `m.intencao('heroina', { tipo: 'atacar', alvoId: orc, arma: 'chicote-teste' })`. Depois anda, como antes, e o ponto
  fica a seguir a isso. Para o ataque ser válido, a (c) põe o orc em `(2,6)`, a casa do guião de `privacidade.test.mjs`,
  porque `(8,8)` está fora do alcance e dava `acao_invalida`. `mesaEmCombate` ganhou a opção `casaOrc`; os outros
  testes ficam com `(8,8)`.
- **Sanidade no próprio teste:** o orc fica com `vidaActual === 6601`, e há no journal um evento com
  `soMestre.semente === SEMENTE`. Sem isto o canário não está vivo, e o teste diz isso.
- **Prova (mutações executadas, `tmp/mutar.py` na sede; revertidas, núcleo limpo):**

  | Mutação (temporária, no código do jogo) | (c) nova | (c) antiga (`6a87b9e`) |
  |---|---|---|
  | **M13**: `fugaB1` = a última `soMestre.semente` do journal, no topo de todo o ROOM_SNAPSHOT da Party (`sala.js` `mensagemSnapshot`) | **falha** na linha da varredura do snapshot do «voltar» (l. 293, «heroina: canários do Mestre … no snapshot do «voltar»»), valor `3237998097` = `0xC0FFEE11` = `SEMENTE` | **passa calada** (9/9): sem resolução, não há semente |
  | **M14**: `fugaB1` = a Vida dos inimigos feridos (`vidaActual < vidaTotal`), no mesmo sítio | **falha** na mesma linha, valor `6601` | **passa calada** (9/9): o orc nunca foi ferido |

  Na suite inteira, a M13 parte 2 testes (416/418): a (c) e «canários: nada do Mestre chega…». A M14 parte 3
  (415/418): esses dois e a fixture do ecrã do Mestre. O teste antigo de `privacidade` já apanhava as duas, porque o
  guião dele ataca; o que faltava era a (c).

### B2: `41, 61, 6601, SEMENTE` em `NUMEROS_MESTRE_CAIXA`
- Entraram os quatro. A lista é agora `7777, 313, 41, 61, 6601, 5150, 3579, 4040, 1357, 4848, 9137, 4949, 6363, 6464,
  SEMENTE` e os valores de iniciativa. Os dois testes que a usam passam: «nada do Mestre na caixa da Party (canários)» e
  a varredura da `caixa` na (c).
- `41`/`61` são pequenos, mas a `caixa` só tem `ligada`, `ordemPor` e a `ordemDinamica` (ids em texto e `fechada`).
  Nenhum contador, por isso não há falso positivo.

### B3: o nome verdadeiro do lobo e os verbos do orc/lobo como canários
- `'Lobo Teste'` está em `TEXTOS_SO_MESTRE` (`ajudantes.mjs`). Pela B7, isto chega aos dois ficheiros: `TEXTOS_MESTRE`
  de `privacidade.test.mjs` é `[...os canários do guião, ...TEXTOS_SO_MESTRE]`.
- **Os verbos também entraram:** `'desferiu o machado'`, `'tentou desferir o machado'`, `'deu uma patada'` e
  `'tentou dar uma patada'`. Vêm de `fichas-ficticias.json` e só vão na figura do Mestre (`projecao.js`
  `figuraDoMestre`, Ordem 13 parte C). A Party não narra os golpes dos monstros (`cliente/README.md`), por isso
  qualquer verbo que lhe chegue é fuga. Nenhum deu falso positivo.
- **Vivos:** a sanidade de «canários: nada do Mestre chega…» confirma agora que o Mestre recebe `Lobo Teste` e os
  quatro verbos. Passa, por isso o teste não está a procurar no vazio.
- **Prova (mutações executadas):**

  | Mutação | `privacidade` nova | `privacidade` antiga | (c) nova | (c) antiga |
  |---|---|---|---|---|
  | **M15**: **só** o nome verdadeiro do lobo (`nomeVerdadeiro: 'Lobo Teste'`) na figura pública (`projecao.js` `figuraPublica`) | **falha** («canários: nada do Mestre…», valor `'Lobo Teste'`) | **passa calada** (8/8) | **falha** | passa (9/9) |
  | **M16**: **só** os verbos dos monstros na figura pública | **falha** (os 4 verbos) | **passa calada** (8/8) | **falha** | passa (9/9) |

  Na suite inteira, cada uma parte 3 testes (415/418): a (c), «canários: nada do Mestre…» e a fixture do ecrã do Mestre.

### B4: a linha «Servidor 418/418», com os números certos por job
- Os ESTADO-FINAL anteriores davam «Servidor 418/418», mas esse número vem da corrida local sem `--permission`. No CI:
  - **job `servidor`** (`node --permission --allow-fs-read=… --test`, só leitura): **408 passam + 10 saltados** de 418.
    (Corrigido pela Ordem CAIXA-TESTES-CORRECOES-4, B3: os 10 saltados **não** são de rede. São **8 de disco**
    (`SEM_DISCO`: 5 da ordem 16 em `ordem16-journal-disco.test.mjs` e 3 da ordem 17 em `ordem17-varredura.test.mjs`,
    sem escrita) e **2 de leitura de `../protocolo`** (`SEM_PROTOCOLO`: os N19-1 e N19-2 de `ordem21-decisoes.test.mjs`,
    fora do `--allow-fs-read`). Os 10 correm no job `protocolo`. Os testes de rede **passam** no job `servidor`.)
  - **job `protocolo`** (a recolha do tráfego, `PROTOCOLO_DUMP=… node --test … "servidor/testes/*.test.mjs"`, sem
    `--permission`): **418/418**.
- Esta ordem não muda o número de testes (só aperta os que já havia), por isso os dois números ficam: **408 + 10
  saltados** no `servidor` e **418/418** no `protocolo`. Os números deste ramo no CI estão na secção do CI.

### B5: a enumeração da nota ¹ (`ESTADO-FINAL-ORDEM-CAIXA-TESTES.md`)
- A linha dos «Totais actuais» foi reescrita e está datada. Os testes que falham nas duas formas são a (b), a (c), o
  **«por omissão»** e a fixture. Só com a `caixaMestre` no topo (5) falha «segue para a Party». Só com ela dentro da
  `caixa` (7) falham «canários da caixa», «journal» e o teste do lobby. **O teste do lobby só conta nos 7.** Os nomes vêm
  das M1/M2 já registadas em `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-2.md`. A enumeração errada da B7 desse
  ESTADO-FINAL («com a (c) da B7 e o teste do lobby») fica corrigida por esta nota; o ficheiro antigo não foi reescrito.

### B6: a (c) varre também o snapshot da re-entrada da aliada
- O snapshot `sa` (a aliada sai e volta a entrar depois do «voltar») varre-se como o do «voltar»: `CHAVES_SO_MESTRE`,
  `NUMEROS_PROIBIDOS_NO_SNAPSHOT.aliada` (os do Mestre e os da heroína) e `TEXTOS_SO_MESTRE`. Tem a mesma sanidade da
  exclusão: `sa.propria.vidaTotal === 3579`.
- **Prova (mutação executada, M17):** `fugaB6: 7777` (a Vida do orc) **só** no snapshot de sincronização de uma jogadora
  (`sala.js` `mensagensDeSincronizacao`, o caminho do JOIN e do RESYNC; o snapshot do «voltar» não passa por aqui). A (c)
  nova **falha na linha nova** (l. 308, «aliada: canários do Mestre (e da heroína) no snapshot da re-entrada depois do
  «voltar»»). A (c) antiga **passa calada** (9/9).

### B7: uma só fonte das listas (`ajudantes.mjs`)
- `ajudantes.mjs` exporta `SEMENTE`, `NUMEROS_SO_MESTRE`, `TEXTOS_SO_MESTRE`, `CHAVES_SO_MESTRE`, `NUMEROS_HEROINA` e
  `NUMEROS_ALIADA`, todas congeladas.
- `privacidade.test.mjs` importa-as. `NUMEROS_MESTRE` e `CHAVES_MESTRE` ficam como nomes locais para as mesmas listas;
  `TEXTOS_MESTRE` são os canários só do guião dele (`CANARIO-*` e `23:59`) mais `TEXTOS_SO_MESTRE`.
- `caixa-hud-jogadora.test.mjs` importa-as e já não tem cópias. Só ficaram lá as listas próprias da caixa
  (`CHAVES_MESTRE_CAIXA` e `NUMEROS_MESTRE_CAIXA`) e a composição por papel (`NUMEROS_PROIBIDOS_NO_SNAPSHOT`).
- **Sem mudar comportamento:** comparei, numa corrida, as listas novas com as cópias antigas. `SEMENTE`, os números, as
  chaves e os números das jogadoras são iguais (`true` em todos). Nos textos não se perdeu nenhum, e os únicos novos são
  os cinco da B3. A lógica de varredura (`procurarCanarios`) não mudou.

**Privacidade:** nenhuma fuga viva. Só há asserções e varreduras sobre o que a Party já recebia, e os números e nomes são
os valores-canário de bancada das fichas de teste. As fugas das mutações M13–M17 foram temporárias e revertidas
(`git checkout -- rascunhos/servidor/nucleo`, depois `nucleo limpo: True`).

## Números das corridas (PC, Node 26.13, sobre `6a87b9e` + este ramo)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` (sem `--permission`) | **418/418**, 0 saltados (`caixa-hud-jogadora` 9/9, `privacidade` 8/8) |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (11 passos; não tocada) |
| Conferência dos schemas (`PROTOCOLO_DUMP` + `conferir-schemas.py`) | **0 falhas** nas mensagens que saem (exit 0) |

No PC, a corrida **com** `--permission` dá 401 passam e 7 falham, todos testes de rede (V20 e ordem 30). É o mesmo
problema do ambiente registado nas ordens anteriores: o Node 26 daqui recusa a rede nesse modo. ~~No CI (Node 24) esses
testes saltam-se (ver B4).~~ (Corrigido pela Ordem CAIXA-TESTES-CORRECOES-4, B3. A frase dos «7 falham, todos de
rede» foi **re-verificada** no PC a 22/11/2026 sobre `f747427`: 401 passam, 7 falham, 10 saltados, e as 7 falhas são
todas `ERR_ACCESS_DENIED` com `permission: 'Net'`, ou seja, os 4 V20 e os 3 da ordem 30. O erro estava na frase
seguinte. No CI (Node 24) esses 7 testes de rede **passam**; os 10 **saltados** são outros, 8 de disco e 2 de leitura
de `../protocolo` (ver B4).) Não corri os testes Godot do cliente porque nada do cliente mudou; quem os cobre é o CI.

## CI deste ramo (em `eb74bb7`, o commit das listas)

- **«Testes dos rascunhos»**, run 44979062131: **10/10 jobs verdes** (servidor, validador-glb, motor-real, protocolo,
  cliente, godot-cliente, ponta-a-ponta, provas-mapa, foto-mestre, **retoma-pc**).
  - job `servidor`: `tests 418 · pass 408 · fail 0 · skipped 10`, e a Prova da caixa dá **PROVA OK** (B4).
  - job `protocolo`: `tests 418 · pass 418 · fail 0 · skipped 0` (B4).
- **«Sonda de privacidade»**, run 44979062216: verde.
- Este parágrafo foi acrescentado num commit a seguir, que só toca neste ficheiro (fora de `rascunhos/`). As listas da
  retoma não mudam com ele: corri o `actualizar-listas` outra vez e não houve diferença.

### As mutações (resumo; detalhe em B1, B3 e B6)

| | Mutação | Suite nova | (c) antiga | `privacidade` antiga |
|---|---|---|---|---|
| M13 | última semente do journal no snapshot da Party | 416/418: (c), «canários: nada do Mestre…» | **passa** | falha |
| M14 | Vida dos inimigos feridos no snapshot da Party | 415/418: (c), «canários…», fixture do Mestre | **passa** | falha |
| M15 | só `'Lobo Teste'` na figura pública | 415/418: (c), «canários…», fixture do Mestre | passa | **passa** |
| M16 | só os verbos na figura pública | 415/418: (c), «canários…», fixture do Mestre | passa | **passa** |
| M17 | `7777` só no snapshot de sincronização da jogadora | 410/418: (c) na linha da B6, «canários…», os 2 da fixture do Mestre, L1, CORR8 (a) ×2, MAPA-JOGÁVEL (f) | **passa** | falha |

## Pontos para o coordenador

1. **A (c) põe o orc em `(2,6)`** (opção `casaOrc` de `mesaEmCombate`) para o ataque ser válido. A ordem da Party no
   ponto continua `[H]`: o ataque é da heroína, que é a única a jogar antes do ponto.
2. **Os verbos são canários a partir de agora.** Se um dia a Party passar a narrar os golpes dos monstros com o verbo
   da ficha (hoje é «omisso registado para palavra do Mestre», `cliente/README.md`), estes quatro textos têm de sair de
   `TEXTOS_SO_MESTRE`, e isso é uma decisão, não um ajuste.
3. **Riscos registados na ordem, só lidos, sem mexer:**
   - `8642` continua sem prova de vida como número: só aparece dentro de `'1d20+8642'`, que é texto.
   - A B2 da ordem anterior compara a ordem filtrada com a bruta.
   - `41`/`61` são frágeis como canários.
   - O tripwire `contexto` é fail-closed por desenho.
4. **`NUMEROS_MESTRE_CAIXA` e `CHAVES_MESTRE_CAIXA` ficaram locais** em `caixa-hud-jogadora.test.mjs`. Só esse ficheiro
   as usa, por isso não há cópia nenhuma que possa derivar. (Corrigido pela Ordem CAIXA-TESTES-CORRECOES-4, B5: para
   `NUMEROS_MESTRE_CAIXA` isto era falso. Os valores eram cópia à mão dos das listas partilhadas e já tinham derivado:
   faltavam 8642, 5551 e 2468. A lista passou a derivar-se delas. `CHAVES_MESTRE_CAIXA` é própria e fica.)
5. **Ambiente do PC:** os números são da corrida sem `--permission` (ver acima).
6. O `ORDEM.md` da sede não foi tocado.
