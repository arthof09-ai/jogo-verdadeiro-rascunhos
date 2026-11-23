#!/bin/bash
# Ordem F51 da sentença da F25 (§3): a prova da mutação do canário, com o log cometido.
#   bash provas/ordem-f51-mutacao/correr-mutacao-canario.sh <godot> <pasta-tmp> [saída]
# Põe `false and` na condição de `no_relato()` (nomes_relato.gd:59) SÓ na cópia de trabalho, corre o canário
# (teste_nomes_relato.gd, --headless, como o CI), repõe o ficheiro com `git checkout` e confere que ficou igual ao commit.
# A saída crua do canário traz os nomes verdadeiros inteiros de propósito: fica em <pasta-tmp> (fora do repo) e o que se
# comete é a saída redigida pelo redigir-nomes.mjs (a redacção do §2 da F25). Em [saída] (por omissão esta pasta):
# teste-nomes-relato.mutacao.log (o log redigido), mutacao.diff (a mutação posta) e resumo.txt.
# Sai com 0 se a mutação deu o esperado (rc=1, 23 de 26, as 3 FALHA do §3 da F25, e — desde a F68 — o mutacao.diff com
# exactamente uma linha mudada, contada desde a F91 também pelo `git diff --numstat`), 1 se não, 9 se a cópia não está limpa.
cd "$(dirname "$0")/../.." || exit 9
G=${1:?godot}; T=${2:?pasta-tmp}
S=$PWD/${3:-provas/ordem-f51-mutacao}
F=provas/ordem-caixa-janela/ferramentas/nomes_relato.gd
CANARIO=provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd
mkdir -p "$S" "$T"
git diff --quiet -- "$F" || { echo "$F não está igual ao commit — não corro"; exit 9; }
[ "$(sed -n 59p "$F")" = $'\t\t\tif relato[i].contains(str(k)):' ] || { echo "$F:59 não é a condição de no_relato()"; exit 9; }

sed -i '59s/\tif relato\[i\]\.contains(str(k)):/\tif false and relato[i].contains(str(k)):/' "$F"
git diff -- "$F" > "$S/mutacao.diff"
# F68 (sentença da F51): o diff tem exactamente uma linha mudada — uma «-», uma «+», e a «-» é a linha 59 como estava.
# F91 (sentença da F66+F68): contam-se TODAS as linhas «-» e «+» (também as que só têm «-» ou «+», ou que começam por
# «--»/«++»), menos os cabeçalhos «--- » e «+++ »; e a contagem tem de coincidir com o `git diff --numstat`.
menos=$(( $(grep -c '^-' "$S/mutacao.diff") - $(grep -c '^--- ' "$S/mutacao.diff") ))
mais=$(( $(grep -c '^+' "$S/mutacao.diff") - $(grep -c '^+++ ' "$S/mutacao.diff") ))
numstat=$(git diff --numstat -- "$F" | cut -f1,2 | tr '\t' ' ')
umalinha=NÃO
[ "$menos" = 1 ] && [ "$mais" = 1 ] && [ "$numstat" = "1 1" ] \
  && grep -qFx -- $'-\t\t\tif relato[i].contains(str(k)):' "$S/mutacao.diff" \
  && grep -qFx -- $'+\t\t\tif false and relato[i].contains(str(k)):' "$S/mutacao.diff" && umalinha=sim
timeout 180 "$G" --headless --path rascunhos/cliente -s "$PWD/$CANARIO" > "$T/mutacao.cru.log" 2>&1
rc=$?
git checkout -- "$F"
git diff --quiet -- "$F" && reposto="sim (git diff vazio)" || reposto="NÃO"

node provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs "$T/mutacao.cru.log" --saida="$S/teste-nomes-relato.mutacao.log" 2> "$T/redigir.txt"
rr=$?
L="$S/teste-nomes-relato.mutacao.log"
total=$(grep "verificações passaram" "$L" | tr -d '\r')
falhas=$(grep "^  FALHA" "$L" | tr -d '\r' | LC_ALL=C sort -u)  # F68: sort -u (o uniq só junta as repetidas seguidas; F92: neste log a troca é preventiva — o uniq também dá 3)
nf=$(printf '%s\n' "$falhas" | grep -c "FALHA")
erros=$(grep -c -E "SCRIPT ERROR|Parse Error|Compile Error" "$L")
esperado=nao
[ $rc = 1 ] && [ $rr = 0 ] && [ "$nf" = 3 ] && [ "$erros" = 0 ] && [[ "$total" == *": 23 de 26 verificações passaram." ]] \
  && [ "$reposto" != "NÃO" ] && [ "$umalinha" = sim ] && esperado=sim

{
  echo "Ordem F51 — mutação do canário (§3 da F25), $(date -u +%Y-%m-%dT%H:%MZ)"
  echo "base: $(git rev-parse HEAD) ($(git branch --show-current))"
  echo "godot: $(head -1 "$L" | tr -d '\r')"
  echo "mutação: $F:59 — «if relato[i].contains(str(k)):» → «if false and relato[i].contains(str(k)):» (mutacao.diff)"
  echo "corrida: $G --headless --path rascunhos/cliente -s <raiz>/$CANARIO" | sed "s#$HOME#~#"
  echo "mutacao.diff: $menos linha(s) tirada(s), $mais posta(s) (git diff --numstat: $numstat) — exactamente uma linha mudada: $umalinha"
  echo "rc=$rc"
  echo "contagem: ${total#*: }"
  echo "FALHA distintas: $nf (todas saem duas vezes no log: o teste faz print e printerr)"
  printf '%s\n' "$falhas"
  echo "SCRIPT ERROR / Parse Error / Compile Error: $erros"
  echo "reposto com git checkout: $reposto"
  echo "log: teste-nomes-relato.mutacao.log — a saída do canário redigida pelo redigir-nomes.mjs (§2 da F25); a crua ficou fora do repo"
  echo "redacção: $(sed 's#^redigir-nomes: .*mutacao\.cru\.log: ##' "$T/redigir.txt")"
  echo "sha256 do log: $(sha256sum "$L" | cut -c1-64)"
  echo "esperado (rc=1, 23 de 26, as 3 FALHA, ficheiro reposto, diff de uma linha): $esperado"
} > "$S/resumo.txt"
cat "$S/resumo.txt"
[ $esperado = sim ]
