# Ordem 40 — Clima na arena (chuva e neve) — notas de trabalho

Ramo: `fable/clima-40` (frente paralela independente; não toca na main, no ramo vivo nem na cadeia do mapa).
Nenhuma destas notas aprova nada: o veredicto é do olho do Mestre, sobre os vídeos.

## Nota 1 — base conferida (2026-11-13)

- Hash lido no clone (`git rev-parse HEAD`, antes de qualquer commit): `548d66c589c393350245fbac8a7f428f3f6036b9`.
- PONTA-BASE da ordem: `548d66c589c393350245fbac8a7f428f3f6036b9`.
- **São iguais.** O ramo `fable/clima-40` nasce exactamente dela.
- Godot: `C:\Users\txcga\godot-472\Godot_v4.7.2-stable_win64_console.exe`. GPU: NVIDIA GeForce RTX 4060.

## Nota 2 — o que foi entregue (2026-11-14)

A ordem correu em duas sessões da conta 1: a primeira (13/11, 21:23–21:40) fez o módulo e a bancada e morreu no
limite de 5 h; a segunda (14/11, a partir das 02:10) conferiu, pôs os testes, corrigiu o que os olhos
apanharam, gravou as provas e fechou.

### O sistema (módulo transplantável)

`rascunhos/cliente/arte/clima/` — ver o `README.md` de lá (como ligar a uma cena em 6 linhas).
Um nó `clima.gd` que a arena liga; o chão e as figuras entram por grupo (`clima_chao`, `clima_figura`) e
recebem um `material_overlay` — **nenhum material da cena é trocado**, por isso serve qualquer chão e
qualquer figura. Está ligado às duas arenas de hoje (`cenas/arena/arena.gd` e `cenas/mestre/arena_mestre.gd`).

- **Chuva com vento**: cada gota é um risco esticado ao longo da velocidade do frame (queda + vento desse
  frame) — inclina-se com o vento e roda quando ele roda. O chão lê-se molhado: escurece, reflecte o céu
  (mais nas poças e de raspão), tem brilho do sol, anéis dos pingos onde a chuva bate e salpicos que
  saltam (Médio e Alto). As figuras ganham brilho de molhado (contorno e lustro), sem perder a cor.
- **Neve com vento**: flocos virados para a câmara. O chão branqueia aos poucos (pó → manchas que crescem →
  manto), com a neve rala ao longo das linhas da grelha para a grelha continuar a ler-se; as figuras
  ganham neve em cima (o topo primeiro, depois tudo o que olha para cima). Só visual: não muda altura
  nenhuma do jogo.
- **Um só vento** (rumo e força) para os dois climas, com rajadas.
- **Intensidades**: fraco e forte para cada clima, comutáveis **sem reiniciar a cena** (as partículas entram
  e saem em ~1,5 s; ver o vídeo `comutacao.mp4`). Coube na arquitectura sem custo extra.
- **Só apresentação** (guarda 6): o módulo não lê `Estado` nem `Rede` (há um teste que o confere), não manda
  comando nenhum e não mexe em casas, destaques nem figuras (teste na arena do Mestre).

### Como o deslocamento frame a frame foi implementado (a lição da REF_85)

Ficheiro `arte/clima/integrador_vento.gd` (CPU) e `clima_comum.gdshaderinc` (a mesma conta, no vértice).

- Em cada frame soma-se **só o que esse frame andou**: `posição += (vento do frame + queda) × dt`.
  Em lado nenhum aparece «vento × tempo total».
- Para não custar uma posição por floco na CPU, o que se integra são **7 acumuladores**: 1 da queda, 3 do
  vento (cada um com a sua rajada, ganho sempre > 0) e 3 do balanço lateral (perpendicular ao vento do
  frame). Cada floco lê-os com pesos constantes sorteados uma vez (inteiros pequenos no `INSTANCE_CUSTOM`
  da MultiMesh): `xz = base + Σ d_vento[c]·w_c/16 + Σ d_lado[c]·l_c/8`, `y = base − d_queda·k/16`.
- Como os pesos são constantes, o que cada floco anda num frame é exactamente
  `dt × (vento × ganho + perpendicular × balanço + queda)`, com ganho ≥ 0: nenhum floco pode andar contra o
  vento do frame, e mudar o vento só muda o que se soma daí para a frente (nada salta).
- O `dt` está preso a 0,1 s (um engasgo do aparelho não vira salto) e os acumuladores dão a volta em
  16 × caixa (os pesos são múltiplos de 1/16 e 1/8, por isso a volta não mexe em floco nenhum).

**Medido com a conta do jogo** (`Integrador.medir()`, floco a floco, frame a frame):

| Medição | Flocos × frames | Vento | Contra o vento | Sobem | Salto máximo |
| --- | --- | --- | --- | --- | --- |
| Bancada (`medicao.json`, `ref_85`) | 3000 × 600 (10 s a 60 fps) | roda +75° e ganha ×1,7 aos 5 s, com rajadas | **0 de 1 793 075 (0,0%)** | 0 | **0,117 m** |
| Teste do CI (`rodar_testes.gd`) | 3000 × 60 | roda 150° e ganha ×1,7 a meio, com rajadas | **0 de 179 321 (0,0%)** | 0 | 0,113 m |
| Teste do CI, 10 s | 300 × 600 | o mesmo | 0 de 179 316 | 0 | — |
| Controlo: a fórmula errada («vento × tempo total») | 1 ponto × 600 | o mesmo | **187 de 599 frames (31,2%)** | — | — |

(A REF_85 mediu 47,7% contra o vento com a fórmula errada e 0,0% / 0,12 m com a certa, com 3000 flocos.
As «voltas da caixa» — o floco que sai por um lado e reaparece no outro — contam-se à parte: 6 925.)

### Contagem de partículas por intensidade e por perfil

| | Baixo | Médio | Alto |
| --- | --- | --- | --- |
| Chuva fraca (gotas + salpicos) | 900 + 0 | 1600 + 120 | 2400 + 200 |
| Chuva forte (gotas + salpicos) | 2800 + 0 | 5000 + 350 | 8000 + 600 |
| Neve fraca (flocos) | 1000 | 2000 | 3000 |
| Neve forte (flocos) | 3000 | 6000 | 9000 |

Outras diferenças entre intensidades: queda da chuva 11 → 15 m/s; força do bater (anéis e salpicos) 0,30 →
0,95; pingos no chão 30% → 100%; queda da neve 1,2 → 1,8 m/s; o chão molha de todo em 24 s (fraca) / 9 s
(forte) e fica todo branco em 90 s (fraca) / 45 s (forte); seca em 40 s e derrete em 60 s depois de parar.
No Baixo: sem salpicos, uma só camada de pingos e ruído mais simples no chão.
As contagens seguem o perfil gráfico (`perfil_aplicado` do `aplicar_perfil.gd` → `clima.definir_perfil`), sem reiniciar.

### Custo medido (PC, RTX 4060, Compatibility/OpenGL 3.3)

`medicao.md` / `medicao.json`. Arena do Mestre com as 4 figuras da fixture, câmara Fixa, render 1920×1080
(janela 1028×749 no ecrã deste PC), sem vsync, 2 s seguidos por caso, já em regime; o chão a 80% molhado
(chuva) ou 60% nevado (neve).

| Perfil | Clima | Partículas | FPS (média) | ms/frame | Draw calls | Primitivas |
| --- | --- | --- | --- | --- | --- | --- |
| baixo | sem clima | 0 | 2285 | 0.44 | 42 | 3538 |
| baixo | chuva fraco | 900 | 2016 | 0.50 | 51 | 6322 |
| baixo | chuva forte | 2800 | 2044 | 0.49 | 51 | 10122 |
| baixo | neve fraco | 1000 | 2023 | 0.49 | 51 | 6522 |
| baixo | neve forte | 3000 | 2039 | 0.49 | 51 | 10522 |
| medio | sem clima | 0 | 2113 | 0.47 | 42 | 3538 |
| medio | chuva fraco | 1720 | 1912 | 0.52 | 52 | 7962 |
| medio | chuva forte | 5350 | 1920 | 0.52 | 52 | 15222 |
| medio | neve fraco | 2000 | 1913 | 0.52 | 51 | 8522 |
| medio | neve forte | 6000 | 1888 | 0.53 | 51 | 16522 |
| alto | sem clima | 0 | 2262 | 0.44 | 42 | 3538 |
| alto | chuva fraco | 2600 | 2015 | 0.50 | 52 | 9722 |
| alto | chuva forte | 8600 | 2033 | 0.49 | 52 | 21722 |
| alto | neve fraco | 3000 | 2036 | 0.49 | 51 | 10522 |
| alto | neve forte | 9000 | 1920 | 0.52 | 51 | 22522 |

Leitura: o clima acrescenta **9 a 10 draw calls** (1 por nuvem — gotas, salpicos, flocos — mais 1 da camada
do chão e 1 por malha de figura vestida: 7 nesta cena) e cerca de **0,05 ms por frame** neste PC.
**Aviso honesto:** a 2000 FPS este PC não diz nada sobre o telemóvel — o que importa lá é o enchimento de
píxeis das camadas transparentes (o chão inteiro tem uma camada com ruído e pingos) e isso só se mede no
aparelho. Não foi medido no Redmi nem no export web.

### Provas (nesta pasta)

- `videos/` — **a prova principal** (MP4 H.264, 1280×720, 30 fps certos, gravados quadro a quadro pelo
  Movie Maker do Godot com render de verdade, perfil Alto; cada um tem a etiqueta no ecrã com o clima, a
  intensidade, a contagem, o vento do frame e a seta laranja a apontar para onde o vento sopra):
  - `chuva-fraca.mp4`, `chuva-forte.mp4` (vento 4,0 m/s), `neve-fraca.mp4`, `neve-forte.mp4` (vento 2,2 m/s).
    Guião de cada um (24 s): 1 s **sem clima** (o «antes») → o clima liga sem reiniciar a cena (câmara Fixa) →
    aos ~8 s **o vento muda** (rumo +75°, força ×1,7) → câmara Fixa de perto nas figuras → câmara Panorama
    (o campo inteiro).
  - `comutacao.mp4` (25 s): chuva fraca → chuva forte → neve fraca → neve forte → desligado, na mesma cena,
    sem reiniciar (o molhado seca por baixo da neve; desligado, a neve pousada fica a derreter).
- `capturas/` — a acumulação da neve em 3 tempos + antes + Panorama (`neve-acumulacao-0…4`) e o chão molhado
  antes / a molhar / molhado / de perto / 360° rasante / depois de a chuva parar (`chuva-chao-0…5`).
- `folhas/` — 6 quadros de cada vídeo numa folha (para ver o guião de relance).
- `rastos/` — o movimento posto numa imagem: três quadros seguidos do vídeo, o 1.º a VERMELHO, o 2.º a VERDE,
  o 3.º a AZUL (o que está parado fica cinzento). Cada floco deixa três pontos R → G → B no sentido em que
  anda. Quadros 200 (vento inicial), 330 (depois de o vento mudar), 500 (de perto), 700 (Panorama).
- `medicao.md`, `medicao.json` — o custo e a medição da REF_85.
- `ferramentas/` — os dois scripts que gravaram os vídeos e fizeram os rastos (caminhos deste PC).

**O que vi com os olhos** (nos quadros dos vídeos finais, nas folhas e nos rastos — o veredicto é do Mestre):
- Neve: em todos os rastos que abri (fraca 330; forte 200, 330, 500, 700) todos os trios R → G → B andam
  para o mesmo lado — para onde a seta aponta, mais a queda. Não vi nenhum floco a andar contra o vento,
  nem antes nem depois de o vento mudar, e nenhum salto na mudança.
- Chuva: os riscos são paralelos entre si e mudam de inclinação quando o vento muda (rasto 200 contra 330,
  na mesma zona do ecrã). A câmara da mesa olha de cima, por isso a perspectiva abre os riscos em leque:
  a inclinação lê-se melhor em movimento e na primeira metade do vídeo (vento de través).
- Chão: molha de forma legível (poças com reflexo, anéis dos pingos) e branqueia de forma legível (neve
  forte: 51% aos 24 s; a 100% nas capturas). A grelha e as casas destacadas continuam a ler-se nos dois.
- Figuras: continuam a ler-se; molhadas ganham um brilho discreto; com neve ficam de cabeça e ombros brancos.
- Fraca contra forte: lê-se a diferença (densidade, poças, velocidade a que o chão muda).

### Testes e CI

- `testes/rodar_testes.gd`: +29 verificações do clima (167 no total) — integração frame a frame, controlo da
  fórmula errada, pesos, módulo (liga, troca, intensidade, perfil, vento único, desliga e dorme, só apresentação).
- `testes/pecas_mestre.gd`: +11 verificações (234 no total) — o clima na arena do Mestre de verdade, pelos grupos.
- `retoma-i0004/actualizar-listas.py` corrido depois de cada commit que mexeu em `rascunhos/` (o job
  `retoma-pc` confere as listas).

### Correcções feitas na segunda sessão (apanhadas a olhar)

1. A camada do molhado das figuras «lutava» pela profundidade com a figura (salpicos de z-fighting nas
   cabeças): o vértice da camada era calculado por outro caminho (`world_vertex_coords`). Agora é igual,
   bit a bit, ao da figura quando não há neve.
2. O molhado tirava a cor às figuras (ficavam cinzentas): baixou-se o reflexo; a cor da figura manda.
3. A bancada dos vídeos começava já com clima no «antes» (o módulo também lê o `--clima=` da linha de
   comando): agora começa sempre seca. **Os dois vídeos que o coordenador gravou às 22:21 de 13/11
   (`fable-clima\prova\`) são de antes destas três correcções** — valem os desta pasta.
4. A medição contava quadros em vez de tempo (media o clima anterior ainda a sair): agora espera pelo relógio.
5. Os grupos só se procuram dentro da árvore; os alvos registados à mão valem sempre (para os testes sem janela).
6. Neve fraca: o chão cobre em 90 s (era 150 s) — em 24 s de vídeo já se lê o véu.

## Nota 3 — a arena da jogadora com render (2026-11-14, fecho)

A segunda sessão morreu às 02:32 (limite de 5 h) dois minutos depois da nota 2, com um modo novo da bancada
escrito e corrido mas por commitar: `--modo=jogadora` do `testes/video_clima.gd`. A sessão do fecho conferiu-o
(abre os 37 scripts, 167 de 167 testes, a corrida gravada deu 0 falhas), commitou-o e juntou a prova:

- `videos/arena-jogadora.mp4` (32 s, 1280×720, perfil Alto): a cena que a jogadora vê (`cenas/arena/arena.tscn`,
  com o HUD e as casas do «Mover» destacadas, sobre um snapshot público de bancada — não é o jogo). 1,5 s sem
  clima → preferência `"clima"` = `chuva-forte` (9 s) → `neve-forte` (14 s) → de perto (5 s) → `nenhum`.
  O clima liga-se como a arena o liga (`arena._ao_preferencia`), sem reiniciar a cena.
- `capturas/jogadora-0…3` e `folhas/folha-arena-jogadora.png`.

**O que vi** (nas 4 capturas e na folha de 6 quadros): o chão molha e branqueia como na arena do Mestre; as
casas azuis do «Mover» e a casa amarela da vez continuam a ler-se com chuva forte a 100% de molhado e com neve
a ~40%; as cápsulas ganham o topo branco com a neve e mantêm a cor; o HUD fica por cima de tudo. Não vi
z-fighting nas cápsulas com contorno (perfil Alto). **Defeito da bancada, não do clima:** a etiqueta do vídeo
fica por cima do botão «FICHA» (canto superior esquerdo). Este vídeo é o 6.º — os 5 vídeos pedidos pela ordem
continuam a ser os da nota 2. Fecha o ponto 3 da lista abaixo (fica lá, riscado, para a história).

## O que ficou por fazer / por conferir

1. **Não há interruptor na interface.** O clima liga-se pela API, pela preferência `"clima"` (a arena da
   jogadora já a escuta, mas nenhum controlo do HUD a emite) e pela linha de comando (`-- --clima=neve-forte`).
   Pôr o interruptor no ⚙ (como os perfis) ou no ecrã do Mestre é decisão do coordenador — não mexi no HUD.
   Se um dia o clima for decidido pelo Mestre para a mesa toda, isso é estado de jogo e tem de vir do servidor.
2. **Não medido no telemóvel nem no export web** (só PC, RTX 4060). Os shaders usam só o que o Compatibility
   tem (sem textura de ecrã, sem profundidade), mas o custo real das camadas transparentes só se vê no aparelho.
3. ~~**A arena da jogadora (`arena.gd`) só foi provada sem janela**~~ — **feito na nota 3**
   (`videos/arena-jogadora.mp4`): vista com render, cápsulas com contorno no perfil Alto. Falta só o olho do
   Mestre sobre esse vídeo.
4. **Figuras GLB**: a camada está feita para qualquer malha, mas só foi vista nos marcadores.
5. **Chão com relevo** (o mapa da cadeia): a camada do chão serve qualquer malha (usa a posição e a normal
   do mundo; em paredes a pique não põe neve nem poças), mas os **salpicos** nascem num plano à altura do
   centro do campo (`chao_y`) — num terreno com alturas vão precisar de ler a altura do chão. As poças são
   ruído no plano XZ: num declive, a «poça» fica inclinada. Passo da integração.
6. **Sombras sob a neve cheia**: a camada tapa 93% do chão, por isso a sombra das figuras fica ténue a 100%
   de neve (ver `capturas/neve-acumulacao-3-depois.png`).
7. **Ordem de desenho** com outros transparentes: as partículas têm `render_priority` 20 e a camada do chão
   −20; com a água e a erva do mapa pode ser preciso afinar.
8. **Câmara livre do Mestre** (primeira pessoa, dentro da coluna de clima): não vista. Os flocos esbatem a
   menos de 2,5 m da câmara para não taparem a mesa.
9. A chuva não é tapada por nada (não há colisão): chove «através» das figuras. Sem som.
