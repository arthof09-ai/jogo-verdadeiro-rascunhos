# Provas — ORDEM-D-AUD-01-CORRECCOES-2 (23/11/2026)

A conferência da D-AUD-01-CORRECCOES (830, ENTRA COM CORRECÇÕES) encontrou um buraco: `armou_mover()` guardava o
`a_colocar` sem condição. Armar o «Mover» duas vezes (duplo clique — no mesmo botão ou no botão refeito pelo `atualizar()`, que só o volta a ligar a `iniciar_mover()`) guardava
`""` por cima da ficha, e o «Cancelar» já não repunha o «Colocar». Faltava também prova do ramo «a vez muda».

Prova só com o teste de unidade, as suites e o CI, tudo headless. **A bancada de rede não correu.** Não há capturas.

## As 2 verificações novas (`testes/pecas_mestre.gd`, bloco «aba Agir»)

| Verificação | O que faz | Resultado |
|---|---|---|
| `D-AUD-01-CORRECCOES-2: «Colocar» → armar «Mover» duas vezes → «Cancelar» repõe …` | `escolher_colocar("orc-teste")` → `iniciar_mover()` ×2 → botão «Cancelar» (`_cancelar.pressed`) → toque | Mover desarmado, `a_colocar == "orc-teste"`, **1 `MASTER_PLACE` `["orc-teste"]`** |
| `D-AUD-01-CORRECCOES-2: mover usado → a vez muda → «Mover» → «Cancelar» não repõe a ficha velha` | depois do `MASTER_ACT mover` (com o «Colocar» armado antes): `a_colocar` lido → vista com outra `vezId` → vista da vez original → `iniciar_mover()` → «Cancelar» → toque | `a_colocar == ""` depois do mover, Mover rearmado, `a_colocar` continua `""`, **0 `MASTER_PLACE`** |

## Três corridas do `pecas_mestre` (`suites/`)

A primeira linha dos logs ANTES e SÓ-PONTO-1 é o comando da corrida; o `pecas_mestre.log` não traz linha de comando (começa no cabeçalho do Godot) e a sua proveniência fica coberta pelo CI + commit.

1. `pecas_mestre-ANTES-da-correccao.log`: os testes novos sobre o código da ponta `2385651`. Dá **293 de 294**. A
   única FALHA é o duplo armar (`0 MASTER_PLACE []`).
2. `pecas_mestre-SO-PONTO-1.log`: só o ponto 1 da ordem (guarda condicional), sem limpar a guarda. Dá **283 de 294**.
   O duplo armar passa, mas o teste da vez FALHA com **1 `MASTER_PLACE`**: a ficha guardada pelo «Mover» que já foi
   usado sobreviveu, e o «Cancelar» de um «Mover» armado mais tarde repôs a ficha velha. As outras 10 FALHAS vêm em
   cascata desse `MASTER_PLACE` a mais, que ficou em voo sem recibo. Na versão final o teste responde-lhe se ele
   aparecer, para uma falha não arrastar as outras. Esta corrida prova que o ponto 3 da ordem (limpar a guarda nos
   desarmes do sistema) passa a ser necessário com o ponto 1.
3. `pecas_mestre.log`: com a correcção inteira (`72e1103`), **294 de 294**.

## Suites (`suites/`, resumo em `suites/resumo.txt`)

Corridas neste PC com Godot 4.7.2 `--headless` e Node, sobre `72e1103`. São as mesmas da D-AUD-01-CORRECCOES, com o
mesmo guião (só mudaram os caminhos da pasta). Tirei dos logs o caminho da máquina (`<sede>`).

| Suite | Resultado | Na D-AUD-01-CORRECCOES |
|---|---|---|
| servidor (`testes/*.test.mjs`) | 421/421 | 421/421 |
| motor real (`testes-motor-real`) | 2/2 | 2/2 |
| prova da caixa | PROVA OK | PROVA OK |
| `abrir_scripts` | 108 scripts, 0 falhas | 108, 0 |
| `rodar_testes` | 321 de 321 | 321 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | **294 de 294** | 292 |
| `medir_mestre` | 220 ok, 0 falhas, 0 sem medida | 220, 0 |
| `hud_acoes` | 50 de 50 | 50 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| canário de privacidade | 10 de 10 | 10 |
| `validar-mensagens.py` | `pecas_mestre` 29 mensagens, 0 falhas (o `MASTER_PLACE` a mais é o do duplo armar); `abrir_mestre` 9, 0 falhas | 28 / 9 |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.

Comandos (a partir da raiz do repo; `G` é o Godot 4.7.2):

```
cd rascunhos/servidor && node --test --test-isolation=none --test-timeout=30000 --test-reporter=spec "testes/*.test.mjs"
node provas/ordem-caixa/ferramentas/prova-servidor.mjs
cd rascunhos/servidor && MOTOR_MJS=<motor privado, fora do repo> node --test --test-reporter=spec "testes-motor-real/*.test.mjs"
cd rascunhos/cliente && MESTRE_COMANDOS=<sede>/tmp/suites/comandos-<suite>.jsonl $G --headless --path . -s res://testes/<suite>.gd
python rascunhos/protocolo/ferramentas/validar-mensagens.py <sede>/tmp/suites/comandos-<suite>.jsonl
```
