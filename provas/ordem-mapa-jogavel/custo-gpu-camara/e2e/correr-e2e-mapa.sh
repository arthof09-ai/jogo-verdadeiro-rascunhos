#!/bin/bash
# ORDEM MAPA-JOGÁVEL-CUSTO-CÂMARA (A4): o guião do job do CI (testes.yml, «Servidor + jogadora (Node) + Mestre (Godot)»)
# com a ÚNICA troca do servidor pela cópia adaptada (servidor-e2e-mapa.mjs, sem `sala.mapa`). Correr na raiz do repo:
#   GODOT=<godot> MOTORES=<motores.mjs do embrulhar.mjs> SAIDA=<pasta> bash provas/ordem-mapa-jogavel/custo-gpu-camara/e2e/correr-e2e-mapa.sh
set -u
cd rascunhos
SRVJS=../provas/ordem-mapa-jogavel/custo-gpu-camara/e2e/servidor-e2e-mapa.mjs
correr() {  # $1 = rótulo, $2 = porta, $3 = MOTOR_MJS (vazio = motor falso)
  L="$SAIDA/$1"; mkdir -p "$L"
  MOTOR_MJS="$3" node $SRVJS "$2" > "$L/servidor.log" 2>&1 &
  SRV=$!
  for i in $(seq 1 50); do grep -q pronto-e2e "$L/servidor.log" && break; sleep 0.2; done
  node servidor/e2e/jogadora-e2e.mjs "$2" > "$L/jogadora.log" 2>&1 &
  JOG=$!
  MESTRE=0
  (cd cliente && timeout 180 "$GODOT" --headless --path . -s res://testes/e2e_mestre.gd -- --servidor=127.0.0.1:$2) > "$L/mestre.log" 2>&1 || MESTRE=$?
  JOGADORA=0
  wait $JOG || JOGADORA=$?
  kill $SRV || true
  if grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$L/mestre.log"; then return 1; fi
  echo "$1: Mestre=$MESTRE jogadora=$JOGADORA"
  test "$MESTRE" -eq 0 && test "$JOGADORA" -eq 0
}
R1=0; correr motor-falso 8765 "" || R1=$?
R2=0; correr vlab-real 8766 "$MOTORES" || R2=$?
grep -q "motor REAL" "$SAIDA/vlab-real/servidor.log" || { echo "o servidor do VLAB não carregou o motor real"; R2=1; }
echo "motor falso=$R1 · VLAB real=$R2"
test "$R1" -eq 0 && test "$R2" -eq 0
