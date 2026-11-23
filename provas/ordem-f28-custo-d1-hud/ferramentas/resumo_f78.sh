#!/bin/bash
# Escreve o resumo-f78.txt (Ordem F78+F79+F81+F82). Uso: resumo_f78.sh <raiz-do-repo> <rc-ponta> <rc-sem-d1> <partida>
R=$1; P=$R/provas/ordem-f28-custo-d1-hud; M=$P/medicao
tab(){ grep '^TABELA' "$1" | tr -d '\r'; }
novas(){ grep -E '^  MEDIDA (CASA|PINÇA)' "$1"; }
conta(){ printf 'rc=%s · %s · linhas com MEDIDA %s · linhas TABELA (sem o cabeçalho) %s · PARTIDA %s · DEPOIS %s · linhas com error/warning %s\n' \
  "$2" "$(grep 'Medição acabada' "$1")" "$(grep -c '^  MEDIDA ' "$1")" "$(grep -c '^TABELA |' "$1")" \
  "$(grep -c '^  PARTIDA ' "$1")" "$(grep -c '^  DEPOIS ' "$1")" "$(grep -ci 'error\|warning' "$1")"; }
# F78: o cursor nas PARTIDA; F79: «de o»; F81: MEDIDA seguida de DEPOIS (0 = PARTIDA, DEPOIS, MEDIDA em todos) e os CR
forma(){ local cr; cr=$(tr -cd '\r' < "$1" | wc -c)
  printf 'cursor nas PARTIDA: %s · «de o Mover» %s · MEDIDA seguida de DEPOIS %s · bytes CR %s (%s)\n' \
  "$(grep '^  PARTIDA ' "$1" | grep -oE 'cursor \([0-9-]+, [0-9-]+\)' | sort | uniq -c | sed -E 's/^ *([0-9]+) cursor /\1 × /' | paste -sd ';' | sed 's/;/; /g')" \
  "$(grep -c 'de o Mover' "$1")" \
  "$(grep -E '^  (PARTIDA|DEPOIS|MEDIDA) ' "$1" | awk '{print $1}' | awk 'p=="MEDIDA" && $0=="DEPOIS"{n++} {p=$0} END{print n+0}')" \
  "$cr" "$([ "$cr" = 0 ] && echo LF || echo CRLF)"; }
cmpr(){ local n; n=$(diff <(tab "$1") <(tab "$2") | grep -c '^<'); echo "-- $3: $n de 62 linhas TABELA diferem"; diff <(tab "$1") <(tab "$2"); }
{
echo "Ordem F78+F79+F81+F82 (sentença da F64) — resumo da medição do custo do D1 com a ferramenta acabada"
echo "Ferramenta: provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd (a da F64, mais: o cursor reposto no _repor,"
echo "«do Mover», rumo e inclinação na pinça a deslocar, PARTIDA/DEPOIS/MEDIDA por esta ordem). Godot 4.7.2 --headless"
echo "(_console.exe), Windows 11; a saída passa por tr -d '\r' (logs em LF)."
echo "Partida: $4."
echo
echo "== Na ponta (com o D1): medicao/medir_custo_d1_hud-f78.log"
conta $M/medir_custo_d1_hud-f78.log $2
forma $M/medir_custo_d1_hud-f78.log
echo
echo "== Sem o D1 (caixa_ordem.gd de 0bebd76 só na cópia de trabalho, reposto a seguir; sha cc26f56c… igual ao HEAD): medicao/medir_custo_d1_hud-sem-d1-f78.log"
conta $M/medir_custo_d1_hud-sem-d1-f78.log $3
forma $M/medir_custo_d1_hud-sem-d1-f78.log
echo
echo "== Antes (os logs da F64), para comparar"
forma $M/medir_custo_d1_hud-f64.log
forma $M/medir_custo_d1_hud-sem-d1-f64.log
echo
echo "== As tabelas não mudaram (linhas TABELA, diff 2.ª corrida da F61 → F78)"
cmpr $M/medir_custo_d1_hud-corrida2.log $M/medir_custo_d1_hud-f78.log "na ponta"
cmpr $M/medir_custo_d1_hud-sem-d1-corrida2.log $M/medir_custo_d1_hud-sem-d1-f78.log "sem o D1"
echo
echo "== As linhas da casa e das pinças, na ponta"
novas $M/medir_custo_d1_hud-f78.log
echo
echo "== As linhas da casa e das pinças, sem o D1"
novas $M/medir_custo_d1_hud-sem-d1-f78.log
} > $M/resumo-f78.txt
