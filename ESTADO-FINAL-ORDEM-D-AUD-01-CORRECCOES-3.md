# ESTADO-FINAL — ORDEM-D-AUD-01-CORRECCOES-3 (teste isolado do ramo da vez + o buraco formal do `iniciar_mover()`)

**Estado: FEITA.**

- **B1:** o teste novo isola o ramo `vez != _vez`. Sem esse ramo, o teste falha.
- **B2:** é **inalcançável** em produção. A prova está no §2. O código de produção não mudou.
- **A3:** a errata foi aplicada ao comentário do duplo armar.
- `pecas_mestre` dá **295 de 295**, com o teste novo «ok», e as suites estão verdes. O CI está na nota do fim.

Dados da corrida:

- **Executor:** Claude (opus), PC. **Data:** 24/11/2026 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `e671f49` (nota do CI da PLANO-2-F2). Conferi-a por `git ls-remote`
  (`e671f49a4d1063b23be30904a387a042f9671d31`) antes do primeiro commit e outra vez antes do push. Fiz um clone
  novo em `ordem-d-aud-01-correccoes-3-pc/repo`.
- **Só correram testes headless.** A bancada de rede não correu.
- A SENTENCA.md (`~/workspace/conferencias/…`) não está neste PC. Li a errata A1-A3 no commit do coordenador
  `4052913`, que já tinha mexido no comentário. A A3 ficou completa aqui (§3).

## 1. B1 — o teste isolado (`rascunhos/cliente/testes/pecas_mestre.gd`)

O teste novo vem a seguir ao teste da vez da D-AUD-01-CORRECCOES-2. Faz isto:

1. Arma o «Colocar» com `orc-teste`.
2. Arma o «Mover», sem o usar. **A guarda fica viva:** `a_mover`, `_colocar_guardado == "orc-teste"` e
   `a_colocar == ""`.
3. Muda a vez: uma vista com `vezId` de **outra criatura**, uma gémea da criatura da fixture com outro id, e
   **opções válidas para ela**, na mesma revisão.
4. Carrega no «Cancelar».
5. Toca na casa (19,19).

Pede: guarda `""` depois da mudança de vez, `a_mover` falso, `a_colocar == ""` e **0 `MASTER_PLACE`**. No fim
repõe as opções e a vista de origem, para as verificações seguintes.

**Porque a criatura gémea e as opções dela.** O `atualizar()` (`aba_agir.gd:60-100`) tem três `parar_mover()`:

- o do ramo da vez (linhas 63-64);
- o de «sem figura ou figura da jogadora» (linha 73);
- o de «sem opções» (linha 82).

Uma vista com um `vezId` que não existe cai na linha 73. Opções de outro `vezId` caem na 82, porque o `_opcoes()`
da linha 106 as dá vazias. O teste usa uma criatura que existe e opções que valem para ela, por isso a 73 e a 82
não correm. A única coisa que desarma o «Mover» é o ramo da vez. As opções entram no `Estado` sem o sinal, como
se chegassem com a vista. Se chegassem antes, o `atualizar()` corria com a vista velha e caía na linha 82.

**A prova de isolamento** é a mutação. Tirei as linhas 63-64 (`if vez != _vez: parar_mover()`), corri, e
desfiz a mudança com `git checkout`. Resultado em `suites/pecas_mestre-SEM-RAMO-DA-VEZ.log`, **294 de 295**:

- a única FALHA é o teste novo: `guarda depois «orc-teste», a_colocar «orc-teste», 1 MASTER_PLACE ["orc-teste"]`;
- o teste da D-AUD-01-CORRECCOES-2 passa **sem** o ramo, como a conferência disse no B1.

## 2. B2 — `iniciar_mover()` com `_casas` vazio e a guarda viva: **inalcançável**

O buraco está em `aba_agir.gd:123`: `a_mover = not _casas.is_empty()` desarma sem `parar_mover()`. Só é um defeito
se a guarda estiver viva. A prova tem cinco passos.

**(a) Guarda viva implica «Mover» armado, de onde se conclui que este é um 2.º armar.**

- A guarda só se escreve em `mestre.gd:716` (`armou_mover()`). Só há uma chamada a `armou_mover()`:
  `aba_agir.gd:125`. Essa chamada só corre se `a_mover` acabou de ficar `true` (`aba_agir.gd:123-124`).
- A guarda apaga-se em `mestre.gd:706` (`armou_colocar`), `mestre.gd:724` (`cancelou_mover`) e `mestre.gd:733`
  (`desarmou_mover`, chamado por `parar_mover()` em `aba_agir.gd:175`).
- `a_mover` só se escreve em `aba_agir.gd:17` (início, `false`), `aba_agir.gd:123` (o buraco) e `aba_agir.gd:171`
  (`parar_mover()`).

Por indução, enquanto a linha 123 não desarmar com a guarda viva, vale isto: guarda viva implica `a_mover`. O
buraco só abre num `iniciar_mover()` chamado com o «Mover» já armado, cujo `_opcoes().mover` não dê nenhuma casa.

**(b) Só um chamador em produção: o botão «Mover».**

Fora dos testes, `iniciar_mover` só aparece em `aba_agir.gd:91`: `_botao(Textos.MOVER, iniciar_mover)`. Esse
botão só nasce se o `_opcoes()` desse `atualizar()` tiver `mover` como Array **não vazio** (`aba_agir.gd:90`). Cada
`atualizar()` faz `queue_free()` aos botões velhos (`aba_agir.gd:66-67`).

**(c) O `_opcoes()` do clique é o `_opcoes()` do último `atualizar()`.**

O `_opcoes()` (`aba_agir.gd:104-108`) depende de duas coisas:

- `_vez`, que só se escreve no `atualizar()` (`aba_agir.gd:65`);
- `Estado.opcoes_validas()` (`estado.gd:257-264`), que lê `opcoes`, `tem_snapshot` e `revisao`.

Todas as escritas destes três campos no `estado.gd` emitem `opcoes_mudaram` na mesma chamada:

| Escrita | Emissão |
|---|---|
| `aplicar_snapshot` 111/117/119 | 166 (os `return` são anteriores à linha 111) |
| `receber_opcoes` 201/203 | 204 |
| `ver_revisao` 210 | 211, só se mudou |
| `limpar` 215/217/227 | 243 |
| `_aplicar_evento` 404 | 506, se `rev_mudou` |

O `_subir_revisao` (532-539), único escritor da `revisao` além de 117 e 217, só é chamado em 119, 203, 210 e 404.
Fora de `estado.gd`, nada escreve nestes campos em produção. Os usos externos são só de leitura (por exemplo `arena.gd:371/377/804`, `hud.gd:463-584`, `aba_agir.gd:105`;
também `lobby.gd:300`, `arena.gd:149/160/392`, `hud.gd:164/165/175`, `mestre.gd:737/813`).

O `opcoes_mudaram` está ligado sem `CONNECT_DEFERRED` a `_aba_agir.atualizar()` (`mestre.gd:196`). A mudança de vista chama o `atualizar()` (`mestre.gd:385`, dentro de `aplicar_vista`, `mestre.gd:373-385`; a
linha 375 é `vista = msg` e a 384 é `_aba_mesa.atualizar`). Logo, depois de cada mudança destas
entradas, o `atualizar()` corre na mesma pilha.

**(d) O botão velho não chega a ser carregado.**

As mensagens chegam no `Rede._process` (`rede.gd:373`; `_ws.poll()` na linha 381), dentro do `SceneTree.process` do Godot. Este
esvazia a fila do `queue_free()` no fim do mesmo quadro. O input da GUI despacha-se fora do `process`. Por isso um
botão refeito pelo `atualizar()` já não existe quando o próximo clique for despachado.

Daqui sai que o botão «Mover» que recebe um clique foi feito pelo último `atualizar()`, com o mesmo `_opcoes()` de
agora: `mover` é um Array não vazio.

Este elo assenta em semântica do motor Godot (input despachado antes do
`_process`; `queue_free()` esvaziada
no fim do quadro) e não em código lido no repositório nem em prova
executada.

**(e) Cada item do `mover` é um objecto, logo `_casas` não fica vazio.**

O servidor só faz `mover.push({ x, y, custoM })` (`servidor/nucleo/sala.js:889`, dentro de `calcularOpcoes` (`sala.js:870`; o `mover.push` está na 889)). O schema `protocolo/v2/ROOM_OPTIONS.schema.json:15-26` exige `items.type: object`. A `Rede`
passa o ROOM_OPTIONS intacto (`rede.gd:538`). Logo, cada item é `Dictionary`, o ciclo de `aba_agir.gd:120-122` põe
pelo menos uma casa, e a linha 123 dá `a_mover = true`. O ramo que desarma sem `parar_mover()` não corre.

**Conclusão.** Em produção, com o nosso servidor, `iniciar_mover()` nunca chega à linha 123 com `_casas` vazio e a
guarda viva. Só um chamador directo o alcança, e isso só existe nos testes. Ficam, fora do perímetro, duas
condições que quebrariam a prova:

- um servidor que mande `mover` com itens que não sejam objectos, o que viola o schema;
- uma mudança futura que chame `iniciar_mover()` noutro sítio, ou que mude `opcoes`/`revisao` sem emitir.

Seguindo a ordem («se não for, registar a prova»), não mexi no `aba_agir.gd`.

**Observação ao lado (não é B2 e não mexi):** se chegarem opções novas da **mesma** vez sem `mover`, mas com
ataques ou acções, o `atualizar()` não chama o `parar_mover()`. O «Mover» fica armado com as `_casas` velhas e com
a guarda. A guarda é coerente, mas o estado visível não é: o «Mover» fica armado sem botão, com `_casas` velhas e
destaque velho, e cada toque manda um `MASTER_ACT` que o servidor recusa (`acao_invalida`); o cliente não
desarma na recusa. Merece ordem de seguimento. O «Cancelar» continua a repor. Um toque numa
casa velha manda um `MASTER_ACT` que o servidor recusa. Registo-o para o coordenador decidir se merece ordem.

No fluxo normal de produção as ROOM_OPTIONS novas
chegam antes da MASTER_VIEW (a vista só vem por pedido
diferido ou resync, sempre depois das opções); por isso
a guarda morre normalmente na linha 82, e o ramo `vez
!= _vez` é rede de segurança para a vista chegar antes
das opções.

## 3. Errata A3

O comentário do teste do duplo armar (`pecas_mestre.gd:219-222`) diz agora isto: o `atualizar()` não re-arma o
«Mover», só refaz o botão e o liga outra vez a `iniciar_mover()`. O 2.º armar é sempre um 2.º `iniciar_mover()`:
duplo clique no mesmo botão, ou um clique no botão refeito.

## 4. Provas (`provas/ordem-d-aud-01-correccoes-3/`, mapa no README)

**Todos os logs começam com a linha do comando**, incluindo o `pecas_mestre.log`. A 1.ª linha do `pecas_mestre-SEM-RAMO-DA-VEZ.log` é um comando anotado (a
mutação descrita entre parênteses,
sem `MESTRE_COMANDOS` nem `timeout 300`); essa corrida não escreveu
`comandos-*.jsonl` e o seu exit não está
no `resumo.txt`.
Tirei o caminho da máquina e
pus `<sede>` no lugar.

| Corrida do `pecas_mestre` | Resultado |
|---|---|
| Sem o ramo da vez (mutação temporária, não commitada) | **294 de 295**. A única FALHA é a nova (1 `MASTER_PLACE` `orc-teste`), e o teste da D-AUD-01-CORRECCOES-2 passa |
| Ponta com os testes (`bd3c79b`) | **295 de 295** |

Não há corrida ANTES à parte, porque o código de produção não mudou.

| Suite (sobre `bd3c79b`, Godot 4.7.2 `--headless`) | Resultado | Na D-AUD-01-CORRECCOES-2 |
|---|---|---|
| servidor (`testes/*.test.mjs`) | **435/435** | 421/421 (a linha cresceu entre `68ffd3e` e `e671f49`) |
| motor real | 2/2 | 2/2 |
| prova da caixa | PROVA OK | PROVA OK |
| `abrir_scripts` | 111 scripts, 0 falhas | 108 (idem) |
| `rodar_testes` | 321 de 321 | 321 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | **295 de 295** | 294 |
| `medir_mestre` | 0 falhas, 0 sem medida | 0, 0 |
| `hud_acoes` | 50 de 50 | 50 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| canário de privacidade | 10 de 10 | 10 |
| `validar-mensagens.py` | `pecas_mestre` 29, 0 falhas; `abrir_mestre` 9, 0 falhas | 29 / 9 |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.

## 5. Commits

- `bd3c79b`: o teste isolado e a errata A3 (`pecas_mestre.gd`).
- `8f3c867`: listas da retoma sincronizadas com `retoma-i0004/actualizar-listas.py` (0 novos, 0 tirados). Só mudou
  o SHA do `pecas_mestre.gd`, no `depois.txt` e no `MANIFESTO-SHA256.txt`. Corri o guião com o `python` (3.12),
  porque neste PC o `python3` é o atalho da Microsoft Store.
- O commit das provas e deste ESTADO-FINAL não mexe em `rascunhos/`, por isso as listas não precisam de nova
  passagem.

## 6. Perímetro e privacidade

- Só mudou o teste. Não mexi na semântica da exclusão, no servidor, nos workflows, nos dados nem na `main`.
- O ponto da Secção C fica para o Mestre.
- A errata A4 (`MANIFESTO-SHA256.txt:2`) fica para o coordenador. O guião das listas não tocou nessa linha.
- O motor real veio da pasta privada da bancada da D-AUD-01 (`MOTOR_MJS`, fora do repo). Não foi copiado.
- Nomes: só os fictícios das fichas de teste.

## Nota do CI

- `4746c9d` (teste + listas + provas + ESTADO-FINAL): **Testes dos rascunhos 45333270344: success**, com os 10 jobs
  verdes (servidor, validador-glb, motor-real, protocolo, cliente, godot-cliente, foto-mestre, provas-mapa,
  ponta-a-ponta, retoma-pc), e **Sonda de privacidade 45333270447: success**. No log do CI: `pecas_mestre` 295 de
  295, com a D-AUD-01-CORRECCOES-3 «ok», e `rodar_testes` 321 de 321. O `retoma-pc` passou à primeira.

Nota da conferência (930): erratas A1–A8 aplicadas no `90c16b46` (base `0c57f2bb`). CI verde no `90c16b46` — Testes 45442684178 + Sonda 45442684015, ambos success.
