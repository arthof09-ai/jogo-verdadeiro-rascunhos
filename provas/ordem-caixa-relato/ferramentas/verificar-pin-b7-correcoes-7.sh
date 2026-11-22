#!/bin/bash
# Ordem CAIXA-RELATO-B7-CORRECOES-7: a verificação do PIN depois das correcções JD2–JD4 (a de verificar-pin-b7-correcoes-6.sh,
# que fica como estava — é o registo da -6 —, com o que esta ordem muda). SÓ CONTAGENS: os valores nunca se imprimem, nem
# neste script, nem no log. O PIN antigo e o PIN novo de 20 dígitos vêm dos objectos do git, como na -6.
#   bash provas/ordem-caixa-relato/ferramentas/verificar-pin-b7-correcoes-7.sh [<godot.exe>] [<base>] [<ref-antigo>] [<ref-novo>]
#   <base>       a ponta da fable/integracao-50 no lançamento desta ordem (por omissão bfe4c3c): «ficheiros novos» = os que
#                mudam de <base> para a árvore de trabalho, mais os não seguidos;
#   <ref-antigo> por omissão 1b907bc; <ref-novo> por omissão e8f1a42 (os mesmos da -6).
# O que muda em relação à -6:
#   B2 (JD3) — o servidor-autojogo.mjs tem de sair com o código 2 (e não só «recusar»): sem --pin, com um --pin que não é
#              só dígitos, e sem --pin com um --cenario que não existe (prova de que o PIN se valida ANTES do lerCenario).
#   B1 (JD2) — 0 `.pathname` no código (fora de comentários) do servidor-bancada-prova.mjs da caixa, e um arranque vivo
#              dele (no Windows, onde o `.pathname` não abria o cenário).
#   B3 (JD4) — o autojogo.gd repõe o `_pin` a "" antes da geração e rejeita os bytes ≥ 250 antes do `% 10`.
#   O PIN da corrida — cadeias de 20 ou mais dígitos seguidos nos ficheiros novos: 0 (todo o PIN de corrida tem 20).
# Código de saída: 0 tudo como esperado · 1 alguma contagem ≠ do esperado · 2 argumentos.
cd "$(dirname "$0")/../../.." || exit 9
G=${1:-}; BASE=${2:-bfe4c3c}; RA=${3:-1b907bc}; RN=${4:-e8f1a42}
[ -n "$G" ] && [ ! -f "$G" ] && { echo "o <godot> não existe" >&2; exit 2; }
C=rascunhos/servidor/autojogo/cenario-bancada.json
R=provas/ordem-caixa-relato/b7-correcoes-7
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
digitos_novos() {  # <mínimo> → ocorrências de cadeias de <mínimo> ou mais dígitos seguidos nos ficheiros novos de texto
  # Os sha256 (64 caracteres hexadecimais seguidos, como os do MANIFESTO e das listas da retoma) tiram-se antes: os
  # dígitos de dentro de um sha não são um PIN.
  local n=0 f
  for f in $novos; do [ -f "$f" ] && grep -Iq . "$f" && n=$((n + $(sed -E 's/[0-9a-fA-F]{64}//g' "$f" | grep -oE "[0-9]{$1,}" | wc -l))); done; echo $n
}
LANC=(provas/ordem-caixa-hud-jogadora/ferramentas/correr-prova-caixa-hud.sh provas/ordem-caixa-janela/ferramentas/correr-prova-caixa-janela.sh
      provas/ordem-caixa-manequim/ferramentas/correr-prova-caixa-manequim.sh provas/ordem-caixa/ferramentas/correr-prova-caixa.sh
      provas/ordem-caixa-relato/ferramentas/correr-prova-caixa-relato.sh)
soma() { awk -F: '{s+=$NF} END {print s+0}'; }

echo "# verificação do PIN (Ordem CAIXA-RELATO-B7-CORRECOES-7) · $(git rev-parse --short HEAD) · base $BASE"
echo "# só contagens; os valores nunca se escrevem. O PIN antigo vem de $RA, o PIN novo de 20 dígitos de $RN."
read -r fN oN <<< "$(na_arvore "$NOV")"
linha "PIN novo de 20 dígitos — ficheiros na árvore de trabalho (seguidos ou não)" "$fN" 0
linha "PIN novo de 20 dígitos — ocorrências na árvore de trabalho" "$oN" 0
linha "PIN novo de 20 dígitos — ficheiros seguidos (git grep)" "$(git grep -lF -- "$NOV" | grep -c .)" 0
read -r fA oA <<< "$(na_arvore "$ANT")"
linha "PIN antigo — ficheiros na árvore de trabalho (seguidos ou não)" "$fA" 0
linha "PIN antigo — ocorrências na árvore de trabalho" "$oA" 0
linha "PIN antigo — ficheiros novos ou mudados desde a base ($(printf '%s\n' "$novos" | grep -c .) ficheiros)" "$(nos_novos "$ANT")" 0
linha "PIN de corrida — cadeias de 20+ dígitos seguidos nos ficheiros novos" "$(digitos_novos 20)" 0
echo "(informativo) cadeias de 6+ dígitos seguidos nos ficheiros novos: $(digitos_novos 6) — números de linhas, sha, horas; nenhuma é um PIN (o antigo e o novo contam-se acima e o de corrida tem 20)"
linha "chave \"pin\" no cenário de bancada" "$(node -e 'process.stdout.write(String(Object.hasOwn(require("./'"$C"'"),"pin")))')" false
linha "servidor-info.json seguidos" "$(git ls-files | grep -c 'servidor-info\.json$')" 0
linha "servidor.log seguidos fora de suites/" "$(git ls-files | grep '/servidor\.log$' | grep -vc '/suites/')" 0
linha "cp do info ou do log do servidor nos 5 lançadores" "$(grep -cE '^[^#]*cp .*(info|servidor-prova|servidor-)' "${LANC[@]}" | soma)" 0
linha "cat do info nos 5 lançadores" "$(grep -cE '^[^#]*cat [^|]*info' "${LANC[@]}" | soma)" 0
linha "chave \"pin\" nos registos de b7-correcoes-7/" "$(grep -rlE '"pin"[[:space:]]*:' "$R" 2>/dev/null | grep -c .)" 0

# B1 (JD2): o `.pathname` saiu do código da cópia da caixa (os comentários podem citá-lo).
SC=provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs
linha "\`.pathname\` no código de $SC" "$(grep -vE '^[[:space:]]*//' "$SC" | grep -c '\.pathname')" 0
linha "fileURLToPath no código de $SC" "$(grep -vE '^[[:space:]]*//' "$SC" | grep -c 'fileURLToPath(')" 3
# B3 (JD4): o PIN do autojogo sem enviesamento e com a variável reposta.
AJ=rascunhos/cliente/autojogo/autojogo.gd
linha "autojogo.gd: \`_pin = \"\"\` antes da geração" "$(awk '/_pin = ""/{r=NR} /generate_random_bytes/{g=NR} END{print (r && g && r < g) ? "sim" : "não"}' "$AJ")" sim
linha "autojogo.gd: rejeição dos bytes ≥ 250 antes do % 10" "$(grep -cE 'if bytes\[i\] < 250 and' "$AJ")" 1
linha "autojogo.gd: \`% 10\` sem a rejeição na mesma linha ou na de cima" "$(awk '/^[[:space:]]*#/{next} /% 10/{ if (prev !~ /< 250/ && $0 !~ /< 250/) n++ } {prev=$0} END{print n+0}' "$AJ")" 0

# Recusas: sem --pin (ou com um PIN que não é de 6+ dígitos) nada arranca, e os TRÊS servidores saem com 2.
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
for s in provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs "$SC"; do
  timeout 30 node "$s" --porta=8840 --motor-falso --info="$T/i.json" > /dev/null 2>&1; r=$?
  linha "$s sem --pin → código" $r 2
  timeout 30 node "$s" --porta=8840 --motor-falso --pin=12ab56 --info="$T/i.json" > /dev/null 2>&1; r=$?
  linha "$s com --pin que não é só dígitos → código" $r 2
done
AS=rascunhos/servidor/autojogo/servidor-autojogo.mjs
timeout 30 node "$AS" --porta=8841 --motor-falso --info="$T/i.json" > "$T/aj.log" 2>&1; r=$?
linha "$AS sem --pin → código" $r 2
linha "$AS sem --pin → a mensagem «falta --pin»" "$(grep -c 'falta --pin' "$T/aj.log")" 1
timeout 30 node "$AS" --porta=8841 --motor-falso --pin=12ab56 --info="$T/i.json" > /dev/null 2>&1; r=$?
linha "$AS com --pin que não é só dígitos → código" $r 2
timeout 30 node "$AS" --porta=8841 --motor-falso --cenario="$T/nao-existe.json" --info="$T/i.json" > "$T/aj2.log" 2>&1; r=$?
linha "$AS sem --pin e com um --cenario que não existe → código (o PIN valida-se antes do cenário)" $r 2
linha "info escrito por um servidor recusado" "$([ -f "$T/i.json" ] && echo 1 || echo 0)" 0
# Arranques vivos com o cenário novo e um PIN fresco: o info sai sem a chave "pin", e a linha «pronto-…» também.
P=$(node -e 'const c=require("crypto");let s="";for(let i=0;i<20;i++)s+=c.randomInt(10);process.stdout.write(s)')
vivo() {  # <rótulo> <servidor> <porta> <prefixo da linha pronto>
  rm -f "$T/vivo.json" "$T/vivo.log"
  node "$2" --porta=$3 --motor-falso --pin="$P" --info="$T/vivo.json" --vida-max-s=30 > "$T/vivo.log" 2>&1 &
  local SRV=$!
  for i in $(seq 1 30); do [ -f "$T/vivo.json" ] && break; sleep 1; done
  kill $SRV 2>/dev/null; wait $SRV 2>/dev/null
  linha "arranque vivo $1 (cenário novo, PIN fresco): info pronto" "$(node -e 'process.stdout.write(String(require(process.argv[1]).pronto===true))' "$T/vivo.json" 2>/dev/null)" true
  linha "arranque vivo $1: chave \"pin\" no info" "$(cat "$T/vivo.json" 2>/dev/null | grep -c '"pin"')" 0
  linha "arranque vivo $1: o PIN da corrida no info ou no log do servidor" "$(cat "$T/vivo.json" "$T/vivo.log" 2>/dev/null | grep -cF -- "$P")" 0
  linha "arranque vivo $1: linha $4 no log" "$(grep -c "^$4 " "$T/vivo.log")" 1
}
vivo "do servidor do HUD" provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs 8842 pronto-prova-caixa-hud
vivo "do servidor da caixa" "$SC" 8844 pronto-prova-caixa
vivo "do servidor do autojogo" "$AS" 8845 pronto-autojogo
if [ -n "$G" ]; then
  for f in provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd provas/ordem-caixa-janela/ferramentas/prova_caixa_janela.gd provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd provas/ordem-caixa/ferramentas/prova_caixa_reentrar.gd; do
    timeout 60 "$G" --headless --path rascunhos/cliente -s "$PWD/$f" -- --servidor=127.0.0.1:8843 --saida="$T/s" > "$T/g.log" 2>&1; r=$?
    linha "$f sem --pin → código" $r 2
  done
fi
echo "falhas: $falhas"
[ $falhas -eq 0 ]
