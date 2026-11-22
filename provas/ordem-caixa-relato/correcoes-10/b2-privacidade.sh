# B2 (CAIXA-RELATO-CORRECOES-10): os 16 casos da privacidade da CORRECOES-9 (13 + H01–H03) + os 3 em falta (P14–P16),
# e, à parte, 2 casos extra da B1 (HOME=C:/ nos dois scripts), com os scripts verdadeiros chamados da sede. Todos os casos têm
# de dar rc=2, a mensagem certa, e nada escrito (nem pasta tmp, nem saída, nem registo, nem ficheiros-fonte mudados):
# compara-se a listagem da sede + o git status do clone (em repo/), antes/depois.
#   bash tmp/b2-privacidade.sh    (da pasta da sede)
G=/c/Users/txcga/RPG_Local/ferramentas/Godot_4.7.2/Godot_v4.7.2-stable_win64_console.exe
M=$PWD/tmp/nao-existe-vlab.js
R=repo/provas/ordem-caixa-relato/ferramentas
lista() { find . -path ./repo/.git -prune -o -path ./repo/rascunhos/cliente/.godot -prune -o -path ./tmp/b2-priv-err.txt -prune -o -path "./tmp/b2-priv-lista-*" -prune -o -print | sort; (cd repo && git status --porcelain); }
lista > tmp/b2-priv-lista-antes.txt
ok=0; n=0
caso() {  # <id> <HOME> <pedaço da mensagem> <script> <args…>
  local id=$1 h=$2 msg=$3 sc=$4; shift 4
  HOME=$h SO=B3-PA bash "$R/$sc" "$@" >/dev/null 2>tmp/b2-priv-err.txt; local rc=$?
  local err; err=$(cat tmp/b2-priv-err.txt)
  n=$((n+1))
  if [ $rc -eq 2 ] && [[ $err == *"$msg"* ]]; then r=OK; ok=$((ok+1)); else r=ERRO; fi
  printf '%-4s %-4s %-30s rc=%s  %s\n' "$id" "$r" "$sc" "$rc" "$err"
}
P=correr-prova-caixa-relato.sh; U=correr-mutacoes.sh; H=/c/Users/txcga
UNC='caminho de rede (UNC)'; UNI='sem barra é relativo à pasta corrente'
caso P01 $H '~utilizador não é suportado' $P "$G" "$M" '~root/x'
caso P02 $H "$UNC" $P "$G" "$M" '\\servidor\partilha\tmp'
caso P03 $H "$UNC" $P "$G" "$M" '//servidor/partilha/tmp'
caso P04 $H "$UNC" $P "$G" "$M" '\/servidor/partilha'
caso P05 $H "$UNI" $P "$G" "$M" 'C:tmp'
caso P06 $H "$UNI" $P "$G" "$M" 'C:'
caso P07 $H '~utilizador não é suportado' $U "$G" "$M" '~root/x' novo "$PWD/tmp/nunca.log"
caso P08 $H "$UNC" $U "$G" "$M" '\\servidor\partilha\tmp' novo "$PWD/tmp/nunca.log"
caso P09 $H "$UNC" $U "$G" "$M" '//servidor/partilha/tmp' novo "$PWD/tmp/nunca.log"
caso P10 $H "$UNC" $U "$G" "$M" '\/servidor/partilha' novo "$PWD/tmp/nunca.log"
caso P11 $H "$UNI" $U "$G" "$M" 'C:tmp' novo "$PWD/tmp/nunca.log"
caso P12 $H "$UNI" $U "$G" "$M" 'C:' novo "$PWD/tmp/nunca.log"
caso P13 casa-relativa 'não é absoluto' $P "$G" "$M" '~/x'
caso H01 / 'é a raiz, não uma pasta pessoal' $P "$G" "$M" '~/x'
caso H02 / 'é a raiz, não uma pasta pessoal' $U "$G" "$M" '~/x' novo "$PWD/tmp/nunca.log"
caso H03 / 'é a raiz, não uma pasta pessoal' $U "$G" "$M" "$PWD/tmp/nunca" novo '~/x.log'
caso P14 $H "$UNC" $P "$G" "$M" '/\x'
caso P15 $H "$UNC" $U "$G" "$M" '/\x' novo "$PWD/tmp/nunca.log"
caso P16 casa-relativa 'não é absoluto' $U "$G" "$M" '~/x' novo "$PWD/tmp/nunca.log"
okb2=$ok; nb2=$n; ok=0; n=0
RAIZ='é a raiz da unidade C:, não uma pasta pessoal'
caso R01 'C:/' "$RAIZ" $P "$G" "$M" '~/x'
caso R02 'C:/' "$RAIZ" $U "$G" "$M" '~/x' novo "$PWD/tmp/nunca.log"
lista > tmp/b2-priv-lista-depois.txt
echo "RESULTADO B2: $okb2 de $nb2"
echo "EXTRA B1 (scripts verdadeiros): $ok de $n"
diff tmp/b2-priv-lista-antes.txt tmp/b2-priv-lista-depois.txt && echo "NADA ESCRITO (listagem da sede e git status do clone iguais)"
