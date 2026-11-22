# ESTADO FINAL — ORDEM-CAIXA-PADRAO-CORRECOES (Claude conta 1, PC · 22/11/2026)

**Linha:** `fable/integracao-50`, trabalho directo, sem ramo lateral e sem fusão. Parti da ponta `00df26f`, que é a fusão
da pilha da estética. Fiz `fetch` antes de publicar e a ponta não tinha andado, por isso não houve rebase nem conflito.
Commits:
1. `6ab81e5` — código, testes e provas (B1–B9);
2. `802f87e` — este ESTADO-FINAL, com as listas da retoma sincronizadas;
3. o acrescento do resultado do CI a este ESTADO-FINAL (só documento).

Este ficheiro não tem nomes verdadeiros, nem pedaços deles, nem o valor de nenhum PIN. O conferidor estrito dá
0 / 0 achados nele (§3).

## 1. O que mudou, ponto a ponto

### B1 — o «de pé» já não depende do passo (`hud/retratos.gd`)
- **Medi o ciclo inteiro do ANDAR v3, nos 42 quadros a 30 q/s.**
  - A figura toda chega a **1,008 m** de fundo, no quadro 0. O limiar é 1,769 / 1,2 = **1,474 m**, por isso a margem
    é de **0,466 m**, e é também a margem mínima em todo o ciclo.
  - O tronco não passa de 0,653 m.
  - A figura está de pé nos 42 quadros, quer se meça pela caixa toda, quer pelo tronco.
- **A regra passa a medir só o tronco.** `de_pe(c, caixas)` usa `largura_tronco`: a largura das partes acima de
  metade da altura (`FRACAO_TRONCO` = 0,5). As pernas e os pés de quem dá um passo ficam fora da medida.
  - Sem `caixas`, a função mede a caixa toda, como antes. A chamada antiga continua válida.
  - Uma figura deitada ou um quadrúpede são largos também em cima, por isso continuam de corpo inteiro.
- **Teste com a figura a meio de uma passada longa** (as coxas abertas 60° para a frente e para trás). A figura mede
  1,59 m de fundo e 1,58 m de alto.
  - Pela caixa toda, já **não** contaria como de pé.
  - Pelo tronco (0,92 m) conta, e o retrato continua a ser o busto.
- Na prova viva, o ciclo inteiro corre também sobre o manequim de uma figura em cena, e o retrato da passada longa é
  desenhado (`retratos/casos/passada-longa.png`).

### B2 — o que não é corpo fica fora da faixa e da altura (`hud/retratos.gd`)
- **Funções novas `caixas_do_corpo` e `caixa_do_corpo`.** Se a figura tem malhas esfoladas, o corpo são essas malhas.
  As malhas **rígidas** que ela leva (uma arma empunhada, um escudo, um adereço preso a um osso) desenham-se no
  retrato, mas não contam para a altura, para a faixa do busto nem para o «de pé». Uma figura feita só de malhas
  rígidas, como a cápsula ou o marcador, conta toda como corpo.
- O `enquadrar` passa a medir o corpo. A `caixa_visivel` não mudou: continua a dar tudo o que se vê.
- **Teste com uma lâmina rígida de 1,1 m na mão direita, levantada.** A ponta fica a 2,40 m e a cabeça a 1,80 m.
  - O corpo e a janela do busto **não mudam**: a janela vai de 1,26 m a 1,85 m.
  - Se a arma contasse, a janela subia para 1,68–2,47 m.
  - O retrato continua a ser o busto, e a arma desenha-se.
- **Limites, documentados no código:**
  - Uma capa **esfolada** conta como corpo.
  - Um braço levantado **é** corpo e sobe a altura. Medido: com o braço levantado, a figura passa de 1,80 m para
    2,13 m. Continua de pé, o rosto fica no quadro e o peito sai (`retratos/casos/braco-levantado.png`).
  - Um adereço rígido na cabeça (um elmo) não sobe a janela e pode ficar cortado em cima.

### B3 — medir os caracteres visíveis (`hud/caixa_ordem.gd`)
- **Função nova `texto_visivel(label)`.** Devolve o que a linha de nome **mostra**, depois do corte com «…» na largura
  da célula. Faz a mesma conta que a Label: uma `TextLine` com a mesma fonte, letra e largura, cortada com o mesmo
  `text_overrun_behavior`.
- A prova passa a imprimir os caracteres visíveis, e não o `nome.text`. Na janela de 1028×720 os nomes compridos
  mostram **«Arqueir…» (7 letras)** e **«Espada…» (6 letras)**. Os nomes curtos ficam inteiros, com 4 e 5 letras. Nas
  capturas lê-se o mesmo.
- Na suite (`_teste_caixa_ordem`): o texto visível de um nome cortado é o começo do nome seguido de «…», e com mais
  uma letra já não caberia na célula.
- **A escolha de 7 ou 10 letras é do Mestre.** Não encontrei nenhuma palavra dele a mandar subir
  `LADO_RETRATO_EM_LETRAS`, por isso ficou em 3,4. A medida fica registada aqui e no fim do `relato.txt`.

### B4 — o ramo «corpo inteiro» exercitado
- **Manequim deitado** (0,48 × 1,01 × 1,77 m): não conta como de pé, e o retrato mostra o corpo inteiro, com os oito
  cantos no quadro.
- **Quadrúpede esfolado.** **O repositório não tem nenhum modelo de quadrúpede, e o PC também não** (procurei os
  `.glb`; só há manequins humanos). Por isso fiz um em código, em `testes/casos_retrato.gd`:
  - um `Skeleton3D` com 7 ossos, uma `Skin` e uma `ArrayMesh` com ossos e pesos;
  - o motor dá as caixas dos 7 ossos (`bone_aabbs`), tal como para o manequim;
  - mede 0,45 × 1,23 × 1,80 m e não conta como de pé, nem pela caixa toda nem pelo tronco (1,80 m);
  - o retrato mostra o corpo inteiro;
  - na prova viva, o motor esfola-o e a malha cabe na caixa.
- **Caixa zero** (nada visível): o enquadramento usa a figura de recurso de 2 m. A câmara fica à frente e olha o busto
  a 1,73 m, com os planos entre 0,01 e 5,18 m. Desenha sem erro (`retratos/casos/caixa-zero.png`).

### B5 — a validação em repouso, cometida, e a caixa em pose contra a AABB esfolada do motor
- **Em repouso** (`reset_bone_poses`), a conta por ossos dá a caixa da malha do ficheiro: 1,762 × 1,806 × 0,309 m,
  igual ao milímetro. A esfola também dá essa caixa, e a pose em T não conta como de pé. Isto está na suite e na
  prova viva.
- **Em pose**, comparei a caixa do retrato com a malha esfolada vértice a vértice.
  - A caixa **contém sempre** a malha.
  - A folga máxima é **0,143 m** (a 1,0 s do ANDAR, em z). Nas poses da prova viva é 0,050 m. Esta folga vem das
    caixas por osso, porque uma caixa de osso leva inteiros todos os vértices que o osso move.
- **A AABB do próprio motor** vem de `MeshInstance3D.bake_mesh_from_current_skeleton_pose`.
  - **Só funciona com render.** Com `--headless`, o motor não regista a skin e recusa.
  - Por isso a suite (que no CI corre sem ecrã) usa a esfola por CPU, que é a mesma conta que o motor faz.
  - A prova viva compara as duas: nos momentos 1, 2, 4 e 5, nos 4 retratos da cena, a esfola por CPU dá o mesmo que
    a do motor (diferença abaixo de 2 mm), e a caixa do retrato contém a malha esfolada pelo motor.

### B6 — um assert de largura renderizada por slot (`testes/caixa_janela.gd`)
- Em todas as medições (8, 12 e 16 figuras; 1280×720, 844×390 e 780×360) confere-se slot a slot que o rectângulo global e
  a moldura têm a largura da célula e que a moldura é quadrada. São 9 verificações novas.
  - Larguras medidas: 75 u (50,0 px reais), 122 u (44,1 px) e 133 u (44,3 px).
- **Prova de que dispara:** fiz uma mutação local, sem commit, que alargava as células conforme o id. Deu 9 falhas,
  e o ficheiro foi reposto.

### B7 — a privacidade também no momento 2
`await _privacidade("2")` passa a correr também no momento 2 (iniciativa), com as 4 verificações de sempre, que dão 4/4.

### B8 — o PIN das provas não volta a ser publicado
- A ferramenta da prova nova não tem nenhum literal do PIN. O lançador gera um PIN fresco de 20 dígitos por
  corrida e passa-o só por `--pin=`.
- O info e o log do servidor ficam na pasta temporária e **não** se copiam para a saída. A prova do padrão-busto
  copiava-os, com o PIN dentro.
- Também deixei de pôr a vista do Mestre no relato: as linhas da IA e da batalha a meio usam `nomePublico`, e o nome
  de entrada da jogadora já não se imprime. O relato novo tem 0 nomes verdadeiros inteiros.

### B9 — o tecto do desvio com a caixa nova (`testes/caixa_jogadora.gd`)
- **A caixa nova explica a diferença ao meio u.** A faixa centra-se entre a ⚙ e a caixa (margem direita = largura da
  caixa + folga). Por isso o desvio é (margem dir − margem esq) / 2, e muda metade do que a caixa muda:

| resolução | caixa antes → agora (u) | desvio antes → agora (u) | diferença |
|---|---|---|---|
| 844×390 | 1186 → 1193 | 539,0 → **542,5** | +3,5 = +7 / 2 |
| 780×360 | 1269 → 1292 | 576,0 → **587,5** | +11,5 = +23 / 2 |
| 1920×1080 | 767 → 753 | 350,5 → **343,5** | −7,0 = −14 / 2 |

- **Tectos actualizados para os valores medidos**: 542,5 / 587,5 / 343,5 u. A justificação está escrita no teste:
  «não pior que a caixa do padrão-busto».
- **A recentragem que não encolhe a caixa não se aplicou** (ver §4, ponto 3).
- **Sensibilidade:** baixei os três tectos 0,5 u, só no ficheiro local, e repu-los logo a seguir. Deu **33/36, rc 1**,
  e falharam exactamente as três guardas. Está em `provas/ordem-caixa-padrao-correcoes/tecto/sensibilidade.log`.

## 2. Os números das corridas

Godot 4.7.2, Windows 11, RTX 4060. As suites correram com `--headless`, como no CI.

| passo do cliente | resultado |
|---|---|
| `abrir_scripts` | 108 scripts (era 107: entrou `testes/casos_retrato.gd`), 0 falhas |
| `rodar_testes` | **311/311** (eram 297; +14) |
| `caixa_janela` | **78/78** (eram 69; +9, a B6) |
| `caixa_jogadora` | **36/36** (antes da B9 dava 34/36, as mesmas 2 falhas do CI 45076802117) |
| `abrir_clareira` | 22/22 |
| `medir_painel_config` | 0 falhas, 0 sem medida |
| `abrir_mestre` / `pecas_mestre` | 67/67 · 286/286; comandos contra os schemas: 9 e 26 mensagens, 0 falhas |
| `medir_mestre` | 0 falhas, 0 sem medida |
| `hud_acoes` | 50/50 |
| `teste_relato_caixa` / `teste_nomes_relato` | 31/31 · 26/26 |
| `canario_privacidade` | 10/10 |
| arranque da cena principal | chega a «pronto», 0 erros de script |
| erros de script em todos os passos | 0 |
| ensaio local do `retoma-pc` (ensaio, cópia, ensaio) | 0 / 0 / 0 |

**A prova viva dá 95/95.** Cliente real pela Rede, servidor de mesa real com o motor VLAB real (`a91c021c…`), semente
7, janela 1028×720, manequim `andar-v3.glb` com o SHA conferido e nenhuma cápsula à vista.
- As **78** verificações da prova do padrão-busto saem iguais e pela mesma ordem (comparei as listas `ok` com `diff`:
  só há acrescentos).
- **+4** da privacidade no momento 2 (B7).
- **+4** dos retratos contra a malha esfolada pelo motor (B5).
- **+9** casos: B1 ×3, B2 ×2, B4 ×3 e B5 ×1.

Capturas e retratos em `provas/ordem-caixa-padrao-correcoes/cliente/`; o README tem os SHA. Vi as 5 capturas e os
6 retratos dos casos. Os quadradinhos medem 46×60 px em todos os momentos.

**CI da ponta `802f87e`, já na linha** (corrida Testes 45080058208): **os 10 jobs estão verdes**, incluindo o `cliente`
(onde estava a falha da B9) e o `retoma-pc`. No Linux do CI os números são os mesmos de cá: `rodar_testes` 311/311
(nos jobs `cliente` e `godot-cliente`) e `caixa_jogadora` 36/36. A sonda de privacidade (45080058125) também está verde.

**Listas da retoma:** corri o `actualizar-listas.py` depois do commit 1. Deu 1 ficheiro novo no manifesto (o
`casos_retrato.gd`), 0 tirados. O `depois.txt` e o `MANIFESTO-SHA256.txt` vão sincronizados no commit 2.

## 3. Privacidade: o conferidor estrito nos dois critérios

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-caixa-padrao-correcoes/README.md` | **0 / 0** | 0 |
| `rascunhos/cliente/testes/casos_retrato.gd` (novo) | **0 / 0** | 0 |
| `tecto/corrida-tecto.log`, `tecto/sensibilidade.log` | **0 / 0** | 0 |
| as linhas que acrescentei a `hud/` e aos testes (só o `+` do diff) | **0 / 0** | 0 |
| as linhas novas da ferramenta da prova, contra a do padrão-busto | **0 / 0** | 0 |
| a ferramenta da prova, inteira | 53 / 53 | 0 |
| o lançador da prova | 2 / 2 | 0 |
| `cliente/relato.txt` | 67 / 67 | **0** |
| (precedentes na linha: prova do manequim · `rodar_testes.gd` · `teste_nomes_relato.gd`) | 63/61 · 121/109 · 151/150 | — |

Os achados que sobram **não vêm do meu texto**. A ferramenta e o lançador têm de nomear os ficheiros da casa (o
servidor, o cenário, a IA e os lugares, todos com essa palavra no caminho) e levam o texto herdado da prova do
padrão-busto. O relato imprime os nomes **públicos** das figuras, que é o que a caixa mostra à jogadora, e as
palavras correntes de sempre. Os nomes públicos partilham pedaços com os verdadeiros. Não há nenhum nome verdadeiro
inteiro, nenhum PIN, e nada de vida, alma, PA ou dados do Mestre.

## 4. Pontos para o coordenador

1. **Há artefactos na linha que já lá estavam e que eu não toquei:**
   - **nomes verdadeiros inteiros** nos `relato.txt` de cinco provas da caixa: teste-estetica 6, padrão-busto 6,
     manequim 6, hud-jogadora 6, janela 22;
   - **o valor do PIN antigo das provas** em 6 ficheiros: no `servidor-info.json`, no `servidor.log` e na ferramenta
     das provas do padrão-busto e do teste estético.

   Vêm das funções que liam o nome da vista do Mestre e do lançador que copiava o info. Na prova nova isto já está
   corrigido (B8). Apagar ou redigir provas de outras ordens é decisão tua, e mesmo assim os ficheiros ficam no
   histórico.
2. **A barreira «0 achados» não se pode cumprir, tal como está escrita, para a ferramenta da prova e para o relato**
   (§3): eles têm de nomear os ficheiros da casa e de mostrar os nomes públicos. Cumpri-a em tudo o que é só texto meu.
   Para chegar a 0 nestes também, era preciso uma ordem que mude os caminhos da casa ou que faça o relato usar ids em
   vez de nomes públicos.
3. **B9: a recentragem existe, mas não a apliquei.** Seria pôr a faixa o mais perto do centro do ecrã que o espaço
   livre deixa, sem encolher a caixa. Calculado, os desvios passariam a 407,0 / 535,0 / 30,5 u. Mas isso muda o
   desenho da faixa da CAIXA-JANELA B3 («centrada entre a ⚙ e a caixa»), que está à espera do olho do Mestre (o
   EXPANDE), e mexe no `hud.gd`, fora da caixa. Por isso actualizei os tectos. Se o Mestre a quiser, é uma ordem
   à parte, e os tectos baixam com ela.
4. **B3: 7 ou 10 letras.** Medido: nos nomes compridos ficam 6 a 7 letras à vista. Para chegar às 10 é preciso subir
   `LADO_RETRATO_EM_LETRAS`, e isso alarga todas as células juntas. A decisão é do Mestre.
5. **A regra do «de pé» pelo tronco e a do corpo sem armas rígidas valem também para o ecrã do Mestre**, porque usa o
   mesmo `retratos.gd`. Com as cápsulas de hoje nada muda: a caixa e o tronco são o mesmo.
6. **B4:** para testar com um quadrúpede real, com um modelo de ficheiro, é preciso um modelo. O feito em código passa
   pelo mesmo caminho da esfola, com bone_aabbs, skin e esqueleto.

<b>Estado: NOVA</b>
