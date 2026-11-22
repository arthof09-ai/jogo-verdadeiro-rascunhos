#!/bin/bash
# Ordem CAIXA-RELATO-B7-CORRECOES-5: a cópia do script da B7-CORRECOES-4 (que fica como estava — é o registo dessa
# ordem), com as correcções B2, B4 e B5 da sentença da B7-CORRECOES-4. As mutações e os esperados são os MESMOS 34.
#  - B2 (D2): os logs saem sem o caminho da pasta temporária. Os rastos do Godot (`SCRIPT ERROR … at: (…)`) traziam
#    `C:/Users/<utilizador>/AppData/Local/Temp/mutacoes-relato-…/`; cada log é limpo logo a seguir à corrida (a pasta
#    nas três grafias — `cygpath -m`, `cygpath -w` e a do Git Bash — passa a `<tmp>`). No fim, se algum log da saída
#    ainda trouxer a pasta temporária, o caminho da casa ou o nome do utilizador, o script sai com 6.
#  - B4 (D4): os argumentos validam-se ANTES de tudo: sem <godot> ou sem <saída>, com <godot> que não existe, ou com
#    argumentos a mais → uso no stderr e código 2; uma <base> que o git não conhece → código 3.
#  - B5 (D5): um Godot que morre a meio (código ≠ 0 e ≠ 1 — p. ex. 124 do `timeout`, 141 de SIGPIPE, um disco cheio),
#    um log vazio ou sem a linha «N de M verificações passaram» já NÃO contam como «NAO-BATE»: a linha do mutacoes.log
#    diz «FALHA-DA-CORRIDA» (com o motivo) e o script sai com 4 — a corrida não é prova de nada, nem a favor nem contra.
#    Inclui-se aqui, por decisão da sentença, a correcção do separador não-ASCII (a mutação b5-separador-nao-ascii).
# Códigos de saída: 0 todas batem · 1 alguma não bate · 2 argumentos · 3 base desconhecida · 4 falha da corrida
# (Godot) · 6 caminho pessoal num log · 7 mutação (âncora não única / desconhecida) · 8 pasta/cópia · 9 cd.
#
# --- o cabeçalho da B7-CORRECOES-4 ---
# Ordem CAIXA-RELATO-B7-CORRECOES-4: corre as mutações das correcções B1/B2/B5 (e as de regressão da B7-CORRECOES-3)
# contra o teste do registo NOVO (o da árvore de trabalho), o ANTIGO (o de <base>, por omissão c847966, a ponta da
# fable/integracao-50 no lançamento — o teste da B7-CORRECOES-3) e, para a reprodução do R1, o de <base-r1> (por
# omissão a12b905, o de antes da B7-CORRECOES-3).
#
# B4 (D4) da sentença da B7-CORRECOES-3:
#  - CÓPIA ÚNICA POR CORRIDA: cada corrida trabalha numa pasta sua (`mktemp -d`), com a cópia mutada do teste e o
#    relato_caixa.gd DA MESMA VERSÃO ao lado (o teste carrega-o da própria pasta). Nada se escreve em ferramentas/; duas
#    corridas ao mesmo tempo não colidem. A pasta apaga-se no fim (`trap`).
#  - CÓDIGO DE SAÍDA FIEL: cada mutação tem o resultado ESPERADO (código do Godot, se o valor-canário ecoa ou não, e —
#    nas sondas B5 — se a `PROIBIDAS` o nomeia). O script sai com 0 só se TODAS baterem; 1 se alguma não bater (a linha
#    leva «NAO-BATE»); 2–9 se a própria corrida falhar (argumentos, git, node, mutação com âncora não única).
#
# Cada corrida grava o seu log em <saída>/<mutação>-teste-<versão>.log e uma linha em <saída>/mutacoes.log: código,
# «N de M», linhas FALHA e RETIDA, quantas vezes o canário sai no log, se a PROIBIDAS o nomeia, e BATE/NAO-BATE.
# PC Windows, Git Bash, na raiz do repo (num clone novo, primeiro `godot --headless --path rascunhos/cliente --import`):
#   bash provas/ordem-caixa-relato/ferramentas/correr-mutacoes-b7-correcoes-5.sh <godot.exe> <pasta-saída> [<base>] [<base-r1>]
# Os valores são canários de bancada (fictícios): «Canario-R1», «turno», «42», as chaves «alcunha», «própria», «maſter».
USO='uso: correr-mutacoes-b7-correcoes-5.sh <godot.exe> <pasta-saída> [<base>] [<base-r1>]'
# B4: validar os argumentos antes de mexer em qualquer coisa (antes do cd, para o <godot> relativo valer como foi dado).
if [ $# -lt 2 ] || [ $# -gt 4 ] || [ -z "$1" ] || [ -z "$2" ]; then echo "$USO" >&2; exit 2; fi
if [ ! -f "$1" ]; then echo "o <godot> não existe: $1" >&2; echo "$USO" >&2; exit 2; fi
G=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); O=$2; BASE=${3:-c847966}; BASE_R1=${4:-a12b905}
case "$O" in /*|[A-Za-z]:*) ;; *) O=$PWD/$O ;; esac
cd "$(dirname "$0")/../../.." || exit 9
for b in "$BASE" "$BASE_R1"; do
  git rev-parse --verify --quiet "$b^{commit}" > /dev/null || { echo "base desconhecida do git: $b" >&2; exit 3; }
done
F=provas/ordem-caixa-relato/ferramentas
D=$(mktemp -d "${TMPDIR:-/tmp}/mutacoes-relato-b7c5.XXXXXX") || exit 8
trap 'rm -rf "$D"' EXIT INT TERM
caminho() { if command -v cygpath > /dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
# B2: as grafias da pasta temporária que o Godot e o bash podem escrever num log (sem repetidas).
TMP_GRAFIAS=$( { echo "$D"; if command -v cygpath > /dev/null; then cygpath -m "$D"; cygpath -w "$D"; fi; } | sort -u)
limpar_log() {  # <log>: troca a pasta temporária por <tmp>, sem distinguir maiúsculas (o Windows não distingue)
  local g
  while IFS= read -r g; do
    [ -n "$g" ] && TMP_G=$g perl -pi -e 's/\Q$ENV{TMP_G}\E/<tmp>/gi' "$1"
  done <<< "$TMP_GRAFIAS"
}

mkdir -p "$O" || exit 8
RES=$O/mutacoes.log
: > "$RES"
for v in novo antigo r1; do mkdir -p "$D/$v" "$D/fonte-$v"; done
cp "$F/teste_relato_caixa.gd" "$D/fonte-novo/teste.gd" && cp "$F/relato_caixa.gd" "$D/novo/relato_caixa.gd" || exit 8
git show "$BASE:$F/teste_relato_caixa.gd" > "$D/fonte-antigo/teste.gd" && git show "$BASE:$F/relato_caixa.gd" > "$D/antigo/relato_caixa.gd" || exit 8
git show "$BASE_R1:$F/teste_relato_caixa.gd" > "$D/fonte-r1/teste.gd" && git show "$BASE_R1:$F/relato_caixa.gd" > "$D/r1/relato_caixa.gd" || exit 8

# mutar <versão> <id>: escreve $D/<versão>/_mutacao_teste.gd e imprime 2 linhas — o canário (como sai no log) e o nome
# que a PROIBIDAS deve dar (ou «-»). Os caracteres não-ASCII das sondas vão em \u, para se lerem aqui.
mutar() {
  node - "$D/fonte-$1/teste.gd" "$D/$1/_mutacao_teste.gd" "$2" <<'JS'
const fs = require('fs');
const [src, dst, id] = process.argv.slice(2);
let s = fs.readFileSync(src, 'utf8');
const troca = (a, b) => { if (s.split(a).length !== 2) { console.error('mutação ' + id + ': âncora não única: ' + a); process.exit(7); } s = s.replace(a, b); };
// A caixa do snapshot do caso do limpar() (igual nas três versões) — onde as mutações B1/B2/B5 põem o valor.
const CAIXA = '"caixa": {"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": [a], "fechada": false, "ultimo": a}}})';
const naCaixa = (a, b) => troca(CAIXA, CAIXA.replace(a, b));
const comChave = (k, v) => naCaixa('"ordemPor": "dinamico", ', '"ordemPor": "dinamico", ' + k + ': ' + v + ', ');
let canario = '-', nome = '-';
switch (id) {
  case 'nada': break;
  // R1 (a reprodução): um valor sem chave proibida ao lado.
  case 'r1-alcunha': comChave('"alcunha"', '"Canario-R1"'); canario = 'Canario-R1'; break;
  // B1 (D1): valores com a forma errada debaixo de chaves permitidas.
  case 'b1-ultimo-turno': naCaixa('"ultimo": a', '"ultimo": "turno"'); canario = '"ultimo":"turno"'; break;
  case 'b1-ultimo-42': naCaixa('"ultimo": a', '"ultimo": 42'); canario = '"ultimo":42'; break;
  case 'b1-ligada-texto': naCaixa('"ligada": true', '"ligada": "turno"'); canario = '"ligada":"turno"'; break;
  case 'b1-fechada-numero': naCaixa('"fechada": false', '"fechada": 0'); canario = '"fechada":0'; break;
  case 'b1-ordempor-turno': naCaixa('"ordemPor": "dinamico"', '"ordemPor": "turno"'); canario = '"ordemPor":"turno"'; break;
  case 'b1-ordem-palavra': naCaixa('"ordem": [a]', '"ordem": [a, "dinamico"]'); canario = '"dinamico"]'; break;
  // B2 (D2), o limite registado: um 17-hex qualquer passa por id.
  case 'b2-ultimo-17hex': naCaixa('"ultimo": a', '"ultimo": "0123456789abcdef0"'); canario = '0123456789abcdef0'; break;
  // Regressão da B7-CORRECOES-3 (B2): a chave com acento, pré-composta e combinante (U+0301).
  case 'b2-propria-acento': comChave('"própria"', '{"figuraId": a}'); canario = 'própria'; nome = '"propria"'; break;
  case 'b2-propria-combinante': comChave('"própria"', '{"figuraId": a}'); canario = 'própria'; nome = '"propria"'; break;
  // B5 (D5): as sondas da conferência — o s longo U+017F e a marca U+20D0.
  case 'b5-s-longo': comChave('"maſter"', 'true'); canario = 'maſter'; nome = '"master"'; break;
  case 'b5-marca-20d0': comChave('"pro⃐pria"', '{"figuraId": a}'); canario = 'pro⃐pria'; nome = '"propria"'; break;
  // B5: um carácter não-ASCII que _normal não traduz (U+0237) servia de separador — «1ȷe» dava «1» e «e», permitidas.
  case 'b5-separador-nao-ascii': troca('R.linha("1", snap_caixa, snap, act)', 'R.linha("1ȷe", snap_caixa, snap, act)'); canario = '1ȷe'; break;
  // Regressão da B7-CORRECOES-3: B5 (uma verificação removida) e B4 (o passo 3 igual ao 2, o limite registado).
  case 'b5-sem-uma-verificacao': troca('_ok(not R.desactualizado({}, R.caixa_actual({}, m3)), "sem caixa no snapshot: nada desactualizado")', 'pass'); break;
  case 'b4-passo-3-igual-ao-2': troca('\tevento.call(4, "movimento", a)', '\tpass  # mutação: sem o evento à espera'); break;
  default: console.error('mutação desconhecida ' + id); process.exit(7);
}
fs.writeFileSync(dst, s);
console.log(canario); console.log(nome);
JS
}

# O esperado de cada <mutação>:<versão> = «código ecos nomeada»: código do Godot (0/1); ecos 0 = o canário não sai no
# log, + = sai (o defeito ou o limite), - = sem canário; nomeada + = a PROIBIDAS nomeia-o, 0 = não nomeia, - = não conta.
declare -A ESP=(
  [nada:novo]="0 - -"                     [nada:antigo]="0 - -"                     [nada:r1]="0 - -"
  [r1-alcunha:novo]="1 0 -"               [r1-alcunha:antigo]="1 0 -"               [r1-alcunha:r1]="0 + -"
  [b1-ultimo-turno:novo]="1 0 -"          [b1-ultimo-turno:antigo]="0 + -"
  [b1-ultimo-42:novo]="1 0 -"             [b1-ultimo-42:antigo]="0 + -"
  [b1-ligada-texto:novo]="1 0 -"          [b1-ligada-texto:antigo]="0 + -"
  [b1-fechada-numero:novo]="1 0 -"        [b1-fechada-numero:antigo]="0 + -"
  [b1-ordempor-turno:novo]="1 0 -"        [b1-ordempor-turno:antigo]="0 + -"
  [b1-ordem-palavra:novo]="1 0 -"         [b1-ordem-palavra:antigo]="0 + -"
  [b2-ultimo-17hex:novo]="0 + -"          [b2-ultimo-17hex:antigo]="0 + -"
  [b2-propria-acento:novo]="1 0 +"        [b2-propria-acento:antigo]="1 0 +"
  [b2-propria-combinante:novo]="1 0 +"    [b2-propria-combinante:antigo]="1 0 +"
  [b5-s-longo:novo]="1 0 +"               [b5-s-longo:antigo]="1 0 0"
  [b5-marca-20d0:novo]="1 0 +"            [b5-marca-20d0:antigo]="1 0 0"
  [b5-separador-nao-ascii:novo]="1 0 -"   [b5-separador-nao-ascii:antigo]="0 + -"
  [b5-sem-uma-verificacao:novo]="1 - -"   [b5-sem-uma-verificacao:antigo]="1 - -"
  [b4-passo-3-igual-ao-2:novo]="0 - -"    [b4-passo-3-igual-ao-2:antigo]="0 - -"
)
ORDEM_IDS="nada r1-alcunha b1-ultimo-turno b1-ultimo-42 b1-ligada-texto b1-fechada-numero b1-ordempor-turno b1-ordem-palavra
  b2-ultimo-17hex b2-propria-acento b2-propria-combinante b5-s-longo b5-marca-20d0 b5-separador-nao-ascii
  b5-sem-uma-verificacao b4-passo-3-igual-ao-2"

nao_batem=0; falhas_corrida=0
for versao in novo antigo r1; do
  for id in $ORDEM_IDS; do
    esp=${ESP[$id:$versao]}
    [ -z "$esp" ] && continue
    saida_m=$(mutar "$versao" "$id") || exit 7
    canario=$(sed -n 1p <<< "$saida_m"); nome=$(sed -n 2p <<< "$saida_m")
    L=$O/$id-teste-$versao.log
    timeout 120 "$G" --headless --path rascunhos/cliente -s "$(caminho "$D/$versao/_mutacao_teste.gd")" 2>&1 | grep -v "^Godot Engine" > "$L"
    st=("${PIPESTATUS[@]}"); rc=${st[0]}
    limpar_log "$L"
    resumo=$(grep -o "[0-9]* de [0-9]* verificações passaram" "$L" | head -1)
    # B5: a corrida tem de ter chegado ao fim para contar. Se não chegou, não é BATE nem NAO-BATE.
    motivo=
    if [ "$rc" != 0 ] && [ "$rc" != 1 ]; then motivo="o Godot saiu com $rc"
    elif [ "${st[1]}" -gt 1 ]; then motivo="o filtro do log saiu com ${st[1]}"
    elif [ ! -s "$L" ]; then motivo="log vazio"
    elif [ -z "$resumo" ]; then motivo="sem a linha «N de M verificações passaram»"
    fi
    if [ -n "$motivo" ]; then
      falhas_corrida=$((falhas_corrida + 1))
      printf '%-24s teste %-6s rc=%s  FALHA-DA-CORRIDA (%s)  esperado «%s»\n' "$id" "$versao" "$rc" "$motivo" "$esp" | tee -a "$RES"
      continue
    fi
    ecos=-; [ "$canario" != "-" ] && ecos=$(grep -oF -- "$canario" "$L" | wc -l)
    nomeada=-; [ "$nome" != "-" ] && nomeada=$(grep 'RETIDA' "$L" | grep -cF -- "$nome")
    read -r e_rc e_ecos e_nome <<< "$esp"
    bate=BATE
    [ "$rc" != "$e_rc" ] && bate=NAO-BATE
    case "$e_ecos" in 0) [ "$ecos" = 0 ] || bate=NAO-BATE ;; +) [ "$ecos" != - ] && [ "$ecos" -gt 0 ] || bate=NAO-BATE ;; esac
    case "$e_nome" in 0) [ "$nomeada" = 0 ] || bate=NAO-BATE ;; +) [ "$nomeada" != - ] && [ "$nomeada" -gt 0 ] || bate=NAO-BATE ;; esac
    [ "$bate" = BATE ] || nao_batem=$((nao_batem + 1))
    printf '%-24s teste %-6s rc=%s  %-32s FALHA=%s RETIDA=%s  canário=%s nomeada=%s  esperado «%s»  %s\n' "$id" "$versao" "$rc" \
      "$resumo" "$(grep -c '^  FALHA' "$L")" "$(grep -c 'RETIDA' "$L")" "$ecos" "$nomeada" "$esp" "$bate" | tee -a "$RES"
  done
done
echo "mutações que não batem com o esperado: $nao_batem" | tee -a "$RES"
echo "corridas que falharam (FALHA-DA-CORRIDA): $falhas_corrida" | tee -a "$RES"
# B2: nenhum log da saída leva a pasta temporária, a casa ou o nome do utilizador.
pessoais=$( { echo "$TMP_GRAFIAS"; echo "$HOME"; command -v cygpath > /dev/null && cygpath -m "$HOME"; echo "${USERNAME:-${USER:-}}"; } |
  awk 'length($0) >= 3' | sort -u)
com_pessoal=0
for L in "$O"/*.log; do
  while IFS= read -r p; do
    if grep -qiF -- "$p" "$L"; then echo "caminho pessoal em $(basename "$L")" >&2; com_pessoal=$((com_pessoal + 1)); break; fi
  done <<< "$pessoais"
done
echo "logs com caminho pessoal: $com_pessoal" | tee -a "$RES"
[ "$falhas_corrida" -eq 0 ] || exit 4
[ "$com_pessoal" -eq 0 ] || exit 6
[ "$nao_batem" -eq 0 ] && exit 0 || exit 1
