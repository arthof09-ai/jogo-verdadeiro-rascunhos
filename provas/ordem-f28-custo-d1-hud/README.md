# Ordem F28 — o custo do D1 nos botões do HUD (só medição)

Esta pasta mede o que o D1 da F14 custa. O D1 diz: com a lista da caixa aberta por toque, o toque fora que a fecha
fica na caixa. Nenhum ficheiro do jogo muda com esta ordem. As conclusões estão em
`ESTADO-FINAL-ORDEM-F28-CUSTO-D1-HUD.md`, na raiz.

- `ferramentas/medir_custo_d1_hud.gd` é a ferramenta de medição. Monta a arena a sério, como o §11 da `caixa_jogadora`,
  sem servidor e com 12 figuras. A jogadora está na vez, com um ROOM_OPTIONS que liga todos os botões. Os toques vão pelo
  `Input` do motor, que imita o rato a partir deles, como no aparelho. Mede em 844×390 e em 780×360:
  - os 15 botões do HUD, um a um;
  - o arrastar, a pinça, a roda e o rato;
  - uma jogada típica: mover e encerrar.
  Saem linhas `MEDIDA` e uma `TABELA` no fim. É uma medição, não um teste: o código de saída é 0 quando a medição correu
  sem erros.
- `medicao/medir_custo_d1_hud.log` é a medição na ponta, com o D1.
- `sem-d1/medir_custo_d1_hud.log` é a mesma medição com o `caixa_ordem.gd` de `0bebd76`, de antes da F14. O ficheiro foi
  trocado só na cópia de trabalho e reposto a seguir (`git diff` vazio). Esse ficheiro não tem o D1 nem o D3.
- **2.ª corrida (Ordem F61, sentença da F28):** `medicao/medir_custo_d1_hud-corrida2.log` (na ponta) e
  `medicao/medir_custo_d1_hud-sem-d1-corrida2.log` (sem o D1, com a mesma troca do `caixa_ordem.gd`).
  - `medicao/resumo.txt` tem o rc, a contagem, as tabelas e a comparação com a 1.ª corrida. Escreve-o
    `bash ferramentas/resumo_corrida2.sh <raiz-do-repo> <rc-ponta> <rc-sem-d1> <partida>`.
  - Desde a F61, a ferramenta repõe a câmara entre casos (a F64 pediu-o): o modo, o foco, o zoom, o rumo e a inclinação
    de quando a arena ficou pronta. As tabelas saem iguais às da 1.ª corrida, menos o deslocamento do arrastar, que muda
    na 4.ª casa decimal. Ver `ESTADO-FINAL-ORDEM-F61-SEGUNDA-CORRIDA-D1.md`, na raiz.

- **A ferramenta das L1–L3 (Ordem F64, sentença da F28):** `medicao/medir_custo_d1_hud-f64.log` (na ponta) e
  `medicao/medir_custo_d1_hud-sem-d1-f64.log` (sem o D1, com a mesma troca do `caixa_ordem.gd`). A ferramenta passou a
  escrever mais linhas, e as linhas TABELA continuam iguais byte a byte às da 2.ª corrida:
  - `MEDIDA CASA` (L1): o toque numa casa do Mover, com a lista aberta por toque e de controlo, no mesmo ponto. Diz se
    a casa fecha a lista sem mover a figura ou se a move (a intenção «mover» na fila).
  - a `MEDIDA PINÇA` diz também quanto o foco da câmara andou e o rumo e a inclinação. A `MEDIDA PINÇA A DESLOCAR` (L2)
    é uma 2.ª pinça cujo meio anda 60 u: no controlo a câmara desloca-se, e com a lista aberta mede-se se se desloca.
  - `PARTIDA` e `DEPOIS` (L3): o estado antes do gesto medido (a caixa, o modo, a gaveta, os painéis, a figura dela e a
    casa onde está, o cursor, a declaração do Mover, a fila e a câmara) e o que mudou ao 1.º toque e no fim.
  - `medicao/resumo-f64.txt` tem o rc, as contagens, a comparação das tabelas e as linhas novas. Escreve-o
    `bash ferramentas/resumo_f64.sh <raiz-do-repo> <rc-ponta> <rc-sem-d1> <partida>`. Ver
    `ESTADO-FINAL-ORDEM-F64-FERRAMENTA-MEDICAO-D1.md`, na raiz.
  - **O gesto da `PINÇA A DESLOCAR` é arbitrário (F82):** 22 u e 2 u por passo, durante 5 passos, e o meio anda 60 u.
    Foi escolhido só para o controlo dar um número grande e não vem de nenhum aparelho. Os 0,854 m que ele dá provam
    que a medida funciona. Nunca são o que um gesto real da jogadora desloca, nem se citam assim.

- **Os acabamentos (Ordem F78+F79+F81+F82, sentença da F64):** `medicao/medir_custo_d1_hud-f78.log` (na ponta) e
  `medicao/medir_custo_d1_hud-sem-d1-f78.log` (sem o D1, com a mesma troca do `caixa_ordem.gd`), em LF. As linhas TABELA
  continuam iguais byte a byte às da 2.ª corrida.
  - F78: o `_repor` repõe também o cursor da arena, no (−1, −1) com que ela nasce, e a partida passa a ser neutra. Só
    nos casos em que a preparação abre o Mover a `PARTIDA` traz o cursor na casa dela, que é onde a arena o põe.
  - F79: a gaveta escreve «à vista, do Mover» (era «de o Mover»).
  - F81: a `MEDIDA PINÇA A DESLOCAR` traz o rumo e a inclinação, e em todos os casos as linhas saem pela ordem `PARTIDA`,
    `DEPOIS` e `MEDIDA`. Os logs passam a LF.
  - `medicao/resumo-f78.txt` escreve-se com `bash ferramentas/resumo_f78.sh <raiz-do-repo> <rc-ponta> <rc-sem-d1> <partida>`.
    Ver `ESTADO-FINAL-ORDEM-F78-F79-F81-F82-FERRAMENTA-D1.md`, na raiz.
  - Os logs mais antigos (F28, F61, F64) ficam como foram cometidos, em CRLF.

Para correr (Godot 4.7.2; num clone novo, faz antes o `--import`):

    godot --headless --path rascunhos/cliente --import
    godot --headless --path rascunhos/cliente -s "$PWD/provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd"

No Windows, o Godot escreve CRLF. Desde a F81, o log guarda-se em LF, com a saída a passar por `tr -d '\r'`
(`… 2>&1 | tr -d '\r' > log`, com o rc tirado de `${PIPESTATUS[0]}`).

Não usa servidor nem PIN.
