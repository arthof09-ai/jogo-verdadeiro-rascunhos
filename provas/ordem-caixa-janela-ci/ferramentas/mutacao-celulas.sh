#!/usr/bin/env bash
# Ordem CAIXA-JANELA-CI — a prova de que o passo da caixa_janela dispara (a mutação da B6 da CAIXA-PADRAO-CORRECOES).
#
#   bash provas/ordem-caixa-janela-ci/ferramentas/mutacao-celulas.sh "$GODOT" <ficheiro-de-log>
#
# Corre na raiz do repositório. Muta SÓ a cópia de trabalho (nunca se comete): em hud/caixa_ordem.gd, as células da
# fila passam a ter a largura da célula fixa MAIS 1 u nos ids ímpares (f1, f3, … → +1 u; f2, f4, … → +0 u), isto é, as células
# alargam conforme o id. Corre a suite caixa_janela com a mutação e exige:
#   - código de saída diferente de 0;
#   - exactamente 9 falhas, todas do assert B6 («os N slots renderizam com a largura da célula»), uma por medição
#     (8, 12 e 16 figuras × 1280×720, 844×390 e 780×360);
#   - a linha final «69 de 78 verificações passaram.»;
#   - 0 erros de script.
# Repõe o ficheiro a seguir (git checkout), mesmo se algo falhar, e confere que a cópia de trabalho ficou limpa.
# Código de saída 0 se a mutação foi apanhada como devia, 1 se não.
set -u
GODOT="$1"
LOG="$2"
ALVO=rascunhos/cliente/hud/caixa_ordem.gd
ORIGINAL='		slot.custom_minimum_size = celula'
MUTADA='		slot.custom_minimum_size = celula + Vector2(float(id.trim_prefix("f").to_int() % 2), 0.0)  # MUTACAO (CAIXA-JANELA-CI)'

repor() { git checkout -- "$ALVO"; }
trap repor EXIT

if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO já tem alterações por cometer"; exit 1; fi
if [ "$(grep -cxF "$ORIGINAL" "$ALVO")" != "1" ]; then echo "PARAR: a linha a mutar não está (uma vez) em $ALVO"; exit 1; fi

sed -i "s|^$ORIGINAL\$|$MUTADA|" "$ALVO"
if [ "$(grep -cxF "$MUTADA" "$ALVO")" != "1" ]; then echo "PARAR: a mutação não ficou feita"; exit 1; fi
echo "== mutação feita (só na cópia de trabalho):"
git diff --stat -- "$ALVO"
git diff -U0 -- "$ALVO" | grep -E '^[-+][^-+]'

RC=0
(cd rascunhos/cliente && timeout 120 "$GODOT" --headless --path . -s res://testes/caixa_janela.gd) > "$LOG" 2>&1 || RC=$?

repor
trap - EXIT
if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO não ficou reposto"; exit 1; fi
echo "== ficheiro reposto: git diff vazio em $ALVO"

N_FALHAS=$(grep -c "  FALHA " "$LOG")
N_B6=$(grep "  FALHA " "$LOG" | grep -c "slots renderizam com a largura da célula")
FINAL=$(grep -E "^[0-9]+ de [0-9]+ verificações passaram\.$" "$LOG" | tail -1)
ERROS=$(grep -cE "SCRIPT ERROR|Parse Error|Compile Error" "$LOG")
echo "== com a mutação: rc=$RC · falhas=$N_FALHAS (do assert B6: $N_B6) · «$FINAL» · erros de script=$ERROS"
grep "  FALHA " "$LOG"
if [ "$RC" -ne 0 ] && [ "$N_FALHAS" -eq 9 ] && [ "$N_B6" -eq 9 ] && [ "$FINAL" = "69 de 78 verificações passaram." ] && [ "$ERROS" -eq 0 ]; then
  echo "MUTACAO APANHADA: 9 falhas, todas do assert B6; o passo dispara."
  exit 0
fi
echo "MUTACAO NAO APANHADA COMO DEVIA (esperado: rc≠0, 9 falhas B6, 69 de 78, 0 erros)"
exit 1
