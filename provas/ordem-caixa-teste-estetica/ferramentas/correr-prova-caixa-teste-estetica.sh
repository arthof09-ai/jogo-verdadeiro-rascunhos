#!/bin/bash
# Ordem CAIXA-TESTE-ESTETICA (cópia da CAIXA-MANEQUIM, com as cores do protótipo na caixa): os 5 momentos da prova viva da CAIXA-HUD-JOGADORA, com o manequim de referência no lugar das
# cápsulas (servidor de bancada + Godot com render, no PC Windows, Git Bash). O servidor é o da CAIXA-HUD-JOGADORA,
# usado tal como está. Saída em provas/ordem-caixa-teste-estetica/cliente.
#   bash provas/ordem-caixa-teste-estetica/ferramentas/correr-prova-caixa-teste-estetica.sh <godot.exe> <vlab-completo.js> <pasta-tmp>
cd "$(dirname "$0")/../../.." || exit 9
G=${1:?godot}; MOTOR=${2:?motor}; T=${3:?tmp}
S=$PWD/provas/ordem-caixa-teste-estetica/cliente
mkdir -p "$S" "$T"
rm -f "$T/info.json"
node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=8794 --semente=7 --info="$T/info.json" \
  --motor="$MOTOR" --vida-max-s=900 > "$T/servidor-prova.log" 2>&1 &
SRV=$!
for i in $(seq 1 30); do [ -f "$T/info.json" ] && break; sleep 1; done
cat "$T/info.json"; echo
timeout 900 "$G" --resolution 1280x720 --path rascunhos/cliente \
  -s "$PWD/provas/ordem-caixa-teste-estetica/ferramentas/prova_caixa_teste_estetica.gd" -- --servidor=127.0.0.1:8794 --saida="$S" > "$T/prova-cliente.log" 2>&1
rc=$?
kill $SRV 2>/dev/null
cp "$T/info.json" "$S/servidor-info.json" 2>/dev/null
cp "$T/servidor-prova.log" "$S/servidor.log" 2>/dev/null
echo "rc=$rc"
exit $rc
