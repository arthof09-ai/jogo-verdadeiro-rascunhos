# Ordem CAIXA-RELATO-CORRECOES-8 (B3/B4): torna absoluto um caminho dado na linha de comandos, ou falha com mensagem.
# Lido (`.`) por correr-mutacoes.sh e correr-prova-caixa-relato.sh, ANTES do `cd` para a raiz, com ORIGEM=$PWD.
#   absolutizar <nome-da-variável> <o que é, para as mensagens>   → 0 e a variável reescrita; ou 1 e uma mensagem
# Nunca resolve em silêncio para o sítio errado. Os casos (PC Windows, Git Bash; o Godot é um .exe Windows):
#   /c/…, /tmp/…            absoluto (MSYS) — fica.
#   C:/… , C:\…             absoluto (Windows) — fica (as barras invertidas passam a /).
#   ~ , ~/…                 $HOME (que tem de ser absoluto) + o resto. ~utilizador/… → falha.
#   \pasta\…  (uma barra)   relativo à raiz da unidade da ORIGEM → <unidade>:/pasta/… (a unidade lê-se com cygpath).
#   \\servidor\… , //…      caminho de rede (UNC) → falha: o Godot e o bash não o tratam da mesma maneira.
#   C:pasta  (sem barra)    relativo à pasta corrente da unidade C:, que o bash não sabe → falha.
#   o resto (pasta, ./…, ../…)  relativo à ORIGEM → ORIGEM/….
# Se o caminho mudou, avisa no stderr com o caminho que vai usar.
absolutizar() {
  local nome=$1 oque=$2 v=${!1} u
  local o=$v
  case "$v" in
    '~'|'~/'*|'~\'*)
      case "$HOME" in /*|[A-Za-z]:[\\/]*) ;; *) echo "$oque «$o»: começa por ~ mas o \$HOME («$HOME») não é absoluto — dá um caminho absoluto" >&2; return 1 ;; esac
      v=$HOME${v:1} ;;
    '~'*) echo "$oque «$o»: ~utilizador não é suportado — dá um caminho absoluto" >&2; return 1 ;;
  esac
  case "$v" in
    '\\'*|'//'*|'\/'*|'/\'*) echo "$oque «$o»: caminho de rede (UNC) não é suportado — usa uma pasta local" >&2; return 1 ;;
    '\'*)
      u=$(cygpath -m "$ORIGEM" 2>/dev/null); u=${u:0:2}
      case "$u" in [A-Za-z]:) v=$u$v ;; *) echo "$oque «$o»: relativo à raiz da unidade, e não sei a unidade de «$ORIGEM» — dá um caminho com a unidade (C:/…)" >&2; return 1 ;; esac ;;
    /*|[A-Za-z]:/*|[A-Za-z]:'\'*) ;;
    [A-Za-z]:*) echo "$oque «$o»: «${v:0:2}» sem barra é relativo à pasta corrente dessa unidade, que não sei — escreve ${v:0:2}/… ou um caminho relativo" >&2; return 1 ;;
    *) v=$ORIGEM/$v ;;
  esac
  v=${v//\\//}
  [ "$v" != "$o" ] && echo "$oque «$o» — uso o caminho absoluto $v" >&2
  printf -v "$nome" '%s' "$v"
}
