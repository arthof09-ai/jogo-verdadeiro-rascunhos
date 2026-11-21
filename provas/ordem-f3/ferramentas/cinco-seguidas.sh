#!/usr/bin/env bash
# ORDEM-F3: 5 vezes seguidas — a bancada padrão (correr-bancada.sh) + o guião do CI (correr-provas-mapa.sh) e o
# comparador da CORR9 contra a primeira corrida (como no passo «Repetição» do CI).
set -u
REPO=/c/Users/txcga/RPG_Local/jogo-verdadeiro/ordem-f3/repo
BASE=/c/Users/txcga/RPG_Local/jogo-verdadeiro/ordem-f3/corridas-5
cd "$REPO"
for k in 1 2 3 4 5; do
  O="$BASE/r$k"; mkdir -p "$O"
  echo "== corrida $k — início $(date +%T)"
  B=0; bash provas/ordem-mapa-jogavel/provas-bancada/ferramentas/correr-bancada.sh 8821 "$O/bancada" > "$O/bancada.out" 2>&1 || B=$?
  echo "   bancada padrão: saída $B — $(tail -1 "$O/bancada.out") — $(grep -h 'verificações passaram' "$O/bancada/bancada-jogadora.log")"
  C=0; bash provas/ordem-provas-mapa-corr9/ferramentas/correr-provas-mapa.sh "$O/ci" 8822 > "$O/ci.out" 2>&1 || C=$?
  echo "   guião do CI: saída $C — $(grep terreno-original "$O/ci.out")"
  R=0; node provas/ordem-provas-mapa-corr9/ferramentas/comparar-corridas.mjs --md="$O/repeticao.md" primeira=provas/ordem-mapa-jogavel/provas-bancada ci="$O/ci" > "$O/repeticao.out" 2>&1 || R=$?
  echo "   comparador: saída $R — $(tail -1 "$O/repeticao.out")"
  echo "   quietos (bancada/ci): $(node -e "for (const p of process.argv.slice(1)) { const q=require(p).quietos; console.log(q.map(x=>x.onde.replace(/ m: /,'m ')+':'+x.frames+'f'+(Object.values(x.resto).some(r=>r!=='Vector3(0, 0, 0)')?'*RESTO*':'')).join(' ')) }" "$O/bancada/bancada-jogadora.json" "$O/ci/bancada-jogadora.json" | tr '\n' '|')"
done
echo "== fim $(date +%T)"
