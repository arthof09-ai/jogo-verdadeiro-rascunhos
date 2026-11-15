# Ordem 54: linha juntada (entra a Ordem 52) e a arena do Mestre abre depressa outra vez. ESTADO FINAL

*Fecho da ordem, 2026-11-15, Claude conta 2 (Opus 5.5), uma só sessão. PCDANASA, Godot 4.7.2 (Compatibility), Node 26
local. Trabalhei no clone `C:\Users\txcga\fable-mapa\repo`, na própria `fable/integracao-50`, sem branch nova. A ponta
de partida era `3c908ec` (Ordens 48 + 49 + 51). As duas partes estão feitas, commitadas e empurradas. Tudo o que
aparece como «provado» abaixo corri-o eu nesta máquina. Os registos estão em `C:\Users\txcga\fable-mapa\_tmp\o54\`,
fora do repositório. Não toquei em `main` (`2383737`), na worktree `fable-servidor-wt`, no ramo
`fable/mestre-perfil-52` nem em `.github`.*

## O que mudou (commits)

| commit | o quê |
|---|---|
| `37ee86c` | **Parte A.** Funde `fable/mestre-perfil-52` (Ordem 52, ponta `27e9769`) em `fable/integracao-50`. 2 conflitos, ambos em listas geradas, refeitos pelo gerador. |
| `c7eb07d` | **Parte B, a correcção.** O mapa da mesma zona constrói-se uma vez: o molde (`mapa/floresta/molde_floresta.gd`). O pacote do terreno do servidor foi refeito pela ferramenta, porque muda o SHA de uma fonte; o terreno é o mesmo. |
| `7589263` | **Parte B, as provas.** `pecas_mestre` +10, `abrir_mestre` +1 e a ferramenta com render `provar_molde_54.gd`. |
| *(este)* | Este ESTADO FINAL. |
| *(o seguinte)* | Listas da retoma e MANIFESTO refeitos (este documento está dentro de `rascunhos/`). |

## Parte A: a fusão da Ordem 52 (`37ee86c`)

A Ordem 52 parte de `8cd941d`, a mesma base das Ordens 48, 49 e 51. Usei `--no-ff`, com um commit de fusão nomeado.

**O código entrou sem conflito.** Cinco ficheiros de código foram mexidos pelos dois lados e o git juntou-os
sozinho. Conferi cada um à mão, e cada um soma os dois lados:
- `campo_da_mesa.gd`: o `ponto_no_chao` da 51 e o `ligar_perfil` / `perfil_no_mapa` / `densidade_do_perfil` da 52;
- `arena.gd`: o `remove_child` da 49 e a ligação do perfil da 52;
- `mestre.gd`: o tecto da vista da 49 e a linha «Gráficos» da 52;
- `textos_mestre.gd`;
- `rodar_testes.gd`: o teste da 48 e a lista dos perfis, que passou para `escolha_perfil.gd`.

**Houve 2 conflitos, os dois em listas geradas.** Foram `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt`.
Resolvi-os com a receita das Ordens 50 e 53, sem escolher lado:
1. fiz um commit solto com a árvore fundida (`05d48ad`, fora de qualquer ramo, nunca empurrado);
2. corri sobre ele uma cópia do gerador (`_tmp/o54/listas_tmp.py`).

O resultado: MANIFESTO com **338** ficheiros, `depois.txt` com **289**, `antes.txt` com 32, sem mudança. O
`actualizar-listas.py` verdadeiro, corrido sobre `37ee86c`, dá **0 novos e 0 tirados**.

**As quatro presenças estão juntas e provadas na linha fundida** (`37ee86c`, antes da Parte B):

| presença | prova | resultado |
|---|---|---|
| (48) grelhas quaisquer até 50 × 50, julgadas pelo servidor real | `provar_terreno_servidor.gd -- --json=` | TUDO PASSOU; o JSON é **igual byte a byte** ao blob `provas/ordem-48-terreno/medicao-terreno-qualquer-grelha.json` |
| (49) o tecto de tentativas da MASTER_VIEW e o nó «Linhas» da arena da jogadora | `abrir_mestre` (bloco «o pedido da vista tem tecto», 9 verificações) e `hud_acoes` (bloco «ordem 49», 10 verificações) | 66/66 e 42/42 |
| (51) toque rasante 30 × 30 e 20 × 20 400/400 | `medir_toque_rasante.gd -- --json=` | SEM FALHAS; o JSON é **igual byte a byte** a `provas/ordem-51-toque/depois.json`: 30 × 30 rasante 895/895 nas duas arenas, 20 × 20 rasante 400/400 |
| (52) o perfil gráfico no ecrã do Mestre, com as contagens medidas | `medir_perfil_mestre_52.gd -- --json=` e `pecas_mestre` | o JSON é **igual chave a chave** ao `medir-depois.json` da Ordem 52 (Mestre sem escolha 1,00 · 33456 tufos; «Baixo» 0,50 · 16741, chuva forte 2800/0); `pecas_mestre` dá **255/255**, o que inclui as 19 do perfil |

**Suites da linha fundida** (`37ee86c`):
- servidor: 345 passam, 0 falham, 10 saltados (local com `--allow-net`), e 355/355 como o job `protocolo`;
- `conferir-schemas` exit 0 sobre 16 868 mensagens; `validador-glb` 31/0; TERRENO EM DIA;
- `abrir_scripts` 71 (os 69 da 53 mais os 2 da 52); `rodar_testes` 177/177; `abrir_clareira` 22/22;
  `abrir_mestre` 66/66; `pecas_mestre` 255/255; `hud_acoes` 42/42; `canario_privacidade` 10/10; `clima_forte` 119/119;
- `medir_mestre` e `medir_painel_config` com 0 falhas; arranque «pronto»;
- `provar_mestre_no_relevo` e `provar_assentamento` dão TUDO PASSOU;
- ponta a ponta: 2 corridas, 17/17 nas duas, a jogadora OK com 23 mensagens;
- nenhum SCRIPT ERROR.

Empurrei sem força (`3c908ec..37ee86c`). O CI dessa ponta, run **43719851682**, deu `success` nos 9 jobs:
`servidor`, `validador-glb`, `motor-real`, `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `retoma-pc` e
`foto-mestre`. A «Sonda de privacidade», run 43719851675, também deu `success`.

## Parte B: a arena do Mestre abre depressa outra vez

### Onde ia o tempo (medido antes de mexer)

1. **O `abrir_mestre` abre o ecrã do Mestre 5 vezes**, nos blocos c, c2, c3 e c4, mais a recusa, que não monta a
   arena. **Cada uma das 4 aberturas construía o mapa da floresta inteiro de raiz**, pelo módulo partilhado
   (`campo_da_mesa.montar_mapa`), sempre para a mesma zona (20 × 20 de 1,5 m).
   - Os números da construção, lidos de `[floresta] pronta em`: **1,5 s na primeira e ~2,9–3,0 s em cada uma
     das seguintes**.
   - Somam ~10,4 s dos ~15,2 s de cada corrida.
2. **Por fases** (instrumentação provisória no `_ready`, que não entrou em nenhum commit), na 1.ª construção:
   - relva 385 ms; árvores 373 ms; o mapa do chão 223 ms; Árvore Ancestral 182 ms; anel 143 ms; o resto <80 ms cada.
   - Nas construções seguintes, as fases que fazem malhas (árvores, relva, anel, Ancestral) **duplicam**. As de
     puro cálculo (o mapa do chão) não.
   - O mesmo acontece com o mapa sozinho, fora do ecrã do Mestre (1,7 → 2,5 → 3,1 → 3,1 s), sem objectos a vazar.
     É do motor e não o persegui: a correcção deixa de construir, por isso deixa de pagar isto também.
3. **A causa**: o mesmo mapa, determinístico, construído outra vez a cada abertura. A construção só depende da
   semente, da zona jogável, da relva no campo e da densidade.

### A correcção: o molde do mapa (`c7eb07d`)

`mapa/floresta/molde_floresta.gd` (novo) faz duas coisas:
- **Guarda.** No fim da **primeira** construção de uma chave (semente, zona, relva no campo, densidade), ainda
  dentro do `_ready`, ou seja, antes de o perfil, o clima, o recorte ou a ocupação da grelha mexerem no mapa,
  guarda um **molde intacto** do mapa acabado:
  - os nós (a Arena e o Fundo), num `PackedScene`;
  - o estado dos scripts (o mapa e a relva), copiado.
- **Veste.** Os mapas seguintes com a mesma chave **vestem-se de uma cópia** do molde em vez de se construírem.
  - **Partilha-se** só o que ninguém muda depois de construído: as malhas, as texturas, as formas de colisão e os
    shaders.
  - **Copia-se para cada mapa** o que muda:
    - os materiais (o recorte, a densidade, a neve e a água escrevem neles);
    - as MultiMesh (o LOD da relva), pelo buffer;
    - a grelha (a ocupação), os lotes e o gerador de acaso;
    - todos os contentores do estado.
  - Mantém-se a partilha que a construção faz: os 50 blocos de relva continuam com um só material, que é deles.
  - O molde nunca é entregue a ninguém e nunca muda. Cada mapa nasce como se tivesse sido construído agora.
- Cabem até 3 chaves (zonas); a mais antiga sai primeiro.
- Uma construção que registe erros (`Erros`) não guarda molde: o mapa seguinte constrói-se outra vez e regista-os.
- Os nós com nome automático (`@CollisionShape3D@N`) voltam a nascer sem nome. O `PackedScene` trocava-lhes o «@».

A ligação ficou em três sítios:
- `campo_floresta.gd`: `@export var reutilizar_molde := false`. O `_ready` veste-se do molde ou constrói e guarda-o.
  O céu, a névoa e a luz montam-se sempre no Ambiente, no Sol e na Câmara do dono, e o fim da carga é o mesmo
  código nos dois caminhos.
- `campo_da_mesa.montar_mapa` liga-o. Valem as **duas** arenas, pelo módulo partilhado.
- O mapa sozinho (`campo_floresta.tscn`: filmes e medições) fica desligado e constrói sempre.

**O pacote do terreno do servidor.** `servidor/dados/terreno-floresta.json` guarda o SHA das fontes do cliente, e
`campo_floresta.gd` é uma delas. Por isso refiz o pacote com `exportar_terreno.gd`.
- O `--conferir` antes de refazer disse que só a fonte tinha mudado.
- A comparação estrutural do pacote velho com o novo dá **uma só diferença**:
  `cabecalho.fontes["mapa/floresta/campo_floresta.gd"]`.
- `conferir-terreno.mjs` dá TERRENO EM DIA.

### A prova de que nada do que se vê muda

- **`pecas_mestre`, +10 verificações** (corre no CI). O **retrato** de um mapa (`MoldeFloresta.retrato`) tem 136
  linhas e cobre:
  - cada nó: caminho, classe, transformação, visibilidade, grupos, sombra, margens;
  - malhas pelos dados, materiais com todos os parâmetros, MultiMesh;
  - o estado do mapa, da relva, da grelha e dos lotes;
  - o céu, a névoa e a luz montados no dono;
  - a partilha dos recursos. Fica de fora só `medidas.carga_ms`.

  As verificações:
  - o retrato do mapa vestido é **igual linha a linha** ao de um mapa construído de raiz com o molde desligado;
  - guardar o molde não muda o mapa que o guarda;
  - depois de mexer num mapa vivo como o jogo mexe (perfil 0,5, recorte, neve, camada do clima no chão, LOD,
    ocupação da grelha, medidas), o mapa seguinte continua igual. Mexer no mapa vestido também não chega ao molde;
  - os 92 objectos que mudam (materiais, MultiMesh, grelha, lotes, acaso) não são partilhados entre dois mapas
    vivos;
  - a verificação negativa, feita à parte: mudar uma cor da relva ou mexer uma copa 1 mm torna o retrato diferente.
- **Com GPU** (`cenas/mestre/ferramentas/provar_molde_54.gd`, com janela, NVIDIA RTX 4060). Abre o ecrã do Mestre
  três vezes, como a foto 1 do `foto_mestre`, com o relógio dos shaders parado (`Engine.time_scale = 0`, para o
  vento ficar no mesmo instante):

  | abertura | mapa |
  |---|---|
  | 1, sem molde | construído em 1565 ms |
  | 2, com o molde ligado | construído em 1496 ms, e o molde guardado |
  | 3 | **vestido em 52 ms** |

  - **As fotos 2 e 3 são iguais à foto 1 byte a byte**: 0 bytes diferentes de 8 294 400 (1920 × 1080).
  - Os três retratos são iguais.
  - Com GPU, os buffers das MultiMesh existem (57 140 números num só bloco de relva) e entram no retrato.
  - Sem janela, o servidor de render não os guarda, nem no mapa construído nem no vestido.
- **As medições das presenças, já com o molde.** Aqui as arenas vestem-se umas às outras: o jogador e o Mestre na
  mesma zona, e as grelhas repetidas.
  - os JSON da 48 e da 51 continuam **iguais byte a byte** aos blobs;
  - o JSON da 52 continua **igual chave a chave** ao `medir-depois.json`;
  - `provar_mestre_no_relevo` e `provar_assentamento` dão TUDO PASSOU.

### O cronómetro: `abrir_mestre`, antes e depois, na mesma harness

O processo Godot inteiro, sem janela (`godot --headless --path cliente -s res://testes/abrir_mestre.gd`), 3
corridas seguidas de cada lado, com a máquina sossegada (`_tmp/o54/cronometrar.sh`):

| | corrida 1 | corrida 2 | corrida 3 | média | o mapa em cada uma das 4 aberturas (ms) |
|---|---|---|---|---|---|
| **antes** (`37ee86c`, 66 verificações) | 15 180 ms | 15 163 ms | 15 133 ms | **15,16 s** | 1542 · 3058 · 2873 · 2934 / 1541 · 3019 · 2885 · 3004 / 1534 · 2968 · 2960 · 2952 |
| **depois** (`7589263`, 67 verificações) | 6 278 ms | 6 262 ms | 6 447 ms | **6,33 s** | 1542 · 41 · 7 · 8 / 1541 · 59 · 7 · 6 / 1578 · 68 · 7 · 8 |

- A abertura passa de ~15,2 s para **~6,3 s (−58 %)**.
- O mapa passa de ~10,4 s por corrida para ~1,6 s. O que resta é a única construção que importa, a da 1.ª
  abertura. As outras três vestem-se em 6–68 ms.
- Sem os mapas repetidos, a corrida fica em ~4,7 s mais essa construção. É a ordem de grandeza dos «~4 s» da
  conferência da Ordem 45, que foi medida noutra máquina. Não medi aqui uma árvore de antes da 45.
- Guardar o molde custa 0–40 ms à 1.ª construção (1542/1541/1578 contra 1542/1541/1534).
- O `abrir_mestre` ganhou a verificação que segura isto: «4 aberturas do ecrã do Mestre: 1 mapa construído, 3
  vestidos do molde».

## Provas do fecho (ponta da Parte B, `7589263`)

| suite | resultado |
|---|---|
| servidor (`--permission` + `--allow-net`) · protocolo | 345 / 0 / 10 saltados · 355/355 |
| `conferir-schemas` · `validador-glb` · `conferir-terreno` | exit 0 (16 868 mensagens) · 31/0 · TERRENO EM DIA |
| `abrir_scripts` | **73** scripts, 0 falhas (os 71 da linha mais `molde_floresta.gd` e `provar_molde_54.gd`) |
| `rodar_testes` | 177/177 (com o pacote do terreno refeito; antes de o refazer, o teste das fontes dava a falha certa) |
| `abrir_mestre` | **67/67** (66 + 1 da Ordem 54) |
| `pecas_mestre` | **265/265** (255 + 10 da Ordem 54) |
| `abrir_clareira` · `hud_acoes` · `canario_privacidade` · `clima_forte` | 22/22 · 42/42 · 10/10 · 119/119 |
| `medir_mestre` · `medir_painel_config` | 0 falhas, 0 sem medida |
| arranque `--quit-after 600` | «pronto», 0 erros |
| `provar_terreno_servidor` · `medir_toque_rasante` · `provar_mestre_no_relevo` · `provar_assentamento` | TUDO PASSOU · SEM FALHAS · TUDO PASSOU · TUDO PASSOU |
| `medir_perfil_mestre_52` | igual chave a chave ao da Ordem 52 |
| `provar_molde_54` (com janela) | molde: 0 falhas; fotos iguais byte a byte |
| ponta a ponta (motor falso, local) | 2 corridas, 17/17 nas duas; jogadora OK, 23 mensagens |

Nenhuma suite teve SCRIPT ERROR, Parse Error ou Compile Error, e nenhuma deu aviso de objectos vivos à saída.

CI: ver a secção «CI» no fim.

## Resíduos nomeados

1. **A 1.ª abertura de cada zona continua a construir o mapa (~1,5 s).** O molde só poupa as construções
   repetidas. Não adiei nada da 1.ª construção, porque tudo o que ela faz se vê logo: o céu, a Ancestral no
   horizonte, a relva. O ecrã do Mestre num jogo de verdade abre uma vez por sessão, e essa abertura custa o mesmo
   que antes. Ganham as reaberturas, as voltas a uma grelha já vista e a arena do jogador na mesma zona.
2. **Memória.** O molde de cada zona fica vivo a sessão inteira, no máximo 3 zonas. Guarda:
   - as malhas, partilhadas com o mapa vivo e por isso sem cópia;
   - uma cópia de cada material do mapa;
   - os dados das MultiMesh na memória do processo (com GPU, a relva inteira são ~45 mil instâncias);
   - o estado: o mapa do chão de 512 × 512 × 4 números (4 MB) e a grelha.

   As MultiMesh do molde ficam sem instâncias e não ocupam a placa.
3. **A prova com GPU não corre no CI.** O `pecas_mestre` corre sem janela, onde as MultiMesh não guardam os
   buffers. A prova com GPU (`provar_molde_54.gd`) corri-a eu, com janela. O job `foto-mestre` do CI corre com
   render, mas não lhe juntei esta ferramenta, para não mexer em `.github`.
4. **Por que é que as construções seguintes do mapa custam o dobro** (do motor, nas fases que fazem malhas): ficou
   medido, mas não investigado. Com o molde deixou de acontecer nas arenas. Um mapa de outra zona, ou o mapa
   sozinho, ainda o paga.
5. **Quem mudar a construção do mapa** e criar um recurso que se muda depois de construído, de um tipo que o molde
   não copia (o molde copia materiais, MultiMesh, objectos com script e o gerador de acaso), fica com ele partilhado
   entre mapas. O retrato do `pecas_mestre` apanha um mapa vestido diferente do construído, mas não apanha uma
   partilha nova.
6. **O que as Ordens 48, 49, 51 e 52 deixaram em aberto continua em aberto.** Está nos ESTADOs delas. Da 52, por
   exemplo: a escolha «feita» é a chave no ficheiro, não há recuo do telemóvel para o Mestre e não há «voltar a sem
   escolha».
7. **Higiene.**
   - `rascunhos/servidor/dados-exemplo/mesa-mestre.json` continua modificado pelo artefacto CRLF antigo. Não o
     commitei nem o «corrigi».
   - Os `.uid` dos 2 scripts novos não entram, por causa do `*.uid` no `.git/info/exclude`. É a regra local de
     sempre.
   - A instrumentação das fases foi revertida antes de qualquer commit.
   - Não há `_tmp`, `.avi` nem referências nos commits.
8. **Node 26 local**: o servidor corre com `--allow-net` a mais, como nas Ordens 50 e 53. O CI usa o Node 24.

## Nota de retoma

Não há nada a meio. A linha única das Ordens 48, 49, 51 e 52, com a abertura rápida da Ordem 54, é
`fable/integracao-50`. Quem pegar daqui parte da ponta deste ramo, que já tem as listas em dia.
- Para lhe juntar outro ramo, as listas refazem-se no fim (`python3 retoma-i0004/actualizar-listas.py` na raiz). Se
  houver conflito nelas, a resolução é a das Ordens 50, 53 e 54: refazer pelo gerador sobre a árvore fundida.
- **Quem mexer em `campo_floresta.gd`** (ou noutra fonte do terreno) refaz o pacote com `exportar_terreno.gd`. O
  `rodar_testes` avisa se ficar esquecido.

## CI

Confirmado pela API do GitHub (`gh api …/actions/runs/<id>/jobs`). Os pushes foram normais, sem força. `origin/main`
ficou em `2383737`.

- **Parte A, ponta `37ee86c`:** «Testes dos rascunhos», run **43719851682**, `success` nos 9 jobs. «Sonda de
  privacidade», run 43719851675, `success`.
- **Parte B:** o push leva `c7eb07d`, `7589263`, este documento e as listas. O run dessa ponta vai no relatório do
  fecho; não o escrevi aqui para não precisar de mais um commit só por isso.
