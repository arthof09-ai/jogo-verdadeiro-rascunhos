#!/bin/bash
# Suites da ORDEM-D-AUD-01-CORRECCOES-6 sobre o código final (J8 + J4 + J1), com três mutações antes (muta.sh):
#   - SEM-REFRESCO: o J1 tirou a linha que a mutação da CORRECCOES-5 mutava («if novas != _casas:»). O equivalente
#     no código novo é não trocar as casas: «_casas = novas» → «novas = _casas» (o destaque continua a ser reposto,
#     mas com as casas velhas). Tem de falhar SÓ o teste da CORRECCOES-5 (a casa que entrou engolida: `[]`).
#   - SEM-J1: repõe o bloco da CORRECCOES-5 («if novas != _casas:» com as duas linhas dentro). Tem de falhar SÓ o
#     teste novo do J1.
#   - SEM-B1: a da CORRECCOES-4, com o mesmo texto. Têm de falhar as 2 da CORRECCOES-4 e a do B2.
#
#   GODOT=<Godot_v4.7.2-stable_win64_console.exe> [MOTOR_MJS=<motor privado>] [PYTHON=<python com jsonschema>] \
#     L=<pasta dos logs> bash provas/ordem-d-aud-01-correccoes-6/suites.sh
# Sem MOTOR_MJS o motor real não corre aqui (fica «motor-real SALTOU» no resumo; o CI corre-o no job motor-real).
. "$(dirname "$0")/muta.sh"
M="${MOTOR_MJS:-}"
: > "$L/resumo.txt"
cd "$R"
echo "# commit: $(git rev-parse HEAD)" >> "$L/resumo.txt"
muta pecas_mestre-SEM-REFRESCO '		_casas = novas' '		novas = _casas  # MUTACAO (D-AUD-01-CORRECCOES-6): sem o refresco das casas'
muta pecas_mestre-SEM-J1 $'\t\tvar novas := _casas_de(op)\n\t\t_casas = novas\n\t\tmestre.destacar(_casas)' $'\t\tvar novas := _casas_de(op)\n\t\tif novas != _casas:  # MUTACAO (D-AUD-01-CORRECCOES-6): sem o J1\n\t\t\t_casas = novas\n\t\t\tmestre.destacar(_casas)'
muta pecas_mestre-SEM-B1 '	if a_mover and not tem_mover:' '	if false and a_mover and not tem_mover:  # MUTACAO (D-AUD-01-CORRECCOES-4): sem o desarme do B1'

# ---- as suites, sobre o código da ponta ----
echo "# comando: cd rascunhos/servidor && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec \"testes/*.test.mjs\"" > "$L/servidor.log"
cd "$R/rascunhos/servidor" && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" >> "$L/servidor.log" 2>&1; echo "servidor exit=$?" >> "$L/resumo.txt"
echo "# comando: node provas/ordem-caixa/ferramentas/prova-servidor.mjs" > "$L/prova-caixa.log"
cd "$R" && node provas/ordem-caixa/ferramentas/prova-servidor.mjs >> "$L/prova-caixa.log" 2>&1; echo "prova-caixa exit=$?" >> "$L/resumo.txt"
if [ -n "$M" ]; then
  echo "# comando: cd rascunhos/servidor && MOTOR_MJS=<motor privado, fora do repo> node --test --test-reporter=spec \"testes-motor-real/*.test.mjs\"" > "$L/motor-real.log"
  cd "$R/rascunhos/servidor" && MOTOR_MJS="$M" node --test --test-reporter=spec "testes-motor-real/*.test.mjs" >> "$L/motor-real.log" 2>&1; echo "motor-real exit=$?" >> "$L/resumo.txt"
else
  echo "motor-real SALTOU (sem MOTOR_MJS neste PC; corre no CI, job motor-real)" >> "$L/resumo.txt"
fi
cd "$R/rascunhos/cliente"
for s in abrir_scripts rodar_testes abrir_mestre pecas_mestre medir_mestre hud_acoes caixa_jogadora caixa_janela canario_privacidade; do
  echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/suites/comandos-$s.jsonl timeout 300 Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/$s.gd" > "$L/$s.log"
  MESTRE_COMANDOS="$L/comandos-$s.jsonl" timeout 300 "$G" --headless --path . -s res://testes/$s.gd >> "$L/$s.log" 2>&1; e=$?
  echo "$s exit=$e scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$s.log") fim=«$(grep -E 'passaram|falhas' "$L/$s.log" | tail -1)»" >> "$L/resumo.txt"
done
cd "$R"
for s in pecas_mestre abrir_mestre; do
  echo "# comando: python rascunhos/protocolo/ferramentas/validar-mensagens.py <sede>/tmp/suites/comandos-$s.jsonl" > "$L/validar-mensagens-$s.log"
  "$P" rascunhos/protocolo/ferramentas/validar-mensagens.py "$L/comandos-$s.jsonl" >> "$L/validar-mensagens-$s.log" 2>&1; echo "validar-$s exit=$?" >> "$L/resumo.txt"
done
redigir
echo FIM >> "$L/resumo.txt"
