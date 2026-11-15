# Ordem 53: fundir a Ordem 51 na linha de integração (construção e ligação; nada visual). ESTADO FINAL

*Fecho da ordem, 2026-11-15, Opus 5.5, uma só sessão. PCDANASA, Godot 4.7.2 (Compatibility), Node 26 local.
Trabalhei no clone `C:\Users\txcga\fable-mapa\repo`, na própria `fable/integracao-50`, sem branch nova. A ponta de
partida era `6f2fa43` (Ordens 48 + 49, fundidas pela Ordem 50). Fundi `fable/toque-51` (Ordem 51, ponta `c407b7e`).
As três partes estão feitas, commitadas e empurradas. Tudo o que aparece como «provado» abaixo corri-o eu nesta
máquina, na árvore fundida. Os registos estão em `C:\Users\txcga\fable-mapa\_tmp\o53\`, fora do repositório. Não
toquei em `main`, em `fable/toque-51` nem em `.github`.*

## O que mudou (commits)

| commit | o quê |
|---|---|
| `92f4892` | **Parte A.** Funde `fable/toque-51` (Ordem 51, ponta `c407b7e`) em `fable/integracao-50`. Houve 2 conflitos, ambos em listas geradas. Estão resolvidos e nomeados no corpo do commit e abaixo. |
| *(este)* | **Parte C.** Este ESTADO FINAL. |
| *(o seguinte)* | Listas da retoma e MANIFESTO refeitos (este documento está dentro de `rascunhos/`). |

A Parte B não precisou de nenhum commit: não apareceu nenhum defeito da fusão para consertar (ver abaixo).

## Parte A: a fusão (`92f4892`)

A Ordem 51 parte de `8cd941d`, a mesma base das Ordens 48 e 49. Usei `--no-ff`, com um commit de fusão nomeado.

**O código da Ordem 51 não se cruza com o da integração.** A 51 mexe em 9 ficheiros. Nenhum ficheiro de código,
teste, prova ou dado é tocado pelos dois lados. Estes entraram sem conflito:

- `rascunhos/cliente/cenas/arena/campo_da_mesa.gd` (o conserto do raio partilhado `ponto_no_chao`);
- `rascunhos/cliente/cenas/arena/ferramentas/medir_toque_rasante.gd`;
- `provas/ordem-51-toque/antes.{txt,json}` e `depois.{txt,json}`;
- `rascunhos/cliente/mapa/floresta/ESTADO-FINAL-ORDEM-51.md`.

Houve dois conflitos, os dois em listas **geradas** pelo `retoma-i0004/actualizar-listas.py`:

| ficheiro | o que o lado integração trazia | o que o lado 51 trazia | como ficou |
|---|---|---|---|
| `MANIFESTO-SHA256.txt` | Os SHA dos ficheiros das Ordens 48, 49 e 50, e o SHA **da base** em `campo_da_mesa.gd`. | O SHA novo de `campo_da_mesa.gd`, as linhas novas de `medir_toque_rasante.gd` e do ESTADO da 51, e os SHA **da base** nos ficheiros da 48 e da 49 (por exemplo `exportar_terreno.gd`). | **Nenhum lado servia à árvore fundida**, porque cada um traz os SHA velhos dos ficheiros do outro. Refi-lo com o próprio gerador sobre a árvore fundida. Em relação ao lado integração mudam só as 3 linhas da Ordem 51 (o SHA de `campo_da_mesa.gd` e as duas linhas novas). São **332 ficheiros**. |
| `retoma-i0004/depois.txt` | 281 ficheiros | 276 ficheiros | Refeito da mesma maneira: **283** (os 281 da integração mais os 2 novos da 51, com `campo_da_mesa.gd` no SHA da 51). `antes.txt` não muda (32). |

**Como fiz a resolução, sem escolher um lado.** É a receita da Ordem 50. O gerador lê o `HEAD`, e durante a
fusão o `HEAD` ainda é o lado integração. Por isso:

1. pus as duas listas provisoriamente no texto do lado integração;
2. fiz um commit **solto** (`git commit-tree`, `24a5643`, fora de qualquer ramo) com a árvore fundida;
3. corri uma cópia do gerador, em `_tmp/o53/listas_tmp.py`, que lê esse commit em vez do `HEAD`;
4. o resultado entrou no commit de fusão.

**Provas da resolução:**

- O `actualizar-listas.py` verdadeiro, corrido sobre `92f4892`, **não muda nenhum byte** (0 novos, 0 tirados).
- As 3 linhas da 51 no MANIFESTO fundido são iguais, byte a byte, às do MANIFESTO da ponta `c407b7e`.
- O job `retoma-pc` do CI confere as listas contra o clone, e está verde nesse commit.

**O trabalho de cada lado ficou inteiro.** Para cada ficheiro que cada lado mudou em relação a `8cd941d`, comparei
o blob da fusão com o blob da ponta desse lado:

- integração (48 + 49 + 50): 31 ficheiros, 29 iguais;
- Ordem 51: 9 ficheiros, 7 iguais;
- os únicos diferentes, nos dois casos, são `MANIFESTO-SHA256.txt` e `depois.txt`, as duas listas refeitas.

Não houve nenhum conflito com duas lógicas incompatíveis. Não parei nenhuma parte.

## Parte B: a prova da linha fundida (ponta `92f4892`)

### Servidor

| corrida | resultado |
|---|---|
| Como o job `servidor`: `--permission --allow-fs-read=…` e também `--allow-net` (ver resíduo 1) | 355 testes: **345 passam, 0 falham**, 10 saltados. É o número da Ordem 50. |
| Como o job `protocolo`: sem `--permission`, com `PROTOCOLO_DUMP` | **355/355** |
| `conferir-schemas.py` sobre esse tráfego (16 868 mensagens) | exit 0, 0 falhas nas mensagens que saem do servidor |
| `validador-glb` | 31 passam, 0 falham (33 testes, 2 saltados) |
| `node servidor/ferramentas/conferir-terreno.mjs` | **TERRENO EM DIA**: o pacote, refeito pelo cliente, igual byte a byte |

A Ordem 51 não mexe no servidor, por isso os números são os da linha antes da fusão.

### Cliente, sem janela (Godot 4.7.2), depois do `--import`

| suite | resultado |
|---|---|
| `abrir_scripts` | **69 scripts**, 0 falhas (os 68 da 50 mais o `medir_toque_rasante.gd` da 51) |
| `rodar_testes` | **177/177** (o número da 50; a 51 dava 176 porque não tinha o teste da 48) |
| `abrir_clareira` | 22/22 |
| `medir_painel_config` | 0 falhas, 0 sem medida |
| `abrir_mestre` | 66/66. Os comandos validam contra os schemas: 9 mensagens, 0 falhas |
| `pecas_mestre` | 236/236. Os comandos validam contra os schemas: 26 mensagens, 0 falhas |
| `medir_mestre` | 0 falhas, 0 sem medida |
| `hud_acoes` | 42/42 |
| `canario_privacidade` | 10/10 |
| `clima_forte` | 119/119 |
| arranque `--quit-after 600` | «pronto», 0 erros |
| `provar_terreno_servidor`, `provar_mestre_no_relevo`, `provar_assentamento` | TUDO PASSOU nos três |

Nenhuma suite teve SCRIPT ERROR, Parse Error ou Compile Error.

### Ponta a ponta

Corri como o job do CI: servidor Node de verdade, a jogadora Node, o Mestre Godot e o motor falso. Fiz
**2 corridas, 17/17 nas duas**. A jogadora deu OK nas duas, com 23 mensagens e as quatro fases conferidas pelos
canários (jogo 13, voltar 4, fim 1, recomeço 5). O VLAB real ficou para o CI, que o corre no `ponta-a-ponta` e
saiu verde.

### As três presenças, uma a uma

1. **A prova da Ordem 48: sala 25 × 25 julgada pelo servidor de verdade, desvio 0.** Corri
   `provar_terreno_servidor.gd -- --json=…` na árvore fundida. Deu TUDO PASSOU nas 12 grelhas. As três salas de
   25 × 25 têm **desvio 0** na altura do centro da casa e no pé da figura, dentro e fora da zona livre, com 0
   juízos diferentes e 0 motivos diferentes:

   | escala | casas dentro / fora da zona livre | casas bloqueadas | recusas |
   |---|---|---|---|
   | 1,5 m | 400 / 225 | 10 | 10, todas com o motivo do cliente; mover oferece 51 casas, 0 bloqueadas |
   | 1 m | 625 / 0 | 0 | 0 |
   | 2 m | 225 / 400 | 41 | 41 |

   O JSON da medição é **igual byte a byte** ao blob de
   `provas/ordem-48-terreno/medicao-terreno-qualquer-grelha.json`. Comparei com o blob, e não com o disco, porque
   a cópia de trabalho está em CRLF.
2. **O tecto da MASTER_VIEW e o nome «Linhas» (Ordem 49).**
   - O código está em `mestre.gd`: `TENTATIVAS_VISTA_MAX := 40` (l. 41), `FALHA_VISTA := "vista_sem_pedido"`
     (l. 43) e o corte em `_tentar_vista` (l. 230–239). No `abrir_mestre`, o bloco «o pedido da vista tem
     tecto…» dá as 9 verificações `ok`. Entre elas: 40 pedidos e não 201, a falha `vista_sem_pedido`, um só
     alerta, «Atualizar» recomeça a conta.
   - O `_grelha.remove_child(n)` está em `arena.gd` (l. 164). No `hud_acoes`, o bloco «ordem 49: a grelha
     refeita…» dá as 10 verificações `ok`. Entre elas: no mesmo quadro, `Grelha/Linhas` já é o nó novo; os nomes
     são `AbrigosDoMapa`, `Cursor`, `Destaques`, `Fogo` e `Linhas`, sem nenhum a mais; as linhas cobrem
     (−18, −16,5)–(18, 16,5).
3. **A medição da Ordem 51: toques rasantes da 30 × 30 completos, e a 20 × 20 continua 400/400.** Corri
   `medir_toque_rasante.gd -- --json=…` na árvore fundida. Deu SEM FALHAS, exit 0:

   | grelha · modo | jogador | Mestre | já acertavam e mudaram |
   |---|---|---|---|
   | 20 × 20 · Fixa | 340/340 | 301/301 | 0 · 0 |
   | 20 × 20 · Panorama | 400/400 | 400/400 | 0 · 0 |
   | 20 × 20 · 360° rasante | **400/400** | **400/400** | 0 · 0 |
   | 30 × 30 · Fixa | 637/637 | 467/467 | 0 · 0 |
   | 30 × 30 · Panorama | 900/900 | 900/900 | 0 · 0 |
   | 30 × 30 · 360° rasante | **895/895** (5 tapadas) | **895/895** (5 tapadas) | 0 · 0 |

   O JSON é **igual byte a byte** ao blob de `provas/ordem-51-toque/depois.json`. A prova da Ordem 45
   (`provar_mestre_no_relevo.gd`) confirma por outro caminho: no modo 1, Mestre 895 de 895 e jogador 895 de 895,
   com TUDO PASSOU.

**Defeitos da fusão: nenhum.** Não houve nenhuma falha que não existisse num dos lados. Os números batem com os
fechos: servidor 345 (+10 saltados) / 355, `rodar_testes` 177, `abrir_scripts` 69, `abrir_mestre` 66,
`hud_acoes` 42, rasante 30 × 30 895/895.

## Parte C: push e CI

- O push foi normal, sem força: `6f2fa43..92f4892`, um avanço rápido do ramo remoto. Empurrei logo depois da
  fusão, para a fatia ficar guardada.
- **CI da ponta `92f4892`, confirmado pela API do GitHub**
  (`gh api …/actions/runs/43709105202/jobs`): «Testes dos rascunhos», run **43709105202**, conclusão
  `success`, **os 9 jobs com `success`**: `servidor`, `validador-glb`, `motor-real`, `protocolo`, `cliente`,
  `godot-cliente`, `ponta-a-ponta`, `retoma-pc` e `foto-mestre`. A «Sonda de privacidade», run 43709105224,
  também deu `success`. É a árvore fundida inteira. Os dois commits seguintes só trazem este documento e as
  listas.
- O CI desses dois commits finais vai no relatório do fecho. Não o escrevi aqui para não precisar de mais um
  commit só por isso.

## Resíduos nomeados

1. **Node 26 local e `--permission`.** Como na Ordem 50: localmente o servidor corre com `--allow-net` a mais,
   porque o modelo de permissões do Node 26 também fecha a rede e o Node 24 do CI não. O job `servidor` do CI,
   sem esse flag, está verde.
2. **`rascunhos/servidor/dados-exemplo/mesa-mestre.json`** continua a aparecer modificado na árvore de trabalho:
   é o artefacto de fim-de-linha (CRLF) de antes da sessão. Não o commitei nem o «corrigi». Conferi o
   `git diff --cached` de cada commit: nunca entrou.
3. **As cópias de trabalho em CRLF** (`autocrlf=true`). Por isso as medições das presenças 1 e 3 comparam-se com
   os blobs do repositório, e não com os ficheiros no disco.
4. **O que as Ordens 48, 49 e 51 deixaram em aberto continua em aberto.** A integração não lhe mexe:
   - da 48: a cobertura da borda não é servida abaixo de 2, as salas nascem a 1,5 m, e a altura e a cobertura
     ainda estão fora das regras;
   - da 49: o contrato dos alertas, os pontos de workflow e a `E2E_FUGA` fora do CI;
   - da 51: as 5 casas tapadas no rasante da 30 × 30, a tolerância de 1 mm (`TOQUE_RASANTE_M`), o caso de dois
     mínimos de folga entre os mesmos três passos, e só o rumo 135° medido.
5. **Higiene.**
   - Nos commits não há `referencias-arvore-ancestral/`, `.avi` nem `_tmp`, e os workflows estão intocados.
   - O commit solto da resolução (`24a5643`) não está em nenhum ramo e não foi empurrado.
   - `fable/toque-51` ficou como estava (`c407b7e`, local igual ao remoto). A `main` não foi tocada.

## Nota de retoma

Não há nada a meio. A linha única das Ordens 48, 49 e 51 é `fable/integracao-50`. Quem pegar daqui parte da ponta
deste ramo, que já tem as listas em dia. Para lhe juntar outro ramo, as listas refazem-se no fim
(`python3 retoma-i0004/actualizar-listas.py` na raiz). Se houver conflito nelas, a resolução é a das Ordens 50 e 53:
refazer pelo gerador sobre a árvore fundida, nunca escolher um lado.
