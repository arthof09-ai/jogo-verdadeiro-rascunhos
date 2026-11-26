# ESTADO-FINAL — ORDEM-D-AUD-01-CORRECCOES-5 (o «Mover» armado refresca as casas; E1; o aviso do B2 persiste)

**Estado: FEITA.**

- **Passo 1 (caso vizinho (a)):** quando chegam opções da mesma vez com `mover` mas com outras casas, o «Mover»
  armado passa a usar as casas novas. Escolhi **refrescar**, e não desarmar (§1).
- **Passo 2:** há um teste novo. A casa que saiu não manda nada, e a que entrou manda `MASTER_ACT mover`.
- **Passo 3:** a mutação do refresco correu pelo `suites.sh` e deu **335 de 336**. Só falha o teste novo.
- **Passo 4 (E1):** o teste (b) leva o texto exacto da ordem. Sobre o commit da E1 o `pecas_mestre` dá **334 de 334**
  e a mutação do B1 dá **332 de 334**, com só as duas da CORRECCOES-4 a falhar.
- **Passo 5 (B2):** o aviso fica no `Info` enquanto as opções desta vez não trouxerem `mover`. Há uma asserção nova.
- **Passo 6:** as suites estão verdes e o `pecas_mestre` final dá **336 de 336**. O CI está na nota do fim.

Dados da corrida:

- **Executor:** Claude (opus), PC. **Data:** 26/11/2026 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `5751cce` (nota do CI da PLANO-2-F2-ANDROID-SHADER). Clone novo em
  `ordem-d-aud-01-correccoes-5-pc/repo`, com `core.autocrlf=false`. Não houve rebase: a ponta remota não andou
  durante o trabalho, e todos os push foram fast-forward.
- **Só correram testes headless.** A bancada de rede não correu.

## 1. Passo 1 — o refresco (`rascunhos/cliente/cenas/mestre/aba_agir.gd`, `atualizar()`)

```gdscript
if a_mover and tem_mover:
	# (comentário de 4 linhas)
	var novas := _casas_de(op)
	if novas != _casas:
		_casas = novas
		mestre.destacar(_casas)
```

`_casas_de(op)` é uma função nova. Lê as casas do `mover`, e o `iniciar_mover()` passou a usá-la também (mesmo
código, agora num só sítio).

**Decisão delegada: refrescar, e não desarmar e avisar.** As razões:

- As opções novas trazem casas válidas para esta vez, por isso continua a haver o que mover. Desarmar obrigava o
  Mestre a voltar a carregar no «Mover» sem razão.
- O Mestre vê a mudança: o destaque passa a ser o novo e o `Info` mostra a contagem nova
  (`MOVER_ESCOLHER % _casas.size()`, no fim do `atualizar()`).
- O «Mover» fica armado, e com ele o «Cancelar» e a ficha guardada do «Colocar». O `armou_mover()` não corre outra
  vez, por isso a guarda não é reescrita. O «Cancelar» continua a repor o «Colocar», como antes das opções novas.

Se o Mestre preferir desarmar, basta trocar o corpo do `if` por `parar_mover()` com o aviso.

Resultado:

- uma casa que saiu da lista já não está em `_casas`, e o `mover()` engole o toque (não há `MASTER_ACT` recusado);
- uma casa que entrou já está em `_casas` e manda o `MASTER_ACT`.

## 2. Passo 2 — o teste (`rascunhos/cliente/testes/pecas_mestre.gd`, «D-AUD-01-CORRECCOES-5: …»)

As opções novas chegam pelo caminho real, como nos testes da CORRECCOES-4:

`_rede._ao_receber(ROOM_OPTIONS)` na **mesma revisão** → `Estado.receber_opcoes` → `opcoes_mudaram` → `atualizar()`

A vista não muda. As opções novas são as da fixture com o `mover` mudado:

- sai a 1.ª casa, (1,3);
- entra (7,3), com `custoM` 7,5. Está fora do orçamento de 6 m da fixture e por isso não estava no `mover` velho.

É o mesmo ROOM_OPTIONS que o servidor manda, por exemplo, depois de aprovar um cartão de IA com proposta de
movimento. O teste não passa pelo cartão: entra directamente pela Rede.

O teste pede:

- **armado antes:** `_casas` tem a casa que sai e não tem a que entra;
- **depois das opções novas:** `a_mover`, `_casas == novas`, `casas_destacadas() == novas`, o «Cancelar» visível e o
  `Info` igual a `MOVER_ESCOLHER % novas.size()`;
- tocar na casa que saiu dá **0 comandos**;
- tocar na casa que entrou dá **um** `MASTER_ACT` com `tipo: mover` e esse destino.

Responde aos comandos que saem, e no fim repõe as opções da fixture e a vista.

## 3. Passo 3 — a mutação (`provas/ordem-d-aud-01-correccoes-5/suites.sh`)

O guião troca `if novas != _casas:` por `if false and novas != _casas:`. Corre com `MESTRE_COMANDOS` e
`timeout 300`, repõe com `git checkout` e confere o `git diff` vazio. O resultado ficou no `resumo.txt`:

```
pecas_mestre-SEM-REFRESCO exit=1 falhas=1 falhas-correccoes-5=1 falhas-correccoes-5-B2=0 falhas-correccoes-4=0 scriptErrors=0 fim=«335 de 336 verificações passaram.» reposto=sim
```

Só falha o teste novo. A FALHA mostra o refresco a `false` e a casa que saiu a mandar `["MASTER_ACT"]`, que é a
casa-fantasma.

O mesmo guião corre também a mutação do B1 da CORRECCOES-4 sobre o código final:

```
pecas_mestre-SEM-B1 exit=1 falhas=3 falhas-correccoes-5=0 falhas-correccoes-5-B2=1 falhas-correccoes-4=2 scriptErrors=0 fim=«333 de 336 verificações passaram.» reposto=sim
```

Agora há três falhas: as duas da CORRECCOES-4 e a asserção do B2. Sem o desarme, o `_aviso_sem_casas` nunca liga.
É o esperado. Os 332 de 334 pedidos pela ordem são os da E1, medidos antes das verificações novas (§4).

## 4. Passo 4 — E1

O teste (b) leva o texto **exacto** da ordem:

- as quatro leituras (`desarmado_b`, `aviso_b`, `rot_b`) a seguir a `guarda_depois_b`, antes do
  `_cancelar.pressed.emit()`;
- a condição nova do `_ok`, com a mensagem igual.

Foi um commit só para isto (`3b6bf7b`), sem nenhuma mudança de código desta ordem. Corri sobre ele o `e1.sh`
(`provas/.../e1/resumo.txt`):

```
pecas_mestre exit=0 ok=334 falhas=0 ... fim=«334 de 334 verificações passaram.»
pecas_mestre-SEM-B1 exit=1 ok=332 falhas=2 falhas-correccoes-4=2 scriptErrors=0 fim=«332 de 334 verificações passaram.»
reposto=sim
```

**A E1 está provada:** dá 334 de 334, e a mutação do B1 dá 332 de 334 com só as duas da CORRECCOES-4 a falhar. A
ordem fez a E1 o passo 4. Corri-a primeiro para poder medir estes números exactos, porque os passos 2 e 5 juntam
duas verificações ao `pecas_mestre`.

## 5. Passo 5 — B2: o aviso persiste enquanto não houver `mover` nesta vez

A mudança está no `aba_agir.gd`. Há uma variável nova, `_aviso_sem_casas`, e o aviso passa a ser recalculado em
cada `atualizar()`:

- **liga** no desarme do B1 (`a_mover and not tem_mover`);
- **desliga** quando as opções desta vez trazem `mover`, ou quando a vez muda (ramo `vez != _vez`);
- enquanto está ligada, cada `atualizar()` com opções põe `MOVER_SEM_CASAS` no `Info`.

O aviso só nasce do desarme. Uma criatura que nunca teve o «Mover» armado não o vê. Isto segue a semântica da
CORRECCOES-4: o aviso explica um destaque que saiu.

Com «sem opções» o `atualizar()` sai cedo e mostra `AGIR_SEM_OPCOES`. A variável fica, e o aviso volta se
chegarem outra vez opções sem `mover` na mesma vez. Para voltar ao aviso de tiro único basta uma palavra do Mestre:
pôr `_aviso_sem_casas = false` logo a seguir a pôr o texto no `Info`.

**A asserção** («D-AUD-01-CORRECCOES-5 (B2): …») fica logo a seguir ao teste (b), com o estado em que o (b) o
deixa: mesma vez, opções sem `mover`, «Mover» desarmado.

1. Faz um 2.º `atualizar()` com as **mesmas** opções, pela Rede. Pede o aviso no `Info`.
2. Chegam as opções com `mover`. Pede o aviso fora.

É um `_ok` separado, e não uma condição a mais no `_ok` do (b). Assim o (b) fica exactamente como a E1 o escreve, e
a contagem da E1 (334 e 332) pode ser repetida no commit dela. Com o código da CORRECCOES-4 esta asserção falha,
porque o aviso some no 2.º `atualizar()`: `a_mover` já é falso. É também o que mostra a mutação SEM-B1 (§3).

## 6. Suites (`provas/ordem-d-aud-01-correccoes-5/`, mapa no README)

Correram com Godot 4.7.2 `--headless` e Node, sobre `fa82f20`:

| Suite | Resultado | Na CORRECCOES-4 |
|---|---|---|
| mutação do refresco (SEM-REFRESCO) | **exit 1, 335 de 336**: só a nova falha | — |
| mutação do B1 (SEM-B1), código final | exit 1, 333 de 336: as 2 da CORRECCOES-4 e a do B2 | 332/334 |
| mutação do B1 sobre a E1 (`3b6bf7b`) | **exit 1, 332 de 334**: só as 2 da CORRECCOES-4 | 332/334 |
| `pecas_mestre` sobre a E1 (`3b6bf7b`) | **334 de 334** | 334 |
| servidor | **446/446**, exit 0 | 446/446 (LF) |
| motor real | **6/6**, exit 0 | 6/6 (LF) |
| prova da caixa | PROVA OK | PROVA OK |
| `abrir_scripts` | 113 scripts, 0 falhas | 113 |
| `rodar_testes` | 333 de 333 | 333 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | **336 de 336** | 334 |
| `medir_mestre` | 0 falhas, 0 sem medida | 0, 0 |
| `hud_acoes` | 70 de 70 | 70 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| canário de privacidade | 10 de 10 | 10 |
| `validar-mensagens.py` | `pecas_mestre` 30, 0 falhas; `abrir_mestre` 9, 0 falhas | 29 / 9 |

Todas as suites deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`. O clone está em LF, por isso o
servidor e o motor real passaram directamente.

Há três pormenores, descritos no README das provas:

- a primeira corrida do `e1.sh` deu `Parse Error` antes do `--import` (era um clone novo);
- o `PYTHON` é um venv com `jsonschema`, fora do repo;
- o motor real vem da pasta privada da D-AUD-06 e não foi copiado.

## 7. Commits (todos empurrados; não há nenhum commit só local)

| Commit | O quê |
|---|---|
| `3b6bf7b` | E1: o teste (b), com o texto exacto da ordem |
| `bbbbda5` | E1: provas (`e1.sh`, `e1/`), 334/334 e 332/334 |
| `97900c7` | E1: o caminho `C:/…` também passa a `<sede>` nos logs |
| `ab3c66c` | listas da retoma sincronizadas depois do `3b6bf7b` |
| `39bb0fb` | passos 1, 2 e 5: `aba_agir.gd` e `pecas_mestre.gd` |
| `4ca3d8f` | listas da retoma sincronizadas depois do `39bb0fb` |
| `fa82f20` | passo 3: o `suites.sh` com as duas mutações |
| `0a53953` | README das provas, logs e este ESTADO-FINAL |
| (este) | a nota do CI |

O `actualizar-listas.py` correu com o `python` 3.12, porque neste PC o `python3` é o atalho da Microsoft Store. Nas
duas passagens deu 0 novos e 0 tirados, e só mudaram os SHA no `depois.txt` e no `MANIFESTO-SHA256.txt`. Os commits
de provas e do ESTADO-FINAL não mexem em `rascunhos/`.

**CI pelo caminho.** O job `retoma-pc` dá `failure` em `97900c7` (run `45819107762`): o ensaio diz «o clone não
bate com depois.txt». Isto vem da lei de guardar a cada passo. O `3b6bf7b`, o `bbbbda5` e o `97900c7` mudaram
`rascunhos/` antes da sincronização das listas, que só entrou no `ab3c66c`. O `ab3c66c` dá Testes **success**
(run `45819156967`).

## 8. Perímetro e privacidade

- Só mudou o cliente do Mestre (`aba_agir.gd`) e o teste dele (`pecas_mestre.gd`), mais as provas.
- Não toquei na C-6, no «na vez» (D-AUD-03), na posição da caixa (ponto 5), na regra da largura, no servidor, nos
  dados, no cliente da jogadora nem na `main`.
- Nomes: só os fictícios das fichas de teste. Nos logs, o caminho da máquina passou a `<sede>`.

## Secção C — para o Mestre (sem decisão)

Ficam com o Mestre, sem decisão: a **terceira semântica** e a **preclusão da opção (b) do Plano 2**. Esta ordem não
as decide nem lhes toca. As decisões desta ordem são só do «Mover» armado: refrescar com `mover` diferente, e o aviso
persistente do B2, que foi decidido pelo coordenador.

## Nota do CI

- **`0a53953`** (todo o trabalho, as provas e o ESTADO-FINAL):
  - **Testes dos rascunhos `45820067479`: success.** Os 10 jobs deram verde: servidor, validador-glb, motor-real,
    protocolo, cliente, godot-cliente, foto-mestre, provas-mapa, ponta-a-ponta e retoma-pc. No log do CI o
    `pecas_mestre` dá 336 de 336, e as duas verificações da CORRECCOES-5 estão «ok».
  - **Sonda de privacidade `45820067531`: success.**
- **`fa82f20`** (código final e guião): Testes `45819546192` success, Sonda `45819546270` success.
- **`4ca3d8f`** e **`ab3c66c`**: Testes, Sonda e Aparelhos (F2), todos success.
- **`97900c7`**: o `retoma-pc` falhou nos Testes (run `45819107762`) porque as listas ainda não estavam
  sincronizadas. Está explicado no §7.

O workflow «Aparelhos (F2)» de `0a53953` (run `45820067614`) ainda estava a correr quando escrevi esta nota. Fica
fora do critério desta ordem, que é Testes + Sonda.
