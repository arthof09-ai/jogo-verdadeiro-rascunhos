# D-AUD-15 — os dados do ataque, pelo caminho real

motor: motores.mjs · VLAB oficial SHA-256 a91c021cda11df675c78c63277e6f2679faa79c716c7ba104373198689993261 (o .mjs: 751c332c35bb3ae9fc7618d05e2c7effe2b761bf7986a557fb06c64ef5df18e2)
node v26.13.0 · 2026-11-26T17:27:22.716Z
registados: registados-auditoria.json (6 ataques tirados do journal da auditoria em 24/11)

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
| 1 | 100165 · 5.008 % · +0.008 | 99683 · 4.984 % · -0.016 |
| 2 | 100113 · 5.006 % · +0.006 | 100383 · 5.019 % · +0.019 |
| 3 | 100066 · 5.003 % · +0.003 | 100069 · 5.003 % · +0.003 |
| 4 | 99507 · 4.975 % · -0.025 | 99591 · 4.980 % · -0.020 |
| 5 | 100652 · 5.033 % · +0.033 | 100226 · 5.011 % · +0.011 |
| 6 | 100092 · 5.005 % · +0.005 | 99864 · 4.993 % · -0.007 |
| 7 | 99895 · 4.995 % · -0.005 | 100405 · 5.020 % · +0.020 |
| 8 | 100646 · 5.032 % · +0.032 | 99930 · 4.997 % · -0.003 |
| 9 | 99317 · 4.966 % · -0.034 | 100034 · 5.002 % · +0.002 |
| 10 | 100531 · 5.027 % · +0.027 | 100095 · 5.005 % · +0.005 |
| 11 | 100121 · 5.006 % · +0.006 | 100245 · 5.012 % · +0.012 |
| 12 | 99329 · 4.966 % · -0.034 | 99705 · 4.985 % · -0.015 |
| 13 | 99821 · 4.991 % · -0.009 | 99468 · 4.973 % · -0.027 |
| 14 | 100291 · 5.015 % · +0.015 | 99775 · 4.989 % · -0.011 |
| 15 | 99562 · 4.978 % · -0.022 | 100495 · 5.025 % · +0.025 |
| 16 | 100127 · 5.006 % · +0.006 | 100210 · 5.011 % · +0.011 |
| 17 | 99526 · 4.976 % · -0.024 | 99963 · 4.998 % · -0.002 |
| 18 | 100478 · 5.024 % · +0.024 | 99717 · 4.986 % · -0.014 |
| 19 | 99762 · 4.988 % · -0.012 | 100360 · 5.018 % · +0.018 |
| 20 | 99999 · 5.000 % · -0.000 | 99782 · 4.989 % · -0.011 |

- **sementes 1..N (repetível):** 2000000 resoluções (0 sem face), 2569 ms. Faces entre 4.966 % e 5.033 %; **maior desvio 0.034 pp** (barra ±0.06 pp: DENTRO). χ² = 31.97 com 19 g.l., p = 0.031. Pares seguidos (independência): χ² = 455.3 com 399 g.l., p = 0.027.
- **sementes do CSPRNG do servidor (rngNode):** 2000000 resoluções (0 sem face), 6685 ms. Faces entre 4.973 % e 5.025 %; **maior desvio 0.027 pp** (barra ±0.06 pp: DENTRO). χ² = 16.96 com 19 g.l., p = 0.592. Pares seguidos (independência): χ² = 371.9 com 399 g.l., p = 0.831.
- Desvio-padrão esperado por face com N = 2000000: 0.0154 pp (a barra ±0.06 pp = 3.9 σ). Com N = 200 000 seria 0.0487 pp (a barra = 1.2 σ: uma de 20 faces cai fora só por acaso na maioria das corridas). Por isso N = 2 000 000.

## A suspeita

- Em 6 lançamentos justos de d20, a probabilidade de haver **4 ou mais faces iguais seguidas** (qualquer face) é 0.035 % (2 000 000 simulações). Pouco provável numa sequência escolhida de antemão; numa auditoria que olha para muitas sequências à procura de um padrão, não é sinal de nada.
- As faces registadas saem **exactamente** das sementes registadas pelo caminho do jogo (passo A): não há sorteios escondidos antes da face, nem outra semente. A simulação da auditoria divergia por usar o gerador da Parte C (xorshift32).
- A distribuição da face do ataque sobre as sementes fica dentro da barra em todas as séries (passo B).
- As faces de resoluções seguidas não mostram dependência (teste dos pares, p > 0,001 nas duas séries).

**Veredicto: suspeita AFASTADA — os dados do ataque são justos e a sequência registada é a simulada.**
