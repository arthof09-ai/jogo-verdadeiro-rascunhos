#!/bin/bash
# uso: c.sh NOME [espera_s] < script.ps1  -> corre no agente da sessão 1 e imprime o .out
D=<JV>/ordem-plano-2-f1-pc/tmp/cmd; N=$1; W=${2:-30}
rm -f $D/$N.out; cat > $D/$N.tmp && mv $D/$N.tmp $D/$N.ps1
for i in $(seq 1 $((W*5))); do [ -f $D/$N.out ] && { sleep 0.3; python -c "import sys;print(open(sys.argv[1],'rb').read().decode('utf-8-sig','replace'))" $D/$N.out; exit 0; }; sleep 0.2; done
echo "SEM RESPOSTA em ${W}s"; exit 1
