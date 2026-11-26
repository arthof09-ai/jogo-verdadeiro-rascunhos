# ESTADO-FINAL — ORDEM-D-AUD-01-CORRECCOES-4 (o «Mover» desarma quando as opções da mesma vez chegam sem `mover`)

**Estado: FEITA.**

- **B1:** com opções novas da mesma vez sem `mover`, o «Mover» armado desarma. Escolhi **desarmar e avisar**
  (§1). Os dois testes novos passam com a correcção. Sem ela, só eles falham, pela mutação corrida no guião
  (exit 1 no `resumo.txt`).
- **B2:** está feito o comentário de uma linha no ramo `vez != _vez`.
- **B3:** a mutação correu pelo `suites.sh`, com `MESTRE_COMANDOS` e `timeout 300`, e o exit está no `resumo.txt`.
- **B4:** a limitação está declarada (§3).
- `pecas_mestre` dá **334 de 334** e as suites estão verdes. O CI está na nota do fim.

Dados da corrida:

- **Executor:** Claude (opus), PC. **Data:** 26/11/2026 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `08beeda` (nota do CI da D-AUD-14-SEGUIMENTO-MUTACAO). Conferi-a por `git ls-remote`
  (`08beeda6d4e99e236a1881ef7eec4c956711729e`) antes do primeiro commit. Fiz um clone novo em
  `ordem-d-aud-01-correccoes-4-pc/repo`.
- **Só correram testes headless.** A bancada de rede não correu.

## 1. B1 — o desarme (`rascunhos/cliente/cenas/mestre/aba_agir.gd:93-101`)

No `atualizar()` o teste do «Mover» passou para uma variável, `tem_mover`: `mover` é Array não vazio. O caso novo
fica assim:

```gdscript
var tem_mover: bool = op.get("mover") is Array and not op["mover"].is_empty()
if a_mover and not tem_mover:
	parar_mover()
	_info.text = (_info.text + "\n" if _info.text != "" else "") + Textos.MOVER_SEM_CASAS
if tem_mover:
	_botao(Textos.MOVER, iniciar_mover)
```

O `parar_mover()` faz quatro coisas:

- limpa `_casas`;
- apaga o destaque (`mestre.destacar([])`);
- esconde o «Cancelar»;
- apaga a ficha guardada do «Colocar» (`mestre.desarmou_mover()`).

É o mesmo desarme do sistema que a mudança de vez e o «sem opções» já faziam. Por isso o «Cancelar» depois disto
não repõe o «Colocar», e é coerente com a D-AUD-01-CORRECCOES-2: a ficha guardada não sobrevive ao desarme do
sistema.

O `parar_mover()` só corre **com o «Mover» armado**. Ficou assim por duas razões:

- sem «Mover» armado, a guarda está morta, pela indução do §2(a) da CORRECCOES-3;
- o aviso só faz sentido quando havia algo a desarmar.

As linhas 74 e 84, de «sem figura» e «sem opções», continuam a chamar o `parar_mover()` incondicionalmente, como
antes.

**Decisão de semântica: desarmar e avisar.** O destaque some do tabuleiro sem o Mestre ter tocado em nada. Sem
explicação, parece um defeito. O aviso usa uma constante nova, `Textos.MOVER_SEM_CASAS` (`textos_mestre.gd:126`):
«Mover: o servidor já não dá casas para mover nesta vez.».

- Vai para o `Info` da aba, junta-se ao «editar» e à «marcha livre» se estiverem lá, e não abre alerta.
- Fica até ao próximo `atualizar()`, que refaz o `Info`.
- Não se repete: no `atualizar()` seguinte `a_mover` já é falso.

É um aviso leve, que não pede acção ao Mestre. Se o Mestre preferir silêncio, basta tirar a linha do `_info`, e o
1.º teste deixa de pedir o aviso.

**Os testes** estão em `rascunhos/cliente/testes/pecas_mestre.gd`, a seguir ao teste da CORRECCOES-3. As opções
chegam pelo caminho real: `_rede._ao_receber(ROOM_OPTIONS)` na **mesma revisão**, depois `Estado.receber_opcoes`,
depois `opcoes_mudaram` e por fim `atualizar()`. As opções são as da fixture com `mover: []`, com os ataques e as
acções. A vista não muda. Assim não correm nem o ramo da vez nem o de «sem opções»: o único desarme possível é o
novo.

- **(a) Sem «Colocar».** O teste arma o «Mover» (casas destacadas) e depois chegam as opções sem `mover`. Pede:
  `a_mover` falso, `_casas` vazio, destaque vazio, «Cancelar» invisível, o aviso no `Info`, os botões de ataque e
  de acção lá e sem «Mover». Depois toca na casa velha (a 1.ª casa do `mover` da fixture) e pede **0 comandos**.
- **(b) Com «Colocar».** O teste arma o «Colocar» `orc-teste`, depois o «Mover» (a guarda viva), e chegam as
  opções sem `mover`. Pede: a guarda a `""`. Carrega no «Cancelar» e pede `a_colocar == ""`. Toca em (19,19) e na
  casa velha e pede **0 comandos, ou seja, 0 `MASTER_ACT` e 0 `MASTER_PLACE`**.

Os dois testes respondem aos comandos a mais, se os houver, para uma falha não derrubar as verificações seguintes.
No fim, repõem as opções com `mover` e a vista de origem.

**A mutação** (B3) troca `if a_mover and not tem_mover:` por `if false and a_mover and not tem_mover:`. Corre pelo
`suites.sh` antes das suites, com o mesmo `MESTRE_COMANDOS` e o mesmo `timeout 300`, e grava o exit no
`resumo.txt`:

```
pecas_mestre-SEM-B1 exit=1 falhas=2 falhas-correccoes-4=2 scriptErrors=0 reposto=sim
```

O resultado é **332 de 334**. As duas FALHA são as duas novas e não há falhas em cascata.

- Na (a): `desarma … false; aviso: false` e `["MASTER_ACT"]`, que é a casa-fantasma.
- Na (b): `guarda depois «orc-teste», a_colocar «orc-teste»` e `["MASTER_PLACE", "MASTER_PLACE"]`.

O ficheiro foi reposto com `git checkout`, e o guião confere o `git diff` vazio.

**Fica de fora (observação, sem mexer):** chegarem opções novas da mesma vez **com** `mover`, mas com casas
diferentes. O «Mover» armado fica com as `_casas` velhas. Um toque numa casa que saiu da lista manda um
`MASTER_ACT` que o servidor recusa. Uma casa que entrou é ignorada até o Mestre voltar a armar. É vizinho do J1,
mas não é o caso da ordem («sem `mover`»). Registo-o para o coordenador decidir.

## 2. B2 — o comentário (`aba_agir.gd:63`)

```gdscript
# Rede de segurança: as opções chegam normalmente primeiro e a guarda morre no parar_mover() de «sem opções».
if vez != _vez:
	parar_mover()
```

A ordem cita «a linha 82», que é a numeração de antes. Agora o `parar_mover()` de «sem opções» está na linha 84,
porque o comentário acrescentou uma linha. O comentário diz «de «sem opções»» em vez de dar o número, para não
envelhecer.

## 3. B4 — a limitação da prova do B2 da CORRECCOES-3

O passo **(d)** da prova do B2 (ESTADO-FINAL da CORRECCOES-3, §2) diz que o botão velho não chega a ser carregado.
Esse passo assenta numa **premissa externa ao repositório**: a ordem de despacho do Godot.

- O input da GUI é despachado fora do `SceneTree.process` (antes do `_process` do quadro).
- A fila do `queue_free()` esvazia-se no fim do quadro.

É comportamento documentado do motor. Não há nada a provar no repo e nenhum teste do repo o exercita. Fica
registado que a prova da inalcançabilidade do B2 depende dessa premissa. Se uma versão futura do Godot mudar a
ordem, o passo (d) tem de ser revisto. Os passos (a), (b), (c) e (e) assentam só em código do repo e no schema.

## 4. Provas (`provas/ordem-d-aud-01-correccoes-4/`, mapa no README)

Correram com Godot 4.7.2 `--headless` e Node v26.13.1, sobre `a158c31`.

| Suite | Resultado | Na D-AUD-01-CORRECCOES-3 |
|---|---|---|
| mutação do B1 (`pecas_mestre-SEM-B1`) | **exit 1, 332 de 334**: só as 2 novas falham | 294/295 (outra mutação) |
| servidor (`testes/*.test.mjs`), árvore LF | **446/446** | 435/435 |
| motor real, árvore LF | **6/6** | 2/2 |
| prova da caixa | PROVA OK | PROVA OK |
| `abrir_scripts` | 113 scripts, 0 falhas | 111 |
| `rodar_testes` | 333 de 333 | 321 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | **334 de 334** | 295 |
| `medir_mestre` | 0 falhas, 0 sem medida | 0, 0 |
| `hud_acoes` | 70 de 70 | 50 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| canário de privacidade | 10 de 10 | 10 |
| `validar-mensagens.py` | `pecas_mestre` 29, 0 falhas; `abrir_mestre` 9, 0 falhas | 29 / 9 |

As suites Godot deram todas exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`. A linha cresceu desde a
CORRECCOES-3, e daí os números maiores.

Há três registos a fazer. Os pormenores estão no README das provas.

- **Fim de linha.** No `resumo.txt` do guião, `servidor` (445/446) e `motor-real` (5/6) têm `exit=1`. Nos dois a
  única falha é uma comparação byte a byte com um ficheiro guardado (`mesa-mestre.json`, `01-ataque-normal.json`),
  porque o clone do PC tem `core.autocrlf=true` (`i/lf w/crlf`). No worktree LF do mesmo commit
  (`suites-node-lf.sh`) deram **446/446 e 6/6, exit 0**. O servidor não foi tocado. O CI corre em LF.
- **Duas corridas do guião.** Na 1.ª, o `python` do PC não tinha o `jsonschema`, e os dois validadores deram
  `ModuleNotFoundError`. Instalei-o num venv fora do repo, juntei `PYTHON` ao guião e corri tudo outra vez. Os
  resultados acima são da 2.ª corrida. O `resumo.txt` da 1.ª está em `suites/corrida-1/`, e a mutação deu igual nas
  duas.
- **Motor real.** Veio da pasta privada da bancada da D-AUD-06 (`MOTOR_MJS`, fora do repo). Não foi copiado.

## 5. Commits

- `07ea9ff`: B1 e B2. Inclui o `aba_agir.gd`, o `textos_mestre.gd` (`MOVER_SEM_CASAS`) e o `pecas_mestre.gd` (os
  dois testes).
- `a158c31`: listas da retoma sincronizadas com `retoma-i0004/actualizar-listas.py` (0 novos, 0 tirados; mudam os
  SHA dos três ficheiros no `depois.txt` e no `MANIFESTO-SHA256.txt`). Corri o guião com o `python` (3.12), porque
  neste PC o `python3` é o atalho da Microsoft Store.
- O commit das provas e deste ESTADO-FINAL não mexe em `rascunhos/`, por isso as listas não precisam de nova
  passagem.

## 6. Perímetro e privacidade

- Só mudou o cliente do Mestre (`aba_agir.gd`, `textos_mestre.gd`) e o teste dele. Não toquei na C-6, no «na vez»
  (D-AUD-03), na posição da caixa (ponto 5), no servidor, nos dados, no cliente da jogadora nem na `main`.
- Nomes: só os fictícios das fichas de teste. Nos logs, o caminho da máquina passou a `<sede>`.

## Secção C — para o Mestre (sem decisão)

Fica com o Mestre, como na sentença 930, secção C: a **terceira semântica** e a **preclusão literal da opção (b)
do Plano 2**. Esta ordem não as decide nem lhes toca. A semântica do B1 (desarmar e avisar) é só a do «Mover»
armado perante opções sem `mover`, e não decide nenhuma das duas.
