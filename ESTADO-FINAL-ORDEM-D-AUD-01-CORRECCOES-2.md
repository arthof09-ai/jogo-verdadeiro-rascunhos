# ESTADO-FINAL — ORDEM-D-AUD-01-CORRECCOES-2 (guardar o «Colocar» só quando há ficha + testes do duplo armar e da mudança de vez)

**Estado: FEITA.** Armar o «Mover» duas vezes já não apaga a ficha guardada, e o «Cancelar» repõe o «Colocar». Com
o «Mover» usado e a vez mudada, o «Cancelar» não repõe a ficha velha. `pecas_mestre` dá **294 de 294**, com as 2
verificações novas «ok», e as suites estão verdes. O CI está na nota do fim.

- **Executor:** Claude (opus), PC. **Data:** 23/11/2026, das ~21:16 às ~21:30 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `2385651` (nota do CI da D-AUD-04-BANCADA), conferida por `git ls-remote`
  (`2385651f65e092d2243f86c716520ebdbc53d5d3`) antes do primeiro commit e outra vez antes do push. Clone novo em
  `ordem-d-aud-01-correccoes-2-pc/repo`.
- **Só correram testes headless.** A bancada de rede não correu, para não perturbar o trabalho de GPU da outra cadeira.

## 1. A correcção

| Ficheiro | Mudança |
|---|---|
| `cenas/mestre/mestre.gd` | **Ponto 1:** `armou_mover()` só guarda o `a_colocar` quando há ficha (`if _aba_mesa.a_colocar != ""`). **Ponto 3:** nova `desarmou_mover()`, que apaga `_colocar_guardado`. O comentário da variável (antes na linha 102) diz agora quanto tempo ela vale |
| `cenas/mestre/aba_agir.gd` | `parar_mover()` chama `mestre.desarmou_mover()`. `cancelar_mover()` repõe (`mestre.cancelou_mover()`) **antes** de `parar_mover()`, porque este apaga a guarda |
| `testes/pecas_mestre.gd` | 2 verificações novas (§2) |

**Ponto a conferir: o ponto 3 deixou de ser opcional.** A ordem dava o ponto 3 como opcional, por o cheiro estar
provado inalcançável. Era inalcançável com o código antigo, porque cada `armou_mover()` escrevia por cima da guarda.
Com o ponto 1 deixa de escrever quando não há ficha, e a guarda velha passa a ser alcançável. Caminho: «Colocar» armado,
depois «Mover», depois mover. A guarda fica com a ficha. Mais tarde o Mestre arma o «Mover» e cancela, e a ficha
velha volta.

A corrida `suites/pecas_mestre-SO-PONTO-1.log` (só com o ponto 1) prova-o. O teste da mudança de vez FALHA com
**1 `MASTER_PLACE`** da ficha velha. Por isso limpei a guarda em todos os desarmes do sistema: depois de mover,
quando a vez muda, quando não há opções e no `armou_colocar()`. Tudo passa por `parar_mover()`. A guarda só
sobrevive enquanto o «Mover» que a guardou estiver armado, e só o «Cancelar» a gasta.

A mudança no `aba_agir.gd` é de 3 linhas. A ordem fala só de `mestre.gd`, mas os desarmes do sistema estão todos no
`parar_mover()` do Agir, e foi aí que os liguei.

**A semântica não mudou.** A exclusão mútua continua simétrica: fica armado só o último que o Mestre escolheu. A
reposição continua só no «Cancelar» explícito, como na D-AUD-01-CORRECCOES. O ponto da Secção C (a terceira
semântica e a preclusão literal da opção (b) do Plano 2) fica em aberto, e a decisão é do Mestre.

## 2. As provas (`provas/ordem-d-aud-01-correccoes-2/`, mapa no README)

| Verificação nova | Resultado |
|---|---|
| **duplo armar repõe:** Colocar `orc-teste` → armar Mover duas vezes → «Cancelar» → toque | ok: Mover desarmado, Colocar `orc-teste` armado, **1 `MASTER_PLACE` (`orc-teste`)** |
| **a vez muda e não repõe:** Mover usado (Colocar armado antes) → `a_colocar` é `""` → a vez muda e volta → Mover → «Cancelar» → toque | ok: `a_colocar` fica `""`, **0 `MASTER_PLACE`** |

| Corrida do `pecas_mestre` | Resultado |
|---|---|
| ANTES (testes novos, código da ponta `2385651`) | **293 de 294**: FALHA só o duplo armar (`0 MASTER_PLACE []`) |
| Só o ponto 1 | **283 de 294**: FALHA o teste da vez (1 `MASTER_PLACE` da ficha velha), mais 9 em cascata desse comando sem recibo |
| Correcção inteira (`72e1103`) | **294 de 294** |

## 3. Suites (com a correcção, neste PC, Godot 4.7.2 `--headless`)

| Suite | Resultado | Na D-AUD-01-CORRECCOES |
|---|---|---|
| servidor (`testes/*.test.mjs`) | **421/421** | 421/421 |
| motor real (`testes-motor-real`) | 2/2 | 2/2 |
| prova da caixa (`prova-servidor.mjs`) | PROVA OK | PROVA OK |
| `abrir_scripts` | 108 scripts, 0 falhas | 108, 0 |
| `rodar_testes` | **321 de 321** | 321 |
| `abrir_mestre` | **67 de 67** | 67 |
| `pecas_mestre` | **294 de 294** | 292 |
| `medir_mestre` | 220 ok, **0 falhas**, 0 sem medida | 220, 0 |
| `hud_acoes` | **50 de 50** | 50 |
| `caixa_jogadora` | **70 de 70** | 70 |
| `caixa_janela` | **123 de 123** | 123 |
| canário de privacidade | **10 de 10** | 10 |
| `validar-mensagens.py` | `pecas_mestre` 29 mensagens, 0 falhas; `abrir_mestre` 9, 0 falhas | 28 / 9 |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.

## 4. Commits

- `72e1103`: correcção (`mestre.gd`, `aba_agir.gd`) e as 2 verificações (`pecas_mestre.gd`).
- `0ba3245`: listas da retoma sincronizadas com `retoma-i0004/actualizar-listas.py` (0 novos, 0 tirados). Só
  mudaram os 3 SHA dos ficheiros desta ordem, no `depois.txt` e no `MANIFESTO-SHA256.txt`. Corri o guião com o
  `python` (3.12), porque neste PC o `python3` é o atalho da Microsoft Store.
- O commit das provas e deste ESTADO-FINAL não mexe em `rascunhos/`, por isso as listas não precisam de nova passagem.

## 5. Perímetro e privacidade

- Escrevi só o código da causa (2 ficheiros do ecrã do Mestre), o teste, as provas e este ESTADO-FINAL. As listas da
  retoma mudaram pelo guião da casa. O servidor, os workflows, os dados e a `main` ficaram como estavam.
- O motor real das suites veio da pasta privada da bancada da D-AUD-01 (`MOTOR_MJS`, fora do repo). Não foi copiado.
- Nomes: só os fictícios das fichas de teste. Tirei dos logs o caminho com o utilizador da máquina (`<sede>`).
