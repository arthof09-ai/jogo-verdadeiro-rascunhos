# D-AUD-15 recontável a partir do pacote (ORDEM-PLANO-2-F1-FECHO, F5)

O objectivo é que um terceiro reconte o χ² dos pares e a corrida4em6 **sem correr a ferramenta original**
(`../../ferramentas/dados-justos.mjs`) e **sem o motor privado**. Não houve corrida nova da ferramenta.

## O que está aqui

| Ficheiro | O quê |
|---|---|
| `pares-serie-1-N.csv` | **A tabela 20×20 dos pares seguidos da série 1..N** (N = 2 000 000). A linha é a face da semente s, a coluna a da semente s+1, para s = 1..N-1 (1 999 999 pares). SHA-256 `80028f0d…a8c8a8f9`. |
| `faces-serie-1-N.csv` | As 20 contagens da mesma série. SHA-256 `5aa5ee87…26597f20`. |
| `sementes-registadas.txt` | As 6 sementes da auditoria e a face que cada uma dá. |
| `gerar-pares.mjs` | Gera os três ficheiros de cima. Não importa nada do repositório nem do motor: só a `mulberry32` (o algoritmo público de Tommy Ettinger, igual à letra à de `vlab-completo.js:691-699`) e a regra «face = 1 + ⌊1.ª saída · 20⌋». |
| `recontar.py` | Lê **só** os dois CSV e recalcula o χ² das faces, o χ² dos pares e os valores de p. Calcula também a corrida4em6 exacta e um Monte Carlo com semente publicada. É Python com a biblioteca padrão, sem a ferramenta e sem o motor. |
| `recontar.txt` | A saída do `recontar.py` em 26/11. |

```
node provas/ordem-plano-2-f1/dados/recontar/gerar-pares.mjs --n=2000000   # opcional: regenera os CSV (~1 s)
python -I provas/ordem-plano-2-f1/dados/recontar/recontar.py              # reconta a partir dos CSV
```

Sem correr nada, a conta faz-se numa folha de cálculo sobre o `pares-serie-1-N.csv`. O esperado por casa é
E = 1 999 999 / 400 = 4999,9975, e χ² = Σ (O − E)² / E nas 400 casas, com 399 g.l.

## Resultado da recontagem (26/11)

| | Ferramenta original (`../dados-justos.json`) | Recontagem (`recontar.txt`) |
|---|---|---|
| 20 contagens da série 1..N | 100165, 100113, … , 99999 | **iguais, as 20** |
| χ² das faces (19 g.l.) | 31,9714 · p = 0,031 | 31,9714 · p = 0,0315 |
| χ² dos pares (399 g.l.) | 455,2544 · p = 0,027 | 455,2544 · p = 0,0269 |
| faces das 6 sementes registadas | 10, 18, 18, 18, 18, 19 (pelo servidor inteiro) | 10, 18, 18, 18, 18, 19 (só `mulberry32`) |

Os p = 0,031 e 0,027 da série 1..N ficam registados como **sinal amarelo**. Estão dentro da barra da ordem (±0,06 pp
por face), mas não são o «nada a ver» da série CSPRNG (p = 0,592 e 0,831).

## A corrida4em6 e a semente do Monte Carlo

**O Monte Carlo da ferramenta original não tem semente.** Usou `rngNode()`, o CSPRNG do servidor
(`dados-justos.mjs`, «a suspeita»), e por isso não se reproduz por construção: deu 0,037 % em 24/11 e 0,03525 % em 26/11.
Não há semente a publicar. Em lugar dela ficam:

- **o valor exacto, que não precisa de semente:** P(4 ou mais faces iguais seguidas em 6 d20 justos) = q³(3 − 2q), com q =
  1/20, = **29/80000 = 0,03625 %**. Em 6 lançamentos há 5 transições «igual à anterior» independentes, de probabilidade q;
  a corrida de 4 é haver 3 transições iguais seguidas, e há 3 sítios para a pôr. O `recontar.py` confirma-o por programação
  dinâmica em fracções;
- **um Monte Carlo com semente publicada:** `random.Random(20261126)` de Python, M = 2 000 000 → 703 → 0,03515 %. É uma
  simulação nova e pequena (não é a corrida de 2M sementes da ferramenta), e qualquer pessoa a repete com o mesmo número.

Os dois valores da ferramenta (0,037 % e 0,03525 %) estão a menos de 1 σ do exacto (σ ≈ 0,0013 pp com M = 2 000 000).

## Verificação das linhas 788-801 do motor, por leitura (26/11)

Li o `vlab-completo.js` privado (`bancada-rede/privado/`, fora do repositório), com SHA-256 `a91c021c…89993261`, igual ao
`motorSha` dos JSONs.

- `:790`: `const rng = !facesDadas && ctx.semente != null ? mulberry32(ctx.semente) : null;`. O gerador nasce **aqui**,
  dentro do `resolverAtaque` (`:720`), da semente do contexto. Antes desta linha nada o chama.
- `:799`: `if (rng) return { face: 1 + Math.floor(rng() * lados) };`, dentro de `tirar`. É o único sítio onde o `rng` é
  chamado até à 1.ª face.
- `:803-810`: o 1.º `tirar` é o do 1.º termo do 1.º conjunto. Com `1d20+4` e sem vantagem nem desvantagem
  (`nConjuntos = 1`), a face do d20 é a **1.ª saída** de `mulberry32(semente)`, sem sorteios antes.
- Há duas `mulberry32` no ficheiro (`:341` e `:691`), em IIFEs separadas (`:10-612` e `:614-1519`), e são iguais linha a
  linha. O `resolverAtaque` usa a de `:691`. É a mesma que está no `gerar-pares.mjs`.

**Quem leu:** o próprio dono (Muse, CM-000009, na sessão deste fecho), e não um terceiro. A prova operacional deixa de ser
só a reprodução 6/6. As 20 contagens de 2 000 000 sementes saem iguais de uma `mulberry32` isolada, sem o servidor nem o
motor, e isso só acontece se a face for mesmo a 1.ª saída sem sorteios antes, em todas as sementes. Se a conferência
exigir a leitura por outra pessoa, vale a frase da sentença: «mecanismo por verificar por leitura; prova operacional:
reprodução 6/6» (agora com as 20 contagens de 2M sementes recontadas fora da ferramenta).
