# Ordem 45: a arena do Mestre (terreno e clima no ecrã do Mestre). ESTADO FINAL

*Fecho da ordem, 2026-11-15 (00:08–00:40), conta 1, Opus, sessão única (havia um só `ordem45-c1-out.txt`; nenhuma
outra sessão neste clone). PCDANASA: RTX 4060, Godot 4.7.2 (Compatibility), Node 26 local. Ramo
`fable/mestre-45`, tirado de `66f49ff` (ponta da Ordem 44). As duas partes estão feitas, commitadas e empurradas.
O veredicto visual é do Mestre; o que está «provado» abaixo foi corrido ou visto por mim nesta máquina, e o resto
está dito. O levantamento (Parte 0) e o relato de cada parte estão em `ESTADO-ORDEM-45.md`.*

## O que mudou (commits)

| commit | o quê |
|---|---|
| `672c42c` | **Partes 0 e 1.** `ESTADO-ORDEM-45.md` (levantamento e plano). `cenas/arena/campo_da_mesa.gd` (novo): o que as duas arenas fazem igual sobre o mapa, tirado de `arena.gd` sem mudar uma conta. `arena_mestre.gd` no mesmo mapa, na mesma origem, com o pé do marcador pela base inclinada. `camara_livre.gd` no relevo. `pecas_mestre.gd` (6 verificações do chão plano passam a ler a origem e o relevo). `provar_mestre_no_relevo.gd` (novo) e `provas/ordem-45-mestre/medicao-mestre-no-relevo.json`. |
| `11a1c3e` | Listas da retoma e MANIFESTO refeitos (Parte 1). |
| `eb92f81` | **Parte 2.** O clima sobre o mapa no ecrã do Mestre (as mesmas bacias e abrigos do jogador; a relva responde); o clima de jogo da aba Ambiente liga-o. `pecas_mestre.gd` +1. `capturar_mestre_45.gd` (novo) e as provas: 17 capturas rotuladas, as medições e o README. |
| `3c9e782` | Listas da retoma e MANIFESTO refeitos (Parte 2). |
| *(este)* | Este ESTADO FINAL. |

## Parte 1: terreno e grelha no ecrã do Mestre

**Uma só fonte.** A arena do jogador (Ordem 42) tinha em `arena.gd` a montagem do mapa, a ligação do clima ao
mapa, os remendos por casa, as linhas no relevo e o raio do toque. Isso passou para
`cenas/arena/campo_da_mesa.gd` (funções estáticas, sem `Estado`, `Rede` nem nada do Mestre) e as duas arenas
chamam-no. A arena do jogador não mudou: `provar_assentamento` e `provar_terreno_servidor` TUDO PASSOU,
`exportar_terreno --conferir` EM DIA (o pacote do servidor continua byte a byte o que o cliente gera),
`rodar_testes` 176/176.

**O ecrã do Mestre.** A arena do Mestre (`cenas/mestre/arena_mestre.gd`, num SubViewport do `mestre.tscn`) deixou
o chão plano em (0, 0), o fundo, o ambiente e o sol do site. Monta o mesmo mapa da floresta, na mesma origem
(`Assentamento.origem_no_mapa`: 20 × 20 → (−15; −15)). As linhas da grelha, os destaques do «Mover», os
contornos, as casas a arder e o anel da vez colam-se ao relevo, com as cores do site e o shader `sobre_relevo`
(por cima da relva pisada). O toque vai contra o relevo; a câmara da mesa tem `altura_em`; as copas entre a
câmara e o foco recortam-se, como no jogador. A câmara livre conta os olhos, o «chão + 0,4» e o tecto a partir
do relevo.

**O pé das figuras (a regra da Ordem 44, parte B).** A raiz do marcador do site fica no `pe_figura` (a
`Assentamento.pegada` com o raio da pegada do jogador, que é o `peM` do servidor) e deita-se no plano da base: o
anel e a sombra de contacto ficam no plano da encosta. O corpo de pé fica a prumo. A figura caída deita-se no
plano. **Uma adaptação**, que digo às claras: a cápsula do jogador tem o fundo redondo e sobe `subida_do_corpo`;
o corpo do marcador do site tem o fundo **plano** (cilindro de 0,38 m), e um fundo plano rígido e a prumo não
toca um plano inclinado sem flutuar de um lado (até 0,55 m na casa (0, 0)). Por isso o corpo segue o plano com um
cisalhamento vertical: o fundo assenta inteiro no plano (medido: 0,000001 m), o eixo continua vertical, a cabeça
fica redonda. Ver a captura `M03`.

### Medição (desvio grelha-relevo no ecrã do Mestre)

`cenas/mestre/ferramentas/provar_mestre_no_relevo.gd`, sem janela, no `mestre.tscn` de verdade, contra a arena do
jogador aberta com a mesma grelha e contra `servidor/dados/terreno-floresta.json`. Casa a casa em
`provas/ordem-45-mestre/medicao-mestre-no-relevo.json`.

| o que se mede | 20 × 20 de 1,5 m (a zona livre) | 30 × 30 de 1,5 m |
|---|---|---|
| centro de casa − relevo | **0 m** (400 casas) | **0 m** (900) |
| centro de casa Mestre − jogador | **0 m** | **0 m** |
| centro de casa Mestre − `alturaM` do servidor | **0 m** | **0 m** |
| linhas / destaques / contornos / fogo − relevo | todos os vértices a +0,030 / 0,040 / 0,045 / 0,035 m | idem |
| linhas Mestre − jogador | 0 m (6 720 vértices) | 0 m (14 880) |
| pé Mestre − jogador · Mestre − `peM` do servidor | **0 m · 0 m** (54 figuras) | **0 m · 0 m** (105 figuras) |
| plano da base − relevo, raio da pegada 0,42 m | enterra 0,025 / flutua 0,024 m; nas 6 casas da encosta 0,020 / 0,019 m (os números da Ordem 44) | casas que se pisam 0,053 / 0,053 m |
| idem, raio da sombra 0,5 m · do anel 0,56 m | 0,034 / 0,024 · 0,045 / 0,028 m | 0,053 / 0,073 · 0,053 / 0,088 m |
| toque Fixa · Panorama · 360° rasante | 301/301 · 400/400 · 400/400 | 467/467 · 900/900 · 892/895 |
| casas bloqueadas pelo mapa, Mestre = jogador = servidor | 0 = 0 = 0 | 43 = 43 = 43 |
| céu | 1 WorldEnvironment e 1 DirectionalLight3D; céu pintado e névoa; céu, névoa e sol iguais aos do jogador | idem |

## Parte 2: o clima no ecrã do Mestre

- **O mesmo clima sobre o mesmo mapa.** `CampoDaMesa.ligar_clima`, o código do jogador: as bacias de
  `BaciasRelevo.achar(zona)` (os mesmos dados que a arena do jogador dá a `definir_bacias()`), os 8 abrigos dos
  obstáculos reais, as malhas reais a vestir a neve. A relva do mapa enterra-se na neve e afoga-se nas bolsas.
  Medido: bacias Mestre 8 = jogador 8 e abrigos 8 = 8, os mesmos, nível incluído, na 20 × 20 e na 30 × 30.
- **Como se liga.** O clima de jogo que o Mestre escolhe na aba Ambiente chega na vista (`mestre.ambiente.clima`)
  e o ecrã dele segue-o quando muda: «Chuva» → chuva fraca, «Tempestade» → chuva forte (o alagamento), «Neve» →
  neve forte (a nevasca); «Limpo», «Nublado» e «Nevoeiro» não chovem nem nevam. A tabela é uma
  (`CLIMA_DO_AMBIENTE`). Também há `definir_clima(nome)` com os nomes da preferência «clima» do jogador. Só
  apresentação: o teste do clima confere que nenhum comando sai e que casas, destaques e figuras ficam.
- **Um só céu.** O Ambiente e o Sol do Mestre são os do mapa, os mesmos do jogador (a prova compara o céu, a névoa
  e o sol).
- **O ciclo do dia e o vento (Ordem 43) não foram tocados.** A Ordem 43 constrói-os dentro do mapa
  (`campo_floresta`). Como o Mestre monta agora o mesmo mapa com o Ambiente e o Sol dele
  (`CampoDaMesa.montar_mapa`), o que ela fizer no mapa chega aos dois ecrãs sem mexer nas arenas. O vento do clima
  continua a ser o do módulo (`clima.definir_vento`, intocado). A hora do servidor (`ambiente.hora`) não se liga a
  nada.
- **No ecrã:** nevasca aos 38 s com neve 0,81, aglomerado 0,84 e gelo 0,52, a juntar-se contra os menires, as
  rochas e o tronco tombado. Alagamento com as bolsas cheias: 13,5 m² de água na zona, 4,3 cm de fundo (os
  números da Ordem 42 no jogador). A aliada fica com os pés na cova do prado.

## Capturas para o veredicto do Mestre

`provas/ordem-45-mestre/capturas/`, com o README. São 17 imagens de 1920 × 1080, com etiqueta, todas do ecrã do
Mestre de verdade (a arena 3D e a folha; nas de perto a folha está encolhida):

- **M01–M05, vista normal:** Panorama, Fixa, a heroína na encosta de 35° do outeiro (o pé), 360° rasante e a
  câmara livre (aberta pelo botão do ecrã);
- **N01–N06, neve:** antes, 9 s, 22 s, 38 s, e de perto os menires (NO) e o tronco tombado (SO);
- **A01–A06, alagamento:** seco, 16 s, 30 s, 44 s, e de perto as covas do prado e a boca da garganta.

Vi-as todas com os meus olhos. A grelha segue o relevo e as figuras estão de pé nas casas, também na encosta. Na
M03 o anel e a sombra estão deitados na encosta, o corpo a prumo, sem fresta. O céu é o do mapa. A neve junta-se
contra os obstáculos reais e a chuva enche as covas reais.

## O que o jogador vê (as regras que não se partem)

- **A arena do jogador não mudou:** é o mesmo código, chamado de outro sítio. As provas da Ordem 42/44 passam com
  os mesmos números (`provar_assentamento`, `provar_terreno_servidor`, `exportar_terreno --conferir`,
  `rodar_testes`, `clima_forte`, `hud_acoes`, `abrir_clareira`, o arranque).
- **Nada do Mestre sai de `cenas/mestre/`.** O módulo partilhado não lê nada do Mestre. O clima do ecrã do Mestre
  segue a vista do Mestre, que só o Mestre recebe. `canario_privacidade` 10/10; a Sonda de privacidade do CI verde
  em todos os pushes; no ponta a ponta, a jogadora «nenhum canário do Mestre».

## Provas corridas no fecho (ponta `3c9e782`)

**Cliente, sem janela (Godot 4.7.2):**

| suite | resultado |
|---|---|
| `abrir_scripts` | 67 scripts, 0 falhas (64 antes, mais os 3 novos) |
| `rodar_testes` | 176/176 |
| `clima_forte` | 119/119 |
| `pecas_mestre` | **236/236** (235 antes, mais 1) |
| `hud_acoes` | 32/32 |
| `abrir_clareira` | 22/22 |
| `abrir_mestre` | 57/57 |
| `canario_privacidade` | 10/10 |
| `medir_mestre`, `medir_painel_config` | saída 0 |

Nenhuma suite teve SCRIPT ERROR. Também correram: o arranque `--quit-after 600` («pronto», 0 erros);
`provar_assentamento`, `provar_terreno_servidor` e `provar_mestre_no_relevo`: TUDO PASSOU; o `exportar_terreno
--conferir`: EM DIA.

**Servidor:** 348 testes, 348 passam, 0 falham (não lhe toquei).

**Ponta a ponta** (servidor Node de verdade, jogadora Node e Mestre Godot, motor falso): **17/17**, jogadora OK,
nenhum canário do Mestre.

**Com render:** `capturar_mestre_45.gd` fez as 17 capturas nos três modos, 0 erros.

**CI:**

- ponta `3c9e782`: «Testes dos rascunhos», run 43672913587, **verde nos 9 jobs** (`servidor`, `validador-glb`,
  `motor-real`, `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta` com o motor falso e o VLAB real,
  `retoma-pc` e `foto-mestre`, que fotografa o ecrã do Mestre já com o mapa). «Sonda de privacidade», run
  43672913551: verde.
- ponta da Parte 1 (`11a1c3e`): runs 43672780060 (9 de 9 jobs verdes) e 43672780101 (Sonda), ambos verdes.
- O run do commit deste documento não mexe em `rascunhos/`.

## Reservas honestas

1. **O corpo do marcador cisalha-se.** A base segue a regra da Ordem 44 à letra (a mesma função, o mesmo `peM`).
   O corpo de fundo plano do site não sobe como a cápsula: segue o plano com um cisalhamento vertical. O eixo fica
   vertical e a cabeça fica redonda. Na encosta de 35°, o topo do cilindro fica inclinado como o chão (tapado em
   boa parte pela cabeça). É a minha leitura de «a prumo, a tocar o plano sem o atravessar» para um fundo plano.
   Pede o olho do Mestre (M03).
2. **Três toques na 30 × 30, em 360° rasante.** As casas (0,6), (24,27) e (24,28) dão «fora da grelha». Falham
   **igual** na arena do jogador: são do raio partilhado (`ponto_no_chao`), fora da zona livre. Não os investiguei;
   a 20 × 20 dá 400/400 nos três modos.
3. **O pé fora da zona livre.** Na 30 × 30, nas 5 casas bloqueadas pelo mapa (menires, santuário, água) o plano
   fica até 0,30 m do relevo. O servidor recusa essas casas (Ordem 44), e é igual no jogador. Nas casas que se
   pisam fica até 0,053 m (raio da pegada) e 0,088 m (raio do anel).
4. **A tabela do clima de jogo é uma escolha minha.** «Neve» dá neve **forte** (a ordem pede o clima forte) e
   «Chuva» dá chuva fraca. Não há «neve fraca» no clima de jogo. Mudar é uma linha (`CLIMA_DO_AMBIENTE`).
5. **Perfis gráficos.** O ecrã do Mestre não tem escolha de perfil. A relva do mapa fica na densidade do próprio
   mapa (1,0, a do Alto), e o clima usa as contagens do «médio» do módulo. O jogador segue o perfil que escolhe.
6. **Custo.** O ecrã do Mestre passou a construir o mapa da floresta (~1,5 s, 45 mil tufos) dentro do SubViewport.
   `abrir_mestre` foi de 4 s para 12 s e `medir_mestre` de 1 s para 8 s, sem janela. Não medi FPS nem chamadas de
   desenho do ecrã do Mestre com render.
7. **Material do anel e da sombra.** Para ficarem por cima da relva sem o clima os vestir, desenham-se num
   `next_pass` com o `sobre_relevo`, por baixo de um material transparente e sem luz. A malha e a cor do site
   ficam. É um truque; está comentado no código.
8. **A bancada `video_clima.gd`** (Ordens 40/41, fora do CI) usava a arena do Mestre como chão plano de bancada.
   Agora essa arena é o mapa. Compila (`abrir_scripts`), mas não corri os modos dela de novo. Os vídeos dessas
   ordens continuam a ser do chão plano em que foram gravados.
9. **Um defeito latente da arena do jogador, deixado como está.** Quando a grelha se refaz, o nó `Linhas` novo
   fica com outro nome enquanto o velho espera pela fila de libertação. Na do Mestre corrigi-o
   (`remove_child` antes); na do jogador não lhe toquei (regra: não alterar o comportamento dela). A prova procura
   a malha viva.
10. **Os testes tocam em dois privados do módulo do clima.** `pecas_mestre` e a prova põem `_ate_procurar = 0`
    (o relógio de procura dos alvos, de 0,5 em 0,5 s), como o teste da Ordem 41 já tocava em
    `segundos_transicao` e `segundos_levantar`.
11. **Higiene.** Rascunhos e registos em `C:\Users\txcga\fable-mapa\_tmp\o45\`. Nada de
    `referencias-arvore-ancestral/`, de `.avi` nem de `_tmp` nos commits (conferido no `git diff --cached` de cada
    commit). A fixture `servidor/dados-exemplo/mesa-mestre.json` continua com os fins de linha locais (o resíduo da
    Ordem 44) e não foi commitada. Não toquei em `main`, nos outros ramos, nos workflows nem no clone da Ordem 43.
    Os pushes foram normais, sem força.

## O que fica para depois

- Juntar o ramo da Ordem 43 (ciclo do dia e vento) quando ela fechar. O ponto de ligação é o mapa: os dois ecrãs
  passam o Ambiente e o Sol ao `campo_floresta` pelo mesmo `CampoDaMesa.montar_mapa`.
- Decidir a tabela do clima de jogo para o ecrã do Mestre (reserva 4) e se o Mestre também escolhe perfil gráfico
  (reserva 5).
- Medir o ecrã do Mestre com render (FPS, chamadas de desenho), como a Ordem 42 mediu o do jogador.
