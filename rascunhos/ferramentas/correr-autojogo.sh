#!/usr/bin/env bash
# ORDEM AUTOJOGO — FERRAMENTA DE MEDIÇÃO: corre N partidas de autojogo seguidas (sementes fixas) e resume-as numa tabela.
#
#   rascunhos/ferramentas/correr-autojogo.sh [-n N] [-s SEMENTE_INICIAL] [-o PASTA] [-g GODOT] [-p PORTA_BASE]
#        [-k VELOCIDADE] [-c CENARIO.json] [-m MOTOR.js] [-d] [-f]
#
#   -n N        partidas (padrão 3); sementes S, S+1, …, S+N-1
#   -s S        semente inicial (padrão 1)
#   -o PASTA    onde ficam os registos s<N>.jsonl, os logs s<N>.log e o resumo (padrão ./autojogo-saida)
#   -g GODOT    binário do Godot 4.7 (padrão: $GODOT, senão `godot`)
#   -p PORTA    porta base do servidor de bancada (padrão 8790; a partida i usa PORTA+i)
#   -k K        velocidade (padrão 0 = sem pausa; o resultado não depende dela)
#   -c / -m     cenário e motor (vlab-completo.js) a passar ao servidor de bancada
#   -d          determinismo: corre a 1.ª semente outra vez e exige o mesmo registo, byte a byte
#   -f          motor FALSO (só canalização; NÃO serve para medir equilíbrio)
#
# Saída: resumo.md (a tabela) e resumo.json na PASTA; código 0 só se todas as partidas acabaram, todos os registos
# batem com o próprio resumo e (com -d) a repetição deu o mesmo registo.
set -u
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RASC="$(cd "$AQUI/.." && pwd)"
N=3; S=1; OUT="./autojogo-saida"; GOD="${GODOT:-godot}"; PORTA=8790; K=0; CEN=""; MOT=""; DET=0; FALSO=0
while getopts "n:s:o:g:p:k:c:m:df" o; do
  case "$o" in
    n) N="$OPTARG" ;; s) S="$OPTARG" ;; o) OUT="$OPTARG" ;; g) GOD="$OPTARG" ;; p) PORTA="$OPTARG" ;;
    k) K="$OPTARG" ;; c) CEN="$(realpath "$OPTARG")" ;; m) MOT="$(realpath "$OPTARG")" ;; d) DET=1 ;; f) FALSO=1 ;;
    *) sed -n '2,20p' "$0"; exit 2 ;;
  esac
done
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"

partida() {  # $1 = semente, $2 = porta, $3 = registo
  local extra=()
  [ -n "$CEN" ] && extra+=("--cenario=$CEN")
  [ -n "$MOT" ] && extra+=("--motor=$MOT")
  [ "$FALSO" = 1 ] && extra+=("--motor-falso")
  (cd "$RASC/cliente" && timeout 900 "$GOD" --headless --path . -s res://autojogo/autojogo.gd -- --autojogo \
      --semente="$1" --registo="$3" --servidor="127.0.0.1:$2" --velocidade="$K" "${extra[@]}") > "${3%.jsonl}.log" 2>&1
}

FALHAS=0
REGISTOS=()
for ((i = 0; i < N; i++)); do
  sem=$((S + i)); reg="$OUT/s$sem.jsonl"
  t0=$(date +%s)
  if partida "$sem" $((PORTA + i)) "$reg"; then r=ok; else r="FALHOU ($?)"; FALHAS=$((FALHAS + 1)); fi
  if grep -qE "SCRIPT ERROR|Parse Error|Compile Error" "${reg%.jsonl}.log"; then r="$r + erro de script"; FALHAS=$((FALHAS + 1)); fi
  echo "semente $sem: $r ($(( $(date +%s) - t0 )) s) — $(tail -1 "$reg" 2>/dev/null | sed -n 's/.*"texto":"\([^"]*\)".*/\1/p')"
  REGISTOS+=("$reg")
done

if [ "$DET" = 1 ]; then
  rep="$OUT/s$S.repeticao.jsonl"
  partida "$S" $((PORTA + N)) "$rep" || FALHAS=$((FALHAS + 1))
  a=$(sha256sum < "$OUT/s$S.jsonl" | cut -d' ' -f1); b=$(sha256sum < "$rep" | cut -d' ' -f1)
  if [ "$a" = "$b" ]; then echo "determinismo: semente $S repetida → o mesmo registo (sha256 $a)"
  else echo "determinismo: FALHOU — semente $S deu $a e depois $b"; diff <(cat "$OUT/s$S.jsonl") "$rep" | head -10; FALHAS=$((FALHAS + 1)); fi
fi

echo
node "$RASC/servidor/autojogo/resumir-autojogo.mjs" "${REGISTOS[@]}" --md="$OUT/resumo.md" --json="$OUT/resumo.json" || FALHAS=$((FALHAS + 1))
[ "$FALHAS" -eq 0 ] && exit 0 || { echo "($FALHAS falha(s))"; exit 1; }
