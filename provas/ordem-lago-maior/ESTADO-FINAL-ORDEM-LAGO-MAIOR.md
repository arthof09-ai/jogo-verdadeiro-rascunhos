# ESTADO FINAL — ORDEM LAGO-MAIOR (o lago maior e mais fundo + a floresta de dentro do campo devolvida)

Executor: Claude do PC, conta 2 (Opus, esforço médio). Ordem de 20/11/2026 18:56–18:58 (palavra do Mestre),
interrompida às 19:47 pelo limite de 5 h e **retomada às 22:00 no ponto exacto** (a sonda `sonda_lago.gd` e a medição
`antes.json` das 19:46 usadas tal como estavam, sem reescrever nem recalcular).

- Ramo: **`claude2/lago-maior`**, sobre `c9c176f` (o head da `fable/integracao-50` quando a ordem foi dada). **Sem fusão.**
- Estado do repositório na retoma (22:00): ramo em `c9c176f`, nenhum ficheiro seguido alterado, só a sonda/medição e os
  `.uid` gerados pelo Godot por seguir — **igual ao das 19:46**.
- Entretanto o remoto `fable/integracao-50` avançou para `b62a887` (Ordem PROVAS-MAPA): **só acrescenta ficheiros em
  `provas/ordem-mapa-jogavel/provas-bancada/`**, nenhum do jogo. A fusão não deve dar conflito; os números de terreno
  registados nessas provas (tabela de grelhas) passam a ser os de antes desta ordem.

## 0. Resumo

| | antes | agora |
|---|---|---|
| área do lago | 183,1 m² | **452,6 m²** (×2,5) |
| área de **andar** (fundura ≤ 1,25 m) | 162,2 m² | **162,6 m²** (a mesma) |
| área de **nadar** (fundura > 1,25 m) | 20,9 m² | **290,0 m²** (×14) — **maior que a de andar** |
| fundura máxima | 2,00 m | **2,52 m** |
| fundura no meio | 2,00 m (19,5; −21) | **2,45 m** (21; −21) |
| casas de 1,5 m (pelo centro): andar × nadar | 76 × 5 | **70 × 131** |
| árvores / rochas / estrato dentro do mapa (grelha = o mapa) | 1 / 0 / 422 | **25 / 49 / 571** |
| tronco tombado | 4,1 m | **12,7 m** |

Medido pela **mesma sonda** (`provas/ordem-lago-maior/ferramentas/sonda_lago.gd`, área em passos de 0,25 m):
`medicao/antes.json` × `medicao/depois.json`; e por `ferramentas/verificar_lago.gd` corrido no relevo de antes e no de
agora (`medicao/verificar-antes.json` × `verificar-depois.json`).

## 1. O lago — VERIFICADO (medido)

### 1.1 Área e profundidades

- **Nível da água: o mesmo** (−1,522 m). O lago cresce para fora e para baixo, não sobe.
- **Faixa de andar: a mesma área** (162,2 → 162,6 m²) e **a mesma profundidade** (0,48 m, a «rasa pelo joelho» da
  Ordem 66). Interpretação registada: «mantém a mesma extensão» = a mesma **quantidade de área** (palavra do Mestre,
  18:57: «pode deixar a quantidade de área para andar»). Com a mesma *largura* de faixa (~5 m) num lago maior, a área
  de andar crescia com o perímetro e nunca ficava menor que a de nadar.
- **Tudo o que cresceu é água de nadar**: 20,9 → 290,0 m².
- **Perfil** (fundura pela distância à margem, para dentro):

| distância à margem | 0 | 0,5 m | 1,0 m | 1,5 m | 2,0 m | 2,5 m | 3,0 m | 4,0 m | 5,0 m | ≥ 6,0 m |
|---|---|---|---|---|---|---|---|---|---|---|
| fundura | 0 | 0,42 | 0,48 | 0,75 | 1,28 | 1,60 | 1,64 | 1,92 | 2,28 | **2,45** |

  (`verificar-depois.json`, `perfil_por_distancia_a_margem`, sem o ondulado do fundo.)
  faixa de andar (rasa, 0,48 m) até 1,0 m · talude até 2,55 m (passa a fronteira do nado, 1,25 m, a ~2 m da margem) ·
  funda de 1,60 m a 2,45 m (plena a 6 m da margem), com o fundo a ondear ±7 cm (máximo medido 2,52 m).
- **No meio, uma figura de 1,7 m** com o pé no leito (como o jogo a põe hoje numa casa funda) fica **submersa, com a
  cabeça 0,75 m abaixo da água**; a boiar (`LagoFloresta.pe_na_agua`, o que o NADO já faz) fica com 1,25 m de água
  acima do pé — pelo peito. Nenhuma mecânica nova.
- **Margem**: desenhada, irregular — uma baía a oeste, um lóbulo a norte, nada de círculo (raios de 7,8 a 15,1 m à
  volta de (21; −21)). Contém o lago da Ordem 66 inteiro. Fica a mais de raio + 1,3 m de cada árvore posta à mão, a
  mais de 0,9 × tam + 0,7 m de cada rocha, a mais de 3,2 m do trilho, a mais de 2 m da borda do mapa; o santuário
  (SE, 20,5; 20) e os menires (NO) ficam longe.

### 1.2 Casas de água por grelha

Pelo centro da casa, geometria do lago (`verificar_lago.gd`):

| grelha-mapa | antes: andar × nadar (água) | agora: andar × nadar (água) |
|---|---|---|
| 1 m (75 × 75) | 162 × 21 (183) | **164 × 289** (453) |
| 1,5 m (50 × 50) | 76 × 5 (81) | **70 × 131** (201) |
| 2 m (37 × 37) | 43 × 5 (48) | **41 × 72** (113) |

**Casas de água do servidor** (motivo «água funda» do pacote, a regra do servidor e das arenas: a casa do mapa debaixo
do centro): **1 m: 50 → 301 · 1,5 m: 21 → 131 · 2 m: 13 → 75.**

### 1.3 O que mudou nos dados do terreno

`rascunhos/cliente/mapa/floresta/relevo_floresta.gd` (as profundidades por casa continuam escritas na grelha cozida do
relevo, `_fino`, que é malha = colisão = consulta):
- `LAGO_CENTRO` (21; −21) e `LAGO_MARGEM_M` (72 raios, de 5 em 5°, Catmull-Rom entre eles) — a margem desenhada;
  `distancia_margem()`, `dentro_da_margem()`, `margem_raio()`, `perfil_fundura()`.
- O perfil: `LAGO_RASA_M` 0,48 (igual) · `LAGO_ANDAR_FIM` 1,0 · `LAGO_TALUDE_FIM` 2,55 · `LAGO_FUNDA_BASE_M` 1,60 ·
  `LAGO_FUNDA_M` 2,0 → **2,45** · `LAGO_FUNDA_PLENA` 6,0. Saem as três «bolhas» da funda da Ordem 66.
- Fora da margem, o chão seco desce para a água num **barranco** de `LAGO_BARRANCO` 0,35 m/m (nunca abaixo do nível
  dentro do raio onde o lago olha). `LAGO_RAIO` 11 → 19,5 m (o raio à volta da cova dentro do qual o lago existe).
- **1.235 vértices** da zona fina mudaram (todos a menos de 23,5 m do centro do lago); **0 na costura** com a zona larga;
  **0 amostras com água a mais de 0,6 m fora da margem**, 0 secas por dentro (`verificar-depois.json`). Maior desnível
  dentro de uma casa de andar: 1,36 m (antes 1,55; a escarpa é a partir de 1,7) — **nenhuma escarpa nova** (32 = 32).
- O relevo da Ordem 38 (`_fino_38`, `agua()`, `normal_38()`) fica intacto: é dele que o gerador decide — **a floresta
  não muda de sítio por causa do lago**.

`rascunhos/cliente/mapa/floresta/campo_floresta.gd`:
- **«água funda» = onde não se faz pé**: fundura do lago novo no centro da casa > `LagoFloresta.FLUTUA_M` (1,25 m, a
  fronteira do NADO). Antes: o charco da Ordem 38 com mais de 0,40 m (21 casas, a maioria de fundura de andar). As casas
  da faixa de andar são chão — pisam-se como sempre.
- **Decoração**: nenhuma árvore nem pedra nasce na água (`_na_agua`: a semente gasta-se igual, o lugar fica ocupado — o
  resto do mapa sai o mesmo; medido: 0 árvores e 0 rochas na água; o estrato que caía na água nova não cresce, 5 → 14).
- **A margem nova recebe a mesma terra de margem** (o mesmo carimbo de lodo da Ordem 66, agora ao longo da linha de
  água nova, 120 carimbos a 0,3 m para fora); o leito por baixo de água continua a ser lodo (`_carimbar_leito_do_lago`,
  que segue o lago sozinho).
- **A árvore seca da cova** ficava debaixo de água (estava a 6 m da cova): passa para a ponta da baía de oeste
  (`ARVORE_SECA_RUMO` 275°, a 0,9 m da água — o sítio da margem mais longe de árvores, rochas e trilho, 8 m),
  inclinada para a água.

`rascunhos/servidor/dados/terreno-floresta.json`: **refeito pelo exportador** (`exportar_terreno.gd`); conferência
completa `conferir-terreno.mjs`: **«TERRENO EM DIA»** (refeito pelo cliente, igual byte a byte).

### 1.4 A água continua pisável e a reagir

- A grelha continua a ser o mapa inteiro (75 / 50 / 37 casas). As 131 casas de água a 1,5 m alcançam-se e pisam-se
  (testes do servidor `ordem-mapa-jogavel` (b): todas as casas pisáveis alcançáveis do canto, a heroína entra no meio do
  lago nas três escalas; (c) 6 m sobre a água = 6 / 4 / 3 casas; (d) ataque de oportunidade dentro de água).
- ÁGUA-REAÇÃO nas casas novas: os testes do cliente da água-reação (entrar → um salpico, vadear, acalmar, passar a nadar
  → um salpico) correm agora **no lago novo** (o ponto de vadear antigo, (14,6; −18,6), caiu na parte de nadar e passou
  para (13,85; −15,75), na faixa de andar). E nas capturas o manequim mexe a água (linha de espuma à volta do corpo).
  A superfície e a textura da fundura (`lago_floresta.gd`) cobrem o raio novo sozinhas.

## 2. A floresta de dentro do campo — VERIFICADO (medido)

### 2.1 O mecanismo da remoção (encontrado)

Em `campo_floresta.gd`, `_na_zona(x, z, raio)` testava a **zona jogável viva** (`zona_jogo`, que a arena põe igual à
grelha). Com a MAPA-JOGÁVEL a zona passou a ser o mapa inteiro e a regra da Ordem 42 («dentro do campo não fica
decoração solta») cortou em `_arvore` (39 árvores), `_registar_rocha` (66 rochas), `_criar_estrato` (168
arbustos/fetos) e `_marco_garganta` (o tronco tombado ficou com 4,1 m em vez de 12,7). A semente gastava-se igual
(as fontes não foram destruídas): bastava deixar de cortar.

### 2.2 A correcção

`_na_zona` passa a testar um **campo fixo**, `CAMPO_ORDEM_42 = Rect2(−15, −15, 30, 30)` — o quadrado do meio da grelha de
sempre (20 × 20 de 1,5 m), onde a Ordem 42 já cortava antes da MAPA-JOGÁVEL — **seja qual for a zona jogável**. O mapa
volta a ser exactamente o de antes da MAPA-JOGÁVEL, e é o MESMO com qualquer grelha (medido: zona = mapa, zona 20 × 20
e sem zona dão os mesmos 25 / 49 / 571 e as mesmas 283 casas bloqueadas). Por ser independente da zona, o pacote do
servidor (um só mapa de referência) continua exacto para qualquer grelha.

| dentro do mapa | antes da MAPA-JOGÁVEL (zona 20 × 20) | com a MAPA-JOGÁVEL (zona = mapa) | **agora** |
|---|---|---|---|
| árvores | 25 | 1 (39 cortadas) | **25** |
| rochas | 49 | 0 (66 cortadas) | **49** |
| estrato (arbustos, silvados, fetos, folhas largas) | 580 | 422 (168 cortados) | **571** (9 caíam na água nova) |
| tronco tombado | 12,7 m | 4,1 m | **12,7 m** |
| casas bloqueadas na grelha do cliente (1,5 m) | 173 | 88 | **283** = 152 + 131 de água |

### 2.3 A convenção de obstáculos (a do jogo, seguida — não inventada)

A de `_marcar_grelha` (Ordem 38): **tronco de árvore** → a casa do tronco **bloqueada** («tronco») e meia cobertura às
vizinhas; **rocha** de 1 m ou mais → as casas que ela cobre **bloqueadas** («rocha»), as menores só dão cobertura;
**tronco tombado** → bloqueado («tronco tombado»); **arbustos e mato (estrato)** → **pisáveis**, só cobertura, cenário
leve. No pacote do servidor: **67 → 152 casas bloqueadas** a 1,5 m (mais as 131 de água).

## 3. Provas — VERIFICADO

| prova | resultado |
|---|---|
| testes do cliente (`rodar_testes.gd`) | **290 / 290** (base em `c9c176f`: 290 / 290) |
| testes do servidor (`node --test testes/*.test.mjs`, inclui `privacidade.test.mjs`) | **403 / 403** (base: 403 / 403) |
| servidor × arena casa a casa, **18 grelhas** (`provar_terreno_servidor_mapa.gd`, a adaptada da PROVAS-MAPA, `b62a887`) | **TUDO PASSOU** — altura e pé com desvio 0 (bit a bit), bloqueios e motivos 0 diferentes, recusas = casas bloqueadas no cliente com o mesmo motivo, mover sem casas bloqueadas |
| servidor × arena, 12 grelhas (`provar_terreno_servidor.gd`, a original) | 9 FALHAS, **todas no caso 50 × 50 @ 1 m** — o artefacto conhecido (o servidor serve 75 × 75 e a ferramenta original desenha 50 × 50); **as mesmas 9 do registo do remoto** antes desta ordem. As outras 11 grelhas passam |
| conferência do pacote (`conferir-terreno.mjs`) | **TERRENO EM DIA** |
| canário de privacidade (cliente) | **10 / 10** |
| ponta-a-ponta (servidor + jogadora Node + Mestre Godot, motor falso) | **17 / 17**, jogadora OK, nenhum canário do Mestre |
| `abrir_scripts` 107/0 · `abrir_clareira` 22/22 · `abrir_mestre` 67/67 · `pecas_mestre` 286/286 · `hud_acoes` 50/50 · `medir_mestre` 0 falhas · `medir_painel_config` 0 falhas · arranque «pronto» | todos verdes |

Testes mudados (números presos ao lago e ao mapa antigos — cada um com o porquê no próprio teste):
- cliente `rodar_testes.gd`: casas de água por escala 50/21/13 → 301/131/75; o ponto de vadear da água-reação.
- servidor `ordem-mapa-jogavel`: os números do mapa (água e bloqueadas nas três escalas); a criatura por omissão no
  canto SO passa a `cantoSO()` (a 2 m o canto tem agora um abeto).
- `ordem44-terreno` (30 × 30: 26/17 → 43/47), `ordem48-terreno-qualquer-grelha` (25 × 25: 8/2 → 16/12; 25×25@2 28 → 46;
  33×27@2 35 → 59), `ordem59-fronteira-cobertura` (na faixa da fronteira a regra antiga também afirmava a cobertura 2,
  que agora existe por causa dos troncos), `ordem62-escala-bloqueadas` (figuras nomeadas 4/6/5/5 → 10/11/11/10).
- A grelha de sempre (20 × 20 de 1,5 m) continua com **0 casas bloqueadas**: as regressões «com ou sem terreno, o mesmo
  combate» passam sem mudança.

Registos: `provas/ordem-lago-maior/testes/` e `provas/ordem-lago-maior/provas-bancada/`.

## 4. Capturas — VERIFICADO (render com GPU)

`provas/ordem-lago-maior/capturas/` (RTX 4060, 1920 × 1080, a arena do jogo, grelha 50 × 50 @ 1,5 m). **A figura é o
manequim de referência da casa** (`Mannequin_F` do UAL2, ANDAR v3, SHA conferido) — **nenhuma cápsula nem bicho de
enchimento**: a arena abre sem figuras do jogo.

1. `1-mapa-inteiro.png` — vista da jogadora (Panorama): o mapa inteiro, o lago maior e a floresta devolvida.
2. `2-funda-pescoco.png` — a parte funda, a água pelo pescoço (1,49 m).
3. `3-funda-meio.png` — o meio (2,45 m): o manequim coberto.
4. `4-margem-rasa.png` — a faixa de andar: a água pelo joelho (0,42 m).
5. `5-floresta-ne.png` — o lago inteiro visto de dentro do campo, com as árvores e rochas devolvidas.

Antes, para comparar: `provas/ordem-mapa-jogavel/capturas/jogadora_50x50_1,5m_1-mapa-todo.png`.

## 5. Fronteiras — respeitadas

Não toquei na paleta, nas cores da caixa/retrato, na iniciativa nem no **custo da água** (continua igual a uma casa
seca: **[FALTA]** o número do Mestre). Natação: nada inventado (o pé no leito é o de hoje; o boiar é o do NADO).

## 6. Pontos para o coordenador / o Mestre

1. **PROPOSTO — o campo do meio (Ordem 42).** Devolvi o que a MAPA-JOGÁVEL cortou; o quadrado de 30 × 30 m do meio
   continua sem decoração solta, como antes dela (2 árvores, 24 rochas e 5 arbustos ficam por pôr lá, como sempre
   estiveram). Se o Mestre quiser também esse quadrado com floresta, é uma constante (`CAMPO_ORDEM_42` vazio) e refazer
   o pacote — mas a grelha de sempre (bancadas, ponta-a-ponta) passa a ter casas bloqueadas.
2. **«Água funda» mudou de sentido**: era o charco antigo (21 casas, quase todas de fundura de andar); agora é **onde
   não se faz pé** (131). As casas da faixa de andar são chão. O custo continua [FALTA].
3. O manequim de referência mede **1,81 m** na pose (a ordem fala de 1,7 m): no meio fica coberto de qualquer maneira
   (2,45 m); na foto 2 a água chega-lhe ao pescoço.
4. A árvore seca da cova mudou de sítio (ponta da baía de oeste) — o sítio antigo ficou debaixo de água.
5. A baía de oeste do lago chega a x ≈ 6 m (mais perto do meio do mapa do que o lago antigo, a 3,2 m do trilho no ponto
   mais perto). O olho do Mestre julga nas capturas.
6. Depois da fusão, as tabelas da PROVAS-MAPA (`b62a887`) ficam com os números de terreno de antes desta ordem.

## 7. Passagem

**Onde parou:** ordem cumprida — lago maior e mais fundo (área de nadar 290 m² > andar 162,6 m²; meio 2,45 m), floresta
devolvida, pacote do servidor refeito e conferido, provas verdes, capturas com o manequim. Commit no ramo
`claude2/lago-maior` (mais o commit das listas da retoma e do MANIFESTO, `retoma-i0004/actualizar-listas.py`) e ramo
enviado para o `origin`. **Sem fusão.**

**Próximo passo (coordenador):** conferir o CI do ramo, olhar as capturas com o Mestre e fundir em `fable/integracao-50`.

**O que falta conferir:** o olho do Mestre (forma da margem, tamanho, a floresta à volta); o ponto 1 (o campo do meio);
o custo da água ([FALTA], fora desta ordem).
