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
