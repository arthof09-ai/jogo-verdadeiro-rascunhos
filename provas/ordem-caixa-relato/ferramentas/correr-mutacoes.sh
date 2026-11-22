#!/bin/bash
# Ordem CAIXA-RELATO-CORRECOES-3 (B7): corre as mutações de mutacoes.mjs, uma a uma, e escreve a cauda de cada corrida
# (o resumo «N de M», as linhas FALHA e o código de saída) num registo. Cada mutação é aplicada sobre os ficheiros
# limpos e desfeita a seguir; no fim, todos os ficheiros tocados voltam ao que eram (também se o script for
# interrompido). PC Windows, Git Bash, na raiz de um clone já importado:
#   bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes.sh <godot.exe> <vlab-completo.js> <pasta-tmp> <base|novo> <registo.log> [<commit-base>]
# Modo `base`: os 4 ficheiros das provas vêm do <commit-base> (por omissão 6a87b9e, fable/integracao-50) — reproduz os
# números da ordem anterior. Modo `novo`: os ficheiros como estão.
# CAIXA-RELATO-CORRECOES-4: modo `base4` — os ficheiros das provas de da6683e (fable/integracao-50, a base desta ordem),
# com as mutações de `novo`. Nas provas vivas, as linhas FALHA e o resumo lêem-se agora do relato.txt (o ficheiro que a
# prova deixa; na consola, uma linha reescrita aparece duas vezes). B2: conta-se quantas vezes um nome verdadeiro (das
# fichas da corrida, nome ≠ nomePublico) aparece nas linhas FALHA, no relato e na consola. Antes de ir para o registo
# (que é cometido), o harness troca qualquer nome verdadeiro por «‹nome verdadeiro›»: uma mutação que põe o nome no
# próprio resumo deixava-o lá. Com `SO="id1 id2"`, corre só essas mutações.
cd "$(dirname "$0")/../../.." || exit 9
G=${1:?godot}; MOTOR=${2:?motor}; T=${3:?tmp}; MODO=${4:?base|base4|novo}; LOG=${5:?registo}
BASE=${6:-$([ "$MODO" = base4 ] && echo da6683e || echo 6a87b9e)}
M=provas/ordem-caixa-relato/ferramentas/mutacoes.mjs
FICH=(provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd
      provas/ordem-caixa-relato/ferramentas/relato_caixa.gd provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd
      rascunhos/servidor/autojogo/fichas-bancada.json)
mkdir -p "$T/guarda" "$T/limpo"
for f in "${FICH[@]}"; do k=$(echo "$f" | tr / _); cp "$f" "$T/guarda/$k"; done
repor_guarda() { for f in "${FICH[@]}"; do k=$(echo "$f" | tr / _); cp "$T/guarda/$k" "$f"; done; }
trap repor_guarda EXIT INT TERM
# Os ficheiros limpos do modo (base: do commit; novo: os de agora). A lista e as substituições lêem-se do mutacoes.mjs
# de agora (o da base não o tem).
for f in "${FICH[@]}"; do k=$(echo "$f" | tr / _)
  if [ "$MODO" != novo ] && [ "$f" != rascunhos/servidor/autojogo/fichas-bancada.json ]; then git show "$BASE:$f" > "$T/limpo/$k" || exit 8
  else cp "$f" "$T/limpo/$k"; fi
done
repor_limpo() { for f in "${FICH[@]}"; do k=$(echo "$f" | tr / _); cp "$T/limpo/$k" "$f"; done; }

correr_teste() {  # <saída>
  timeout 120 "$G" --headless --path rascunhos/cliente -s "$PWD/provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd" > "$1" 2>&1
}
correr_prova() {  # <hud|manequim> <saída> <porta>
  local fer=provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd
  [ "$1" = manequim ] && fer=provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd
  local S="$T/saida-$1"; rm -rf "$S"; mkdir -p "$S"; rm -f "$T/info-mut.json"
  node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=$3 --semente=7 --info="$T/info-mut.json" \
    --motor="$MOTOR" --vida-max-s=900 > "$T/servidor-mut.log" 2>&1 &
  local SRV=$!
  for i in $(seq 1 30); do [ -f "$T/info-mut.json" ] && break; sleep 1; done
  timeout 900 "$G" --resolution 1280x720 --path rascunhos/cliente -s "$PWD/$fer" -- --servidor=127.0.0.1:$3 --saida="$S" > "$2" 2>&1
  local r=$?
  kill $SRV 2>/dev/null; wait $SRV 2>/dev/null
  return $r
}

{
  echo "# mutações — modo $MODO$([ "$MODO" != novo ] && echo " (ficheiros das provas de $BASE)") · $(date '+%Y-%m-%d %H:%M:%S %z') · $(git rev-parse --short HEAD)"
  echo "# Godot: $("$G" --version 2>/dev/null | tr -d '\r')  ·  motor sha256 $(sha256sum "$MOTOR" | cut -c1-12)…"
} > "$LOG"
porta=8810
nomes_verdadeiros() {  # das fichas como estão (já com a mutação): um por linha
  node -e 'for (const f of require(process.argv[1]).fichas) if (f.nome && f.nome !== f.nomePublico) console.log(f.nome)' \
    "$PWD/rascunhos/servidor/autojogo/fichas-bancada.json" | tr -d '\r'
}
conta_nomes() {  # <ficheiro> <nomes> → ocorrências (sem distinguir maiúsculas) dos nomes nas linhas FALHA
  local n=0 k
  [ -f "$1" ] || { echo 0; return; }
  while IFS= read -r k; do
    [ -n "$k" ] && n=$((n + $(grep -E "FALHA " "$1" | grep -oiF -- "$k" | wc -l)))
  done <<< "$2"
  echo $n
}
filtrar() {  # stdin → stdout, com os nomes <nomes> trocados por «‹nome verdadeiro›»
  local prog="" k
  while IFS= read -r k; do [ -n "$k" ] && prog="$prog;s/$k/‹nome verdadeiro›/Ig"; done <<< "$1"
  if [ -n "$prog" ]; then sed -e "${prog#;}"; else cat; fi
}
node "$M" lista "$MODO" | tr -d '\r' | while read -r id corrida; do
  if [ -n "$SO" ] && [[ " $SO " != *" $id "* ]]; then continue; fi
  repor_limpo
  if ! node "$M" aplicar "$MODO" "$id" 2> "$T/erro-mut.txt"; then
    { echo; echo "== $id ($corrida) — NÃO APLICOU: $(cat "$T/erro-mut.txt")"; } >> "$LOG"; continue
  fi
  saida="$T/mut-$MODO-$id.log"
  if [ "$corrida" = teste ]; then correr_teste "$saida"; else porta=$((porta + 1)); correr_prova "$corrida" "$saida" $porta; fi
  rc=$?
  nomes=$(nomes_verdadeiros)
  fonte="$saida"; [ "$corrida" != teste ] && fonte="$T/saida-$corrida/relato.txt"
  {
    echo
    echo "== $id ($corrida) — $(node "$M" diz "$MODO" "$id")"
    echo "rc=$rc"
    if [ "$corrida" != teste ]; then
      echo "relato.txt: $(wc -l < "$fonte" 2>/dev/null) linhas, $(grep -c 'verificações passaram' "$fonte" 2>/dev/null) resumo(s); nomes verdadeiros nas linhas FALHA: relato $(conta_nomes "$fonte" "$nomes"), consola $(conta_nomes "$saida" "$nomes")"
    fi
    {
      grep -E "SCRIPT ERROR|Parse Error|Compile Error" "$saida" | head -3
      grep -E "^  FALHA " "$fonte" | awk '!v[$0]++' | cut -c1-400
      grep -E "verificações passaram|verificações\)" "$fonte" | tail -2
    } | filtrar "$nomes"
  } >> "$LOG"
  echo "$id $corrida rc=$rc $(grep -E 'verificações passaram' "$fonte" | tail -1 | filtrar "$nomes")"
done
repor_guarda
git status --short -- "${FICH[@]}"
