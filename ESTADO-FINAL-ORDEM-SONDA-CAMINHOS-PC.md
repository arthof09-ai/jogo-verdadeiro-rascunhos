# ESTADO-FINAL — ORDEM-SONDA-CAMINHOS-PC (a Sonda apanha os caminhos do PC)

**Estado: FEITA NO RAMO, COM UM PASSO POR APLICAR.** A rede está feita e provada, mas o passo dela no
`privacidade.yml` não está no workflow. O GitHub recusou o push: o token do PC não tem o âmbito `workflow` (§3). O
passo vai como remendo, como na CAIXA-JANELA-CI e na PLANO-2-F2. **Até o coordenador o aplicar, o CI corre a Sonda
antiga.**

- **Executor:** Claude (opus), PC, conta 2. **Data:** 24/11/2026, ~07:37–07:50 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `072cefb`. Durante o trabalho entraram o `baaa31f` e o `aacaef6` (F4-PARCIAL: listas da retoma e nota do CI). Pus
  os meus commits por cima deles, que ainda não tinham subido. Não reescrevi nada do que estava no remoto.
- **Não toquei** no servidor, nos dados, na `main`, nos ficheiros da F3 nem em `rascunhos/`. Por isso **não corri o
  `actualizar-listas.py`**: nenhum commit desta ordem muda ficheiros em `rascunhos/`.

Este ficheiro não traz o caminho do PC escrito. As formas descrevem-se por partes.

## 1. A rede

`.github/sonda/caminhos_pc.py`: procura em todos os ficheiros de texto (fora do `.git`; os binários são saltados como
no `grep -I` da regra dos e-mails), sem distinguir maiúsculas:

| forma | o que apanha |
|---|---|
| 1 | a unidade `C:` seguida de `/Users/`, também com a barra dobrada |
| 2 | a unidade `C:` seguida de `\Users\`, também com a barra invertida dobrada (que é como sai escapada em JSON) |
| 3 | `/c/` seguido de `Users/` (a forma do Git Bash) |

As expressões estão escritas de modo a não se apanharem a si mesmas: a letra da unidade vai entre parênteses rectos.
Quando há ocorrências novas, a saída diz `ficheiro:linha` e a forma, **sem o texto da linha**. Assim o próprio
registo do CI não repete o caminho.

A regra dos e-mails não mudou.

### 1.1 Desvio: a linha de base (decisão minha; peço confirmação)

A ordem manda acrescentar a rede e ter a Sonda verde, e proíbe tocar nos ficheiros já escritos. Com a rede crua, as
duas coisas não podem ser verdade ao mesmo tempo. No ramo, a ponta `baaa31f` já traz **348 ocorrências em 109
ficheiros**:

| onde | ocorrências |
|---|---|
| `provas/` | 247 |
| raiz (ESTADO-FINAL, MANIFESTO, README, RETOMA) | 53 |
| `rascunhos/` | 39 |
| `pacotes/` | 7 |
| `bancada-rede/` | 1 |
| `retoma-i0004/` | 1 |

Por forma (uma linha pode ter mais do que uma): forma 1 em 118 linhas, forma 2 em 87, forma 3 em 151. O
`MANIFESTO-SHA256.txt:2`, o precedente da D-AUD-01-CORRECCOES, está entre elas (forma 2). É muito mais do que os 7
ficheiros da F3, porque a Sonda era cega a isto desde o princípio.

Por isso a rede tem uma **linha de base congelada**, `.github/sonda/caminhos-pc-base.txt`. Cada entrada é o caminho
relativo + o sha256 da linha. A base não traz o texto, por isso não repete o caminho do PC. A conta é feita como
multiconjunto:

- as 348 ocorrências conhecidas passam;
- **qualquer ocorrência nova falha**: num ficheiro novo, numa linha nova de um ficheiro já listado, na mesma linha
  copiada para outro ficheiro ou repetida no mesmo ficheiro (os quatro casos estão no auto-teste);
- quando uma errata redige um ficheiro, as entradas dele **sobram**. A Sonda informa («N entradas da base já não
  existem») mas não falha. Para encolher a base: `python3 .github/sonda/caminhos_pc.py --raiz . --gerar
  .github/sonda/caminhos-pc-base.txt`. A base só pode encolher. Para a fazer crescer, é precisa uma ordem **e** o sinal `--permitir-crescer` com a referência dessa ordem — o código recusa crescer sem ele.

Se o coordenador preferir a rede crua, isto é, a Sonda vermelha até a redacção acabar, basta tirar o `--base` do
passo.

## 2. A prova de que morde (aceitação: as três formas, uma a uma)

`provas/ordem-sonda-caminhos-pc/ferramentas/prova-sonda.sh` corre na cópia de trabalho os passos do
`privacidade.yml` com o remendo, pela ordem: e-mails, depois caminhos. A ponta é a `35e7123` (o mesmo commit que é hoje o `ae20ea2`; mudou de hash quando o reassentei sobre o `aacaef6`, uma nota da F4 que não toca no `.github`), com o `.github` igual ao
commit.

A ponta `35e7123` é um hash local, anterior ao rebase; a cadeia `35e7123` → `ae20ea2` assenta na minha palavra e na identidade dos blobs do `.github/` entre as duas pontas.

| prova | ficheiro de teste | saída da Sonda |
|---|---|---|
| p0 | nenhum | **0**: e-mails limpos; 348 ocorrências, 348 na base, 0 novas |
| p1 | `sonda-teste-caminho.txt` com a forma 1 na linha 2 | **1**: `NOVO sonda-teste-caminho.txt:2 forma 1` |
| p2 | o mesmo, com a forma 2 | **1**: `… forma 2` |
| p3 | o mesmo, com a forma 3 | **1**: `… forma 3` |
| p4 | apagado | **0**, como em p0 |
| p5 | auto-teste (o passo «A rede morde») | **0**: 11 casos, 0 falhas |

Os 11 casos do auto-teste:

- a árvore limpa passa;
- as 6 variantes são apanhadas: as três formas, a barra dobrada, o JSON escapado e as minúsculas;
- a ocorrência conhecida na base passa;
- 3 casos de batota com a base são apanhados.

O auto-teste também mostra o que **não** se apanha: `C:/Programas`, `/c/Programas`, a unidade `D:` com `Users`,
`Users/` sem unidade, `<sede>/repo`, a mistura de barras (`C:/Users\…` e `C:\Users/…`), `/c//Users/`, `C:Users`
sem barra, a linha que termina na pasta do utilizador sem barra a seguir a `Users`, os caminhos de rede UNC
(`\\servidor\Users\…`) e os ficheiros em UTF-16 ou com byte NUL cedo, que o guião salta inteiros como binários.
**A rede cobre as três formas pedidas pela ordem; não cobre todos os caminhos reais do PC.** Alargar a rede a estas
formas é outra ordem.

**Relato da prova (não medido):** na primeira corrida, o auto-teste imprimia o caminho inteiro da base temporária — a
pasta temporária do Windows fica debaixo da pasta do utilizador, e a rede nova apanhou-o no meu próprio registo. Não
há log dessa primeira corrida na entrega; a correcção (o guião imprime só o nome do ficheiro) está verificada no
código e no p5. Mais um relato: o `--import` do Godot escreve o caminho do PC em
`rascunhos/cliente/.godot/editor/project_metadata.cfg`; apaguei a cache (`git clean -fdX rascunhos/cliente`) antes da
conferência final, mas sem registo da eliminação — e o `--import` do próprio `rodar.log` regenera essa cache, por
isso não está provado que o ficheiro não existia durante as suites. Em qualquer caso o impacto no repositório é
zero: esse ficheiro é ignorado pelo git e nunca sobe.

## 3. O CI

- **O remendo** `provas/ordem-sonda-caminhos-pc/remendo-privacidade.yml.patch` acrescenta dois passos ao job
  `sonda`, ambos com `if: always()`: «A rede morde (auto-teste com as três formas, uma a uma)» e «Procurar caminhos
  reais do PC». O `git apply --check` passa na ponta.
- **O push dele foi recusado:** *«refusing to allow an OAuth App to create or update workflow
  `.github/workflows/privacidade.yml` without `workflow` scope»*. O guião e a base estão em `.github/sonda/`, que não
  é pasta de workflows, e esses subiram.
- **CI desta entrega** (Testes + Sonda antiga): ver a nota do fim. A rede nova ainda não correu no CI.

## 4. As suites

Nenhum código do jogo mudou. Corri as suites para confirmar que o ramo continua verde:

| suite | resultado |
|---|---|
| `rascunhos/servidor` (`node --test --test-isolation=none`) | 442 / 442, 0 falhas |
| `rascunhos/validador-glb` | 31 passam, 2 saltados (UAL1, sem `UAL1_GLB`, como no CI), 0 falhas |
| `rascunhos/cliente` `rodar_testes.gd` (Godot 4.7.2 `--headless`) | 333 de 333 |

Os logs estão em `provas/ordem-sonda-caminhos-pc/suites/`. Cada um abre com `# comando:`, `# hora:` e `# ponta:`.

## 5. Commits

| commit | o quê |
|---|---|
| `ae20ea2` | a rede (`caminhos_pc.py`) e a linha de base (348 entradas) |
| `aa31e3a` | este ESTADO-FINAL, as provas, o remendo |
| (seguinte) | a nota do CI |

## 6. Pontos para o coordenador

1. **Aplicar o remendo** com o token que tem o âmbito `workflow`:
   `git apply provas/ordem-sonda-caminhos-pc/remendo-privacidade.yml.patch`, commit e push. A primeira run da Sonda
   com o remendo deve dar os dois passos novos verdes («AUTO-TESTE: 0 falha(s)» e «0 novas»). **Só então fica
   cumprido o «CI verde (Sonda)» com a rede nova.**
2. **Confirmar ou recusar a linha de base** (§1.1).
3. **Encolher a base** depois de cada errata de redacção (`--gerar`). Com o tempo, a base deve chegar a 0 entradas.

## Nota do CI

No `aa31e3a`: **Testes `45377701821` success** (os 10 jobs) + **Sonda `45377701648` success**. A Sonda que correu é
a **antiga** (só os e-mails): o remendo não está aplicado (§3, §6.1). A rede nova só foi provada no PC (§2).

**Nota do CI das erratas (conferência 745):** erratas de registo A.1/A.2/A.3/A.6 (`0344114`), guarda A.4 (`ddb76db`) e
remendo A.5 (`9ab44e2`) — CI verde nos três commits (Testes + Sonda). No `9ab44e2`: **Testes `45383839052` success** (os 10
jobs) + **Sonda `45383839777` success** — a 1.ª corrida da Sonda nova: «A rede morde» com `AUTO-TESTE: 0 falha(s)` (15 casos:
11 do auto-teste + 4 da guarda) e «Procurar caminhos reais do PC» com 348 ocorrências, 348 na base, **0 novas**. A aceitação
«CI verde (Testes + Sonda)» com a rede nova fica cumprida.
