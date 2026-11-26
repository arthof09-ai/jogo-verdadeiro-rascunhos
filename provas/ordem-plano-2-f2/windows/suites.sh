#!/bin/bash
# Suites da ORDEM-PLANO-2-F2-PROVA-WINDOWS: as da D-AUD-01-CORRECCOES-4 (provas/ordem-d-aud-01-correccoes-4/suites.sh,
# sem a mutação do B1, que é dessa ordem) mais o aparelhos_f2.gd da F2. Logs inteiros, com a linha do comando e o
# exit no resumo.txt.
#
#   GODOT=<Godot_v4.7.2-stable_win64_console.exe> MOTOR_MJS=<motor privado> [PYTHON=<python com jsonschema>] bash provas/ordem-plano-2-f2/windows/suites.sh
#
# Os logs vão para $L (por omissão <sede>/tmp/suites, ao lado do repo). Na escrita dos logs, o caminho da máquina sai
# como <sede>.
set -u
R="$(git rev-parse --show-toplevel)"; B="$(cd "$R/.." && pwd)"; L="${L:-$B/tmp/suites}"
G="${GODOT:?GODOT por definir}"; M="${MOTOR_MJS:?MOTOR_MJS por definir}"; P="${PYTHON:-python}"
mkdir -p "$L"
: > "$L/resumo.txt"
# ---- as suites, sobre o código da ponta ----
echo "# comando: cd rascunhos/servidor && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec \"testes/*.test.mjs\"" > "$L/servidor.log"
cd "$R/rascunhos/servidor" && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" >> "$L/servidor.log" 2>&1; echo "servidor exit=$?" >> "$L/resumo.txt"
echo "# comando: node provas/ordem-caixa/ferramentas/prova-servidor.mjs" > "$L/prova-caixa.log"
cd "$R" && node provas/ordem-caixa/ferramentas/prova-servidor.mjs >> "$L/prova-caixa.log" 2>&1; echo "prova-caixa exit=$?" >> "$L/resumo.txt"
echo "# comando: cd rascunhos/servidor && MOTOR_MJS=<motor privado, fora do repo> node --test --test-reporter=spec \"testes-motor-real/*.test.mjs\"" > "$L/motor-real.log"
cd "$R/rascunhos/servidor" && MOTOR_MJS="$M" node --test --test-reporter=spec "testes-motor-real/*.test.mjs" >> "$L/motor-real.log" 2>&1; echo "motor-real exit=$?" >> "$L/resumo.txt"
cd "$R/rascunhos/cliente"
for s in aparelhos_f2 abrir_scripts rodar_testes abrir_mestre pecas_mestre medir_mestre hud_acoes caixa_jogadora caixa_janela canario_privacidade; do
  echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/suites/comandos-$s.jsonl timeout 300 Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/$s.gd" > "$L/$s.log"
  MESTRE_COMANDOS="$L/comandos-$s.jsonl" timeout 300 "$G" --headless --path . -s res://testes/$s.gd >> "$L/$s.log" 2>&1; e=$?
  echo "$s exit=$e scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$s.log")" >> "$L/resumo.txt"
done
cd "$R"
for s in pecas_mestre abrir_mestre; do
  echo "# comando: python rascunhos/protocolo/ferramentas/validar-mensagens.py <sede>/tmp/suites/comandos-$s.jsonl" > "$L/validar-mensagens-$s.log"
  "$P" rascunhos/protocolo/ferramentas/validar-mensagens.py "$L/comandos-$s.jsonl" >> "$L/validar-mensagens-$s.log" 2>&1; echo "validar-$s exit=$?" >> "$L/resumo.txt"
done
echo FIM >> "$L/resumo.txt"
