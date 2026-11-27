#!/bin/bash
# J4 da ORDEM-D-AUD-01-CORRECCOES-6, sobre o commit do J4 (antes do J1, que junta uma verificação): os números
# exactos da ordem — pecas_mestre 336/336, SEM-REFRESCO 335/336 (só o teste da CORRECCOES-5, agora com a casa que
# entrou engolida: `[]`), SEM-B1 333/336. As duas mutações são as da CORRECCOES-5, com o mesmo texto.
#   GODOT=<Godot_v4.7.2-stable_win64_console.exe> PYTHON=<python> L=<pasta dos logs> bash provas/ordem-d-aud-01-correccoes-6/j4.sh
. "$(dirname "$0")/muta.sh"
: > "$L/resumo.txt"
echo "# commit: $(git rev-parse HEAD)" >> "$L/resumo.txt"
pecas pecas_mestre
muta pecas_mestre-SEM-REFRESCO '		if novas != _casas:' '		if false and novas != _casas:  # MUTACAO (D-AUD-01-CORRECCOES-5): sem o refresco'
muta pecas_mestre-SEM-B1 '	if a_mover and not tem_mover:' '	if false and a_mover and not tem_mover:  # MUTACAO (D-AUD-01-CORRECCOES-4): sem o desarme do B1'
redigir
echo FIM >> "$L/resumo.txt"
