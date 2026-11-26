#!/bin/bash
# As duas suites do Node que comparam bytes com ficheiros guardados (fixture do Mestre e vetores-ouro), numa árvore
# em LF como a do CI. Na cópia de trabalho do PC (core.autocrlf=true) os ficheiros guardados estão em CRLF e as duas
# falham só por isso (ver o ESTADO-FINAL, §4).
#
#   MOTOR_MJS=<motor privado> bash provas/ordem-d-aud-01-correccoes-4/suites-node-lf.sh
#
# Faz um worktree destacado em <sede>/tmp/lf no HEAD, com checkout em LF, corre as suites e tira o worktree.
set -u
R="$(git rev-parse --show-toplevel)"; B="$(cd "$R/.." && pwd)"; L="${L:-$B/tmp/suites}"; W="$B/tmp/lf"
M="${MOTOR_MJS:?MOTOR_MJS por definir}"
mkdir -p "$L"
cd "$R"
[ -d "$W" ] || git -c core.autocrlf=false worktree add -q --detach "$W" HEAD
H=$(git -C "$W" rev-parse --short HEAD)
echo "# worktree LF em $H: $(git -C "$W" ls-files --eol rascunhos/servidor/dados-exemplo/mesa-mestre.json | cut -c1-16)" > "$L/resumo-node-lf.txt"
echo "# comando: (worktree LF em <sede>/tmp/lf, $H) cd rascunhos/servidor && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec \"testes/*.test.mjs\"" > "$L/servidor-LF.log"
cd "$W/rascunhos/servidor" && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" >> "$L/servidor-LF.log" 2>&1; echo "servidor-LF exit=$?" >> "$L/resumo-node-lf.txt"
echo "# comando: (worktree LF em <sede>/tmp/lf, $H) cd rascunhos/servidor && MOTOR_MJS=<motor privado, fora do repo> node --test --test-reporter=spec \"testes-motor-real/*.test.mjs\"" > "$L/motor-real-LF.log"
MOTOR_MJS="$M" node --test --test-reporter=spec "testes-motor-real/*.test.mjs" >> "$L/motor-real-LF.log" 2>&1; echo "motor-real-LF exit=$?" >> "$L/resumo-node-lf.txt"
cd "$R" && git worktree remove --force "$W" && echo "worktree removido" >> "$L/resumo-node-lf.txt"
