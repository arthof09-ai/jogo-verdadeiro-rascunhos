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
| 1 | 30×30 @ 1.5 | 30×30 @ 1.5 | 900 (400/500) | 17 | 26 | 0 | 0 | 0 | 99 (1) | 0 | 0 | 15 (0) | 3 | 41 (0) | 6/6 |
| 2 | 30×30 @ 2.0 | 30×30 @ 2.0 | 900 (196/704) | 12 | 30 | 0 | 0 | 0 | 107 (0) | 0 | 0 | 10 (0) | 0 | 30 (0) | 4/4 |
| 3 | 20×20 @ 1.5 | 20×20 @ 1.5 | 400 (400/0) | 0 | 0 | 0 | 0 | 0 | 76 (1) | 0 | 0 | 10 (0) | 0 | 47 (0) | 0/0 |
| 4 | 25×25 @ 1.5 | 25×25 @ 1.5 | 625 (400/225) | 2 | 8 | 0 | 0 | 0 | 91 (2) | 0 | 0 | 10 (0) | 8 | 52 (0) | 0/0 |
| 5 | 25×25 @ 1.0 | 25×25 @ 1.0 | 625 (625/0) | 0 | 0 | 0 | 0 | 0 | 184 (2) | 0 | 0 | 10 (0) | 0 | 91 (0) | 0/0 |
| 6 | 25×25 @ 2.0 | 25×25 @ 2.0 | 625 (225/400) | 13 | 28 | 0 | 0 | 0 | 42 (3) | 0 | 0 | 10 (0) | 28 | 21 (0) | 5/5 |
| 7 | 21×17 @ 1.0 | 21×17 @ 1.0 | 357 (357/0) | 0 | 0 | 0 | 0 | 0 | 87 (0) | 0 | 0 | 10 (0) | 0 | 90 (0) | 0/0 |
| 8 | 33×27 @ 2.0 | 33×27 @ 2.0 | 891 (225/666) | 13 | 35 | 0 | 0 | 0 | 112 (4) | 0 | 0 | 10 (0) | 35 | 30 (0) | 7/7 |
| 9 | 44×20 @ 1.5 | 44×20 @ 1.5 | 880 (400/480) | 0 | 11 | 0 | 0 | 0 | 120 (3) | 0 | 0 | 10 (0) | 11 | 52 (0) | 2/2 |
| 10 | 50×50 @ 1.5 | 50×50 @ 1.5 | 2500 (400/2100) | 21 | 67 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 67 | 52 (0) | 14/14 |
| 11 | 50×50 @ 1.0 | 75×75 @ 1.0 | 5625 (841/4784) | 50 | 156 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 156 | 110 (0) | 14/14 |
| 12 | 37×37 @ 2.0 | 37×37 @ 2.0 | 1369 (225/1144) | 13 | 43 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 43 | 31 (0) | 9/9 |
| 13 | 49×49 @ 1.5 | 49×49 @ 1.5 | 2401 (400/2001) | 21 | 67 | 0 | 0 | 0 | 97 (0) | 0 | 0 | 10 (0) | 67 | 52 (0) | 14/14 |
| 14 | 50×20 @ 1.5 | 50×20 @ 1.5 | 1000 (400/600) | 0 | 11 | 0 | 0 | 0 | 96 (1) | 0 | 0 | 10 (0) | 11 | 52 (0) | 2/2 |
| 15 | 20×50 @ 1.5 | 20×50 @ 1.5 | 1000 (400/600) | 0 | 10 | 0 | 0 | 0 | 88 (0) | 0 | 0 | 10 (0) | 10 | 52 (0) | 2/2 |
| 16 | 49×30 @ 1.5 | 49×30 @ 1.5 | 1470 (400/1070) | 17 | 43 | 0 | 0 | 0 | 112 (1) | 0 | 0 | 10 (0) | 43 | 51 (0) | 10/10 |
| 17 | 37×20 @ 2.0 | 37×20 @ 2.0 | 740 (210/530) | 5 | 15 | 0 | 0 | 0 | 65 (1) | 0 | 0 | 10 (0) | 15 | 31 (0) | 3/3 |
| 18 | 35×37 @ 2.0 | 35×37 @ 2.0 | 1295 (225/1070) | 13 | 43 | 0 | 0 | 0 | 74 (0) | 0 | 0 | 10 (0) | 43 | 31 (0) | 9/9 |

### terreno-servidor-arena-adaptada.json

prova: `provas/ordem-mapa-jogavel/provas-bancada/ferramentas/provar_terreno_servidor_mapa.gd (cópia adaptada de cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd)`

| # | pedida | servida | casas (dentro/fora zona livre) | água | bloq. srv | juízo ≠ | motivo ≠ | cob. afirmada ≠ | cob. não afirmada (cli ≠ ref) | desvio alt. máx (m) | desvio pé máx (m) | figuras (desvio m) | recusas | mover (bloq. no cli) | marcos ok |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 30×30 @ 1.5 | 30×30 @ 1.5 | 900 (400/500) | 17 | 26 | 0 | 0 | 0 | 99 (1) | 0 | 0 | 15 (0) | 3 | 41 (0) | 6/6 |
| 2 | 30×30 @ 2.0 | 30×30 @ 2.0 | 900 (196/704) | 12 | 30 | 0 | 0 | 0 | 107 (0) | 0 | 0 | 10 (0) | 0 | 30 (0) | 4/4 |
| 3 | 20×20 @ 1.5 | 20×20 @ 1.5 | 400 (400/0) | 0 | 0 | 0 | 0 | 0 | 76 (1) | 0 | 0 | 10 (0) | 0 | 47 (0) | 0/0 |
| 4 | 25×25 @ 1.5 | 25×25 @ 1.5 | 625 (400/225) | 2 | 8 | 0 | 0 | 0 | 91 (2) | 0 | 0 | 10 (0) | 8 | 52 (0) | 0/0 |
| 5 | 25×25 @ 1.0 | 25×25 @ 1.0 | 625 (625/0) | 0 | 0 | 0 | 0 | 0 | 184 (2) | 0 | 0 | 10 (0) | 0 | 91 (0) | 0/0 |
| 6 | 25×25 @ 2.0 | 25×25 @ 2.0 | 625 (225/400) | 13 | 28 | 0 | 0 | 0 | 42 (3) | 0 | 0 | 10 (0) | 28 | 21 (0) | 5/5 |
| 7 | 21×17 @ 1.0 | 21×17 @ 1.0 | 357 (357/0) | 0 | 0 | 0 | 0 | 0 | 87 (0) | 0 | 0 | 10 (0) | 0 | 90 (0) | 0/0 |
| 8 | 33×27 @ 2.0 | 33×27 @ 2.0 | 891 (225/666) | 13 | 35 | 0 | 0 | 0 | 112 (4) | 0 | 0 | 10 (0) | 35 | 30 (0) | 7/7 |
| 9 | 44×20 @ 1.5 | 44×20 @ 1.5 | 880 (400/480) | 0 | 11 | 0 | 0 | 0 | 120 (3) | 0 | 0 | 10 (0) | 11 | 52 (0) | 2/2 |
| 10 | 50×50 @ 1.5 | 50×50 @ 1.5 | 2500 (400/2100) | 21 | 67 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 67 | 52 (0) | 14/14 |
| 11 | 50×50 @ 1.0 | 75×75 @ 1.0 | 5625 (841/4784) | 50 | 156 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 156 | 110 (0) | 14/14 |
| 12 | 37×37 @ 2.0 | 37×37 @ 2.0 | 1369 (225/1144) | 13 | 43 | 0 | 0 | 0 | 0 (0) | 0 | 0 | 10 (0) | 43 | 31 (0) | 9/9 |
| 13 | 49×49 @ 1.5 | 49×49 @ 1.5 | 2401 (400/2001) | 21 | 67 | 0 | 0 | 0 | 97 (0) | 0 | 0 | 10 (0) | 67 | 52 (0) | 14/14 |
| 14 | 50×20 @ 1.5 | 50×20 @ 1.5 | 1000 (400/600) | 0 | 11 | 0 | 0 | 0 | 96 (1) | 0 | 0 | 10 (0) | 11 | 52 (0) | 2/2 |
| 15 | 20×50 @ 1.5 | 20×50 @ 1.5 | 1000 (400/600) | 0 | 10 | 0 | 0 | 0 | 88 (0) | 0 | 0 | 10 (0) | 10 | 52 (0) | 2/2 |
| 16 | 49×30 @ 1.5 | 49×30 @ 1.5 | 1470 (400/1070) | 17 | 43 | 0 | 0 | 0 | 112 (1) | 0 | 0 | 10 (0) | 43 | 51 (0) | 10/10 |
| 17 | 37×20 @ 2.0 | 37×20 @ 2.0 | 740 (210/530) | 5 | 15 | 0 | 0 | 0 | 65 (1) | 0 | 0 | 10 (0) | 15 | 31 (0) | 3/3 |
| 18 | 35×37 @ 2.0 | 35×37 @ 2.0 | 1295 (225/1070) | 13 | 43 | 0 | 0 | 0 | 74 (0) | 0 | 0 | 10 (0) | 43 | 31 (0) | 9/9 |
