# ESTADO-FINAL — ORDEM-D-AUD-01-CORRECCOES-6 (J1 + J4 + J8)

**Estado: FEITA.**

- **J8:** a guarda em `_casas_de` tem o texto da ordem (`386813e`).
- **J4:** a mitigação do teste da CORRECCOES-5 já não volta a armar o «Mover». Ficou um `_ok` só, e a limitação está
  registada no README (`2e226c7`).
- **J1:** o destaque é reposto sempre que o «Mover» está armado e as opções trazem `mover`. Há um teste novo no
  `pecas_mestre` (`9c831f9`).
- **Números exactos da ordem**, sobre `2e226c7` (antes do J1): `pecas_mestre` **336/336**, **SEM-REFRESCO
  335/336** (só o teste novo, agora com a casa que entrou engolida, `[]`) e **SEM-B1 333/336**.
- **Código final**, sobre `9c831f9`: `pecas_mestre` **337/337**, porque o J1 juntou uma verificação. SEM-REFRESCO dá
  336/337, SEM-J1 336/337 e SEM-B1 334/337. As suites estão verdes.
- **CI (Testes + Sonda):** verde em todos os commits da ordem. Está na nota do fim.

Dados da corrida:

- **Executor:** Claude (opus), conta 1, PC do cunhado, com o PC EM_USO (só código). **Data:** 27/11/2026 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. Não houve fusão e a `main` não foi tocada.
- **Ponta de partida:** `723cbe7`, medida com `git ls-remote` ao arrancar, igual à do coordenador. Clone novo em
  `ordem-d-aud-01-correccoes-6-pc/repo`, com `core.autocrlf=false`. Todos os push foram fast-forward.
- **Só correram testes headless.** A bancada de rede não correu.
- **Erratas de registo** (J2, J3, J5, J6, J9–J13): ficam com o coordenador. Não toquei em nenhum ESTADO-FINAL
  anterior.

## 1. J8 — `_casas_de` (`rascunhos/cliente/cenas/mestre/aba_agir.gd`)

O código é o da ordem, letra por letra, mais um comentário de duas linhas. Muda três coisas:

- um `mover` que não seja lista dá vazio;
- uma casa sem `x`/`y` salta (antes dava a casa-fantasma (-1,-1));
- uma casa repetida conta uma vez.

O `iniciar_mover()` e o refresco usam ambos esta função. Sobre `386813e`, o `pecas_mestre` dá 336/336.

## 2. J4 — a mitigação do teste da CORRECCOES-5 (`rascunhos/cliente/testes/pecas_mestre.gd`)

Tirei o `c._aba_agir.iniciar_mover()` da mitigação. Fica só o `_responder`, com um comentário a explicar porquê:
voltar a armar lia as casas novas e escondia que o refresco faltava.

**A opção que escolhi: um `_ok` só, com a limitação no README.** Com um `_ok` separado para «a casa que entrou», a
SEM-REFRESCO daria **duas** falhas num total de 337, e não os 335/336 exactos que a ordem exige. No README
(`provas/ordem-d-aud-01-correccoes-6/README.md`, §J4) ficou registado: «a mutação só discrimina o fantasma; a metade
da casa que entrou só é provada pela corrida verde».

**A prova** é o `j4.sh`, sobre `2e226c7`, com as duas mutações no texto exacto da CORRECCOES-5:

```
pecas_mestre exit=0 falhas=0 scriptErrors=0 fim=«336 de 336 verificações passaram.»
pecas_mestre-SEM-REFRESCO exit=1 falhas=1 falhas-correccoes-6=0 falhas-correccoes-5=1 falhas-correccoes-5-B2=0 falhas-correccoes-4=0 scriptErrors=0 fim=«335 de 336 verificações passaram.» reposto=sim
pecas_mestre-SEM-B1 exit=1 falhas=3 falhas-correccoes-6=0 falhas-correccoes-5=0 falhas-correccoes-5-B2=1 falhas-correccoes-4=2 scriptErrors=0 fim=«333 de 336 verificações passaram.» reposto=sim
```

Na SEM-REFRESCO a FALHA mostra a casa que entrou **engolida**:
`… a casa que saiu não manda nada (["MASTER_ACT"]) e a que entrou manda MASTER_ACT mover ([])`. Na CORRECCOES-5 ali
aparecia o `MASTER_ACT`, por causa de voltar a armar.

## 3. J1 — repor o destaque sempre que o «Mover» está armado

**Código.** No ramo `if a_mover and tem_mover:` do `atualizar()` ficou o texto da ordem, mais um comentário:

```gdscript
		var novas := _casas_de(op)
		_casas = novas
		mestre.destacar(_casas)
```

**O teste novo** fica no `pecas_mestre.gd`, logo a seguir ao da CORRECCOES-5, com a mensagem
«D-AUD-01-CORRECCOES-6 (J1): …»:

1. O «Mover» está armado e o destaque é o das `_casas` (33).
2. O esquema da Mesa liga-se (`ligar_esquema(true)`) e troca o destaque. O teste confere que este já não é o do
   «Mover».
3. Chegam as **mesmas** opções pela Rede (`ROOM_OPTIONS`, mesma revisão e mesma vez).
4. O teste pede `a_mover`, as mesmas `_casas` e `casas_destacadas() == _casas`.

No fim desliga o esquema e cancela o «Mover».

**Prova do J1:**

- com o J1, o `pecas_mestre` dá **337/337**;
- o teste novo sobre o código velho (a mutação SEM-J1, que repõe o bloco `if novas != _casas:`) dá **336/337**. Só
  falha o J1, com «0 casas destacadas, 33 armadas».

## 4. Código final (`provas/ordem-d-aud-01-correccoes-6/suites/resumo.txt`, sobre `9c831f9`)

```
pecas_mestre-SEM-REFRESCO exit=1 falhas=1 falhas-correccoes-6=0 falhas-correccoes-5=1 ... fim=«336 de 337 verificações passaram.» reposto=sim
pecas_mestre-SEM-J1 exit=1 falhas=1 falhas-correccoes-6=1 falhas-correccoes-5=0 ... fim=«336 de 337 verificações passaram.» reposto=sim
pecas_mestre-SEM-B1 exit=1 falhas=3 ... falhas-correccoes-5-B2=1 falhas-correccoes-4=2 ... fim=«334 de 337 verificações passaram.» reposto=sim
```

- **SEM-REFRESCO foi redefinida.** O J1 tirou a linha que a mutação velha mutava. O equivalente no código novo é
  trocar `_casas = novas` por `novas = _casas`. Falha só a CORRECCOES-5, com a casa que entrou em `[]`.
- **Desvio dos números da ordem.** Sobre o código final, os números são os da ordem mais 1 no total (337), porque o
  J1 juntou uma verificação. Os números **exactos** (336, 335/336, 333/336) foram medidos sobre `2e226c7`, antes do
  J1 (§2). Nenhuma falha a mais apareceu em nenhuma das corridas.

| Suite (sobre `9c831f9`) | Resultado |
|---|---|
| servidor | **459/459**, exit 0 |
| motor real | **não correu neste PC** (não há `MOTOR_MJS` privado). Verde no CI, job motor-real |
| prova da caixa | PROVA OK |
| `abrir_scripts` | 113 scripts, 0 falhas |
| `rodar_testes` | 333 de 333 |
| `abrir_mestre` | 67 de 67 |
| `pecas_mestre` | **337 de 337** |
| `medir_mestre` | 0 falhas, 0 sem medida |
| `hud_acoes` | 70 de 70 |
| `caixa_jogadora` | 70 de 70 |
| `caixa_janela` | 123 de 123 |
| canário de privacidade | 10 de 10 |
| `validar-mensagens.py` | `pecas_mestre` 30, 0 falhas; `abrir_mestre` 9, 0 falhas |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.

## 5. Commits (todos empurrados; não há nenhum commit só local)

| Commit | O quê |
|---|---|
| `386813e` | J8, com as listas da retoma sincronizadas no mesmo commit |
| `2e226c7` | J4, com as listas da retoma |
| `57779cd` | prova do J4: `muta.sh`, `j4.sh` e `j4/` (336, 335/336, 333/336) |
| `9c831f9` | J1, código e teste, com as listas da retoma |
| `4e64bb0` | prova final: `suites.sh` e `suites/` |
| (este) | README das provas e este ESTADO-FINAL |
| (seguinte) | a nota do CI |

**Um commit por ponto.** Corri o `actualizar-listas.py` (Python 3.12) a seguir a cada commit que mexe em
`rascunhos/` e juntei o resultado ao mesmo commit com `--amend`, **antes** do push. Assim nenhuma ponta empurrada
ficou com as listas desactualizadas, e o `retoma-pc` não falha pelo caminho, como falhou na CORRECCOES-5. Nas três
passagens deu 0 novos e 0 tirados: só mudaram os SHA no `depois.txt` e no `MANIFESTO-SHA256.txt`.

## 6. Perímetro e privacidade

- Só mudaram o `aba_agir.gd`, o `pecas_mestre.gd`, as listas da retoma e as provas.
- Não toquei no servidor, nos dados, no cliente da jogadora, nos ESTADO-FINAL anteriores nem na `main`.
- Nomes: só os fictícios das fichas de teste. Nos logs, o caminho da máquina passou a `<sede>`.

## Nota do CI

Testes e Sonda deram verde em cada commit da ordem:

| Commit | Testes dos rascunhos | Sonda de privacidade | Aparelhos (F2) |
|---|---|---|---|
| `386813e` (J8) | `45936124943` success | `45936124948` success | success |
| `2e226c7` (J4) | `45936228985` success | `45936229018` success | success |
| `57779cd` (prova J4) | `45936407923` success | `45936408008` success | success |
| `9c831f9` (J1) | `45936571109` success | `45936571146` success | (não esperei) |
| `4e64bb0` (prova final) | `45936927442` success | `45936927244` success | a correr |
| **`0aac77a`** (README + ESTADO-FINAL, ponta antes desta nota) | **`45937037447` success** | **`45937037487` success** | `45937037558` a correr |

**`0aac77a`, os 10 jobs dos Testes deram success:** servidor, validador-glb, motor-real (6 pass, 0 fail),
protocolo, cliente, godot-cliente, foto-mestre, provas-mapa, ponta-a-ponta e retoma-pc. No log do job cliente o
`pecas_mestre` dá **337 de 337**, e a verificação «D-AUD-01-CORRECCOES-6 (J1)» está «ok» (33 casas destacadas, 33
armadas). O retoma-pc ficou verde em todos os commits: as listas foram sincronizadas no mesmo commit (§5).

O «Aparelhos (F2)» não entra no critério desta ordem, que é Testes + Sonda. Esta nota só mexe no ESTADO-FINAL, não
em `rascunhos/`.
