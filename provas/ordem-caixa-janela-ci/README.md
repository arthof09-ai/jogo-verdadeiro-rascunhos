# Provas da Ordem CAIXA-JANELA-CI

A suite `rascunhos/cliente/testes/caixa_janela.gd` passa a correr no CI (job `cliente` do `testes.yml`), com o mesmo
arranque que a casa usa no PC: `godot --headless --path rascunhos/cliente -s res://testes/caixa_janela.gd`. Não precisa
de ecrã nem de render.

- `remendo-ci-testes.yml.patch` — **o passo novo do CI, por aplicar.** O token deste PC não tem o âmbito `workflow` e
  o GitHub recusou o push do `testes.yml`. Por isso o remendo vem aqui e aplica-o o coordenador:
  `git apply provas/ordem-caixa-janela-ci/remendo-ci-testes.yml.patch`. São dois passos e um artefacto no job
  `cliente`, a seguir à `caixa_jogadora`:
  1. a suite, com o log em `$RUNNER_TEMP/caixa-janela/`. Falha com erros de script, com uma verificação falhada (rc) ou
     se a suite não chegar à linha «N de N verificações passaram.»;
  2. a mutação (o guião abaixo). Depois, o `git diff` do ficheiro mutado tem de estar vazio;
  3. o artefacto **`caixa-janela`**, com os três logs.
- `ferramentas/mutacao-celulas.sh` — a prova de que o passo dispara. Muda só a cópia de trabalho, nunca se comete: as
  células da fila com id ímpar ficam 1 u mais largas. Corre a suite e exige rc ≠ 0, exactamente 9 falhas, todas do
  assert B6 (uma por medição: 8, 12 e 16 figuras × 1280×720, 844×390 e 780×360), «69 de 78» e 0 erros de script.
  Repõe o ficheiro e confere que o `git diff` ficou vazio.
- `local/` — as corridas no PC (Godot 4.7.2, Windows 11), à mão: `caixa_janela.gd.log` (78/78),
  `mutacao-celulas.log` (69/78, as 9 falhas da B6) e `mutacao-celulas.resumo.txt` (a saída do guião).
- `ensaio-passos/` — o corpo exacto dos dois passos, tirado do workflow remendado (`passo-suite.sh`,
  `passo-mutacao.sh`), corrido como o runner o corre (`bash -e`, com `GODOT` e `RUNNER_TEMP`). Os três logs são os que
  o artefacto `caixa-janela` vai levar: 78/78 e, com a mutação, 69/78. É um ensaio no PC, não uma corrida do CI.
