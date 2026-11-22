# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-8 (as correcções B1–B5 da sentença da CAIXA-RELATO-CORRECOES-7)

**Quem:** Claude, conta 1, no PC (22/11/2026). **Ramo:** `claude1/caixa-relato-correcoes-8`, a partir de `5e67145`
(a ponta de `fable/integracao-50` à hora do lançamento; conferido com `git fetch`). **Não fundi.**
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-8\`. O clone está em `repo\`, a
pasta tmp em `tmp\`.
**Commits:** `2f060f7` tem as correcções e as corridas, com o CI verde (10/10 jobs, retoma-pc incluído, e a sonda
de privacidade). A seguir vem o commit deste ESTADO-FINAL.

A conferência não está neste PC (`~/workspace/conferencias/` não existe aqui). Trabalhei pelo texto da ordem.

Este ficheiro não cita os nomes verdadeiros nem pedaços deles. Diz só o n.º do nome, a linha e o comprimento.
O conferidor estrito dá 0 achados neste ficheiro, nos dois critérios. Também dá 0 no ESTADO-FINAL-7 emendado e no `absolutizar.sh`. Nos outros dois scripts e na secção nova do README
não entra nenhum achado novo: 17 → 17, 3 → 3 e 20 → 20. São palavras correntes e a palavra do cenário, que já lá
estavam.

## 1. Ponto a ponto

### B1 — «36 resumos» → 38 — FEITO, PROVADO (contado)
- **Contado** no `correcoes-4/mutacoes.log`: **36** blocos `== `, **38** linhas-resumo «N de M», **36** `rc=`.
- **Os 2 a mais:** na parte 1 (`base4`), os blocos `N-B1-canario-na-linha-em-branco` e
  `N4-B1-canario-na-linha-em-branco-manequim` têm 2 resumos por bloco. O `relato.txt` dessas corridas traz uma linha-resumo
  escrita antes da re-varredura (43 de 43; 53 de 53) e outra depois de ela achar o canário (43 de 44; 53 de 54), e o
  harness copia as duas («2 resumo(s)»). Na parte 2 (`novo`), há só uma.
- **Os 38 são iguais aos de antes:** entre o registo actual e o de `fe4a84d` (antes da regeneração da CORRECOES-7), o
  `diff` sai vazio nos 38 resumos e nos 36 `rc=`; 4 títulos diferem (n.º 1, 7, 19, 25), só na redacção.²

  ² **Emenda (Ordem CAIXA-RELATO-CORRECOES-9, B1).** A primeira redacção dizia que o `diff` dos títulos, resumos e
  `rc=` saía vazio. Nos títulos não sai: os 4 títulos (n.º 1, 7, 19 e 25 dos 36, pela ordem do registo) das mutações
  `B1-nome-verdadeiro` e `N-B2-canario-minusculas-relato` (as duas, nas duas partes) passaram de «‹nome verdadeiro›»
  para a redacção «n.º 1» na CORRECOES-7. Corrido outra vez na CORRECOES-9.
- **Correcção:** no `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-7.md` §1 B1, «36» fica riscado e passa a **38**¹, com
  uma nota de emenda (¹), como as emendas ¹ e ² do ESTADO-FINAL-6.
- **Conferidor** nesse ficheiro: 0 achados antes e 0 depois. A primeira redacção da nota dava 2 achados de 4 car.
  (uma palavra corrente e um fim de palavra seguido da preposição). Reescrevi-a, porque o ficheiro diz de si mesmo
  que dá 0.

### B2 — os pedaços de 12 car. do ESTADO-FINAL-4 §3.2 — FEITO, PROVADO (executado)
- **Correcção:** linha 105, «ainda tem nomes-canário (o nome verdadeiro n.º 1 e um nome público), em 6 títulos»;
  linha 109, «São valores-canário (o nome verdadeiro n.º 1 e um nome público), fictícios». É a redacção «n.º» da
  linha 106.
- **Prova** (conferidor, critério alargado, e o script de classificação, só em tmp):
  - o ficheiro passa de **10 para 7** achados;
  - os 4 de 12 car. (linhas 105 e 109, n.º 1 e n.º 2) saíram;
  - na linha 105 fica 1 achado de **6 car.**, o fim de «registo» seguido de «de». Já estava na linha, escondido
    pelo pedaço maior;
  - os outros 6, linhas 10, 24 e 76 (4 car.), já lá estavam;
  - **0 nomes inteiros**.

### B3 — os casos de canto do absolutizar — FEITO, PROVADO (executado, caso a caso)
- **Correcção:** uma função só, **`provas/ordem-caixa-relato/ferramentas/absolutizar.sh`**. Os dois scripts lêem-na
  (`.`) antes do `cd` para a raiz. Substitui o `case` do `correr-mutacoes.sh` (era a linha 29) e o `absoluto()` do
  `correr-prova-caixa-relato.sh` (era a linha 20).

  | Entrada | Antes (5e67145) | Agora |
  |---|---|---|
  | `~/…`, `~`, `~\…` | `<origem>/~/…` (sítio errado) | `$HOME/…`. Se o `$HOME` não for absoluto, falha |
  | `~utilizador/…` | `<origem>/~utilizador/…` | **falha**, rc=2 |
  | `\\servidor\…` | `<origem>/\\servidor\…` | **falha**, rc=2 («caminho de rede (UNC) não é suportado») |
  | `//servidor/…`, `/\…` | tomado por absoluto | **falha**, rc=2 (UNC) |
  | `\/servidor/…` | `<origem>/\/servidor/…` | **falha**, rc=2 (UNC) |
  | `C:pasta`, `C:` | tomado por absoluto | **falha**, rc=2 (relativo à pasta corrente da unidade) |
  | `\pasta\…` | `<origem>/\pasta\…` | `<unidade da origem>:/pasta/…` (a unidade lê-se com `cygpath -m`) |
  | `/c/…`, `C:/…` | fica | fica |
  | `C:\…` | fica | fica, com as barras invertidas a passar a `/` |
  | relativo (`tmp/x`, `./x`, `..\x`) | `<origem>/…` | `<origem>/…`, com `\` → `/` |

  Quando o caminho muda, há um aviso no stderr com o caminho usado. Escolhi **falhar** nos casos que não têm resposta
  certa:
  - num UNC, o bash do MSYS e o Godot podiam não ver a mesma pasta;
  - num `C:pasta`, o bash não conhece a pasta corrente das unidades;
  - num `~utilizador`, não há maneira fiável de achar a pasta.

- **Prova 1 — a função antiga contra a nova, executadas:** 16 casos (`tmp/b3-casos.sh`) e mais 3 só da nova
  (`tmp/b3-casos-extra.sh`): `/\…` → falha; `~/x` com `HOME=casa-relativa` → falha; `~/x` com `HOME=C:/Users/…` →
  `C:/Users/…/x`. A tabela é o que saiu das corridas.
- **Prova 2 — os scripts verdadeiros, chamados da sede, com os 5 caminhos que falham** (`~root/x`,
  `\\servidor\partilha\tmp`, `//servidor/partilha/tmp`, `C:tmp`, `C:`) em todos os argumentos que são caminhos:
  - a pasta tmp e a de saída do `correr-prova-caixa-relato.sh`; a pasta tmp e o registo do `correr-mutacoes.sh`;
  - dão **20 de 20 com rc=2**, todos com a mensagem certa;
  - uma listagem da sede e do clone, mais o `git status`, antes e depois, são iguais. A única diferença é o próprio
    ficheiro da listagem «depois». Nada foi escrito.
- **Prova 3 — os dois casos que passam a ser resolvidos, na corrida a sério:**
  - as corridas da §2 foram lançadas da sede com a pasta tmp `'~/RPG_Local/…/ordem-caixa-relato-correcoes-8/tmp/corrida'`
    (entre plicas, para o bash não a expandir) e a pasta de saída
    `'\Users\txcga\…\repo\provas\ordem-caixa-relato\correcoes-8'`;
  - saíram os dois avisos (`/c/Users/txcga/…/tmp/corrida` e `C:/Users/txcga/…/correcoes-8`), **31/31, 43/43, 53/53,
    rc=0**, e as saídas ficaram nesses sítios.
- **Prova 4 — o `C:pasta` com o script antigo e com o novo**, numa mutação (`SO=B1-nome-verdadeiro`, modo `novo`):
  - **antes**, o script de `5e67145` com a pasta tmp `C:tmp-antes-c8`:
    - o MSYS criou na raiz do clone uma pasta chamada `C`+U+F03A+`tmp-antes-c8` (troca o `:` por um carácter
      privado), e os ficheiros limpos foram para uma pasta encaixada dentro dela, `…/C:tmp-antes-c8/limpo`
      (`cp: cannot create …` / `cannot stat …`);
    - o Godot deu «ERROR: Could not create directory: '…/repo/rascunhos/cliente/C:tmp-antes-c8'», e a prova deu
      «0 de 2 verificações»;
    - o script não achou o relato e **saiu com 0**;
    - os ficheiros das provas voltaram ao que eram (a guarda foi para o mesmo sítio estranho e foi lida de lá), e o
      `git status` não mostrou nenhum ficheiro-fonte mudado;
    - apaguei a pasta estranha a seguir, pelo caminho literal (não estava no git).
  - **depois**, o script novo com `C:tmp-depois-c8`: rc=2 e a mensagem. Nada escrito.

### B4 — o `LOG` absolutizado à entrada — FEITO, PROVADO (executado)
- **Correcção:** `absolutizar LOG "registo" || exit 2` no `correr-mutacoes.sh`, logo a seguir à pasta tmp. Os casos
  são os mesmos da B3.
- **Prova:**
  - **antes** (a mesma corrida da prova 4 da B3), o registo `tmp/mut-antes.log`, dado a partir da sede, contava a
    partir da raiz do clone, onde não há `tmp/`. Deu «line 67: tmp/mut-antes.log: No such file or directory», e o
    registo não ficou escrito em lado nenhum;
  - **depois**, o script novo da sede, com a pasta tmp `\Users\txcga\…\ordem-caixa-relato-correcoes-8\tmp\mut-depois`
    (o caso `\pasta\…` da B3) e o registo `tmp/mut-depois.log`:
    - os dois avisos, e o registo ficou em `<sede>/tmp/mut-depois.log`;
    - 39 de 43, rc=1, «relato.txt: 68 linhas, 1 resumo(s)»;
    - o bloco é igual ao da parte 2 do registo cometido, tirando as horas;
    - o conferidor dá 0 achados;
  - os 5 caminhos que falham, dados como registo, falham com rc=2 (B3, prova 2).

### B5 — os nomes inteiros nos dois ESTADO-FINAL antigos — FEITO, PROVADO (executado)
- **Correcção (só de texto):**
  - `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-2.md` linha 11: «e não os nomes verdadeiros n.º 1 e n.º 2»; linha
    18: «(«‹o nome verdadeiro n.º 2› na linha 6», …)»;
  - `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-3.md` linha 34: «(o nome verdadeiro n.º 1 em minúsculas, via
    `_nome_publico`)».
- **Prova:** no script de classificação, os nomes inteiros passam de **3 para 0** na CORRECOES-2 e de **1 para 0** na
  CORRECOES-3. No conferidor, os achados passam de 20 para 18 e de 19 para 17. Os que ficam são palavras públicas
  e a palavra do cenário, que já lá estavam.
- Não mexi nos 4 relatos antigos nem no `correcoes-3/mutacoes.log`. São registo histórico permanente, por decisão
  registada.

### A decisão de âmbito — ESCRITA
Está escrita na secção nova (CORRECOES-8) do `provas/ordem-caixa-relato/README.md` e aqui. O critério estrito
(`conferir-registo.mjs`, critério alargado) **aplica-se ao registo e à fonte**. **Não se aplica à saída do jogo**
(os `relato.txt` e os `teste-relato.log`) **nem ao diff que a inclui.**

O diff deste ramo, medido nas linhas adicionadas, dá **101** achados:
- 98 são dos relatos novos (48 HUD + 46 manequim + 4 teste), todos artefactos, com 0 nomes inteiros;
- 2 estão na linha 11 da CORRECOES-2. São os dois nomes públicos, que já lá estavam e continuam na linha mudada;
- 1 está na linha 105 da CORRECOES-4: os 6 car. da B2.

As ferramentas, o README e o ESTADO-FINAL-7 dão **0** no diff. A sentença falava de 102 no diff da CORRECOES-7
(98 + 4 em comentários). Neste ramo não há nenhum achado em comentários.

## 2. As corridas (Godot 4.7.2 Windows, `Godot_v4.7.2-stable_win64_console.exe`, motor VLAB real `a91c021c…3261`, semente 7)

| Corrida | Resultado | Ficheiro |
|---|---|---|
| Teste do relato | **31/31**, rc=0 (conferidor estrito: 4 achados, 2 no `--velho`, 0 inteiros) | `provas/ordem-caixa-relato/correcoes-8/teste-relato.log` |
| Prova HUD-JOGADORA | **43/43**, rc=0; 68 linhas; 0 nomes verdadeiros **inteiros** (varredura do jogo; o conferidor estrito dá 48, todos artefactos) | `correcoes-8/cliente-hud/relato.txt` |
| Prova MANEQUIM | **53/53**, rc=0; 78 linhas; 0 nomes verdadeiros **inteiros** (varredura do jogo; o conferidor estrito dá 46, todos artefactos) | `correcoes-8/cliente-manequim/relato.txt` |
| Conferidor, critério alargado, registo regenerado | **0 achados**, rc=0, 251 linhas, 151 pedaços | `correcoes-4/mutacoes.log` |
| Conferidor, critério antigo (`--velho`), registo regenerado | **0 achados**, rc=0, 26 pedaços | idem |
| B3, função antiga e nova, 16 + 3 casos | ver a tabela da B3 | só em tmp |
| B3/B4, scripts verdadeiros, 5 caminhos × 4 argumentos | **20/20 rc=2**, nada escrito | só em tmp |
| B3/B4, mutação `B1-nome-verdadeiro`: antes / depois | antes: Godot falha, 0 de 2, registo por escrever, rc=0 · depois: `C:pasta` rc=2; `\pasta\…` 39/43, bloco igual | só em tmp |

- Os três ficheiros da CORRECOES-8 são iguais aos da CORRECOES-7, linha a linha, se se tirarem as horas e os
  milissegundos (`diff` vazio nos três).
- O PIN das duas salas (o `pin` dos `info-*.json`, que ficaram na pasta tmp) **não aparece** em `correcoes-8/`, no
  README nem nos ESTADO-FINAL. Procurei-o com `grep -F`. Não se copiam as capturas.

O `actualizar-listas` (`python retoma-i0004/actualizar-listas.py`) correu antes do commit `2f060f7` e outra vez
antes do commit deste ficheiro. As duas vezes deu «0 novos, 0 tirados», e o `git status` não mudou. O ramo não toca
em `rascunhos/`.

**CI em `2f060f7`:** os **10/10 jobs** do «Testes dos rascunhos» passaram (servidor, cliente, motor-real,
foto-mestre, godot-cliente, protocolo, ponta-a-ponta, provas-mapa, validador-glb, **retoma-pc**; run 45035286792).
A «Sonda de privacidade» também passou (run 45035286791).

## 3. Pontos para o coordenador
1. **B3: falhar ou absolutizar.** Os scripts **absolutizam** `~/…` e `\pasta\…` (há resposta certa) e **falham**
   com UNC, `C:pasta` e `~utilizador` (não há). Se preferires que o `\pasta\…` também falhe, é uma linha no
   `absolutizar.sh`.
2. **A função ficou num ficheiro novo** (`absolutizar.sh`), para os dois scripts não voltarem a divergir. É lido com
   `.` a partir de `$(dirname "$0")`, antes do `cd`.
3. **O `C:pasta` era pior do que «resolver para o sítio errado».** O bash e o Godot não o resolveram da mesma maneira
   (uma pasta com um carácter privado na raiz do clone; um erro do Godot), e o script saiu com 0. A guarda foi para o
   mesmo sítio estranho e foi lida de lá, por isso os ficheiros-fonte voltaram ao que eram. Mas o caso mostra porque
   é que falhar à entrada é a escolha certa.
4. **B2:** ficou um achado de 6 car. na linha 105 (o fim de «registo» seguido de «de»). É do tipo que a sentença já
   classificou como artefacto, e estava escondido pelo pedaço de 12. Não o reescrevi.
5. **B5:** na CORRECOES-2, a linha 81 tem um pedaço de 12 car. que não é nome inteiro e está fora da ordem (a B5 pede
   os nomes inteiros). Não lhe toquei.
6. **Fronteira:** mexi só em `provas/ordem-caixa-relato/` (`absolutizar.sh` novo, `correr-mutacoes.sh`,
   `correr-prova-caixa-relato.sh`, README, `correcoes-8/` nova), nos ESTADO-FINAL da CORRECOES-2, -3, -4 e -7 (só
   texto) e neste ficheiro. Não mexi no código do jogo, no HUD, nas cores, no workflow nem em `rascunhos/`.
7. **A linha «Estado: NOVA»:** o `ORDEM.md` da sede já termina com ela (`<b>Estado: NOVA</b>`), e não mexi nele.
