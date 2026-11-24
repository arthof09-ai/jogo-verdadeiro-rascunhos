#!/usr/bin/env bash
# ORDEM-F3 (24/11, sobre a ponta da linha): N corridas da batalha de bancada (servidor + jogadora + Mestre), sem as
# provas do terreno, com uma de duas jogadoras:
#   padrao — a bancada da linha tal como está (bancada_jogadora_mapa.gd, com a espera dos nós quietos);
#   sem    — a MESMA bancada com QUIETO_FRAMES := 1, gerada aqui por sed numa pasta temporária: com 1 leitura, o
#            `_esperar_quietos` sai logo na 1.ª volta, por isso lê a posição no frame em que o «assente» a aceitou —
#            o comportamento de antes do conserto de 21/11 (73975d6). O registo `quietos` traz o resto nesse frame.
#   GODOT=... [GARGS="--fixed-fps 3001"] bash medir-ponta.sh <padrao|sem> <pasta> <N> [porta]
# Uma linha por corrida: as saídas, o desvio da heroína a 1 m e a 2 m e os restos que o `quietos` apanhou.
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$AQUI/../../.." && pwd)"
PM="$REPO/provas/ordem-mapa-jogavel/provas-bancada/ferramentas"
MODO="$1"; BASE="$2"; N="$3"; PORTA="${4:-8811}"
: "${GODOT:?GODOT por definir}"
win() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
mkdir -p "$BASE"; BASE="$(cd "$BASE" && pwd)"
case "$MODO" in
  padrao) JS="$PM/bancada_jogadora_mapa.gd" ;;
  sem)    JS="$BASE/bancada_jogadora_mapa_sem_quietos.gd"
          sed 's/^const QUIETO_FRAMES := 3 /const QUIETO_FRAMES := 1 /' "$PM/bancada_jogadora_mapa.gd" > "$JS"
          grep -q '^const QUIETO_FRAMES := 1 ' "$JS" || { echo "o sed não apanhou QUIETO_FRAMES"; exit 2; } ;;
  *) echo "modo: padrao|sem"; exit 2 ;;
esac
for k in $(seq 1 "$N"); do
  OUT="$BASE/c$k"; mkdir -p "$OUT"
  node "$PM/bancada-servidor.mjs" "$PORTA" "$(win "$OUT/escuta-jogadora.jsonl")" > "$OUT/bancada-servidor.log" 2>&1 &
  SRV=$!
  for i in $(seq 1 50); do grep -qs pronto-bancada "$OUT/bancada-servidor.log" && break; sleep 0.2; done
  (cd "$REPO/rascunhos/cliente" && timeout 400 "$GODOT" ${GARGS:-} --headless --path . -s "$(win "$JS")" -- \
    --servidor=127.0.0.1:$PORTA --json="$(win "$OUT/bancada-jogadora.json")") > "$OUT/bancada-jogadora.log" 2>&1 &
  JOG=$!
  for i in $(seq 1 300); do grep -qs na-mesa-bancada "$OUT/bancada-jogadora.log" && break; sleep 0.2; done
  M=0; node "$PM/bancada-mestre.mjs" "$PORTA" "$(win "$OUT/bancada-mestre.json")" > "$OUT/bancada-mestre.log" 2>&1 || M=$?
  J=0; wait $JOG || J=$?
  kill $SRV 2>/dev/null; wait $SRV 2>/dev/null
  D=$(node "$AQUI/resumir-jogadora.mjs" "$(win "$OUT/bancada-jogadora.json")")
  echo "corrida $k: mestre=$M jogadora=$J $(grep -h 'verificações passaram' "$OUT/bancada-jogadora.log" | sed 's/bancada da jogadora: //') | $D"
done
