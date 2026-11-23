#!/bin/bash
R="<sede>/repo"; L="<sede>/tmp/suites"
G="<godot-472>/Godot_v4.7.2-stable_win64.exe"
: > "$L/resumo.txt"
cd "$R/rascunhos/servidor" && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" > "$L/servidor.log" 2>&1; echo "servidor exit=$?" >> "$L/resumo.txt"
cd "$R" && node provas/ordem-caixa/ferramentas/prova-servidor.mjs > "$L/prova-caixa.log" 2>&1; echo "prova-caixa exit=$?" >> "$L/resumo.txt"
cd "$R/rascunhos/servidor" && MOTOR_MJS="$R/bancada-rede/privado/motores.mjs" node --test --test-reporter=spec "testes-motor-real/*.test.mjs" > "$L/motor-real.log" 2>&1; echo "motor-real exit=$?" >> "$L/resumo.txt"
cd "$R/rascunhos/cliente"
for s in abrir_scripts rodar_testes abrir_mestre pecas_mestre medir_mestre hud_acoes caixa_jogadora caixa_janela canario_privacidade; do
  MESTRE_COMANDOS="<sede>/tmp/suites/comandos-$s.jsonl" timeout 300 "$G" --headless --path . -s res://testes/$s.gd > "$L/$s.log" 2>&1; e=$?
  echo "$s exit=$e scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$s.log")" >> "$L/resumo.txt"
done
echo FIM >> "$L/resumo.txt"
