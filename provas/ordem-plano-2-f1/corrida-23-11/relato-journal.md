# Relato do journal da corrida de 23/11 (22:04–22:10 -03), tirado do registo do Mestre

Fonte: `bancada-rede/privado/anteriores/2026-11-23_22-13-22/registo-MESTRE-ONLY-bancada-rede.json` (privado, fora do repositório). vlabSha a91c021cda11df675c78c63277e6f2679faa79c716c7ba104373198689993261. Código: `4739849` (o commit da F1, 22:01:59).

Desfecho: **morte** · fase `fim` · rodada 3 · eventos 72

Colocações: 4 (Arqueira de Bancada em (38,4); Lobo 1 em (36,4); Lobo 2 em (40,1); Bruto 1 em (43,0)) · **ids repetidos: 0** · casas repetidas: 0

Estado final das figuras:

| figura | ordinal | vida | vivo | estadoMorte |
|---|---|---|---|---|
| Arqueira de Bancada | — | 0 | false | {"falhas":3,"fase":"aMorrer","sucessos":1} |
| Lobo 1 | 1 | 7 | true | null |
| Lobo 2 | 2 | 16 | true | null |
| Bruto 1 | 1 | 34 | true | null |

| seq | hora (UTC) | evento | resumo | recibo (soMestre) |
|---|---|---|---|---|
| 2 | 01:04:19 | pausa | {"motivo":"mestre_desconectado"} |  |
| 3 | 01:05:04 | retomada | {"motivo":"mestre_desconectado"} |  |
| 4 | 01:05:26 | lobby | {} |  |
| 5 | 01:05:46 | colocacao | Arqueira de Bancada em (38,4) |  |
| 7 | 01:06:28 | colocacao | Lobo 1 em (36,4) |  |
| 8 | 01:06:40 | colocacao | Lobo 2 em (40,1) |  |
| 9 | 01:06:51 | colocacao | Bruto 1 em (43,0) |  |
| 10 | 01:07:17 | movimento | Arqueira de Bancada (38,4)→(36,2), 6 m |  |
| 11 | 01:07:17 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada, de oportunidade): acerto | 1d20+4 → [14] | [13] = 20 vs CA 13 → ACERTA · dano 6 (perfurante) |
| 12 | 01:07:17 | dano | Arqueira de Bancada perde 6 (perfurante) |  |
| 13 | 01:07:17 | estado | Arqueira de Bancada: vida 16 |  |
| 14 | 01:07:37 | ataque | Arqueira de Bancada → Lobo 1 (tiro-certeiro-bancada): acerto | 1d20+6 → [20] = 26 vs CA 13 → ACERTA · dano 9 (perfurante) |
| 15 | 01:07:37 | dano | Lobo 1 perde 9 (perfurante) |  |
| 16 | 01:07:37 | estado | Arqueira de Bancada: vida 16 |  |
| 19 | 01:08:16 | movimento | Lobo 1 (36,4)→(36,3), 1.5 m |  |
| 21 | 01:08:16 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada): acerto | 1d20+4 → [11] = 15 vs CA 13 → ACERTA · dano 6 (perfurante) |
| 22 | 01:08:16 | dano | Arqueira de Bancada perde 6 (perfurante) |  |
| 23 | 01:08:16 | estado | Arqueira de Bancada: vida 10 |  |
| 27 | 01:08:16 | movimento | Lobo 2 (40,1)→(36,1), 9 m |  |
| 29 | 01:08:16 | ataque | Lobo 2 → Arqueira de Bancada (mordida-bancada): acerto | 1d20+4 → [12] | [8] = 18 vs CA 13 → ACERTA · dano 6 (perfurante) |
| 30 | 01:08:16 | dano | Arqueira de Bancada perde 6 (perfurante) |  |
| 31 | 01:08:16 | estado | Arqueira de Bancada: vida 4 |  |
| 35 | 01:08:16 | movimento | Bruto 1 (43,0)→(39,0), 6 m |  |
| 38 | 01:08:48 | movimento | Arqueira de Bancada (36,2)→(31,1), 9 m |  |
| 39 | 01:08:48 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada, de oportunidade): acerto | 1d20+4 → [11] | [17] = 23 vs CA 13 → ACERTA · dano 6 (perfurante) |
| 40 | 01:08:48 | dano | Arqueira de Bancada perde 6 (perfurante) |  |
| 41 | 01:08:48 | estado | Arqueira de Bancada: vida 0, estadoMorte {"falhas":0,"fase":"aMorrer","sucessos":0} |  |
| 44 | 01:10:12 | movimento | Lobo 1 (36,3)→(32,1), 9 m |  |
| 46 | 01:10:12 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada): acerto | 1d20+4 → [11] = 15 vs CA 13 → ACERTA · dano 6 (perfurante) |
| 47 | 01:10:12 | dano | Arqueira de Bancada perde 6 (perfurante) |  |
| 51 | 01:10:12 | movimento | Lobo 2 (36,1)→(31,0), 9 m |  |
| 53 | 01:10:12 | ataque | Lobo 2 → Arqueira de Bancada (mordida-bancada): critico | 1d20+4 → [19] = 23 vs CA 13 → CRITICO · dano 14 (perfurante) |
| 54 | 01:10:12 | dano | Arqueira de Bancada perde 14 (perfurante) |  |
| 58 | 01:10:12 | movimento | Bruto 1 (39,0)→(35,0), 6 m |  |
| 61 | 01:10:12 | teste_morte | Arqueira de Bancada |  |
| 62 | 01:10:12 | estado | Arqueira de Bancada: vida 0, estadoMorte {"falhas":2,"fase":"aMorrer","sucessos":1} |  |
| 65 | 01:10:40 | ataque | Lobo 1 → Arqueira de Bancada (mordida-bancada): erro | 1d20+4 → [4] = 8 vs CA 13 → ERRA |
| 69 | 01:10:40 | ataque | Lobo 2 → Arqueira de Bancada (mordida-bancada): acerto | 1d20+4 → [20] = 24 vs CA 13 → ACERTA · dano 8 (perfurante) |
| 70 | 01:10:40 | dano | Arqueira de Bancada perde 8 (perfurante) |  |
| 71 | 01:10:40 | estado | Arqueira de Bancada: vida 0, estadoMorte {"falhas":3,"fase":"aMorrer","sucessos":1} |  |
| 72 | 01:10:40 | fim | {"desfecho":"morte"} |  |
