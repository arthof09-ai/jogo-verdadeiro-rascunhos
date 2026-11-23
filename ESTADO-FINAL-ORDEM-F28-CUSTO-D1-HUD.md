# ESTADO-FINAL — Ordem F28 da sentença da CAIXA-EXPANDE-INTERACAO (o custo do D1 nos botões do HUD)

**Coordenador:** CM-000009. **Executor:** Claude conta 1, PC do cunhado. **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.

**Partida:** `30d9c9d` (`30d9c9dc1142de5800c10797a0bdf9242a1c32b6`), registado antes de começar.
- Durante o trabalho a linha andou 1 commit, até `7c4da45`: as emendas F31–F35 da CAIXA-EXPANDE-VISTAS.
- Esse commit só mexe num documento (`ESTADO-FINAL-ORDEM-CAIXA-EXPANDE-VISTAS.md`). Não toca em `rascunhos/`, nas
  listas da retoma nem em nada desta ordem.
- Avancei a cópia por `--ff-only` antes do commit 1. As medidas valem tal e qual.

**Commits:**
1. `5e74098` — a ferramenta de medição, as duas medições (na ponta e sem o D1) e o README da pasta.
2. este ESTADO-FINAL.
3. a nota do CI da ponta do commit 2, acrescentada ao §5 (só documento).

**Esta ordem só mede e não muda nenhum comportamento.** Nenhum ficheiro do jogo foi tocado. A decisão é do Mestre (§7).

Este ficheiro não tem nomes verdadeiros, nem pedaços deles, nem o valor de nenhum PIN (§6).

## 1. Como medi
- **Ferramenta:** `provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd`.
  - O palco é o do §11 da `caixa_jogadora` (F27): a arena a sério (`cenas/arena/arena.tscn`, com o HUD, a câmara e o
    `_ao_toque`), sem servidor. A Rede fica «na mesa» com um `WebSocketPeer` por ligar, e a intenção regista-se na fila.
  - Há 12 figuras e a jogadora está na vez. O ROOM_OPTIONS liga todos os botões dela: as casas do Mover, um ataque, um
    consumível com 2 alvos e as acções encerrar, defender, correr, desvincular, apagar_fogo e transformar.
  - Os toques vão pelo `Input` do motor (`Input.parse_input_event`, em píxeis da janela), que imita o rato a partir
    deles, como no aparelho. O rato a sério é `device` 0.
  - Corre em 844×390 e 780×360, com Godot 4.7.2 `--headless` no Windows 11.
- **Por botão:**
  1. o estado de partida, posto com um toque e a caixa fechada (por exemplo, o Mover aberto para os botões da gaveta);
  2. a lista aberta por toque;
  3. toques no centro do botão até a acção sair, no máximo 4.

  Regista-se o 1.º toque (fechou a lista? o botão recebeu o `pressed`? a acção saiu?) e quantos toques foram precisos.
  O **controlo** é o mesmo caso com a caixa fechada.
- **Contrafactual:** a mesma medição com o `caixa_ordem.gd` de `0bebd76`, de antes da F14, que não tem o D1 nem o D3.
  Troquei-o só na cópia de trabalho e repus-o a seguir. `git diff` ficou vazio e o SHA do ficheiro é igual ao do `HEAD`
  (`cc26f56c…`).
- **Registos:** `provas/ordem-f28-custo-d1-hud/medicao/medir_custo_d1_hud.log` (na ponta) e `…/sem-d1/` (o contrafactual).
  Os dois têm 62 casos e 0 erros de medição. Os registos não têm nenhuma linha com `error` nem `warning`.
- **Repetição:** corri as duas medições duas vezes. As tabelas saíram iguais; só o deslocamento da câmara no arrastar
  varia, na 4.ª casa decimal.

## 2. Botão a botão (com a lista aberta por toque)
Os dois ecrãs deram **exactamente o mesmo** em todos os botões, por isso a tabela vale para 844×390 e 780×360.
Nenhum botão fica por baixo da lista aberta: o centro de todos fica fora dela, nos dois ecrãs.

| botão | o que faz | 1.º toque com a lista aberta | toques precisos | a acção sai? | controlo (caixa fechada) | sem o D1 (antes da F14) |
|---|---|---|---|---|---|---|
| Mover | abre o Mover (casas a azul) | fecha só a lista; o botão não recebe o `pressed` | **2** | sim, ao 2.º | 1 | 1: fecha e executa |
| Ataque | abre o Ataque (alvos) | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| Consumível | abre o Consumível (alvos) | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| Encerrar | abre «Encerrar a sua vez?» | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| ⚙ | abre as Configurações | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| FICHA ▸ | abre a ficha | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| Declarar Defender (na ficha aberta) | envia `defender` | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| » Correr (gaveta do Mover) | envia `correr` | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| ↩ Sair c/ segurança (gaveta do Mover) | liga a declaração | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| Apagar o fogo (gaveta do Mover) | envia `apagar_fogo` | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| ✦ Transformação (gaveta do Ataque) | abre a confirmação | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| Sim, encerrar (painel de escolha) | envia `encerrar` | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| Cancelar (painel de escolha) | fecha o painel | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| Fechar (Configurações) | fecha as Configurações | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |
| Repor o zoom (Configurações) | repõe o zoom | fecha só a lista | **2** | sim, ao 2.º | 1 | 1 |

- **O custo é igual em todos os botões: mais 1 toque.** O 1.º toque fecha a lista e mais nada. O botão não recebe o
  `pressed` (0), e o estado de partida fica como estava: o Mover continua aberto, o painel continua à vista. O 2.º toque
  executa a acção, com 1 `pressed`. Nenhum botão executa a acção duas vezes.
- **Sem o D1, todos davam 1 toque:** o toque fecha a lista e executa a acção no mesmo gesto.
- **O rato não muda nada** (tabela do rato no §3).

## 3. O resto
**O primeiro gesto no tabuleiro após abrir a lista por toque** (os dois ecrãs deram o mesmo):

| gesto | com a lista aberta por toque | controlo (caixa fechada) | sem o D1 |
|---|---|---|---|
| arrastar 1 dedo 90 u (deslocar a câmara) | a câmara **não se mexe** (0,000 m); a lista fecha | 2,27 m | 2,27 m |
| pinça, 2 dedos que se afastam 100 u (zoom) | o zoom **não muda** (1,500 → 1,500); a lista fecha | 1,500 → 3,000 | 1,500 → 3,000 |
| toque numa casa com o Mover aberto (F27) | fecha só a lista; a figura fica | escolhe a casa | **move a figura** (o defeito que o D1 corrige) |

- **O arrastar perde-se inteiro.** O D1 engole o gesto todo desse dedo, até ele se levantar. Custa repetir o gesto.
- **A pinça também se perde inteira.** O 1.º dedo é engolido, e por isso a câmara só vê o 2.º dedo. Um dedo sozinho não
  faz pinça, nem desloca: com um só dedo, a câmara usa o rato imitado, que vem só do 1.º dedo, e esse também é engolido.
- **A gaveta do Ataque e o Defender na ficha** são botões como os outros. Pagam o mesmo toque a mais (§2), e o estado de
  partida não se perde: a gaveta continua aberta e a ficha continua à vista.

**A roda do rato** (não é o D1, é o D3 da F14):

| onde | zoom | na ponta | sem o D1 nem o D3 |
|---|---|---|---|
| sobre a caixa compacta, sem o rato ter passado por cima | 1 passo para cima | **1,500 → 1,500** (fica na caixa) | 1,500 → 1,650 |
| sobre a caixa, depois de o rato entrar nela (abre a lista) | 1 passo para cima | **1,500 → 1,500** | 1,500 → 1,650 |
| sobre o tabuleiro (controlo) | 1 passo para cima | 1,500 → 1,650 | 1,500 → 1,650 |

A roda em cima da caixa, compacta ou aberta, nunca dá zoom. É o que a F14 registou. Num PC, a roda sobre a compacta é
quase sempre a roda sobre a lista aberta, porque o rato abre-a ao entrar.

**O rato** (Mover, Encerrar e ⚙, nos dois ecrãs; o mesmo na ponta e sem o D1):

| como | a lista fecha quando o rato sai para o botão? | cliques até a acção sair | a lista fica aberta no fim? |
|---|---|---|---|
| só o rato: a lista abre com o rato por cima | sim | **1** | não |
| a lista aberta por **toque**, depois o rato a sério (portátil com ecrã de toque) | **não** | **1** | **sim** |

- **O rato não paga o D1.** A lista do rato fecha quando o rato sai, antes do clique, e o clique chega ao botão. O D1 só
  olha para o rato imitado a partir do toque, e o clique do rato a sério passa sempre.
- **O rato a seguir a um toque deixa a lista aberta.** Se a lista foi aberta por toque, nem o rato a sair da caixa nem
  um clique fora a fecham. Só um toque a fecha. O clique no botão executa a acção na mesma (1 clique), mas a lista
  continua por cima do tabuleiro. Isto não vem do D1: a medição sem o D1 dá o mesmo (ponto 3 do §7).

## 4. O custo por jogada típica
A jogada é mover para uma casa e encerrar (Mover → casa → Encerrar → «Sim, encerrar»). Contei os toques todos, incluindo
o de abrir a lista para ver quem vem. Os dois ecrãs deram o mesmo.

| quando ela abre a lista por toque | na ponta (com o D1) | sem o D1 | o que paga o D1 |
|---|---|---|---|
| nunca | **4** (Mover 1, casa 1, Encerrar 1, Sim 1) | 4 | 0 |
| no começo da vez | **6** (abrir 1, Mover **2**, casa 1, Encerrar 1, Sim 1) | 5 | **+1** |
| com o Mover já aberto | **6** (Mover 1, abrir 1, casa **2**, Encerrar 1, Sim 1) | 5 | **+1** |

- **O preço é 1 toque por abertura da lista por toque**, seja qual for o alvo do toque seguinte: um botão,
  uma casa ou um gesto. Numa jogada de 4 toques, abrir a lista uma vez passa-a a 6, contra 5 sem o D1. O toque de abrir
  é preço da lista, não do D1.
- O toque a mais só não se paga quando ela já queria fechar a lista sem fazer mais nada. Nesse caso, fechar pela própria
  caixa ou por fora custa o mesmo toque, com ou sem D1.
- **O que o D1 compra com esse toque:** sem o D1, o toque que fecha a lista e cai numa casa com o Mover aberto **move a
  figura** (provado na F27), e o arrastar ou a pinça mexem a câmara por baixo da lista que se fecha.

## 5. CI
*(A preencher no commit 3 com o CI da ponta do commit 2.)*

## 6. Privacidade: o conferidor estrito, re-derivado nos dois critérios
Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, critério alargado / `--velho`. Na coluna dos
nomes inteiros conta-se um achado cujo pedaço tem o comprimento do nome inteiro.

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-f28-custo-d1-hud/README.md` | **0 / 0** | 0 |
| `ferramentas/medir_custo_d1_hud.gd` (todo o ficheiro é meu) | **0 / 0** | 0 |
| `medicao/medir_custo_d1_hud.log`, `sem-d1/medir_custo_d1_hud.log` | 2 / 2 por log | **0** |

- **A ferramenta** tinha 9 / 8 achados na primeira versão, em 5 linhas. Vinham de três sítios:
  - uma palavra corrente num comentário;
  - um pedaço a cavalo de duas palavras noutro comentário;
  - o nome de uma propriedade e de um botão do próprio `hud.gd`, que eu repetia.

  Testei as substitutas no conferidor antes de as trocar. Os comentários passaram a ter outra redacção. A propriedade
  passou a ler-se pelo começo do nome (`_declarar_saida`), e o botão pelo 1.º filho da gaveta. As medições voltaram a
  correr depois da troca, e os números acima são dessas corridas.
- **Este ESTADO-FINAL** tinha 8 / 6 achados na primeira versão, em 5 linhas: uma palavra corrente (3 linhas) e dois
  pedaços a cavalo de palavras. Troquei-os por redacções testadas antes no conferidor, e ficaram 0 / 0.
- **Os dois registos** têm 2 / 2 numa só linha que eu não escrevi: o relatório de carga do mapa da floresta
  (`[floresta] pronta em … ms | {…}`), que a arena imprime ao abrir. São os mesmos achados que a F27 aceitou nos logs da
  `caixa_jogadora`: palavras correntes, não nomes.
- **Os nomes que a ferramenta e os registos mostram** são públicos e genéricos, os mesmos da suite (`NOMES_8`).
- **O PIN:** esta ordem não usa servidor nem PIN. Procurei números de 20 algarismos (a forma do PIN) em todos os
  ficheiros desta ordem e não há nenhum. **0 valores de PIN** em qualquer ficheiro.

## 7. Pontos para o coordenador e para o Mestre
1. **A pergunta ao Mestre, com os números.** O D1 custa **+1 toque por abertura da lista por toque**. É o
   mesmo em todos os 15 botões, nos dois ecrãs, no arrastar e na pinça. Numa jogada típica de 4 toques, abrir a lista uma
   vez dá 6 com o D1, contra 5 sem ele. Em troca, o toque que fecha a lista nunca dá ordens ao tabuleiro (a figura não
   anda, a câmara não se mexe).
   - Se o Mestre quiser poupar os botões, a correcção poupava o 1 toque nos 15 botões do §2.
   - Mas a correcção tem de continuar a segurar o tabuleiro: o toque numa casa, o arrastar e a pinça.
   - A coluna «sem o D1» mostra o que os botões dariam nesse caso (1 toque). Ela mede o ficheiro antigo, que deixa passar
     tudo, e não uma correcção dessas. Não a construí nem a medi: não é desta ordem.
2. **O arrastar e a pinça como primeiro gesto perdem-se inteiros** (§3). É o mesmo +1 (repetir o gesto). O Mestre pode
   querer decidi-los à parte dos botões, porque o arrastar e a pinça não dão ordens ao jogo: só mexem a câmara.
3. **Achado à margem: com a lista aberta por toque, o rato não a fecha** (§3). Num aparelho com toque e rato, a lista
   aberta por toque só fecha com outro toque: o rato a sair, ou um clique fora, não a fecham. Já era assim antes da F14
   (a medição sem o D1 dá o mesmo). Não é custo do D1, por isso não entra nas contas do §4. Fica registado, porque é a
   pergunta «o rato muda alguma coisa?».
4. **Este PC não tem ecrã de toque**, como na F14 e na F27. Os toques são os que o motor recebe de um aparelho
   (`ScreenTouch`/`ScreenDrag` pelo `Input`, com a imitação do rato). Um telemóvel a sério não foi medido.
5. **A primeira corrida sem o D1 deu 28 erros de medição.** A ferramenta escrevia uma variável que o `caixa_ordem.gd`
   antigo não tem (`_engolir_toque`). Corrigi a ferramenta: agora só a escreve se ela existir. As corridas entregues têm
   0 erros. A corrida com erros não se cometeu.
6. **A medição não entra no CI.** É uma ferramenta de `provas/`, como a da prova viva. Não mudei nenhuma suite nem o
   workflow. A `caixa_jogadora` continua com **70/70** neste PC.
