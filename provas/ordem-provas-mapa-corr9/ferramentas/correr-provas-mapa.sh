#!/usr/bin/env bash
# ORDEM PROVAS-MAPA-CORR9: as provas do mapa da ORDEM-PROVAS-MAPA, de ponta a ponta, numa pasta de saída à escolha
# (para se poderem repetir sem pisar os registos da primeira corrida, e para o CI):
#   prova 1a — a ferramenta original  res://cenas/arena/ferramentas/provar_terreno_servidor.gd   (18 grelhas)
#   prova 1b — a cópia adaptada       provas/ordem-mapa-jogavel/provas-bancada/ferramentas/provar_terreno_servidor_mapa.gd
#   prova 2  — a batalha de bancada   servidor Node (WebSocket) + jogadora Godot + Mestre e espectador Node
# Usa as ferramentas da ORDEM-PROVAS-MAPA tal como estão (nenhuma é copiada nem mudada); só a pasta de saída muda.
# ORDEM-F2: a prova 2 segue o correr-bancada.sh — a escuta do fio no servidor e, no fim, a sonda do fio (sonda-fio.mjs).
#   GODOT=<godot console> bash correr-provas-mapa.sh <pasta-de-saida> [porta]
# Precisa do projecto do cliente importado (godot --headless --path rascunhos/cliente --import) e do Node no PATH.
# Sai com 0 se as três passam.
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$AQUI/../../.." && pwd)"
PM="$REPO/provas/ordem-mapa-jogavel/provas-bancada/ferramentas"
OUT="${1:?pasta de saída}"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
PORTA="${2:-8793}"
: "${GODOT:?GODOT por definir}"
win() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
agora() { date +%Y-%m-%dT%H:%M:%S%z; }
CLI="$REPO/rascunhos/cliente"

terreno() {  # $1 = rótulo, $2 = script (res:// ou caminho absoluto), $3 = json
  local LOG="$OUT/provar-terreno-servidor$1.log" R=0
  { echo "# início: $(agora)"; } > "$LOG"
  (cd "$CLI" && timeout 900 "$GODOT" --headless --path . -s "$2" -- --json="$(win "$3")") >> "$LOG" 2>&1 || R=$?
  { echo "# código de saída: $R"; echo "# fim: $(agora)"; } >> "$LOG"
  return $R
}

T1=0; terreno "" "res://cenas/arena/ferramentas/provar_terreno_servidor.gd" "$OUT/terreno-servidor-arena.json" || T1=$?
T2=0; terreno "-adaptada" "$(win "$PM/provar_terreno_servidor_mapa.gd")" "$OUT/terreno-servidor-arena-adaptada.json" || T2=$?

# prova 2: o mesmo encadeamento de correr-bancada.sh, com os registos em $OUT
echo "# início: $(agora)" > "$OUT/bancada-tempos.log"
node "$PM/bancada-servidor.mjs" "$PORTA" "$(win "$OUT/escuta-jogadora.jsonl")" > "$OUT/bancada-servidor.log" 2>&1 &
SRV=$!
for i in $(seq 1 50); do grep -q pronto-bancada "$OUT/bancada-servidor.log" && break; sleep 0.2; done
(cd "$CLI" && timeout 400 "$GODOT" --headless --path . -s "$(win "$PM/bancada_jogadora_mapa.gd")" -- \
  --servidor=127.0.0.1:$PORTA --json="$(win "$OUT/bancada-jogadora.json")") > "$OUT/bancada-jogadora.log" 2>&1 &
JOG=$!
for i in $(seq 1 300); do grep -q na-mesa-bancada "$OUT/bancada-jogadora.log" && break; sleep 0.2; done
MESTRE=0
node "$PM/bancada-mestre.mjs" "$PORTA" "$OUT/bancada-mestre.json" > "$OUT/bancada-mestre.log" 2>&1 || MESTRE=$?
JOGADORA=0
wait $JOG || JOGADORA=$?
kill $SRV 2>/dev/null || true
echo "# fim: $(agora)" >> "$OUT/bancada-tempos.log"
FIO=0
node "$PM/sonda-fio.mjs" "$(win "$OUT/escuta-jogadora.jsonl")" "$(win "$OUT/sonda-fio.json")" > "$OUT/sonda-fio.log" 2>&1 || FIO=$?
ERROS=$(cat "$OUT"/provar-terreno-servidor*.log "$OUT/bancada-jogadora.log" | grep -cE "SCRIPT ERROR|Parse Error|Compile Error")
echo "terreno-original=$T1 terreno-adaptada=$T2 Mestre/espectador=$MESTRE jogadora=$JOGADORA sonda-do-fio=$FIO erros-de-script=$ERROS" | tee "$OUT/resultado.txt"
grep -E "^  (ok|FALHA)|PASSOU|FALHAS" "$OUT/sonda-fio.log" | sed 's/^/[sonda-do-fio] /'
test "$T1" -eq 0 && test "$T2" -eq 0 && test "$MESTRE" -eq 0 && test "$JOGADORA" -eq 0 && test "$FIO" -eq 0 && test "$ERROS" -eq 0
