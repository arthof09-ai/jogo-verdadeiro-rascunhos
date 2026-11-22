# B1 (CAIXA-RELATO-CORRECOES-11): os 26 casos da CORRECOES-10 (22 do mecânico + H01 + R01–R03) + R04–R06 (raiz da unidade com mais de uma barra)
#   + X01–X02 (guardas: C:/// rejeitado; C://Users/t, uma pasta a sério depois das barras, continua aceite).
#   bash b1-mecanico.sh <absolutizar.sh>    → uma linha por caso: OK/ERRO, o esperado e o obtido; no fim, N de 31.
ORIGEM=/c/Users/t/origem
ORIGEM_ERR=$(mktemp)
. "$1"
ok=0; n=0
caso() {  # <id> <HOME> <entrada> <esperado: caminho, ou FALHA:<pedaço da mensagem>>
  local id=$1 h=$2 e=$3 esp=$4 X=$3 obt rc
  if HOME=$h absolutizar X "caso" 2>"$ORIGEM_ERR"; then obt=$X; else rc=$?; obt="FALHA rc=$rc — $(cat "$ORIGEM_ERR")"; fi
  n=$((n+1))
  case "$esp" in
    FALHA:*) if [[ $obt == FALHA* && $obt == *"${esp#FALHA:}"* ]]; then r=OK; ok=$((ok+1)); else r=ERRO; fi ;;
    *) if [ "$obt" = "$esp" ]; then r=OK; ok=$((ok+1)); else r=ERRO; fi ;;
  esac
  printf '%-4s %-5s HOME=%-14s %-26s esperado: %s\n%37s obtido:   %s\n' "$id" "$r" "«$h»" "«$e»" "$esp" "" "$obt"
}
H=/c/Users/t
caso M01 $H '~/x/tmp'                  /c/Users/t/x/tmp
caso M02 $H '~'                        /c/Users/t
caso M03 $H '~\x'                      /c/Users/t/x
caso M04 $H '~root/x'                  'FALHA:~utilizador não é suportado'
caso M05 $H '\\servidor\partilha\tmp'  'FALHA:caminho de rede (UNC)'
caso M06 $H '//servidor/partilha/tmp'  'FALHA:caminho de rede (UNC)'
caso M07 $H '\/servidor/partilha'      'FALHA:caminho de rede (UNC)'
caso M08 $H '/\x'                      'FALHA:caminho de rede (UNC)'
caso M09 $H 'C:tmp'                    'FALHA:sem barra é relativo à pasta corrente'
caso M10 $H 'C:'                       'FALHA:sem barra é relativo à pasta corrente'
caso M11 $H '\tmp\sub'                 C:/tmp/sub
caso M12 $H '/c/abs/tmp'               /c/abs/tmp
caso M13 $H 'C:/abs/tmp'               C:/abs/tmp
caso M14 $H 'C:\abs\tmp'               C:/abs/tmp
caso M15 $H 'tmp/rel'                  /c/Users/t/origem/tmp/rel
caso M16 $H './tmp'                    /c/Users/t/origem/./tmp
caso M17 $H '..\tmp\rel'               /c/Users/t/origem/../tmp/rel
caso M18 $H '/tmp/x'                   /tmp/x
caso M19 casa-relativa '~/x'           'FALHA:não é absoluto'
caso M20 'C:/Users/t' '~/x'            C:/Users/t/x
caso M21 'C:\Users\t' '~\x'            C:/Users/t/x
caso M22 /c/Users/t/ '~/x'             /c/Users/t//x
caso H01 / '~/x'                       'FALHA:é a raiz, não uma pasta pessoal'
caso R01 'C:/' '~/x'                   'FALHA:é a raiz da unidade C:, não uma pasta pessoal'
caso R02 'C:\' '~/x'                   'FALHA:é a raiz da unidade C:, não uma pasta pessoal'
caso R03 'C:'  '~/x'                   'FALHA:não é absoluto'
caso R04 'C://'  '~/x'                 'FALHA:é a raiz da unidade C:, não uma pasta pessoal'
caso R05 'C:\\' '~/x'               'FALHA:é a raiz da unidade C:, não uma pasta pessoal'
caso R06 'c://'  '~/x'                 'FALHA:é a raiz da unidade c:, não uma pasta pessoal'
caso X01 'C:///' '~/x'                 'FALHA:é a raiz da unidade C:, não uma pasta pessoal'
caso X02 'C://Users/t' '~/x'           C://Users/t/x
echo "RESULTADO: $ok de $n"
