# Ordem 49: correcções do servidor e dos testes (código e testes; nada visual). ESTADO FINAL

*Fecho da ordem, 2026-11-15, conta 1, Opus 5.5, sessão única. Havia um só `ordem49-c1-out.txt`. O
`ordem48-c2-out.txt` do mesmo minuto é de outra ordem, noutro clone (`fable-mapa\repo`, ramo
`fable/servidor-grelhas-48`), e nada mudou neste worktree enquanto eu só lia. PCDANASA, Godot 4.7.2 (Compatibility),
Node local. Worktree `C:\Users\txcga\fable-servidor-wt`, ramo `fable/servidor-correcoes-49`, tirado de `8cd941d`
(ponta da Ordem 45). As três partes estão feitas, commitadas e empurradas. Tudo o que está «provado» abaixo foi
corrido por mim nesta máquina. Os registos estão em `C:\Users\txcga\fable-mapa\_tmp\o49\`.*

## O que mudou (commits)

| commit | o quê |
|---|---|
| `d3e623f` | **Parte A.** `cenas/mestre/mestre.gd`: tecto para a nova tentativa do pedido da `MASTER_VIEW`, com a falha nomeada. `textos_mestre.gd`: o texto do alerta. `testes/abrir_mestre.gd`: +9. |
| `e840f50` | **Parte B.** M5: `servidor/e2e/jogadora-e2e.mjs` passa os canários em todas as fases. `servidor/e2e/servidor-e2e.mjs`: a fuga plantada `E2E_FUGA`, só para a prova. M7: `protocolo/ferramentas/conferir-schemas.py` falha com o tráfego vazio. |
| `78af67e` | **Parte C.** `cenas/arena/arena.gd`: `remove_child` antes do `queue_free`, a mesma correcção que o Mestre recebeu. `testes/hud_acoes.gd`: +10, o teste de regressão. |
| `82250a7` | Listas da retoma e MANIFESTO refeitos (A–C). |
| *(este)* | Este ESTADO FINAL e as listas outra vez (o documento está dentro de `rascunhos/`). |

## Parte A: tecto para a nova tentativa da MASTER_VIEW (achado leve da Ordem 35)

**O defeito.** Desde a Ordem 35, um pedido da vista que não sai (o limite de 10 envios/s do aparelho, ou fora da
mesa) volta a ser feito 0,25 s depois, até sair. Não havia fim. Com o pedido sempre a falhar, pedia para sempre.

**A correcção** (`mestre.gd`):

- **Tecto:** `TENTATIVAS_VISTA_MAX = 40` pedidos seguidos que não saem, ao passo de `ESPERA_VISTA_S` (0,25 s),
  ou seja 10 s. A janela do limite é de 1 s, por isso o caso da Ordem 35 cabe com muita folga. O ponta a ponta
  sai à volta de 1,1 s.
- **Ao fim do tecto, uma falha com nome:**
  - pára, sem nenhum pedido à espera;
  - `falha_vista = "vista_sem_pedido"`, que os testes lêem;
  - um alerta ao Mestre, uma só vez por episódio: «A vista da mesa não se pediu (40 tentativas). Toque em
    «Atualizar».»;
  - um `push_warning("MASTER_VIEW: vista_sem_pedido — o pedido não saiu 40 vezes seguidas (10 s); parei")` no
    registo do Godot.
- **O que recomeça a conta:** só o abrir, o «Atualizar» e a ligação que volta à mesa (`_ao_ligacao`). Um evento
  ou recibo arma o pedido mas não recomeça a conta. Se recomeçasse, um fluxo de eventos com o pedido sempre a
  falhar voltava a ser um ciclo sem fim. Depois do tecto, cada evento dá-lhe uma tentativa, sem alerta novo.
- **Um pedido que sai** limpa a conta e a falha.

**Prova** (`abrir_mestre.gd`, +9 verificações). O relógio anda à mão: `_process` é chamado no teste, com o do
quadro desligado.

| caso | antes (HEAD + teste novo) | depois |
|---|---|---|
| falha permanente, 50 s de relógio | 201 pedidos, nenhuma falha nomeada, um pedido sempre à espera | 40 pedidos, para, `vista_sem_pedido`, 1 alerta |
| um evento depois do tecto | 20 pedidos | 1 pedido, nenhum alerta novo |
| «Atualizar» depois do tecto | 201 | 40 outra vez, mais 1 alerta |
| sai na 40.ª tentativa (o caminho bom, a meio) | — | chega, sem falha, sem alerta |
| sai à 1.ª | — | 1 pedido, sem falha |
| **total** | **57/66** | **66/66** |

As duas linhas do caminho bom contam como falha no «antes» só porque a propriedade `falha_vista` ainda não
existia. O caminho bom da Ordem 35 (sair à 3.ª, ao abrir e depois de um evento) continua nas verificações de
antes, iguais. No ponta a ponta, a verificação «o pedido da vista esperou pela janela e voltou a ser feito» passa
em todas as 11 corridas desta ordem (17/17).

## Parte B: os testes da Ordem 36 (M5 e M7)

### M5: a jogadora de ponta a ponta passa todas as fases pelos canários

**O defeito.** `jogadora-e2e.mjs` fazia `process.exit(0)` ao ver o evento `revertido`. O snapshot do «voltar», o
«Terminar» (evento `fim`) e o «Recomeçar» (evento `recomeco` e o snapshot novo) nunca passavam pelos canários.

**A correcção:**

- Cada mensagem passa pelos canários ao chegar. A falha diz a fase e o tipo, por exemplo «fase voltar,
  ROOM_SNAPSHOT».
- No fim, tudo junto passa outra vez, como rede de trás.
- A jogadora segue o guião do Mestre até ao fim: revertido + snapshot, fim, recomeco + snapshot. Depois espera
  0,5 s pelas mensagens que faltam da mesma transacção.
- Só sai com 0 se as quatro fases (jogo, voltar, fim, recomeço) tiverem mensagens conferidas.
- Os 5 canários ficam os mesmos.

**A fuga plantada** (`servidor-e2e.mjs`). Com `E2E_FUGA=voltar|fim|recomeco`, a primeira mensagem dessa fase que
vai a um lugar que não é o do Mestre leva `fugaPlantada: "Orc Verdadeiro"`: o snapshot do voltar, o evento fim, o
snapshot do recomeço. O servidor regista «FUGA PLANTADA na fase …». Sem a variável, a sala é a de sempre. O CI
não a usa, e os workflows não foram tocados.

**Prova** (servidor Node real, Mestre Godot, motor falso):

| fuga plantada | jogadora antes (a do HEAD) | jogadora depois |
|---|---|---|
| nenhuma | OK, 14 mensagens | OK, **23 mensagens** (jogo 13, voltar 4, fim 1, recomeço 5) |
| `voltar` (ROOM_SNAPSHOT) | **OK**: a fuga passou | FALHA «fase voltar, ROOM_SNAPSHOT: Orc Verdadeiro», exit 1 |
| `fim` (ROOM_EVENT fim) | **OK**: a fuga passou | FALHA «fase fim, ROOM_EVENT fim: Orc Verdadeiro», exit 1 |
| `recomeco` (ROOM_SNAPSHOT) | **OK**: a fuga passou | FALHA «fase recomeço, ROOM_SNAPSHOT: Orc Verdadeiro», exit 1 |

Em todas estas corridas, o Mestre deu 17/17.

### M7: o tráfego vazio é falha

**O defeito.** `conferir-schemas.py` imprimia os esquemas não vistos e saía com 0 quando o tráfego vinha vazio.

**A correcção.** Sem nenhuma mensagem que SAIA do servidor (as únicas que fazem falhar), o script escreve
`FALHA TRAFEGO-VAZIO: N mensagens no tráfego, 0 que saem do servidor, em <ficheiro> (<porquê>)` e sai com 1. As
linhas em branco saltam-se.

**Prova** (o script do HEAD corrido da mesma pasta, contra o de agora):

| tráfego | antes | depois |
|---|---|---|
| ficheiro vazio | **exit 0** | exit 1, TRAFEGO-VAZIO |
| só entradas (50 linhas `entra`) | **exit 0** | exit 1, TRAFEGO-VAZIO («só entradas») |
| só linhas em branco | exit 1 com traceback (`JSONDecodeError`) | exit 1, TRAFEGO-VAZIO |
| o tráfego real dos 348 testes (16 688 mensagens) | exit 0 | exit 0, saída igual byte a byte |

## Parte C: as «Linhas» da arena do jogador (reserva 9 da Ordem 45)

**O defeito.** Em `arena.gd` (`_construir_grelha`), os filhos velhos da Grelha só saíam pela fila de libertação.
Os novos nasciam com outro nome («@MeshInstance3D@…»): `Grelha/Linhas` dava o nó velho até ao fim do quadro e
depois não dava nada. Acontecia também ao Fogo, aos Destaques, ao Cursor e ao `AbrigosDoMapa` do clima.

**A correcção.** A mesma que o ecrã do Mestre recebeu na Ordem 45 (`arena_mestre.gd`): `_grelha.remove_child(n)`
antes do `queue_free()`. São três linhas.

**O teste de regressão** (`hud_acoes.gd`, +10). Usa a arena verdadeira do jogador, e um snapshot com outro tamanho
(24 × 22) refaz a grelha pelo caminho de verdade (`_ao_snapshot`). O teste confere que:

- no mesmo quadro, `Grelha/Linhas` já é o nó novo;
- depois da fila de libertação, `Grelha/Linhas` continua lá e é o mesmo nó;
- os nomes da Grelha são os de antes (`AbrigosDoMapa`, `Cursor`, `Destaques`, `Fogo`, `Linhas`), sem nenhum nome
  inventado a mais;
- `Fogo`, `Destaques` e `Cursor` são as camadas que a arena usa;
- há uma só malha de linhas, e as linhas cobrem a grelha nova: (−18, −16,5)–(18, 16,5).

**Antes** (o `arena.gd` do HEAD): **35/42**. Falhavam 7: o nó velho no mesmo quadro, nada depois da fila, os
nomes perdidos (1 → 6 nomes inventados) e as três camadas. **Depois: 42/42.**

**A jogadora fora disto não muda.** Comparei com os registos do fecho da Ordem 45, linha a linha, sem os tempos de
carga. `provar_assentamento`, `provar_terreno_servidor`, `rodar_testes` (176), `clima_forte` (119),
`abrir_clareira` (22), `canario_privacidade` (10) e `exportar_terreno --conferir` dão as mesmas linhas. As 32
verificações de antes do `hud_acoes` também são as mesmas: só mudam os UUID aleatórios dos `intentId`.
`arena.gd` não é fonte do terreno do servidor (`exportar_terreno.gd`, `FONTES`): o pacote continua EM DIA.

## Provas corridas no fecho (ponta `82250a7`)

**Cliente, sem janela (Godot 4.7.2):**

| suite | resultado |
|---|---|
| `abrir_scripts` | 67 scripts, 0 falhas |
| `rodar_testes` | 176/176 (igual) |
| `clima_forte` | 119/119 (igual) |
| `pecas_mestre` | 236/236 (igual) |
| `hud_acoes` | **42/42** (32 antes, +10 da Parte C) |
| `abrir_clareira` | 22/22 (igual) |
| `abrir_mestre` | **66/66** (57 antes, +9 da Parte A) |
| `canario_privacidade` | 10/10 (igual) |
| `medir_mestre`, `medir_painel_config` | saída 0 |
| `provar_assentamento`, `provar_terreno_servidor`, `provar_mestre_no_relevo` | TUDO PASSOU |
| `exportar_terreno --conferir` | EM DIA |
| arranque `--quit-after 600` | «pronto», 0 erros |

Nenhuma suite teve SCRIPT ERROR.

**Servidor:** 348 testes, 348 passam. `conferir-schemas.py` sobre o tráfego deles: exit 0.

**Ponta a ponta** (servidor Node real, jogadora Node, Mestre Godot, motor falso, como o CI): **17/17** em 3
corridas seguidas no fecho, mais as corridas das provas. A jogadora deu OK em todas, com 23 mensagens e as quatro
fases conferidas.

**CI:** run 43700437582 verde nos 9 jobs (ver «CI do ramo», no fim).

## O que ficou de fora (como a ordem mandou)

- **O contrato dos alertas** (achados M1/L1 da Ordem 36): espera a palavra do Mestre. O alerta novo da Parte A é
  um alerta local do ecrã do Mestre (`_juntar_alerta`), como o «A ligação caiu». Não passa pelo `MASTER_ALERTAS`
  nem pelo contrato.
- **Os pontos de workflow** (M3, M4, L6–L9 e a parte de workflow do M6): esperam autorização. Não toquei em
  `.github`. A fuga plantada da Parte B não entra no CI, porque isso pedia mexer no workflow.

## Resíduos honestos

1. **O alerta da Parte A é texto novo no ecrã.** A ordem diz «nada visual». Para não ser silêncio, a falha nomeada
   vai pelo canal de alertas que já existe: uma linha de texto, sem nada desenhado de novo. Se o Mestre a quiser só
   no registo, basta tirar a chamada a `_juntar_alerta` (1 linha).
2. **Fora da mesa também conta para o tecto.** A cena não distingue o limite de envios de estar fora da mesa: a
   `Rede` devolve `false` nos dois casos. Com a ligação caída mais de 10 s, o Mestre vê «A ligação caiu» e, 10 s
   depois, o alerta da vista. Quando a ligação volta, a conta recomeça e o pedido sai.
3. **Os 5 canários da jogadora são os mesmos.** A ordem pedia as fases, não mais canários. O
   `servidor/testes/privacidade.test.mjs` tem listas maiores (o PIN, os `fichaId`, a semente…); alargar a lista do
   ponta a ponta fica para quando se pedir.
4. **`E2E_FUGA` vive no `servidor-e2e.mjs`.** É um botão de injecção só para provas. Está à vista no código e não
   tem efeito sem a variável. Pô-lo no CI é um ponto de workflow, por isso não o fiz.
5. **O rótulo do custo da arena (`Label3D`) nunca teve nome.** Fica «@Label3D@…» desde a primeira construção, nos
   dois lados. Não é o defeito da Parte C e não lhe mexi. O teste aceita-o: conta os nomes inventados antes e
   depois, 1 → 1.
6. **Antes, o `AbrigosDoMapa` também perdia o nome ao refazer.** Só a ferramenta `clima_no_mapa.gd` o procura
   pelo nome, e só na primeira grelha, por isso nenhuma prova dava por isso. Com a Parte C fica certo.
7. **A fixture `servidor/dados-exemplo/mesa-mestre.json` neste worktree.** O checkout novo com `autocrlf=true`
   pô-la em CRLF, e o `fixture-mestre.test.mjs`, que compara byte a byte, falhou: 347/348. Não foi código meu. É o
   mesmo resíduo dos fins de linha da Ordem 44. Pus a cópia local em LF, sem diferença no índice, e deu 348/348.
   Não a commitei.
8. **Higiene.** Os rascunhos dos remendos e os registos estão em `C:\Users\txcga\fable-mapa\_tmp\o49\`. Nos
   commits não há `referencias-arvore-ancestral/`, `.avi` nem `_tmp`: conferi o `git diff --cached` de cada um.
   Não toquei em `main`, nos outros ramos nem em `.github`. Os pushes foram normais, sem força.

## CI do ramo

- Ponta `82250a7` (as três partes e as listas): «Testes dos rascunhos», run 43700437582, **verde nos 9 jobs**
  (`servidor`, `validador-glb`, `motor-real`, `protocolo`, que corre o `conferir-schemas.py` novo sobre o tráfego
  dos testes, `cliente`, `godot-cliente`, `ponta-a-ponta` com o motor falso e o VLAB real e a jogadora nova,
  `retoma-pc` e `foto-mestre`). «Sonda de privacidade», run 43700437580: verde.
- O commit deste documento e o das listas a seguir só mexem neste `.md` e nas listas. O CI deles corre de novo,
  mas não o fui ver antes de fechar este texto.

## Nota de retoma

Não há nada a meio. Se outra ordem pegar daqui: o ramo `fable/servidor-correcoes-49` está empurrado e a ponta tem
as listas da retoma em dia. Para juntar a outro ramo, refazer as listas depois (`python3
retoma-i0004/actualizar-listas.py` na raiz).
