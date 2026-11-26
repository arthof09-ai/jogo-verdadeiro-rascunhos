#!/bin/bash
# Suites da ORDEM-PLANO-2-F1-ADENDA (D-AUD-12: o sufixo também no snapshot) — as mesmas da PLANO-2-F1 (provas/ordem-plano-2-f1/
# suites.sh) mais o teste novo d-aud-12-snapshot-novo, e antes delas uma mutação pelo padrão B3 (ficheiro mutado, log com o
# comando e o diff, reposto com git checkout e o git diff conferido vazio):
#   - d-aud-12-snapshot-SEM-SUFIXO-NA-FIGURA-PUBLICA: projecao.js, em figuraPublica, «nomePublico: nomePublicoDaFigura(fig, …)»
#     → «nomePublico: nomePublicoDe(fichas[fig.fichaId])» (o estado da reprodução `l28` da INVESTIGA, E9).
#
#   GODOT=<Godot_v4.7.2-stable_win64(.exe)> MOTOR_MJS=<motor privado> [PYTHON=<python com jsonschema>] bash provas/ordem-plano-2-f1-adenda/suites.sh
#
# Os logs vão para $L (por omissão <sede>/tmp/suites-f1-adenda). Na escrita dos logs, o caminho da máquina sai como <sede>.
set -u
R="$(git rev-parse --show-toplevel)"; B="$(cd "$R/.." && pwd)"; L="${L:-$B/tmp/suites-f1-adenda}"
G="${GODOT:?GODOT por definir}"; M="${MOTOR_MJS:?MOTOR_MJS por definir}"; P="${PYTHON:-python}"
mkdir -p "$L"; rm -f "$L"/*.log "$L"/*.jsonl
: > "$L/resumo.txt"
cd "$R"
echo "# commit: $(git rev-parse HEAD)" >> "$L/resumo.txt"

# godot <log> <args...> — o Godot sem consola deste PC escreve por --log-file; o exit vem do processo.
godot() { local log="$1"; shift; local t; t="$(mktemp)"; timeout 300 "$G" --headless --log-file "$(cygpath -w "$t" 2>/dev/null || echo "$t")" "$@" > /dev/null 2>&1; local e=$?; cat "$t" >> "$log"; rm -f "$t"; return $e; }

# muta <nome> <ficheiro> <linha original> <linha mutada> <comando...>
muta() {
  local n="$1" ALVO="$2" ORIGINAL="$3" MUTADA="$4" e; shift 4
  cd "$R"
  conta() { tr -d '\r' < "$ALVO" | grep -cxF -- "$1"; }
  if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO já tem alterações por cometer"; exit 1; fi
  if [ "$(conta "$ORIGINAL")" != "1" ]; then echo "PARAR: a linha a mutar não está (uma vez) em $ALVO"; exit 1; fi
  trap 'cd "$R" && git checkout -- "$ALVO"' EXIT
  ORIGINAL="$ORIGINAL" MUTADA="$MUTADA" ALVO="$ALVO" "$P" -c "
import os
p=os.environ['ALVO']; s=open(p,encoding='utf8',newline='').read()
nl='\r\n' if '\r\n' in s else '\n'
a=os.environ['ORIGINAL']+nl; b=os.environ['MUTADA']+nl
assert s.count(a)==1; open(p,'w',encoding='utf8',newline='').write(s.replace(a,b))"
  if [ "$(conta "$MUTADA")" != "1" ] || [ "$(conta "$ORIGINAL")" != "0" ]; then echo "PARAR: a mutação não ficou feita"; exit 1; fi
  { echo "# comando: (mutação: em $ALVO, «$(echo "$ORIGINAL" | sed 's/^[\t ]*//')» → «$(echo "$MUTADA" | sed 's/^[\t ]*//')»; reposta com git checkout)"
    echo "# comando: $*"
    git diff -U0 -- "$ALVO" | grep -E '^[-+][^-+]' | sed 's/^/# diff: /'; } > "$L/$n.log"
  "$@" >> "$L/$n.log" 2>&1; e=$?
  cd "$R" && git checkout -- "$ALVO" && trap - EXIT
  if ! git diff --quiet -- "$ALVO"; then echo "PARAR: $ALVO não ficou reposto"; exit 1; fi
  echo "$n exit=$e falhas=$(grep -cE '  FALHA |^not ok|✖' "$L/$n.log") fim=«$(grep -E 'verificações passaram|^ℹ (pass|fail) ' "$L/$n.log" | tr '\n' ' ')» reposto=$(git diff --quiet -- "$ALVO" && echo sim || echo NAO)" >> "$L/resumo.txt"
}
snap() { cd "$R/rascunhos/servidor" && PROVA_SNAPSHOT=1 node --test --test-reporter=spec testes/d-aud-12-snapshot-novo.test.mjs; }
muta d-aud-12-snapshot-SEM-SUFIXO-NA-FIGURA-PUBLICA rascunhos/servidor/nucleo/projecao.js   '    nomePublico: nomePublicoDaFigura(fig, fichas[fig.fichaId]),'   '    nomePublico: nomePublicoDe(fichas[fig.fichaId]), // MUTACAO (PLANO-2-F1-ADENDA): o snapshot sem o número' snap

# ---- as suites, sobre o código da ponta ----
echo "# comando: cd rascunhos/servidor && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec \"testes/*.test.mjs\"" > "$L/servidor.log"
cd "$R/rascunhos/servidor" && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs" >> "$L/servidor.log" 2>&1; echo "servidor exit=$? $(grep -E '^ℹ (tests|pass|fail|skipped) ' "$L/servidor.log" | tr '\n' ' ')" >> "$L/resumo.txt"
echo "# comando: node provas/ordem-caixa/ferramentas/prova-servidor.mjs" > "$L/prova-caixa.log"
cd "$R" && node provas/ordem-caixa/ferramentas/prova-servidor.mjs >> "$L/prova-caixa.log" 2>&1; echo "prova-caixa exit=$? $(tail -1 "$L/prova-caixa.log")" >> "$L/resumo.txt"
echo "# comando: cd rascunhos/servidor && MOTOR_MJS=<motor privado, fora do repo> node --test --test-reporter=spec \"testes-motor-real/*.test.mjs\"" > "$L/motor-real.log"
cd "$R/rascunhos/servidor" && MOTOR_MJS="$M" node --test --test-reporter=spec "testes-motor-real/*.test.mjs" >> "$L/motor-real.log" 2>&1; echo "motor-real exit=$? $(grep -E '^ℹ (pass|fail) ' "$L/motor-real.log" | tr '\n' ' ')" >> "$L/resumo.txt"
cd "$R/rascunhos/cliente"
for s in abrir_scripts rodar_testes abrir_clareira medir_painel_config abrir_mestre pecas_mestre medir_mestre hud_acoes caixa_jogadora camera_segue aparelhos_f2 caixa_janela canario_privacidade; do
  echo "# comando: cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/suites-f1-adenda/comandos-$s.jsonl timeout 300 Godot_v4.7.2-stable_win64.exe --headless --path . -s res://testes/$s.gd" > "$L/$s.log"
  MESTRE_COMANDOS="$(cygpath -w "$L" 2>/dev/null || echo "$L")/comandos-$s.jsonl" godot "$L/$s.log" --path . -s res://testes/$s.gd; e=$?
  echo "$s exit=$e scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$s.log") $(grep -E 'verificações passaram' "$L/$s.log" | tail -1)" >> "$L/resumo.txt"
done
for t in provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd; do
  b=$(basename "$t" .gd)
  echo "# comando: cd rascunhos/cliente && timeout 300 Godot_v4.7.2-stable_win64.exe --headless --path . -s <repo>/$t" > "$L/$b.log"
  godot "$L/$b.log" --path . -s "$(cygpath -w "$R/$t" 2>/dev/null || echo "$R/$t")"; e=$?
  echo "$b exit=$e scriptErrors=$(grep -cE 'SCRIPT ERROR|Parse Error|Compile Error' "$L/$b.log") $(grep -E 'passaram' "$L/$b.log" | tail -1)" >> "$L/resumo.txt"
done
cd "$R"
for s in pecas_mestre abrir_mestre; do
  echo "# comando: python rascunhos/protocolo/ferramentas/validar-mensagens.py <sede>/tmp/suites-f1-adenda/comandos-$s.jsonl" > "$L/validar-mensagens-$s.log"
  "$P" rascunhos/protocolo/ferramentas/validar-mensagens.py "$L/comandos-$s.jsonl" >> "$L/validar-mensagens-$s.log" 2>&1; echo "validar-$s exit=$?" >> "$L/resumo.txt"
done
echo "# comando: python3 .github/sonda/caminhos_pc.py --raiz . --base .github/sonda/caminhos-pc-base.txt" > "$L/sonda-caminhos.log"
"$P" .github/sonda/caminhos_pc.py --raiz . --base .github/sonda/caminhos-pc-base.txt >> "$L/sonda-caminhos.log" 2>&1; echo "sonda-caminhos exit=$?" >> "$L/resumo.txt"
sed -i -e "s|$B|<sede>|g" -e "s|$(cygpath -m "$B" 2>/dev/null || echo "$B")|<sede>|g" -e "s|$(cygpath -w "$B" 2>/dev/null | sed 's|\\|\\\\|g' || echo "$B")|<sede>|g" "$L"/*.log
echo FIM >> "$L/resumo.txt"
