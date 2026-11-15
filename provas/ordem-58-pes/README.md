# Ordem 58: os pés nas casas bloqueadas do mapa (provas)

As provas são da prova nova `rascunhos/cliente/cenas/arena/ferramentas/provar_pes_bloqueadas.gd`: sem janela, com
Godot 4.7.2 e contra o servidor de verdade (`servidor/ferramentas/juizo-terreno.mjs`). Correm as duas arenas: a do
jogador (`arena.tscn`) e a do ecrã do Mestre (`mestre.tscn`).

| ficheiro | o que é |
|---|---|
| `pes-antes.txt` · `pes-antes.json` | A prova correu no commit `dcef8ef`: a prova já existe, a correcção ainda não. Sai com 15 falhas, que são os números de antes. |
| `pes-depois.txt` · `pes-depois.json` | A mesma prova, corrida na ponta do ramo com a correcção: TUDO PASSOU. |
| `medicao-mestre-no-relevo-antes.json` · `-depois.json` | A prova da Ordem 45 (`provar_mestre_no_relevo.gd -- --json=`), antes e depois da correcção. |
| `sonda-escala-bloqueadas.mjs` · `.txt` | Mostra que o servidor pode deixar figuras em casas bloqueadas: ao mudar a escala de 1,5 para 2 m, ficam 7. |

Os JSON `pes-*` guardam, para cada figura, os 8 bytes de x, y e z da posição desenhada (`posicoes_bits`). Comparámos
antes e depois. As figuras nas casas que se pisam têm as mesmas posições, bit a bit, nas duas arenas e nas 6 grelhas.
O detalhe está no ESTADO: `rascunhos/cliente/mapa/floresta/ESTADO-FINAL-ORDEM-58.md`.

Para correr a prova:

    godot --headless --path rascunhos/cliente -s res://cenas/arena/ferramentas/provar_pes_bloqueadas.gd -- --json=saida.json
