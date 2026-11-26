# ESTADO FINAL — ORDEM-PLANO-2-F1-FECHO · F4 (correcções documentais) + F5 (D-AUD-15 endurecido) + F6 (PANORAMA)

Dono: Muse (CM-000009). Linha `fable/integracao-50`, sem fusão. 26/11/2026, PC do cunhado. **Sem corrida nova**: não houve
bancada nem nova corrida da ferramenta com 2M.
Sentença de origem: a conferência da retoma da F1, **APROVADA COM RESSALVAS (entrega parcial), 817/1000**, follow-ups
F4–F6. Este ESTADO-FINAL não fecha a F1 inteira: a batalha de bancada na ponta, com vídeo, continua por fazer
(`ESTADO-FINAL-ORDEM-PLANO-2-F1-PARCIAL.md` §5).

## 0. Base

`git fetch` + `git ls-remote` ao arrancar: `fable/integracao-50` →
`c169e6c44a576a1a7837dccfcb40c1ec623a2829` (a nota do CI da ADENDA). Fiz um clone novo dessa ponta.

## 1. F4 — correcções documentais

As cinco correcções valem para este ESTADO-FINAL e foram escritas também no `ESTADO-FINAL-ORDEM-PLANO-2-F1-PARCIAL.md` e no
`provas/ordem-plano-2-f1/README.md`, cada um com uma nota no topo que as lista.

| | Antes | Agora (texto da sentença) | Onde está | Conferido |
|---|---|---|---|---|
| (a) | «igual byte a byte» | **as contagens da série 1..N são idênticas; os ficheiros diferem (ms, série CSPRNG, corrida4em6)** | PARCIAL §2.3; README, linha `dados/24-11/` | `cmp`: os dois `dados-justos.json` diferem na linha 64. As 20 contagens, o χ² (31,9714) e o χ² dos pares (455,2544) da série 1..N são iguais. Diferem `ms` (2569 / 1262), as 20 contagens da série CSPRNG e a `corrida4em6` (0,0003525 / 0,00037). |
| (b) | «Suspeita AFASTADA» | **suspeita não confirmada pela barra da ordem (±0,06 pp); χ² p=0,031 e pares p=0,027 na série 1..N ficam registados como sinal amarelo** | PARCIAL §2.3; README, secção «D-AUD-15: a leitura que vale» | O `dados-justos.md` e o `dados-26-11.log` são a saída da ferramenta e ficam como saíram. O README diz que a linha «Veredicto» deles se lê com este texto. |
| (c) | «19 de 19 na ponta», «corrida de dados na ponta» | **`279f0d7` + o caso 10** (o caso 10 é o `4caa2f1`, cometido depois das corridas) | PARCIAL §2.1 e o título do §2.3; README, as linhas `suites/`, `dados-justos` e `dados-26-11.log` | `dados-26-11.log`, linha 2: `# commit: 279f0d71… (+ o teste da câmara por cometer…)`; `resumo.txt`, linha 1: `# commit: 279f0d71…`. |
| (d) | `resumo.txt`: `d-aud-12-SEM-ORDINAL … falhas=11` | **o contador de falhas conta testes falhados, não linhas `✖`: o SEM-ORDINAL falha 5, não 11** | `suites/resumo.txt` (agora `falhas=5`, com uma linha `#` que o explica); `suites.sh` (função `falhas`); PARCIAL §3; README, as mutações | No log há 11 linhas `✖`: os 5 testes, o cabeçalho `✖ failing tests:` e os mesmos 5 repetidos. O node diz `ℹ fail 5`. O contador novo, corrido sobre os logs de 26/11, dá SEM-ORDINAL 5, SEM-FOCO 1, SEM-SEGUIR 4, servidor 0 e camera_segue 0. |
| (e) | o `servidor.log` sem menção no pacote | **o `servidor.log` (446/446) está no pacote de provas** | `provas/ordem-plano-2-f1/suites/servidor.log`, versionado desde o `5227011`; o README e o PARCIAL §3 citam-no agora | `ℹ tests 446 · ℹ pass 446 · ℹ fail 0`, 456 linhas, SHA-256 `008d5428325c52b2f2af7177cf8cb7b8b3e26b4addb8479232d3e516b2816f61`. |

## 2. F5 — o D-AUD-15 endurecido (sem nova corrida de 2M)

Tudo em `provas/ordem-plano-2-f1/dados/recontar/`, ao lado dos JSONs (o `README.md` da pasta tem o pormenor).

- **A tabela 20×20 dos pares seguidos da série 1..N** está em `pares-serie-1-N.csv` (1 999 999 pares). As 20 contagens
  estão em `faces-serie-1-N.csv`. Gerei-as com o `gerar-pares.mjs`, que não usa a ferramenta original nem o motor: só a
  `mulberry32` e a regra da 1.ª saída. As **20 contagens saem iguais às do `dados-justos.json`**, uma a uma.
- **A recontagem a partir do pacote** (`recontar.py`, Python com a biblioteca padrão, lê só os CSV) dá χ² das faces
  31,9714 (p = 0,0315) e χ² dos pares 455,2544 (p = 0,0269). São os números da ferramenta. Também se fazem numa folha de
  cálculo: E = 4999,9975 por casa, 399 g.l.
- **A semente do Monte Carlo da corrida4em6 não existe.** A ferramenta usou `rngNode()` (CSPRNG) sem semente, e por isso
  deu 0,037 % em 24/11 e 0,03525 % em 26/11. Em lugar da semente ficam **o valor exacto, 29/80000 = 0,03625 %** (q³(3 − 2q),
  q = 1/20, confirmado por programação dinâmica em fracções), e um Monte Carlo com semente publicada,
  `random.Random(20261126)`, M = 2 000 000 → 0,03515 %. Os dois valores antigos estão a menos de 1 σ do exacto.
- **Verificação das linhas 788-801 por leitura:** li o `vlab-completo.js` privado, com SHA-256 `a91c021c…`, igual ao
  `motorSha`. O `rng` nasce em `:790` de `mulberry32(ctx.semente)`. A única chamada até à 1.ª face é a de `:799`
  (`1 + Math.floor(rng() * lados)`). Com `1d20+4` sem vantagem nem desvantagem, a face é a **1.ª saída, sem sorteios
  antes**. As duas `mulberry32` do ficheiro (`:341` e `:691`, em IIFEs separadas) são iguais.
  **Ressalva:** quem leu fui eu (o dono, Muse), não um terceiro. Se a conferência exigir outra pessoa, vale
  «mecanismo por verificar por leitura; prova operacional: reprodução 6/6». A prova operacional ficou mais forte: as 20
  contagens de 2M sementes, recontadas fora da ferramenta, só batem se a face for a 1.ª saída em todas as sementes.
- **Critério de aceite** (um terceiro reconta pares e corrida4em6 a partir do pacote sem correr a ferramenta original): o
  `recontar.py` e a fórmula da corrida4em6 fazem-no só com o que está em `dados/recontar/`.

## 3. F6 — PANORAMA: o caso está verde (não precisou de ressalva)

`rascunhos/cliente/testes/camera_segue.gd`, **caso 11**: a colocação dela chega como evento com a câmara já em
**PANORAMA** (snapshot do lobby, `definir_modo(PANORAMA)`, depois o evento `colocacao` dela na casa (38, 4)).

| Verificação | Resultado |
|---|---|
| No Panorama a imagem continua no centro da arena (`_foco_alvo()` = centro; o Panorama não usa o foco) | ok |
| Mas a primeira vez fica feita: `camera.foco` = a casa dela e `_focou = true` | ok |
| De volta à Fixa, **sem mais eventos**, ela está no terço central | ok, (0,500; 0,500) |

- **`camera_segue`: 22 de 22**, exit 0, 0 erros de script, sobre `d5ceb8a` (o caso 11 é o `529b126`; corri-o antes de o
  cometer, sobre `1e7f803`, e o `arena.gd` não mudou).
- **Mutações, as duas repostas:**
  - SEM-FOCO-NO-EVENTO (`if _focar_primeira_vez():` → `if false and …`) dá **19 de 22**. Falham o caso 10 e as duas
    verificações do foco no caso 11.
  - PANORAMA-NAO-FOCA, uma mutação nova (`return false` no `_focar_primeira_vez` quando o modo é PANORAMA), dá
    **20 de 22**. Só falha o caso 11. Antes dele, nenhum caso via esta mutação.
- O código (`arena.gd`, `camera_mesa.gd`) não mudou: o caminho já estava certo, só faltava prová-lo.
- `ci/passo-camera-segue.patch` espera agora «22 de 22» (`git apply --check` OK). **Continua por aplicar**: o token deste PC
  não tem o âmbito `workflow`.

## 4. Suites desta ordem (Godot 4.7.2 `--headless`, depois do `--import` do clone novo)

Mudaram um teste do Godot e documentos, e não mudou código do jogo. Por isso corri só o que estas mudanças tocam:

| Suite | Resultado | Log |
|---|---|---|
| `camera_segue` | 22 de 22 | `provas/ordem-plano-2-f1-fecho/suites/camera_segue.log` |
| `camera_segue-SEM-FOCO-NO-EVENTO` · `-PANORAMA-NAO-FOCA` | 19 de 22 · 20 de 22 (repostas) | idem |
| canário de privacidade | **10 de 10** | `…/canario_privacidade.log` |
| sonda dos caminhos do PC (cópia limpa, `git archive`) | 0 novas, exit 0 | `…/sonda-caminhos-copia-limpa.log` |
| listas da retoma | 0 novos, 0 tirados (`camera_segue.gd` `9a147723…` → `5473c72d…`) | `…/actualizar-listas.log` |
| recontagem do D-AUD-15 | iguais à ferramenta (§2) | `provas/ordem-plano-2-f1/dados/recontar/recontar.txt` |

Não voltei a correr o servidor (446/446 na F1, 453/453 na ADENDA), porque nada do servidor mudou. O CI corre-o (§6).
Privacidade: só nomes fictícios; os caminhos do PC não aparecem nas provas novas.

## 5. Commits

| Commit | O quê |
|---|---|
| `2f7b6f6` | F4: as cinco correcções, no PARCIAL, no README, no `resumo.txt` e no `suites.sh`, e este ESTADO-FINAL (§1). **Por engano levou também** os ficheiros gerados do F5 (`dados/recontar/`: `gerar-pares.mjs`, `recontar.py` e os CSV). Não reescrevi a linha. |
| `1e7f803` | F5: o README e a saída da recontagem, a leitura das linhas 788-801 e o §2 |
| `529b126` | F6: o caso 11 do `camera_segue`, as mutações e o patch do CI a «22 de 22» |
| `d5ceb8a` | listas da retoma sincronizadas |
| (este) | os logs das suites do fecho e este ESTADO-FINAL completo |
| (o seguinte) | a nota do CI |

## 6. Nota do CI

(no commit seguinte)

## 7. O que continua aberto na F1 (fora desta ordem)

1. A batalha de bancada na ponta: acabada por morte, com vídeo dos dois ecrãs, as capturas do terço central e 0
   colocações duplicadas. Precisa do PC livre.
2. O «na vez» contra o banner em 20 vezes seguidas (D-AUD-03, a bancada do coordenador).
3. Aplicar `ci/passo-camera-segue.patch` («22 de 22»). Precisa de alguém com o âmbito `workflow`.
4. Se a conferência quiser, a leitura das linhas 788-801 por um terceiro (§2, ressalva).
