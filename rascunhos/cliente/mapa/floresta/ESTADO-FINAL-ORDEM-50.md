# Ordem 50: integração das Ordens 48 e 49 numa linha só (construção e ligação; nada visual). ESTADO FINAL

*Fecho da ordem, 2026-11-15, Opus 5.5, uma só sessão. PCDANASA, Godot 4.7.2 (Compatibility), Node 26 local.
Trabalhei no clone `C:\Users\txcga\fable-mapa\repo`. O ramo é `fable/integracao-50`, tirado de `8cd941d` (a base comum
das duas ordens, ponta da Ordem 45). As três partes estão feitas, commitadas e empurradas. Tudo o que aparece
como «provado» abaixo corri-o eu nesta máquina, na árvore fundida. Os registos estão em
`C:\Users\txcga\fable-mapa\_tmp\o50\`, fora do repositório. Não toquei em `main`, nos ramos das duas ordens nem
em `.github`.*

## O que mudou (commits)

| commit | o quê |
|---|---|
| `c33014c` | **Parte A, fusão 1/2.** Funde `fable/servidor-grelhas-48` (Ordem 48, ponta `69ed8a2`). Não houve conflitos. |
| `d0c9085` | **Parte A, fusão 2/2.** Funde `fable/servidor-correcoes-49` (Ordem 49, ponta `491c3fa`). Houve 2 conflitos, ambos em listas geradas. Estão resolvidos e nomeados no corpo do commit e abaixo. |
| *(este)* | **Parte C.** Este ESTADO FINAL. |
| *(o seguinte)* | Listas da retoma e MANIFESTO refeitos (este documento está dentro de `rascunhos/`). |

A Parte B não precisou de nenhum commit: não apareceu nenhum defeito da fusão para consertar (ver abaixo).

## Parte A: as fusões, uma de cada vez

### Fusão 1/2: Ordem 48 (`c33014c`)

A branch nasceu em `8cd941d`, que é a base da Ordem 48. Por isso a fusão não teve conflitos. Usei `--no-ff`,
com um commit de fusão nomeado, para a linha ficar legível. Entram os 21 ficheiros da ordem: `terreno.js`,
`sala.js`, `servidor-ws.js`, o pacote `terreno-floresta.json` (`terreno/2`), `conferir-terreno.mjs`, o
`exportar_terreno.gd` e a sonda, `grelha_floresta.gd`, `rodar_testes.gd`, os testes `ordem44`/`ordem48`, as provas
em `provas/ordem-48-terreno/` e o ESTADO dela.

### Fusão 2/2: Ordem 49 (`d0c9085`)

**O código das duas ordens não se cruza.** Nenhum ficheiro de código, teste ou dado é tocado pelos dois lados:
fora as duas listas, a 48 mexe em 19 ficheiros e a 49 em 9, sem nenhum em comum. Esses fundiram-se sozinhos.
Houve dois conflitos, os dois em listas **geradas** pelo `retoma-i0004/actualizar-listas.py`:

| ficheiro | o que o lado 48 trazia | o que o lado 49 trazia | como ficou |
|---|---|---|---|
| `MANIFESTO-SHA256.txt` | Os SHA novos dos seus ficheiros (`provar_mestre_no_relevo.gd`, `rodar_testes.gd`, `servidor-ws.js`, `dados/README.md`, `terreno-floresta.json`, `conferir-terreno.mjs`, `juizo-terreno.mjs`, `ESTADO-FINAL-ORDEM-48.md`) e, nas linhas da 49, os SHA da base. | Os SHA novos dos seus (`mestre.gd`, `textos_mestre.gd`, `abrir_mestre.gd`, `hud_acoes.gd`, `arena.gd`, `conferir-schemas.py`, `jogadora-e2e.mjs`, `servidor-e2e.mjs`, `ESTADO-FINAL-ORDEM-49.md`) e, nas linhas da 48, os SHA da base. | **Nenhum lado servia à árvore fundida**, porque cada um traz os SHA velhos dos ficheiros do outro. Escolher um lado deixaria hashes errados. Refi-lo com o próprio gerador sobre a árvore fundida: ficam todas as linhas dos dois lados, cada uma com o SHA dos bytes fundidos, e entra a linha do ESTADO da 49. São **329 ficheiros**. |
| `retoma-i0004/depois.txt` | 279 ficheiros | 275 ficheiros | Refeito da mesma maneira: **280** (os 279 da 48 mais o ESTADO da 49), com os SHA da árvore fundida. `antes.txt` não muda (32), porque nenhuma das duas ordens mexe num ficheiro que já existisse no `9cbaca8` e ainda não estivesse na lista. |

**Como fiz a resolução, sem escolher um lado.** O gerador lê o `HEAD`, e durante a fusão o `HEAD` ainda é o
lado 48. Por isso:

1. pus as duas listas provisoriamente no texto do lado 48;
2. fiz um commit **solto** (`git commit-tree`, fora de qualquer ramo) com a árvore fundida;
3. corri uma cópia do gerador, em `_tmp`, que lê esse commit em vez do `HEAD`;
4. o resultado entrou no commit de fusão.

**Provas da resolução:**

- O `actualizar-listas.py` verdadeiro, corrido sobre `d0c9085`, **não muda nenhum byte** (0 novos, 0 tirados).
- Em relação ao lado 48, as únicas linhas que mudam nas listas são as dos 9 ficheiros da Ordem 49.
- O job `retoma-pc` do CI confere as listas contra o clone, e está verde nesse commit.

**O trabalho de cada ordem ficou inteiro.** Para cada ficheiro que cada ordem mudou em relação a `8cd941d`,
comparei o blob da fusão com o blob da ponta da ordem:

- Ordem 48: 21 ficheiros, 19 iguais;
- Ordem 49: 11 ficheiros, 9 iguais;
- os únicos diferentes, nos dois casos, são `MANIFESTO-SHA256.txt` e `depois.txt`, as duas listas refeitas.

Não houve nenhum conflito com duas lógicas incompatíveis. Não parei nenhuma parte.

## Parte B: a prova da união (árvore fundida, ponta `d0c9085`)

### Servidor

| corrida | resultado |
|---|---|
| Como o job `servidor`: `--permission --allow-fs-read=…` e também `--allow-net` (ver resíduo 1) | 355 testes: **345 passam, 0 falham**, 10 saltados. É o número da Ordem 48. |
| Como o job `protocolo`: sem `--permission`, com `PROTOCOLO_DUMP` | **355/355**. São os 348 da Ordem 49 mais os 7 líquidos da 48. |
| `conferir-schemas.py` (o novo da 49, com o TRAFEGO-VAZIO) sobre esse tráfego (16 868 mensagens) | exit 0 |
| `validador-glb` | 31 passam, 0 falham (33 testes) |
| `node servidor/ferramentas/conferir-terreno.mjs` (da 48) | **TERRENO EM DIA**: as 6 fontes em dia e o pacote, refeito pelo cliente, igual byte a byte |

### Cliente, sem janela (Godot 4.7.2), depois do `--import`

| suite | resultado |
|---|---|
| `abrir_scripts` | 68 scripts, 0 falhas |
| `rodar_testes` | **177/177**, o número da 48 (a 49 não lhe mexeu) |
| `abrir_clareira` | 22/22 |
| `medir_painel_config` | 0 falhas, 0 sem medida |
| `abrir_mestre` | **66/66** (57 + 9 da Ordem 49 A). Os comandos validam contra os schemas: 9 mensagens, 0 falhas |
| `pecas_mestre` | 236/236. Os comandos validam contra os schemas: 26 mensagens, 0 falhas |
| `medir_mestre` | 0 falhas, 0 sem medida |
| `hud_acoes` | **42/42** (32 + 10 da Ordem 49 C) |
| `canario_privacidade` | 10/10 |
| `clima_forte` | 119/119 |
| arranque `--quit-after 600` | «pronto», 0 erros |
| `provar_terreno_servidor` | TUDO PASSOU (12 grelhas) |
| `provar_mestre_no_relevo`, `provar_assentamento` | TUDO PASSOU |

Nenhuma suite teve SCRIPT ERROR, Parse Error ou Compile Error.

### Ponta a ponta

Corri como o job do CI: servidor Node de verdade (que já traz o terreno da 48), a jogadora Node da 49, o Mestre
Godot e o motor falso. Fiz **2 corridas, 17/17 nas duas**. A jogadora deu OK nas duas, com **23 mensagens** e
as quatro fases conferidas pelos canários (jogo 13, voltar 4, fim 1, recomeço 5). O VLAB real ficou para o CI,
que o corre no `ponta-a-ponta` e saiu verde.

### As três presenças, uma a uma

1. **A prova da Ordem 48 continua de pé.** Corri `provar_terreno_servidor.gd -- --json=…` na árvore fundida: o
   servidor de verdade (`juizo-terreno.mjs`: `sala.js` com o pacote) contra a arena do jogo. Deu TUDO PASSOU
   nas 12 grelhas.
   - As três salas de **25 × 25** têm todas **desvio 0** na altura e no pé, dentro e fora da zona livre (pelos
     bits do double), 0 juízos diferentes e 0 motivos diferentes:

     | escala | casas bloqueadas | recusas | mover |
     |---|---|---|---|
     | 1,5 m | 10 | 10, todas com o motivo do cliente | 51 casas, 0 bloqueadas |
     | 1 m | 0 | 0 | 91 casas, 0 bloqueadas |
     | 2 m | 41 | 41 | 21 casas, 0 bloqueadas |

   - O JSON da medição é **igual byte a byte** ao blob de `provas/ordem-48-terreno/medicao-terreno-qualquer-grelha.json`
     no repositório. Comparei com o blob porque a cópia de trabalho está em CRLF (`autocrlf`).
2. **O tecto da nova tentativa da MASTER_VIEW (Ordem 49, A) está presente e o teste passa.**
   - O código está em `mestre.gd`: `TENTATIVAS_VISTA_MAX := 40` (l. 41), `FALHA_VISTA := "vista_sem_pedido"`
     (l. 43) e o corte em `_tentar_vista` (l. 230–239). O alerta está em `textos_mestre.gd` (l. 231).
   - No `abrir_mestre`, o bloco «o pedido da vista tem tecto…» dá as 9 verificações `ok`:
     - 40 pedidos e não 201;
     - nenhum pedido à espera;
     - a falha com o nome `vista_sem_pedido`;
     - um só alerta;
     - um evento depois do tecto dá 1 tentativa;
     - «Atualizar» recomeça a conta;
     - um pedido que sai na 40.ª tentativa chega;
     - um pedido que sai à 1.ª fica num pedido só.
   - O `push_warning` aparece no registo duas vezes, como deve.
3. **A arena do jogador guarda o nome «Linhas» ao refazer a grelha (Ordem 49, C).** O `_grelha.remove_child(n)`
   está em `arena.gd` (l. 164). No `hud_acoes`, o bloco «ordem 49: a grelha refeita…» dá as 10 verificações
   `ok`, com um snapshot de 24 × 22:
   - no mesmo quadro, `Grelha/Linhas` já é o nó novo;
   - depois da fila de libertação continua lá e é o mesmo nó;
   - os nomes são `AbrigosDoMapa`, `Cursor`, `Destaques`, `Fogo` e `Linhas`, sem nenhum inventado a mais
     (1 → 1);
   - há uma só malha de linhas;
   - `Fogo`, `Destaques` e `Cursor` são as camadas novas;
   - as linhas cobrem (−18, −16,5)–(18, 16,5).

**Defeitos da fusão: nenhum.** Não houve nenhuma falha de suite na árvore fundida que não existisse num dos
ramos. Os números batem com a soma dos dois fechos: servidor 345 (+10 saltados) / 355, `rodar_testes` 177,
`abrir_mestre` 66, `hud_acoes` 42.

## Parte C: push e CI

- O push foi normal, sem força, com o ramo novo (`[new branch]`): antes confirmei com `ls-remote` que o remoto
  não o tinha. Empurrei logo depois da fusão 2/2, para a fatia ficar guardada.
- **CI da ponta `d0c9085`, confirmado pela API do GitHub**
  (`gh api …/actions/runs/43706175376/jobs`): «Testes dos rascunhos», run **43706175376**, conclusão
  `success`, **os 9 jobs com `success`**: `servidor`, `validador-glb`, `motor-real`, `protocolo`, `cliente`,
  `godot-cliente`, `ponta-a-ponta`, `retoma-pc` e `foto-mestre`. A «Sonda de privacidade», run 43706175324,
  também deu `success`. É a árvore fundida inteira. Os dois commits seguintes só trazem este documento e as
  listas.
- O CI desses dois commits finais está nas «Notas de fecho», no fim.

## Resíduos nomeados

1. **Node 26 local e `--permission`.** Corrido exactamente como o CI (`--permission --allow-fs-read`), o servidor
   dá aqui 7 vermelhos. São todos `ERR_ACCESS_DENIED` de rede: o modelo de permissões do Node 26 também fecha a
   rede, e o Node 24 do CI não. Com `--allow-net` dá 345/0/10, e o job `servidor` do CI está verde. Isto vem da
   máquina, não da fusão. O registo dos 7 está em `_tmp/o50/servidor.log`.
2. **`rascunhos/servidor/dados-exemplo/mesa-mestre.json`** continua a aparecer modificado na árvore de trabalho:
   é o artefacto de fim-de-linha (CRLF) de antes da sessão. Não o commitei nem o «corrigi». Conferi o
   `git diff --cached` de cada commit: nunca entrou. O `fixture-mestre` passou na mesma.
3. **As cópias de trabalho em CRLF** (`autocrlf=true`). Por isso a medição da presença 1 compara-se com o blob do
   repositório, e não com o ficheiro no disco.
4. **O que as Ordens 48 e 49 deixaram em aberto continua em aberto.** A integração não lhe mexe:
   - da 48: a cobertura da borda não é servida abaixo de 2, as salas nascem a 1,5 m, e a altura e a cobertura
     ainda estão fora das regras;
   - da 49: o contrato dos alertas, os pontos de workflow e a `E2E_FUGA` fora do CI.
5. **Higiene.**
   - Nos commits não há `referencias-arvore-ancestral/`, `.avi` nem `_tmp`, e os workflows estão intocados.
   - O commit solto da resolução (`96a6222`) não está em nenhum ramo e não foi empurrado.
   - Os ramos `fable/servidor-grelhas-48` e `fable/servidor-correcoes-49` ficaram como estavam (`69ed8a2` e
     `491c3fa`, local igual ao remoto).

## Nota de retoma

Não há nada a meio. A linha única das duas ordens é `fable/integracao-50`. Quem pegar daqui parte da ponta deste
ramo, que já tem as listas em dia. Para lhe juntar outro ramo, as listas refazem-se no fim
(`python3 retoma-i0004/actualizar-listas.py` na raiz). Se houver conflito nelas, a resolução é a desta ordem:
refazer pelo gerador sobre a árvore fundida, nunca escolher um lado.

## Notas de fecho

O CI dos dois últimos commits (este documento e as listas) foi conferido pela API depois do push. O resultado
vai no relatório do fecho; não o escrevi aqui para não precisar de mais um commit só por isso.
