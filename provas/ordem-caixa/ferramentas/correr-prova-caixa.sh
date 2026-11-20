#!/bin/bash
# Ordem CAIXA-PERSISTENTE: a prova do cliente (servidor de bancada + Godot com render). Saída em provas/ordem-caixa/cliente.
cd ~/workspace/claude2-hud/repo || exit 9
T=~/workspace/claude2-hud/tmp-caixa
S=$PWD/provas/ordem-caixa/cliente
G=~/workspace/tools/godot/Godot_v4.7.2-stable_linux.x86_64
mkdir -p "$S"
[ -f $T/srv.pid ] && kill "$(cat $T/srv.pid)" 2>/dev/null
rm -f $T/info.json
node provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs --porta=8791 --semente=7 --info=$T/info.json \
  --motor=$T/motor/vlab-completo.js --vida-max-s=1900 > $T/servidor-prova.log 2>&1 &
echo $! > $T/srv.pid
for i in $(seq 1 30); do [ -f $T/info.json ] && break; sleep 1; done
cat $T/info.json; echo
timeout 1800 xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --resolution 1280x720 --path rascunhos/cliente \
  -s $PWD/provas/ordem-caixa/ferramentas/prova_caixa_reentrar.gd -- --servidor=127.0.0.1:8791 --saida=$S > $T/prova-cliente.log 2>&1
rc=$?
kill "$(cat $T/srv.pid)" 2>/dev/null
echo "rc=$rc"
