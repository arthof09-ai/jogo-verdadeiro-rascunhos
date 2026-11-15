# Ordem 59: a cobertura na faixa da fronteira do mapa (provas)

Nada visual: medições feitas sem janela (Godot 4.7.2, Node 26), com o servidor de verdade. O fecho da ordem está
em `rascunhos/cliente/mapa/floresta/ESTADO-FINAL-ORDEM-59.md`.

## Antes da correcção (servidor da ponta `ac2676b`)

- `antes-medicao-fronteira.json`: `node rascunhos/servidor/ferramentas/medir-fronteira-cobertura.mjs --json=…`.
  21 grelhas (as 12 da Ordem 48 e 9 que tocam a fronteira do mapa em 1, 2 ou 4 lados). Por grelha: as casas da
  faixa da borda, separadas em faixa da FRONTEIRA (todos os lados perto estão na fronteira do mapa) e faixa do
  INTERIOR, quantas o servidor devolve `null` em cada uma, e o SHA-256 do juízo inteiro.
- `antes-provar-terreno.log`: `provar_terreno_servidor.gd` (cliente contra servidor) com as grelhas da fronteira.

**A reserva reproduz-se:** 533 casas `null` na faixa da fronteira (as 9 grelhas que lhe tocam), 2 022 na faixa
do interior, 0 fora da faixa. Nas casas `null` da fronteira, o cliente tem SEMPRE a cobertura do mapa de
referência (0 diferentes): o servidor cala-se onde sabia a resposta.

## Depois da correcção (`nucleo/terreno.js` + `folgaFonteCoberturaM` no pacote)

- `depois-medicao-fronteira.json`: a mesma medição. **0 casas `null` na faixa da fronteira** (eram 533); 2 022 na
  faixa do interior e 0 fora da faixa, como antes. As 12 grelhas que não tocam a fronteira têm o MESMO SHA-256 do
  juízo inteiro que antes; as 9 que tocam mudam só nisso.
- Juízo casa a casa (o JSON inteiro de `juizo-terreno.mjs` antes e depois, nas 21 grelhas): **533 casas mudaram,
  todas na faixa da fronteira, todas de `null` para a cobertura do mapa de referência; 0 outras diferenças**
  (altura, pé, bloqueio, motivo, cobertura fora da faixa da fronteira, figuras, recusas, mover).
- `depois-provar-terreno.json` / `.log`: a prova cliente↔servidor. **Desvio 0** em altura e pé (bits do double),
  0 juízos e 0 motivos diferentes, e nas faixas da fronteira **533 casas com cobertura afirmada, 0 diferentes do
  cliente**. As recusas continuam todas com o nome do cliente. É a referência das presenças desta prova a partir
  da Ordem 59 (o blob da Ordem 48 já não serve: tem o `null` antigo).
- Contra o blob da Ordem 48 (`provas/ordem-48-terreno/medicao-terreno-qualquer-grelha.json`), as 10 grelhas
  antigas que não tocam a fronteira ficam iguais campo a campo (com o detalhe casa a casa das três 25 × 25). Nas duas
  que tocam (50 × 50 de 1,5 m e 37 × 37 de 2 m) só muda `coberturaNaoAfirmada`: 196 → 0 e 73 → 0.
