#!/bin/bash
# Suites da ORDEM-D-AUD-01-CORRECCOES-4 (as mesmas da D-AUD-01-CORRECCOES-3) e, antes delas, a mutação do B1 pelo
# MESMO caminho (B3 da sentença 930): MESTRE_COMANDOS + timeout 300, log com a linha do comando, exit no resumo.txt.
#
#   GODOT=<Godot_v4.7.2-stable_win64_console.exe> MOTOR_MJS=<motor privado> [PYTHON=<python com jsonschema>] bash provas/ordem-d-aud-01-correccoes-4/suites.sh
#
# Corre a partir de qualquer pasta dentro do repositório. Os logs vão para $L (por omissão <sede>/tmp/suites, ao lado
# do repo). Na escrita dos logs, o caminho da máquina sai como <sede>.
set -u
R="$(git rev-parse --show-toplevel)"; B="$(cd "$R/.." && pwd)"; L="${L:-$B/tmp/suites}"
G="${GODOT:?GODOT por definir}"; M="${MOTOR_MJS:?MOTOR_MJS por definir}"; P="${PYTHON:-python}"  # PYTHON: um python com jsonschema
mkdir -p "$L"
: > "$L/resumo.txt"

# ---- B1: a mutação (só na cópia de trabalho; reposta com git checkout, mesmo se algo falhar) ----
ALVO=rascunhos/cliente/cenas/mestre/aba_agir.gd
ORIGINAL='	if a_mover and not tem_mover:'
MUTADA='	if false and a_mover and not tem_mover:  # MUTACAO (D-AUD-01-CORRECCOES-4): sem o desarme do B1'
cd "$R"
conta() { tr -d '\r' < "$ALVO" | grep -cxF "$1"; }
if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO já tem alterações por cometer"; exit 1; fi
if [ "$(conta "$ORIGINAL")" != "1" ]; then echo "PARAR: a linha a mutar não está (uma vez) em $ALVO"; exit 1; fi
trap 'cd "$R" && git checkout -- "$ALVO"' EXIT
sed -i "s|^	if a_mover and not tem_mover:\(\r\?\)\$|$MUTADA\1|" "$ALVO"
if [ "$(conta "$MUTADA")" != "1" ] || [ "$(conta "$ORIGINAL")" != "0" ]; then echo "PARAR: a mutação não ficou feita"; exit 1; fi
s=pecas_mestre; n=pecas_mestre-SEM-B1
{ echo "# comando: (mutação: em $ALVO, «if a_mover and not tem_mover:» → «if false and a_mover and not tem_mover:»; reposta com git checkout)"
  echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/suites/comandos-$n.jsonl timeout 300 Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/$s.gd"
  git diff -U0 -- "$ALVO" | grep -E '^[-+][^-+]' | sed 's/^/# diff: /'; } > "$L/$n.log"
cd "$R/rascunhos/cliente"
MESTRE_COMANDOS="$L/comandos-$n.jsonl" timeout 300 "$G" --headless --path . -s res://testes/$s.gd >> "$L/$n.log" 2>&1; e=$?
cd "$R" && git checkout -- "$ALVO" && trap - EXIT
if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO não ficou reposto"; exit 1; fi
echo "$n exit=$e falhas=$(grep -c '  FALHA ' "$L/$n.log") falhas-correccoes-4=$(grep -c '  FALHA D-AUD-01-CORRECCOES-4:' "$L/$n.log") scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$n.log") reposto=$(git diff --quiet -- "$ALVO" && echo sim || echo NAO)" >> "$L/resumo.txt"

# ---- as suites, sobre o código da ponta ----
echo "# comando: cd rascunhos/servidor && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec \"testes/*.test.mjs\"" > "$L/servidor.log"
cd "$R/rascunhos/servidor" && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" >> "$L/servidor.log" 2>&1; echo "servidor exit=$?" >> "$L/resumo.txt"
echo "# comando: node provas/ordem-caixa/ferramentas/prova-servidor.mjs" > "$L/prova-caixa.log"
cd "$R" && node provas/ordem-caixa/ferramentas/prova-servidor.mjs >> "$L/prova-caixa.log" 2>&1; echo "prova-caixa exit=$?" >> "$L/resumo.txt"
echo "# comando: cd rascunhos/servidor && MOTOR_MJS=<motor privado, fora do repo> node --test --test-reporter=spec \"testes-motor-real/*.test.mjs\"" > "$L/motor-real.log"
cd "$R/rascunhos/servidor" && MOTOR_MJS="$M" node --test --test-reporter=spec "testes-motor-real/*.test.mjs" >> "$L/motor-real.log" 2>&1; echo "motor-real exit=$?" >> "$L/resumo.txt"
cd "$R/rascunhos/cliente"
for s in abrir_scripts rodar_testes abrir_mestre pecas_mestre medir_mestre hud_acoes caixa_jogadora caixa_janela canario_privacidade; do
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
