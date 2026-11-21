# As grelhas servidor × arena (gerado por `ferramentas/tabela_grelhas.py`)

Regras de contagem (o que cada coluna conta):
- **água**: casas do juízo do servidor com `agua` verdadeiro. O gerador recalcula-as: corre `juizo-terreno.mjs` com a
  grelha **pedida** e a escala, sem figuras (a água é do terreno, não depende das figuras). Não estão nos JSON.
- **bloq. srv**: casas com `passavel` falso no juízo (`casasBloqueadas` do JSON). A água pisa-se e não conta.
- **juízo ≠ / motivo ≠**: casas em que o cliente diz bloqueada e o servidor não, ou o contrário; e casas bloqueadas
  com outro motivo (`juizoDiferente`, `motivosDiferentes`).
- **cob. afirmada ≠**: conta **só** as casas em que o servidor **afirma** a cobertura (≠ null) e o cliente tem outra
  (`coberturaAfirmadaDiferente`). É este o portão da ferramenta.
- **cob. não afirmada (cli ≠ ref)**: casas da faixa da borda em que o servidor diz `null` (`coberturaNaoAfirmada`) e,
  entre parênteses, quantas delas o cliente tem com outra cobertura que a do mapa de referência do pacote
  (`coberturaNaoAfirmadaClienteDifereDaReferencia`). É um campo **registado, não julgado**: a ferramenta não falha
  por ele.
- **figuras**: as figuras que o servidor colocou e a arena desenhou, contando a heroína. Nos casos «auto» são as 9
  casas livres mais a heroína (as bloqueadas são todas recusadas). Na grelha 1 foram pedidas 17 casas e recusadas 3
  (dois menires e um santuário): 14 + a heroína = 15.
- **marcos ok**: marcos do mapa dentro da grelha que o mapa do cliente bloqueia com o próprio nome e que caem no centro
  de uma casa do jogo (entrada em `marcos` do JSON). O gerador conta os que têm a casa bloqueada no servidor; a
  ferramenta exige também o mesmo nome (e passa).


### terreno-servidor-arena.json

prova: `cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd`

| # | pedida | servida | casas (dentro/fora zona livre) | água | bloq. srv | juízo ≠ | motivo ≠ | cob. afirmada ≠ | cob. não afirmada (cli ≠ ref) | desvio alt. máx (m) | desvio pé máx (m) | figuras (desvio m) | recusas | mover (bloq. no cli) | marcos ok |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 30×30 @ 1.5 | 30×30 @ 1.5 | 900 (400/500) | 47 | 43 | 0 | 0 | 0 | 76 (0) | 0 | 0 | 15 (0) | 3 | 41 (0) | 10/10 |
| 2 | 30×30 @ 2.0 | 30×30 @ 2.0 | 900 (196/704) | 66 | 50 | 0 | 0 | 0 | 98 (0) | 0 | 0 | 10 (0) | 0 | 30 (0) | 10/10 |
| 3 | 20×20 @ 1.5 | 20×20 @ 1.5 | 400 (400/0) | 0 | 0 | 0 | 0 | 0 | 75 (0) | 0 | 0 | 10 (0) | 0 | 47 (0) | 0/0 |
| 4 | 25×25 @ 1.5 | 25×25 @ 1.5 | 625 (400/225) | 12 | 16 | 0 | 0 | 0 | 78 (0) | 0 | 0 | 10 (0) | 16 | 52 (0) | 2/2 |
| 5 | 25×25 @ 1.0 | 25×25 @ 1.0 | 625 (625/0) | 0 | 0 | 0 | 0 | 0 | 184 (0) | 0 | 0 | 10 (0) | 0 | 91 (0) | 0/0 |
| 6 | 25×25 @ 2.0 | 25×25 @ 2.0 | 625 (225/400) | 43 | 46 | 0 | 0 | 0 | 37 (0) | 0 | 0 | 10 (0) | 46 | 21 (0) | 12/12 |
| 7 | 21×17 @ 1.0 | 21×17 @ 1.0 | 357 (357/0) | 0 | 0 | 0 | 0 | 0 | 87 (0) | 0 | 0 | 10 (0) | 0 | 90 (0) | 0/0 |
| 8 | 33×27 @ 2.0 | 33×27 @ 2.0 | 891 (225/666) | 61 | 59 | 0 | 0 | 0 | 103 (0) | 0 | 0 | 10 (0) | 59 | 29 (0) | 17/17 |
| 9 | 44×20 @ 1.5 | 44×20 @ 1.5 | 880 (400/480) | 15 | 24 | 0 | 0 | 0 | 107 (0) | 0 | 0 | 10 (0) | 24 | 50 (0) | 7/7 |
| 10 | 50×50 @ 1.5 | 50×50 @ 1.5 | 2500 (400/2100) | 131 | 152 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 152 | 51 (0) | 39/39 |
| 11 | 50×50 @ 1.0 | 75×75 @ 1.0 | 5625 (841/4784) | 301 | 348 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 348 | 108 (0) | 39/39 |
| 12 | 37×37 @ 2.0 | 37×37 @ 2.0 | 1369 (225/1144) | 75 | 94 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 94 | 31 (0) | 26/26 |
| 13 | 49×49 @ 1.5 | 49×49 @ 1.5 | 2401 (400/2001) | 131 | 150 | 0 | 0 | 0 | 87 (0) | 0 | 0 | 10 (0) | 150 | 52 (0) | 39/39 |
| 14 | 50×20 @ 1.5 | 50×20 @ 1.5 | 1000 (400/600) | 15 | 32 | 0 | 0 | 0 | 83 (0) | 0 | 0 | 10 (0) | 32 | 50 (0) | 9/9 |
| 15 | 20×50 @ 1.5 | 20×50 @ 1.5 | 1000 (400/600) | 15 | 36 | 0 | 0 | 0 | 75 (0) | 0 | 0 | 10 (0) | 36 | 43 (0) | 10/10 |
| 16 | 49×30 @ 1.5 | 49×30 @ 1.5 | 1470 (400/1070) | 71 | 90 | 0 | 0 | 0 | 90 (0) | 0 | 0 | 10 (0) | 90 | 49 (0) | 24/24 |
| 17 | 37×20 @ 2.0 | 37×20 @ 2.0 | 740 (210/530) | 26 | 37 | 0 | 0 | 0 | 51 (0) | 0 | 0 | 10 (0) | 37 | 31 (0) | 10/10 |
| 18 | 35×37 @ 2.0 | 35×37 @ 2.0 | 1295 (225/1070) | 75 | 92 | 0 | 0 | 0 | 64 (0) | 0 | 0 | 10 (0) | 92 | 31 (0) | 26/26 |

### terreno-servidor-arena-adaptada.json

prova: `provas/ordem-mapa-jogavel/provas-bancada/ferramentas/provar_terreno_servidor_mapa.gd (cópia adaptada de cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd)`

| # | pedida | servida | casas (dentro/fora zona livre) | água | bloq. srv | juízo ≠ | motivo ≠ | cob. afirmada ≠ | cob. não afirmada (cli ≠ ref) | desvio alt. máx (m) | desvio pé máx (m) | figuras (desvio m) | recusas | mover (bloq. no cli) | marcos ok |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 30×30 @ 1.5 | 30×30 @ 1.5 | 900 (400/500) | 47 | 43 | 0 | 0 | 0 | 76 (0) | 0 | 0 | 15 (0) | 3 | 41 (0) | 10/10 |
| 2 | 30×30 @ 2.0 | 30×30 @ 2.0 | 900 (196/704) | 66 | 50 | 0 | 0 | 0 | 98 (0) | 0 | 0 | 10 (0) | 0 | 30 (0) | 10/10 |
| 3 | 20×20 @ 1.5 | 20×20 @ 1.5 | 400 (400/0) | 0 | 0 | 0 | 0 | 0 | 75 (0) | 0 | 0 | 10 (0) | 0 | 47 (0) | 0/0 |
| 4 | 25×25 @ 1.5 | 25×25 @ 1.5 | 625 (400/225) | 12 | 16 | 0 | 0 | 0 | 78 (0) | 0 | 0 | 10 (0) | 16 | 52 (0) | 2/2 |
| 5 | 25×25 @ 1.0 | 25×25 @ 1.0 | 625 (625/0) | 0 | 0 | 0 | 0 | 0 | 184 (0) | 0 | 0 | 10 (0) | 0 | 91 (0) | 0/0 |
| 6 | 25×25 @ 2.0 | 25×25 @ 2.0 | 625 (225/400) | 43 | 46 | 0 | 0 | 0 | 37 (0) | 0 | 0 | 10 (0) | 46 | 21 (0) | 12/12 |
| 7 | 21×17 @ 1.0 | 21×17 @ 1.0 | 357 (357/0) | 0 | 0 | 0 | 0 | 0 | 87 (0) | 0 | 0 | 10 (0) | 0 | 90 (0) | 0/0 |
| 8 | 33×27 @ 2.0 | 33×27 @ 2.0 | 891 (225/666) | 61 | 59 | 0 | 0 | 0 | 103 (0) | 0 | 0 | 10 (0) | 59 | 29 (0) | 17/17 |
| 9 | 44×20 @ 1.5 | 44×20 @ 1.5 | 880 (400/480) | 15 | 24 | 0 | 0 | 0 | 107 (0) | 0 | 0 | 10 (0) | 24 | 50 (0) | 7/7 |
| 10 | 50×50 @ 1.5 | 50×50 @ 1.5 | 2500 (400/2100) | 131 | 152 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 152 | 51 (0) | 39/39 |
| 11 | 50×50 @ 1.0 | 75×75 @ 1.0 | 5625 (841/4784) | 301 | 348 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 348 | 108 (0) | 39/39 |
| 12 | 37×37 @ 2.0 | 37×37 @ 2.0 | 1369 (225/1144) | 75 | 94 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 94 | 31 (0) | 26/26 |
| 13 | 49×49 @ 1.5 | 49×49 @ 1.5 | 2401 (400/2001) | 131 | 150 | 0 | 0 | 0 | 87 (0) | 0 | 0 | 10 (0) | 150 | 52 (0) | 39/39 |
| 14 | 50×20 @ 1.5 | 50×20 @ 1.5 | 1000 (400/600) | 15 | 32 | 0 | 0 | 0 | 83 (0) | 0 | 0 | 10 (0) | 32 | 50 (0) | 9/9 |
| 15 | 20×50 @ 1.5 | 20×50 @ 1.5 | 1000 (400/600) | 15 | 36 | 0 | 0 | 0 | 75 (0) | 0 | 0 | 10 (0) | 36 | 43 (0) | 10/10 |
| 16 | 49×30 @ 1.5 | 49×30 @ 1.5 | 1470 (400/1070) | 71 | 90 | 0 | 0 | 0 | 90 (0) | 0 | 0 | 10 (0) | 90 | 49 (0) | 24/24 |
| 17 | 37×20 @ 2.0 | 37×20 @ 2.0 | 740 (210/530) | 26 | 37 | 0 | 0 | 0 | 51 (0) | 0 | 0 | 10 (0) | 37 | 31 (0) | 10/10 |
| 18 | 35×37 @ 2.0 | 35×37 @ 2.0 | 1295 (225/1070) | 75 | 92 | 0 | 0 | 0 | 64 (0) | 0 | 0 | 10 (0) | 92 | 31 (0) | 26/26 |
