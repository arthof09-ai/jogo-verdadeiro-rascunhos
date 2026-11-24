#!/usr/bin/env bash
# ORDEM-F3 (24/11, sobre a ponta da linha): 5 vezes seguidas — a bancada padrão (correr-bancada.sh) + o guião do CI
# (correr-provas-mapa.sh) e o comparador da CORR9 contra a primeira corrida (o passo «Repetição» do CI, à letra).
# Os caminhos saem da pasta deste guião (o cinco-seguidas.sh de 21/11 tinha-os fixos para o clone de então).
#   GODOT=<godot> bash cinco-seguidas-ponta.sh <pasta-de-trabalho> [porta-bancada] [porta-ci]
# Uma linha de resumo por passo; no fim, «5/5» se as cinco deram tudo verde e REPETE-SE.
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$AQUI/../../.." && pwd)"
BASE="${1:?pasta de trabalho}"; mkdir -p "$BASE"; BASE="$(cd "$BASE" && pwd)"
PB="${2:-8821}"; PC="${3:-8822}"
: "${GODOT:?GODOT por definir}"
win() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
cd "$REPO"
echo "# ponta $(git rev-parse HEAD) · $("$GODOT" --version 2>/dev/null | tr -d '\r') · node $(node --version) · $(date '+%F %z')"
BOAS=0
for k in 1 2 3 4 5; do
  O="$BASE/r$k"; mkdir -p "$O"
  echo "== corrida $k — início $(date +%T)"
  B=0; bash provas/ordem-mapa-jogavel/provas-bancada/ferramentas/correr-bancada.sh "$PB" "$O/bancada" > "$O/bancada.out" 2>&1 || B=$?
  echo "   bancada padrão: saída $B — $(tail -1 "$O/bancada.out") — $(grep -h 'verificações passaram' "$O/bancada/bancada-jogadora.log") — sonda do fio: $(grep -hoE 'TUDO PASSOU|[0-9]+ FALHAS?' "$O/bancada/sonda-fio.log" | head -1)"
  C=0; bash provas/ordem-provas-mapa-corr9/ferramentas/correr-provas-mapa.sh "$O/ci" "$PC" > "$O/ci.out" 2>&1 || C=$?
  echo "   guião do CI: saída $C — $(grep terreno-original "$O/ci.out") — $(grep -h 'verificações passaram' "$O/ci/bancada-jogadora.log")"
  R=0; node provas/ordem-provas-mapa-corr9/ferramentas/comparar-corridas.mjs --md="$O/repeticao.md" primeira=provas/ordem-mapa-jogavel/provas-bancada ci="$O/ci" > "$O/repeticao.out" 2>&1 || R=$?
  sed -i "s|$O/ci|$(basename "$BASE")/r$k/ci|g" "$O/repeticao.md"  # redigir o caminho absoluto do PC no gerado
  echo "   comparador: saída $R — $(tail -1 "$O/repeticao.out")"
  echo "   bancada padrão: $(node "$AQUI/resumir-jogadora.mjs" "$(win "$O/bancada/bancada-jogadora.json")")"
  echo "   guião do CI:    $(node "$AQUI/resumir-jogadora.mjs" "$(win "$O/ci/bancada-jogadora.json")")"
  if [ "$B" -eq 0 ] && [ "$C" -eq 0 ] && [ "$R" -eq 0 ] && grep -q "^REPETE-SE — primeira × ci: números 461/461 iguais, bits 73/73" "$O/repeticao.out"; then BOAS=$((BOAS + 1)); fi
done
echo "== fim $(date +%T) — $BOAS/5 corridas com bancada 0, guião do CI 0 e REPETE-SE 461/461 e 73/73"
test "$BOAS" -eq 5
