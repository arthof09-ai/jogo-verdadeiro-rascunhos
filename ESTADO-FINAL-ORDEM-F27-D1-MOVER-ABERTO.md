# ESTADO-FINAL — Ordem F27 da sentença da CAIXA-EXPANDE-INTERACAO (prova do D1 com o Mover aberto)

**Coordenador:** CM-000009. **Executor:** Claude conta 2, PC do cunhado. **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.

**Partida:** `94719e0` (`94719e0965ee3626a51e60da5885eb5d2a05c8fe`), registado antes de começar.
- Durante o trabalho a linha andou 4 commits até `b64fc91`: o CI da F14 e a F25 (limpeza dos 11 ficheiros).
- Esses commits só mexem em documentos e em registos de `provas/`. Nenhum toca em `rascunhos/`, na ferramenta da prova,
  nas listas da retoma nem em nenhum ficheiro desta ordem.
- Avancei a cópia local por `--ff-only` antes do commit 1. As medidas feitas em cima de `94719e0` valem tal e qual,
  porque o código do jogo e as ferramentas são os mesmos.

**Commits:**
1. `52397ac` — a suite (`caixa_jogadora` §11), a ferramenta da prova (passo 13), o lançador e as provas.
2. este ESTADO-FINAL e as listas da retoma sincronizadas.
3. a nota do CI da ponta do commit 2, acrescentada ao §6 (só documento).

Este ficheiro não tem nomes verdadeiros, nem pedaços deles, nem o valor de nenhum PIN (§7).

## 1. O que mudou
**Nenhum ficheiro do jogo.** A correcção do D1 é a da F14 (`caixa_ordem.gd`, `_fechar_por_toque_fora` e `_engolir`).
Esta ordem só a prova com movimento.

- **`rascunhos/cliente/testes/caixa_jogadora.gd` — §11 novo (`_mover_aberto`).** Monta a **arena a sério**
  (`cenas/arena/arena.tscn`), com o HUD, a câmara e o `_ao_toque` dela. É o caminho toque → casa → intenção do jogo.
  Não há servidor. Corre com 12 e 16 figuras, em 844×390 e 780×360. Em todos os casos:
  - a jogadora está na vez, na casa (10, 10), com um ROOM_OPTIONS que traz as casas a até 3 casas dela (48);
  - o Mover abre-se **por toque no botão da barra**, pelo `Input` do motor;
  - a expandida abre-se por toque;
  - o sítio do toque fora é o centro de uma casa de destino, projectado pela câmara. Fica fora da caixa, da ⚙/ficha, da
    barra, da faixa e da gaveta do Mover, e `casa_em_tela` confirma que tocar aí dá essa casa.
  - A Rede fica «na mesa» com um `WebSocketPeer` por ligar. Assim a intenção regista-se na fila e o envio do texto falha
    sem erro. No fim, o estado da Rede é reposto.
- **`provas/ordem-caixa-expande/ferramentas/prova_caixa_expande.gd` — passo 13 novo** (`_mover_aberto`, depois do
  11/12). Faz a condução até à vez dela (§2) e o D1 com movimento contra o servidor real (§3).
  - Antes de medir, espera que o tabuleiro assente: nenhum nó de figura se mexe durante 30 quadros.
  - O destino da intenção lê-se do `ROOM_EVENT movimento` que a jogadora recebe. A fila da Rede apaga o texto da
    intenção quando ela termina (ver §8.1).
- **`provas/ordem-f27-mover-aberto/`**: o lançador `ferramentas/correr-prova-mover-aberto.sh` (cópia do da F14, com a
  saída nesta pasta; o PIN é novo por corrida e passa só por `--pin=`), as capturas, o relato, os logs das suites,
  `sem-correcao/` e `mutacao/`. O `README.md` tem os SHA-256 das 6 capturas novas.

**Biblioteca primeiro.** Não construí nenhum sistema: só usei peças do próprio jogo (a arena, o HUD, a câmara, a Rede, a
IA de ensaio e os lugares de ensaio, ambos em `rascunhos/cliente/autojogo/`). A F14 já tinha visto a GameDev Kit para esta
mesma matéria (eventos de interface): lá não há nada que se aplique. Para uma prova que só usa o jogo, não havia o que
procurar de novo, por isso não voltei a abrir a biblioteca.

## 2. A condução até à vez dela (prova viva, passo 13)
Depois do passo 11/12 há 16 figuras e a caixa está no modo iniciativa. A IA de ensaio joga as vezes das outras figuras,
pelo Mestre e pelos lugares de ensaio (mover e encerrar), até a `vezId` do servidor ser a da jogadora do ecrã a sério.
Depois espera que o ROOM_OPTIONS dela chegue ao aparelho, com casas do Mover.

| ecrã | vezes jogadas pela IA de ensaio | vez de | rodada | casa dela | casas do Mover | orçamento |
|---|---|---|---|---|---|---|
| 844×390 | 6 (todas criaturas da mesma ficha) | a jogadora | 2 | (11, 8) | 38 | 9,0 m |
| 780×360 | 0 (a mesma vez, depois do controlo do 844×390) | a jogadora | 2 | (7, 9) | 4 | 1,5 m |

Em 780×360 a medida corre na mesma vez dela, com o orçamento que sobrou do movimento do controlo de 844×390. Se o Mover
estivesse gasto, a ferramenta encerrava a vez dela e voltava a conduzir a batalha (o caminho existe, mas não foi preciso).

## 3. O toque fora com o Mover aberto — antes e depois
**Prova viva** (servidor de mesa real, motor VLAB real `a91c021c…`, semente 7, manequim de referência `andar-v3.glb` com o SHA conferido (`sha256 8413b0395d6b9f161aefe05004999ee5f605d4eb68e81a4767a81f9b56ea3491`, 2.858.648 B)). «u» são unidades do HUD. A casa do servidor é a da vista do Mestre.

| ecrã | toque fora em | casa de destino sob o toque | ANTES: nó · casa (Estado) · casa (servidor) · modo · fila | DEPOIS: fechou · «toque» · nó · casa (Estado) · casa (servidor) · modo · fila · «movimento» da jogadora recebido |
|---|---|---|---|---|
| 844×390 | (922,9; 591,9) | (7, 9) | (2.25, −0.02, −2.25) · 11,8 · 11,8 · Mover · 0 | sim · 0 · (2.25, −0.02, −2.25) · 11,8 · 11,8 · Mover · 0 · 0 |
| 780×360 | (986,2; 592,7) | (8, 9) | (−3.75, −0.08, −0.75) · 7,9 · 7,9 · Mover · 0 | sim · 0 · (−3.75, −0.08, −0.75) · 7,9 · 7,9 · Mover · 0 · 0 |

- A última intenção enviada pela arena não mudou, e o cursor também não ((11, 8) e (7, 9)).
- A comparação do tabuleiro inteiro deu **0 diferenças** nos dois casos: os nós de todas as figuras, as casas do Estado,
  o modo, o cursor, os alvos, o item, a última intenção e a fila.

**O controlo** — a caixa fechada e o mesmo toque, no mesmo sítio:

| ecrã | «toque» | intenções novas | movimento recebido do servidor | nó | casa (Estado) | casa (servidor) | modo |
|---|---|---|---|---|---|---|---|
| 844×390 | 1 | 1 | 1, para (7, 9) | (2.25, −0.02, −2.25) → (−3.75, −0.08, −0.75) | 11,8 → 7,9 | 11,8 → 7,9 | Mover → nenhum |
| 780×360 | 1 | 1 | 1, para (8, 9) | (−3.75, −0.08, −0.75) → (−2.25, −0.12, −0.75) | 7,9 → 8,9 | 7,9 → 8,9 | Mover → nenhum |

**Capturas** (em `provas/ordem-f27-mover-aberto/cliente/`; vi as três de 844×390):
- `13-mover-aberta-*`: a lista aberta por toque, o Mover aberto e as casas de destino a azul;
- `13-mover-toque-fora-*`: a caixa já compacta, as casas de destino ainda a azul (o Mover continua aberto) e a figura
  no mesmo sítio;
- `13-mover-controlo-*`: a figura na casa de destino e o Mover fechado. Os números de dano que se vêem por cima de duas
  figuras são do ataque de uma criatura durante a condução, não deste toque.

**Suite, §11** (arena a sério, sem servidor). Nos 4 casos a casa de destino sob o toque é a (7, 11), e o toque fora cai
em (983–985; 588,7–590,1) u.

| caso | D1 com o Mover aberto: fechou · «toque» · nó j1 · casa j1 · modo · fila · cursor | controlo: «toque» · intenção que sai |
|---|---|---|
| 12 · 844×390 | sim · 0 · igual · 10,10 → 10,10 · Mover → Mover · 0 → 0 · igual | 1 · `{"tipo":"mover","destino":{"x":7,"y":11}}` |
| 12 · 780×360 | sim · 0 · igual · igual · Mover → Mover · 0 → 0 · igual | 1 · a mesma |
| 16 · 844×390 | sim · 0 · igual · igual · Mover → Mover · 0 → 0 · igual | 1 · a mesma |
| 16 · 780×360 | sim · 0 · igual · igual · Mover → Mover · 0 → 0 · igual | 1 · a mesma |

Na suite não há servidor, por isso o controlo prova a escolha (a intenção `mover` para a casa sob o toque). A figura a andar
prova-se na prova viva.

**O §11 apanha o defeito.** Corri a suite com o `caixa_ordem.gd` de `0bebd76` (antes da F14), só na cópia de trabalho, e
depois repus o ficheiro (`git diff` vazio). O resultado foi **54/70**: as 8 falhas do §10, como na F14, e as **8 novas
do §11**. Sem a correcção, o toque fora **envia a intenção de mover**: a fila passa de 0 a 1, o modo passa de Mover a
nenhum e o «toque» dispara 1 vez. O controlo falha porque o Mover já se tinha fechado
(`provas/ordem-f27-mover-aberto/sem-correcao/caixa_jogadora.log`).

## 4. O que a F14 provou continua
Godot 4.7.2, Windows 11, `--headless`, como no CI. Os logs da caixa estão em `provas/ordem-f27-mover-aberto/suite/`; as
linhas finais dos outros passos estão em `suite/resumo-alheios.txt`.

| passo | F14 | agora |
|---|---|---|
| `rodar_testes` | 321/321 | **321/321** |
| `caixa_janela` | 123/123 | **123/123** |
| `caixa_jogadora` | 58/58 | **70/70** (+12: o §11, 3 por caso × 4 casos) |
| `caixa_jogadora -- --estrita` | 57/58 | 69/70 (a mesma falha de sempre: 780×360, 11,5 u) |
| guião de mutação da CAIXA-JANELA-CI | 114 de 123 | **114 de 123** (9 falhas, todas da B6, 0 erros, ficheiro reposto) |
| `abrir_scripts` · `abrir_clareira` · `abrir_mestre` · `pecas_mestre` · `hud_acoes` | 108/0 · 22 · 67 · 286 · 50 | iguais |
| `medir_painel_config` · `medir_mestre` | 0 falhas, 0 sem medida | iguais |
| `teste_relato_caixa` · `teste_nomes_relato` · `canario_privacidade` | 31 · 26 · 10 | iguais |
| erros de script em todos os passos | 0 | 0 |
| prova viva | 209 (F14) · 241 (VISTAS) | **255/255**: os passos 0–12 dão os mesmos 241, e o 13 dá 14 |

- **O único número que mudou é o da `caixa_jogadora`, porque cresceu com o §11.** O CI não prende esta suite a um
  número: corre-a com `set -o pipefail` e o código de saída (`quit(1)` com falhas). A guarda «123 de 123» é só da
  `caixa_janela`, que não mudou.
- **A roda e o zoom ficam como a F14 os deixou.** Não toquei no `caixa_ordem.gd` nem na câmara. O §10 (D1 sem modo, D3)
  continua verde nos 4 casos, e o passo 11 da prova viva (roda, zoom, controlo da roda fora) também: 70 verificações no
  11 com o 12, como na VISTAS.
- No §11 a arena carrega o mapa da floresta, em cerca de 3,5 s. A suite inteira, com o §11, correu em 7,5 s neste PC,
  longe do limite de 120 s do CI.

## 5. Listas da retoma
Corri o `actualizar-listas.py` depois do commit 1, porque ele lê o `HEAD`. Deu **0 novos e 0 tirados**. Só muda o SHA
de um ficheiro, `rascunhos/cliente/testes/caixa_jogadora.gd`, em `retoma-i0004/depois.txt` e no `MANIFESTO-SHA256.txt`.
Os dois vão sincronizados no commit 2. A ferramenta da prova está em `provas/`, fora das listas.

## 6. CI
**CI da ponta `3ed5368` (commit 2), já na linha** (Testes 45105992689 + Sonda 45105992711): **10/10 jobs verdes e a
Sonda verde**.

**CI da ponta `07d0a87` (F40, emendas da conferência), já na linha** (Testes 45110483676 + Sonda 45110483808): **10/10 jobs verdes e a Sonda verde** — a condição da fusão da F27 está cumprida (F41). Os jobs são `servidor`, `validador-glb`, `foto-mestre`, `godot-cliente`, `cliente`, `ponta-a-ponta`,
`retoma-pc`, `provas-mapa`, `motor-real` e `protocolo`.

No Linux do CI os números são os de cá:
- **`caixa_jogadora` 70/70**: o §11 corre lá com a arena a sério;
- `caixa_janela` 123/123, e a guarda «123 de 123» passou;
- `rodar_testes` 321/321, nos jobs `cliente` e `godot-cliente`;
- `abrir_scripts` 108 scripts e 0 falhas · `abrir_clareira` 22/22 · `abrir_mestre` 67/67 · `pecas_mestre` 286/286 ·
  `hud_acoes` 50/50 · `medir_painel_config` e `medir_mestre` com 0 falhas e 0 sem medida;
- `teste_relato_caixa` 31/31 · `teste_nomes_relato` 26/26 · o canário 10/10;
- o guião de mutação: 9 falhas, todas da B6, e «114 de 123».

O `retoma-pc` passou com as listas do commit 2.

## 7. Privacidade: o conferidor estrito, re-derivado nos dois critérios
Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, critério alargado / `--velho`. Na coluna dos
nomes inteiros conta-se um achado cujo pedaço tem o comprimento do nome inteiro.

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-f27-mover-aberto/README.md` | **0 / 0** | 0 |
| as linhas que acrescentei a `caixa_jogadora.gd` e à ferramenta da prova (só o `+` do diff) | **0 / 0** | 0 |
| `suite/resumo-alheios.txt`, `mutacao/mutacao-celulas.resumo.txt` | **0 / 0** | 0 |
| `suite/caixa_jogadora.log`, `suite/caixa_jogadora-estrita.log`, `sem-correcao/caixa_jogadora.log` | 2 / 2 por log | **0** |
| o lançador `correr-prova-mover-aberto.sh` (cópia do da F14) | 2 / 2 | 0 |
| `cliente/relato.txt` | 133 / 133 | **0** |

- **As minhas linhas** tinham 13 achados na primeira versão. Vinham de quatro palavras correntes que partilham pedaços
  com os nomes. Testei as substitutas no conferidor antes de as trocar e ficaram 0 / 0. A suite e a prova viva voltaram
  a correr depois da troca, e os números acima são dessa corrida.
- **Os logs da `caixa_jogadora`** têm agora 2 / 2. Os dois achados estão numa só linha que eu não escrevi: o relatório de
  carga do mapa da floresta (`[floresta] pronta em … ms | {…}`), que a arena imprime ao abrir. Antes do §11 a suite não
  abria a arena. É a mesma natureza dos achados aceites na `caixa_janela` (palavras correntes, não nomes).
- **O lançador** herda a linha do servidor de ensaio (2 / 2, como os da CAIXA-EXPANDE e da F14).
- **O relato** dá 133. Os passos 0–12 dão 100 (o da VISTAS deu 108 para os mesmos passos, porque a IA de ensaio não
  joga sempre igual) e o passo 13 dá 33. Os 33 vêm de linhas com formatos que já existiam e do nome **público** dela:
  - as linhas `IA:` do `_jogar_vez`;
  - as linhas finais dos quadradinhos;
  - a minha linha de condução, que mostra a vez com o nome público, como a caixa o mostra.
- **Os logs dos outros passos não se cometem**: o do `teste_nomes_relato` imprime nomes verdadeiros inteiros de
  propósito. Desses fica só a linha final, no `resumo-alheios.txt` (0 / 0).
- **O PIN** é novo nas 4 corridas, uma a uma, e passa só por `--pin=`. O info e o log do servidor ficaram na pasta
  temporária, fora do repo.
  - Procurei números de 20 algarismos (a forma do PIN) em todos os ficheiros desta ordem: nenhum.
  - **0 valores de PIN** em qualquer ficheiro.

**Emenda da conferência (F40, 23/11/2026): o quadro verdadeiro.** O que este §7 diz sobre *esta entrega* é verdade (0 nomes inteiros em tudo o que ela acrescenta), mas a base trazia **90 pares (linha, nome) de nomes verdadeiros inteiros pré-existentes em 11 ficheiros** — a F25 limpou-os, 90→0, no commit `dd16afe`; esta ordem acrescenta 0; a ponta está a 0 nos ficheiros que o conferidor cobre.

## 8. Pontos para o coordenador
1. **A primeira corrida da prova viva deu 245/246.**
   - No D1 de 844×390, os dados da figura dela ficaram todos iguais (nó, casas, modo, fila, cursor, intenção), mas a
     comparação do tabuleiro inteiro falhou.
   - Essa corrida não imprimia que chave mudou. O mais provável é uma figura que a IA de ensaio acabara de mover ainda
     estar a andar; não o provei.
   - Na mesma corrida, o controlo deu um erro de script: o texto da intenção já tinha sido apagado da fila pelo recibo, e
     o passo parou aí.
   - Corrigi a ferramenta: espera que o tabuleiro assente, imprime as diferenças e lê o destino do `ROOM_EVENT`. Nas
     corridas seguintes, as diferenças deram **[]** e o resultado foi **255/255**. O código do jogo não mudou entre as
     corridas.
2. **Uma das corridas de 255/255 foi deitada fora.** Correu ao mesmo tempo que eu trocava o `caixa_ordem.gd` pela versão
   sem correcção, para a suite `sem-correcao`. Podia ter carregado o ficheiro errado. Repeti-a sozinha, sem nada a correr
   ao lado. Os números e as capturas deste ESTADO-FINAL são dessa última corrida.
3. **Um clone novo precisa do `--import` antes das suites.** Sem ele, a primeira corrida deu 280/321 e erros de script
   (as classes globais ainda não estão registadas). O CI já faz o `--import`. Fica o registo para quem correr à mão.
4. **O ponto 1 da F14 continua.** Com a lista aberta por toque, tocar em «Mover» só fecha a lista. Por isso a prova abre
   o Mover primeiro, com a caixa fechada, e só depois abre a lista. Não lhe toquei: a matéria desta ordem é só a prova.
5. **O arrastar num ecrã de toque** continua por provar neste PC, como na F14: este PC também não tem ecrã de toque.
