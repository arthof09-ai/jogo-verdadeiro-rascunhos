set -o pipefail
mkdir -p "$RUNNER_TEMP/caixa-janela"
L="$RUNNER_TEMP/caixa-janela/caixa_janela.gd.log"
timeout 120 "$GODOT" --headless --path . -s res://testes/caixa_janela.gd 2>&1 | tee "$L"
! grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$L"
# A suite tem de chegar ao fim (a linha «N de N verificações passaram.», com os dois números iguais).
grep -E "^([0-9]+) de \1 verificações passaram\.$" "$L"
