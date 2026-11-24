# ESTADO-FINAL — ORDEM-F4-PARCIAL (os dados físicos validados + os vetores-ouro)

**Estado: FEITA.**

O servidor confere agora cada face física declarada contra o dado da técnica. Um valor fora do intervalo é recusado e
fica gravado. Os vetores-ouro da JV0.3 têm **517 casos em 9 grupos** e dão **517/517 (100 %) no CI**. Duas gerações
em processos separados são byte-idênticas. O grep da regra no cliente dá **0**. CI verde (Testes + Sonda).

- **Executor:** Claude (opus), PC (conta 2). **Data:** 24/11/2026, das ~04:57 às ~06:40 (-03). Uma primeira corrida
  fez os 4 commits e as provas (~04:57-05:10). Esta corrida fechou o resto: redigiu os caminhos do PC nos logs e
  escreveu o README das provas e este ESTADO-FINAL.
- **Linha:** `fable/integracao-50`, trabalho directo, sem ramo. A `main` não foi tocada. Os workflows e os dados
  também não.
- **Ponta de partida:** `1e2baab`. Entretanto a F3 pôs 3 commits por cima (`04d29e6`, `a8efed6`, `cb759ec`), que só
  mexem em provas e em documentos da F3 (`git diff --stat bcf02d1 cb759ec -- rascunhos` vem vazio). Na ponta nova,
  os 7 testes dos dados físicos voltaram a passar (7/7).
- **Vigia:** a janela do PC fechou às 05:03 (AVISO-VIGIA). Depois disso só corri trabalho leve (um `node --test` de
  7 testes, sem Godot).

## 1. Os commits

| Commit | O quê |
|---|---|
| `2c76172` | Os dados físicos validados por intervalo no servidor (JV1.3, M-28; o TODO do `sala.js:201`) |
| `57b0f36` | As listas da retoma sincronizadas depois de `2c76172` (`actualizar-listas`: 2 novos, 0 tirados) |
| `f0ed40b` | Os vetores-ouro da JV0.3: 517 casos em 9 grupos, contra o motor oficial (SHA `a91c021c…`) |
| `bcf02d1` | As listas da retoma sincronizadas depois de `f0ed40b` (`actualizar-listas`: 13 novos, 0 tirados) |
| (este) | `provas/ordem-f4-parcial/` (README + logs) e este ESTADO-FINAL. Não mexe em `rascunhos/`, por isso não há sincronização das listas |

## 2. Dados físicos (JV1.3, M-28)

| Peça | O quê |
|---|---|
| `rascunhos/servidor/nucleo/dados-fisicos.js` (novo, puro, sem `node:*`) | Lê a expressão da técnica com a gramática do motor (`NdM(+NdM)*` com bónus, e componentes → repartição → `expressaoDano`). Confere cada face pela ordem em que o motor oficial as consome (`vlab-completo.js`, D10): primeiro os conjuntos do ataque (1 a 5, conforme a V/D líquida, que só o motor sabe) e depois os dados do dano. Na falha crítica entram o d100 da desgraça e o dano derivado |
| `rascunhos/servidor/nucleo/sala.js` | O `dadosFisicosBemFormados` só vê a forma. O intervalo confere-se em `aplicarIntencao`, no ramo `atacar`, com `conferirFacesFisicas`. **Fora do intervalo:** `ROOM_REJECT acao_invalida`, gravado (RECUSADA na consulta, e o mesmo `intentId` devolve a mesma recusa), sem cartão ao Mestre e sem vez gasta. O porquê (`DADOS_FISICOS_FORA_DO_INTERVALO: …`) vai só ao Mestre, no evento interno `recusa`. **Dentro:** como antes, `AGUARDANDO_MESTRE` e o cartão de dados |
| `rascunhos/servidor/testes/dados-fisicos.test.mjs` (novo) | 7 testes: 4 da função pura e 3 na sala (dentro passa, fora é recusado, a recusa fica gravada) |

O cliente Godot não calcula regra. As duas buscas do `logs/grep-regra-cliente.log` dão 0 achados, na ponta `bcf02d1`.

## 3. Vetores-ouro (JV0.3)

| Grupo | Casos |
|---|---|
| 01 ataque normal | 96 |
| 02 ataque crítico | 44 |
| 03 falha crítica e as 6 desgraças | 66 |
| 04 morte 3×3 | 68 |
| 05 Desvincular | 47 |
| 06 Defender | 40 |
| 07 transformação | 30 |
| 08 consumíveis | 24 |
| 09 acumulação do DMG | 102 |
| **Total** | **517** (≥ 500, cada grupo ≥ 20) |

- **Ficheiros:** `rascunhos/servidor/testes-motor-real/` → `vetores-ouro.mjs` (os casos), `gerar-vetores.mjs` (gera),
  `vetores-ouro.test.mjs` (4 testes) e `vetores-ouro/*.json` (9 grupos + `MANIFESTO.json`). Cada caso traz a entrada
  (com a semente ou as faces) e a saída. Cada ficheiro e o manifesto trazem o SHA-256 do motor.
- **Onde correm:** no job `motor-real` do CI (`MOTOR_MJS`, `testes-motor-real/*.test.mjs`), sem mudar o workflow.
  O motor **não** se copia para o repositório (regra do README da raiz). Com um motor diferente, o teste falha e avisa
  para regenerar e rever.
- **O que os vetores NÃO decidem:** os valores do Defender são fictícios (o valor é do Mestre). O grupo dos
  consumíveis congela a ausência de hoje (`consumiveis: []` e a intenção recusada), porque o conteúdo é do Mestre
  (JV0.6b). Quando o Mestre decidir, regeneram-se esses dois grupos e revêem-se. A transformação vai pelo caminho do
  servidor (a acção `transformar` e a `fichaEfetiva`), porque o `levelup.js` não chega ao job `motor-real`.

## 4. Os números

| Medição | Resultado |
|---|---|
| CI, job `motor-real`, run `45353754892` (ponta `bcf02d1`) | `VETORES-OURO 517/517 (100 %)`, com todos os grupos cheios. Os 4 testes dos vetores passam (o job inteiro: 6/6 testes, 0 falhas) |
| CI, os 10 jobs do run `45353754892` | todos `success` (servidor, ponta-a-ponta, provas-mapa, protocolo, cliente, motor-real, godot-cliente, validador-glb, foto-mestre, retoma-pc) |
| CI, Sonda de privacidade, run `45353754800` | `success` |
| PC, vetores com o motor vivo, 2 corridas | 517/517 nas duas, 0 falhas |
| PC, 2 gerações em processos separados | O `sha256sum` dos 10 ficheiros é igual nas duas e igual ao dos ficheiros gravados: byte-idênticas |
| PC, controlo com o motor mutado (um peso das desgraças 35→34) | Falha como deve: o SHA, 457/517 (só o grupo 03 cai, para 6/66) e os bytes |
| PC, dados físicos | 7/7 |
| PC, suite do servidor com `--allow-net` | 442 testes: 432 passam, **0 falham**, 10 saltados |
| PC, suite do servidor com o comando do CI (sem `--allow-net`) | 442: 425 passam, 7 falham, 10 saltados. As 7 são testes de rede (V20, ordem 30) com `ERR_ACCESS_DENIED` do Node 26 neste PC. **A ponta de antes, `1e2baab`, falha os mesmos 7.** São ambiente, não regra, e no CI passam |
| Grep da regra no cliente | 0 achados |

As provas estão em `provas/ordem-f4-parcial/` (README + `logs/`). Os caminhos absolutos do PC foram redigidos nos
logs.

## 5. O que ficou de fora (de propósito)

Os consumíveis (JV0.6b), a reacção A-4 e o valor do Defender, o dano do raio e as perguntas R0 esperam pelo Lote 2 das
decisões do Mestre. Nenhum deles foi tocado.
