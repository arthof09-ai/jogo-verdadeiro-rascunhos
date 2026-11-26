#!/bin/bash
# ORDEM-D-AUD-01-CORRECCOES-5, passo 4 (E1): depois de reforçar o teste (b), correr outra vez o `pecas_mestre`
# (tem de dar 334/334) e a mutação do B1 da CORRECCOES-4 (tem de dar 332/334, só as duas da CORRECCOES-4 a falhar).
# Corre sobre o commit da E1, ANTES das mudanças de código desta ordem (passos 1, 2, 3 e 5).
#
#   GODOT=<Godot_v4.7.2-stable_win64_console.exe> bash provas/ordem-d-aud-01-correccoes-5/e1.sh
#
# Os logs vão para $L (por omissão <sede>/tmp/e1). Na escrita dos logs, o caminho da máquina sai como <sede>.
set -u
R="$(git rev-parse --show-toplevel)"; B="$(cd "$R/.." && pwd)"; L="${L:-$B/tmp/e1}"
G="${GODOT:?GODOT por definir}"
mkdir -p "$L"
: > "$L/resumo.txt"
cd "$R"
echo "# commit: $(git rev-parse HEAD)" >> "$L/resumo.txt"
ALVO=rascunhos/cliente/cenas/mestre/aba_agir.gd
conta() { tr -d '\r' < "$ALVO" | grep -cxF "$1"; }
corre() {  # $1 = nome do log
  { echo "# commit: $(git -C "$R" rev-parse HEAD)"
    echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/e1/comandos-$1.jsonl timeout 300 Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/pecas_mestre.gd"
    git -C "$R" diff -U0 -- "$ALVO" | grep -E '^[-+][^-+]' | sed 's/^/# diff: /'; } > "$L/$1.log"
  (cd "$R/rascunhos/cliente" && MESTRE_COMANDOS="$L/comandos-$1.jsonl" timeout 300 "$G" --headless --path . -s res://testes/pecas_mestre.gd >> "$L/$1.log" 2>&1); e=$?
  echo "$1 exit=$e ok=$(grep -c '^  ok ' "$L/$1.log") falhas=$(grep -c '  FALHA ' "$L/$1.log") falhas-correccoes-4=$(grep -c '  FALHA D-AUD-01-CORRECCOES-4:' "$L/$1.log") scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$1.log") fim=«$(grep -E "verificações passaram" "$L/$1.log" | tail -1)»" >> "$L/resumo.txt"
}
if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO já tem alterações por cometer"; exit 1; fi
corre pecas_mestre
ORIGINAL='	if a_mover and not tem_mover:'
MUTADA='	if false and a_mover and not tem_mover:  # MUTACAO (D-AUD-01-CORRECCOES-4): sem o desarme do B1'
if [ "$(conta "$ORIGINAL")" != "1" ]; then echo "PARAR: a linha a mutar não está (uma vez) em $ALVO"; exit 1; fi
trap 'cd "$R" && git checkout -- "$ALVO"' EXIT
sed -i "s|^	if a_mover and not tem_mover:\(\r\?\)\$|$MUTADA\1|" "$ALVO"
if [ "$(conta "$MUTADA")" != "1" ] || [ "$(conta "$ORIGINAL")" != "0" ]; then echo "PARAR: a mutação não ficou feita"; exit 1; fi
corre pecas_mestre-SEM-B1
cd "$R" && git checkout -- "$ALVO" && trap - EXIT
echo "reposto=$(git diff --quiet -- "$ALVO" && echo sim || echo NAO)" >> "$L/resumo.txt"
sed -i "s|$B|<sede>|g" "$L"/*.log
echo FIM >> "$L/resumo.txt"
