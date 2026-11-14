# arte/clima — o sistema de clima da arena (Ordens 40 e 41)

Chuva e neve a caírem sobre o campo de batalha, com vento, e o chão e as figuras a responderem.
Na Ordem 41 o clima forte passou a ser a sério: a **neve forte é a nevasca** e a **chuva forte é a que
alaga** (ver «O clima forte»). Os climas fracos ficam como eram.
É um **módulo**: um nó (`clima.gd`) que a cena da arena liga. Não está preso a cena nenhuma.

**Só apresentação.** O clima não lê o `ROOM_SNAPSHOT` nem as `ROOM_OPTIONS`, não muda casas, custos,
alvos nem alturas de jogo, e não decide o tempo a partir do estado do jogo. Ligar/desligar, intensidade
e vento são parâmetros de apresentação, como os perfis gráficos. (Os testes `rodar_testes.gd` e
`clima_forte.gd` conferem que o código do módulo não toca no `Estado` nem na `Rede`; o `clima_forte.gd`
corre também a nevasca, o alagamento e a drenagem inteiros com os autoloads vivos e confere que nenhum
sinal deles dispara e que nenhuma variável deles muda.)

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
pedra.add_to_group(Clima.GRUPO_OBSTACULO)               # Ordem 41, "clima_obstaculo": pedras, muros, troncos
clima.definir_bacias([Vector4(x, z, raio_m, fundura_m)])  # Ordem 41, opcional: os pontos baixos do mapa (P1–P4)
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
Fora dos grupos: `clima.registar_chao(no)` / `clima.registar_figura(no)` / `clima.registar_obstaculo(no)`. Para procurar os grupos só
debaixo de um nó (várias arenas na mesma árvore): `clima.raiz_alvos`.

Onde está ligado hoje: `cenas/arena/arena.gd` (jogadora; a preferência `"clima"` do HUD chega a
`clima.definir_por_nome`) e `cenas/mestre/arena_mestre.gd` (Mestre). Pela linha de comando, para a bancada:
`godot --path cliente -- --clima=neve-forte --vento=30,3.5`.

## O clima forte (Ordem 41)

Escolhe-se como antes (`definir("neve", "forte")`, `definir("chuva", "forte")`); `nevasca()` e `alaga()`
dizem se é o caso. Tudo o que se segue é estado **visual**: 0..1, acumulado frame a frame em `avancar(dt)`,
sem mexer em casas, custos, alturas de jogo nem estado. Entre parênteses, os valores de origem dos
`@export` (todos se mudam no inspector ou por código).

### Nevasca (neve forte)

- **O vento ganha rajadas legíveis.** Em `segundos_levantar` (4 s) o vento da nevasca levanta-se
  (`vento_da_nevasca()` 0 → 1); depois a força vai da calma (×`nevasca_calma` = 0,65) ao pico
  (×`nevasca_pico` = 2,9) da força pedida, e o rumo guina até `nevasca_guinada_graus` (26°). A rajada é
  `rajada_da_nevasca(t)`: duas séries (7 s e 11 s) que chegam, enchem e passam; repete-se a cada 77 s. É o
  mesmo vento integrado frame a frame: nada salta. Quando a nevasca acaba, o vento deita-se nos mesmos 4 s.
- **A neve aglomera-se** (`aglomerado`): nos cantos e nas bordas do campo (a borda de onde o vento vem
  junta mais), à volta da base dos obstáculos e numa cauda a sotavento deles; o centro aberto fica varrido.
  Junta-se com o vento de cada frame: com o vento de referência (`vento_referencia`, 4 m/s) fica cheio em
  `segundos_aglomerar` (38 s); com o dobro do vento, em metade; sem vento, a ×0,25.
- **As superfícies gelam** (`gelo`): cheio em `segundos_gelar` (70 s); não depende do vento.
- **O véu**: cartões grandes e ténues que só se vêem ao longe (`veu_perto` / `veu_longe`, em múltiplos da
  distância da câmara ao ponto para onde ela olha; a zona da câmara fica sempre limpa). Só na neve forte, e
  não no perfil Baixo.
- **Derrete devagar, de propósito** (`segundos_derreter` = 60 s): com neve fraca, o aglomerado e o gelo
  descem a ×0,5; com chuva, o aglomerado a ×2 e o gelo a ×3; sem clima, os montes a ×0,8 (duram mais do
  que o manto) e o gelo a ×1.

### Chuva que alaga (chuva forte)

- A água (`agua`) **só se junta com o chão encharcado** (`molhado` ≥ `molhado_para_alagar` = 0,7, ou seja
  6,3 s de chuva forte desde o seco) e enche as bolsas em `segundos_alagar` (36 s). A chuva fraca nunca alaga.
- Junta-se nas **bacias**: as do mapa entram por `definir_bacias()` (até 8); sem isso, o módulo sorteia 5,
  sempre as mesmas para o mesmo campo (as sorteadas não evitam obstáculos nem casas). A margem não é um
  círculo de compasso (`torcer()`), e num chão com relevo a altura da malha entra na conta do shader.
- A **lama** acompanha a água a subir (vai um pouco à frente: `lama` = `agua` × 1,1 + 0,04) e fica onde a
  água chegou.
- **Drenagem em 3 fases**, quando a chuva pára: (1) **escoa**: as bolsas somem-se em `segundos_drenar`
  (24 s; com chuva fraca, a meio ritmo, e enquanto chove a lama não perde o brilho); (2) **lama baça**:
  com a água abaixo de 2 %, a lama perde o brilho (`lama_humida` 1 → 0) em `segundos_lama_baca` (10 s);
  (3) **lama seca**: só então encolhe para o fundo da bacia, em `segundos_lama_secar` (24 s).
  Das bolsas cheias, com a chuva parada: água a 0 aos 24 s, lama baça aos 33,5 s, seco aos 57,5 s.
- **Pés na água**: as figuras dentro de uma bolsa ganham o anel à volta dos pés (acende quando se mexem e
  apaga-se em 1,4 s paradas). Lê só a posição do nó na cena.

O módulo só dorme com tudo a zero: molhado, neve, aglomerado, gelo, água, lama, partículas **e** o vento
da nevasca deitado.

### A API nova

```gdscript
clima.nevasca()                       # true na neve forte
clima.alaga()                         # true na chuva forte
clima.definir_bacias([Vector4(x, z, raio_m, fundura_m), {"x": .., "z": .., "raio": .., "fundura": ..}])
                                      # até 8; sem raio/fundura: 2 m e 8 cm; mínimos 0,1 m e 5 mm; [] = as sorteadas
clima.bacias()                        # Array[Vector4] (x, z, raio, fundura), uma cópia
clima.registar_obstaculo(no)          # um obstáculo fora do grupo "clima_obstaculo"
clima.abrigos()                       # Array[Vector4] (x, z, meia-largura x, meia-largura z): as caixas dos obstáculos (até 8)
clima.definir_forte(aglomerado, gelo, agua, lama = -1)
                                      # o estado forte à mão (0..1), para capturas e testes; lama < 0: acompanha a água
clima.fundura_em(Vector2(x, z), enchimento = -1, margem = 0, y_rel = 0)
                                      # a água (m) por cima do ponto (negativo = seco); espelho de clima_fundura no shader
clima.abrigo_em(Vector2(x, z), rumo = Vector2.ZERO)
                                      # quanto a neve se junta ali: 0 = varrido … 1,6 = canto com obstáculo
clima.neve_em(Vector2(x, z))          # quanta neve há ali (1 = manto cheio, > 1 = monte)
clima.medir_alagamento(passo_m = 0.1) # {area_agua_m2, percent_agua, area_lama_m2, percent_lama, fundura_max_m, raio_medio_m, ...}
Clima.rajada_da_nevasca(t)            # a rajada no instante t: 0 (calma) … 1 (pico)
clima.vento_da_nevasca()              # 0..1: quanto o vento da nevasca está levantado
clima.contagem_alvo("veu")            # os cartões do véu (0 / 140 / 260); contagem_atual("veu") = os desenhados agora
```

Os obstáculos (do grupo ou registados) vestem a mesma camada das figuras (neve em cima e a sotavento, gelo)
e dão as caixas dos abrigos ao chão. Procuram-se de 0,5 em 0,5 s, como os outros alvos: um obstáculo que se
mexe ou sai da cena é seguido. Um obstáculo sem malha não dá abrigo; o grupo respeita `raiz_alvos`.

## Os ficheiros

| Ficheiro | O que é |
| --- | --- |
| `clima.gd` | O nó: API, contagens por perfil, transições, acumulação (molhado / neve pousada; na Ordem 41 também aglomerado, gelo, água e lama), overlays. |
| `integrador_vento.gd` | O deslocamento **integrado frame a frame** (a lição da REF_85) e a medição `medir()`. |
| `clima_comum.gdshaderinc` | A mesma conta da posição, no vértice (espelho de `Integrador.posicao()`). |
| `chuva_gotas.gdshader` | A gota: um risco esticado ao longo da velocidade do frame (queda + vento). |
| `chuva_salpicos.gdshader` | O salpico que salta do chão onde a chuva bate (Médio e Alto); dentro das bolsas, a coroa de água. |
| `neve_flocos.gdshader` | O floco, virado para a câmara; na nevasca, com rasto ao longo da velocidade; é também o véu. |
| `clima_terreno.gdshaderinc` | Ordem 41: as bacias, os abrigos e o campo (`clima_fundura`, `clima_abrigo`), espelhados em `fundura_em` / `abrigo_em`. |
| `clima_chao.gdshader` | A camada do chão: molhado (reflexo, poças, anéis dos pingos) e neve (pó → manchas → manto); na Ordem 41, bolsas de água, lama, montes de neve, gelo, neve rasteira (anda com o vento) e véu. |
| `clima_figura.gdshader` | A camada das figuras (e dos obstáculos): brilho de molhado e neve em cima (topo primeiro); na Ordem 41, neve a sotavento, gelo no contorno e do lado do vento, pés na água. |

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

Tudo MultiMesh com a conta no vértice: **1 draw call por nuvem** (gotas, salpicos, flocos, véu), zero trabalho
por partícula na CPU. As camadas do chão e das figuras são `unshaded` (a luz é a que o módulo manda).
Desligado e seco, o nó não processa, não desenha e não deixa overlay em ninguém.

Partículas por perfil gráfico (`CONTAGEM` em `clima.gd`):

| | Baixo | Médio | Alto |
| --- | --- | --- | --- |
| Chuva fraca (gotas + salpicos) | 900 + 0 | 1600 + 120 | 2400 + 200 |
| Chuva forte (gotas + salpicos) | 2800 + 0 | 5000 + 350 | 8000 + 600 |
| Neve fraca (flocos) | 1000 | 2000 | 3000 |
| Neve forte = nevasca (flocos + véu) | 3000 + 0 | 6000 + 140 | 9000 + 260 |

No Baixo o chão usa uma só camada de pingos e ruído mais simples, e a nevasca não tem véu.

O que o clima forte custa a mais do que «sem clima» (Ordem 41, `provas/ordem-41-clima/medicao41.md`:
RTX 4060, Godot 4.7.2, renderer Compatibility, 1920×1080, sem vsync, câmara Fixa, 2 s por caso já em regime;
DC = draw calls):

| Perfil | Sem clima | Nevasca formada | Chuva alagada |
| --- | --- | --- | --- |
| Baixo | 56 DC · 0,47 ms | 3000 flocos + 0 véu · +12 DC · 0,55 ms (+0,08) | 2800 gotas + 0 salpicos · +12 DC · 0,57 ms (+0,10) |
| Médio | 56 DC · 0,49 ms | 6000 + **140 véu** · +13 DC · 0,59 ms (+0,10) | 5000 + 350 · +13 DC · 0,60 ms (+0,11) |
| Alto | 56 DC · 0,46 ms | 9000 + **260 véu** · +13 DC · 0,57 ms (+0,11) | 8000 + 600 · +13 DC · 0,58 ms (+0,12) |

O clima forte custa os mesmos draw calls que o fraco, com uma exceção: **o véu é +1 draw call** na nevasca
do Médio e do Alto (69, contra os 68 da neve fraca). A chuva alagada tem os mesmos draw calls da chuva
fraca (69; 68 no Baixo): as bolsas, a lama, os montes e o gelo são das camadas do chão e das figuras, que são overlays e não acrescentam
draw calls. O que cresce são as primitivas: no Alto, de 12 010 (neve fraca) a 24 530 (nevasca). A tabela
completa (também a câmara Panorama e os climas fracos) está no `medicao41.md`. Não medido no telemóvel nem
no export web; lá, o que conta é o enchimento de píxeis das camadas transparentes (véu, coroas, rastos).
As medições da Ordem 40 estão em `provas/ordem-40-clima/`.

## Provar

- Sem janela: `testes/rodar_testes.gd` (integração frame a frame, módulo) e `testes/pecas_mestre.gd`
  (o clima na arena do Mestre, pelos grupos), no CI; e `testes/clima_forte.gd` (Ordem 41: nevasca,
  alagamento e drenagem nas 3 fases, a API nova, só apresentação), que o CI por agora só compila (o passo
  que o corre está no ESTADO-FINAL-ORDEM-41-TESTES.md, à espera de quem possa mexer nos workflows). O `rodar_testes.gd` e o `clima_forte.gd` avançam o
  módulo à mão, com `avancar(dt)` e um dt fixo, nunca pelo `_process`: o passo de tempo da máquina não entra
  em conta nenhuma. O `pecas_mestre.gd` corre o clima pelos quadros de verdade, por isso só confere o que não
  depende do passo (o que tem de sobrar põe-se à mão, com `definir_forte`).
- Com render (olhos): `testes/video_clima.gd` — vídeos etiquetados, capturas e medição (na Ordem 41, os
  modos `nevasca`, `alaga`, `fracos`, `fotos41` e `medir41`; as provas estão em `provas/ordem-41-clima/`). Clima é
  movimento: prova-se em vídeo.
