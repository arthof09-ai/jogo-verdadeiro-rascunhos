#!/usr/bin/env bash
# ORDEM-D-AUD-14-SEGUIMENTO-MUTACAO (B1) — a prova de que o teste da largura do Mestre (_medir_historia, D-AUD-14-LARGURA)
# dispara, a correr no CI em cada push. Segue o precedente do mutacao-celulas.sh da CAIXA-JANELA-CI.
#
#   bash provas/ordem-d-aud-14-seguimento-mutacao/ferramentas/mutacao-largura.sh "$GODOT" <ficheiro-de-log>
#
# Corre na raiz do repositório. Muta SÓ a cópia de trabalho (nunca se comete): em cenas/mestre/mestre.gd, tira a ligação
# do minimum_size_changed da barra das abas a _ao_mudar_barra_abas — isto é, tira a correcção do 7c65fb8 (sem a ligação,
# a folha nunca se volta a medir quando a letra nova chega à barra; o resto da correcção fica inerte). Corre o
# medir_mestre.gd com a mutação e exige:
#   - código de saída 1;
#   - exactamente 4 falhas, e são as quatro do bloco da D-AUD-14 (uma de cada):
#       «(1600, 900) directo: a folha é a da letra actual»,
#       «(800, 450): a folha é a da letra actual»,
#       «(800, 450) → (1600, 900): a folha é a da letra actual»,
#       «(1600, 900): o tabuleiro tem a mesma largura aberto directo»;
#   - a linha final «ecrã do Mestre: 4 falha(s), 0 sem medida»;
#   - 0 erros de script.
# (É o que dava o mestre.gd do afc7e85, sem a correcção: logs/antes/medir-mestre-sem-correccao.log da D-AUD-14-LARGURA,
# directo=880 px, depois de (800, 450)=712 px.)
# Repõe o ficheiro a seguir (git checkout), mesmo se algo falhar, e confere que a cópia de trabalho ficou limpa.
# Os ficheiros podem estar em CRLF (cópia de trabalho do PC, core.autocrlf) ou LF (runner): o sed aceita o «\r» final e
# os grep correm sobre o texto normalizado com «tr -d '\r'» (o «\r?» não funciona no grep GNU, F3 da CAIXA-JANELA-CI).
# Código de saída 0 se a mutação foi apanhada como devia, 1 se não.
set -u
GODOT="$1"
LOG="$2"
ALVO=rascunhos/cliente/cenas/mestre/mestre.gd
ORIGINAL='	_abas.get_tab_bar().minimum_size_changed.connect(_ao_mudar_barra_abas)'
MUTADA='	pass  # MUTACAO (D-AUD-14-SEGUIMENTO-MUTACAO): sem a ligação, a folha não se volta a medir'

repor() { git checkout -- "$ALVO"; }
conta() { tr -d '\r' < "$ALVO" | grep -cxF "$1"; }

if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO já tem alterações por cometer"; exit 1; fi
if [ "$(conta "$ORIGINAL")" != "1" ]; then echo "PARAR: a linha a mutar não está (uma vez) em $ALVO"; exit 1; fi
# O trap só se arma depois das guardas: antes disso nada foi mutado, e um restauro aqui apagaria trabalho alheio.
trap repor EXIT

# Os pontos e os parênteses escapam-se no padrão do sed (BRE: «(» é literal, «.» é coringa).
ORIGINAL_RE='\t_abas\.get_tab_bar()\.minimum_size_changed\.connect(_ao_mudar_barra_abas)'
sed -i "s|^$ORIGINAL_RE\(\r\?\)\$|$MUTADA\1|" "$ALVO"
if [ "$(conta "$MUTADA")" != "1" ]; then echo "PARAR: a mutação não ficou feita"; exit 1; fi
if [ "$(conta "$ORIGINAL")" != "0" ]; then echo "PARAR: a linha original ainda lá está"; exit 1; fi
if [ "$(tr -d '\r' < "$ALVO" | grep -c "minimum_size_changed.connect(_ao_mudar_barra_abas)")" != "0" ]; then
  echo "PARAR: ainda há uma ligação a _ao_mudar_barra_abas"; exit 1
fi
echo "== mutação feita (só na cópia de trabalho):"
git diff --stat -- "$ALVO"
git diff -U0 -- "$ALVO" | grep -E '^[-+][^-+]'

RC=0
(cd rascunhos/cliente && timeout 120 "$GODOT" --headless --path . -s res://testes/medir_mestre.gd) > "$LOG" 2>&1 || RC=$?

repor
trap - EXIT
if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO não ficou reposto"; exit 1; fi
echo "== ficheiro reposto: git diff vazio em $ALVO"

TXT=$(tr -d '\r' < "$LOG")
N_FALHAS=$(grep -c "^  FALHA " <<< "$TXT")
uma() { grep -cE "^  FALHA $1" <<< "$TXT"; }
F1=$(uma '\(1600, 900\) directo: a folha é a da letra actual ')
F2=$(uma '\(800, 450\): a folha é a da letra actual ')
F3=$(uma '\(800, 450\) → \(1600, 900\): a folha é a da letra actual ')
F4=$(uma '\(1600, 900\): o tabuleiro tem a mesma largura aberto directo ')
FINAL=$(grep -E "^ecrã do Mestre: [0-9]+ falha\(s\), [0-9]+ sem medida$" <<< "$TXT" | tail -1)
ERROS=$(grep -cE "SCRIPT ERROR|Parse Error|Compile Error" <<< "$TXT")
echo "== com a mutação: rc=$RC · falhas=$N_FALHAS (do bloco D-AUD-14: $F1+$F2+$F3+$F4) · «$FINAL» · erros de script=$ERROS"
grep -E "^  FALHA |MEDIDA MESTRE-LARGURA" <<< "$TXT"
if [ "$RC" -eq 1 ] && [ "$N_FALHAS" -eq 4 ] && [ "$F1" -eq 1 ] && [ "$F2" -eq 1 ] && [ "$F3" -eq 1 ] && [ "$F4" -eq 1 ] \
   && [ "$FINAL" = "ecrã do Mestre: 4 falha(s), 0 sem medida" ] && [ "$ERROS" -eq 0 ]; then
  echo "MUTACAO APANHADA: 4 falhas, as quatro do bloco D-AUD-14; o teste da largura dispara."
  exit 0
fi
echo "MUTACAO NAO APANHADA COMO DEVIA (esperado: rc=1, 4 falhas do bloco D-AUD-14, «ecrã do Mestre: 4 falha(s), 0 sem medida», 0 erros)"
exit 1
