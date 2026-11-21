#!/usr/bin/env bash
# ORDEM-F2 — a prova da escuta permanente, FORA da corrida padrão: a mesma cadeia do correr-bancada.sh (a jogadora
# Godot e o Mestre/espectador padrão, sem mudança), mas o servidor é bancada-servidor-k.mjs (a escuta padrão + os
# canários K1–K5 da CORR8), e a sonda do fio corre com --canarios.
# Esperado: sonda do fio 0 (apanha K1–K5 pelo conjunto exacto, e fora 0 achados); a jogadora padrão FALHA a sonda dela
# (apanha K1–K3, que chegam aos sinais da Rede — é o esperado: não há controlo positivo na bancada padrão).
#   GODOT=<godot console> bash correr-prova-escuta.sh <pasta-de-saida> [porta]
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$AQUI/../../.." && pwd)"
PM="$REPO/provas/ordem-mapa-jogavel/provas-bancada/ferramentas"
OUT="${1:?pasta de saída}"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
PORTA="${2:-8796}"
: "${GODOT:?GODOT por definir}"
win() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }

node "$AQUI/bancada-servidor-k.mjs" "$PORTA" "$(win "$OUT/escuta-jogadora.jsonl")" > "$OUT/bancada-servidor.log" 2>&1 &
SRV=$!
for i in $(seq 1 50); do grep -q pronto-bancada "$OUT/bancada-servidor.log" && break; sleep 0.2; done
(cd "$REPO/rascunhos/cliente" && timeout 400 "$GODOT" --headless --path . -s "$(win "$PM/bancada_jogadora_mapa.gd")" -- \
  --servidor=127.0.0.1:$PORTA --json="$(win "$OUT/bancada-jogadora.json")") > "$OUT/bancada-jogadora.log" 2>&1 &
JOG=$!
for i in $(seq 1 300); do grep -q na-mesa-bancada "$OUT/bancada-jogadora.log" && break; sleep 0.2; done
MESTRE=0
node "$PM/bancada-mestre.mjs" "$PORTA" "$(win "$OUT/bancada-mestre.json")" > "$OUT/bancada-mestre.log" 2>&1 || MESTRE=$?
JOGADORA=0
wait $JOG || JOGADORA=$?
kill $SRV 2>/dev/null || true
FIO=0
node "$PM/sonda-fio.mjs" "$(win "$OUT/escuta-jogadora.jsonl")" "$(win "$OUT/sonda-fio.json")" --canarios > "$OUT/sonda-fio.log" 2>&1 || FIO=$?
ERROS=$(grep -cE "SCRIPT ERROR|Parse Error|Compile Error" "$OUT/bancada-jogadora.log")
echo "PROVA DA ESCUTA: sonda-do-fio=$FIO (esperado 0) jogadora=$JOGADORA (esperado 1: a sonda dela apanha K1–K3) Mestre/espectador=$MESTRE erros-de-script=$ERROS"
test "$FIO" -eq 0 && test "$JOGADORA" -ne 0 && test "$MESTRE" -eq 0 && test "$ERROS" -eq 0
