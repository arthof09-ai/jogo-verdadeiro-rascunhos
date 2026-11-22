#!/bin/bash
# Ordem CAIXA-JANELA: a prova viva do cliente da jogadora (servidor de bancada + Godot com render, PC Windows, Git Bash).
# Saída em provas/ordem-caixa-janela/cliente. Usa o servidor de bancada da CAIXA-HUD-JOGADORA (intacto).
#   bash provas/ordem-caixa-janela/ferramentas/correr-prova-caixa-janela.sh <godot.exe> <vlab-completo.js> <pasta-tmp> [saída]
# CAIXA-JANELA-NOMES: [saída] opcional (relativa à raiz do repo); sem ela, provas/ordem-caixa-janela/cliente, como antes.
cd "$(dirname "$0")/../../.." || exit 9
G=${1:?godot}; MOTOR=${2:?motor}; T=${3:?tmp}
S=$PWD/${4:-provas/ordem-caixa-janela/cliente}
mkdir -p "$S" "$T"
rm -f "$T/info.json"
node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=8793 --semente=7 --info="$T/info.json" \
  --motor="$MOTOR" --vida-max-s=900 > "$T/servidor-prova.log" 2>&1 &
SRV=$!
for i in $(seq 1 30); do [ -f "$T/info.json" ] && break; sleep 1; done
cat "$T/info.json"; echo
timeout 900 "$G" --resolution 1280x720 --path rascunhos/cliente \
  -s "$PWD/provas/ordem-caixa-janela/ferramentas/prova_caixa_janela.gd" -- --servidor=127.0.0.1:8793 --saida="$S" > "$T/prova-cliente.log" 2>&1
rc=$?
kill $SRV 2>/dev/null
cp "$T/info.json" "$S/servidor-info.json" 2>/dev/null
cp "$T/servidor-prova.log" "$S/servidor.log" 2>/dev/null
echo "rc=$rc"
exit $rc
