# Relato do journal — batalha F1 na ponta c9fc4ab, 26/11/2026 19:29–19:31 -03 (a corrida com vídeo)

Fonte: `registo-MESTRE-ONLY-bancada-rede.json` (cópia bruta neste pacote: `journal/`), SHA-256 `3f5f6e35882cee3dbb07642a0ecf3755d1ac85bc4e9aab2d287508682ecf9978`. Gerado por `ferramentas/relato.mjs` (todas as seqs, sem selecção).

Desfecho: **{"desfecho":"morte"}** (seq 78) · fase `fim` · rodada 6 · 78 eventos · seqs 1..78 sem buracos

Colocações: 3 (Arqueira de Bancada em (38,4); Lobo 1 em (36,3); Bruto 1 em (41,1)) · **ids repetidos: 0** · **casas repetidas: 0**

Conferências automáticas: **121 ✔, 0 ✘**.

## Regras declaradas (lidas no código que correu)

- **Crítico** (`vlab-completo.js` D4, `resolverAtaque`; `sala.js:1668`): NÃO sai do d20. O servidor gera à parte uma verificação de 3d6 por CSPRNG (`verificacaoCritico`, só no `soMestre`); é crítico se os dois primeiros forem 6 e o 3.º ≥ 5 − margem (a margem não é enviada: 0, por isso o 3.º tem de ser 5 ou 6). O crítico FORÇA o acerto, seja qual for o total, e o dano soma o máximo dos dados da técnica. Falha crítica = 1,1 e 3.º em {1,2}. Por isso um «[8] = 14 → CRÍTICO» é legítimo, e um «[20]» pode não ser crítico.
- **Testes de morte** (`vlab-completo.js` `resolverTesteDeMorte`, M3/T1–T9): só para quem tem testes de morte designados (a Arqueira; os monstros a 0 ficam «morta»). No início de cada vez dela, caída, rola-se a Fortitude: total = d20 + CON (o «+1» da expressão não entra: `bonusFonte: nenhum`) contra CD = CON + k da classificação (bronze: k = 3). Arqueira: CON 11 → CD 14, sucesso se total > 14, ou seja d20 ≥ 4. Sem crítico dentro do teste. Corrida 3×3: 3 sucessos estabilizam (fica caída com 1 de Vida e sem agir até uma cura — Q4, `sala.js:792`), 3 falhas matam. Dano directo enquanto está «aMorrer» soma +1 falha (crítico incluído: +1, nunca +2); estabilizada e ferida outra vez reentra a 0/0.
- **Recibos de duas faces** (`vlab-completo.js` D3; `sala.js:2001`): o ataque de oportunidade é resolvido com `niveisVantagem: 1`. Uma vantagem líquida = 2 conjuntos de 1d20, cada um com o bónus da ficha + 2 (= 2 × vantagem); fica o MAIOR. O recibo mostra os dois conjuntos separados por « | ». Cada um está explicado na tabela abaixo.
- **Distâncias**: a grelha é de 1,5 m por casa. Cada movimento é conferido passo a passo (ortogonal, 1 casa), custo = passos × 1,5 m, e contra a distância de Manhattan entre a origem e o destino. Nos ataques ficam registadas as distâncias de Manhattan e de Chebyshev entre as figuras naquele momento (os corpo-a-corpo na diagonal dão Manhattan 2 e Chebyshev 1).
- **Dano**: o journal não guarda as faces do dano (só a semente). Confere-se que cada dano cai dentro do intervalo da expressão da técnica (+ máximo dos dados no crítico, − RD do alvo).

## Os recibos de duas faces

| seq | atacante | recibo | faces | conta | porquê duas |
|---|---|---|---|---|---|
| 25 | Lobo 1 | 1d20+4 → [15] \| [4] = 21 vs CA 13 → ACERTA · dano 7 (perfurante) | [15] e [4] | 15+4+2=21 · 4+4+2=10 → maior = 21 | ataque de oportunidade (sala.js: niveisVantagem 1) |

## Distâncias dos movimentos contra Manhattan

| seq | figura | de → para | passos | Manhattan | custo |
|---|---|---|---|---|---|
| 7 | Arqueira de Bancada | (38,4) → (37,4) | 1 | 1 | 1.5 m |
| 13 | Lobo 1 | (36,3) → (37,3) | 1 | 1 | 1.5 m |
| 21 | Bruto 1 | (41,1) → (39,3) | 4 | 4 | 6 m |
| 24 | Arqueira de Bancada | (37,4) → (38,4) | 1 | 1 | 1.5 m |
| 31 | Lobo 1 | (37,3) → (38,3) | 1 | 1 | 1.5 m |
| 37 | Bruto 1 | (39,3) → (39,4) | 1 | 1 | 1.5 m |

## Testes de morte

| seq | d20 | total | CD | resultado | estadoMorte depois | desfecho |
|---|---|---|---|---|---|---|
| 64 | 1 | 12 | 14 | falha | {"falhas":1,"fase":"aMorrer","sucessos":0} | continua |
| 76 | 2 | 13 | 14 | falha | {"falhas":3,"fase":"aMorrer","sucessos":0} | morreu |

## Estado final das figuras

| figura | vida | vivo | caído | posição | estadoMorte |
|---|---|---|---|---|---|
| Bruto 1 | 34 | true | false | (39,4) | null |
| Arqueira de Bancada | 0 | false | false | (38,4) | {"falhas":3,"fase":"aMorrer","sucessos":0} |
| Lobo 1 | 8 | true | false | (38,3) | null |

## O journal inteiro (todas as seqs)

| seq | hora (UTC) | evento | resumo | recibo (soMestre) | conferência |
|---|---|---|---|---|---|
| 1 | 22:29:09.911 | lobby | lobby |  |  |
| 2 | 22:29:10.021 | colocacao | Arqueira de Bancada (jogadora) em (38,4), id fda7ef7392485a374 |  | vida inicial 22 (ficha arqueira-bancada) |
| 3 | 22:29:10.021 | turno | vez de Arqueira de Bancada · rodada 1 |  |  |
| 4 | 22:29:10.130 | colocacao | Lobo 1 (criatura) em (36,3), id ffebaea19d5ccd4a6 |  | vida inicial 16 (ficha lobo-bancada) |
| 5 | 22:29:10.239 | colocacao | Bruto 1 (criatura) em (41,1), id f14bc8a1805184105 |  | vida inicial 34 (ficha bruto-bancada) |
| 6 | 22:29:10.351 | entrada | Arqueira de Bancada entra (jogadora) |  |  |
| 7 | 22:29:30.198 | movimento | Arqueira de Bancada (38,4)→(37,4) por (38,4)(37,4), 1.5 m, reserva 7.5 m |  | ✔ «de» = posição conhecida (38,4); ✔ 1 passo(s), todos ortogonais de 1 casa; ✔ custo = 1 × 1,5 m = 1.5 m; ✔ Manhattan (38,4)–(37,4) = 1 = passos (caminho mínimo) |
| 8 | 22:29:52.447 | ataque | Arqueira de Bancada → Lobo 1 (tiro-certeiro-bancada): acerto | 1d20+6 → [10] = 16 vs CA 13 → ACERTA · dano 8 (perfurante) | ✔ expressão 1d20+6 (ficha arqueira-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 10 + 6 = 16; ✔ CA do alvo 13 (ficha lobo-bancada); ✔ verificação do crítico [3,5,3] → não é crítico; 16 > 13 → acerto; ✔ dano 8 dentro de 2d6+2 = [4, 14]; ✔ totalEfectivo 8 = dano do recibo; ℹ distância Manhattan 2, Chebyshev 1 entre (37,4) e (36,3) |
| 9 | 22:29:52.447 | dano | Lobo 1 perde 8 (perfurante) — autor Arqueira de Bancada |  | ✔ = dano do ataque anterior; vida 16 − 8 = 8 |
| 10 | 22:29:52.447 | estado | Arqueira de Bancada: de_pe · vida 22 |  | ✔ vida 22 = conta corrente 22 |
| 11 | 22:29:56.356 | turno | vez de Lobo 1 · rodada 1 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 12 | 22:29:56.360 | ia | IA de Lobo 1: mover → (37,3) — «Aproxima-se da jogadora.» |  |  |
| 13 | 22:29:56.360 | movimento | Lobo 1 (36,3)→(37,3) por (36,3)(37,3), 1.5 m, reserva 10.5 m |  | ✔ «de» = posição conhecida (36,3); ✔ 1 passo(s), todos ortogonais de 1 casa; ✔ custo = 1 × 1,5 m = 1.5 m; ✔ Manhattan (36,3)–(37,3) = 1 = passos (caminho mínimo) |
| 14 | 22:29:56.363 | ia | IA de Lobo 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 15 | 22:29:56.363 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada): acerto | 1d20+4 → [12] = 16 vs CA 13 → ACERTA · dano 6 (perfurante) | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 12 + 4 = 16; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [5,3,1] → não é crítico; 16 > 13 → acerto; ✔ dano 6 dentro de 1d6+2 = [3, 8]; ✔ totalEfectivo 6 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (37,3) e (37,4) |
| 16 | 22:29:56.363 | dano | Arqueira de Bancada perde 6 (perfurante) — autor Lobo 1 |  | ✔ = dano do ataque anterior; vida 22 − 6 = 16 |
| 17 | 22:29:56.363 | estado | Arqueira de Bancada: de_pe · vida 16 |  | ✔ vida 16 = conta corrente 16 |
| 18 | 22:29:56.366 | ia | IA de Lobo 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 19 | 22:29:56.366 | turno | vez de Bruto 1 · rodada 1 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 20 | 22:29:56.369 | ia | IA de Bruto 1: mover → (39,3) — «Aproxima-se da jogadora.» |  |  |
| 21 | 22:29:56.369 | movimento | Bruto 1 (41,1)→(39,3) por (41,1)(40,1)(39,1)(39,2)(39,3), 6 m, reserva 0 m |  | ✔ «de» = posição conhecida (41,1); ✔ 4 passo(s), todos ortogonais de 1 casa; ✔ custo = 4 × 1,5 m = 6 m; ✔ Manhattan (41,1)–(39,3) = 4 = passos (caminho mínimo) |
| 22 | 22:29:56.370 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 23 | 22:29:56.370 | turno | vez de Arqueira de Bancada · rodada 2 |  |  |
| 24 | 22:30:09.043 | movimento | Arqueira de Bancada (37,4)→(38,4) por (37,4)(38,4), 1.5 m, reserva 7.5 m |  | ✔ «de» = posição conhecida (37,4); ✔ 1 passo(s), todos ortogonais de 1 casa; ✔ custo = 1 × 1,5 m = 1.5 m; ✔ Manhattan (37,4)–(38,4) = 1 = passos (caminho mínimo) |
| 25 | 22:30:09.043 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada, de oportunidade): acerto | 1d20+4 → [15] \| [4] = 21 vs CA 13 → ACERTA · dano 7 (perfurante) | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 2 conjunto(s) = 1 + \|vantagem líquida 1\|; ✔ duas faces: [15] + 4 (bónus da ficha) + 2 (vantagem 1 × 2) = 21 e [4] + 4 (bónus da ficha) + 2 (vantagem 1 × 2) = 10; fica o maior = 21; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [2,2,5] → não é crítico; 21 > 13 → acerto; ✔ dano 7 dentro de 1d6+2 = [3, 8]; ✔ totalEfectivo 7 = dano do recibo; ℹ distância Manhattan 2, Chebyshev 1 entre (37,3) e (38,4) |
| 26 | 22:30:09.043 | dano | Arqueira de Bancada perde 7 (perfurante) — autor Lobo 1 |  | ✔ = dano do ataque anterior; vida 16 − 7 = 9 |
| 27 | 22:30:09.043 | estado | Arqueira de Bancada: de_pe · vida 9 |  | ✔ vida 9 = conta corrente 9 |
| 28 | 22:30:31.681 | ataque | Arqueira de Bancada → Bruto 1 (arco-bancada): erro | 1d20+5 → [6] = 11 vs CA 12 → ERRA | ✔ expressão 1d20+5 (ficha arqueira-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 6 + 5 = 11; ✔ CA do alvo 12 (ficha bruto-bancada); ✔ verificação do crítico [4,2,3] → não é crítico; 11 ≤ 12 → erro; ℹ distância Manhattan 2, Chebyshev 1 entre (38,4) e (39,3) |
| 29 | 22:30:36.048 | turno | vez de Lobo 1 · rodada 2 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 30 | 22:30:36.050 | ia | IA de Lobo 1: mover → (38,3) — «Aproxima-se da jogadora.» |  |  |
| 31 | 22:30:36.050 | movimento | Lobo 1 (37,3)→(38,3) por (37,3)(38,3), 1.5 m, reserva 10.5 m |  | ✔ «de» = posição conhecida (37,3); ✔ 1 passo(s), todos ortogonais de 1 casa; ✔ custo = 1 × 1,5 m = 1.5 m; ✔ Manhattan (37,3)–(38,3) = 1 = passos (caminho mínimo) |
| 32 | 22:30:36.051 | ia | IA de Lobo 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 33 | 22:30:36.051 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada): erro | 1d20+4 → [6] = 10 vs CA 13 → ERRA | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 6 + 4 = 10; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [4,2,4] → não é crítico; 10 ≤ 13 → erro; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 34 | 22:30:36.055 | ia | IA de Lobo 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 35 | 22:30:36.055 | turno | vez de Bruto 1 · rodada 2 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 36 | 22:30:36.056 | ia | IA de Bruto 1: mover → (39,4) — «Aproxima-se da jogadora.» |  |  |
| 37 | 22:30:36.056 | movimento | Bruto 1 (39,3)→(39,4) por (39,3)(39,4), 1.5 m, reserva 4.5 m |  | ✔ «de» = posição conhecida (39,3); ✔ 1 passo(s), todos ortogonais de 1 casa; ✔ custo = 1 × 1,5 m = 1.5 m; ✔ Manhattan (39,3)–(39,4) = 1 = passos (caminho mínimo) |
| 38 | 22:30:36.058 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 39 | 22:30:36.058 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): erro | 1d20+4 → [7] = 11 vs CA 13 → ERRA | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 7 + 4 = 11; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [3,4,5] → não é crítico; 11 ≤ 13 → erro; ℹ distância Manhattan 1, Chebyshev 1 entre (39,4) e (38,4) |
| 40 | 22:30:36.061 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 41 | 22:30:36.061 | turno | vez de Arqueira de Bancada · rodada 3 |  |  |
| 42 | 22:30:44.061 | turno | vez de Lobo 1 · rodada 3 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 43 | 22:30:44.064 | ia | IA de Lobo 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 44 | 22:30:44.064 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada): erro | 1d20+4 → [5] = 9 vs CA 13 → ERRA | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 5 + 4 = 9; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [6,4,2] → não é crítico; 9 ≤ 13 → erro; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 45 | 22:30:44.067 | ia | IA de Lobo 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 46 | 22:30:44.067 | turno | vez de Bruto 1 · rodada 3 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 47 | 22:30:44.068 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 48 | 22:30:44.068 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): erro | 1d20+4 → [4] = 8 vs CA 13 → ERRA | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 4 + 4 = 8; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [2,4,1] → não é crítico; 8 ≤ 13 → erro; ℹ distância Manhattan 1, Chebyshev 1 entre (39,4) e (38,4) |
| 49 | 22:30:44.070 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 50 | 22:30:44.070 | turno | vez de Arqueira de Bancada · rodada 4 |  |  |
| 51 | 22:30:51.984 | turno | vez de Lobo 1 · rodada 4 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 52 | 22:30:51.986 | ia | IA de Lobo 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 53 | 22:30:51.986 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada): acerto | 1d20+4 → [11] = 15 vs CA 13 → ACERTA · dano 6 (perfurante) | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 11 + 4 = 15; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [5,2,4] → não é crítico; 15 > 13 → acerto; ✔ dano 6 dentro de 1d6+2 = [3, 8]; ✔ totalEfectivo 6 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 54 | 22:30:51.986 | dano | Arqueira de Bancada perde 6 (perfurante) — autor Lobo 1 |  | ✔ = dano do ataque anterior; vida 9 − 6 = 3 |
| 55 | 22:30:51.986 | estado | Arqueira de Bancada: de_pe · vida 3 |  | ✔ vida 3 = conta corrente 3 |
| 56 | 22:30:51.989 | ia | IA de Lobo 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 57 | 22:30:51.989 | turno | vez de Bruto 1 · rodada 4 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 58 | 22:30:51.992 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 59 | 22:30:51.992 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): acerto | 1d20+4 → [19] = 23 vs CA 13 → ACERTA · dano 13 (contundente) | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 19 + 4 = 23; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [6,1,2] → não é crítico; 23 > 13 → acerto; ✔ dano 13 dentro de 1d10+3 = [4, 13]; ✔ totalEfectivo 13 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (39,4) e (38,4) |
| 60 | 22:30:51.992 | dano | Arqueira de Bancada perde 13 (contundente) — autor Bruto 1 |  | ✔ = dano do ataque anterior; vida 3 − 13 = -10 → 0 (trava em 0) |
| 61 | 22:30:51.992 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":0,"fase":"aMorrer","sucessos":0} |  | ✔ vida 0 = conta corrente 0; ✔ nascimento da corrida de morte 0/0 (vida a 0) |
| 62 | 22:30:51.996 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 63 | 22:30:51.996 | turno | vez de Arqueira de Bancada · rodada 5 |  |  |
| 64 | 22:30:51.996 | teste_morte | teste de morte de Arqueira de Bancada: d20 [1] → teste de morte → agrava-se · {"falhas":1,"fase":"aMorrer","sucessos":0} | teste de morte → agrava-se | ✔ total = d20 1 + CON 11 = 12; ✔ CD = CON 11 + k 3 (bronze) = 14; ✔ 12 ≤ 14 → falha (o d20 tem de ser ≥ 4); ✔ progressão 0✓/0✗ → 0✓/1✗ |
| 65 | 22:30:51.996 | estado | Arqueira de Bancada: caida · vida 0 · estadoMorte {"falhas":1,"fase":"aMorrer","sucessos":0} |  | ✔ vida 0 = conta corrente 0; ✔ estadoMorte igual à conta corrente aMorrer 0✓/1✗ |
| 66 | 22:31:00.047 | turno | vez de Lobo 1 · rodada 5 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 67 | 22:31:00.049 | ia | IA de Lobo 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 68 | 22:31:00.049 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada): erro | 1d20+4 → [2] = 6 vs CA 13 → ERRA | ✔ expressão 1d20+4 (ficha lobo-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 2 + 4 = 6; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [1,6,3] → não é crítico; 6 ≤ 13 → erro; ℹ distância Manhattan 1, Chebyshev 1 entre (38,3) e (38,4) |
| 69 | 22:31:00.051 | ia | IA de Lobo 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 70 | 22:31:00.051 | turno | vez de Bruto 1 · rodada 5 · narrada pelo Mestre (criatura; `narra: true`) |  |  |
| 71 | 22:31:00.052 | ia | IA de Bruto 1: atacar → Arqueira de Bancada — «Alvo ao alcance: ataca.» |  |  |
| 72 | 22:31:00.052 | ataque | Bruto 1 → Arqueira de Bancada (clava-bancada): acerto | 1d20+4 → [20] = 24 vs CA 13 → ACERTA · dano 13 (contundente) | ✔ expressão 1d20+4 (ficha bruto-bancada); ✔ 1 conjunto(s) = 1 + \|vantagem líquida 0\|; ✔ total 20 + 4 = 24; ✔ CA do alvo 13 (ficha arqueira-bancada); ✔ verificação do crítico [2,3,2] → não é crítico; 24 > 13 → acerto; ✔ dano 13 dentro de 1d10+3 = [4, 13]; ✔ totalEfectivo 13 = dano do recibo; ℹ distância Manhattan 1, Chebyshev 1 entre (39,4) e (38,4) |
| 73 | 22:31:00.052 | dano | Arqueira de Bancada perde 13 (contundente) — autor Bruto 1 |  | ✔ = dano do ataque anterior; vida 0 − 13 = -13 → 0 (trava em 0); ℹ dano directo a quem está «aMorrer»: +1 falha (1→2), regra T1 |
| 74 | 22:31:00.053 | ia | IA de Bruto 1: encerrar — «Nada a fazer: encerra.» |  |  |
| 75 | 22:31:00.053 | turno | vez de Arqueira de Bancada · rodada 6 |  |  |
| 76 | 22:31:00.053 | teste_morte | teste de morte de Arqueira de Bancada: d20 [2] → teste de morte → não resistiu · {"falhas":3,"fase":"aMorrer","sucessos":0} | teste de morte → não resistiu | ✔ total = d20 2 + CON 11 = 13; ✔ CD = CON 11 + k 3 (bronze) = 14; ✔ 13 ≤ 14 → falha (o d20 tem de ser ≥ 4); ✔ progressão 0✓/2✗ → 0✓/3✗ |
| 77 | 22:31:00.053 | estado | Arqueira de Bancada: morta · vida 0 · estadoMorte {"falhas":3,"fase":"aMorrer","sucessos":0} |  | ✔ vida 0 = conta corrente 0; ✔ 3 falhas nos testes de morte → morta; ✔ estadoMorte igual à conta corrente aMorrer 0✓/3✗ |
| 78 | 22:31:00.053 | fim | fim {"desfecho":"morte"} |  |  |
