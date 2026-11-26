# Relato do journal — corrida de 19:18–19:22 -03 na ponta c9fc4ab (anexo: o vídeo desta corrida foi apagado por um erro meu)

Fonte: `registo-MESTRE-ONLY-bancada-rede.json` (cópia bruta neste pacote: `journal/`), SHA-256 `37405871c57077683eef2f3a16ef7fbb89772416d07ff7fa14a37522d0893338`. Gerado por `ferramentas/relato.mjs` (todas as seqs, sem selecção).

Desfecho: **{"desfecho":"morte"}** (seq 81) · fase `fim` · rodada 9 · 81 eventos · seqs 1..81 sem buracos

Colocações: 3 (Arqueira de Bancada em (38,4); Lobo 1 em (36,3); Bruto 1 em (41,1)) · **ids repetidos: 0** · **casas repetidas: 0**

Conferências automáticas: **133 ✔, 0 ✘**.

## Regras declaradas (lidas no código que correu)

- **Crítico** (`vlab-completo.js` D4, `resolverAtaque`; `sala.js:1668`): NÃO sai do d20. O servidor gera à parte uma verificação de 3d6 por CSPRNG (`verificacaoCritico`, só no `soMestre`); é crítico se os dois primeiros forem 6 e o 3.º ≥ 5 − margem (a margem não é enviada: 0, por isso o 3.º tem de ser 5 ou 6). O crítico FORÇA o acerto, seja qual for o total, e o dano soma o máximo dos dados da técnica. Falha crítica = 1,1 e 3.º em {1,2}. Por isso um «[8] = 14 → CRÍTICO» é legítimo, e um «[20]» pode não ser crítico.
- **Testes de morte** (`vlab-completo.js` `resolverTesteDeMorte`, M3/T1–T9): só para quem tem testes de morte designados (a Arqueira; os monstros a 0 ficam «morta»). No início de cada vez dela, caída, rola-se a Fortitude: total = d20 + CON (o «+1» da expressão não entra: `bonusFonte: nenhum`) contra CD = CON + k da classificação (bronze: k = 3). Arqueira: CON 11 → CD 14, sucesso se total > 14, ou seja d20 ≥ 4. Sem crítico dentro do teste. Corrida 3×3: 3 sucessos estabilizam (fica caída com 1 de Vida e sem agir até uma cura — Q4, `sala.js:792`), 3 falhas matam. Dano directo enquanto está «aMorrer» soma +1 falha (crítico incluído: +1, nunca +2); estabilizada e ferida outra vez reentra a 0/0.
- **Recibos de duas faces** (`vlab-completo.js` D3; `sala.js:2001`): o ataque de oportunidade é resolvido com `niveisVantagem: 1`. Uma vantagem líquida = 2 conjuntos de 1d20, cada um com o bónus da ficha + 2 (= 2 × vantagem); fica o MAIOR. O recibo mostra os dois conjuntos separados por « | ». Cada um está explicado na tabela abaixo.
- **Distâncias**: a grelha é de 1,5 m por casa. Cada movimento é conferido passo a passo (ortogonal, 1 casa), custo = passos × 1,5 m, e contra a distância de Manhattan entre a origem e o destino. Nos ataques ficam registadas as distâncias de Manhattan e de Chebyshev entre as figuras naquele momento (os corpo-a-corpo na diagonal dão Manhattan 2 e Chebyshev 1).
- **Dano**: o journal não guarda as faces do dano (só a semente). Confere-se que cada dano cai dentro do intervalo da expressão da técnica (+ máximo dos dados no crítico, − RD do alvo).

## Os recibos de duas faces

Não há nesta batalha (nenhum ataque com vantagem/desvantagem).

## Distâncias dos movimentos contra Manhattan

| seq | figura | de → para | passos | Manhattan | custo |
|---|---|---|---|---|---|
| 7 | Arqueira de Bancada | (38,4) → (37,4) | 1 | 1 | 1.5 m |
| 14 | Bruto 1 | (41,1) → (39,3) | 4 | 4 | 6 m |
| 17 | Arqueira de Bancada | (37,4) → (38,4) | 1 | 1 | 1.5 m |
| 21 | Bruto 1 | (39,3) → (38,3) | 1 | 1 | 1.5 m |

## Testes de morte

| seq | d20 | total | CD | resultado | estadoMorte depois | desfecho |
|---|---|---|---|---|---|---|
| 35 | 13 | 24 | 14 | sucesso | {"falhas":0,"fase":"aMorrer","sucessos":1} | continua |
| 42 | 18 | 29 | 14 | sucesso | {"falhas":0,"fase":"aMorrer","sucessos":2} | continua |
| 50 | 10 | 21 | 14 | sucesso | {"falhas":1,"fase":"estabilizado","sucessos":3} | estabilizado |
| 59 | 7 | 18 | 14 | sucesso | {"falhas":0,"fase":"aMorrer","sucessos":1} | continua |
| 67 | 4 | 15 | 14 | sucesso | {"falhas":1,"fase":"aMorrer","sucessos":2} | continua |
| 74 | 3 | 14 | 14 | falha | {"falhas":2,"fase":"aMorrer","sucessos":2} | continua |

## Estado final das figuras

| figura | vida | vivo | caído | posição | estadoMorte |
|---|---|---|---|---|---|
| Bruto 1 | 34 | true | false | (38,3) | null |
| Arqueira de Bancada | 0 | false | true | (38,4) | {"falhas":3,"fase":"aMorrer","sucessos":2} |
| Lobo 1 | 0 | false | false | (36,3) | null |

## O journal inteiro (todas as seqs)

| seq | hora (UTC) | evento | resumo | recibo (soMestre) | conferência |
|---|---|---|---|---|---|
| 1 | 22:17:49.024 | lobby | lobby |  |  |
| 2 | 22:17:49.131 | colocacao | Arqueira de Bancada (jogadora) em (38,4), id f280b7a10474f5ffc |  | vida inicial 22 (ficha arqueira-bancada) |
| 3 | 22:17:49.131 | turno | vez de Arqueira de Bancada · rodada 1 |  |  |
| 4 | 22:17:49.257 | colocacao | Lobo 1 (criatura) em (36,3), id fe5092d2cbf058a60 |  | vida inicial 16 (ficha lobo-bancada) |
| 5 | 22:17:49.381 | colocacao | Bruto 1 (criatura) em (41,1), id f10fc284f0635bb34 |  | vida inicial 34 (ficha bruto-bancada) |
| 6 | 22:17:49.496 | entrada | Arqueira de Bancada entra (jogadora) |  |  |
| 7 | 22:19:43.728 | movimento | Arqueira de Bancada (38,4)→(37,4) por (38,4)(37,4), 1.5 m, reserva 7.5 m |  | ✔ «de» = posição conhecida (38,4); ✔ 1 passo(s), todos ortogonais de 1 casa; ✔ custo = 1 × 1,5 m = 1.5 m; ✔ Manhattan (38,4)–(37,4) = 1 = passos (caminho mínimo) |
| 8 | 22:20:09.789 | ataque | Arqueira de Bancada → Lobo 1 (tiro-certeiro-bancada): critico | 1d20+6 → [8] = 14 vs CA 13 → CRITICO · dano 21 (perfurante) | ✔ expressão 1d20+6 (ficha arqueira-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 8 + 6 = 14; ✔ CA do alvo 13 (ficha lobo-bancada); ✔ verificação do crítico [6,6,6] → 6,6 e 3.º ≥ 5: CRÍTICO; o crítico força o acerto → critico; ✔ dano 21 dentro de 2d6+2 + 12 (máximo dos dados, crítico) = [16, 26]; ✔ totalEfectivo 21 = dano do recibo; ℹ distância Manhattan 2, Chebyshev 1 entre (37,4) e (36,3) |
| 9 | 22:20:09.789 | dano | Lobo 1 perde 21 (perfurante) — autor Arqueira de Bancada |  | ✔ = dano do ataque anterior; vida 16 − 21 = -5 → 0 (trava em 0) |
| 10 | 22:20:09.789 | estado | Lobo 1: morta |  | ✔ figura sem testes de morte designados: vida 0 → morta |
| 11 | 22:20:09.789 | estado | Arqueira de Bancada: de_pe · vida 22 |  | ✔ vida 22 = conta corrente 22 |
| 12 | 22:20:24.239 | turno | vez de Bruto 1 · rodada 1 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 13 | 22:20:24.242 | ia | IA de Bruto 1: mover → (39,3) — «Aproxima-se da jogadora.» |  |  |
| 14 | 22:20:24.242 | movimento | Bruto 1 (41,1)→(39,3) por (41,1)(40,1)(39,1)(39,2)(39,3), 6 m, reserva 0 m |  | ✔ «de» = posição conhecida (41,1); ✔ 4 passo(s), todos ortogonais de 1 casa; ✔ custo = 4 × 1,5 m = 6 m; ✔ Manhattan (41,1)–(39,3) = 4 = passos (caminho mínimo) |
| 15 | 22:20:24.244 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 16 | 22:20:24.244 | turno | vez de Arqueira de Bancada · rodada 2 |  |  |
| 17 | 22:20:38.538 | movimento | Arqueira de Bancada (37,4)→(38,4) por (37,4)(38,4), 1.5 m, reserva 7.5 m |  | ✔ «de» = posição conhecida (37,4); ✔ 1 passo(s), todos ortogonais de 1 casa; ✔ custo = 1 × 1,5 m = 1.5 m; ✔ Manhattan (37,4)–(38,4) = 1 = passos (caminho mínimo) |
| 18 | 22:20:58.758 | ataque | Arqueira de Bancada → Bruto 1 (arco-bancada): erro | 1d20+5 → [2] = 7 vs CA 12 → ERRA | ✔ expressão 1d20+5 (ficha arqueira-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 2 + 5 = 7; ✔ CA do alvo 12 (ficha bruto-bancada); ✔ verificação do crítico [1,2,6] → não é crítico; 7 ≤ 12 → erro; ℹ distância Manhattan 2, Chebyshev 1 entre (38,4) e (39,3) |
| 19 | 22:21:11.988 | turno | vez de Bruto 1 · rodada 2 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 20 | 22:21:11.990 | ia | IA de Bruto 1: mover → (38,3) — «Aproxima-se da jogadora.» |  |  |
| 21 | 22:21:11.990 | movimento | Bruto 1 (39,3)→(38,3) por (39,3)(38,3), 1.5 m, reserva 4.5 m |  | ✔ «de» = posição conhecida (39,3); ✔ 1 passo(s), todos ortogonais de 1 casa; ✔ custo = 1 × 1,5 m = 1.5 m; ✔ Manhattan (39,3)–(38,3) = 1 = passos (caminho mínimo) |
| 22 | 22:21:11.992 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 23 | 22:21:11.992 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): acerto | 1d20+4 → [16] = 20 vs CA 13 → ACERTA · dano 11 (contundente) | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 16 + 4 = 20; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [1,3,5] → não é crítico; 20 > 13 → acerto; ✔ dano 11 dentro de 1d10+3 = [4, 13]; ✔ totalEfectivo 11 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 24 | 22:21:11.992 | dano | Arqueira de Bancada perde 11 (contundente) — autor Bruto 1 |  | ✔ = dano do ataque anterior; vida 22 − 11 = 11 |
| 25 | 22:21:11.992 | estado | Arqueira de Bancada: de_pe · vida 11 |  | ✔ vida 11 = conta corrente 11 |
| 26 | 22:21:11.994 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 27 | 22:21:11.994 | turno | vez de Arqueira de Bancada · rodada 3 |  |  |
| 28 | 22:21:31.368 | turno | vez de Bruto 1 · rodada 3 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 29 | 22:21:31.370 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 30 | 22:21:31.370 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): acerto | 1d20+4 → [17] = 21 vs CA 13 → ACERTA · dano 12 (contundente) | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 17 + 4 = 21; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [6,4,5] → não é crítico; 21 > 13 → acerto; ✔ dano 12 dentro de 1d10+3 = [4, 13]; ✔ totalEfectivo 12 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 31 | 22:21:31.370 | dano | Arqueira de Bancada perde 12 (contundente) — autor Bruto 1 |  | ✔ = dano do ataque anterior; vida 11 − 12 = -1 → 0 (trava em 0) |
| 32 | 22:21:31.370 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":0,"fase":"aMorrer","sucessos":0} |  | ✔ vida 0 = conta corrente 0; ✔ nascimento da corrida de morte 0/0 (vida a 0) |
| 33 | 22:21:31.373 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 34 | 22:21:31.373 | turno | vez de Arqueira de Bancada · rodada 4 |  |  |
| 35 | 22:21:31.373 | teste_morte | teste de morte de Arqueira de Bancada: d20 [13] → teste de morte → aguenta-se · {"falhas":0,"fase":"aMorrer","sucessos":1} | teste de morte → aguenta-se | ✔ total = d20 13 + CON 11 = 24; ✔ CD = CON 11 + k 3 (bronze) = 14; ✔ 24 > 14 → sucesso (o d20 tem de ser ≥ 4); ✔ progressão 0✓/0✗ → 1✓/0✗ |
| 36 | 22:21:31.373 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":0,"fase":"aMorrer","sucessos":1} |  | ✔ vida 0 = conta corrente 0; ✔ estadoMorte igual à conta corrente aMorrer 1✓/0✗ |
| 37 | 22:21:46.965 | turno | vez de Bruto 1 · rodada 4 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 38 | 22:21:46.967 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 39 | 22:21:46.967 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): erro | 1d20+4 → [4] = 8 vs CA 13 → ERRA | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 4 + 4 = 8; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [5,1,5] → não é crítico; 8 ≤ 13 → erro; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 40 | 22:21:46.968 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 41 | 22:21:46.968 | turno | vez de Arqueira de Bancada · rodada 5 |  |  |
| 42 | 22:21:46.968 | teste_morte | teste de morte de Arqueira de Bancada: d20 [18] → teste de morte → aguenta-se · {"falhas":0,"fase":"aMorrer","sucessos":2} | teste de morte → aguenta-se | ✔ total = d20 18 + CON 11 = 29; ✔ CD = CON 11 + k 3 (bronze) = 14; ✔ 29 > 14 → sucesso (o d20 tem de ser ≥ 4); ✔ progressão 1✓/0✗ → 2✓/0✗ |
| 43 | 22:21:46.968 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":0,"fase":"aMorrer","sucessos":2} |  | ✔ vida 0 = conta corrente 0; ✔ estadoMorte igual à conta corrente aMorrer 2✓/0✗ |
| 44 | 22:21:55.582 | turno | vez de Bruto 1 · rodada 5 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 45 | 22:21:55.583 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 46 | 22:21:55.583 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): acerto | 1d20+4 → [19] = 23 vs CA 13 → ACERTA · dano 13 (contundente) | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 19 + 4 = 23; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [5,1,5] → não é crítico; 23 > 13 → acerto; ✔ dano 13 dentro de 1d10+3 = [4, 13]; ✔ totalEfectivo 13 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 47 | 22:21:55.583 | dano | Arqueira de Bancada perde 13 (contundente) — autor Bruto 1 |  | ✔ = dano do ataque anterior; vida 0 − 13 = -13 → 0 (trava em 0); ℹ dano directo a quem está «aMorrer»: +1 falha (0→1), regra T1 |
| 48 | 22:21:55.584 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 49 | 22:21:55.584 | turno | vez de Arqueira de Bancada · rodada 6 |  |  |
| 50 | 22:21:55.584 | teste_morte | teste de morte de Arqueira de Bancada: d20 [10] → teste de morte → estabilizou · {"falhas":1,"fase":"estabilizado","sucessos":3} | teste de morte → estabilizou | ✔ total = d20 10 + CON 11 = 21; ✔ CD = CON 11 + k 3 (bronze) = 14; ✔ 21 > 14 → sucesso (o d20 tem de ser ≥ 4); ✔ progressão 2✓/1✗ → 3✓/1✗; ℹ 3 sucessos → estabilizada: fica caída com 1 de Vida (Q4, sala.js:792) |
| 51 | 22:21:55.584 | estado | Arqueira de Bancada: caida · vida 1 · estadoMorte {"falhas":1,"fase":"estabilizado","sucessos":3} |  | ✔ vida 1 = conta corrente 1; ✔ estadoMorte igual à conta corrente estabilizado 3✓/1✗ |
| 52 | 22:22:04.082 | turno | vez de Bruto 1 · rodada 6 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 53 | 22:22:04.083 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 54 | 22:22:04.083 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): acerto | 1d20+4 → [15] = 19 vs CA 13 → ACERTA · dano 11 (contundente) | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 15 + 4 = 19; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [5,1,1] → não é crítico; 19 > 13 → acerto; ✔ dano 11 dentro de 1d10+3 = [4, 13]; ✔ totalEfectivo 11 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 55 | 22:22:04.083 | dano | Arqueira de Bancada perde 11 (contundente) — autor Bruto 1 |  | ✔ = dano do ataque anterior; vida 1 − 11 = -10 → 0 (trava em 0); ℹ estabilizada ferida outra vez: reentra a 0/0 (T1) |
| 56 | 22:22:04.083 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":0,"fase":"aMorrer","sucessos":0} |  | ✔ vida 0 = conta corrente 0; ✔ estadoMorte igual à conta corrente aMorrer 0✓/0✗ |
| 57 | 22:22:04.085 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 58 | 22:22:04.085 | turno | vez de Arqueira de Bancada · rodada 7 |  |  |
| 59 | 22:22:04.085 | teste_morte | teste de morte de Arqueira de Bancada: d20 [7] → teste de morte → aguenta-se · {"falhas":0,"fase":"aMorrer","sucessos":1} | teste de morte → aguenta-se | ✔ total = d20 7 + CON 11 = 18; ✔ CD = CON 11 + k 3 (bronze) = 14; ✔ 18 > 14 → sucesso (o d20 tem de ser ≥ 4); ✔ progressão 0✓/0✗ → 1✓/0✗ |
| 60 | 22:22:04.085 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":0,"fase":"aMorrer","sucessos":1} |  | ✔ vida 0 = conta corrente 0; ✔ estadoMorte igual à conta corrente aMorrer 1✓/0✗ |
| 61 | 22:22:13.136 | turno | vez de Bruto 1 · rodada 7 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 62 | 22:22:13.138 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 63 | 22:22:13.138 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): acerto | 1d20+4 → [10] = 14 vs CA 13 → ACERTA · dano 8 (contundente) | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 10 + 4 = 14; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [5,4,1] → não é crítico; 14 > 13 → acerto; ✔ dano 8 dentro de 1d10+3 = [4, 13]; ✔ totalEfectivo 8 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 64 | 22:22:13.138 | dano | Arqueira de Bancada perde 8 (contundente) — autor Bruto 1 |  | ✔ = dano do ataque anterior; vida 0 − 8 = -8 → 0 (trava em 0); ℹ dano directo a quem está «aMorrer»: +1 falha (0→1), regra T1 |
| 65 | 22:22:13.140 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 66 | 22:22:13.140 | turno | vez de Arqueira de Bancada · rodada 8 |  |  |
| 67 | 22:22:13.140 | teste_morte | teste de morte de Arqueira de Bancada: d20 [4] → teste de morte → aguenta-se · {"falhas":1,"fase":"aMorrer","sucessos":2} | teste de morte → aguenta-se | ✔ total = d20 4 + CON 11 = 15; ✔ CD = CON 11 + k 3 (bronze) = 14; ✔ 15 > 14 → sucesso (o d20 tem de ser ≥ 4); ✔ progressão 1✓/1✗ → 2✓/1✗ |
| 68 | 22:22:13.140 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":1,"fase":"aMorrer","sucessos":2} |  | ✔ vida 0 = conta corrente 0; ✔ estadoMorte igual à conta corrente aMorrer 2✓/1✗ |
| 69 | 22:22:22.108 | turno | vez de Bruto 1 · rodada 8 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 70 | 22:22:22.109 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 71 | 22:22:22.109 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): erro | 1d20+4 → [7] = 11 vs CA 13 → ERRA | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 7 + 4 = 11; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [1,4,4] → não é crítico; 11 ≤ 13 → erro; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 72 | 22:22:22.110 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 73 | 22:22:22.110 | turno | vez de Arqueira de Bancada · rodada 9 |  |  |
| 74 | 22:22:22.110 | teste_morte | teste de morte de Arqueira de Bancada: d20 [3] → teste de morte → agrava-se · {"falhas":2,"fase":"aMorrer","sucessos":2} | teste de morte → agrava-se | ✔ total = d20 3 + CON 11 = 14; ✔ CD = CON 11 + k 3 (bronze) = 14; ✔ 14 ≤ 14 → falha (o d20 tem de ser ≥ 4); ✔ progressão 2✓/1✗ → 2✓/2✗ |
| 75 | 22:22:22.110 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":2,"fase":"aMorrer","sucessos":2} |  | ✔ vida 0 = conta corrente 0; ✔ estadoMorte igual à conta corrente aMorrer 2✓/2✗ |
| 76 | 22:22:31.205 | turno | vez de Bruto 1 · rodada 9 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 77 | 22:22:31.207 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 78 | 22:22:31.207 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): acerto | 1d20+4 → [15] = 19 vs CA 13 → ACERTA · dano 11 (contundente) | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 15 + 4 = 19; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [4,2,6] → não é crítico; 19 > 13 → acerto; ✔ dano 11 dentro de 1d10+3 = [4, 13]; ✔ totalEfectivo 11 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 79 | 22:22:31.207 | dano | Arqueira de Bancada perde 11 (contundente) — autor Bruto 1 |  | ✔ = dano do ataque anterior; vida 0 − 11 = -11 → 0 (trava em 0); ℹ dano directo a quem está «aMorrer»: +1 falha (2→3), regra T1 |
| 80 | 22:22:31.207 | estado | Arqueira de Bancada: morta · vida 0 · estadoMorte {"falhas":3,"fase":"aMorrer","sucessos":2} |  | ✔ vida 0 = conta corrente 0; ✔ 3 falhas nos testes de morte → morta; ✔ estadoMorte igual à conta corrente aMorrer 2✓/3✗ |
| 81 | 22:22:31.207 | fim | fim {"desfecho":"morte"} |  |  |
