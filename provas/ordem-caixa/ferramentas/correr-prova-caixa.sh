#!/bin/bash
# Ordem CAIXA-PERSISTENTE: a prova do cliente (servidor de bancada + Godot com render). Saída em provas/ordem-caixa/cliente.
#   bash provas/ordem-caixa/ferramentas/correr-prova-caixa.sh                         (o modo antigo: Linux, caminhos fixos)
#   bash provas/ordem-caixa/ferramentas/correr-prova-caixa.sh <godot> <vlab-completo.js> <pasta-tmp> [<pasta-saída>]
# Ordem CAIXA-RELATO-B7-CORRECOES-7 (B1/JD2): com argumentos, o lançador corre em qualquer máquina (PC Windows com Git
# Bash, ou Linux), como os outros 3 lançadores: a raiz é a do clone onde o script está, o Godot, o motor e a pasta tmp vêm
# dos argumentos e a <pasta-saída> (por omissão provas/ordem-caixa/cliente) muda a pasta onde a prova escreve. O xvfb-run
# só se usa se existir (no Windows não existe e não é preciso: há ecrã). Os caminhos passam pela função `absolutizar`
# (a mesma dos lançadores da relato): o Godot corre com `--path rascunhos/cliente` e um caminho relativo ia parar lá.
# Sem argumentos fica o modo antigo, tal como estava (claude2-hud, xvfb, Godot de Linux).
if [ $# -eq 0 ]; then
  cd ~/workspace/claude2-hud/repo || exit 9
  T=~/workspace/claude2-hud/tmp-caixa
  S=$PWD/provas/ordem-caixa/cliente
  G=~/workspace/tools/godot/Godot_v4.7.2-stable_linux.x86_64
  MOTOR=$T/motor/vlab-completo.js
else
  [ $# -ge 3 ] || { echo "uso: $0 [<godot> <vlab-completo.js> <pasta-tmp> [<pasta-saída>]]" >&2; exit 2; }
  ORIGEM=$PWD
  . "$(dirname "$0")/../../ordem-caixa-relato/ferramentas/absolutizar.sh" || exit 9
  G=$1; MOTOR=$2; T=$3; S=${4:-}
  absolutizar G "godot" || exit 2
  absolutizar MOTOR "motor" || exit 2
  absolutizar T "pasta tmp" || exit 2
  [ -n "$S" ] && { absolutizar S "pasta de saída" || exit 2; }
  [ -f "$G" ] || { echo "o <godot> não existe: $G" >&2; exit 2; }
  [ -f "$MOTOR" ] || { echo "o motor não existe: $MOTOR" >&2; exit 2; }
  cd "$(dirname "$0")/../../.." || exit 9
  S=${S:-$PWD/provas/ordem-caixa/cliente}
fi
mkdir -p "$S" "$T"
[ -f "$T/srv.pid" ] && kill "$(cat "$T/srv.pid")" 2>/dev/null
rm -f "$T/info.json"
# Ordem CAIXA-RELATO-B7-CORRECOES-6 (B1/B2): o PIN do Mestre é FRESCO em cada corrida (20 dígitos de crypto.randomInt) e
# só passa por --pin= ao servidor e à prova — não está no repositório e nunca se escreve nele. O info imprime-se sem a
# chave "pin" (o servidor já não a põe; o filtro fica de cinto) e o info/log do servidor ficam na pasta tmp: já NÃO se
# copiam para a pasta de saída (a que se comete).
PIN=$(node -e 'const c = require("crypto"); let s = ""; for (let i = 0; i < 20; i++) s += c.randomInt(10); process.stdout.write(s)') || exit 9
node provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs --porta=8791 --semente=7 --info="$T/info.json" --pin="$PIN" \
  --motor="$MOTOR" --vida-max-s=1900 > "$T/servidor-prova.log" 2>&1 &
echo $! > "$T/srv.pid"
for i in $(seq 1 30); do [ -f "$T/info.json" ] && break; sleep 1; done
node -e 'const i = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); delete i.pin; console.log(JSON.stringify(i))' \
  "$T/info.json" || echo "(info do servidor ilegível)"
if command -v xvfb-run > /dev/null 2>&1; then
  ECRA=(xvfb-run -a -s "-screen 0 1280x720x24"); RENDER=(--rendering-driver opengl3)
else
  ECRA=(); RENDER=()
fi
timeout 1800 "${ECRA[@]}" "$G" "${RENDER[@]}" --resolution 1280x720 --path rascunhos/cliente \
  -s "$PWD/provas/ordem-caixa/ferramentas/prova_caixa_reentrar.gd" -- --servidor=127.0.0.1:8791 --saida="$S" --pin="$PIN" > "$T/prova-cliente.log" 2>&1
rc=$?
kill "$(cat "$T/srv.pid")" 2>/dev/null
echo "rc=$rc"
exit $rc
