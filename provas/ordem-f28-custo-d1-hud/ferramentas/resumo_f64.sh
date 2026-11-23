#!/bin/bash
# Escreve o resumo-f64.txt (Ordem F64). Uso: resumo_f64.sh <raiz-do-repo> <rc-ponta> <rc-sem-d1> <partida>
R=$1; P=$R/provas/ordem-f28-custo-d1-hud; M=$P/medicao
tab(){ grep '^TABELA' "$1" | tr -d '\r'; }
novas(){ grep -E '^  MEDIDA (CASA|PINÇA)' "$1" | tr -d '\r'; }
conta(){ printf 'rc=%s · %s · linhas com MEDIDA %s · linhas TABELA (sem o cabeçalho) %s · PARTIDA %s · DEPOIS %s · linhas com error/warning %s\n' \
  "$2" "$(grep 'Medição acabada' "$1" | tr -d '\r')" "$(grep -c '^  MEDIDA ' "$1")" "$(grep -c '^TABELA |' "$1")" \
  "$(grep -c '^  PARTIDA ' "$1")" "$(grep -c '^  DEPOIS ' "$1")" "$(grep -ci 'error\|warning' "$1")"; }
cmpr(){ local n; n=$(diff <(tab "$1") <(tab "$2") | grep -c '^<'); echo "-- $3: $n de 62 linhas TABELA diferem"; diff <(tab "$1") <(tab "$2"); }
{
echo "Ordem F64 (sentença da F28) — resumo da medição do custo do D1 com a ferramenta das L1–L3"
echo "Ferramenta: provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd (câmara reposta da F61; MEDIDA CASA,"
echo "deslocamento na pinça, MEDIDA PINÇA A DESLOCAR, PARTIDA e DEPOIS da F64). Godot 4.7.2 --headless (_console.exe), Windows 11."
echo "Partida: $4."
echo
echo "== Na ponta (com o D1): medicao/medir_custo_d1_hud-f64.log"
conta $M/medir_custo_d1_hud-f64.log $2
echo
echo "== Sem o D1 (caixa_ordem.gd de 0bebd76 só na cópia de trabalho, reposto a seguir; sha cc26f56c… igual ao HEAD): medicao/medir_custo_d1_hud-sem-d1-f64.log"
conta $M/medir_custo_d1_hud-sem-d1-f64.log $3
echo
echo "== As tabelas não mudaram (linhas TABELA, diff 2.ª corrida da F61 → F64)"
cmpr $M/medir_custo_d1_hud-corrida2.log $M/medir_custo_d1_hud-f64.log "na ponta"
cmpr $M/medir_custo_d1_hud-sem-d1-corrida2.log $M/medir_custo_d1_hud-sem-d1-f64.log "sem o D1"
echo
echo "== As linhas novas (L1 a casa, L2 a pinça), na ponta"
novas $M/medir_custo_d1_hud-f64.log
echo
echo "== As linhas novas (L1 a casa, L2 a pinça), sem o D1"
novas $M/medir_custo_d1_hud-sem-d1-f64.log
} > $M/resumo-f64.txt
