#!/bin/bash
# Ordem CAIXA-HUD-JOGADORA: a prova do cliente da jogadora (servidor de bancada + Godot com render, no PC Windows,
# Git Bash). Saída em provas/ordem-caixa-hud-jogadora/cliente.
#   bash provas/ordem-caixa-hud-jogadora/ferramentas/correr-prova-caixa-hud.sh <godot.exe> <vlab-completo.js> <pasta-tmp>
cd "$(dirname "$0")/../../.." || exit 9
G=${1:?godot}; MOTOR=${2:?motor}; T=${3:?tmp}
S=$PWD/provas/ordem-caixa-hud-jogadora/cliente
mkdir -p "$S" "$T"
rm -f "$T/info.json"
# Ordem CAIXA-RELATO-B7-CORRECOES-6 (B1/B2): o PIN do Mestre é FRESCO em cada corrida (20 dígitos de crypto.randomInt) e
# só passa por --pin= ao servidor e à prova — não está no repositório e nunca se escreve nele. O info imprime-se sem a
# chave "pin" (o servidor já não a põe; o filtro fica de cinto) e o info/log do servidor ficam na pasta tmp: já NÃO se
# copiam para a pasta de saída (a que se comete).
PIN=$(node -e 'const c = require("crypto"); let s = ""; for (let i = 0; i < 20; i++) s += c.randomInt(10); process.stdout.write(s)') || exit 9
node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=8792 --semente=7 --info="$T/info.json" --pin="$PIN" \
  --motor="$MOTOR" --vida-max-s=900 > "$T/servidor-prova.log" 2>&1 &
SRV=$!
for i in $(seq 1 30); do [ -f "$T/info.json" ] && break; sleep 1; done
node -e 'const i = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); delete i.pin; console.log(JSON.stringify(i))' \
  "$T/info.json" || echo "(info do servidor ilegível)"
timeout 900 "$G" --resolution 1280x720 --path rascunhos/cliente \
  -s "$PWD/provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd" -- --servidor=127.0.0.1:8792 --saida="$S" --pin="$PIN" > "$T/prova-cliente.log" 2>&1
rc=$?
kill $SRV 2>/dev/null
echo "rc=$rc"
exit $rc
