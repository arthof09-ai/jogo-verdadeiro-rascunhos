#!/bin/bash
# Suites da ORDEM-PLANO-2-F1-F2-FECHO-4DEZ no PC (sem mutações: esta ordem não muda código do jogo).
#   GODOT=<Godot_v4.7.2-stable_win64_console.exe> [PYTHON=python] bash provas/ordem-plano-2-f1-f2-fecho-4dez/suites.sh
# Logs inteiros em provas/ordem-plano-2-f1-f2-fecho-4dez/suites/ (o caminho da sede trocado por <sede>);
# resumo.txt com o exit de cada uma. A camera_segue leva a mesma guarda N de N do passo do CI (patch da F3b).
R="$(cd "$(dirname "$0")/../.." && pwd)"; B="$(cd "$R/.." && pwd)"
L="$R/provas/ordem-plano-2-f1-f2-fecho-4dez/suites"; G="$GODOT"; P="${PYTHON:-python}"
mkdir -p "$L"; rm -f "$L"/*; : > "$L/resumo.txt"
echo "# commit: $(git -C "$R" rev-parse HEAD)" >> "$L/resumo.txt"
echo "# Godot: $("$G" --version 2>/dev/null | tail -1); node $(node --version)" >> "$L/resumo.txt"
cd "$R/rascunhos/cliente"
[ -d .godot/imported ] || timeout 600 "$G" --headless --path . --import > "$L/import.log" 2>&1
echo "# comando: cd rascunhos/servidor && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec \"testes/*.test.mjs\"" > "$L/servidor.log"
cd "$R/rascunhos/servidor" && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" >> "$L/servidor.log" 2>&1
echo "servidor exit=$? $(grep -E '^ℹ (tests|pass|fail) ' "$L/servidor.log" | tr '\n' ' ')" >> "$L/resumo.txt"
cd "$R/rascunhos/cliente"
for s in abrir_scripts rodar_testes abrir_mestre pecas_mestre medir_mestre hud_acoes caixa_jogadora caixa_janela canario_privacidade camera_segue aparelhos_f2; do
  echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/…/suites/comandos-$s.jsonl timeout 300 Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/$s.gd" > "$L/$s.log"
  MESTRE_COMANDOS="$L/comandos-$s.jsonl" timeout 300 "$G" --headless --path . -s res://testes/$s.gd >> "$L/$s.log" 2>&1; e=$?
  echo "$s exit=$e scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$s.log") fim=«$(tr -d '\r' < "$L/$s.log" | grep -E 'passaram|falhas|falharam' | tail -1)»" >> "$L/resumo.txt"
done
# a guarda N de N da camera_segue, como no passo do CI
FINAL=$(tr -d '\r' < "$L/camera_segue.log" | grep -E "^[0-9]+ de [0-9]+ verificações passaram\.$" || true)
N=$(printf '%s\n' "$FINAL" | grep -c . || true); read -r PASSOU _ TOTAL _ <<< "$FINAL"
if [ "$N" = 1 ] && [ "${TOTAL:-0}" -gt 0 ] && [ "$PASSOU" = "$TOTAL" ]; then echo "camera_segue guarda N de N: $PASSOU de $TOTAL ok" >> "$L/resumo.txt"; else echo "camera_segue guarda N de N: FALHA ($N linhas; «$FINAL»)" >> "$L/resumo.txt"; fi
cd "$R"
for s in pecas_mestre abrir_mestre; do
  echo "# comando: python rascunhos/protocolo/ferramentas/validar-mensagens.py <sede>/…/suites/comandos-$s.jsonl" > "$L/validar-mensagens-$s.log"
  "$P" rascunhos/protocolo/ferramentas/validar-mensagens.py "$L/comandos-$s.jsonl" >> "$L/validar-mensagens-$s.log" 2>&1; echo "validar-$s exit=$?" >> "$L/resumo.txt"
done
rm -f "$L"/comandos-*.jsonl
sed -i -e "s|$B|<sede>|g" -e "s|$(cygpath -m "$B" 2>/dev/null || echo "$B")|<sede>|g" -e "s|$(cygpath -w "$B" 2>/dev/null | sed 's|\|\\|g' || echo "$B")|<sede>|g" "$L"/*.log
echo FIM >> "$L/resumo.txt"
