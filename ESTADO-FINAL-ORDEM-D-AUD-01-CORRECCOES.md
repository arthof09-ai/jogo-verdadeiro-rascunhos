# ESTADO-FINAL — ORDEM-D-AUD-01-CORRECCOES (cancelar o «Mover» repõe o «Colocar» + 5.º caso no teste)

**Estado: FEITA.** Quando o Mestre cancela o «Mover», o «Colocar» que o «Mover» tinha desarmado volta armado, com a
mesma ficha. O 5.º caso tem agora teste. `pecas_mestre` dá **292 de 292**, com as 2 verificações novas «ok», e as
suites estão verdes. O CI está na nota do fim.

- **Executor:** Claude (opus), PC. **Data:** 23/11/2026, das ~17:38 às ~17:50 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `cdc08be` (nota do CI da MAPA-JOGAVEL-CUSTO-CAMARA), conferida por `git ls-remote`
  (`cdc08be2d7763143675e2b4af5f5ada30b21491f`) ao começar e outra vez antes do push. Clonei-a de novo em
  `ordem-d-aud-01-correccoes-pc/repo`.
- **Só correram testes headless.** A bancada de rede não correu, para não perturbar a medição de GPU do MAPA.

## 1. A correcção

| Ficheiro | Mudança |
|---|---|
| `cenas/mestre/mestre.gd` | Nova `var _colocar_guardado`. `armou_mover()` guarda o `a_colocar` da Mesa antes do `parar()`. A nova `cancelou_mover()` repõe-no com `_aba_mesa.escolher_colocar(ficha)` e depois limpa-o. `armou_colocar()` também o limpa, porque uma escolha nova no Colocar manda |
| `cenas/mestre/aba_agir.gd` | O botão «Cancelar» passa a ligar-se a `cancelar_mover()`. Essa função faz `parar_mover()` e, se o Mover estava armado, chama `mestre.cancelou_mover()` |
| `testes/pecas_mestre.gd` | 2 verificações novas (§2) |

`aba_mesa.gd` não mudou. A reposição usa `escolher_colocar()`, que já existia: volta a mostrar «Parar de colocar» e
o texto da ficha, e passa por `armou_colocar()`, como uma escolha normal.

**Onde a reposição acontece e onde não.** A ordem diz «`parar_mover()` repõe-no quando o Mover é cancelado». Pus a
reposição no **cancelamento explícito** (o botão «Cancelar»), e não dentro de `parar_mover()`. É que `parar_mover()`
também corre noutros casos, e em nenhum deles o Mestre cancelou:

- depois de mover (`agir()`): o Mover foi usado e não cancelado. Se o Colocar voltasse aqui, o toque seguinte ia
  colocar sem o Mestre o ter pedido outra vez;
- quando a vez muda, ou quando não há opções (`atualizar()`);
- dentro de `armou_colocar()`: aí o Colocar novo é que manda.

Nestes casos o Colocar fica desarmado, como na D-AUD-01. Se o Mestre quiser outra coisa, a mudança é de uma linha.

**A semântica não mudou.** A exclusão mútua continua simétrica: fica armado só o último que o Mestre escolheu. Com o
Mover armado, escolher uma ficha no Colocar desarma o Mover e apaga o que estava guardado. Armar o Mover outra vez
volta a guardar. O ponto da Secção C da sentença (a terceira semântica e a preclusão literal da opção (b) do Plano 2)
fica em aberto, e a decisão é do Mestre.

## 2. As provas (`provas/ordem-d-aud-01-correccoes/`, mapa no README)

| Verificação nova | Resultado |
|---|---|
| **cancelar repõe:** Colocar `orc-teste` → armar Mover → «Cancelar» → toque | ok: Mover desarmado, Colocar `orc-teste` armado, **1 `MASTER_PLACE` (`orc-teste`)** |
| **5.º caso:** Mover armado → escolher `lobo-teste` no Colocar → toque | ok: **1 `MASTER_PLACE` (`lobo-teste`), 0 do `orc-teste`** |

- **Sem a correcção** (o teste novo sobre o código da ponta): **291 de 292**. A única FALHA é «cancelar repõe»
  (`0 MASTER_PLACE []`). O 5.º caso já passava, e isso confirma o que a conferência disse
  (`suites/pecas_mestre-ANTES-da-correccao.log`).
- **Com a correcção:** **292 de 292** (`suites/pecas_mestre.log`).

## 3. Suites (com a correcção, neste PC, Godot 4.7.2 `--headless`)

| Suite | Resultado | Na D-AUD-01 |
|---|---|---|
| servidor (`testes/*.test.mjs`) | **421/421** | 421/421 |
| motor real (`testes-motor-real`) | 2/2 | 2/2 |
| prova da caixa (`prova-servidor.mjs`) | PROVA OK | PROVA OK |
| `abrir_scripts` | 108 scripts, 0 falhas | 108, 0 |
| `rodar_testes` | **321 de 321** | 321 |
| `abrir_mestre` | **67 de 67** | 67 |
| `pecas_mestre` | **292 de 292** | 290 |
| `medir_mestre` | 220 ok, **0 falhas**, 0 sem medida | 220, 0 |
| `hud_acoes` | **50 de 50** | 50 |
| `caixa_jogadora` | **70 de 70** | 70 |
| `caixa_janela` | **123 de 123** | 123 |
| canário de privacidade | **10 de 10** | 10 |
| `validar-mensagens.py` | `pecas_mestre` 28 mensagens, 0 falhas (mín. 16); `abrir_mestre` 9, 0 falhas (mín. 5) | 26 / 9 |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.

## 4. Commits

- `062bbc4`: correcção (`mestre.gd`, `aba_agir.gd`) e as 2 verificações (`pecas_mestre.gd`).
- `4e897a8`: listas da retoma sincronizadas com `retoma-i0004/actualizar-listas.py` (0 novos, 0 tirados). Só
  mudaram os 3 SHA dos ficheiros desta ordem, no `depois.txt` e no `MANIFESTO-SHA256.txt`. Neste PC, o `python3` é
  o atalho da Microsoft Store, por isso corri o guião com o `python` (3.12).
- o commit das provas e deste ESTADO-FINAL, que não muda nada em `rascunhos/`.

## 5. Perímetro e privacidade

- Escrevi só o código da causa (2 ficheiros do ecrã do Mestre), o teste, as provas e este ESTADO-FINAL. As listas da
  retoma mudaram pelo guião da casa. O servidor, os workflows, os dados e a `main` ficaram como estavam.
- O motor real das suites veio da pasta privada da bancada da D-AUD-01 (`MOTOR_MJS`, fora do repo). Não foi copiado.
- Nomes: só os fictícios das fichas de teste. Tirei dos logs o caminho com o utilizador da máquina (`<sede>`).

## Nota do CI

(segue no commit seguinte)
