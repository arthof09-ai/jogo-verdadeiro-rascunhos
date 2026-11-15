# Ordem 45: a arena do Mestre. Provas

*Ramo `fable/mestre-45`. Medido nesta máquina (PCDANASA, RTX 4060, Godot 4.7.2, Compatibility). Estas provas
não aprovam nada: o veredicto é do olho do Mestre.*

## O que está aqui

| ficheiro | o quê |
|---|---|
| `medicao-mestre-no-relevo.json` | a medição da Parte 1 e o clima da Parte 2, casa a casa, das grelhas 20 × 20 e 30 × 30 de 1,5 m (`cenas/mestre/ferramentas/provar_mestre_no_relevo.gd`) |
| `capturas/M01–M05` | a vista normal do ecrã do Mestre |
| `capturas/N01–N06` | a neve (o Mestre escolhe «Neve» → nevasca no ecrã dele) |
| `capturas/A01–A06` | o alagamento (o Mestre escolhe «Tempestade» → chuva forte, as bacias do relevo enchem) |
| `mestre45_*_medicao.json` | o estado do clima em cada captura (neve, aglomerado, gelo; molhado, água, lama; o alagamento medido na zona) |

As 17 capturas têm 1920 × 1080 e uma etiqueta em baixo (o que é, o tempo, o clima de jogo e o que o ecrã
desenha). São do **ecrã do Mestre de verdade** (`cenas/mestre/mestre.tscn`: a arena 3D no SubViewport e a folha
à direita; nas de perto a folha está encolhida). As figuras são as quatro da fixture do servidor (cenário
«mestre»), postas em casas que mostram o relevo: DEMONSTRAÇÃO. O clima liga-se pelo caminho do jogo: o clima
escolhido na aba Ambiente chega na vista (`mestre.ambiente.clima`) e a arena do Mestre segue-o.

Como se refazem (com janela; o tempo anda a passo fixo):

    godot --path cliente --resolution 1920x1080 --fixed-fps 30 \
      -s res://cenas/mestre/ferramentas/capturar_mestre_45.gd -- --modo=normal|neve|alaga --saida=<pasta>
    godot --headless --path cliente -s res://cenas/mestre/ferramentas/provar_mestre_no_relevo.gd -- --json=<ficheiro>

## As capturas

**Vista normal**

- `M01` Panorama do ecrã do Mestre: a grelha 20 × 20 inteira sobre o relevo do mapa (a lomba do outeiro a NO,
  o charco a NE), as quatro figuras com o anel e o nome.
- `M02` a câmara Fixa da mesa, com a folha do Mestre.
- `M03` de perto, a heroína na casa (1, 1), na encosta de 35° do outeiro: o anel e a sombra de contacto
  deitados no plano da encosta, o corpo a prumo, o fundo assente no plano (sem fresta, sem se enterrar).
- `M04` 360° rasante.
- `M05` a câmara livre do Mestre (pelo botão do ecrã), com os olhos a 1,6 m do relevo.

**Neve** (`N01` antes; `N02` 9 s; `N03` 22 s; `N04` 38 s; `N05` e `N06` de perto)

| captura | neve | aglomerado | gelo | abrigos do mapa |
|---|---|---|---|---|
| N01 antes | 0 | 0 | 0 | — |
| N02 início | 0,17 | 0,18 | 0,11 | 8 |
| N03 meio | 0,46 | 0,45 | 0,29 | 8 |
| N04 aglomerado | 0,81 | 0,84 | 0,52 | 8 |
| N05 perto dos menires (NO) | 0,86 | 0,88 | 0,55 | 8 |
| N06 perto do tronco tombado (SO) | 0,90 | 0,96 | 0,58 | 8 |

Os 8 abrigos são os da arena do jogador (os mesmos obstáculos reais: a prova confere-o, `abrigos ... Mestre 8 =
jogador 8`). Em `N05` os menires entre a câmara e o foco aparecem em ponteado: é o recorte da vista da Ordem 42
(o que fica entre a câmara da mesa e o foco não tapa o jogo), igual ao do jogador.

**Alagamento** (`A01` seco; `A02` 16 s; `A03` 30 s; `A04` 44 s; `A05` e `A06` de perto)

| captura | água | água na zona | fundo máximo | bacias do relevo |
|---|---|---|---|---|
| A01 seco | 0 | 0,1 m² | 0,002 m | 8 |
| A02 a crescer | 0,23 | 2,5 m² | 0,011 m | 8 |
| A03 meio | 0,62 | 7,6 m² | 0,027 m | 8 |
| A04 bolsas cheias | 1,00 | 13,5 m² | 0,043 m | 8 |

Os números batem com os da Ordem 42 na arena do jogador (13,5 m² com 4,3 cm de fundo, com as bolsas cheias): as
bacias são as mesmas (`BaciasRelevo.achar` da mesma zona; a prova confere-as uma a uma, nível incluído). Em `A05`
a aliada, na casa (8, 7), tem os pés na cova rasa do prado.

## O que vi com os meus olhos

- a grelha segue o relevo e as figuras estão de pé nas casas, também na encosta do outeiro (M01, M03);
- o céu, a névoa e a luz são os do mapa — os mesmos da arena do jogador (a prova compara-os);
- a neve cai, pousa e junta-se contra os menires, as rochas e o tronco tombado (N04–N06);
- a chuva enche as covas reais do prado e a boca da garganta (A04–A06);
- o botão «Entrar na câmera livre» e a folha do Mestre continuam lá.
