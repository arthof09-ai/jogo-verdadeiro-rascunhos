#!/bin/bash
# Ordem CAIXA-RELATO-B7-CORRECOES-3: corre as mutações das correcções B1/B2/B4/B5 contra o teste do registo NOVO (o de
# agora) e o ANTIGO (o da <base>, por omissão a12b905, a ponta da fable/integracao-50 no lançamento). Cada mutação é
# feita numa CÓPIA do teste em ferramentas/ (o teste carrega o relato_caixa.gd da própria pasta), corrida e apagada; o
# teste cometido não muda. Cada corrida grava o seu log em <saída>/ e uma linha de resumo em <saída>/mutacoes.log: o
# código de saída, o «N de M», quantas linhas FALHA e RETIDA, e quantas vezes o valor-canário sai no log.
# PC Windows, Git Bash, na raiz do repo (num clone novo, primeiro `godot --headless --path rascunhos/cliente --import`):
#   bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes-b7-correcoes-3.sh <godot.exe> <pasta-saída> [<base>]
# Os valores são os canários de bancada (fictícios): «Canario-R1» e as chaves «alcunha» / «própria».
cd "$(dirname "$0")/../../.." || exit 9
G=${1:?godot}; O=${2:?saida}; BASE=${3:-a12b905}
F=provas/ordem-caixa-relato/ferramentas
COPIA=$F/_mutacao_teste.gd
trap 'rm -f "$COPIA" "$COPIA.uid"' EXIT INT TERM
mkdir -p "$O"
RES=$O/mutacoes.log
: > "$RES"
git show "$BASE:$F/teste_relato_caixa.gd" > "$O/.teste-antigo.gd" || exit 8
cp "$F/teste_relato_caixa.gd" "$O/.teste-novo.gd"

# A caixa do snapshot do caso do limpar() (igual nos dois testes) — onde as mutações R1/B2 põem o valor.
CAIXA='"caixa": {"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": [a], "fechada": false, "ultimo": a}}})'

mutar() {  # <teste-origem> <id> -> escreve a cópia mutada
  node - "$1" "$COPIA" "$2" "$CAIXA" <<'JS'
const fs = require('fs');
const [src, dst, id, caixa] = process.argv.slice(2);
let s = fs.readFileSync(src, 'utf8');
const troca = (a, b) => { if (s.split(a).length !== 2) { console.error('mutação ' + id + ': âncora não única: ' + a); process.exit(7); } s = s.replace(a, b); };
const comChave = (k, v) => caixa.replace('"ordemPor": "dinamico", ', '"ordemPor": "dinamico", ' + k + ': ' + v + ', ');
switch (id) {
  case 'nada': break;
  // B1 (R1): um valor SEM chave proibida ao lado.
  case 'r1-alcunha': troca(caixa, comChave('"alcunha"', '"Canario-R1"')); break;
  // B2: a chave com acento.
  case 'b2-propria-acento': troca(caixa, comChave('"própria"', '{"figuraId": a}')); break;
  // B2: o acento escrito à parte (o «o» seguido de U+0301, a marca combinante).
  case 'b2-propria-combinante': troca(caixa, comChave('"própria"', '{"figuraId": a}')); break;
  // B5: uma verificação removida.
  case 'b5-sem-uma-verificacao': troca('_ok(not R.desactualizado({}, R.caixa_actual({}, m3)), "sem caixa no snapshot: nada desactualizado")', 'pass'); break;
  // B4 (registo): o passo 3 sem o evento à espera — fica igual ao passo 2 (duplicação dos dois passos do meio).
  case 'b4-passo-3-igual-ao-2': troca('	evento.call(4, "movimento", a)', '	pass  # mutação: sem o evento à espera'); break;
  default: console.error('mutação desconhecida ' + id); process.exit(7);
}
fs.writeFileSync(dst, s);
JS
}

for teste in novo antigo; do
  for id in nada r1-alcunha b2-propria-acento b2-propria-combinante b5-sem-uma-verificacao b4-passo-3-igual-ao-2; do
    mutar "$O/.teste-$teste.gd" "$id" || exit 7
    L=$O/$id-teste-$teste.log
    timeout 120 "$G" --headless --path rascunhos/cliente -s "$PWD/$COPIA" 2>&1 | grep -v "^Godot Engine" > "$L"
    rc=${PIPESTATUS[0]}
    resumo=$(grep -o "[0-9]* de [0-9]* verificações passaram" "$L" | head -1)
    printf '%-24s teste %-6s rc=%s  %-32s FALHA=%s RETIDA=%s  Canario-R1=%s  "própria"=%s  combinante=%s\n' "$id" "$teste" "$rc" \
      "$resumo" "$(grep -c '^  FALHA' "$L")" "$(grep -c 'RETIDA' "$L")" "$(grep -o 'Canario-R1' "$L" | wc -l)" \
      "$(grep -o '"própria"' "$L" | wc -l)" "$(grep -o $'"própria"' "$L" | wc -l)" | tee -a "$RES"
  done
done
rm -f "$O/.teste-antigo.gd" "$O/.teste-novo.gd"
