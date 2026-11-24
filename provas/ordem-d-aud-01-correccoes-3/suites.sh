#!/bin/bash
# Suites da ORDEM-D-AUD-01-CORRECCOES-3 (as mesmas da D-AUD-01-CORRECCOES-2). Cada log começa com a linha do comando.
B="<caminho do PC>"; R="$B/repo"; L="$B/tmp/suites"
G="<caminho do PC>"
M="<caminho do PC>"
: > "$L/resumo.txt"
echo "# comando: cd rascunhos/servidor && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec \"testes/*.test.mjs\"" > "$L/servidor.log"
cd "$R/rascunhos/servidor" && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" >> "$L/servidor.log" 2>&1; echo "servidor exit=$?" >> "$L/resumo.txt"
echo "# comando: node provas/ordem-caixa/ferramentas/prova-servidor.mjs" > "$L/prova-caixa.log"
cd "$R" && node provas/ordem-caixa/ferramentas/prova-servidor.mjs >> "$L/prova-caixa.log" 2>&1; echo "prova-caixa exit=$?" >> "$L/resumo.txt"
echo "# comando: cd rascunhos/servidor && MOTOR_MJS=<motor privado, fora do repo> node --test --test-reporter=spec \"testes-motor-real/*.test.mjs\"" > "$L/motor-real.log"
cd "$R/rascunhos/servidor" && MOTOR_MJS="$M" node --test --test-reporter=spec "testes-motor-real/*.test.mjs" >> "$L/motor-real.log" 2>&1; echo "motor-real exit=$?" >> "$L/resumo.txt"
cd "$R/rascunhos/cliente"
for s in abrir_scripts rodar_testes abrir_mestre pecas_mestre medir_mestre hud_acoes caixa_jogadora caixa_janela canario_privacidade; do
  echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/suites/comandos-$s.jsonl Godot_v4.7.2-stable_win64.exe --headless --path . -s res://testes/$s.gd" > "$L/$s.log"
  MESTRE_COMANDOS="$L/comandos-$s.jsonl" timeout 300 "$G" --headless --path . -s res://testes/$s.gd >> "$L/$s.log" 2>&1; e=$?
  echo "$s exit=$e scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$s.log")" >> "$L/resumo.txt"
done
cd "$R"
for s in pecas_mestre abrir_mestre; do
  echo "# comando: python rascunhos/protocolo/ferramentas/validar-mensagens.py <sede>/tmp/suites/comandos-$s.jsonl" > "$L/validar-mensagens-$s.log"
  python rascunhos/protocolo/ferramentas/validar-mensagens.py "$L/comandos-$s.jsonl" >> "$L/validar-mensagens-$s.log" 2>&1; echo "validar-$s exit=$?" >> "$L/resumo.txt"
done
echo FIM >> "$L/resumo.txt"
