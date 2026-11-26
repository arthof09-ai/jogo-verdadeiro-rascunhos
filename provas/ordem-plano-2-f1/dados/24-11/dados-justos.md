# D-AUD-15 — os dados do ataque, pelo caminho real

motor: motores.mjs · VLAB oficial SHA-256 a91c021cda11df675c78c63277e6f2679faa79c716c7ba104373198689993261 (o .mjs: 751c332c35bb3ae9fc7618d05e2c7effe2b761bf7986a557fb06c64ef5df18e2)
node v26.13.0 · 2026-11-24T00:53:13.701Z
journal: registo-MESTRE-ONLY-bancada-rede.json · vlabSha do estado a91c021cda11df675c78c63277e6f2679faa79c716c7ba104373198689993261 (= o motor desta corrida)

## (A) A sequência registada, reproduzida pelo servidor inteiro

A auditoria simulou a 1.ª saída do **xorshift32** (`novoCursorC`, vlab-completo.js:1115-1130). Esse cursor é o da
Parte C (validações de movimento e testes); o **ataque** tira as faces de `mulberry32(contexto.semente)`
(vlab-completo.js:788-801, `resolverAtaque`): face = 1 + ⌊rng()·20⌋, a 1.ª saída, sem sorteios antes.

| seq | semente | faces no journal | faces pelo servidor | recibo igual | 1.ª saída xorshift32 (a simulação da auditoria) |
|---|---|---|---|---|---|
| 30 | 2599056525 | [10] | [10] | sim | 13 |
| 45 | 1430019558 | [18] | [18] | sim | 15 |
| 56 | 1985287769 | [18] | [18] | sim | 15 |
| 67 | 1655933658 | [18] | [18] | sim | 15 |
| 78 | 2212477532 | [18] | [18] | sim | 7 |
| 89 | 3445070651 | [19] | [19] | sim | 16 |

**Reprodução: 6/6 iguais** (faces, recibo e semente do evento `ataque` = os do journal).

## (B) A distribuição das faces do d20 do ataque, N = 2 000 000 sementes por série

A entrada é a que a sala passou ao `Vlab.resolverAtaque` no passo A (gravada pela espia): heroína-teste, chicote
`1d20+4`, alvo CA 9137, sem vantagem nem desvantagem; só a semente muda.

| face | sementes 1..N (repetível): n · % · desvio (pp) | sementes do CSPRNG do servidor (rngNode): n · % · desvio (pp) |
|---|---|---|
| 1 | 100165 · 5.008 % · +0.008 | 100433 · 5.022 % · +0.022 |
| 2 | 100113 · 5.006 % · +0.006 | 99821 · 4.991 % · -0.009 |
| 3 | 100066 · 5.003 % · +0.003 | 99920 · 4.996 % · -0.004 |
| 4 | 99507 · 4.975 % · -0.025 | 99777 · 4.989 % · -0.011 |
| 5 | 100652 · 5.033 % · +0.033 | 100027 · 5.001 % · +0.001 |
| 6 | 100092 · 5.005 % · +0.005 | 100089 · 5.004 % · +0.004 |
| 7 | 99895 · 4.995 % · -0.005 | 99593 · 4.980 % · -0.020 |
| 8 | 100646 · 5.032 % · +0.032 | 99801 · 4.990 % · -0.010 |
| 9 | 99317 · 4.966 % · -0.034 | 99948 · 4.997 % · -0.003 |
| 10 | 100531 · 5.027 % · +0.027 | 100496 · 5.025 % · +0.025 |
| 11 | 100121 · 5.006 % · +0.006 | 99963 · 4.998 % · -0.002 |
| 12 | 99329 · 4.966 % · -0.034 | 99804 · 4.990 % · -0.010 |
| 13 | 99821 · 4.991 % · -0.009 | 99927 · 4.996 % · -0.004 |
| 14 | 100291 · 5.015 % · +0.015 | 100054 · 5.003 % · +0.003 |
| 15 | 99562 · 4.978 % · -0.022 | 99791 · 4.990 % · -0.010 |
| 16 | 100127 · 5.006 % · +0.006 | 100128 · 5.006 % · +0.006 |
| 17 | 99526 · 4.976 % · -0.024 | 99949 · 4.997 % · -0.003 |
| 18 | 100478 · 5.024 % · +0.024 | 100309 · 5.015 % · +0.015 |
| 19 | 99762 · 4.988 % · -0.012 | 99965 · 4.998 % · -0.002 |
| 20 | 99999 · 5.000 % · -0.000 | 100205 · 5.010 % · +0.010 |

- **sementes 1..N (repetível):** 2000000 resoluções (0 sem face), 1262 ms. Faces entre 4.966 % e 5.033 %; **maior desvio 0.034 pp** (barra ±0.06 pp: DENTRO). χ² = 31.97 com 19 g.l., p = 0.031. Pares seguidos (independência): χ² = 455.3 com 399 g.l., p = 0.027.
- **sementes do CSPRNG do servidor (rngNode):** 2000000 resoluções (0 sem face), 2500 ms. Faces entre 4.980 % e 5.025 %; **maior desvio 0.025 pp** (barra ±0.06 pp: DENTRO). χ² = 9.88 com 19 g.l., p = 0.956. Pares seguidos (independência): χ² = 390.1 com 399 g.l., p = 0.615.
- Desvio-padrão esperado por face com N = 2000000: 0.0154 pp (a barra ±0.06 pp = 3.9 σ). Com N = 200 000 seria 0.0487 pp (a barra = 1.2 σ: uma de 20 faces cai fora só por acaso na maioria das corridas). Por isso N = 2 000 000.

## A suspeita

- Em 6 lançamentos justos de d20, a probabilidade de haver **4 ou mais faces iguais seguidas** (qualquer face) é 0.037 % (2 000 000 simulações). Pouco provável numa sequência escolhida de antemão; numa auditoria que olha para muitas sequências à procura de um padrão, não é sinal de nada.
- As faces registadas saem **exactamente** das sementes registadas pelo caminho do jogo (passo A): não há sorteios escondidos antes da face, nem outra semente. A simulação da auditoria divergia por usar o gerador da Parte C (xorshift32).
- A distribuição da face do ataque sobre as sementes fica dentro da barra em todas as séries (passo B).
- As faces de resoluções seguidas não mostram dependência (teste dos pares, p > 0,001 nas duas séries).

**Veredicto: suspeita AFASTADA — os dados do ataque são justos e a sequência registada é a simulada.**
