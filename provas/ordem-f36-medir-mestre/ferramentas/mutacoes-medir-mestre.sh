#!/usr/bin/env bash
# Ordem F36 (sentença da CAIXA-EXPANDE-VISTAS): prova de que toda a guarda nova do medir_mestre.gd DISPARA.
# Quatro mutações do jogo, uma por vez, na cópia de trabalho e sem commit; todas repostas com git checkout.
#
#   bash provas/ordem-f36-medir-mestre/ferramentas/mutacoes-medir-mestre.sh <godot> <pasta-dos-logs>
#
# M1 (D-A): a caixa nunca sai de cena na câmara livre      -> «sai de cena (sem lugar)» falha em 844×390 e 780×360
# M2 (D-B): sem o tecto da largura (os nomes não cortam)    -> «N nomes cortados com «…»» falha em 780×360
# M3 (D-G): o clique imitado de um toque fora não fecha     -> «fecho pelo clique» falha nos 9 casos
# M4 (D-A): o rato a sério não abre a caixa                 -> «câmara livre: vista expandida aberta pelo rato» falha
# Sai com 0 se as quatro dispararem (e o jogo ficar reposto), 1 se não.
set -u
G="$1"
L="$2"
RAIZ="$(git rev-parse --show-toplevel)"
C="$RAIZ/rascunhos/cliente"
mkdir -p "$L"
falhou=0

mutar() {  # nome ficheiro sed-expr padrão-que-tem-de-falhar
	local nome="$1" f="$2" expr="$3" padrao="$4"
	sed -i "$expr" "$C/$f"
	if git -C "$RAIZ" diff --quiet -- "rascunhos/cliente/$f"; then
		echo "$nome: a mutação não pegou em $f"; falhou=1; return
	fi
	"$G" --headless --path "$C" -s res://testes/medir_mestre.gd > "$L/$nome.log" 2>&1
	local rc=$?
	git -C "$RAIZ" checkout -q -- "rascunhos/cliente/$f"
	local n
	n=$(tr -d '\r' < "$L/$nome.log" | grep "FALHA" | grep -c -E "$padrao")
	echo "$nome: código $rc, $(tr -d '\r' < "$L/$nome.log" | grep -c '^  ok') ok, $(tr -d '\r' < "$L/$nome.log" | grep -c 'FALHA') falhas, das quais $n da guarda nova"
	if [ "$rc" -ne 1 ] || [ "$n" -lt 1 ]; then falhou=1; fi
}

mutar M1-livre-sem-lugar cenas/mestre/mestre.gd 's/^\t\t\t_caixa.visible = false$/\t\t\tpass/' "câmara livre: a caixa da ordem sai de cena"
mutar M2-sem-tecto cenas/mestre/mestre.gd 's/^\t_caixa.limitar_largura(maxf(1.0, _tabuleiro.size.x - _caixa.position.x - margem))$/\tpass/' "nomes cortados com"
mutar M3-clique-nao-fecha hud/caixa_ordem.gd 's/^\t\t\t_fechar_por_toque_fora(0)$/\t\t\tpass/' "fecho pelo clique"
mutar M4-rato-nao-abre hud/caixa_ordem.gd 's/^\t\tdefinir_sobre(_contem(ev))$/\t\tpass/' "câmara livre: vista expandida aberta pelo rato"

git -C "$RAIZ" diff --exit-code --quiet -- rascunhos/cliente/cenas rascunhos/cliente/hud || { echo "o jogo NÃO ficou reposto"; falhou=1; }
exit $falhou
