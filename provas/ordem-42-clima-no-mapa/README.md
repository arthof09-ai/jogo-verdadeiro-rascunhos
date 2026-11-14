# Ordem 42, parte 2: o clima forte sobre o mapa integrado

*Ramo `fable/integracao-42`. Corrido no PCDANASA (RTX 4060, Godot 4.7.2, Compatibility) com
`rascunhos/cliente/cenas/arena/ferramentas/clima_no_mapa.gd`. A cena é a arena DO JOGO (`cenas/arena/arena.tscn`
com o mapa da floresta), com o módulo do clima das Ordens 40/41 (merge do `fable/clima-41-expansao` na ponta
`c167f52`). As figuras e o guião do tempo são de DEMONSTRAÇÃO, postos pela bancada. As bacias e os abrigos
são os do mapa. Estas notas não aprovam nada: o veredicto é do olho do Mestre.*

## O que está aqui

| | |
|---|---|
| `videos/nevasca.mp4` | 44,1 s · 1280 × 720 · 30 q/s · H.264. Panorama do campo da neve a ligar-se até ao aglomerado (0–38 s); depois perto dos menires (canto NO) e perto do tronco tombado (canto SO). |
| `videos/alaga.mp4` | 50,1 s · 1280 × 720 · 30 q/s · H.264. Panorama do chão seco até às bolsas cheias (0–44 s); depois perto das covas do prado e perto da boca da garganta. |
| `capturas/nevasca_tempo-0…3_*.jpg` | Antes (1 s), início (9 s), meio (22 s), aglomerado (38 s). Panorama, 1920 × 1080. |
| `capturas/nevasca_perto-*.jpg` | Os menires (41 s) e o tronco tombado (43 s), câmara 360°. |
| `capturas/alaga_tempo-0…3_*.jpg` | Seco (1 s), a crescer (16 s), meio (30 s), bolsas cheias (44 s). Panorama, 1920 × 1080. |
| `capturas/alaga_perto-*.jpg` | As covas do prado (47 s; a Lia tem os pés na água) e a boca da garganta (49 s). |
| `capturas/clima_*_medicao.json` | O estado do clima em cada captura, as 8 bacias e os 8 abrigos usados e, no alagamento, a área e a fundura da água e da lama **dentro da zona jogável**. |

O vídeo leva a etiqueta (o que é, o vento, o guião das câmaras) e o relógio, gravados na conversão para MP4.
O gravador do Godot (`--write-movie`) só apanhou a imagem 3D, sem a camada 2D (etiqueta e HUD). As
capturas trazem a etiqueta completa, com o estado do clima a cada tempo.

## As bacias vêm do relevo (`cenas/arena/bacias_do_relevo.gd`)

Não há bacias sorteadas nem desenhadas à mão. Usei a **inundação por prioridade** (priority-flood) sobre
`Relevo.altura`, a altura única do mapa:

1. Amostrei o relevo a cada 0,5 m na zona jogável mais 14 m à volta, para a cova do charco caber inteira.
2. A borda da grelha é a saída da água. Enche-se de fora para dentro, sempre pela célula mais baixa ainda
   por visitar.
3. Cada célula fica com o nível a que a água tem de subir para sair dali. Onde esse nível fica acima do
   chão há uma cova.
4. As covas ligadas entre si formam uma bacia, com centro, raio, fundura e nível de transbordo. Ficam as 8
   maiores por volume.
5. A subida da água conta-se do fundo real da cova e fica limitada a 1 m. Sem esse limite, a cova do charco
   (1,37 m até ao transbordo) virava um lago até à borda.

As 8 bacias achadas:

- a cova do charco (NE), com o charco a crescer;
- uma cova a oeste (−22,5; −3,8), com 23 cm;
- a boca da garganta (−17,3; 9,9), com 21 cm;
- cinco covas rasas, de 3 a 5 cm. Duas ficam dentro da zona jogável: (−2,3; −3,0) e (−6,3; −13,7).

No módulo do clima a bacia passou a ter um segundo tipo, a **bacia do relevo** (`bacias_tipo`/`bacias_nivel`
em `clima_terreno.gdshaderinc`, com o espelho em `clima.gd`). A água sobe com a superfície **plana**, do
fundo até ao nível, e é o relevo que dá a forma à bolsa. Só conta o chão da cova: o que fica abaixo do fundo
dela está do outro lado do transbordo e fica seco. A taça da Ordem 41 continua igual.

**Defeito latente corrigido no módulo.** Onde nenhuma bacia contava, a fundura devolvia `−1 − y_rel`. Num
chão com relevo, todo o chão mais de 1 m abaixo da referência saía molhado (2,3 m² de «água» com a chuva
desligada). Agora devolve −1. Num chão liso (`y_rel = 0`) o resultado é o mesmo de antes, e o
`clima_forte.gd` continua a dar 119/119.

**Medido dentro da zona jogável (30 × 30 m):**

| Tempo | Água | Lama | Área com água | Área com lama | Fundura máxima |
|---|---|---|---|---|---|
| seco (1 s) | 0 | 0 | 0,1 m² | 0 | 0,002 m |
| a crescer (16 s) | 0,23 | 0,29 | 2,5 m² | 3,1 m² | 0,011 m |
| meio (30 s) | 0,62 | 0,72 | 7,5 m² | 8,9 m² | 0,027 m |
| cheias (44 s) | 1,00 | 1,00 | 13,5 m² (1,5 % da zona) | 13,2 m² | 0,043 m |

Os 0,1 m² a 2 mm do tempo seco são o arredondamento entre a amostragem do achador e a malha. O prado do
meio foi desenhado quase liso (Ordem 38), por isso as bolsas grandes ficam **fora** da zona: na boca da
garganta, na cova a oeste e no charco. É isso que o relevo real dá.

## A nevasca junta-se contra os obstáculos reais

- **Obstáculos do mapa.** `campo_floresta.gd` regista ao construir-se os obstáculos reais (menires,
  santuário, lanternas, tronco tombado, rochas e árvores) com o pé e a medida de cada um. A arena dá ao
  clima os **8 mais perto da zona**, como caixas invisíveis com essa medida (o módulo lê a caixa da malha e
  aceita até 8). Nesta corrida foram o tronco tombado (−15,6; 23,2), três menires do outeiro (à volta de
  (−17,6; −18,2)), três rochas ((18,2; 9,2), (11,6; 19,0) e (−9,5; 19,5)) e o santuário (21,3; 20,8). A
  lista e as medidas estão no JSON.
- **Neve nos obstáculos.** As malhas reais (pedras, madeira, santuário, troncos) vestem a camada de neve do
  módulo.
- **Sem bordas.** `bordas_abrigo = 0`: a zona jogável não tem muros. Com as bordas ligadas, o módulo enchia
  de neve tudo o que ficava fora do campo e deixava um quadrado verde num mundo branco (visto na primeira
  volta).
- **Grelha na neve.** O fio da grelha só se abre dentro do campo; num mapa, o chão vai muito além da
  grelha.
- **A relva do mapa responde ao clima** (`relva.gdshader` inclui `clima_terreno.gdshaderinc`). Debaixo da
  neve enterra-se e branqueia (o manto e os montes lêem-se em vez de ficarem tapados pela erva). Nas
  bolsas e na lama afoga-se, e a água lê-se no chão.

**Estado medido:** neve 0,17 / 0,46 / 0,81 e aglomerado 0,21 / 0,54 / 1,00 aos 9 / 22 / 38 s; gelo 0,52 aos
38 s.

## O que falta conferir (para o olho do Mestre)

- **Montes quadrados.** Os montes à volta das rochas redondas saem quadrados: o módulo só sabe caixas
  alinhadas aos eixos. Encolhi as caixas (rochas a 0,6 do tamanho, menires a 0,45), o que disfarça mas
  não resolve.
- **Pouca neve no centro.** Com o aglomerado cheio, o campo aberto fica varrido (é o desenho da Ordem 41:
  o centro perde 67 % da neve). No mapa, isso quer dizer pouca neve no centro e montes só junto dos 8
  obstáculos.
- **Neve nas pedras.** As pedras com a camada de neve ficam muito brancas.
- **Ponteado e neve.** Quando o recorte da câmara (o ponteado) passa por um obstáculo vestido, a camada de
  neve desenha-se por cima do ponteado.
- **Nomes dos abrigos.** Quatro abrigos ficaram com nome automático (`@MeshInstance3D@43`…) porque o nome
  repetia («Abrigo_rocha»). As posições e as medidas estão certas no JSON.
- **Não fiz:** o vídeo da drenagem (a chuva a parar), a medição de FPS com o clima ligado no mapa, e o
  perfil Baixo com clima no mapa.
