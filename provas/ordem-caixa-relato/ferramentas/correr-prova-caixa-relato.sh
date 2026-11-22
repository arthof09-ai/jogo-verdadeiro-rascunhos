#!/bin/bash
# Ordem CAIXA-RELATO (B7b): corre o teste do registo e as DUAS provas vivas da caixa no HUD da jogadora (a da
# CAIXA-HUD-JOGADORA e a cópia com o manequim, CAIXA-MANEQUIM), com as ferramentas já corrigidas, e grava as saídas
# em provas/ordem-caixa-relato/ (cliente-hud/, cliente-manequim/, teste-relato.log). As saídas antigas das duas ordens
# ficam como estavam (são o registo do que se viu nessa altura). PC Windows, Git Bash; num clone novo, primeiro
# `godot --headless --path rascunhos/cliente --import`.
#   bash provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh <godot.exe> <vlab-completo.js> <pasta-tmp> [<pasta-saída>]
# Ordem CAIXA-RELATO-CORRECOES: o 4.º argumento (opcional) muda a pasta de saída (por omissão provas/ordem-caixa-relato/);
# as corridas das correcções foram para provas/ordem-caixa-relato/correcoes/, sem reescrever as da ordem anterior.
# Ordem CAIXA-RELATO-B7-CORRECOES-4 (B3): `servidor-info.json` e `servidor.log` deixam de ir para a pasta de saída (o
# PIN); as das ordens anteriores ficam como estavam (pré-existentes, servidor efémero), não se repetem.
# Ordem CAIXA-RELATO-CORRECOES-7 (B5): a <pasta-tmp> e a <pasta-saída> são absolutizadas à entrada. O Godot corre com
# `--path rascunhos/cliente` e lê o `--saida` a partir daí: com um caminho relativo, as saídas iam parar a
# `rascunhos/cliente/<pasta>/`. Um caminho relativo conta agora a partir da pasta de onde se chamou o script.
ORIGEM=$PWD
cd "$(dirname "$0")/../../.." || exit 9
G=${1:?godot}; MOTOR=${2:?motor}; T=${3:?tmp}
P=$PWD/provas/ordem-caixa-relato
O=${4:-$P}
absoluto() { case "$1" in /*|[A-Za-z]:*) printf '%s' "$1" ;; *) printf '%s/%s' "$ORIGEM" "$1" ;; esac; }
[ "$(absoluto "$T")" != "$T" ] && { T=$(absoluto "$T"); echo "pasta tmp relativa — uso o caminho absoluto $T" >&2; }
[ "$(absoluto "$O")" != "$O" ] && { O=$(absoluto "$O"); echo "pasta de saída relativa — uso o caminho absoluto $O" >&2; }
mkdir -p "$T" "$O"
rc_total=0

timeout 120 "$G" --headless --path rascunhos/cliente -s "$P/ferramentas/teste_relato_caixa.gd" > "$T/teste-relato.log" 2>&1
rc=$?; echo "teste_relato_caixa rc=$rc"; [ $rc -ne 0 ] && rc_total=1
grep -v "^Godot Engine" "$T/teste-relato.log" > "$O/teste-relato.log"

correr() {  # <nome> <ferramenta.gd> <porta>
  local S=$O/$1; mkdir -p "$S"; rm -f "$T/info-$1.json"
  node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=$3 --semente=7 --info="$T/info-$1.json" \
    --motor="$MOTOR" --vida-max-s=900 > "$T/servidor-$1.log" 2>&1 &
  local SRV=$!
  for i in $(seq 1 30); do [ -f "$T/info-$1.json" ] && break; sleep 1; done
  cat "$T/info-$1.json"; echo
  timeout 900 "$G" --resolution 1280x720 --path rascunhos/cliente \
    -s "$PWD/$2" -- --servidor=127.0.0.1:$3 --saida="$S" > "$T/prova-$1.log" 2>&1
  local r=$?
  kill $SRV 2>/dev/null
  # B7-CORRECOES-4 (B3): o info e o log do servidor trazem o PIN da sala (servidor local efémero) — ficam na pasta tmp
  # (`$T/info-$1.json`, `$T/servidor-$1.log`) e já NÃO se copiam para a pasta de saída, que é a que se comete.
  # As capturas não são o objecto desta ordem (só o registo): ficam na pasta tmp, não no ramo.
  mkdir -p "$T/capturas-$1"; mv -f "$S"/*.png "$T/capturas-$1/" 2>/dev/null
  echo "$1 rc=$r"; [ $r -ne 0 ] && rc_total=1
}
correr cliente-hud provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd 8796
correr cliente-manequim provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd 8797
echo "rc=$rc_total"
exit $rc_total
