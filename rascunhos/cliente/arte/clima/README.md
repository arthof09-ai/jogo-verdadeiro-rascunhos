# arte/clima — o sistema de clima da arena (Ordem 40)

Chuva e neve a caírem sobre o campo de batalha, com vento, e o chão e as figuras a responderem.
É um **módulo**: um nó (`clima.gd`) que a cena da arena liga. Não está preso a cena nenhuma.

**Só apresentação.** O clima não lê o `ROOM_SNAPSHOT` nem as `ROOM_OPTIONS`, não muda casas, custos,
alvos nem alturas de jogo, e não decide o tempo a partir do estado do jogo. Ligar/desligar, intensidade
e vento são parâmetros de apresentação, como os perfis gráficos. (O teste `rodar_testes.gd` confere que
o código do módulo não toca no `Estado` nem na `Rede`.)

## Ligar a uma cena (transplante)

```gdscript
const Clima := preload("res://arte/clima/clima.gd")

var clima := Clima.new()
add_child(clima)                                        # filho da cena da arena
clima.configurar_area(centro_no_chao, Vector2(largura_m, fundo_m))   # o campo a cobrir
clima.definir_grelha(origem_da_grelha, casa_m)          # opcional: a neve fica rala nas linhas da grelha
perfis.perfil_aplicado.connect(clima.definir_perfil)    # as contagens seguem o perfil gráfico (Baixo/Médio/Alto)

chao.add_to_group(Clima.GRUPO_CHAO)                     # "clima_chao": o que molha e branqueia
corpo_da_figura.add_to_group(Clima.GRUPO_FIGURA)        # "clima_figura": o nó e os MeshInstance3D debaixo dele
```

Depois, em qualquer altura e **sem reiniciar a cena**:

```gdscript
clima.definir("chuva", "forte")      # "nenhum" | "chuva" | "neve"   ×   "fraco" | "forte"
clima.definir_por_nome("neve-fraca") # o mesmo, por nome ("nenhum", "chuva-fraca", "chuva-forte", "neve-fraca", "neve-forte")
clima.definir_vento(20.0, 2.5)       # rumo em graus (0 = +X, 90 = +Z) e força em m/s — UM vento para os dois climas
clima.desligar()                     # as partículas saem; o molhado seca e a neve derrete aos poucos
clima.definir_acumulacao(0.0, 0.6)   # opcional: abrir a cena já molhada / já nevada (0..1)
```

O que o módulo faz aos alvos: põe-lhes um `material_overlay` (a camada do clima) e tira-o quando o clima
acaba e tudo secou. **Não troca material nenhum** — por isso serve qualquer chão (cor lisa, textura, o
terreno do mapa) e qualquer figura (marcador, cápsula, GLB). Um nó que já tenha um `material_overlay`
seu fica como está. Nas figuras, as malhas sem luz (anel, sombra de contacto) ficam de fora.
Fora dos grupos: `clima.registar_chao(no)` / `clima.registar_figura(no)`. Para procurar os grupos só
debaixo de um nó (várias arenas na mesma árvore): `clima.raiz_alvos`.

Onde está ligado hoje: `cenas/arena/arena.gd` (jogadora; a preferência `"clima"` do HUD chega a
`clima.definir_por_nome`) e `cenas/mestre/arena_mestre.gd` (Mestre). Pela linha de comando, para a bancada:
`godot --path cliente -- --clima=neve-forte --vento=30,3.5`.

## Os ficheiros

| Ficheiro | O que é |
| --- | --- |
| `clima.gd` | O nó: API, contagens por perfil, transições, acumulação (molhado / neve pousada), overlays. |
| `integrador_vento.gd` | O deslocamento **integrado frame a frame** (a lição da REF_85) e a medição `medir()`. |
| `clima_comum.gdshaderinc` | A mesma conta da posição, no vértice (espelho de `Integrador.posicao()`). |
| `chuva_gotas.gdshader` | A gota: um risco esticado ao longo da velocidade do frame (queda + vento). |
| `chuva_salpicos.gdshader` | O salpico que salta do chão onde a chuva bate (Médio e Alto). |
| `neve_flocos.gdshader` | O floco, virado para a câmara. |
| `clima_chao.gdshader` | A camada do chão: molhado (reflexo, poças, anéis dos pingos) e neve (pó → manchas → manto). |
| `clima_figura.gdshader` | A camada das figuras: brilho de molhado e neve em cima (topo primeiro). |

## O vento, frame a frame (nunca «vento × tempo total»)

A REF_85 mediu no protótipo web: com «vento actual × tempo total», 47,7% dos flocos andavam contra o vento
(basta o vento mudar para a nuvem inteira saltar). Aqui, em cada frame, soma-se só o que esse frame andou:

    posição += (vento do frame + queda) × dt

Não se guarda uma posição por floco na CPU. Guardam-se **7 acumuladores** (1 da queda, 3 do vento com
rajadas, 3 do balanço lateral), somados frame a frame com o vento desse frame; cada floco lê-os com pesos
constantes, sorteados uma vez (inteiros pequenos no `INSTANCE_CUSTOM` da MultiMesh). Como os pesos do
vento são ≥ 0 e o balanço é perpendicular ao vento do frame, nenhum floco anda contra o vento — por
construção, e medido (`Integrador.medir()`, que os testes do cliente correm). Mudar o vento só muda o que
se soma daqui para a frente: nada salta. Os acumuladores dão a volta em 16 × caixa, por isso a precisão
não se gasta com as horas.

## Custo

Tudo MultiMesh com a conta no vértice: **1 draw call por nuvem** (gotas, salpicos, flocos), zero trabalho
por partícula na CPU. As camadas do chão e das figuras são `unshaded` (a luz é a que o módulo manda).
Desligado e seco, o nó não processa, não desenha e não deixa overlay em ninguém.

Partículas por perfil gráfico (`CONTAGEM` em `clima.gd`):

| | Baixo | Médio | Alto |
| --- | --- | --- | --- |
| Chuva fraca (gotas + salpicos) | 900 + 0 | 1600 + 120 | 2400 + 200 |
| Chuva forte (gotas + salpicos) | 2800 + 0 | 5000 + 350 | 8000 + 600 |
| Neve fraca (flocos) | 1000 | 2000 | 3000 |
| Neve forte (flocos) | 3000 | 6000 | 9000 |

No Baixo o chão usa uma só camada de pingos e ruído mais simples. As medições (FPS, draw calls) e as
provas em vídeo estão em `provas/ordem-40-clima/`.

## Provar

- Sem janela (CI): `testes/rodar_testes.gd` (integração frame a frame, módulo) e `testes/pecas_mestre.gd`
  (o clima na arena do Mestre, pelos grupos).
- Com render (olhos): `testes/video_clima.gd` — vídeos etiquetados, capturas e medição. Clima é movimento:
  prova-se em vídeo.
