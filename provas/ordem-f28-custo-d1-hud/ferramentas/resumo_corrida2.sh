#!/bin/bash
# Escreve o resumo.txt da 2.ª corrida (F61). Uso: fazer-resumo.sh <raiz-do-repo> <rc-ponta> <rc-sem-d1> <partida>
R=$1; P=$R/provas/ordem-f28-custo-d1-hud; M=$P/medicao
tab(){ grep '^TABELA' "$1" | tr -d '\r'; }
conta(){ printf 'rc=%s · %s · linhas com MEDIDA %s · linhas TABELA (sem o cabeçalho) %s · linhas com error/warning %s\n' \
  "$2" "$(grep 'Medição acabada' "$1" | tr -d '\r')" "$(grep -c MEDIDA "$1")" "$(grep -c '^TABELA |' "$1")" "$(grep -ci 'error\|warning' "$1")"; }
cmpr(){ local n; n=$(diff <(tab "$1") <(tab "$2") | grep -c '^<'); echo "-- $3: $n de 62 linhas diferem"; diff <(tab "$1") <(tab "$2"); }
{
echo "Ordem F61 (sentença da F28) — resumo da 2.ª corrida das duas medições do custo do D1"
echo "Ferramenta: provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd, com a câmara reposta entre casos (F61)."
echo "Godot 4.7.2 --headless (_console.exe), Windows 11. Partida: $4."
echo
echo "== Na ponta (com o D1): medicao/medir_custo_d1_hud-corrida2.log"
conta $M/medir_custo_d1_hud-corrida2.log $2
echo
echo "== Sem o D1 (caixa_ordem.gd de 0bebd76 só na cópia de trabalho, reposto a seguir; sha cc26f56c… igual ao HEAD): medicao/medir_custo_d1_hud-sem-d1-corrida2.log"
conta $M/medir_custo_d1_hud-sem-d1-corrida2.log $3
echo
echo "== Comparação com a 1.ª corrida (linhas TABELA, diff 1.ª → 2.ª)"
cmpr $M/medir_custo_d1_hud.log $M/medir_custo_d1_hud-corrida2.log "na ponta (1.ª: medicao/medir_custo_d1_hud.log)"
cmpr $P/sem-d1/medir_custo_d1_hud.log $M/medir_custo_d1_hud-sem-d1-corrida2.log "sem o D1 (1.ª: sem-d1/medir_custo_d1_hud.log)"
echo "Todas as linhas que diferem são do arrastar 1 dedo, e a diferença está na 4.ª casa decimal. As outras são iguais byte a byte."
echo "Com a câmara reposta, os 6 arrastares que deslocam a câmara dão todos o mesmo valor. Na 1.ª corrida variavam entre"
echo "2.2680 e 2.2699. A reposição tira essa variação, o que aponta para o estado que a câmara levava de caso para caso."
echo
echo "== TABELA da 2.ª corrida, na ponta"
tab $M/medir_custo_d1_hud-corrida2.log
echo
echo "== TABELA da 2.ª corrida, sem o D1"
tab $M/medir_custo_d1_hud-sem-d1-corrida2.log
} > $M/resumo.txt
