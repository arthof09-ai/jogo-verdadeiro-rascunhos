mkdir -p "$RUNNER_TEMP/caixa-janela"
# Sem pipefail, o tee não deixa o -e parar aqui; o código do guião lê-se do PIPESTATUS.
bash provas/ordem-caixa-janela-ci/ferramentas/mutacao-celulas.sh "$GODOT" "$RUNNER_TEMP/caixa-janela/mutacao-celulas.log" 2>&1 | tee "$RUNNER_TEMP/caixa-janela/mutacao-celulas.resumo.txt"
R=${PIPESTATUS[0]}
# O ficheiro mutado tem de ter ficado reposto (a cópia de trabalho igual ao commit).
git diff --exit-code -- rascunhos/cliente/hud/caixa_ordem.gd
exit $R
