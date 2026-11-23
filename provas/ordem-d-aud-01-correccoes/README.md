# Provas — ORDEM-D-AUD-01-CORRECCOES (23/11/2026)

A conferência da D-AUD-01 (740, ENTRA COM CORRECÇÕES) pediu duas correcções de código:

1. **cancelar o «Mover» repõe o «Colocar»** que o «Mover» desarmou;
2. **5.º caso no teste:** com o «Mover» armado, escolher outra ficha no «Colocar» faz o toque pôr a ficha NOVA.

A ordem manda provar isto só com o teste de unidade, as suites e o CI, tudo headless. **Não se correu a bancada de
rede**, para não perturbar a medição de GPU do MAPA na outra cadeira. Por isso não há capturas nem vídeos.

## As 2 verificações novas (`testes/pecas_mestre.gd`, bloco «aba Agir»)

| Verificação | O que faz | Resultado |
|---|---|---|
| `D-AUD-01-CORRECCOES: cancelar o «Mover» repõe o «Colocar» …` | Colocar `orc-teste` armado → `iniciar_mover()` → o botão «Cancelar» do Agir (`_cancelar.pressed`) → toque no tabuleiro | Mover desarmado, `a_colocar == "orc-teste"`, **1 `MASTER_PLACE` `["orc-teste"]`** |
| `D-AUD-01-CORRECCOES: com o «Mover» armado, escolher outra ficha …` | `iniciar_mover()` → `escolher_colocar("lobo-teste")` → toque no tabuleiro | Mover desarmado, **1 `MASTER_PLACE` `["lobo-teste"]`, 0 do `orc-teste`** |

As 4 verificações D-AUD-01 que já existiam continuam a passar sem mudança (incluindo «0 `MASTER_PLACE`» no toque
do Mover).

## Antes e depois da correcção

- `suites/pecas_mestre-ANTES-da-correccao.log`: o teste novo corrido **sem** a correcção (código do ecrã do Mestre
  na ponta `cdc08be`). Dá **291 de 292**, e a única FALHA é «cancelar repõe» (`0 MASTER_PLACE []`). O 5.º caso já
  passa sem a correcção, como a conferência disse: o código tratava-o bem e faltava só a prova.
- `suites/pecas_mestre.log`: com a correcção dá **292 de 292**.

## Suites (`suites/`, resumo em `suites/resumo.txt`)

Corridas neste PC com Godot 4.7.2 `--headless` e Node, sobre o commit `062bbc4`. São as mesmas da D-AUD-01. Tirei
dos logs o caminho da máquina (`<sede>`).

| Suite | Resultado |
|---|---|
| servidor (`testes/*.test.mjs`) | 421/421 |
| motor real (`testes-motor-real`) | 2/2 |
| prova da caixa | PROVA OK |
| `abrir_scripts` | 108 scripts, 0 falhas |
| `rodar_testes` | 321 de 321 |
| `abrir_mestre` | 67 de 67 |
| `pecas_mestre` | **292 de 292** |
| `medir_mestre` | 220 ok, 0 falhas, 0 sem medida |
| `hud_acoes` | 50 de 50 |
| `caixa_jogadora` | 70 de 70 |
| `caixa_janela` | 123 de 123 |
| canário de privacidade | 10 de 10 |
| `validar-mensagens.py` | `pecas_mestre` 28 mensagens, 0 falhas (mínimo 16; eram 26, e as 2 a mais são os `MASTER_PLACE` novos); `abrir_mestre` 9, 0 falhas |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.
