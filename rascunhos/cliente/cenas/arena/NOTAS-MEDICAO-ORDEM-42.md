# Ordem 42: o mapa da floresta como campo de batalha. Notas de medição

*Ramo `fable/integracao-42`, a partir de `254188c` (ponta entregue da Ordem 38). Medido nesta máquina
(PCDANASA, NVIDIA GeForce RTX 4060, Godot 4.7.2, Compatibility). Os números vêm de
`capturas/medicao.json` e da saída de `ferramentas/provar_assentamento.gd`. Estas notas não aprovam
nada: o juízo é da bancada e do olho do Mestre.*

> A Parte 2 da ordem (o clima forte sobre o mapa integrado) está em `provas/ordem-42-clima-no-mapa/README.md`,
> e o fecho das duas partes em `ESTADO-FINAL-ORDEM-42.md` (nesta pasta).

## O que mudou na arena

A cena principal do cliente (`cenas/arena/arena.tscn`) apresenta agora o mapa da floresta como o
mundo da batalha. Quando a cena abre, a arena (`arena.gd`) cria o mapa como filho `Mapa`
(`mapa/floresta/campo_floresta.gd`) e passa-lhe três coisas:

- o **Ambiente**, o **Sol** e a **Câmara** da arena (`no_ambiente`, `no_sol`, `no_camera`). O mapa
  monta neles o céu pintado (paleta v2/v3), a névoa, a cor do horizonte e a luz. Fica **um céu só**:
  na árvore há 1 WorldEnvironment e 1 DirectionalLight3D (medido). O fundo de cor própria que a arena
  tinha deixou de contar, porque o mapa reescreve o Environment. A arena também já não roda o Sol: a
  direcção é a da luz pintada do mapa;
- a **zona jogável** (`zona_jogo`), que é o rectângulo da grelha do snapshot em metros do mundo;
- sem teclas de vistas e sem rótulo de medição (`vistas_por_tecla = false`, `mostrar_medicao = false`).

O mapa sozinho (`campo_floresta.tscn`) continua igual ao da Ordem 38. Corri a sonda sem zona e saiu o
mesmo da medição da 38: 44 590 tufos, 208 casas bloqueadas, 167 624 triângulos no anel, 0 erros.

Continua a ser **só apresentação**. As casas, os custos e os alvos vêm do servidor (`ROOM_SNAPSHOT` e
`ROOM_OPTIONS`), como antes. A arena não decide, não pede nem interpreta nada de novo.

## O assentamento da grelha no relevo (o método)

**Uma altura só.** Tudo o que a arena põe no chão lê `Relevo.altura(x, z)`
(`mapa/floresta/relevo_floresta.gd`). É a altura final única da Ordem 38: a malha do chão desenha-a, a
colisão sente-a e a consulta devolve-a (provado na 38 com `provar_altura.gd`: diferença máxima de
0,00002 m). A arena não tem chão próprio. O `PlaneMesh` verde saiu e o chão é o do mapa.

1. **Onde fica a grelha.** Centrada no centro da arena do mapa, (0, 0). Com casas de 1,5 m, a origem
   (canto noroeste) encosta às linhas da grelha do mapa (−37,5 + k × 1,5): cada casa do jogo é
   exactamente uma casa do mapa. Para 20 × 20, a casa do jogo (c, l) é a casa do mapa (c + 15, l + 15)
   e a origem fica em x = z = −15 m (`_origem_no_mapa`). A zona de 30 × 30 m cabe na arena de combate
   da receita (0–30 m do centro).
2. **Casas e figuras.** `centro_casa(c)` devolve x, z e a altura do relevo nesse ponto. A figura pousa
   em `pe_figura(c)`: no centro da casa, à altura **mais baixa** do relevo debaixo da pegada (o centro
   mais 8 pontos no raio da base, 0,42 m). Numa encosta nenhum lado da base fica no ar. O lado de cima
   entra no chão (ver os números e o pendente abaixo).
3. **Linhas, destaques, fogo e cursor.** Já não são quadrados planos. Cada um é um remendo que segue o
   relevo: (4 + 1)² vértices por casa, cada vértice à altura do relevo mais 3–5 cm. As linhas são
   amostradas a cada ¼ de casa. São refeitos sempre que mudam (`_malha_casas`).
4. **Por cima da relva.** Na zona jogável a relva está **pisada** (38 % da altura, 0,18–0,33 m) e
   continua a mexer com o mesmo vento. As hastes ficam a 23 %. Tudo isto se faz no shader da relva
   (`campo_rect`, `campo_alto`). O shader dos remendos (`cenas/arena/sobre_relevo.gdshader`) puxa cada
   vértice 0,45 m para a câmara **ao longo do próprio raio de vista**. No ecrã o vértice fica no mesmo
   píxel, mas na profundidade passa à frente da erva. Uma subida a sério (mais de 0,45 m) continua a
   tapá-lo, como deve.
5. **O toque.** `casa_em_tela` já não corta o raio no plano y = 0. Desce pelo raio até ao primeiro ponto
   abaixo do relevo (passos de 0,25 m) e afina por bisseção (14 passos).
6. **A câmara da mesa.** O foco fica à altura do chão. O Panorama afasta-se até caberem os 4 cantos e os
   4 meios das bordas, cada um à altura real do relevo (no chão e a 1,8 m).

### A prova (`ferramentas/provar_assentamento.gd`, headless, sai com 0)

| O que se mede | Resultado |
|---|---|
| centro de casa − relevo (400 casas) | maior 0,00000 m |
| vértices dos destaques (10 000), fogo, cursor e linhas (6 720) − relevo | todos entre +0,030 e +0,050 m |
| relevo acima do remendo entre vértices | 0,000 m (o shader ainda puxa 0,45 m) |
| pé de 49 figuras: ponto da base mais alto acima do chão | 0,002 m: nada no ar |
| toque: centros de casa vistos pela câmara que voltam à mesma casa | Fixa 70/70 · Panorama 400/400 · 360° rasante 361/361 |
| casas do jogo que o mapa bloqueia | 0 |
| céu | 1 WorldEnvironment, 1 DirectionalLight3D; o Ambiente tem céu pintado e névoa |
| perfis Baixo / Médio / Alto → densidade da relva do mapa | 0,50 / 0,75 / 1,00 |

## O desvio mapa-grelha e como se resolveu

**Encontrado** (`ferramentas/sonda_zona.gd`, antes da correcção):

- **Coordenadas.** A grelha do jogo começava em (0, 0) e crescia para +X/+Z (0–30 m). A do mapa é de
  50 × 50 casas centradas na origem (−37,5…37,5 m). Ficavam 15 m de desfasamento em cada eixo.
  Resolvido como se descreve acima: grelha centrada e encostada às linhas do mapa.
- **Relevo dentro da zona.** Vai de −1,26 a +1,19 m (2,44 m de desnível). A maior inclinação numa casa
  dá um degrau de 1,49 m, junto ao outeiro, no canto NO. Resolvido com o assentamento.
- **Obstáculos que o servidor não conhece.** 27 das 400 casas do jogo estavam bloqueadas pelo mapa:
  16 por rochas soltas do prado, 1 por um tronco de vidoeiro e 10 pela ponta do tronco tombado da
  garganta. Uma figura posta pelo servidor na casa (1, 1) ficava dentro de uma pedra.

**Resolvido (só apresentação; a regra continua no servidor).** Com `zona_jogo`, o mapa deixa de pôr
dentro da zona jogável (com 0,25 m de folga) aquilo que ocuparia uma casa sem o servidor saber:

- 24 pedras soltas;
- 2 árvores;
- 5 peças de estrato;
- o tronco tombado, que acaba à entrada da zona (12,7 m em vez de 20,7 m, cortado pela ponta da copa;
  o prato das raízes fica no sítio).

A semente aleatória gasta-se igual e o lugar fica ocupado (nada mais nasce ali). Por isso os marcos e
as árvores postas à mão ficam onde estavam. A dispersão ao acaso muda um pouco (estrato, anel e
relva: 45 265 tufos em vez de 44 590; anel com 165 828 triângulos em vez de 167 624), porque as pedras
tiradas deixam de carimbar terra no mapa do chão. Mantém a mesma densidade e a mesma qualidade. Medido depois: **0 casas bloqueadas** na zona. Os marcos de relevo
(outeiro, cova, terraço, garganta) não mudam: são chão.

**O que fica por resolver:** o servidor continua sem conhecer o terreno. Se o snapshot pedir uma grelha
maior (por exemplo 30 × 30, ±22,5 m), a zona chega aos menires, ao santuário e à cova. A arena refaz o
mapa para a zona nova, mas **não tira marcos**: essas casas ficam bloqueadas no mapa e livres no
servidor. A ponte é `grelha_floresta.gd exportar_terreno()` (alturas, bloqueios e cobertura por casa),
que já existe para o servidor montar o `ROOM_SNAPSHOT.mapa`. Isso é regra e não entra nesta ordem.

## Medições da cena integrada

1920 × 1080 num SubViewport, sem v-sync, 2 s por vista, perfil **Alto** (escala 1,0, MSAA 4×), com o
combate de demonstração (8 figuras, 40 destaques, 3 casas a arder, cursor). Os contadores são os do
motor (`Viewport.get_render_info`) e o relógio. Não usei o painel Profiler do editor.

| | Chamadas de desenho | Primitivas | FPS |
|---|---|---|---|
| Centro em jogo, Fixa (01, 02) | 115–118 | 1,20 M | 589–599 |
| Cantos, 360° (03–06) | 118–120 | 1,09–1,21 M | 590–645 |
| Longe, vista da referência 07 (07) | 118 | 1,25 M | 656 |
| Panorama (08) | 106 | 1,18 M | 602 |
| Volta de 360° rasante, 8 rumos (09–16) | 120–130 | 1,08–1,25 M | 572–663 |
| De perto (19, 20) | 96–98 | 1,07–1,08 M | 617–632 |
| Centro, perfil **Médio** (18) | 116 | 1,08 M | 1 224 |
| Centro, perfil **Baixo** (17) | 108 | 0,95 M | 1 663 |

- **Intervalo da cena integrada:** 96–130 chamadas e 0,95–1,25 M primitivas por quadro. Em Alto ficou
  entre **572 e 663 FPS**. Comparação: o mapa sozinho tinha 21–92 chamadas na Ordem 38. As chamadas a
  mais vêm das camadas da arena, das figuras (corpo e nome) e do HUD.
- **Carga:** 1 870 ms da cena inteira (o mapa demora 1 593 ms a construir-se).
- **A relva mexe:** a diferença média de luma entre dois quadros a 2 s é **4,45/255** no centro em jogo
  (01) e **7,47/255** de longe (07). A imagem da diferença (`*_MOVIMENTO-2s.png`) acende a relva
  dentro e fora da zona jogável; figuras, chão e pedras ficam pretos.
- **Erros:** 0 na corrida das capturas (com render) e 0 em headless (`--quit-after 600`: «pronto», sem
  `SCRIPT ERROR` nem `ERROR`). Testes do cliente corridos aqui: abrir_scripts (53 scripts, 0 falhas),
  rodar_testes 138/138, abrir_clareira 22/22, abrir_mestre 57/57, pecas_mestre, medir_mestre,
  medir_painel_config, hud_acoes 32/32 e canario_privacidade 10/10 passaram todos. CI: ver o ESTADO FINAL.

## A câmara da mesa sobre o mapa

- **Panorama (08):** o campo inteiro cabe, com os 4 cantos e as figuras, sem cortar.
- **Fixa (01):** com o zoom de 1,5 (18 m, 55°) vê-se o campo, os marcos à volta (os menires e o charco)
  e a orla.
- **360°:** a câmara roda em volta do foco e, nos cantos ou com o zoom mais afastado, fica atrás de
  coisas ou dentro da orla. Na primeira volta das capturas o santuário tapava o campo inteiro no canto
  SE, e no canto NO havia uma copa colada à lente. **Resolvido** com um recorte em ponteado
  (`mapa/floresta/shaders/recorte_vista.gdshaderinc`, nos shaders das copas, do sólido e dos marcos).
  Some num ponteado tudo o que fica dentro de um cilindro de 5 m entre a câmara e o foco, e tudo o que
  está a menos de 6–12 m da lente. O ponteado é feito por píxel, sem alfa nem ordenação. A relva, o
  chão e as figuras não são recortados. No mapa sozinho o recorte está desligado.
- **Cartões planos:** a volta rasante (09–16: inclinação mínima de 20°, câmara a 45 m) não mostra
  nenhum cartão a rodar de lado. O que se vê ao fundo é o anel de 720 árvores **inteiras** em 3D,
  desfeito na cor do horizonte, e a serra do anel longe. São as camadas do fundo da referência 07, que
  continuam a ser camadas vistas de qualquer rumo. Ver «O que falta conferir».

## O que ficou por fazer

1. **O terreno no servidor.** Ver acima: grelhas maiores do que a zona livre e os marcos.
2. **Figuras em casas muito inclinadas.** Em 6 das 400 casas, todas na encosta do outeiro (canto NO),
   o lado de cima da base entra mais de 0,35 m no chão. O pior é 0,60 m, na casa (0, 0), com 1,49 m
   de degrau. Em 14 casas passa de 0,20 m e em 22 passa de 0,10 m. Escolhi que nada flutue e paguei
   em enterrar o lado de cima. As figuras são marcadores provisórios: o pé verdadeiro (inclinar ou IK)
   é do Plano B.
3. **O ponteado do recorte** vê-se (é um padrão de píxeis) nas copas do primeiro plano quando a
   câmara está dentro da orla (vistas 03 e 11). É funcional, não é bonito: um desvanecer com alfa seria
   mais suave, mas obriga a ordenar a folhagem.
4. **Sombras das figuras.** Os perfis Médio e Alto ligam a sombra do Sol, mas o chão do mapa é
   unshaded (a luz é pintada e cozida): as figuras não deitam sombra no chão. Uma mancha de contacto
   por figura ajudaria a ler o pé e fica para quando as figuras deixarem de ser marcadores.
5. **O Ecrã do Mestre** (`cenas/mestre/arena_mestre.gd`) tem arena 3D própria e não foi integrado:
   esta ordem era a cena principal da jogadora.

## Nota de higiene

Na primeira hora escrevi quatro ficheiros de rascunho (scripts de edição e um log) em `/tmp` (a pasta
temporária do Windows), **fora** de `C:\Users\txcga\fable-mapa\`, contra a guarda 3. Apaguei-os assim
que dei por isso e todo o rascunho seguinte foi para `C:\Users\txcga\fable-mapa\_tmp\o42\`. O Godot
escreve também na sua pasta de dados de utilizador quando corre, como nas ordens anteriores.
