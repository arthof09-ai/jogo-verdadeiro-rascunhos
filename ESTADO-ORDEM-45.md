# Ordem 45: a arena do Mestre. Estado da ordem (escrito à medida)

*Conta 1, Opus, sessão única (às 00:08 de 2026-11-15 só havia um `ordem45-c1-out.txt`; nenhuma outra sessão
neste clone). Ramo `fable/mestre-45`, tirado de `66f49ff` (ponta da Ordem 44). Rascunhos e registos em
`C:\Users\txcga\fable-mapa\_tmp\o45\`.*

## Parte 0: levantamento

### Como a arena do jogador foi integrada (Ordens 42 e 44)

Lido em `cenas/arena/arena.gd`, `assentamento.gd`, `bacias_do_relevo.gd`, `ESTADO-FINAL-ORDEM-42.md`,
`NOTAS-MEDICAO-ORDEM-42.md` e `ESTADO-FINAL-ORDEM-44.md`.

- **O mapa é o chão.** `_garantir_mapa(zona)` cria `CampoFloresta` como filho `Mapa` (o primeiro da cena), com
  `no_ambiente`/`no_sol`/`no_camera` a apontar para o Ambiente, o Sol e a Câmara da arena, sem teclas de vistas
  e sem rótulo de medição, e `zona_jogo` = o rectângulo da grelha. O mapa reescreve o Environment e a luz: **um
  só céu**. O chão do clima são `Arena/Terreno` e `Fundo/TerrenoLargo` do mapa (grupo `clima_chao`).
- **Onde fica a grelha.** `Assentamento.origem_no_mapa(tam, casa_m)`: centrada em (0, 0) e encostada às linhas
  de 1,5 m do mapa (20 × 20 → origem (−15, −15)).
- **O que se cola ao relevo.** Linhas amostradas a ¼ de casa a +0,03 m; destaques, fogo e cursor são remendos
  (5 × 5 vértices por casa) à altura do relevo + 0,03…0,05 m, com o shader `sobre_relevo.gdshader` (puxa
  0,45 m para a câmara, para passar à frente da relva pisada). Tudo lê `Relevo.altura`.
- **Toque.** `ponto_no_chao`: o raio desce em passos de 0,25 m até ficar abaixo do relevo e afina por bisseção.
- **Câmara.** `camera.altura_em = altura_chao`; `configurar_arena` com o centro à altura do relevo. A cada quadro
  `mapa.definir_recorte_vista(foco, 5 m)` (0 quando a câmara da mesa não processa).
- **Pé das figuras (Ordem 44, Parte B).** `Assentamento.pegada(x, z, 0,28 × casa)`: plano dos mínimos quadrados
  com deslocamento minimax; `y` é o `peM` do servidor. A mancha de base deita-se no plano; o corpo de pé fica a
  prumo e sobe `subida_do_corpo`; o corpo caído deita-se no plano.
- **Clima (Ordem 42, Parte 2).** `clima.altura_do_chao = altura_chao`; `bordas_abrigo = 0`;
  `definir_bacias(BaciasRelevo.achar(zona))`; abrigos = os 8 obstáculos reais mais perto da zona (caixas
  invisíveis no grupo `clima_obstaculo`) + as malhas reais registadas com `registar_obstaculo`; a relva do mapa
  recebe `clima.empurrar_terreno_para` quando há neve/água/lama. Na arena do jogador, o clima liga-se pela
  preferência local `"clima"` (`nenhum`, `chuva-fraca`, `chuva-forte`, `neve-fraca`, `neve-forte`).
- **Servidor (Ordem 44, Parte A).** O exportador abre a arena do jogador e escreve `terreno-floresta.json`; o SHA
  de 5 fontes (`relevo_floresta`, `grelha_floresta`, `campo_floresta`, `formas_floresta`, `assentamento`) vai no
  pacote. `arena.gd` não está entre elas.

### Como a arena do Mestre difere

`cenas/mestre/arena_mestre.gd` (335 linhas), criada por código dentro de um `SubViewport` (`own_world_3d`) no
lado esquerdo do ecrã do Mestre (`mestre.gd` `_montar`). Não tem `.tscn` próprio.

| | arena do jogador | arena do Mestre (hoje, `66f49ff`) |
|---|---|---|
| chão | o mapa da floresta, com relevo | um `PlaneMesh` verde plano, em y = 0 |
| grelha | centrada no mapa, origem (−15, −15), linhas no relevo | origem (0, 0), linhas a y = 0,01 |
| céu e luz | os do mapa (paleta pintada, névoa) no Ambiente e no Sol | os do site: fundo 353b48, ambiente 96b4df, sol ffb16b a 1,35, fixo |
| figuras | cápsula provisória + mancha de base (Ordem 44) | marcador do site (`cenas/comum/marcador_figura.gd`): anel, sombra de contacto, corpo de pedra; a y = 0 |
| destaques, fogo, anel da vez | remendos no relevo | `QuadMesh` planos a 0,03 m; contornos `ImmediateMesh` |
| toque | raio contra o relevo | raio contra o plano y = 0 |
| câmara | `CameraMesa` com `altura_em` | `CameraMesa` sem `altura_em`; mais a câmara livre (só do Mestre), presa a y ∈ [0,4; 12] |
| clima | ligado ao mapa (bacias, abrigos, relva) e pela preferência | o módulo existe (Ordem 40), sem bacias, sem abrigos, no chão plano; nada o liga no ecrã |
| HUD | `hud.tscn` (jogador) | a folha do Mestre (abas Mesa, Agir, Figuras, Ambiente, Registo) — à parte da arena 3D |

O que a arena do Mestre tem e a do jogador não: todas as figuras colocadas (o Mestre vê tudo), o anel da vez, as
casas a arder vindas de `vista.mestre.fogo`, a câmara livre, os nomes de Mestre. Nada disso muda.

Quem usa `ArenaMestre`: `mestre.gd`; os testes `pecas_mestre` (CI), `abrir_mestre` (CI), `e2e_mestre` (CI,
ponta a ponta), `foto_mestre` (CI, job `foto-mestre`), `medir_mestre` (CI); a bancada `video_clima.gd` da
Ordem 40/41 (não corre no CI; usa a arena do Mestre como chão plano de bancada).

### O plano

1. **Uma só fonte para o que se cola ao mapa.** Tirar de `arena.gd` para um módulo partilhado
   (`cenas/arena/campo_da_mesa.gd`, só funções estáticas, sem `Estado`/`Rede`/Mestre) o que as duas arenas têm de
   fazer igual: montar o mapa na zona, ligar o clima ao mapa (bacias, abrigos, malhas), a malha de remendos por
   casa, as linhas da grelha no relevo e o raio contra o relevo. `arena.gd` passa a chamar o módulo com os mesmos
   argumentos: o comportamento do jogador fica igual (prova: `provar_assentamento`, `rodar_testes`,
   `exportar_terreno --conferir`, as mesmas contas). Não é um sistema paralelo: é o mesmo código, num sítio só.
2. **Parte 1 — terreno e grelha.** `arena_mestre.gd` monta o mesmo mapa, com a mesma origem
   (`Assentamento.origem_no_mapa`), linhas e remendos no relevo (as cores do site ficam), toque contra o relevo,
   `camera.altura_em`, recorte da vista. O pé do marcador do site segue a regra da base inclinada: a raiz na
   altura `Assentamento.pegada(...).y` (o `peM` do servidor), o anel e a sombra de contacto deitados no plano, o
   corpo de pé a prumo, o corpo caído deitado no plano. A câmara livre passa a medir a altura a partir do relevo.
   Medição: uma ferramenta headless (`cenas/mestre/ferramentas/provar_mestre_no_relevo.gd`) mede na cena do
   Mestre o que a Ordem 42 mediu na do jogador (centro − relevo, remendos − relevo, linhas, pé das figuras,
   toque) e compara casa a casa com a arena do jogador.
3. **Parte 2 — clima.** A mesma ligação do clima ao mapa (as mesmas bacias de `BaciasRelevo.achar(zona)`, os
   mesmos abrigos). O céu e o sol do site saem: o Ambiente e o Sol do Mestre passam a ser os do mapa (um só céu,
   o mesmo do jogador). O clima no ecrã do Mestre liga-se pelo mesmo nome da preferência do jogador
   (`definir_clima`), e segue o clima de jogo que o Mestre escolhe na aba Ambiente. Nada do ciclo do dia nem do
   vento: a Ordem 43 constrói-os dentro do mapa (`campo_floresta`); como o Mestre passa a usar o céu e o sol do
   mapa, a ligação dela chega aos dois ecrãs sem mexer aqui. `clima.definir_vento` fica como está.
4. **Privacidade.** Nada sai de `cenas/mestre/` para fora; o módulo partilhado não lê nada do Mestre (o canário
   proíbe `modelo_mestre`, `textos_mestre`, `Estado.mestre` fora de `cenas/mestre/`).

## Parte 1: terreno e grelha no ecrã do Mestre (feito)

**O que mudou.**

- `cenas/arena/campo_da_mesa.gd` (novo): o que as duas arenas fazem igual sobre o mapa — montar o mapa, ligar o
  clima ao mapa, a relva a seguir o clima, os remendos por casa, as linhas da grelha no relevo, o raio do toque.
  Tirado de `arena.gd` sem mudar uma conta; `arena.gd` chama-o (−125 linhas). Provado que a arena do jogador
  não mudou: `provar_assentamento` TUDO PASSOU, `provar_terreno_servidor` TUDO PASSOU, `exportar_terreno
  --conferir` EM DIA, `rodar_testes` 176/176, `clima_forte` 119/119, `hud_acoes` 32/32.
- `cenas/mestre/arena_mestre.gd`: o chão plano, o céu e o sol do site saíram. A arena monta o mesmo mapa, na
  mesma origem (`Assentamento.origem_no_mapa`); as linhas (c9c2a7), os destaques (cab577 a 50 %), os contornos
  (f5d59b), o fogo e o anel da vez colam-se ao relevo com o shader `sobre_relevo` (por cima da relva pisada);
  o toque vai contra o relevo; `camera.altura_em`; o recorte das copas entre a câmara e o foco, como no jogador.
- **O pé do marcador do site, pela regra da base inclinada.** A raiz do marcador fica no `pe_figura` (a
  `Assentamento.pegada` com o raio da pegada da arena do jogador: é o `peM` do servidor) e deita-se no plano da
  base: o anel e a sombra de contacto ficam no plano da encosta. O corpo de pé fica a prumo. Aqui houve uma
  adaptação, dita às claras: a cápsula do jogador tem o fundo redondo e sobe `subida_do_corpo`; o marcador do
  site tem o fundo **plano** (cilindro de 0,38 m), e um fundo plano rígido e a prumo não toca um plano inclinado
  sem flutuar de um lado (até 0,55 m na casa (0, 0)). Por isso o corpo segue o plano com um **cisalhamento
  vertical** (cada ponto sobe o que o plano sobe debaixo dele): o fundo assenta inteiro no plano e o eixo continua
  vertical; a cabeça desfaz o cisalhamento (fica redonda, no mesmo sítio). A figura caída deita-se no plano. O
  anel e a sombra do site (a 0,035 e 0,018 m) desenham-se com o `sobre_relevo` (senão a relva pisada tapava-os);
  a malha e a cor do site ficam como eram.
- `cenas/mestre/camara_livre.gd`: os olhos (1,6), o «chão + 0,4» e o tecto (12) contam-se a partir do relevo.
- `testes/pecas_mestre.gd`: 6 verificações que fixavam o chão plano em (0, 0) passaram a ler a origem e o relevo
  (câmara livre: olhos, beira sul, tecto, chão, bordas; nomes juntos: o foco e a altura das figuras; clima: o
  chão do mapa são 2 malhas, a zona e o fundo, como no jogador). Nenhuma verificação saiu.
- `cenas/mestre/ferramentas/provar_mestre_no_relevo.gd` (novo): a prova abaixo.

**Medição** (`provar_mestre_no_relevo.gd`, sem janela, no ecrã do Mestre de verdade — `mestre.tscn` — contra a
arena do jogador aberta ao lado com a mesma grelha e contra `servidor/dados/terreno-floresta.json`; o detalhe casa
a casa está em `provas/ordem-45-mestre/medicao-mestre-no-relevo.json`):

| o que se mede | 20 × 20 de 1,5 m (a zona livre) | 30 × 30 de 1,5 m |
|---|---|---|
| origem da grelha, Mestre = jogador | (−15; −15) = (−15; −15) | (−22,5; −22,5) = (−22,5; −22,5) |
| centro de casa − relevo | **0 m** (400 casas) | **0 m** (900) |
| centro de casa Mestre − jogador | **0 m** | **0 m** |
| centro de casa Mestre − `alturaM` do servidor | **0 m** | **0 m** |
| linhas / destaques / contornos / fogo − relevo | todos os vértices a 0,030 / 0,040 / 0,045 / 0,035 m, exactos | idem |
| linhas Mestre − jogador (sem o levantamento) | 0 m em 6 720 vértices | 0 m em 14 880 |
| figuras no pé da casa, anel e sombra no plano, corpo a prumo | 54 de 54 | 105 de 105 |
| pé Mestre − jogador (`pe_figura`) | **0 m** | **0 m** |
| pé Mestre − `peM` do servidor | **0 m** | **0 m** |
| fundo do corpo − plano da base | 0,000000 m | 0,000001 m |
| plano − relevo, raio da pegada (0,42 m) | enterra 0,025 / flutua 0,024 m; nas 6 da encosta 0,020 / 0,019 m (os números da Ordem 44) | casas que se pisam: 0,053 / 0,053 m; nas 5 bloqueadas pelo mapa (o servidor recusa-as): 0,304 / 0,311 m |
| plano − relevo, raio da sombra (0,5 m) | 0,034 / 0,024 m; nas 6: 0,027 / 0,019 m | 0,053 / 0,073 m |
| plano − relevo, raio do anel (0,56 m) | 0,045 / 0,028 m; nas 6: 0,038 / 0,019 m | 0,053 / 0,088 m |
| toque (Fixa · Panorama · 360° rasante) | 301/301 · 400/400 · 400/400 | 467/467 · 900/900 · 892/895 (5 centros tapados pelo relevo não contam) |
| casas do jogo que o mapa bloqueia, Mestre = jogador = servidor | 0 = 0 = 0 | 43 = 43 = 43 |
| céu | 1 WorldEnvironment, 1 DirectionalLight3D, céu pintado e névoa, os mesmos do jogador | idem |

O desvio grelha-relevo no ecrã do Mestre é **0 m**, como a Ordem 42 mediu no do jogador, e o Mestre e o jogador
dão o mesmo número em tudo o que se compara (é o mesmo código). Os 3 toques que falham na 30 × 30 em 360° rasante
— (0,6), (24,27) e (24,28), o raio sai da grelha — falham **igual** na arena do jogador: são do raio partilhado
(`ponto_no_chao`), em casas fora da zona livre, não do Mestre (ver as reservas no ESTADO FINAL).

## Parte 2: o clima no ecrã do Mestre (feito)

**O que mudou.**

- `arena_mestre.gd`: o clima assenta no mapa pelo **mesmo** `CampoDaMesa.ligar_clima` da arena do jogador — as
  bacias de `BaciasRelevo.achar(zona)` (os mesmos dados de `definir_bacias()`), os abrigos dos 8 obstáculos reais
  mais perto da zona, as malhas reais a vestir a neve, `bordas_abrigo = 0`, a altura do chão do relevo; a relva do
  mapa responde ao clima (`relva_segue_clima`), como no jogador.
- **Como se liga no ecrã do Mestre.** O clima de jogo que o Mestre escolhe na aba Ambiente (`MASTER_AMBIENTE` →
  servidor → `vista.mestre.ambiente.clima`) passa ao ecrã dele quando muda: «Chuva» → chuva fraca, «Tempestade» →
  chuva forte (o alagamento), «Neve» → neve forte (a nevasca); «Limpo», «Nublado» e «Nevoeiro» não chovem nem
  nevam. A tabela é uma (`CLIMA_DO_AMBIENTE`). Também há `definir_clima(nome)` com os nomes da preferência
  «clima» do jogador. Só apresentação: a arena não manda nada ao servidor e não muda regra nenhuma (o teste do
  clima do `pecas_mestre` confere: nenhum comando sai, casas, destaques e figuras ficam).
- **Um só céu.** O fundo 353b48, o ambiente 96b4df e o sol ffb16b do site saíram já na Parte 1: o Ambiente e o Sol
  do Mestre são os do mapa, iguais aos do jogador (a prova compara o céu, a névoa e o sol).
- **O ciclo do dia e o vento (Ordem 43) não foram tocados.** O ponto de ligação fica limpo: a Ordem 43 constrói o
  sol, a lua, o céu e o vento dentro do mapa (`campo_floresta`); como o Mestre monta agora o mesmo mapa com o
  Ambiente e o Sol dele (`CampoDaMesa.montar_mapa`), o que ela fizer no mapa chega aos dois ecrãs sem mexer nas
  arenas. O vento do clima continua a ser o do módulo (`clima.definir_vento`, intocado); a hora do servidor
  (`ambiente.hora`) não se liga a nada.
- `pecas_mestre.gd`: +1 verificação (a «Tempestade» da aba Ambiente chove forte no ecrã do Mestre); o teste do
  clima começa o relógio de procura do módulo do zero (a aba Ambiente, no teste anterior, já tinha ligado e
  desligado a chuva). 236/236.
- `provar_mestre_no_relevo.gd`: a secção 7 (as bacias e os abrigos do Mestre são os do jogador).
- `capturar_mestre_45.gd` (novo) e `provas/ordem-45-mestre/` (17 capturas rotuladas, as medições, o README).

**Medição.** Bacias: Mestre 8 = jogador 8, as mesmas, nível incluído (20 × 20 e 30 × 30). Abrigos da nevasca:
Mestre 8 = jogador 8, os mesmos. Alagamento no ecrã do Mestre com as bolsas cheias: 13,5 m² de água na zona,
4,3 cm de fundo — os números da Ordem 42 no jogador. Nevasca aos 38 s: neve 0,81, aglomerado 0,84, gelo 0,52.
