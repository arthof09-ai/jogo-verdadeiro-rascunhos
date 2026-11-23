# ESTADO FINAL — ORDEM-CAIXA-EXPANDE (Claude conta 2, PC · 22/11/2026)

**Linha:** `fable/integracao-50`, trabalho directo, sem ramo lateral e sem fusão. Parti da ponta `a271c6d`. Antes de
publicar fiz `fetch`: a linha tinha andado para `ff6d69f` (a ORDEM-CAIXA-JANELA-CI, ver §7, ponto 1). Fiz `rebase`
sem conflito. Commits:
1. `878b13e` — código, testes e provas (a caixa compacta, a vista expandida, a recentragem F4, os tectos novos);
2. `0e81bbc` — o guião de mutação da CAIXA-JANELA-CI acertado com a caixa nova (114 de 123);
3. este ESTADO-FINAL, com as listas da retoma sincronizadas.

Este ficheiro não tem nomes verdadeiros, nem pedaços deles, nem o valor de nenhum PIN (§6).

## 1. O que foi construído (`hud/caixa_ordem.gd`, `hud/hud.gd`)

### A vista compacta (a regra do Mestre, 23:10)
- **O cartão grande é só de quem está a jogar agora**, e o nome a ouro só aparece nele. As caixinhas pequenas
  levam a moldura fina e o nome a pergaminho, todas iguais.
- **As caixinhas pequenas são os próximos a jogar, no máximo 4** (`MAX_FILA = 4`, a escolha do coordenador). Contam a
  partir de quem vem depois da vez e dão a volta à ordem. A figura na vez nunca aparece nelas. Quando a vez passa,
  quem jogou sai do cartão grande e vai para o fim da fila (`proximos`, com um teste próprio). A ordem é a mesma que
  o servidor projecta (dinâmica ou de iniciativa). A caixa só decide o que mostra.
- Com menos de 5 figuras há menos caixinhas: 4 figuras dão 3, e ninguém se repete. Sem ninguém na vez (no modo
  dinâmico, antes de alguém agir) não há cartão grande, e as caixinhas são as 4 primeiras da ordem.
- Os quadradinhos mantêm a célula fixa da pilha da estética (46×60 px na janela da prova). Os nomes compactos
  continuam cortados com «…».

### A vista expandida
- **Com o rato por cima, a caixa cresce** e mostra a ordem completa. A figura na vez vem primeiro, depois as outras
  pela ordem em que vão jogar, até dar a volta. Todas as linhas têm o retrato (a mesma textura da compacta) e o
  **nome completo, sem corte**. A figura na vez vem realçada como no cartão grande: moldura grossa, nome a ouro e
  «na vez». **Ao tirar o rato, volta** ao tamanho compacto.
- **Nos aparelhos de toque**, um toque na caixa abre a mesma vista e outro toque fecha-a. Um toque fora dela
  também a fecha.
- As cores são só as da tabela: painel escuro, moldura dourada, letras pergaminho. Não entrou nenhuma cor nova. A
  prova confere-o em todos os momentos, também com a expandida aberta.
- **Privacidade:** a expandida só mostra o que a compacta já mostra, isto é, os nomes (os que o HUD já recebia) e a
  ordem. Não entra vida, alma, PA nem nada do Mestre. A prova corre `_privacidade` com a expandida aberta e dá 4/4.
- **O mesmo componente serve o ecrã do Mestre** (`cenas/mestre/mestre.gd`), por isso o comportamento aplica-se lá
  também. No HUD da jogadora a caixa cresce para a esquerda e para baixo, encostada ao canto superior direito. No ecrã
  do Mestre cresce para a direita e para baixo, a partir do sítio onde está, e a altura vai até ao fundo do ecrã. O
  ecrã do Mestre decide o sítio da caixa pelo tamanho compacto. Lá os nomes são os que o Mestre já via.

## 2. Como a expansão se comporta (rato e toque)
- **O rato.** A caixa lê os movimentos do rato no `_input`, antes do tabuleiro, e não consome nada. Abre quando o
  rato está dentro dela e fecha quando sai (ou quando o rato sai da janela). Os movimentos que o motor **imita** a
  partir de um toque (`DEVICE_ID_EMULATION`) não abrem a caixa, porque senão um toque deixava-a aberta «por hover».
- **O toque.** Abre ou fecha quando o dedo levanta dentro da caixa, a menos de 0,6 letras do sítio onde tocou.
  Arrastar mais do que isso é rolar a lista, e não abre nem fecha.
- **Os cliques e toques em cima da caixa ficam na caixa.** O painel passou de `MOUSE_FILTER_IGNORE` a `STOP`: o
  tabuleiro não recebe um toque dado em cima da caixa, e um toque para abrir a lista não move uma figura por baixo.
  Fora da caixa nada muda. Os filhos continuam a ignorar o rato, menos o botão do Mestre e a lista que rola.
- **A faixa não se mexe** com a expandida aberta, porque o HUD arruma a faixa pelo tamanho **compacto**. A
  expandida fica acima da barra e não tapa a faixa nem a ⚙ (medido, §3).
- Na suite está provado com eventos do motor (`push_input`): o rato a sério abre e fecha, o rato imitado não abre, um
  toque abre, outro fecha, um toque fora fecha, e arrastar não abre. Na prova viva também (passos 6 e 7).

## 3. Ecrãs baixos com 8+ figuras
As linhas da expandida medem 2,4 letras (`LADO_LINHA_EM_LETRAS`). A altura máxima vai até ao topo da barra. Se a
ordem não couber, **a lista rola por dentro** (com a roda do rato ou a arrastar); a caixa nunca passa a barra.

| figuras | ecrã | expandida (u) | linhas à vista sem rolar | rola | nomes cortados |
|---|---|---|---|---|---|
| 8 | 844×390 | 689×786 (fundo a 810 u, barra a 955 u) | 8 de 8 | não | nenhum |
| 8 | 780×360 | 744×854 (fundo a 878 u, barra a 946 u) | 8 de 8 | não | nenhum |
| 12 | 844×390 | 689×913 | 9 de 12 | sim | nenhum |
| 12 | 780×360 | 744×903 | 8 de 12 | sim | nenhum |
| 16 | 844×390 | 689×913 | 9 de 16 | sim | nenhum |
| 16 | 780×360 | 744×903 | 8 de 16 | sim | nenhum |
| 9 (prova viva) | 844×390 | 686×876 | 9 de 9 | não | nenhum |
| 9 (prova viva) | 780×360 | 744×903 | 8 de 9 | sim | nenhum |

- Estes números são da suite `caixa_janela` (sem ecrã) e da prova viva (janela a sério).
- As linhas medem 86 u em 844×390 e 94 u em 780×360, que são **31 px reais** nos dois ecrãs.
- **Até 8 figuras, a expandida cabe inteira nos dois ecrãs baixos.** Com 9 a 16 figuras, em 844×390 cabem 9 à vista e
  em 780×360 cabem 8; as outras vêem-se a rolar. A captura `8-expandida-780x360-fim.png` mostra a lista rolada até à
  última figura.
- **Nomes que não cabem:** em nenhuma medição houve uma linha cortada. A ordem da suite inclui de propósito um nome
  público de 33 letras, e cabe inteiro nos 3 ecrãs.
- O limite está declarado no código: a expandida não fica mais larga do que a largura que a caixa já pode ter (a que
  deixa a faixa livre). Uma linha cujo nome passe dessa largura corta com «…», e `linhas_cortadas()` diz qual é. A
  suite falha se isso acontecer.

## 4. A recentragem da faixa (F4) e os tectos novos (`hud.gd faixa_recentrada`, `testes/caixa_jogadora.gd`)
- **A regra nova.** A faixa fica **o mais perto do centro do ecrã que o espaço livre entre a ⚙ e a caixa deixa**,
  sem encolher a caixa:
  - se a faixa larga, centrada no ecrã, cabe com a largura de que precisa, as margens são iguais (desvio 0);
  - se não cabe, a faixa fica com a largura de que precisa e encosta-se ao lado mais perto do centro;
  - se nem essa largura cabe, ocupa o espaço livre todo, como antes.

  A suite testa a conta pura em 3 casos (§9 da `caixa_jogadora`).
- **Medi as duas mudanças em separado** (8 figuras, `caixa_jogadora` §8; `corrida-tecto.log`):
  1. A caixa compacta: 4 caixinhas em vez de uma por figura. Isto vem da regra do Mestre, não da recentragem. Com ela
     e a regra antiga da faixa, o desvio seria 0,0 / **313,5** / 0,0 u: em 780×360 a faixa larga centrada não cabe
     por 23 u, e a regra antiga punha-a no meio entre a ⚙ e a caixa.
  2. A recentragem: em 780×360 a faixa fica com os 788 u de que precisa, encostada à caixa, e o desvio passa de
     313,5 para **11,5 u**. Nas outras duas resoluções a faixa já ficava centrada.

| resolução | caixa antes → agora (u) | desvio antes → agora (u) | diferença |
|---|---|---|---|
| 844×390 | 1193 → 689 | 542,5 → **0,0** | −542,5 |
| 780×360 | 1292 → 744 | 587,5 → **11,5** | −576,0 (−313,5 só pela recentragem) |
| 1920×1080 | 753 → 437 | 343,5 → **0,0** | −343,5 |

- **Os tectos novos são 0,0 / 11,5 / 0,0 u** (eram 542,5 / 587,5 / 343,5). A justificação está escrita no teste: «não
  pior que a caixa compacta recentrada».
- **Sensibilidade** (`provas/ordem-caixa-expande/tecto/sensibilidade.log`): baixei um só tecto 0,5 u por corrida.
  Deu 41/42 e rc 1 nas três corridas, e em todas falhou **exactamente** a guarda dessa resolução. Com os três
  baixados, deu 39/42.
- **A variante estrita** (`-- --estrita`, o critério de ≤ 1 u) dá 41/42: só falha 780×360, com 11,5 u.
- **Na prova viva** (passo 9, a janela muda de tamanho a sério, 9 figuras) mediu-se 0,0 / 11,5 / 0,0 u, dentro dos
  tectos. A faixa não toca na caixa. As caixas compactas mediram 686 / 744 / 434 u. A diferença de 3 u para a suite
  vem do nome do cartão grande, que é outro.

## 5. Os números das corridas
Godot 4.7.2, Windows 11, RTX 4060. As suites correram com `--headless`, como no CI.

| passo do cliente | resultado |
|---|---|
| `abrir_scripts` | 108 scripts, 0 falhas |
| `rodar_testes` | **321/321** (eram 311; +10 da caixa: próximos, ouro só no cartão, a fila anda, expandida, rato, toque) |
| `caixa_janela` | **123/123** (eram 78; +45: a expandida em 8/12/16 figuras × 3 ecrãs; os slots passam a ser os 4 próximos) |
| `caixa_jogadora` | **42/42** (eram 36; +6 do §9: a conta da recentragem e o toque no HUD); estrita 41/42 |
| `abrir_clareira` | 22/22 |
| `medir_painel_config` | 0 falhas, 0 sem medida |
| `abrir_mestre` / `pecas_mestre` | 67/67 · 286/286; comandos contra os schemas: 9 e 26 mensagens, 0 falhas |
| `medir_mestre` | 0 falhas, 0 sem medida |
| `hud_acoes` | 50/50 |
| `teste_relato_caixa` / `teste_nomes_relato` | 31/31 · 26/26 |
| `canario_privacidade` | 10/10 |
| arranque da cena principal | chega a «pronto», 0 erros de script |
| erros de script em todos os passos | 0 |
| guião de mutação da CAIXA-JANELA-CI | as 9 falhas da B6, «114 de 123», 0 erros, ficheiro reposto |

**A prova viva dá 171/171** (`provas/ordem-caixa-expande/cliente/`, o README tem os SHA). Cliente real pela Rede,
servidor de mesa real com o motor VLAB real (`a91c021c…`), semente 7, manequim `andar-v3.glb` com o SHA conferido e
nenhuma cápsula à vista. Por passo:

| passo | verificações | o quê |
|---|---|---|
| 0 | 1 | batalha a meio |
| 1 | 22 | |
| 2 | 20 | |
| 3 | 4 | |
| 4 | 22 | |
| 5 | 20 | |
| 6 (a) | 17 | rato → expandida |
| 7 (b) | 31 | 9 figuras e o toque |
| 8 (c) | 18 | ecrãs baixos |
| 9 (d) | 6 | F4 nas 3 resoluções |
| 10 | 9 | os casos do retrato |

Há ainda 1 verificação na abertura do manequim. Os passos 1, 2, 4 e 5 têm agora a verificação da compacta.

Vi as capturas:
- **compacta** (4: o cartão da Arqueira a ouro e 3 caixinhas a pergaminho);
- **6** (a expandida com 4 nomes inteiros);
- **7** (9 linhas, «Espadachim de Bancada» inteiro);
- **8 em 780×360** (8 linhas à vista e a nona a meio, a rolar);
- **9 em 780×360** (a faixa «O Mestre narra» quase ao centro, a caixa compacta com o cartão e 4 caixinhas).

**Listas da retoma:** corri o `actualizar-listas.py` depois do commit 2. Deu 0 novos e 0 tirados (só mudam os SHA
de 6 ficheiros). O `depois.txt` e o `MANIFESTO-SHA256.txt` vão sincronizados no commit 3.

## 6. Privacidade: o conferidor estrito nos dois critérios

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-caixa-expande/README.md` | **0 / 0** | 0 |
| as linhas que acrescentei a `hud/`, `cenas/mestre/` e aos testes (só o `+` do diff) | **0 / 0** | 0 |
| as linhas novas da ferramenta da prova, contra a da CAIXA-PADRAO-CORRECOES | **0 / 0** | 0 |
| `tecto/corrida-tecto.log`, `tecto/sensibilidade.log` | **0 / 0** | 0 |
| `expandida/caixa_janela.log`, `mutacao/mutacao-celulas.resumo.txt` | **0 / 0** | 0 |
| o guião `mutacao-celulas.sh` (depois do meu acerto) | **0 / 0** | 0 |
| a ferramenta da prova, inteira (herdada) | 53 / 53 | 0 |
| o lançador da prova (herdado) | 2 / 2 | 0 |
| `cliente/relato.txt` | 108 / 108 | **0** |

Os achados que sobram são do mesmo tipo dos da CAIXA-PADRAO-CORRECOES:
- **a ferramenta e o lançador** nomeiam os ficheiros da casa e levam o texto herdado. A ferramenta continua com os
  mesmos 53 da anterior;
- **o relato** imprime os nomes **públicos** das figuras, que são o que a caixa mostra. Subiu de 67 para 108 porque
  agora há 9 figuras e as listas da expandida: os mesmos nomes, mais vezes.

Não há nenhum nome verdadeiro inteiro, nenhum PIN, e nada de vida, alma, PA ou dados do Mestre. Para a ferramenta
procurar as criaturas a pôr em campo, tirei os literais das fichas: lêem-se do cenário.

## 7. Pontos para o coordenador
1. **Duas ordens no mesmo território ao mesmo tempo.**
   - A ORDEM-CAIXA-JANELA-CI (conta 1) publicou `02267d1` e `ff6d69f` enquanto esta corria. Não houve conflito no
     rebase.
   - O guião de mutação dela esperava «69 de 78». Com a caixa nova a suite tem 123 verificações e o guião deixava de
     apanhar a mutação como devia. A mutação era apanhada (as 9 falhas), mas a frase que ele procura tinha mudado.
     Acertei o guião («114 de 123», a frase contígua) no commit 2.
   - O remendo do CI dela (por aplicar) continua válido tal como está: exige «N de N». Se o quiseres fixo, o número é
     `^123 de 123`.
2. **Uma figura posta a meio da luta (MASTER_PLACE em combate) não entra na `iniciativa` da jogadora até ao snapshot
   seguinte.** O cliente só lê a `iniciativa` no ROOM_SNAPSHOT, e a colocação chega como evento. A caixa dela fica sem
   a figura nova até lá. Isto é servidor e protocolo, fora do meu território, por isso não lhe toquei. Na prova, a
   escolha da caixa pelo Mestre (que manda um snapshot) vem depois das colocações.
3. **A caixa passou a apanhar os cliques e toques em cima dela** (`MOUSE_FILTER_STOP`). É preciso para o toque
   abrir e fechar sem mexer no tabuleiro por baixo. A verificação antiga «não rouba os toques ao tabuleiro» foi
   substituída por «só o painel apanha, os filhos não». Se o Mestre preferir que o tabuleiro receba também o toque,
   isso volta a IGNORE, e o toque passa a mexer as duas coisas.
4. **780×360: o desvio é 11,5 u, não 0.** A faixa larga centrada não cabe por 23 u. Chegar a 0 obrigava a encolher a
   caixa, o que a F4 proíbe, ou a frase mais comprida da faixa (a da pausa).
5. **O toque e o arrastar provaram-se com eventos do motor** (`InputEventScreenTouch` por `push_input`), na suite e
   na prova viva. **Não houve aparelho de toque a sério** nesta máquina. A roda do rato e o arrastar para rolar são os
   do `ScrollContainer` do Godot, sem medida em telemóvel.
6. **A barra de rolagem é discreta** no tema de agora. Em 780×360 o que mostra que a lista continua é a nona linha
   cortada a meio (`8-expandida-780x360.png`). Se o Mestre quiser a barra mais visível, é uma cor do tema, e isso é
   decisão dele (nada de cores novas aqui).
7. **O ecrã do Mestre não foi medido com 8+ figuras em ecrã baixo com a expandida aberta.** O `medir_mestre` passa
   (0 falhas), mas a expandida, ao crescer para baixo, pode passar por cima da folha do Mestre enquanto o rato lá
   estiver. Fecha ao sair o rato.
8. A janela da prova pede 1280×720 e o sistema dá-lhe 1028×720, como na prova anterior. Nos passos 8 e 9 a janela
   muda de tamanho a sério (844×390, 780×360 e 1920×1080) e confere-se que ficou com o tamanho pedido.

<b>Estado: NOVA</b>
