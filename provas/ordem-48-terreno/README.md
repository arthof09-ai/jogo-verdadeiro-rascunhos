# Ordem 48: o terreno do servidor para qualquer tamanho de grelha (provas)

Nada visual: são duas medições em JSON, feitas sem janela (Godot 4.7.2, PCDANASA), com as ferramentas do
cliente. O fecho da ordem está em `rascunhos/cliente/mapa/floresta/ESTADO-FINAL-ORDEM-48.md`.

## `medicao-terreno-qualquer-grelha.json`: cliente contra servidor

Feita com `cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd -- --json=…`. Para cada grelha, o servidor
de verdade (`servidor/ferramentas/juizo-terreno.mjs`: núcleo `sala.js` com o pacote `terreno-floresta.json`,
que recorta a grelha do mapa inteiro) contra a arena do jogo aberta com o mesmo snapshot. A altura do centro
e o pé comparam-se pelos bits do double (o servidor manda os 8 bytes de cada um).

| grelha | casas | desvio altura / pé | bloqueadas no servidor | juízo / motivo diferente | cobertura afirmada diferente | recusas (todas com o motivo do cliente) | mover oferecido (bloqueadas no cliente) |
|---|---|---|---|---|---|---|---|
| **25 × 25 de 1,5 m** | 625 | **0 / 0 m** | 10 | 0 / 0 | 0 | 10 | 51 (0) |
| **25 × 25 de 1 m** | 625 | **0 / 0 m** | 0 | 0 / 0 | 0 | 0 | 91 (0) |
| **25 × 25 de 2 m** | 625 | **0 / 0 m** | 41 | 0 / 0 | 0 | 41 | 21 (0) |
| 30 × 30 de 1,5 m | 900 | 0 / 0 m | 43 | 0 / 0 | 0 | 4 | 41 (0) |
| 30 × 30 de 2 m | 900 | 0 / 0 m | 42 | 0 / 0 | 0 | 0 | 30 (0) |
| 20 × 20 de 1,5 m | 400 | 0 / 0 m | 0 | 0 / 0 | 0 | 0 | 47 (0) |
| 21 × 17 de 1 m | 357 | 0 / 0 m | 0 | 0 / 0 | 0 | 0 | 90 (0) |
| 33 × 27 de 2 m | 891 | 0 / 0 m | 48 | 0 / 0 | 0 | 48 | 30 (0) |
| 44 × 20 de 1,5 m | 880 | 0 / 0 m | 11 | 0 / 0 | 0 | 11 | 52 (0) |
| 50 × 50 de 1,5 m | 2 500 | 0 / 0 m | 88 | 0 / 0 | 0 | 88 | 52 (0) |
| 50 × 50 de 1 m | 2 500 | 0 / 0 m | 133 | 0 / 0 | 0 | 133 | 69 (0) |
| 37 × 37 de 2 m | 1 369 | 0 / 0 m | 56 | 0 / 0 | 0 | 56 | 31 (0) |

Nas grelhas «auto» (todas menos as três da Ordem 44) o Mestre tenta colocar uma figura em CADA casa que o
servidor julga bloqueada: todas são recusadas, e o motivo da recusa é o que o cliente desenha. O detalhe casa a
casa (com os bits) está nas três 25 × 25; das outras ficam os resumos, as figuras e os marcos.

## `sonda-42-zonas.json`: porque é que o bloqueio se recorta de um só mapa

Feita com `cliente/cenas/arena/ferramentas/sondar_zonas_terreno.gd -- --json=…`. O mapa da arena muda com a zona
jogável (não planta nada dentro dela). A sonda constrói o mapa de verdade para 42 zonas (de 1 × 1 a 70 × 70, as
três escalas, lados pares e ímpares, grelhas maiores do que o mapa) e compara, em cada casa do jogo, com o mapa
de referência do exportador:

- **43 010 casas: 0 com bloqueio diferente, 0 com motivo diferente, 0 com cobertura afirmada diferente.**
- Na faixa da borda (1,35 m), 79 das 4 799 casas têm no cliente outra cobertura (mais alta) do que no mapa de
  referência: abrigo de árvores e rochas logo fora da zona. É por isso que aí o servidor só afirma a cobertura
  total e diz `null` no resto.
