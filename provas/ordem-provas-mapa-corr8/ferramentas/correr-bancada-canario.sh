#!/usr/bin/env bash
# ORDEM-PROVAS-MAPA-CORR8: a batalha de bancada da PROVAS-MAPA com o controlo positivo da sonda de privacidade. Corre:
#  - o servidor com as mensagens de teste e a escuta do fio (bancada-servidor-canario.mjs);
#  - a jogadora Godot (bancada_jogadora_canario.gd);
#  - o Mestre e o espectador da PROVAS-MAPA, SEM MUDANÇA (provas/ordem-mapa-jogavel/.../bancada-mestre.mjs). A sonda do
#    espectador tem de continuar limpa, porque as mensagens de teste só vão ao fio da heroína;
#  - no fim, a sonda Node sobre a escuta do fio (sonda-fio.mjs).
#   GODOT=<godot console> bash correr-bancada-canario.sh [porta]
# Os registos vão para a pasta de cima (provas/ordem-provas-mapa-corr8/).
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
OUT="$(cd "$AQUI/.." && pwd)"
REPO="$(cd "$AQUI/../../.." && pwd)"
MESTRE_JS="$REPO/provas/ordem-mapa-jogavel/provas-bancada/ferramentas/bancada-mestre.mjs"
PORTA="${1:-8792}"
: "${GODOT:?GODOT por definir}"
win() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }

node "$AQUI/bancada-servidor-canario.mjs" "$PORTA" "$(win "$OUT/escuta-jogadora.jsonl")" > "$OUT/bancada-servidor.log" 2>&1 &
SRV=$!
for i in $(seq 1 50); do grep -q pronto-bancada "$OUT/bancada-servidor.log" && break; sleep 0.2; done

(cd "$REPO/rascunhos/cliente" && timeout 400 "$GODOT" --headless --path . -s "$(win "$AQUI/bancada_jogadora_canario.gd")" -- \
  --servidor=127.0.0.1:$PORTA --json="$(win "$OUT/bancada-jogadora.json")") > "$OUT/bancada-jogadora.log" 2>&1 &
JOG=$!
for i in $(seq 1 300); do grep -q na-mesa-bancada "$OUT/bancada-jogadora.log" && break; sleep 0.2; done

MESTRE=0
node "$MESTRE_JS" "$PORTA" "$(win "$OUT/bancada-mestre.json")" > "$OUT/bancada-mestre.log" 2>&1 || MESTRE=$?
JOGADORA=0
wait $JOG || JOGADORA=$?
kill $SRV 2>/dev/null || true
FIO=0
node "$AQUI/sonda-fio.mjs" "$(win "$OUT/escuta-jogadora.jsonl")" "$(win "$OUT/sonda-fio.json")" > "$OUT/sonda-fio.log" 2>&1 || FIO=$?
ERROS=$(grep -cE "SCRIPT ERROR|Parse Error|Compile Error" "$OUT/bancada-jogadora.log")
echo "Mestre/espectador=$MESTRE jogadora=$JOGADORA sonda-do-fio=$FIO erros-de-script=$ERROS"
test "$MESTRE" -eq 0 && test "$JOGADORA" -eq 0 && test "$FIO" -eq 0 && test "$ERROS" -eq 0
