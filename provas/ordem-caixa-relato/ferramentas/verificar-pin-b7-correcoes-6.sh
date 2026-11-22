#!/bin/bash
# Ordem CAIXA-RELATO-B7-CORRECOES-6: a verificação do D1/D2 — o PIN do Mestre fora do repositório. SÓ CONTAGENS: os
# valores nunca se imprimem, nem neste script, nem no log. Os dois valores vêm dos objectos do git (o histórico fica
# como está, por decisão registada — B5): o PIN antigo do cenário em <ref-antigo> e o PIN novo de 20 dígitos (público,
# nunca se reutiliza) do cenário em <ref-novo>.
#   bash provas/ordem-caixa-relato/ferramentas/verificar-pin-b7-correcoes-6.sh [<godot.exe>] [<base>] [<ref-antigo>] [<ref-novo>]
#   <base>       a ponta da fable/integracao-50 no lançamento (por omissão 1b907bc): «ficheiros novos» = os que mudam
#                de <base> para a árvore de trabalho, mais os não seguidos;
#   <ref-antigo> por omissão 1b907bc (a integracao-50 ainda tem o cenário com o PIN antigo);
#   <ref-novo>   por omissão e8f1a42 (a ponta da claude1/caixa-relato-b7-correcoes-5, com o PIN novo).
# Com <godot.exe>, prova também que as 4 provas .gd recusam correr sem --pin (código 2).
# Código de saída: 0 tudo a zero e as recusas como esperado · 1 alguma contagem ≠ 0 ou recusa diferente · 2 argumentos.
cd "$(dirname "$0")/../../.." || exit 9
G=${1:-}; BASE=${2:-1b907bc}; RA=${3:-1b907bc}; RN=${4:-e8f1a42}
[ -n "$G" ] && [ ! -f "$G" ] && { echo "o <godot> não existe" >&2; exit 2; }
C=rascunhos/servidor/autojogo/cenario-bancada.json
pin_de() { git show "$1:$C" 2>/dev/null | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(String(JSON.parse(s).pin??""))}catch{}})'; }
ANT=$(pin_de "$RA"); NOV=$(pin_de "$RN")
[ ${#ANT} -ge 6 ] || { echo "não achei o PIN antigo em $RA:$C" >&2; exit 2; }
[ ${#NOV} -eq 20 ] || { echo "não achei o PIN novo de 20 dígitos em $RN:$C" >&2; exit 2; }
falhas=0
linha() {  # <rótulo> <valor> <esperado>
  local marca=ok; [ "$2" != "$3" ] && { marca=FALHA; falhas=$((falhas + 1)); }
  echo "$1: $2 (esperado $3) $marca"
}
na_arvore() {  # <valor> → ficheiros / ocorrências em TODA a árvore de trabalho (seguidos ou não), fora de .git
  local fs n=0 f
  fs=$(grep -rlF --exclude-dir=.git --exclude-dir=.godot -- "$1" . 2>/dev/null)
  for f in $fs; do n=$((n + $(grep -oF -- "$1" "$f" | wc -l))); done
  echo "$(printf '%s' "$fs" | grep -c .) $n"
}
novos=$( { git diff --name-only --diff-filter=d "$BASE"; git ls-files --others --exclude-standard; } | sort -u)
nos_novos() { local n=0 f; for f in $novos; do [ -f "$f" ] && grep -qF -- "$1" "$f" && n=$((n + 1)); done; echo $n; }

echo "# verificação do PIN (Ordem CAIXA-RELATO-B7-CORRECOES-6) · $(git rev-parse --short HEAD) · base $BASE"
echo "# só contagens; os valores nunca se escrevem. O PIN antigo vem de $RA, o PIN novo de 20 dígitos de $RN."
read -r fN oN <<< "$(na_arvore "$NOV")"
linha "PIN novo de 20 dígitos — ficheiros na árvore de trabalho (seguidos ou não)" "$fN" 0
linha "PIN novo de 20 dígitos — ocorrências na árvore de trabalho" "$oN" 0
linha "PIN novo de 20 dígitos — ficheiros seguidos (git grep)" "$(git grep -lF -- "$NOV" | grep -c .)" 0
read -r fA oA <<< "$(na_arvore "$ANT")"
linha "PIN antigo — ficheiros na árvore de trabalho (seguidos ou não)" "$fA" 0
linha "PIN antigo — ocorrências na árvore de trabalho" "$oA" 0
linha "PIN antigo — ficheiros novos ou mudados desde a base ($(printf '%s\n' "$novos" | grep -c .) ficheiros)" "$(nos_novos "$ANT")" 0
linha "chave \"pin\" no cenário de bancada" "$(node -e 'process.stdout.write(String(Object.hasOwn(require("./'"$C"'"),"pin")))')" false
linha "servidor-info.json seguidos" "$(git ls-files | grep -c 'servidor-info\.json$')" 0
linha "servidor.log seguidos fora de suites/" "$(git ls-files | grep '/servidor\.log$' | grep -vc '/suites/')" 0
linha "cp do info ou do log do servidor nos 5 lançadores" "$(grep -cE '^[^#]*cp .*(info|servidor-prova|servidor-)' provas/ordem-caixa-hud-jogadora/ferramentas/correr-prova-caixa-hud.sh provas/ordem-caixa-janela/ferramentas/correr-prova-caixa-janela.sh provas/ordem-caixa-manequim/ferramentas/correr-prova-caixa-manequim.sh provas/ordem-caixa/ferramentas/correr-prova-caixa.sh provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh | awk -F: '{s+=$2} END {print s}')" 0
linha "cat do info nos 5 lançadores" "$(grep -cE '^[^#]*cat [^|]*info' provas/ordem-caixa-hud-jogadora/ferramentas/correr-prova-caixa-hud.sh provas/ordem-caixa-janela/ferramentas/correr-prova-caixa-janela.sh provas/ordem-caixa-manequim/ferramentas/correr-prova-caixa-manequim.sh provas/ordem-caixa/ferramentas/correr-prova-caixa.sh provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh | awk -F: '{s+=$2} END {print s}')" 0
linha "chave \"pin\" nos registos de b7-correcoes-6/" "$(grep -rlE '"pin"[[:space:]]*:' provas/ordem-caixa-relato/b7-correcoes-6 2>/dev/null | grep -c .)" 0

# Recusas: sem --pin (ou com um PIN que não é de 6+ dígitos) nada arranca.
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
for s in provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs; do
  timeout 30 node "$s" --porta=8840 --motor-falso --info="$T/i.json" > /dev/null 2>&1; r=$?
  linha "$s sem --pin → código" $r 2
  timeout 30 node "$s" --porta=8840 --motor-falso --pin=12ab56 --info="$T/i.json" > /dev/null 2>&1; r=$?
  linha "$s com --pin que não é só dígitos → código" $r 2
done
linha "info escrito por um servidor recusado" "$([ -f "$T/i.json" ] && echo 1 || echo 0)" 0
timeout 30 node rascunhos/servidor/autojogo/servidor-autojogo.mjs --porta=8841 --motor-falso > "$T/aj.log" 2>&1; r=$?
linha "servidor-autojogo.mjs sem --pin → recusa (código ≠ 0)" "$([ $r -ne 0 ] && grep -q 'falta --pin' "$T/aj.log" && echo recusa || echo "rc=$r")" recusa
# Arranque vivo com o cenário novo e um PIN fresco: o info sai sem a chave "pin", e a linha «pronto-…» também.
P=$(node -e 'const c=require("crypto");let s="";for(let i=0;i<20;i++)s+=c.randomInt(10);process.stdout.write(s)')
node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=8842 --motor-falso --pin="$P" --info="$T/vivo.json" --vida-max-s=30 > "$T/vivo.log" 2>&1 &
SRV=$!
for i in $(seq 1 30); do [ -f "$T/vivo.json" ] && break; sleep 1; done
kill $SRV 2>/dev/null; wait $SRV 2>/dev/null
linha "arranque vivo (cenário novo, PIN fresco): info pronto" "$(node -e 'process.stdout.write(String(require(process.argv[1]).pronto===true))' "$T/vivo.json" 2>/dev/null)" true
linha "arranque vivo: chave \"pin\" no info" "$(cat "$T/vivo.json" 2>/dev/null | grep -c '"pin"')" 0
linha "arranque vivo: o PIN da corrida no info ou no log do servidor" "$(cat "$T/vivo.json" "$T/vivo.log" | grep -cF -- "$P")" 0
linha "arranque vivo: linha pronto- no log" "$(grep -c '^pronto-prova-caixa-hud ' "$T/vivo.log")" 1
if [ -n "$G" ]; then
  for f in provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd provas/ordem-caixa-janela/ferramentas/prova_caixa_janela.gd provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd provas/ordem-caixa/ferramentas/prova_caixa_reentrar.gd; do
    timeout 60 "$G" --headless --path rascunhos/cliente -s "$PWD/$f" -- --servidor=127.0.0.1:8843 --saida="$T/s" > "$T/g.log" 2>&1; r=$?
    linha "$f sem --pin → código" $r 2
  done
fi
echo "falhas: $falhas"
[ $falhas -eq 0 ]
