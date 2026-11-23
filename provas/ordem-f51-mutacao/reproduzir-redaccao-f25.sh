#!/bin/bash
# Ordem F51: o redigir-nomes.mjs reproduz a redacção do §2 da F25. Tira do histórico os 11 registos como estavam antes
# da limpeza (no pai do commit 081304e da F25), redige-os com a ferramenta e compara-os um a um, byte a byte, com o
# registo limpo da ponta.
#   bash provas/ordem-f51-mutacao/reproduzir-redaccao-f25.sh <pasta-tmp>
# Os registos de antes trazem os nomes verdadeiros inteiros: ficam em <pasta-tmp>, fora do repo, e a saída deste script
# só diz caminhos, contagens e «igual»/«DIFERE». Precisa do histórico (um clone completo; não corre num clone raso).
# Sai com 0 se os 11 forem iguais.
cd "$(dirname "$0")/../.." || exit 9
T=${1:?pasta-tmp}
OBRA=081304e
git cat-file -e "$OBRA^{commit}" 2>/dev/null || { echo "não há o commit $OBRA da F25 neste clone (clone raso?)"; exit 9; }
iguais=0; n=0
while read -r f; do
  n=$((n + 1))
  mkdir -p "$T/antes/$(dirname "$f")"
  git show "$OBRA^:$f" > "$T/antes/$f"
  node provas/ordem-caixa-relato/ferramentas/redigir-nomes.mjs "$T/antes/$f" --comparar="$f" 2> "$T/redigir.txt" && iguais=$((iguais + 1))
  sed "s#^redigir-nomes: .*/antes/#  redigido: #" "$T/redigir.txt"
done < <(git show --name-only --format= "$OBRA")
echo "base: $(git rev-parse --short HEAD); antes: $(git rev-parse --short "$OBRA^") (pai de $OBRA)"
echo "iguais byte a byte: $iguais de $n"
[ "$iguais" = "$n" ] && [ "$n" = 11 ]
