#!/bin/bash
# J-F8 (ORDEM-PLANO-2-F1-ADENDA-J-F7-J-F8, 26/11/2026) — confere o falhas()/muta() dos dois guiões sobre logs sintéticos.
# Tira as funções muta() e falhas() de cada suites.sh tal como estão cometidas e corre o muta() a sério (mutação num
# ficheiro de um repo git temporário, reposta com git checkout), com um «comando» que só despeja um log sintético:
#   node-sem-resumo        o log da corrida focada do J-F1 cortado no «ℹ tests» (o node morreu antes do resumo): 7 «✖», sem
#                          «ℹ fail N» e sem o cabeçalho «✖ failing tests:»
#   node-morto-na-lista    o mesmo log sem as linhas «ℹ …», mas com a lista final «✖ failing tests:» (que repete os 7)
#   node-completo          o log cometido, inteiro (controlo: «ℹ fail 7»)
#   godot-3-falhas         3 linhas «  FALHA », sem resumo
#   godot-verde            «12 verificações passaram» (controlo: 0 legítimo)
#   sem-marcas             só um «✔» e lixo, sem falha nem resumo → o muta() tem de abortar com PARAR
#   bash provas/ordem-plano-2-f1-adenda/j-f/j-f8-falhas-sem-resumo/conferir-falhas.sh
set -u
R0="$(git rev-parse --show-toplevel)"; cd "$R0"
FOC=provas/ordem-plano-2-f1-adenda/j-f/j-f2-corrida-focada-arvore-limpa/d-aud-12-snapshot-SEM-SUFIXO-NA-FIGURA-PUBLICA.log
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/sint"
sed '/^ℹ tests /,$d' "$FOC" > "$T/sint/node-sem-resumo.log"
grep -v '^ℹ ' "$FOC" > "$T/sint/node-morto-na-lista.log"
cp "$FOC" "$T/sint/node-completo.log"
printf 'a correr\n  FALHA a\n  ok b\n  FALHA c\n  FALHA d\n' > "$T/sint/godot-3-falhas.log"
printf 'a correr\n  ok a\n12 verificações passaram\n' > "$T/sint/godot-verde.log"
printf '✔ um teste (1ms)\nSegmentation fault\n' > "$T/sint/sem-marcas.log"
antigo() { local f; f=$(grep -oE '^ℹ fail [0-9]+' "$1" | tail -1 | grep -oE '[0-9]+$'); [ -n "$f" ] && echo "$f" || grep -cE '  FALHA |^not ok' "$1"; }
for G in provas/ordem-plano-2-f1-adenda/suites.sh provas/ordem-plano-2-f1/suites.sh; do
  echo "== $G (cópia de trabalho, sha256 $(sha256sum "$G" | cut -c1-12))"
  FUN="$( sed -n '/^muta() {/,/^}/p' "$G"; sed -n '/^falhas() {/,/echo "\$f"; }$/p' "$G" )"
  for s in node-sem-resumo node-morto-na-lista node-completo godot-3-falhas godot-verde sem-marcas; do
    r="$T/r-$s"; rm -rf "$r"; mkdir -p "$r/L"; git -C "$r" init -q; printf 'x\nORIGINAL\ny\n' > "$r/alvo.txt"
    git -C "$r" add alvo.txt; git -C "$r" -c user.name=t -c user.email=t@t commit -qm base
    out="$( cd "$r" && R="$r" L="$r/L" P="${PYTHON:-python}" bash -c "$FUN"'
      muta '"$s"' alvo.txt ORIGINAL MUTADA cat "$0"; echo "(sem abortar)"' "$T/sint/$s.log" 2>&1 )"; e=$?
    printf '%-20s antigo=%-2s muta_exit=%s resumo=«%s» saida=«%s» reposto=%s\n' "$s" "$(antigo "$T/sint/$s.log")" "$e" \
      "$(sed 's/ fim=.*//' "$r/L/resumo.txt" 2>/dev/null)" "$(echo "$out" | sed "s|$r|<tmp>|g" | tr '\n' ' ')" \
      "$(git -C "$r" diff --quiet && echo sim || echo NAO)"
  done
done
