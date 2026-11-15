# Ordem 60: a recusa tem de se ver no ecrã. ESTADO FINAL

*Fecho da ordem, 2026-11-15. Foram duas sessões da mesma missão. A conta 1 (Opus 5.5) escreveu e fez commit da
medição de antes (`f07b37d`) e morreu no limite das 5 horas, às 12:37, sem relatório. A conta 2 (Opus 5.5, a
sucessão) continuou desse ponto: fez a correcção, as provas, este ESTADO e a integração. Usei Godot 4.7.2 e Node
nesta máquina. Trabalhei na worktree `C:\Users\txcga\fable-servidor-wt`, no ramo `fable/recusa-60`, que nasceu da
ponta de `fable/pes-58` (`ae1e574`, a Ordem 58 fechada). Tudo o que aparece como «provado» abaixo foi corrido por uma
das duas sessões. Os registos brutos estão em `C:\Users\txcga\fable-mapa\_tmp\o60\`, fora do repositório; os que
contam estão em `provas/ordem-60-recusa/`. Não toquei na árvore do clone `fable-mapa\repo`, nas worktrees
`fable-mapa-wt-b`, `-grama` e `-agua`, no clone `fable-ciclo`, em `main` (`2383737`) nem em `.github`. A
`mesa-mestre.json` não entrou em nenhum commit.*

## O que mudou (commits)

| commit | o quê |
|---|---|
| `f07b37d` | **A medição de antes** (conta 1). É a prova nova `cenas/mestre/ferramentas/provar_recusa_no_ecra.gd`, sozinha, antes da correcção. Neste commit sai com 14 falhas: são os números de antes. |
| `5d225b8` | **A correcção** (conta 2). Está no caminho partilhado das duas arenas, `campo_da_mesa.gd`, e as duas arenas, o HUD e o ecrã do Mestre ligam-se a ele. |
| `2a77367` | As guardas do CI: `pecas_mestre` ganha 4 verificações e `hud_acoes` ganha 4. |
| *(este)* | As provas (`provas/ordem-60-recusa/`), este ESTADO, e as listas da retoma e o MANIFESTO refeitos. |
| *(a fusão)* | `fable/recusa-60` fundido em `fable/integracao-50` (secção 4). |

## 1. A medição de antes: a reserva reproduz-se

Este é o texto da reserva 1 da Ordem 58, tal como está em `ESTADO-FINAL-ORDEM-58.md`:

> **A figura recusada desaparece da arena 3D.** A jogadora também pode deixar de ver a sua própria figura no mapa.
> […] O aviso fica na consola, mas **no ecrã ninguém é avisado**: não há mensagem ao Mestre nem à jogadora.

A prova nova mede as duas arenas de verdade: `arena.tscn`, com o HUD, e `mestre.tscn`. Para cada figura numa casa
que o mapa bloqueia, pergunta ao servidor de verdade se a casa está bloqueada e mede três coisas:

- se a figura fica visível na arena 3D, na casa dela: uma malha que não é do mapa por cima da casa, e um rótulo 3D
  com o nome e o motivo;
- se a recusa aparece no ecrã onde a arena já mostra os seus avisos: o «Aviso» do HUD da jogadora, os alertas do
  Mestre e, no Mestre, a linha da figura na folha;
- se as colocações legais ficam como estavam: as posições, bit a bit, e as linhas da folha, comparadas com
  `--antes=json`.

No commit `f07b37d` a reserva reproduz-se, com 14 falhas (`provas/ordem-60-recusa/recusa-antes.txt`):

| grelha | casas bloqueadas com figura | marcadas na arena (Mestre · jogadora) | avisadas no ecrã (Mestre · jogadora) | folha do Mestre diz porquê |
|---|---|---|---|---|
| 30 × 30 de 1,5 m, conjunto da Ordem 45 (as 5 casas) | 5 | 0 · 0 | 0 · 0 | 0 |
| 30 × 30 de 1,5 m, uma figura em cada casa | 43 | 0 · 0 | 0 · 0 | 0 |
| 20 × 20 de 1,5 m · 25 × 25 de 1 m | 0 | — | — | — |
| entrar e sair da escarpa (27,24), nos dois sentidos | 1 | 0 · 0 | 0 · 0 | — |

As 5 casas são as da Ordem 58: (27,0) e (27,3) com água funda, (27,24) e (24,27) com escarpa, e (1,0) com menir. Nas
5, nas duas arenas, a figura não estava de pé (a regra da Ordem 58), mas também não havia nada na casa, nada no HUD
nem nos alertas, e a folha do Mestre dizia só «… · oculta». A recusa só se via na consola.

## 2. A correcção (`5d225b8`)

**Onde fica.** Está no caminho partilhado das duas arenas, `cenas/arena/campo_da_mesa.gd`, ao lado da
`recusa_do_pe` da Ordem 58:

- `anotar_recusa` passa a devolver `true` quando a recusa é nova ou mudou. Continua a escrever na consola uma vez só.
- `marcar_recusas(dono, marcas, recusas, origem, casa_m, material)` marca cada figura recusada **na casa dela**. A
  marca tem um remendo da casa (0,9 da casa, a seguir o relevo, com a cor de recusa `COR_RECUSA`, magenta a 60 %) e
  um rótulo 3D por cima da casa: «✕ nome» e, na linha de baixo, «não fica de pé: motivo». As marcas ficam num nó
  `Recusas` da arena, fora do mapa. Esse nó só nasce na primeira recusa; sem recusas, a árvore da arena fica como
  era. Uma marca que não mudou não se refaz, e as que deixam de valer saem logo da árvore.
- `aviso_das_recusas(novas, com_casa)` escreve o texto do ecrã, só com as recusas novas. Para uma figura: `«Lia» não
  fica de pé nesta casa: escarpa — o mapa bloqueia a casa. Fica marcada no mapa.` Para várias: `N figuras não ficam
  de pé — o mapa bloqueia as casas delas: «A» motivo; «B» motivo… Ficam marcadas no mapa.`

**Cada arena mostra a recusa onde já mostra os seus avisos:**

- **Jogadora** (`arena.gd` `_sincronizar_figuras`): o «Aviso» do HUD, durante 6 s (`SEGUNDOS_AVISO_RECUSA`), por um
  `hud.mostrar_aviso` novo, que é o `_mostrar_aviso` de sempre. O texto não tem coordenadas, porque o HUD não mostra
  nada técnico à jogadora. O nome é o `nomePublico`.
- **Mestre** (`arena_mestre.gd` `aplicar_vista`): o sinal novo `recusas_novas(aviso)` vai para `_juntar_alerta`, os
  alertas da coluna 1. Este texto leva a casa (x,y) e o nome do Mestre (`Modelo.nome_mestre`). A linha da figura na
  folha (aba Figuras) ganha « · ✕ não está de pé: motivo (o mapa bloqueia a casa)»
  (`Textos.NAO_DE_PE`, por `arena_mestre.motivo_do_pe_recusado`).
- A mesma vista ou o mesmo snapshot outra vez não avisa de novo. A marca fica enquanto a recusa durar. Quando uma
  figura entra numa casa bloqueada e outra sai dela, a marca e o aviso seguem quem entra.

**A escolha: marcada na casa dela, não posta na última posição legal.** O HUD já fala das casas de duas maneiras:
remendos que seguem o relevo (os destaques do mover e do alvo, o fogo, o cursor) e rótulos 3D (os nomes, o custo do
movimento). A marca de recusa usa as mesmas duas peças. Não a pus na última posição legal por três razões:

1. A Ordem 58 já decidiu que a figura não se desenha numa casa onde o servidor não a tem. A posição é do servidor. Uma
   figura desenhada noutra casa engana o toque, os destaques, o alcance e a adjacência.
2. Muitas vezes não há última posição legal. Uma figura que chega a uma casa bloqueada pela mudança de escala
   (a reserva 2 da Ordem 58) ou num snapshot de entrada nunca esteve noutro sítio que a arena conheça.
3. A arena teria de guardar a história das posições, o que é estado do cliente que o servidor não tem.

A marca diz a verdade: a figura está ali, segundo o servidor, e não fica de pé porque o mapa bloqueia a casa.

## 3. As provas de depois

### A prova nova, nas duas arenas

`provar_recusa_no_ecra.gd`, na ponta `5d225b8`, com `--antes=recusa-antes.json`, dá **TUDO PASSOU** (antes eram 14
falhas). O registo está em `provas/ordem-60-recusa/recusa-depois.txt`.

| casa (30 × 30 de 1,5 m) | motivo (servidor) | Mestre: marca na arena · alerta · folha | jogadora: marca na arena · Aviso do HUD |
|---|---|---|---|
| (27, 0) | água funda | «✕ P9 (Heroína Teste) / não fica de pé: água funda» · sim · «… · ✕ não está de pé: água funda (…)» | «✕ P9 / não fica de pé: água funda» · sim |
| (27, 3) | água funda | sim · sim · sim | sim · sim |
| (27, 24) | escarpa | sim · sim · sim | sim · sim |
| (24, 27) | escarpa | sim · sim · sim | sim · sim |
| (1, 0) | menir | sim · sim · sim | sim · sim |

Ficam de pé em casas bloqueadas 0 de 5, como na Ordem 58. Ficam **visíveis e avisadas 5 de 5**, nas duas arenas.

| grelha (figuras) | recusadas: marcadas · com nome e motivo · avisadas no ecrã (nas duas arenas) | folha do Mestre | casas que se pisam: sem marca nem aviso · de pé · posição igual à de antes, bit a bit · folha igual |
|---|---|---|---|
| 30 × 30 de 1,5 m, conjunto da Ordem 45 (105) | 5 · 5 · 5 de 5 | 5 de 5 | 100 · 100 · 100 de 100 · 100 de 100 |
| 20 × 20 de 1,5 m, conjunto da Ordem 45 (54) | 0 (nenhum alerta nem aviso novo) | — | 54 · 54 · 54 de 54 · 54 de 54 |
| 30 × 30 de 1,5 m, uma em cada casa (900) | 43 · 43 · 43 de 43 | 43 de 43 | 857 · 857 · 857 de 857 · 857 de 857 |
| 25 × 25 de 1 m, uma em cada casa (625) | 0 (nenhum alerta nem aviso novo) | — | 625 · 625 · 625 de 625 · 625 de 625 |

- **A mesma vista outra vez**, nas 4 grelhas: o Mestre não ganha nenhum alerta e o Aviso do HUD não volta a aparecer.
- **Entrar e sair**, na 30 × 30. Alfa entra na escarpa (27,24) e Bravo fica de pé na (29,24); depois trocam. Nas duas
  arenas, quem entra fica marcado e avisado («Alfa» / «Bravo» e «escarpa»). Quem sai fica de pé, sem marca, e não
  aparece no aviso.

### Com os olhos (fotos com janela)

`provas/ordem-60-recusa/jogadora-lia-na-escarpa.jpg` e `mestre-lia-na-escarpa.jpg`. Na 30 × 30 de 1,5 m, a figura
da própria jogadora («Lia») está na escarpa (27,24), que é o caso da reserva: a jogadora perdia a sua figura de
vista. O «Corvo» está de pé na casa ao lado. Na foto da jogadora vê-se a casa a magenta, o rótulo «✕ Lia / não fica
de pé: escarpa» e o Aviso no topo do HUD. Na foto do Mestre vê-se a casa marcada, «Alertas: 1» e o começo do alerta
na coluna 1, e a linha completa da folha.

### Suites da linha (ponta do ramo, sem janela, Godot 4.7.2)

Corri as suites na correcção (`5d225b8`); `pecas_mestre`, `hud_acoes` e `abrir_scripts` corri-as outra vez com as
guardas novas (`2a77367`).

| suite | resultado |
|---|---|
| `abrir_scripts` | 75 scripts, 0 falhas (os 74 da Ordem 58 mais a prova nova) |
| `rodar_testes` | 177/177 |
| `pecas_mestre` | 268/268 na correcção; **272/272** com as 4 guardas da Ordem 60 |
| `hud_acoes` | 46/46 na correcção; **50/50** com as 4 guardas da Ordem 60 |
| `abrir_mestre` · `abrir_clareira` · `canario_privacidade` · `clima_forte` | 67/67 · 22/22 · 10/10 · 119/119 |
| `medir_mestre` · `medir_painel_config` | saída 0 |
| `provar_assentamento` · `provar_terreno_servidor` · `provar_mestre_no_relevo` · `provar_pes_bloqueadas` · `provar_recusa_no_ecra` | TUDO PASSOU |
| `exportar_terreno --conferir` | o terreno do servidor está EM DIA |
| `provar_molde_54` | saída 0 |
| arranque `--quit-after 600` | «pronto», 0 erros |

Nenhuma suite deu SCRIPT ERROR, Parse Error nem Compile Error. O servidor não mudou nesta ordem; o CI corre-o.

## 4. A fusão em `fable/integracao-50`

A Ordem 57 já tinha aterrado: o ESTADO FINAL dela está no log de `fable/integracao-50` (`69f4498`) e a ponta era
`9b97066`. Fiz o fetch da linha antes de fundir e outra vez antes do push. A ponta não mexeu: as ordens visuais da
conta 1 (grama e água) ainda não tinham fundido.

**Onde se fez.** O ramo `fable/integracao-50` está aberto na árvore do clone `fable-mapaepo`, em que não toco. Por
isso fiz a fusão nesta worktree, num ramo local `fable/integracao-50-o60` que nasceu de `origin/fable/integracao-50`
(`9b97066`). Publiquei-o como `fable/integracao-50`, sem force: é um avanço rápido da ponta remota.

| commit | o quê |
|---|---|
| `fec411d` | A fusão: `fable/recusa-60` (`91f645d`) em `fable/integracao-50` (`9b97066`). A linha já trazia a Ordem 58 (`ae1e574` é a base comum), por isso só entram os commits da Ordem 60. |
| `b58f131` | As listas da retoma e o MANIFESTO refeitos pelo gerador. Os únicos conflitos da fusão foram nestas listas: ficaram as da linha, e o gerador refê-las (399 ficheiros no MANIFESTO). |
| *(este)* | Esta secção do ESTADO, com as listas. |

**Presenças dos dois lados, provadas na árvore fundida.**

- **Da linha (Ordem 57, o relógio do mundo):** o `ESTADO-FINAL-ORDEM-57.md`; o relógio nos scripts do mapa, do Estado
  e do HUD; e as provas que contam a lua à parte (`provar_assentamento`, `provar_mestre_no_relevo`). O `pecas_mestre`
  traz as 4 verificações da Ordem 57 (268 → 272) e o retrato do molde continua com 188 linhas, igual ao construído de
  raiz.
- **Da Ordem 60:** `marcar_recusas` e `aviso_das_recusas` no `campo_da_mesa.gd`, o sinal `recusas_novas` ligado aos
  alertas do Mestre, `hud.mostrar_aviso`, `Textos.NAO_DE_PE`, a prova `provar_recusa_no_ecra.gd` e as 8 guardas.

**Suites na árvore fundida** (`b58f131`, sem janela, Godot 4.7.2):

| suite | resultado |
|---|---|
| `abrir_scripts` | 83 scripts, 0 falhas (os 82 da linha mais a prova nova) |
| `rodar_testes` | 177/177 |
| `pecas_mestre` | **276/276** (os 272 da linha mais as 4 da Ordem 60) |
| `hud_acoes` | **50/50** (os 46 da linha mais as 4 da Ordem 60) |
| `abrir_mestre` · `abrir_clareira` · `canario_privacidade` · `clima_forte` | 67/67 · 22/22 · 10/10 · 119/119 |
| `medir_mestre` · `medir_painel_config` | saída 0 |
| `provar_assentamento` · `provar_terreno_servidor` · `provar_mestre_no_relevo` · `provar_pes_bloqueadas` · `provar_recusa_no_ecra` | TUDO PASSOU |
| `exportar_terreno --conferir` | o terreno do servidor está EM DIA |
| `provar_molde_54` | 0 falhas; o retrato do mapa vestido é igual ao construído de raiz (188 linhas) |
| arranque `--quit-after 600` | «pronto», 0 erros |

**CI.** No ramo `fable/recusa-60`, o run `43733614374` (commit `91f645d`) deu verdes os 9 jobs: `servidor`,
`retoma-pc`, `validador-glb`, `protocolo`, `motor-real`, `godot-cliente`, `ponta-a-ponta`, `cliente` e
`foto-mestre`. A sonda de privacidade também deu verde. Na linha, o push `9b97066..123dccb` (fetch antes, sem force) correu o run
`43734136474`, com os mesmos 9 jobs verdes, e a sonda de privacidade `43734136490` também verde. Este parágrafo e
as listas refeitas são o último commit da ordem; o CI dele corre no push do fecho.

## Reservas, sem rodeios

1. **O alerta do Mestre fica cortado na coluna 1.** O rótulo de alertas mostra só 2 linhas (`max_lines_visible = 2`,
   de antes desta ordem): «Alertas: N» e o começo do texto, que começa pelo nome. Com várias recusas de uma vez, o
   texto completo fica na lista `alertas` e na folha (aba Figuras), onde cada figura diz porquê. Não mexi no rótulo,
   porque serve todos os alertas.
2. **Um aviso só por vez no HUD da jogadora.** O Aviso do HUD é um só rótulo, e o aviso seguinte apaga o anterior.
   Uma recusa que chega junto com outra frase (um ataque, a desgraça) pode durar menos do que 6 s. Mas a marca na
   casa fica enquanto a recusa durar.
3. **Com muitas recusas de uma vez, o aviso fica comprido.** A prova põe uma figura em cada casa, e as 43 recusas
   cabem num aviso só, que ocupa várias linhas do HUD. No jogo, uma recusa só acontece pelo caminho da reserva 2 da
   Ordem 58 (a mudança de escala deixa figuras em casas bloqueadas): eram 7 figuras na sonda.
4. **A jogadora vê as recusas de todas as figuras que vê na arena, não só da sua.** São as mesmas figuras e os
   mesmos nomes públicos que já vê no mapa, por isso não abre nada novo. O `canario_privacidade` continua verde.
5. **O tamanho do rótulo da marca** é o mesmo nas duas arenas (`font_size` 48, `pixel_size` 0,005). Na arena do
   jogador fica um pouco menor do que os nomes das figuras; no Mestre, metade do tamanho dos nomes (os do Mestre
   usam `pixel_size` 0,01). Lê-se nas fotos, mas é uma escolha de arte por afinar.
6. **A prova nova não corre no CI**, porque precisa do Node ao lado do Godot e não toquei em `.github`, tal como a
   da Ordem 58. O CI guarda a regra com as 4 verificações novas do `pecas_mestre` (marca, aviso ao Mestre, sem
   repetição, troca) e as 4 do `hud_acoes` (marca, Aviso do HUD sem nada técnico, sem repetição, troca).
7. **A reserva 2 da Ordem 58 continua aberta.** O servidor pode deixar figuras em casas bloqueadas quando muda a
   escala. Esta ordem fez a recusa visível; não decidiu o que o servidor faz.
