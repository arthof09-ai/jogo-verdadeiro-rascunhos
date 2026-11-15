# Ordem 60: a recusa do pé tem de se ver no ecrã (provas)

As provas vêm da prova nova `rascunhos/cliente/cenas/mestre/ferramentas/provar_recusa_no_ecra.gd`. Corre sem janela,
com Godot 4.7.2 e contra o servidor de verdade (`servidor/ferramentas/juizo-terreno.mjs`). Usa as duas arenas: a do
jogador (`arena.tscn`, com o HUD) e a do ecrã do Mestre (`mestre.tscn`).

| ficheiro | o que é |
|---|---|
| `recusa-antes.txt` · `recusa-antes.json` | A prova corrida no commit `f07b37d`: a prova já existe, a correcção ainda não. Sai com 14 falhas. São os números de antes. |
| `recusa-depois.txt` · `recusa-depois.json` | A mesma prova na ponta do ramo com a correcção (`5d225b8`), com `--antes=recusa-antes.json`: TUDO PASSOU. |
| `jogadora-lia-na-escarpa.jpg` | Foto com janela, na arena do jogador. A figura da própria jogadora («Lia») está na escarpa (27,24) da 30 × 30 de 1,5 m e o «Corvo» está de pé na (29,24). Vê-se a casa marcada, o rótulo «✕ Lia / não fica de pé: escarpa» e o Aviso do HUD. |
| `mestre-lia-na-escarpa.jpg` | A mesma mesa no ecrã do Mestre. Vê-se a casa marcada, o alerta na coluna 1 e a linha da folha (aba Figuras): «✕ não está de pé: escarpa (o mapa bloqueia a casa)». |
| `fotografar_recusa.gd.txt` | O script das fotos. Fica fora de `rascunhos/` porque precisa de janela. Corre com `godot --path rascunhos/cliente -s fotografar_recusa.gd -- --saida=<pasta>`, depois de lhe tirar o `.txt`. |

Nos `.txt` tirámos os avisos da consola (`push_warning`, com o rasto da pilha) e as linhas `[floresta] pronta`.
Os JSON estão completos.

Os JSON guardam, para cada figura numa casa que se pisa, os 8 bytes de x, y e z da posição desenhada
(`posicoes_bits`) e, no Mestre, a linha da folha. A prova de depois compara-os com os de antes. Nas duas arenas e nas
4 grelhas, as figuras nas casas que se pisam ficam iguais bit a bit, e as linhas da folha delas não mudam.

O detalhe está no ESTADO: `rascunhos/cliente/mapa/floresta/ESTADO-FINAL-ORDEM-60.md`.

Para correr a prova:

    godot --headless --path rascunhos/cliente -s res://cenas/mestre/ferramentas/provar_recusa_no_ecra.gd -- --json=saida.json [--antes=recusa-antes.json]
