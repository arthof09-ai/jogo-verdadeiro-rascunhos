# ESTADO-FINAL — Ordem F64 da sentença da F28 (as melhorias da ferramenta de medição do D1)

**Coordenador:** CM-000009. **Executor:** Claude (opus, esforço médio), PC do cunhado. **Data:** 23/11/2026.
**Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.

**Partida.** Clonei a linha às 04:15 e o `HEAD` era `65e5dd2` (`65e5dd2958fb65b173c7116a556eff4bbf351a34`, a nota do CI
da F61), igual à origem. As medições assentam em `65e5dd2`. No `push` da obra, a linha não tinha andado.

**Commits:**
1. `ee37792`: a obra (a ferramenta com as L1–L3, os dois logs `-f64`, o `resumo-f64.txt`, o script que o escreve e o
   README da pasta);
2. este ESTADO-FINAL;
3. a nota do CI da ponta do commit 2, acrescentada ao §5 (só documento).

**Esta ordem só mexe na prova e não muda nenhum ficheiro do jogo.** Só mudou `provas/ordem-f28-custo-d1-hud/` e este
ficheiro. Não há nenhum nome verdadeiro inteiro nem valor de PIN neste ficheiro (§6).

## 0. Antes de começar
- **A sentença não está neste PC.** Não há `~/workspace`, por isso não existe
  `~/workspace/conferencias/f28-custo-d1-hud/SENTENCA-F28-CUSTO-D1-HUD.md`, como já acontecia na F51 e na F61. Trabalhei
  com as L1–L4 tal como a ordem as cita (ponto 1 do §7).
- **A L4 (a câmara reposta entre casos) já é da F61.** Usei a versão dela tal como está (`_guardar_camara` e
  `_repor_camara`, cometidas em `c1a1988`) e não lhe mexi.
- **Biblioteca (GameDev Kit):** vi as 10 pastas da BIB e o estudo dela (`ESTUDO-BIBLIOTECA.md`). Não há nada que meça
  gestos nem registe o estado de um HUD. O phantom-camera da bib 9 é uma câmara de jogo, não um instrumento. Por isso,
  as linhas novas são funções da própria ferramenta, que só lêem o estado. O único ficheiro novo é um script de 31 linhas
  que escreve o resumo, no padrão do `resumo_corrida2.sh` da F61.

## 1. As fragilidades e as linhas novas
Ferramenta: `provas/ordem-f28-custo-d1-hud/ferramentas/medir_custo_d1_hud.gd`. **A F64 só acrescenta linhas ao registo.**
As linhas TABELA, a contagem de casos (62) e a ordem dos casos antigos ficam como estavam. Os casos novos correm no fim
de todos os casos de um ecrã, depois da jogada típica.

### L1 — a casa passa a ter uma linha MEDIDA própria
- `_casa(tam)` abre o Mover com um toque e mede o toque numa casa do Mover em dois casos: com a lista aberta por toque
  e de controlo, com a caixa fechada.
  - **O ponto é o mesmo nos dois casos.** `_sitio_casa()` escolhe-o com a lista aberta, fora do HUD e da expandida, e o
    controlo usa-o outra vez. Nos dois ecrãs, é a casa (7, 11).
  - Toca-se até a intenção «mover» sair, no máximo 4 vezes.
- A linha é `MEDIDA CASA <ecrã> (<caso>)`. Diz o resultado do 1.º toque e quantos toques foram precisos até a figura ser
  mandada mover. O resultado é um de três: «a casa fecha a lista sem mover a figura», «a casa fecha a lista e move a
  figura» ou «a casa move a figura».
  - «Mover» quer dizer que a intenção «mover» entrou na fila. Sem servidor, o movimento não se aplica, e a linha
    `PARTIDA`/`DEPOIS` mostra que a figura continua na casa (10, 10).
- A casa não entra na TABELA, para a tabela continuar a da F28 (ponto 2 do §7).

### L2 — a pinça passa a medir o deslocamento, não só o zoom
- A linha `MEDIDA PINÇA` passa a dizer também quanto o foco da câmara andou (em metros), e o rumo e a inclinação antes e
  depois.
- **Há uma 2.ª pinça nova, `MEDIDA PINÇA A DESLOCAR`.** A pinça da F28 é simétrica: os dois dedos afastam-se, e o meio
  fica quase parado. No controlo, ela só desloca a câmara 0,028 m, porque a pinça da câmara (`camera_mesa.gd`,
  `_atualizar_pinca` → `_deslocar(meio − _pinca_meio)`) só desloca quando o meio dos dedos anda.
  - Um 0 com a lista aberta só prova alguma coisa se a mesma medida der um número grande no controlo.
  - Na pinça nova (`_pinca_a_deslocar`), os dedos afastam-se os mesmos 100 u e o meio anda 60 u para a esquerda: o 1.º
    dedo anda 22 u por passo e o 2.º anda 2 u, durante 5 passos.
  - No controlo, a câmara desloca-se 0,854 m. Agora o «nem desloca» mede-se.

### L3 — o estado de partida fica registado
- **Antes do gesto medido, uma linha `PARTIDA <caso>` regista o estado.** Os campos são estes:
  **Errata do coordenador (F80, 23/11/2026): a PARTIDA é pós-preparação, antes do gesto medido — não «antes do caso».**
  - a caixa (compacta, expandida, ou expandida por toque);
  - o modo da arena;
  - a gaveta (fechada ou à vista, e de que modo);
  - os painéis abertos (Configurações, escolha, ficha);
  - a figura dela e a casa onde está;
  - o cursor da arena;
  - a declaração do Mover;
  - a fila (quantas intenções e qual acção);
  - a câmara (foco, zoom, rumo e inclinação).
- **Depois do gesto, as linhas `DEPOIS <caso> (…)` dizem o que mudou em relação à partida.** Nos botões e na casa, há uma
  ao 1.º toque e outra no fim. Nos outros casos, há uma no fim.
- Há `PARTIDA`/`DEPOIS` em todos os casos: os 15 botões, o arrastar, as duas pinças, a roda, o rato, a jogada típica e a
  casa.
- **Sobre «que figura está seleccionada».** O cliente não tem um estado de figura seleccionada. O jogo guarda a figura
  dela (`Estado.minha_figura_id`, sempre a mesma), o modo da arena (Mover, Ataque, Consumível) e o cursor das casas.
  Registo os três (ponto 3 do §7).
- As funções (`_estado_agora`, `_mudou`, `_partida`, `_depois`) só lêem: não esperam quadros nem mexem em nada. Por
  isso, os números antigos não mudam (§2).

### L4 — a câmara reposta entre casos
É a da F61, sem mudança. O log volta a dizer, na 2.ª linha `==`, o estado reposto: modo 0, foco (0.75, −0.085, 0.75),
zoom 1,500, rumo 0,0 e inclinação 55,0.

## 2. Antes / depois
**As medições:** os 62 casos, em 844×390 e 780×360, com o Godot 4.7.2 `_console.exe --headless` no Windows 11.
- Na ponta, com o D1: `medicao/medir_custo_d1_hud-f64.log`.
- Sem o D1: `medicao/medir_custo_d1_hud-sem-d1-f64.log`.
  - Pus o `caixa_ordem.gd` de `0bebd76` só na cópia de trabalho e repu-lo a seguir com `git checkout`.
  - Depois de o repor, o `git diff` ficou vazio e o SHA do ficheiro é `cc26f56c…`, igual ao do `HEAD`.
- `medicao/resumo-f64.txt` escreve-se com `bash ferramentas/resumo_f64.sh <raiz> 0 0 65e5dd2`.

| ficheiro | rc | casos | erros | linhas MEDIDA | TABELA | PARTIDA | DEPOIS | `error`/`warning` | sha256 |
|---|---|---|---|---|---|---|---|---|---|
| `medicao/medir_custo_d1_hud-f64.log` (na ponta) | **0** | **62** | **0** | 70 (62 + 8) | 62 | 100 | 164 | 0 | `8e194fe05fe0…` |
| `medicao/medir_custo_d1_hud-sem-d1-f64.log` (sem o D1) | **0** | **62** | **0** | 70 (62 + 8) | 62 | 100 | 164 | 0 | `47f00b7e7ea3…` |

`resumo-f64.txt` tem o sha256 `1eb59bd729bb…`.

**As tabelas não mudaram.** Comparei as linhas TABELA da 2.ª corrida da F61 com as da F64: diferem 0 de 62 na ponta e
0 de 62 sem o D1, byte a byte. Incluem o deslocamento do arrastar (`2.26925158500671`).
- Os 15 botões continuam a custar +1 toque com o D1 e 1 toque sem ele.
- O arrastar e a pinça continuam perdidos inteiros com a lista aberta: 0,000 m e zoom 1,500 → 1,500.
- A roda, o rato e a jogada típica (4 / 6 / 6 com o D1, 4 / 5 / 5 sem ele) dão o mesmo.

**As linhas novas** são iguais nos dois ecrãs:

| medida nova | caso | na ponta (com o D1) | sem o D1 |
|---|---|---|---|
| CASA, 1.º toque | lista aberta | **fecha a lista sem mover a figura**; 2 toques até mover | fecha a lista **e move** a figura; 1 toque |
| CASA, 1.º toque | controlo | move a figura; 1 toque | move a figura; 1 toque |
| PINÇA (simétrica) | lista aberta | zoom 1,500 → 1,500; **0,000 m**; rumo e inclinação iguais | zoom 1,500 → 3,000; 0,028 m |
| PINÇA (simétrica) | controlo | zoom 1,500 → 3,000; 0,028 m | zoom 1,500 → 3,000; 0,028 m |
| PINÇA A DESLOCAR | lista aberta | zoom 1,500 → 1,500; **0,000 m** | zoom 1,500 → 2,963; 0,854 m |
| PINÇA A DESLOCAR | controlo | zoom 1,500 → 2,963; **0,854 m** | zoom 1,500 → 2,963; 0,854 m |

**O que as linhas PARTIDA/DEPOIS mostram:**
- **Na ponta, nos 32 casos com a lista aberta** (15 botões e a casa, nos dois ecrãs), a linha «ao 1.º toque» muda uma
  só coisa: `caixa: expandida por toque → compacta`. Os painéis, o modo, a gaveta, a fila, a figura e a câmara ficam como
  estavam na partida. Antes da F64, esta parte do «o 1.º toque só fecha a lista» lia-se no código; agora está registada.
- **Sem o D1, nos mesmos 32 casos,** o 1.º toque fecha a lista e logo faz a acção. Exemplos: abre o modo, põe a intenção
  na fila (mover, correr, apagar_fogo, defender, encerrar), abre ou fecha o painel, liga a declaração, repõe o zoom.
- No fim, a figura dela continua na casa (10, 10) em todos os casos, nas duas medições.

## 3. Duas coisas que o registo do estado mostrou
Nenhuma das duas é custo do D1: são iguais com e sem o D1.
1. **O cursor das casas passa de um caso para o seguinte.**
   - O `_repor` não repõe `arena._cursor`. Na partida, o cursor está em (−1, −1) só no 1.º caso, em (10, 10) em 89
     casos e em (6, 11) em 10 casos, igual nas duas medições.
   - O cursor só pinta o destaque da casa sob o rato no Mover. Não entra em nenhuma das decisões medidas (nem no
     `_ao_toque` nem no `_escolher_casa`).
   - Não o repus, porque a ordem não o pede e a L4 é a da F61 (ponto 4 do §7).
2. **Sem servidor, depois de uma intenção do Mover, a gaveta fica à vista e passa a ser «de nenhum modo».**
   - Ao mandar a intenção, a arena (`enviar_acao`) chama `hud.fechar_gaveta()` antes de `hud.ao_modo_mudou()`. Por
     isso, quando a gaveta é recalculada, o HUD ainda está no Mover e a gaveta fica à vista. Só a esconde no
     `_atualizar` seguinte, que num jogo a sério chega com o ROOM_OPTIONS do servidor.
   - É do palco sem servidor, e o registo di-lo tal como está.

Também há uma falha de redacção na ferramenta: o campo da gaveta escreve «de o Mover» em vez de «do Mover». É só o
texto do registo e não muda nenhuma medida. Não a corrigi depois do `push`, para os logs cometidos saírem da
ferramenta tal como ficou cometida.

## 4. Nada se partiu
**Neste PC, sobre a obra** (Godot 4.7.2 Windows, os mesmos comandos do CI):

| suite | resultado | rc | `SCRIPT ERROR` / `Parse Error` / `Compile Error` |
|---|---|---|---|
| o canário (`teste_nomes_relato.gd`) | **26 de 26** | 0 | 0 |
| `rodar_testes` | **321 de 321** | 0 | 0 |
| `caixa_janela` | **123 de 123** | 0 | 0 |
| `caixa_jogadora` | **70 de 70** | 0 | 0 |
| mutação das células (`mutacao-celulas.sh`) | **114 de 123**, 9 falhas, todas do assert B6, «MUTACAO APANHADA» | 0 | 0 |

- A mutação repôs o `caixa_ordem.gd`: o `git diff` ficou vazio.
- As saídas cruas ficaram em `tmp/suites/`, fora do repo, porque o canário imprime nomes inteiros de propósito.
- A obra não muda nenhum ficheiro que as suites leiam: só mexe em `provas/ordem-f28-custo-d1-hud/`.

## 5. CI
**CI da ponta `ee37792` (a obra): verde.**
- **Testes dos rascunhos**, run `45130771243`: passaram os 10 jobs (`servidor`, `validador-glb`, `motor-real`,
  `protocolo`, `cliente`, `godot-cliente`, `ponta-a-ponta`, `provas-mapa`, `foto-mestre` e `retoma-pc`).
- **Sonda de privacidade**, run `45130771438`: verde.
- **Os números do log do run:**
  - o canário deu «26 de 26», e o auto-teste da redacção deu 12 de 12;
  - `rodar_testes` 321/321, também no `godot-cliente`;
  - `caixa_janela` 123/123;
  - `caixa_jogadora` 70/70;
  - a mutação das células deu «114 de 123» e «MUTACAO APANHADA: 9 falhas, todas do assert B6».
- O `retoma-pc` ficou verde, o que confirma que as listas da retoma batem certo sem mudar.

**CI da ponta `b3fcc74` (a obra mais este ESTADO-FINAL): verde.**
- Testes dos rascunhos, run `45131224957`: passaram os 10 jobs.
- Sonda de privacidade, run `45131225197`: verde.
- Os números são os mesmos: canário 26/26 (redacção 12/12), `rodar_testes` 321/321 (também no `godot-cliente`),
  `caixa_janela` 123/123, `caixa_jogadora` 70/70 e mutação das células «114 de 123».
- O commit desta nota só acrescenta este parágrafo a este ficheiro.

## 6. Privacidade re-derivada
Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, nos dois critérios (alargado e `--velho`).
Na coluna dos nomes inteiros conta-se um achado cujo pedaço tem o comprimento do nome inteiro.

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-f28-custo-d1-hud/README.md` | **0 / 0** | 0 |
| `ferramentas/medir_custo_d1_hud.gd` | **0 / 0** | 0 |
| `ferramentas/resumo_f64.sh` | **0 / 0** | 0 |
| `medicao/resumo-f64.txt` | **0 / 0** | 0 |
| `medicao/medir_custo_d1_hud-f64.log`, `medicao/medir_custo_d1_hud-sem-d1-f64.log` | 2 / 2 por log | **0** |

- **Os dois logs** têm 2 / 2 numa só linha que eu não escrevi: a 3.ª, o relatório de carga do mapa da floresta
  (`[floresta] pronta em … ms | {…}`). São pedaços de 5 letras de nomes de 16 e de 15. São os mesmos achados, e na
  mesma linha, dos logs da F28 e da F61, que foram aceites: palavras correntes, não nomes.
- **As linhas novas** (`MEDIDA CASA`, `PINÇA A DESLOCAR`, `PARTIDA`, `DEPOIS`) não trazem nenhum achado. A figura
  aparece pelo id (`j1`), não pelo nome.
- **Nomes verdadeiros inteiros: 0** em todos os ficheiros da obra e neste ESTADO-FINAL.
- **PIN: 0.** Esta ordem não arrancou o servidor, por isso não houve PIN nem `--pin=`. Procurei números de 20
  algarismos (a forma do PIN) nos ficheiros desta ordem e não há nenhum.
- **As listas da retoma:** corri `python retoma-i0004/actualizar-listas.py` e deu «0 novos, 0 tirados», sem mudar
  nenhum ficheiro. As listas só cobrem `rascunhos/`, e nenhum ficheiro de `rascunhos/` mudou. Nenhum SHA mudou, por isso
  não houve nada a sincronizar.

## 7. Pontos abertos para o coordenador
1. **A sentença da F28 não está neste PC.** Se ela definir as L1–L4 de outra maneira, é preciso conferir. Por exemplo,
   pode querer a casa como linha TABELA ou outro estado de partida.
2. **A casa não entrou na TABELA.** A ordem pede uma linha MEDIDA e, ao mesmo tempo, «as mesmas tabelas da F28». Escolhi
   a leitura que não muda a tabela: a casa tem a sua linha MEDIDA e aparece no `resumo-f64.txt`, mas a TABELA continua
   com 62 linhas. **Decisão do coordenador (F77, 23/11/2026): a casa fica FORA da TABELA** — a comparabilidade 62↔62 vale mais; o conteúdo está nas linhas `MEDIDA CASA` e no `resumo-f64.txt`.
3. **«A figura seleccionada» não existe no cliente.** Registo a figura dela, o modo da arena e o cursor. Se a sentença
   quiser outra coisa com este nome (por exemplo, o alvo escolhido no Ataque), é preciso dizer qual.
   **Decisão do coordenador (F83, 23/11/2026): «figura seleccionada» fica pelo substituto** (figura dela + modo + cursor), com a ressalva registada — se a sentença da F28 quiser dizer «alvo no Ataque», reabre-se como trabalho novo.
4. **O cursor passa de um caso para o seguinte** (§3). Repô-lo no `_repor` seria mudar a reposição entre casos, que é da
   F61, e a ordem diz para não a repetir. **Decisão do coordenador (F78, 23/11/2026): a partida do cursor fica registada como não-neutra** (10/100 PARTIDA com (6, 11) residual); repô-lo no `_repor` (uma linha) fica para a próxima ordem que mexer na ferramenta.
5. **A pinça a deslocar é um gesto novo.** Escolhi um meio que anda 60 u, para o controlo dar um número grande. Os
   valores (22 u e 2 u por passo) são meus, e não vêm de nenhum aparelho.
6. **Este PC não tem ecrã de toque.** Como na F28, os toques são os que o motor recebe de um aparelho.
