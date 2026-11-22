# ESTADO-FINAL — Ordem CAIXA-RELATO-B7-CORRECOES-6

As correcções B1–B5 da sentença da CAIXA-RELATO-B7-CORRECOES-5, que deu **NÃO FUNDE — 450**. Feitas no PC, na
conta 1 do Claude, a 22/11/2026.

- **Ramo:** `claude1/caixa-relato-b7-correcoes-6`, publicado e **não fundido**.
- **Base:** o ramo `claude1/caixa-relato-b7-correcoes-5`, rebasado sobre a ponta da `fable/integracao-50` no lançamento
  (`1b907bc`).
- **O rebase:** houve um conflito só no `provas/ordem-caixa-relato/README.md`, porque a CAIXA-RELATO-CORRECOES-6 e a
  B7-CORRECOES-5 acrescentaram ambas uma secção no fim. Ficaram as duas, pela ordem em que entraram.
- **Os commits da -5 depois do rebase:** `c9a0ce6` (listas) e `276c579` (ESTADO-FINAL).
- **Os commits desta ordem:** `930faec` (as correcções e as provas) e `5282c99` (as listas da retoma), mais o deste
  ficheiro.

**Privacidade:** nenhum ficheiro do ramo tem o valor do PIN novo de 20 dígitos nem o do PIN antigo, e este também não.

## O resultado, em três linhas

- **No repositório já não há PIN.** O cenário de bancada perdeu a chave `"pin"` e as 4 provas `.gd` perderam o literal.
- **Cada corrida gera o seu PIN** e passa-o por `--pin=`. Nunca se escreve.
- **Nenhum lançador volta a pôr o PIN no ramo:** nenhum faz `cat` do info em bruto nem copia o info ou o log. Além disso,
  o servidor já não escreve o PIN no info nem na linha `pronto-…`.

## B1 (D1, GRAVE) — tirar a senha do repositório

**Feito.**

| Ficheiro | Antes | Agora |
|---|---|---|
| `rascunhos/servidor/autojogo/cenario-bancada.json` | `"pin": "<PIN novo>"` (linha 7) | sem a chave `"pin"`; a `nota` explica de onde vem o PIN |
| `provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd` | literal na linha 33 | `var _pin := ""` |
| `provas/ordem-caixa-janela/ferramentas/prova_caixa_janela.gd` | literal na linha 55 | `var _pin := ""` |
| `provas/ordem-caixa-manequim/ferramentas/prova_caixa_manequim.gd` | literal na linha 38 | `var _pin := ""` |
| `provas/ordem-caixa/ferramentas/prova_caixa_reentrar.gd` | literal nas linhas 30 e 8 (no comentário de uso) | `var _pin := ""`; o uso diz `--pin=<PIN da corrida>` |

- **Um PIN fresco por corrida.** Os 6 lançadores que arrancam o servidor de prova geram-no com
  `crypto.randomInt(10)` × 20, o que dá 20 dígitos. Fica numa variável da shell e passa por `--pin=` ao servidor e à
  prova. São eles: os 3 externos (HUD, JANELA, MANEQUIM), o `correr-prova-caixa.sh`, o `correr-prova-caixa-relato.sh` e
  o `correr-mutacoes.sh`.
- **O servidor aceita o PIN fora do cenário.** Os dois `servidor-bancada-prova.mjs` lêem `--pin=`. Sem ele, ou com um
  valor fora de `/^\d{6,}$/`, saem com **2**, e isto acontece antes de lerem o cenário.
- **As 4 provas `.gd` também recusam.** Sem `--pin=`, ou com um valor que não seja só de dígitos e com pelo menos 6,
  saem com **2**.
- **O autojogo**, fora do território literal (ver os pontos para o coordenador):
  - lia o PIN do mesmo cenário (`servidor-autojogo.mjs:117` e `autojogo.gd:233`);
  - agora o `autojogo.gd` gera um PIN por partida com `Crypto.generate_random_bytes`, um dígito por byte, e passa-o por
    `--pin=`;
  - o `servidor-autojogo.mjs` exige o `--pin=`;
  - o dado semeado não muda, porque é outro rng.

**Prova:** `b7-correcoes-6/verificacao-pin.log`, gerado por `ferramentas/verificar-pin-b7-correcoes-6.sh`. O script tira
os dois valores dos objectos do git: o antigo de `1b907bc` e o novo de `e8f1a42`, a ponta remota da -5. Só imprime
contagens. Correu na árvore de trabalho já com as correcções, por cima de `276c579`, e saiu com **0 falhas**.

| Verificação | Resultado |
|---|---|
| **PIN novo de 20 dígitos — ocorrências na árvore de trabalho** (seguidos ou não, fora de `.git`) | **0** (0 ficheiros) |
| PIN novo de 20 dígitos — ficheiros seguidos (`git grep`) | **0** |
| **PIN antigo — em ficheiros novos ou mudados desde a base** (72 ficheiros) | **0** |
| PIN antigo — ocorrências na árvore de trabalho | **0** |
| chave `"pin"` no cenário de bancada | não há |
| os dois `servidor-bancada-prova.mjs` sem `--pin`, e com um `--pin` que não é só dígitos | código **2** (4 de 4) |
| `servidor-autojogo.mjs` sem `--pin` | recusa |
| as 4 provas `.gd` sem `--pin` (Godot 4.7.2) | código **2** (4 de 4) |
| **arranque vivo com o cenário novo e um PIN fresco** | info `pronto: true`; linha `pronto-prova-caixa-hud` presente |
| o mesmo arranque: chave `"pin"` no info | **0** |
| o mesmo arranque: o PIN da corrida no info ou no log | **0** |

## B2 (D2, GRAVE) — o caminho de re-exposição

**Feito.**

- **Os 3 lançadores externos:**
  - `correr-prova-caixa-hud.sh`: o `cat` estava na linha `:14` e os `cp` nas `:19–20`;
  - `correr-prova-caixa-janela.sh`: `cat` na `:15`, `cp` nas `:20–21`;
  - `correr-prova-caixa-manequim.sh`: `cat` na `:15`, `cp` nas `:20–21`.

  Agora imprimem o info **sem a chave `"pin"`**, com um `node -e` que a apaga. Os dois `cp` (do info e do log para a
  pasta cometida) **saíram**. O info e o log ficam na pasta tmp.
- **O 4.º lançador,** `provas/ordem-caixa/ferramentas/correr-prova-caixa.sh:14`: o `cat` foi trocado pelo mesmo filtro.
- **A linha `pronto-…`:** a chave `pin` saiu dela e do info, nos dois `servidor-bancada-prova.mjs` (era o
  `servidor-bancada-prova.mjs:61`). O filtro dos lançadores fica como cinto.
- **O agravante medido confirmou-se nesta base.** A CAIXA-JANELA-COBERTURA-CORRECOES-5 (`120d7cf`) correu o lançador da
  janela e voltou a cometer `provas/ordem-caixa-janela/cobertura-correcoes-5/cliente/servidor-info.json` e
  `servidor.log`, ambos com o **PIN antigo**. Os dois saíram do ramo. Não há outros: dos `servidor.log` seguidos,
  sobram só os das `suites/`, que não têm PIN.

**Prova:** os 3 lançadores externos correram de verdade (`b7-correcoes-6/lancadores-externos.log`).

| Lançador | Código | Prova |
|---|---|---|
| `correr-prova-caixa-hud.sh` | 0 | **43/43** |
| `correr-prova-caixa-janela.sh` | 0 | **41/41** |
| `correr-prova-caixa-manequim.sh` | 0 | **53/53** |

Em todos: **0** chaves `"pin"` no stdout, no info e no log do servidor. Depois das corridas, **0** ficheiros novos nas
pastas cometidas. Os relatos e as capturas que o HUD e o MANEQUIM reescreveram nas pastas `cliente/` deles foram repostos
(`git checkout`), porque não são desta ordem. A verificação do B1 também conta **0** `cp` do info ou do log e **0** `cat`
do info nos 5 lançadores.

## B3 (D4, BAIXA) — o PIN antigo reimpresso

**Feito.**

- **`b7-correcoes-5/verificacao-pin.log:3`** passa a dizer `ficheiros com o PIN antigo: 0`, sem o valor.
- **`ESTADO-FINAL-ORDEM-CAIXA-RELATO-B7-CORRECOES-5.md:50`** passa a dizer `| com o PIN antigo¹ | **0** |`. A nota ¹
  explica a emenda e porque é que o «0» era falso: o próprio ficheiro e o log tinham o valor.
- **Prova:** na árvore, o PIN antigo dá **0** ocorrências (ver B1).

## B4 (O1/O2, cosméticas)

**Feito.**

- **O1:** o §B4 do ESTADO-FINAL da -5 dizia que os argumentos se validavam todos antes do `cd`. Agora diz o que o script
  faz:
  - o número de argumentos e o `<godot>` validam-se antes do `cd` (linhas 38–39);
  - a base valida-se logo a seguir ao `cd` (linha 44), porque o git precisa da raiz;
  - tudo acontece antes de se criar qualquer pasta (linha 59).
- **O2:** no `verificacao-pin.log`, o rótulo já não tem o valor. Saiu também o aviso «Este ficheiro não conta para si
  mesmo», que era o rótulo a contar-se a si próprio. Uma nota de emenda no fim do log regista a mudança.
- **O log novo** (`b7-correcoes-6/verificacao-pin.log`) foi escrito para não precisar destes cuidados: os rótulos não
  têm valores.

## B5 (D3) — a decisão registada

- **O histórico fica como está:** não houve reescrita nem force-push.
- **O PIN antigo está morto.**
- **O PIN novo de 20 dígitos é público e nunca se reutiliza.** Nenhum lançador o usa, porque cada corrida gera o seu.
- **Uma nota sobre o commit `930faec`:** o diff mostra, nas linhas apagadas, o valor que saiu dos 5 ficheiros. É o mesmo
  valor que já era público e não acrescenta exposição nova.

## As corridas (PC Windows, Godot 4.7.2 `win64_console`, motor VLAB real `a91c021c…3261`, semente 7)

- **O cenário** tem agora o sha256 `7037229e…`. Antes era `2cab6459…`.
- **As fichas** continuam `3c498137…`.

| Corrida | Resultado | Registo |
|---|---|---|
| Teste do relato (`teste_relato_caixa.gd`) | **31/31**, código 0 | `b7-correcoes-6/teste-relato.log` |
| Prova viva HUD-JOGADORA, com PIN fresco | **43/43**, código 0, 68 linhas | `b7-correcoes-6/cliente-hud/relato.txt` |
| Prova viva MANEQUIM, com PIN fresco | **53/53**, código 0, 78 linhas | `b7-correcoes-6/cliente-manequim/relato.txt` |
| O lançador da relato (as três de cima) | código 0; o info sem `pin` | `b7-correcoes-6/lancador.log` |
| Os 3 lançadores externos | 43/43 · 41/41 · 53/53, código 0 | `b7-correcoes-6/lancadores-externos.log` |
| Autojogo, semente 1, PIN por partida | código 0; vitória em 14 turnos; 109 linhas iguais às de `provas/ordem-autojogo/s1.jsonl`, menos a `inicio` (só muda o `cenarioSha256`) | `lancadores-externos.log` |
| Suite do servidor (`rascunhos/servidor/testes/*.test.mjs`) | **421/421** | — |
| `prova-servidor.mjs` da caixa | `PROVA OK` | — |
| Verificação do PIN (B1/B2) | **0 falhas** | `b7-correcoes-6/verificacao-pin.log` |

- **As provas vivas dão os mesmos números da -5:** 43/43 em 68 linhas e 53/53 em 78.
- **A suite tem mais 1 teste do que na -5** (421 contra 420). Esse teste veio na base.
- **O `actualizar-listas`** correu depois de `930faec` e as listas foram no `5282c99`:
  - dá `antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados)`;
  - mudaram 3 linhas, as mesmas no `MANIFESTO-SHA256.txt` e no `retoma-i0004/depois.txt`: as de `cenario-bancada.json`,
    `autojogo.gd` e `servidor-autojogo.mjs`;
  - os sha batem com os blobs cometidos;
  - o registo está em `b7-correcoes-6/actualizar-listas.log`;
  - voltei a corrê-lo antes do commit deste ficheiro e não mudou nada.

## CI

**Verde em `5282c99`**, a ponta com as correcções e as listas:

- **Testes dos rascunhos** (run 45027816549): **10/10 jobs**, a saber cliente, **retoma-pc**, servidor, provas-mapa,
  motor-real, protocolo, foto-mestre, godot-cliente, validador-glb e ponta-a-ponta.
- **Sonda de privacidade** (run 45027816581): success.
- **No registo do CI:**
  - teste do relato: `31 de 31`;
  - protocolo: 421 testes, 421 passaram;
  - servidor: 421 testes, 411 passaram, 10 saltados por desenho (os de disco e de `../protocolo`, que esse passo só de
    leitura não corre), 0 falharam;
  - `PROVA OK`;
  - ponta a ponta: `17 de 17`;
  - bancada da jogadora: `49 de 49`;
  - retoma-pc: o ensaio e a cópia a sério passaram, e o controlo «parou e não copiou».

## Pontos para o coordenador

1. **Saí do território literal em dois sítios, ambos à força do B1:**
   - **O autojogo:** `rascunhos/cliente/autojogo/autojogo.gd` e `rascunhos/servidor/autojogo/servidor-autojogo.mjs`. Lia
     o PIN do mesmo cenário; tirar o `pin` do cenário sem lhe mexer partia-o. A mudança é pequena (o PIN gerado e o `--pin=`) e
     a partida dá o mesmo registo.
   - **Os 2 ficheiros apagados** da pasta da CAIXA-JANELA-COBERTURA-CORRECOES-5, que traziam o PIN antigo.
2. **O `correr-prova-caixa.sh` não correu.** É o 4.º lançador, só de Linux, com caminhos fixos
   (`~/workspace/claude2-hud`, xvfb). Fica corrigido mas sem corrida.
   - **Defeito antigo:** a cópia `provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs` ainda usa `.pathname` e não
     abre o cenário no Windows. A recusa sem `--pin` vem antes da leitura, por isso foi testada no Windows (código 2).
     Não corrigi o caminho, porque não é desta ordem.
3. **As mutações** (`correr-mutacoes.sh`, a de servidor e provas vivas) não correram nesta ordem. Ficam com o PIN fresco
   e o `--pin=`. O modo antigo usa os `.gd` da base, e esses já lêem `--pin=` (conferido em `1b907bc`).
4. **No `autojogo.gd`, o PIN sai de `byte % 10`.** Isto tem um enviesamento pequeno: os dígitos 0–5 saem com 26/256 e
   os 6–9 com 25/256. Com 20 dígitos dá ~66 bits, e o servidor só ouve em 127.0.0.1. Os lançadores shell usam
   `crypto.randomInt`, que não tem enviesamento.
5. **Referências históricas:** os README e ESTADO-FINAL antigos ainda citam `servidor-info.json` e «o PIN no cenário».
   Ficam como registo, tal como na -5.
6. **A linha final do ficheiro da ordem** (`Estado: NOVA`) é do ficheiro da ordem, que fica fora do ramo. Não lhe mexi.
