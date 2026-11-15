# Ordem 44: o terreno no servidor e o pé das figuras nas encostas (provas)

As capturas são da arena do jogo (`cenas/arena/arena.tscn`) com render (RTX 4060, Compatibility,
1920 × 1080). Foram feitas com `cliente/cenas/arena/ferramentas/capturar_terreno_44.gd`. Cada imagem tem
a etiqueta no canto superior esquerdo, e o nome do ficheiro diz o que mostra.

## Parte B: as 6 casas da encosta do outeiro (canto NO da grelha 20 × 20)

- **B01–B06, DEPOIS:** a base inclinada com a encosta (regra da Ordem 44). Grande plano de cada casa, de
  lado, ao longo da curva de nível, um pouco de cima, com só essa figura à vista.
- **B09–B14, ANTES:** a mesma vista com a regra da Ordem 42 (base horizontal à altura mais baixa da pegada,
  sem mancha de base). O «antes» foi redesenhado por cima da arena actual com a regra antiga, só para a
  imagem.
- **B07/B15 e B08/B16:** o grupo das 6 casas, de lado e de baixo, depois e antes.

O nome de cada grande plano leva a encosta, o enterramento e a flutuação medidos. A régua tem 129 pontos
(o centro e 4 anéis de 32 pontos até ao raio de 0,42 m) e é independente dos 33 pontos do ajuste.

| casa | encosta | antes: enterra / flutua | depois: enterra / flutua |
|---|---|---|---|
| (0, 0) | 35,7° | 0,603 / 0,000 m | 0,004 / 0,004 m |
| (1, 0) | 33,2° | 0,549 / 0,000 m | 0,008 / 0,008 m |
| (2, 0) | 26,1° | 0,411 / 0,000 m | 0,013 / 0,013 m |
| (0, 1) | 34,9° | 0,585 / 0,000 m | 0,006 / 0,006 m |
| (1, 1) | 26,1° | 0,411 / 0,000 m | 0,017 / 0,017 m |
| (0, 2) | 25,4° | 0,399 / 0,000 m | 0,020 / 0,019 m |

Nas outras 394 casas, o enterramento máximo passa de 0,341 para 0,028 m e a flutuação máxima de 0,003 para
0,028 m. O limite da ordem era 0,10 m para as duas. As casas todas, uma a uma, estão em
`medicao-pe-encosta-antes-depois.json`.

## Parte A: a grelha maior (30 × 30 de 1,5 m), coerente com o servidor

O servidor de verdade (`servidor/ferramentas/juizo-terreno.mjs`, o núcleo `sala.js` com
`dados/terreno-floresta.json`) põe as figuras e diz que casas a heroína pode pisar. O cliente desenha o
snapshot que o servidor mandaria.

- **Postes vermelhos:** as 43 casas que o servidor julga bloqueadas (menires, santuário, lanternas, água
  funda…). A base de cada poste está na altura que o servidor dá (`alturaM`). Se cliente e servidor
  estiverem de acordo, o poste nasce do chão desenhado.
- **Destaques azuis:** as casas do mover que o servidor oferece à heroína em (2, 2), na roda dos menires.
  Contornam os menires.
- **A17:** panorama da grelha 30 × 30.
- **A18 e A19:** a roda dos menires, fora da zona livre.
- **A20:** o santuário (canto SE). O servidor recusa colocar uma figura em (28, 28) com o motivo «santuário».
- **A21:** as figuras que o servidor pôs na encosta. As casas 5–7 da grelha 30 × 30 são as 6 casas da
  Parte B.

`medicao-terreno-cliente-servidor.json` tem, casa a casa, o que o cliente desenha e o que o servidor julga
em três grelhas: 30 × 30 de 1,5 m (900 casas, 400 dentro da zona livre e 500 fora), 30 × 30 de 2 m (900
casas) e 20 × 20 (400 casas). O desvio da altura do centro, do pé e da posição das figuras desenhadas é 0
nas três: o mesmo double, comparado pelos bits. Os bloqueios, os motivos, a cobertura, as recusas, as casas
do mover e os marcos batem.

`capturas.json` tem a lista das capturas com a etiqueta de cada uma e o que o servidor respondeu.
