# ESTADO-FINAL — Ordem F97 (adenda da decisão F71+F87+F89 à ordem F88–F96)

**Coordenador:** CM-000009 (Muse). **Executor:** Claude (opus, esforço médio), PC do cunhado. **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.

**Partida.** O clone do PC estava em `3f3cfc7`, 3 commits atrás da origem, com uma modificação por cometer em
`provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd`: as 4 descrições do item 1.1 desta ordem, já postas
(de uma tentativa anterior desta ordem neste PC; o `corrida.log` estava vazio). Conferi-a linha a linha contra o
item 1.1 e batia. Pus-a de lado (`git stash`), avancei para a ponta da origem e voltei a pô-la. Os 3 commits que
entraram (`70e994b`, `16a960a`, `8925790`) são erratas de outras ordens e não tocam em nenhum ficheiro desta.
**`HEAD` de partida: `8925790`** (`8925790a4cf54cc2941e21ffb66b9e4ae9ebca12`, a nota do CI da F78+F79+F81+F82).

**Commits:**
1. `879bac2`: a obra (o teste, o registo regenerado, a ferramenta, o README da caixa-relato e o remendo do CI);
2. este ESTADO-FINAL, com um retoque só de texto nos comentários da ferramenta e no README (ver §6);
3. a nota do CI da ponta do commit 2, acrescentada ao §5 (só documento).

**O workflow não mudou na linha: o passo da guarda vai em remendo** (ponto aberto 1). O `push` com o
`.github/workflows/testes.yml` mudado foi recusado: «refusing to allow an OAuth App to create or update workflow
`.github/workflows/testes.yml` without `workflow` scope». Refiz o commit, que ainda não estava publicado, sem o
workflow e com o remendo em `provas/ordem-f97-rede-redaccao/remendo-ci-testes.yml.patch`, como na F51 (aplicado
depois em `74f5fa9`, F65). O remendo aplica-se limpo na ponta (`git apply --check`).

**Biblioteca (GameDev Kit):** não construí nada de raiz. A obra estende o `redigir-nomes.mjs` e o teste do canário,
que já existiam, e segue o padrão deles. A F51 e a F88–F96 já tinham registado que a biblioteca não tem nada para
redigir registos de texto.

Este ficheiro não tem nenhum nome verdadeiro inteiro nem nenhum valor de PIN (§7). Nesta ordem não correu nenhuma
partida com PIN.

## 1. Os itens, um a um, e a linha nova

### Ponto 1 — F71: fechar a impressão dos nomes no CI

| item | o que estava | a linha nova |
|---|---|---|
| **1.1** descrições do teste (`teste_nomes_relato.gd:73, 98, 100, 112`) | os nomes literais nas 4 descrições, e o caso 1 imprimia o array | «1: «nome n.º 1» e «nome n.º 2» são canários (%d)» com `canarios.size()`; nos casos 3 e 4, «nome n.º 1» / «nome n.º 2». **As comparações não mudaram** (continuam com os valores literais), e o diagnóstico continua a dizer só contagens e linhas. (Na ponta, as linhas dos casos 3 e 4 são a 98, a 100 e a 112; o texto da 112 é a descrição do caso 4, que começa na 111.) |
| **1.2** registo limpo `cobertura-correcoes-6/teste-nomes-relato.log` | 3500 bytes, 3464 sem os CR, sha256 `fc57ce8a1c78…` | **regenerado** pela mesma via (canário Godot 4.7.2 Windows + `redigir-nomes.mjs --saida`): **3473 bytes, 3437 sem os CR**, sha256 `03c8928b1bb2…`, 36 linhas, CRLF. **Só uma linha muda: a 6.ª do ficheiro** (a ordem diz «linha 7»; contei a 6.ª, a 1.ª é a do Godot), a do caso 1: o array redigido passou a «(2)». As outras 3 descrições redigem-se para o mesmo texto que antes |
| **1.3** guarda no CI | — | o passo «Guarda: 0 nomes inteiros no log cru do canário (F71)», `if: always()`, `working-directory: ${{ github.workspace }}`, com o comando exacto da ordem, entre o passo do canário (e o `setup-node`) e o passo da redacção. **Vai em remendo** (ponto aberto 1). O `tee` fica; o passo só lê o ficheiro |
| **1.4** RELATO_VELHO e logs passados | — | **ficam.** O RELATO_VELHO continua com os valores literais: 28 ocorrências, 22 achados. Não apaguei nenhum run |

**A guarda tem dentes** (o comando exacto, no PC, com `RUNNER_TEMP` a apontar para uma pasta em `tmp/`):
- com o log cru novo do canário: «guarda-nomes: 0 nome(s) inteiro(s) no log cru do canario», rc=0;
- com o log cru de antes desta ordem: «guarda-nomes: 7 …», **rc=1**.

### Ponto 2 — F87: o nome sem a preposição entra; só o apelido fica fora

| item | o que estava | a linha nova |
|---|---|---|
| **2.1** 5.ª forma na redacção (`redigirLinha`) | o nome sem a preposição escapava (0/0/0) | a forma exacta de um só espaço «1.ª parte + última parte», com fronteira de palavra dos dois lados (`(?<!\p{L})…(?!\p{L})`, como os detectores da F66), passa a **«nome n.º N sem a preposição»**, com contador próprio na linha de contagens («N sem a preposição»). Uma forma por preposição no meio do nome (`partesSemPreposicao`). A forma 1 não mudou |
| **2.2** padrão na rede (`suspeitos`) | — | `reSemPreposicao`: «1.ª parte `\s+` última parte», com fronteira de palavra, conta como resto (contador novo «N nome(s) sem a preposição», com as linhas) e dá saída 3. Apanha os dois espaços, o tabulador e a quebra de linha (conta na linha onde começa). A forma de um espaço **não** se exclui, para um falhanço da redacção sair ainda com 3. Um corte que começa dentro de uma destas ocorrências não conta outra vez (como na F93) |
| **2.3** auto-teste, +2 casos | — | a 22.ª: o nome n.º 1 sem a preposição a meio da linha → «nome n.º 1 sem a preposição», e a rede calada; colado a uma letra (antes ou depois) não se redige. A 23.ª: o nome n.º 2 sem a preposição no fim da linha (com LF antes e CRLF depois) → «nome n.º 2 sem a preposição», e a rede calada |
| — o caso «F95 AINDA ABERTO» do nome sem a preposição | passava enquanto o buraco estava aberto | **virou**, como a F95 manda a quem fechar o buraco (a 21.ª, «F95 FECHADO (F97, F87)»). Com a obra posta e o caso por virar, o auto-teste deu 21 de 22: falhou exactamente esse caso. Virado, afirma a rede: dois espaços, um tabulador, a quebra de linha, e a forma de um espaço crua (a redacção falhada) → 1 sem a preposição, na linha onde começa → saída 3 |
| **2.4** README, «Limite» | o «Limite (F88)» com o texto velho do «parcial» | **«Limite (F97).»** com o texto exacto da ordem, sem mudar uma letra. O item 1 da F88–F96 (documentar o «parcial») fica substituído. O parágrafo dos casos «AINDA ABERTO» diz agora o que fica aberto: o pedaço a meio do nome e as duas palavras da F89 |

**As medições da decisão, refeitas** (com um guião em `tmp/`, fora do repo, que só imprime contagens):

| medida | relato antigo (cru) | relato antigo redigido | registo limpo |
|---|---|---|---|
| 5.ª forma exacta | 0 | 0 | 0 |
| padrão `\s+` | 0 | 0 | 0 |
| apelido, sem distinguir maiúsculas | **75** | **47** | **6** |

E o «parcial» da F88 nunca disparava: mínimo do corte 6 e 5, 1.ªs partes 5 e 4. Batem com a decisão.

### Ponto 3 — F89: só a palavra hifenizada

| item | o que estava | a linha nova |
|---|---|---|
| **3.1** `reVariantesFora` | o meio era `[\p{L}'’]+` | **`[\p{L}'’]+(?:-[\p{L}'’]+)*`**. Nada mais mudou na ideia da variante |
| **3.2** não alargar | — | duas ou três palavras e dígitos continuam fora |
| **3.3** auto-teste, +2 casos | — | a 24.ª: «X du-la Y» não se redige e a rede dá 1 variante → saída 3. A 25.ª, **«F89 AINDA ABERTO»**: «X du la Y» dá 0 em tudo (rede calada), para um fecho futuro ter prova |
| **3.4** README | — | a restrição com a frase exacta **«uma palavra de letras, com ou sem hífenes»**, e porque ficam fora mais de uma palavra (são palavras inseridas) e os dígitos (um número não é uma palavra; não há caso realista) |
| **3.5** fronteira com a F94 | — | escrita no README, não fechada aqui: a substituta colada ao apelido e a substituta seguida de pontuação continuam com a F94 |

### Os casos têm dentes

Fiz 6 cópias mutadas da ferramenta em `tmp/`, uma só regra desfeita por cópia. Todas fazem o auto-teste falhar (rc=1):

| mutação | falha |
|---|---|
| sem a 5.ª forma | a 22.ª e a 23.ª (24 de 26) |
| sem a fronteira de palavra na 5.ª forma | a 22.ª |
| sem o padrão da rede | a 21.ª |
| a rede só com um espaço (sem `\s+`) | a 21.ª |
| sem o hífen da F89 | a 24.ª |
| a F89 alargada a duas palavras | a 25.ª |

**As dependências das fichas (F96), com fichas fictícias em `tmp/`:** com a mesma forma das verdadeiras, 26 de 26.
Com o nome n.º 2 sem preposição falham a 5.ª, a 15.ª e a 23.ª. Com o nome n.º 1 sem preposição falham a 13.ª, a 15.ª
e da 18.ª à 26.ª, menos a 23.ª. Ficou escrito no README e no código: a 21.ª, a 22.ª, a 24.ª e a 25.ª dependem do nome
n.º 1; a 23.ª, do nome n.º 2.

## 2. Os números, antes e depois

| medida | antes (`8925790`) | depois |
|---|---|---|
| nomes inteiros no log do job `cliente` (sem distinguir maiúsculas) | **7** (linhas 2012 ×4, 2023, 2024, 2027; run 45152082652) | **0 + 0** (run 45167352019) |
| nomes inteiros no log cru do canário (PC) | 7 | **0** |
| auto-teste do `redigir-nomes` | 22/22 | **26/26** |
| canário `teste_nomes_relato.gd` | 26/26 | **26/26** |
| registo limpo da COBERTURA-CORRECOES-6 | 3500 bytes, **3464** sem os CR | **3473** bytes, **3437** sem os CR (o byte novo) |
| comparação byte a byte no PC (CRLF) / no CI (sem os CR) | igual (3500) / igual (3464) | **igual (3473) / igual (3437)** |
| rede nos 11 registos limpos (inteiros / variantes / cortes / sem a preposição) | 0/0/0 | **0/0/0/0** |
| nomes inteiros no ficheiro de teste (por desenho, os valores-canário) | 45 (19 + 26) | **40 (17 + 23)**: saíram os 5 das descrições |
| conferidor nos ficheiros da obra (alargado / antigo) | `redigir-nomes.mjs` 2/2, README 34/30 | **2/2, 34/30** (os mesmos) |

**A conta do auto-teste.** A ordem diz «16 + 2 + 2 = 20/20». Mas a base já era 22/22, porque a F88–F96 tinha juntado
6 casos. Fica **22 + 2 (F87) + 2 (F89) = 26/26**. O caso do nome sem a preposição da F95 não é um caso a mais: virou.
Não é uma decisão nova, é só a conta feita sobre a base verdadeira (ponto aberto 3).

## 3. A reprodução da F51 (os 11 registos)

`bash provas/ordem-f51-mutacao/reproduzir-redaccao-f25.sh <tmp>` com a ferramenta nova, na base `8925790` + a obra:

- **10 de 11 iguais byte a byte à ponta.** O que difere é o registo regenerado da COBERTURA-CORRECOES-6, na linha 6
  (3500 contra 3473 bytes). É a consequência directa do item 1.2: o guião redige o registo **anterior** à limpeza da
  F25 (do pai de `081304e`), que traz a descrição velha do caso 1. Não há outro modo de as duas coisas baterem.
- **Contra o registo como estava antes da regeneração** (`git show 8925790:…`), o 11.º sai **igual byte a byte**
  (3500 bytes). Portanto a ferramenta nova reproduz a redacção do §2 da F25 nos 11, sem mudar um byte.
- Nos 11, a linha de contagens dá «0 sem a preposição» e a rede 0/0/0/0.
- **Não mudei o guião nem o `reproducao-f25.log` cometido.** Escolher o alvo da comparação é uma decisão que a ordem
  não toma (ponto aberto 2).

## 4. As suites

- **No PC** (Godot 4.7.2 Windows): canário 26/26, rc=0, sem `SCRIPT ERROR`/`Parse Error`; auto-teste 26/26; a
  comparação igual nas duas formas.
- **No CI**: o §5.
- Não corri o guião da mutação da F51 (`correr-mutacao-canario.sh`): não está na ordem e reescreve artefactos
  cometidos. O `teste-nomes-relato.mutacao.log` cometido ainda traz a linha do caso 1 no texto antigo, já redigido;
  a próxima corrida desse guião muda essa linha (ponto aberto 4). Nenhuma comparação o usa.

## 5. O CI

**Ponta `879bac2` (a obra)**: Testes **45167352019** + Sonda **45167352295**, **10/10 jobs verdes** (`servidor`,
`validador-glb`, `motor-real`, `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`,
`foto-mestre`, `retoma-pc`) **e a Sonda verde**. Li o log do job `cliente` (job 137667630787, 2175 linhas):
- canário: «teste dos nomes do relato da caixa-janela: 26 de 26 verificações passaram.»;
- o passo da F51 a correr: «auto-teste do redigir-nomes: 26 de 26 verificações passaram.»; «36 linhas, 0 redigidas —
  0 nome(s) inteiro(s), … 0 sem a preposição …; sobram 0 nome(s) inteiro(s), 0 variante(s) …, 0 corte(s) …,
  0 nome(s) sem a preposição»; e o registo da COBERTURA-CORRECOES-6 «igual byte a byte ao redigido (**3437 bytes**,
  sem os CR)»;
- **0 nomes inteiros no log inteiro do job** (contagem refeita no log descarregado para `tmp/`, sem distinguir
  maiúsculas: 0 + 0). No run da ponta de partida a mesma contagem deu 7, nas linhas da ordem.

**O passo da guarda não correu**: está no remendo, por aplicar (ponto aberto 1).

## 6. O retoque do commit 2

Depois do `push` da obra, o conferidor (critério alargado) deu mais achados nos dois ficheiros: `redigir-nomes.mjs`
2 → 8, README 34 → 40. Não eram nomes: eram palavras correntes que contêm pedaços do apelido (a palavra que a
decisão chama «palavra corrente»), em frases que eu tinha escrito. Reescrevi essas frases sem mudar o sentido. Os
números voltaram aos da ponta de partida: 2/2 e 34/30. O código não mudou: o auto-teste continua 26/26. O remendo
fica com 2 achados (alargado e antigo): são o caminho das fichas, que vem no comando exacto da ordem e já está no
workflow.

## 7. A privacidade, re-derivada (âmbito corrigido)

**0 nomes inteiros nos registos limpos e nas saídas do relato.** Contado com o `sobram()` da ferramenta, sem
distinguir maiúsculas:
- os 11 registos limpos (os da `081304e`, com o regenerado): **0**;
- as saídas da redacção cometidas (`reproducao-f25.log`, `resumo.txt`, `teste-nomes-relato.mutacao.log`): **0**;
- os ficheiros desta obra (a ferramenta, os dois README, o remendo) e este ESTADO-FINAL: **0**;
- o log do job `cliente` da corrida nova: **0**.

Por desenho: o ficheiro de teste traz **40** (eram 45; são os valores-canário das comparações e o RELATO_VELHO, com
28) e as fichas trazem **2**. O registo limpo traz **0**.

Fora deste âmbito, e sem mudança nesta ordem: os relatos do jogo antigos (os `relato.txt` de ordens anteriores e os
`.jsonl` da ordem do autojogo) trazem nomes inteiros. São a saída do jogo, que a decisão da CORRECOES-7 já tinha
deixado fora do critério. Não lhes toquei.

**SHAs e listas da retoma.** Mudaram o registo da COBERTURA-CORRECOES-6 (sha256 `fc57ce8a1c78…` → `03c8928b1bb2…`),
o teste, a ferramenta e o README. Procurei os SHA antigos (sha256 e blob) no repo. Só o sha256 antigo do registo
aparece, no `ESTADO-FINAL-ORDEM-F25-LIMPEZA-11-FICHEIROS.md`: é o registo histórico da F25 e fica como está. Nenhuma
lista da retoma (`RETOMA-*`, `retoma-pc`) cita estes ficheiros, por isso não houve nada a sincronizar.

## 8. Pontos abertos

1. **O remendo do CI está por aplicar.** O token do PC não tem o âmbito `workflow`. O passo da guarda está em
   `provas/ordem-f97-rede-redaccao/remendo-ci-testes.yml.patch` (com um README ao lado), aplica-se limpo, e o comando
   foi ensaiado no PC: 0 → rc=0, 7 → rc=1. **A aceitação «passo da guarda verde» fica pendente** até o coordenador o
   aplicar (`git apply …`) e o CI da ponta nova correr. O resto da aceitação está cumprido (§5).
2. **Reprodução da F51: 10/11 contra a ponta** (§3). Regenerar o registo é obrigatório pela ordem, e com isso o
   guião, que compara o registo anterior à limpeza com o da ponta, não pode dar 11/11. Contra o registo anterior à
   regeneração dá 11/11. Fica por decidir: o guião passa a comparar com `081304e:<registo>` (o limpo da F25), ou o
   registo da COBERTURA-CORRECOES-6 passa a ter a excepção escrita. Não mudei o guião nem o log cometido.
3. **A conta do auto-teste**: a ordem diz 20/20 (16 + 2 + 2). Com a base verdadeira, 22, fica 26/26 (§2). Peço que a
   aceitação se leia como 26/26.
4. **O log da mutação da F51** (`provas/ordem-f51-mutacao/teste-nomes-relato.mutacao.log`) não foi regenerado. A
   linha do caso 1 tem o texto antigo, redigido, e a próxima corrida do guião muda-a. Não há comparação que o use.
5. **A linha do registo**: a ordem fala da linha 7; a que muda é a 6.ª do ficheiro (§1, item 1.2).
