# ESTADO-FINAL — Ordem CAIXA-RELATO-CORRECOES-7 (as correcções B1–B6 da sentença da CAIXA-RELATO-CORRECOES-6)

**Quem:** Claude, conta 1, no PC (22/11/2026). **Ramo:** `claude1/caixa-relato-correcoes-7`, a partir de `66da920`
(a ponta de `fable/integracao-50` quando clonei). **Não fundi.**
**Sede:** `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-caixa-relato-correcoes-7\`. O clone está em `repo\`, a pasta
tmp em `tmp\`.
**Commits:** `790e9a2` tem as correcções, o registo regenerado e as corridas, com o CI verde (10/10 jobs, retoma-pc
incluído, e a sonda de privacidade). A seguir vem o commit deste ESTADO-FINAL.

A conferência não está neste PC (`~/workspace/conferencias/` não existe aqui). Trabalhei pelo texto da ordem, que
traz os ficheiros e as linhas.

Este ficheiro não cita os nomes verdadeiros nem pedaços deles. Diz só o n.º do nome, a linha e o comprimento.
O conferidor estrito (critério alargado) dá 0 achados neste ficheiro, na secção nova do README e no ESTADO-FINAL-6
emendado.

## 1. Ponto a ponto

### B1 — o registo regenerado com a fonte actual — FEITO, PROVADO (36 corridas)
- **Corrida:** `correr-mutacoes.sh` (já com a B5), modo `base4` (18 mutações) e depois modo `novo` (18), em `66da920`,
  os dois para registos em tmp. Juntei-os em `provas/ordem-caixa-relato/correcoes-4/mutacoes.log`, com o cabeçalho
  reescrito: diz o que mudou e porquê.
- **Os títulos:** nas duas partes, `B1-nome-verdadeiro` e `N-B2-canario-minusculas-relato` (linhas 20/140 e 58/178)
  dizem agora «… o relato traz o nome verdadeiro n.º 1» e «… o nome verdadeiro n.º 1 em minúsculas». Antes diziam
  «‹nome verdadeiro›».
- **O que mudou, medido com `diff` contra o registo cometido, parte a parte:**
  - **Parte 1 (`base4`):** só os 2 títulos, a hora no cabeçalho e as horas da linha FALHA do caso do fuso.
  - **Parte 2 (`novo`):** os 2 títulos, as horas e as linhas FALHA da varredura de palavras de 4 mutações do teste
    (`B2-fuga-linhas-hora`, `B3-caixaMestre`, `B3-master`, `B3-PA`). Estas linhas trazem agora a cláusula «nem nada
    fora das chaves e palavras permitidas» e um contador «palavra(s) fora da lista». Vêm do `teste_relato_caixa.gd`
    da linha B7 (`9a980a0`, `28af7b4`), que entrou depois de `7ce6df3`. A ordem pede a fonte actual, e o modo `novo`
    corre os ficheiros como estão.
  - **Os 36 resumos «N de M» e os 36 rc** são iguais aos do registo cometido.
- **O marcador do filtro:** passa de 28 linhas e 92 ocorrências para **24 linhas e 88 ocorrências**. Saíram as 4 dos
  títulos. As que ficam estão nas linhas FALHA e nos resumos.
- **O conferidor** no registo regenerado (251 linhas): **0 achados, rc=0** no critério alargado (151 pedaços) e
  **0, rc=0** no antigo (`--velho`, 26 pedaços).

### B2 — «0 nomes verdadeiros» qualificado — FEITO, PROVADO (medido)
- **Medido** com o `conferir-registo.mjs` (critério alargado) sobre os relatos da CORRECOES-6: **48** (HUD), **46**
  (manequim) e **4** (`teste-relato.log`; 2 no critério antigo). A CORRECOES-5 dá os mesmos 48/46/4, e a CORRECOES-7
  (abaixo) também.
- **Classificados** com um script à parte, só em tmp. Para as linhas achadas, procurei o maior pedaço do nome que lá
  está.
  - **Nenhum é um nome inteiro**, em nenhum dos três ficheiros.
  - São os nomes públicos das duas fichas (a primeira palavra dos nomes verdadeiros, que o relato mostra por
    direito), a palavra que dá nome ao cenário dos testes (está no nome da sala e nos nomes públicos por inteiro), e,
    no teste, uma palavra corrente e um fim de palavra seguido da preposição.
- **Correcção:**
  - No `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-6.md` §2, as linhas HUD e MANEQUIM dizem agora «0 nomes verdadeiros
    **inteiros** (varredura do jogo; o conferidor estrito dá 48 [46], todos artefactos)». Uma nota de emenda (¹)
    explica o que lá estava, o que são os números e de onde vêm os artefactos.
  - A secção nova do README desta pasta (CORRECOES-7) usa a mesma qualificação.
  - A secção da CORRECOES-6 no README não trazia a frase «0 nomes verdadeiros», por isso não houve nada a emendar lá.

### B3 — o exemplo do comentário do conferidor — FEITO, PROVADO (executado)
- **Correcção** (`conferir-registo.mjs`, linhas 10–12): o exemplo passa a ser «x de Y», num nome de marcação
  «Xxxx de Yyyyy», com uma linha a dizer que é de propósito.
- **Prova:** o conferidor corrido sobre o próprio ficheiro dá 12 achados antes e 12 depois. Na linha 11, o maior
  pedaço passa de 6 caracteres (o pedaço real, a cavalo de palavras) para 5: uma palavra corrente que já estava na mesma
  linha. Os outros achados são pré-existentes: o caminho do ficheiro das fichas e palavras
  correntes. O ficheiro é código, não é o registo.

### B4 — os nomes inteiros que ficavam na fonte — FEITO, PROVADO (executado)
- **Correcção:**
  - `provas/ordem-caixa-relato/README.md` linha 96: «traziam os nomes verdadeiros n.º 1 e n.º 2 (os
    valores-canário). Agora lêem o `nomePublico` (as primeiras palavras deles)».
  - `ESTADO-FINAL-ORDEM-CAIXA-RELATO-CORRECOES-4.md` §3.2, linha 106: «(o nome verdadeiro n.º 1, inteiro e em
    minúsculas)».
  - `correr-mutacoes.sh` linha 16: o fragmento passa a «(o nome verdadeiro n.º 2 sem a última letra)».
- **Prova:**
  - Um grep sem distinguir maiúsculas pelos dois nomes inteiros, e pelo fragmento sem a última letra, dá **0** nos
    três ficheiros.
  - No script de classificação, os nomes inteiros encontrados passam de 2 para **0** no README e de 1 para **0** no
    ESTADO-FINAL-4.
  - No `correr-mutacoes.sh`, o pedaço de 14 caracteres (o fragmento) desaparece. Ficam palavras correntes e a palavra
    do cenário.

### B5 — a pasta tmp absoluta à entrada — FEITO, PROVADO (executado)
- **Correcção:**
  - Os dois scripts guardam `ORIGEM=$PWD` antes do `cd` para a raiz. Se a `<pasta-tmp>` não começar por `/` nem por
    uma letra de unidade (`C:`), passa a `ORIGEM/<pasta-tmp>`, com um aviso no stderr.
  - O `correr-prova-caixa-relato.sh` faz o mesmo à `<pasta-saída>` (o 4.º argumento), que tinha o mesmo defeito: o
    `--saida` do Godot. Isto vai além do que a ordem pediu e está marcado no comentário.
  - Escolhi absolutizar em vez de falhar, porque assim um caminho relativo funciona como se espera.
- **Prova:**
  - Com o **script antigo** (`66da920`), da raiz do clone, `T=../tmp/rel-antes`, `SO=B1-nome-verdadeiro`:
    - o Godot escreveu o relato em **`rascunhos/tmp/rel-antes/saida-hud/relato.txt`**;
    - o script não o achou (`grep: …/saida-hud/relato.txt: No such file`), e o registo ficou com «relato.txt:  linhas,
      resumo(s)» e o resumo vazio;
    - apaguei `rascunhos/tmp/` a seguir (não estava no git).
  - Com o **script novo**, da pasta da sede, `T=tmp/rel-depois`:
    - aviso «pasta tmp relativa — uso o caminho absoluto …/ordem-caixa-relato-correcoes-7/tmp/rel-depois»;
    - **39/43, rc=1**; «relato.txt: 68 linhas, 1 resumo(s)»;
    - o bloco da mutação no registo é igual ao do registo regenerado;
    - nada escrito em `rascunhos/`.
  - Com o `correr-prova-caixa-relato.sh` novo, da pasta da sede, `tmp/rel-prova tmp/rel-prova-saida`:
    - os dois avisos;
    - teste **31/31**, HUD **43/43**, manequim **53/53**, rc=0;
    - as saídas ficaram em `tmp/rel-prova-saida/`.
  - Depois de apagar o `rascunhos/tmp/` da corrida «antes», e a seguir às duas corridas «depois», o `git status` não
    mostra nada fora das saídas da ordem.

### B6 — o caminho do desvio no ESTADO-FINAL-6 §3.4 — FEITO, PROVADO (medido)
- **Medido:**
  - Com uma sonda Godot num projecto à parte (`--path proj`, `-s sonda.gd`), um ficheiro aberto com o caminho relativo
    `pasta-rel/x.txt` foi parar a `proj/pasta-rel/x.txt`. A pasta de trabalho do Godot passa a ser o `--path`.
  - A corrida «antes» da B5 confirma isto no caso real.
- **Correcção:** no §3 ponto 4, `rascunhos/tmp/` fica riscado e passa a `rascunhos/cliente/<pasta-tmp>/`. Uma nota de
  emenda (²) diz o resto:
  - com uma pasta relativa `T`, o bash escreve em `<raiz>/T` e o Godot em `rascunhos/cliente/T/saida-<corrida>/`;
  - o script procura depois o relato num sítio onde ele não está;
  - `rascunhos/tmp/` é só o caso `T=../tmp`, a pasta tmp da sede vista a partir da raiz do clone. É, muito
    provavelmente, o caso que a CORRECOES-6 teve.
  - desde a B5, os scripts absolutizam a pasta tmp.

## 2. As corridas (Godot 4.7.2 Windows, `Godot_v4.7.2-stable_win64_console.exe`, motor VLAB real `a91c021c…3261`, semente 7)

| Corrida | Resultado | Ficheiro |
|---|---|---|
| Teste do relato | **31/31**, rc=0 (conferidor estrito: 4 achados, 0 inteiros) | `provas/ordem-caixa-relato/correcoes-7/teste-relato.log` |
| Prova HUD-JOGADORA | **43/43**, rc=0; 68 linhas varridas = 68 no ficheiro; 0 nomes verdadeiros **inteiros** (varredura do jogo; o conferidor estrito dá 48, todos artefactos) | `correcoes-7/cliente-hud/relato.txt` |
| Prova MANEQUIM | **53/53**, rc=0; 78 = 78; 0 nomes verdadeiros **inteiros** (varredura do jogo; o conferidor estrito dá 46, todos artefactos) | `correcoes-7/cliente-manequim/relato.txt` |
| Mutações, modo `base4` | 18 corridas, nenhuma «NÃO APLICOU»; resumos e rc iguais aos do registo cometido | `correcoes-4/mutacoes.log`, parte 1 |
| Mutações, modo `novo` | 18 corridas, nenhuma «NÃO APLICOU»; resumos e rc iguais aos do registo cometido | `correcoes-4/mutacoes.log`, parte 2 |
| Conferidor, critério alargado, registo regenerado | **0 achados**, rc=0, 251 linhas, 151 pedaços | `correcoes-4/mutacoes.log` |
| Conferidor, critério antigo (`--velho`), registo regenerado | **0 achados**, rc=0, 26 pedaços | idem |
| B5, mutação com tmp relativa: antes / depois | antes: relato em `rascunhos/tmp/…`, registo vazio · depois: 39/43, 68 linhas | só em tmp |
| B5, provas com tmp e saída relativas | 31/31 · 43/43 · 53/53, rc=0 | só em tmp |

- Os relatos da CORRECOES-7 são iguais aos da CORRECOES-6, linha a linha, se se tirarem as horas (`diff` vazio nos
  dois).
- O lançador é o de sempre: `correr-prova-caixa-relato.sh … "$PWD/provas/ordem-caixa-relato/correcoes-7"`. Não copia
  o PIN nem as capturas.

O `actualizar-listas` (`python retoma-i0004/actualizar-listas.py`) correu antes do commit `790e9a2` e outra vez
antes do commit deste ficheiro. As duas vezes deu «0 novos, 0 tirados», e o `git status` não mudou. O ramo não toca
em `rascunhos/`.

**CI em `790e9a2`:** os **10/10 jobs** do «Testes dos rascunhos» passaram (servidor, cliente, motor-real,
foto-mestre, godot-cliente, protocolo, ponta-a-ponta, provas-mapa, validador-glb, **retoma-pc**; run 45023962346).
A «Sonda de privacidade» também passou (run 45023962281).

## 3. Pontos para o coordenador
1. **A parte `novo` do registo já não corre o código da CORRECOES-4.** Corre a fonte actual, com o
   `teste_relato_caixa.gd` da linha B7. Os resumos são os mesmos; mudam só as linhas FALHA de 4 mutações do teste (a
   cláusula nova). O cabeçalho do registo diz isto. Se quiseres a parte 2 presa ao código da CORRECOES-4, é um modo
   `base` com `7ce6df3`; com a ordem a pedir «a fonte actual», não o fiz.
2. **Ainda há nomes inteiros fora dos três sítios da B4.** Estão em registos de corridas de ordens antigas
   (`cliente-hud/` e `cliente-manequim/` da raiz desta pasta e de `correcoes/`: 5 linhas por relato; `correcoes-3/mutacoes.log`:
   30 linhas) e em dois ESTADO-FINAL antigos (CORRECOES-2: 2 linhas; CORRECOES-3: 1 linha). Os registos são o que se
   viu na altura, de antes do B1 da CORRECOES-2, e reescrevê-los falsificava-os. Os ESTADO-FINAL não estavam na ordem.
   Não lhes toquei.
3. **B5 vai um pouco além da ordem.** A `<pasta-saída>` do `correr-prova-caixa-relato.sh` também é absolutizada,
   porque tinha o mesmo defeito. O `<registo.log>` das mutações não precisa: só o bash o escreve.
4. **B2, a secção do README da CORRECOES-6:** não trazia «0 nomes verdadeiros», por isso a qualificação está só no
   ESTADO-FINAL-6 e na secção nova (CORRECOES-7).
5. **O autor do commit:** o primeiro push (`ced3854`) saiu com o autor do commit da ponta, não com a identidade
   configurada. Corrigi-o com `--amend --reset-author` e voltei a publicar com `--force-with-lease` (o ramo é meu,
   tinha um minuto e não estava fundido). O commit é o `790e9a2`.
6. **Fronteira:** mexi só em `provas/ordem-caixa-relato/` (`conferir-registo.mjs`, `correr-mutacoes.sh`,
   `correr-prova-caixa-relato.sh`, README, `correcoes-4/mutacoes.log`, `correcoes-7/` nova), nos ESTADO-FINAL da
   CORRECOES-4 (linha 106) e da CORRECOES-6 (§2 e §3.4, com notas de emenda) e neste ficheiro. Não mexi no código do
   jogo, no HUD, nas cores, no workflow nem em `rascunhos/`. Não mexi no `ORDEM.md` da sede.
7. **A linha «Estado: NOVA»:** o `ORDEM.md` da sede já termina com ela, e não mexi nele. Não a pus neste ficheiro.
