#!/bin/bash
# Ordem CAIXA-PERSISTENTE: a prova do cliente (servidor de bancada + Godot com render). Saída em provas/ordem-caixa/cliente.
cd ~/workspace/claude2-hud/repo || exit 9
T=~/workspace/claude2-hud/tmp-caixa
S=$PWD/provas/ordem-caixa/cliente
G=~/workspace/tools/godot/Godot_v4.7.2-stable_linux.x86_64
mkdir -p "$S"
[ -f $T/srv.pid ] && kill "$(cat $T/srv.pid)" 2>/dev/null
rm -f $T/info.json
# Ordem CAIXA-RELATO-B7-CORRECOES-6 (B1/B2): o PIN do Mestre é FRESCO em cada corrida (20 dígitos de crypto.randomInt) e
# só passa por --pin= ao servidor e à prova — não está no repositório e nunca se escreve nele. O info imprime-se sem a
# chave "pin" (o servidor já não a põe; o filtro fica de cinto) e o info/log do servidor ficam na pasta tmp: já NÃO se
# copiam para a pasta de saída (a que se comete).
PIN=$(node -e 'const c = require("crypto"); let s = ""; for (let i = 0; i < 20; i++) s += c.randomInt(10); process.stdout.write(s)') || exit 9
node provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs --porta=8791 --semente=7 --info=$T/info.json --pin="$PIN" \
  --motor=$T/motor/vlab-completo.js --vida-max-s=1900 > $T/servidor-prova.log 2>&1 &
echo $! > $T/srv.pid
for i in $(seq 1 30); do [ -f $T/info.json ] && break; sleep 1; done
node -e 'const i = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); delete i.pin; console.log(JSON.stringify(i))' \
  $T/info.json || echo "(info do servidor ilegível)"
timeout 1800 xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --resolution 1280x720 --path rascunhos/cliente \
  -s $PWD/provas/ordem-caixa/ferramentas/prova_caixa_reentrar.gd -- --servidor=127.0.0.1:8791 --saida=$S --pin="$PIN" > $T/prova-cliente.log 2>&1
rc=$?
kill "$(cat $T/srv.pid)" 2>/dev/null
echo "rc=$rc"
