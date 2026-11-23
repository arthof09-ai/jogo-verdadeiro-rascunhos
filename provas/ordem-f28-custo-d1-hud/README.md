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

Para correr (Godot 4.7.2; num clone novo, faz antes o `--import`):

    godot --headless --path rascunhos/cliente --import
    godot --headless --path rascunhos/cliente -s "$PWD/provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd"

Não usa servidor nem PIN.
