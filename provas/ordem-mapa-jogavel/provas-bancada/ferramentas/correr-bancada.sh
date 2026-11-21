#!/usr/bin/env bash
# ORDEM PROVAS-MAPA (prova 2): a batalha de bancada — servidor Node (WebSocket) + jogadora Godot (arena real, sem
# janela) + Mestre e espectador em Node. Grelha-mapa; escala 1,5 → 1 → 2 m a meio.
# ORDEM-F2: o servidor escuta SEMPRE o fio da heroína (escuta-jogadora.jsonl); a corrida provoca uma escala recusada do
# Mestre (3 m) e um pedido de escala da jogadora; no fim, a sonda do fio (sonda-fio.mjs) varre a escuta — «fora: 0
# achados», as linhas 3 e 4 do contrato, o ROOM_PAUSED e a cronologia (sonda-fio.log / sonda-fio.json).
#   GODOT=<godot console> bash correr-bancada.sh [porta] [pasta-de-saida]
# Os registos vão para a pasta de cima (provas-bancada/bancada-*.log / *.json), ou para a pasta dada (ORDEM-F2: para
# não pisar os registos da primeira corrida, que o comparador da CORR9 usa como referência).
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
OUT="${2:-$AQUI/..}"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
REPO="$(cd "$AQUI/../../../.." && pwd)"
PORTA="${1:-8791}"
: "${GODOT:?GODOT por definir}"
win() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }

node "$AQUI/bancada-servidor.mjs" "$PORTA" "$(win "$OUT/escuta-jogadora.jsonl")" > "$OUT/bancada-servidor.log" 2>&1 &
SRV=$!
for i in $(seq 1 50); do grep -q pronto-bancada "$OUT/bancada-servidor.log" && break; sleep 0.2; done

(cd "$REPO/rascunhos/cliente" && timeout 400 "$GODOT" --headless --path . -s "$(win "$AQUI/bancada_jogadora_mapa.gd")" -- \
  --servidor=127.0.0.1:$PORTA --json="$(win "$OUT/bancada-jogadora.json")") > "$OUT/bancada-jogadora.log" 2>&1 &
JOG=$!
for i in $(seq 1 300); do grep -q na-mesa-bancada "$OUT/bancada-jogadora.log" && break; sleep 0.2; done

MESTRE=0
node "$AQUI/bancada-mestre.mjs" "$PORTA" "$OUT/bancada-mestre.json" > "$OUT/bancada-mestre.log" 2>&1 || MESTRE=$?
JOGADORA=0
wait $JOG || JOGADORA=$?
kill $SRV 2>/dev/null || true
FIO=0
node "$AQUI/sonda-fio.mjs" "$(win "$OUT/escuta-jogadora.jsonl")" "$(win "$OUT/sonda-fio.json")" > "$OUT/sonda-fio.log" 2>&1 || FIO=$?
ERROS=$(grep -cE "SCRIPT ERROR|Parse Error|Compile Error" "$OUT/bancada-jogadora.log")
echo "Mestre/espectador=$MESTRE jogadora=$JOGADORA sonda-do-fio=$FIO erros-de-script=$ERROS"
test "$MESTRE" -eq 0 && test "$JOGADORA" -eq 0 && test "$FIO" -eq 0 && test "$ERROS" -eq 0
