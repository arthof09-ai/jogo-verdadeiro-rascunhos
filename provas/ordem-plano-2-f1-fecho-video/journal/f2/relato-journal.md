# Relato do journal — F2 («na vez» 20×), 19:24–19:28 -03, modo manual

Fonte: `registo-MESTRE-ONLY-bancada-rede.json` (cópia bruta neste pacote: `journal/`), SHA-256 `537d46cf9ff9647ea2ec0640ec25772025d7f16c905bb0e08779f05e0554054e`. Gerado por `ferramentas/relato.mjs` (todas as seqs, sem selecção).

Desfecho: **sem fim** (seq undefined) · fase `combate` · rodada 7 · 53 eventos · seqs 1..53 sem buracos

Colocações: 3 (Arqueira de Bancada em (38,4); Lobo 1 em (36,3); Bruto 1 em (41,1)) · **ids repetidos: 0** · **casas repetidas: 0**

Conferências automáticas: **51 ✔, 0 ✘**.

## Regras declaradas (lidas no código que correu)

- **Crítico** (`vlab-completo.js` D4, `resolverAtaque`; `sala.js:1668`): NÃO sai do d20. O servidor gera à parte uma verificação de 3d6 por CSPRNG (`verificacaoCritico`, só no `soMestre`); é crítico se os dois primeiros forem 6 e o 3.º ≥ 5 − margem (a margem não é enviada: 0, por isso o 3.º tem de ser 5 ou 6). O crítico FORÇA o acerto, seja qual for o total, e o dano soma o máximo dos dados da técnica. Falha crítica = 1,1 e 3.º em {1,2}. Por isso um «[8] = 14 → CRÍTICO» é legítimo, e um «[20]» pode não ser crítico.
- **Testes de morte** (`vlab-completo.js` `resolverTesteDeMorte`, M3/T1–T9): só para quem tem testes de morte designados (a Arqueira; os monstros a 0 ficam «morta»). No início de cada vez dela, caída, rola-se a Fortitude: total = d20 + CON (o «+1» da expressão não entra: `bonusFonte: nenhum`) contra CD = CON + k da classificação (bronze: k = 3). Arqueira: CON 11 → CD 14, sucesso se total > 14, ou seja d20 ≥ 4. Sem crítico dentro do teste. Corrida 3×3: 3 sucessos estabilizam (fica caída com 1 de Vida e sem agir até uma cura — Q4, `sala.js:792`), 3 falhas matam. Dano directo enquanto está «aMorrer» soma +1 falha (crítico incluído: +1, nunca +2); estabilizada e ferida outra vez reentra a 0/0.
- **Recibos de duas faces** (`vlab-completo.js` D3; `sala.js:2001`): o ataque de oportunidade é resolvido com `niveisVantagem: 1`. Uma vantagem líquida = 2 conjuntos de 1d20, cada um com o bónus da ficha + 2 (= 2 × vantagem); fica o MAIOR. O recibo mostra os dois conjuntos separados por « | ». Cada um está explicado na tabela abaixo.
- **Distâncias**: a grelha é de 1,5 m por casa. Cada movimento é conferido passo a passo (ortogonal, 1 casa), custo = passos × 1,5 m, e contra a distância de Manhattan entre a origem e o destino. Nos ataques ficam registadas as distâncias de Manhattan e de Chebyshev entre as figuras naquele momento (os corpo-a-corpo na diagonal dão Manhattan 2 e Chebyshev 1).
- **Dano**: o journal não guarda as faces do dano (só a semente). Confere-se que cada dano cai dentro do intervalo da expressão da técnica (+ máximo dos dados no crítico, − RD do alvo).

## Os recibos de duas faces

| seq | atacante | recibo | faces | conta | porquê duas |
|---|---|---|---|---|---|
| 14 | Lobo 1 | 1d20+4 → [4] \| [3] = 10 vs CA 13 → ERRA | [4] e [3] | 4+4+2=10 · 3+4+2=9 → maior = 10 | ataque de oportunidade (sala.js: niveisVantagem 1) |
| 27 | Lobo 1 | 1d20+4 → [14] \| [1] = 20 vs CA 13 → ACERTA · dano 6 (perfurante) | [14] e [1] | 14+4+2=20 · 1+4+2=7 → maior = 20 | ataque de oportunidade (sala.js: niveisVantagem 1) |
| 42 | Lobo 1 | 1d20+4 → [6] \| [10] = 16 vs CA 13 → ACERTA · dano 4 (perfurante) | [6] e [10] | 6+4+2=12 · 10+4+2=16 → maior = 16 | ataque de oportunidade (sala.js: niveisVantagem 1) |

## Distâncias dos movimentos contra Manhattan

| seq | figura | de → para | passos | Manhattan | custo |
|---|---|---|---|---|---|
| 7 | Arqueira de Bancada | (38,4) → (39,3) | 2 | 2 | 3 m |
| 13 | Arqueira de Bancada | (39,3) → (37,4) | 3 | 3 | 4.5 m |
| 20 | Arqueira de Bancada | (37,4) → (39,3) | 3 | 3 | 4.5 m |
| 26 | Arqueira de Bancada | (39,3) → (37,4) | 3 | 3 | 4.5 m |
| 35 | Arqueira de Bancada | (37,4) → (39,3) | 3 | 3 | 4.5 m |
| 41 | Arqueira de Bancada | (39,3) → (37,4) | 3 | 3 | 4.5 m |
| 50 | Arqueira de Bancada | (37,4) → (39,3) | 3 | 3 | 4.5 m |

## Testes de morte

| seq | d20 | total | CD | resultado | estadoMorte depois | desfecho |
|---|---|---|---|---|---|---|

## Estado final das figuras

| figura | vida | vivo | caído | posição | estadoMorte |
|---|---|---|---|---|---|
| Bruto 1 | 34 | true | false | (41,1) | null |
| Arqueira de Bancada | 12 | true | false | (39,3) | null |
| Lobo 1 | 16 | true | false | (36,3) | null |

## O journal inteiro (todas as seqs)

| seq | hora (UTC) | evento | resumo | recibo (soMestre) | conferência |
|---|---|---|---|---|---|
| 1 | 22:23:56.915 | lobby | lobby |  |  |
| 2 | 22:23:57.038 | colocacao | Arqueira de Bancada (jogadora) em (38,4), id fb1005a9cc5081b31 |  | vida inicial 22 (ficha arqueira-bancada) |
| 3 | 22:23:57.038 | turno | vez de Arqueira de Bancada · rodada 1 |  |  |
| 4 | 22:23:57.163 | colocacao | Lobo 1 (criatura) em (36,3), id ff7b599a9615e55b6 |  | vida inicial 16 (ficha lobo-bancada) |
| 5 | 22:23:57.272 | colocacao | Bruto 1 (criatura) em (41,1), id f3edfa0e75641e2f9 |  | vida inicial 34 (ficha bruto-bancada) |
| 6 | 22:23:57.401 | entrada | Arqueira de Bancada entra (jogadora) |  |  |
| 7 | 22:24:42.096 | movimento | Arqueira de Bancada (38,4)→(39,3) por (38,4)(39,4)(39,3), 3 m, reserva 6 m |  | ✔ «de» = posição conhecida (38,4); ✔ 2 passo(s), todos ortogonais de 1 casa; ✔ custo = 2 × 1,5 m = 3 m; ✔ Manhattan (38,4)–(39,3) = 2 = passos (caminho mínimo) |
| 8 | 22:25:04.829 | turno | vez de Lobo 1 · rodada 1 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 9 | 22:25:09.094 | acao | {"figuraId":"ff7b599a9615e55b6","tipo":"correr"} |  |  |
| 10 | 22:25:12.439 | turno | vez de Bruto 1 · rodada 1 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 11 | 22:25:39.583 | acao | {"figuraId":"f3edfa0e75641e2f9","tipo":"correr"} |  |  |
| 12 | 22:25:43.037 | turno | vez de Arqueira de Bancada · rodada 2 |  |  |
| 13 | 22:25:49.840 | movimento | Arqueira de Bancada (39,3)→(37,4) por (39,3)(38,3)(37,3)(37,4), 4.5 m, reserva 4.5 m |  | ✔ «de» = posição conhecida (39,3); ✔ 3 passo(s), todos ortogonais de 1 casa; ✔ custo = 3 × 1,5 m = 4.5 m; ✔ Manhattan (39,3)–(37,4) = 3 = passos (caminho mínimo) |
| 14 | 22:25:49.840 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada, de oportunidade): erro | 1d20+4 → [4] \| [3] = 10 vs CA 13 → ERRA | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 2 conjunto(s) = 1 + \|vantagem líquida 1\|; ✔ duas faces: [4] + 4 (bónus da ficha) + 2 (vantagem 1 × 2) = 10 e [3] + 4 (bónus da ficha) + 2 (vantagem 1 × 2) = 9; fica o maior = 10; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [2,2,5] → não é crítico; 10 ≤ 13 → erro; ℹ distância Manhattan 2, Chebyshev 1 entre (36,3) e (37,4) |
| 15 | 22:25:55.647 | turno | vez de Lobo 1 · rodada 2 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 16 | 22:26:00.642 | acao | {"figuraId":"ff7b599a9615e55b6","tipo":"correr"} |  |  |
| 17 | 22:26:04.005 | turno | vez de Bruto 1 · rodada 2 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 18 | 22:26:09.955 | acao | {"figuraId":"f3edfa0e75641e2f9","tipo":"correr"} |  |  |
| 19 | 22:26:13.349 | turno | vez de Arqueira de Bancada · rodada 3 |  |  |
| 20 | 22:26:19.922 | movimento | Arqueira de Bancada (37,4)→(39,3) por (37,4)(38,4)(39,4)(39,3), 4.5 m, reserva 4.5 m |  | ✔ «de» = posição conhecida (37,4); ✔ 3 passo(s), todos ortogonais de 1 casa; ✔ custo = 3 × 1,5 m = 4.5 m; ✔ Manhattan (37,4)–(39,3) = 3 = passos (caminho mínimo) |
| 21 | 22:26:25.949 | turno | vez de Lobo 1 · rodada 3 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 22 | 22:26:30.882 | acao | {"figuraId":"ff7b599a9615e55b6","tipo":"correr"} |  |  |
| 23 | 22:26:34.293 | turno | vez de Bruto 1 · rodada 3 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 24 | 22:26:40.233 | acao | {"figuraId":"f3edfa0e75641e2f9","tipo":"correr"} |  |  |
| 25 | 22:26:43.868 | turno | vez de Arqueira de Bancada · rodada 4 |  |  |
| 26 | 22:26:50.406 | movimento | Arqueira de Bancada (39,3)→(37,4) por (39,3)(38,3)(37,3)(37,4), 4.5 m, reserva 4.5 m |  | ✔ «de» = posição conhecida (39,3); ✔ 3 passo(s), todos ortogonais de 1 casa; ✔ custo = 3 × 1,5 m = 4.5 m; ✔ Manhattan (39,3)–(37,4) = 3 = passos (caminho mínimo) |
| 27 | 22:26:50.406 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada, de oportunidade): acerto | 1d20+4 → [14] \| [1] = 20 vs CA 13 → ACERTA · dano 6 (perfurante) | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 2 conjunto(s) = 1 + \|vantagem líquida 1\|; ✔ duas faces: [14] + 4 (bónus da ficha) + 2 (vantagem 1 × 2) = 20 e [1] + 4 (bónus da ficha) + 2 (vantagem 1 × 2) = 7; fica o maior = 20; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [1,5,1] → não é crítico; 20 > 13 → acerto; ✔ dano 6 dentro de 1d6+2 = [3, 8]; ✔ totalEfectivo 6 = dano do recibo; ℹ distância Manhattan 2, Chebyshev 1 entre (36,3) e (37,4) |
| 28 | 22:26:50.406 | dano | Arqueira de Bancada perde 6 (perfurante) — autor Lobo 1 |  | ✔ = dano do ataque anterior; vida 22 − 6 = 16 |
| 29 | 22:26:50.406 | estado | Arqueira de Bancada: de_pe · vida 16 |  | ✔ vida 16 = conta corrente 16 |
| 30 | 22:26:56.114 | turno | vez de Lobo 1 · rodada 4 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 31 | 22:27:00.988 | acao | {"figuraId":"ff7b599a9615e55b6","tipo":"correr"} |  |  |
| 32 | 22:27:04.339 | turno | vez de Bruto 1 · rodada 4 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 33 | 22:27:10.539 | acao | {"figuraId":"f3edfa0e75641e2f9","tipo":"correr"} |  |  |
| 34 | 22:27:13.963 | turno | vez de Arqueira de Bancada · rodada 5 |  |  |
| 35 | 22:27:20.593 | movimento | Arqueira de Bancada (37,4)→(39,3) por (37,4)(38,4)(39,4)(39,3), 4.5 m, reserva 4.5 m |  | ✔ «de» = posição conhecida (37,4); ✔ 3 passo(s), todos ortogonais de 1 casa; ✔ custo = 3 × 1,5 m = 4.5 m; ✔ Manhattan (37,4)–(39,3) = 3 = passos (caminho mínimo) |
| 36 | 22:27:26.259 | turno | vez de Lobo 1 · rodada 5 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 37 | 22:27:31.223 | acao | {"figuraId":"ff7b599a9615e55b6","tipo":"correr"} |  |  |
| 38 | 22:27:34.574 | turno | vez de Bruto 1 · rodada 5 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 39 | 22:27:40.786 | acao | {"figuraId":"f3edfa0e75641e2f9","tipo":"correr"} |  |  |
| 40 | 22:27:44.131 | turno | vez de Arqueira de Bancada · rodada 6 |  |  |
| 41 | 22:27:50.738 | movimento | Arqueira de Bancada (39,3)→(37,4) por (39,3)(38,3)(37,3)(37,4), 4.5 m, reserva 4.5 m |  | ✔ «de» = posição conhecida (39,3); ✔ 3 passo(s), todos ortogonais de 1 casa; ✔ custo = 3 × 1,5 m = 4.5 m; ✔ Manhattan (39,3)–(37,4) = 3 = passos (caminho mínimo) |
| 42 | 22:27:50.738 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada, de oportunidade): acerto | 1d20+4 → [6] \| [10] = 16 vs CA 13 → ACERTA · dano 4 (perfurante) | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 2 conjunto(s) = 1 + \|vantagem líquida 1\|; ✔ duas faces: [6] + 4 (bónus da ficha) + 2 (vantagem 1 × 2) = 12 e [10] + 4 (bónus da ficha) + 2 (vantagem 1 × 2) = 16; fica o maior = 16; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [6,6,3] → não é crítico; 16 > 13 → acerto; ✔ dano 4 dentro de 1d6+2 = [3, 8]; ✔ totalEfectivo 4 = dano do recibo; ℹ distância Manhattan 2, Chebyshev 1 entre (36,3) e (37,4) |
| 43 | 22:27:50.738 | dano | Arqueira de Bancada perde 4 (perfurante) — autor Lobo 1 |  | ✔ = dano do ataque anterior; vida 16 − 4 = 12 |
| 44 | 22:27:50.738 | estado | Arqueira de Bancada: de_pe · vida 12 |  | ✔ vida 12 = conta corrente 12 |
| 45 | 22:27:56.396 | turno | vez de Lobo 1 · rodada 6 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 46 | 22:28:01.148 | acao | {"figuraId":"ff7b599a9615e55b6","tipo":"correr"} |  |  |
| 47 | 22:28:04.535 | turno | vez de Bruto 1 · rodada 6 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 48 | 22:28:10.638 | acao | {"figuraId":"f3edfa0e75641e2f9","tipo":"correr"} |  |  |
| 49 | 22:28:14.068 | turno | vez de Arqueira de Bancada · rodada 7 |  |  |
| 50 | 22:28:20.708 | movimento | Arqueira de Bancada (37,4)→(39,3) por (37,4)(38,4)(39,4)(39,3), 4.5 m, reserva 4.5 m |  | ✔ «de» = posição conhecida (37,4); ✔ 3 passo(s), todos ortogonais de 1 casa; ✔ custo = 3 × 1,5 m = 4.5 m; ✔ Manhattan (37,4)–(39,3) = 3 = passos (caminho mínimo) |
| 51 | 22:28:26.430 | turno | vez de Lobo 1 · rodada 7 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 52 | 22:28:31.485 | acao | {"figuraId":"ff7b599a9615e55b6","tipo":"correr"} |  |  |
| 53 | 22:28:34.964 | turno | vez de Bruto 1 · rodada 7 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
