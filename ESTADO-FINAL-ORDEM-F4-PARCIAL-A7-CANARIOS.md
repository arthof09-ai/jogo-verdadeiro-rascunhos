# ESTADO-FINAL — ORDEM-F4-PARCIAL-A7-CANARIOS (errata A-7: os três canários do grupo 07)

**Estado: FEITA.** Troquei os três canários na l. 225 com o texto exacto da ordem e regenerei só o grupo 07.
Resultado: **30/30 no grupo 07 e 517/517 no total**, no PC e no CI (job `motor-real` verde).

- **Executor:** Claude (opus), PC, conta 2. **Data:** 24/11/2026, ~08:00–08:15 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo, a partir da ponta `e8b9dc3`. A `main` não foi tocada. Não
  reescrevi história.
- **Não toquei** no motor, no servidor, nos dados nem nos outros 8 grupos dos vetores-ouro.

## 1. A troca (VO l. 225)

```js
  h.paTotal = 20; h.vidaTotal = 60; h.ca = 12; // fictícios (os canários 4040, 5150 e 5551 da fixture não importam aqui: o guião não varre privacidade)
```

É a única linha mudada no guião (`git diff` de 1 linha).

## 2. A regeneração (só o grupo 07)

- Gerei os vetores duas vezes, em processos separados e em pastas à parte, com o motor `a91c021c…`. As duas corridas
  são byte-idênticas.
- Comparei com os ficheiros gravados antes da troca. Só diferem o `07-transformacao.json` e o `MANIFESTO.json`; os
  outros 8 grupos saem byte-iguais.
- Para o repositório copiei **só esses dois ficheiros**.

| Ficheiro | SHA antes | SHA depois |
|---|---|---|
| `07-transformacao.json` | `43706ae3…` | `db2b87aec69b79c7788139b83735b09f3e01f15c65cee1f1e875b9c01d87dd4c` |
| `MANIFESTO.json` | `7b297ee5…` | `c06b6e1f94c055486065b3646b2de747bba05335363c5c887bb14ea85417e0af` |

No `MANIFESTO.json` muda só a linha do SHA do grupo 07. O total continua `517`, e o grupo 07 continua com 30 casos.

**Os canários saíram dos vetores.** No `07-transformacao.json`, o 5150 aparecia 74 vezes e agora aparece 0. O 5551
aparecia 30 vezes e agora aparece 0. O 4040 já estava a 0 e continua. A saída dos 30 casos mudou, porque a vida e a
CA da heroína entram nela.

Também actualizei os `provas/ordem-f4-parcial/logs/sha256-corrida-1.txt` e `-2.txt`. Só mudaram as linhas do 07 e
do MANIFESTO. Pus uma nota no README da F4-PARCIAL.

## 3. Os números

| Onde | Resultado |
|---|---|
| PC, `motor-real` antes da troca (linha de base) | 6/6 testes; 517/517; 07 a 30/30 com o SHA velho |
| PC, `motor-real` depois da troca, corrida 1 e corrida 2 | 6/6 testes em cada; **517/517**; **07 a 30/30**; bytes iguais aos gravados |
| CI, job `motor-real` (run `45380773607`, ponta `f71b070`) | motor `a91c021c…`; 6/6 testes; **517/517**; **07 a 30/30** |
| PC, suite do servidor (comando do CI + `--allow-net`) | 442 testes: 432 passam, **0 falham**, 10 saltados |
| CI, job `servidor` (run `45380773607`) | 442 testes: 432 passam, 0 falham, 10 saltados |
| CI, Testes dos rascunhos `45380773607` | `success`, 10/10 jobs (incluídos o `retoma-pc` e o `ponta-a-ponta`) |
| CI, Sonda de privacidade `45380773642` | `success` |

Por grupo, nas três corridas depois da troca: 01 96/96 · 02 44/44 · 03 66/66 · 04 68/68 · 05 47/47 · 06 40/40 ·
**07 30/30** · 08 24/24 · 09 102/102.

## 4. Os commits

| Commit | O quê |
|---|---|
| `b3c3c8d` | A troca na l. 225, o `07-transformacao.json` e o `MANIFESTO.json` regenerados, e os `sha256-corrida-*.txt` da F4-PARCIAL actualizados (com a nota no README dela) |
| `f71b070` | As listas da retoma sincronizadas com `retoma-i0004/actualizar-listas.py` depois do `b3c3c8d`: 0 novos, 0 tirados. Mudam só 3 SHAs, no `depois.txt` e no `MANIFESTO-SHA256.txt` |
| (este) | As provas (`provas/ordem-f4-parcial-a7-canarios/`) e este ESTADO-FINAL. Não muda `rascunhos/`, por isso não precisa de nova sincronização |

## 5. Provas

`provas/ordem-f4-parcial-a7-canarios/README.md` e os logs da pasta `logs/`: linha de base, duas gerações, os dois
`sha256sum`, a contagem dos canários, duas corridas do `motor-real`, o log do `motor-real` no CI e a suite do servidor.
Os caminhos do PC estão redigidos (`<pasta-da-ordem>`).
