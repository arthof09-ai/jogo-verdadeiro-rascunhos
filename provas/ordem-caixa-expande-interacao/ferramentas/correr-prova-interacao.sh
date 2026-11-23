#!/bin/bash
# Ordem CAIXA-EXPANDE-INTERACAO: a prova da CAIXA-EXPANDE (a mesma ferramenta, com o passo 8 pela roda e o passo 11 dos 3 gestos), com saída em
# provas/ordem-caixa-expande-interacao/cliente. Do lançador da CAIXA-EXPANDE, de que é cópia:
# Ordem CAIXA-EXPANDE: os 5 momentos da prova viva da caixa com o manequim de referência e os momentos novos (cópia da prova da CAIXA-PADRAO-CORRECOES, que é cópia da da
# CAIXA-PADRAO-BUSTO), e os casos do retrato (o 10.º passo). Servidor de ensaio + Godot com render, no PC
# Windows (Git Bash). O servidor é o da CAIXA-HUD-JOGADORA, usado tal como está. Saída em
# provas/ordem-caixa-expande/cliente.
#   bash provas/ordem-caixa-expande-interacao/ferramentas/correr-prova-interacao.sh <godot.exe> <vlab-completo.js> <pasta-tmp>
# B8: o PIN do Mestre é FRESCO por corrida (20 dígitos de crypto.randomInt) e só passa por --pin= ao servidor e à
# prova — nunca se escreve no repositório. O info imprime-se sem a chave "pin"; o info e o log do servidor ficam na pasta
# tmp e NÃO se copiam para a pasta de saída (a que se comete). (A prova do padrão-busto copiava-os, com o PIN.)
cd "$(dirname "$0")/../../.." || exit 9
G=${1:?godot}; MOTOR=${2:?motor}; T=${3:?tmp}
S=$PWD/provas/ordem-caixa-expande-interacao/cliente
mkdir -p "$S" "$T"
rm -f "$T/info.json"
PIN=$(node -e 'const c = require("crypto"); let s = ""; for (let i = 0; i < 20; i++) s += c.randomInt(10); process.stdout.write(s)') || exit 9
node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=8794 --semente=7 --info="$T/info.json" --pin="$PIN" \
  --motor="$MOTOR" --vida-max-s=900 > "$T/servidor-prova.log" 2>&1 &
SRV=$!
for i in $(seq 1 30); do [ -f "$T/info.json" ] && break; sleep 1; done
node -e 'const i = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); delete i.pin; console.log(JSON.stringify(i))' \
  "$T/info.json" || echo "(info do servidor ilegível)"
timeout 900 "$G" --resolution 1280x720 --path rascunhos/cliente \
  -s "$PWD/provas/ordem-caixa-expande/ferramentas/prova_caixa_expande.gd" -- --servidor=127.0.0.1:8794 --saida="$S" --pin="$PIN" > "$T/prova-cliente.log" 2>&1
rc=$?
kill $SRV 2>/dev/null
echo "rc=$rc"
exit $rc
