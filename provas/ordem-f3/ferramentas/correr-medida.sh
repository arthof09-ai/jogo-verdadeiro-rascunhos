#!/usr/bin/env bash
# MEDIÇÃO F3: N corridas da batalha de bancada (servidor + jogadora + Mestre), sem as provas do terreno.
#   GODOT=... bash correr-medida.sh <script-jogadora.gd> <pasta> <N> [porta]
set -u
REPO=/c/Users/txcga/RPG_Local/jogo-verdadeiro/ordem-f3/repo
PM="$REPO/provas/ordem-mapa-jogavel/provas-bancada/ferramentas"
JS="$1"; BASE="$2"; N="$3"; PORTA="${4:-8811}"
win() { cygpath -m "$1"; }
for k in $(seq 1 "$N"); do
  OUT="$BASE/c$k"; mkdir -p "$OUT"
  node "$PM/bancada-servidor.mjs" "$PORTA" "$(win "$OUT/escuta-jogadora.jsonl")" > "$OUT/bancada-servidor.log" 2>&1 &
  SRV=$!
  for i in $(seq 1 50); do grep -q pronto-bancada "$OUT/bancada-servidor.log" && break; sleep 0.2; done
  (cd "$REPO/rascunhos/cliente" && timeout 400 "$GODOT" ${GARGS:-} --headless --path . -s "$(win "$JS")" -- \
    --servidor=127.0.0.1:$PORTA --json="$(win "$OUT/bancada-jogadora.json")") > "$OUT/bancada-jogadora.log" 2>&1 &
  JOG=$!
  for i in $(seq 1 300); do grep -q na-mesa-bancada "$OUT/bancada-jogadora.log" && break; sleep 0.2; done
  M=0; node "$PM/bancada-mestre.mjs" "$PORTA" "$OUT/bancada-mestre.json" > "$OUT/bancada-mestre.log" 2>&1 || M=$?
  J=0; wait $JOG || J=$?
  kill $SRV 2>/dev/null; wait $SRV 2>/dev/null
  D=$(node -e "const d=require('$(win "$OUT/bancada-jogadora.json")');console.log(d.fases.map(f=>Object.values(f.figuras).filter(x=>x.quem!=='orc').map(x=>f.casaM+'m noXZ='+x.noXZ+' desvio='+(x.desvioXZ||'-')).join('')).join(' | '))")
  echo "corrida $k: mestre=$M jogadora=$J | $D | $(grep MEDIDA "$OUT/bancada-jogadora.log" | tr '\n' ' ')"
done
