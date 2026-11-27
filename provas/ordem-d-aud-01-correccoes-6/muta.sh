#!/bin/bash
# Funções comuns da ORDEM-D-AUD-01-CORRECCOES-6 (lidas por j4.sh e suites.sh). O caminho é o da CORRECCOES-5 (padrão
# B3 da CORRECCOES-4): MESTRE_COMANDOS + timeout 300, log com a linha do comando e o diff, exit no resumo.txt,
# ficheiro reposto com git checkout e git diff conferido vazio. A diferença: o ORIGINAL e a MUTADA podem ter várias
# linhas (o J1 tira o «if novas != _casas:» e a mutação SEM-J1 repõe o bloco de 4 linhas); a contagem é feita em
# Python sobre o texto exacto, não com grep -x.
set -u
R="$(git rev-parse --show-toplevel)"; B="$(cd "$R/.." && pwd)"; L="${L:-$B/tmp/suites}"
G="${GODOT:?GODOT por definir}"; P="${PYTHON:-python}"
mkdir -p "$L"
ALVO=rascunhos/cliente/cenas/mestre/aba_agir.gd
conta() { TXT="$1" "$P" -c "
import os; print(open('$R/$ALVO',encoding='utf8',newline='').read().replace('\r','').count(os.environ['TXT']+'\n'))"; }

# muta <nome> <bloco original> <bloco mutado> — corre o pecas_mestre com a mutação e repõe o ficheiro.
muta() {
  local n="$1" ORIGINAL="$2" MUTADA="$3" e
  cd "$R"
  if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO já tem alterações por cometer"; exit 1; fi
  if [ "$(conta "$ORIGINAL")" != "1" ]; then echo "PARAR: o bloco a mutar não está (uma vez) em $ALVO"; exit 1; fi
  trap 'cd "$R" && git checkout -- "$ALVO"' EXIT
  ORIGINAL="$ORIGINAL" MUTADA="$MUTADA" "$P" -c "
import os
p='$ALVO'; s=open(p,encoding='utf8',newline='').read()
a=os.environ['ORIGINAL']+'\n'; b=os.environ['MUTADA']+'\n'
assert s.count(a)==1; open(p,'w',encoding='utf8',newline='').write(s.replace(a,b))"
  if [ "$(conta "$MUTADA")" != "1" ] || [ "$(conta "$ORIGINAL")" != "0" ]; then echo "PARAR: a mutação não ficou feita"; exit 1; fi
  { echo "# comando: (mutação $n em $ALVO, o diff vai abaixo; reposta com git checkout)"
    echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/suites/comandos-$n.jsonl timeout 300 Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/pecas_mestre.gd"
    git diff -U0 -- "$ALVO" | grep -E '^[-+][^-+]' | sed 's/^/# diff: /'; } > "$L/$n.log"
  cd "$R/rascunhos/cliente"
  MESTRE_COMANDOS="$L/comandos-$n.jsonl" timeout 300 "$G" --headless --path . -s res://testes/pecas_mestre.gd >> "$L/$n.log" 2>&1; e=$?
  cd "$R" && git checkout -- "$ALVO" && trap - EXIT
  if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO não ficou reposto"; exit 1; fi
  echo "$n exit=$e falhas=$(grep -c '  FALHA ' "$L/$n.log") falhas-correccoes-6=$(grep -c '  FALHA D-AUD-01-CORRECCOES-6' "$L/$n.log") falhas-correccoes-5=$(grep -c '  FALHA D-AUD-01-CORRECCOES-5:' "$L/$n.log") falhas-correccoes-5-B2=$(grep -c '  FALHA D-AUD-01-CORRECCOES-5 (B2):' "$L/$n.log") falhas-correccoes-4=$(grep -c '  FALHA D-AUD-01-CORRECCOES-4:' "$L/$n.log") scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$n.log") fim=«$(grep 'verificações passaram' "$L/$n.log" | tail -1)» reposto=$(git diff --quiet -- "$ALVO" && echo sim || echo NAO)" >> "$L/resumo.txt"
}

# pecas <nome> — o pecas_mestre sem mutação.
pecas() {
  local n="$1" e
  cd "$R/rascunhos/cliente"
  echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/suites/comandos-$n.jsonl timeout 300 Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://testes/pecas_mestre.gd" > "$L/$n.log"
  MESTRE_COMANDOS="$L/comandos-$n.jsonl" timeout 300 "$G" --headless --path . -s res://testes/pecas_mestre.gd >> "$L/$n.log" 2>&1; e=$?
  echo "$n exit=$e falhas=$(grep -c '  FALHA ' "$L/$n.log") scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$n.log") fim=«$(grep 'verificações passaram' "$L/$n.log" | tail -1)»" >> "$L/resumo.txt"
  cd "$R"
}

redigir() { sed -i -e "s|$B|<sede>|g" -e "s|$(cygpath -m "$B" 2>/dev/null || echo "$B")|<sede>|g" "$L"/*.log; }
