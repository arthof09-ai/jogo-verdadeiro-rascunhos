# ESTADO-FINAL — Ordem CAIXA-EXPANDE-VISTAS (ID ORDEM-CAIXA-EXPANDE-VISTAS-2026-11-22)

**Dono:** Claude conta 2, no PC do cunhado. **Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.
**Partida:** `8b78867`, a ponta deixada pela ORDEM-CAIXA-EXPANDE-INTERACAO (a F14, entregue: o ESTADO-FINAL dela e o CI
verde de `4a33152` estão na linha). Fiz `fetch` antes do commit 1 e outra vez antes do push: a linha não tinha andado.

**Commits:**
1. `53c2945` — o código (D4), a suite `medir_mestre`, o passo 12 da prova viva (D2), as ferramentas e as provas.
2. o commit deste ESTADO-FINAL, com as listas da retoma sincronizadas.
3. o commit que acrescenta o resultado do CI da ponta ao §5 (só documento).

Este ficheiro não tem nomes verdadeiros, nem pedaços deles, nem o valor de nenhum PIN (§6).

## 1. O que mudou

**`rascunhos/cliente/cenas/mestre/mestre.gd`** (o único ficheiro do jogo tocado; `hud/caixa_ordem.gd` não mudou):
- **O tecto da largura.** `_posicionar_caixa` passa a chamar `_caixa.limitar_largura(...)` até ao fim do tabuleiro, menos
  meia letra. É o mesmo mecanismo de tecto do HUD. Com ele, o `teto` de `_aplicar_vista` deixa de ser `INF` no ecrã do
  Mestre: a caixa, compacta ou expandida, nunca passa para a folha.
  - Se a fila da compacta não couber, parte em linhas.
  - Na expandida, se um nome não couber, corta-se com «…», como no HUD.
- **A protecção usa o rectângulo da vista aberta.** Com a caixa aberta, o rectângulo que se confere contra os controlos
  de andar da câmara livre (o manípulo, o subir, o descer e a velocidade) é o da **expandida**, e já não o
  `tamanho_compacto()`. Se a expandida ia tapar um desses controlos, a altura dela pára acima dele e a lista rola por
  dentro. Só se nem assim couber é que a caixa sai de cena, que é o que já acontecia à compacta.
- **A caixa volta a arrumar-se ao abrir e fechar.** Liguei o sinal `vista_mudou` a `_posicionar_caixa`, como o HUD já
  fazia. Sem isto, a protecção nunca via a vista aberta, porque o ecrã do Mestre só arrumava a caixa quando a ordem
  mudava.
- Nada de visual novo nem de cores novas. A barra de rolagem ficou como estava.

**`rascunhos/cliente/testes/medir_mestre.gd`** (é o teste de sobreposição do ecrã do Mestre):
- Em 844×390, 780×360 e 1920×1080, a vista da fixture fica com **12 e com 16 figuras**: as da fixture e criaturas de
  ensaio de nome comprido, em modo iniciativa.
- A expandida abre-se com o **rato a sério**, por `push_input`. Depois confere-se:
  - a caixa aberta fica dentro do tabuleiro, sem tocar a folha, e não passa do fundo do ecrã;
  - nunca fica mais estreita que a compacta;
  - o rato e um clique na folha, à altura da caixa, vão à folha (o clique é contado no `gui_input` do controlo), e a
    caixa volta à compacta. O fecho medido é pelo rato na folha; o fecho pelo clique não foi medido em separado. O ponto é o pior sítio: se a caixa entrar na folha, o ponto fica no meio da parte tapada.
- Na câmara livre, a sobreposição com o «Voltar», a dica e os controlos de andar mede-se também **com a vista aberta**.
- Para o clique não dar uma ordem ao cartão, finge-se um comando em voo: o `tocar` do Mestre não age com comandos em
  voo.

**A prova viva, passo 12 (novo)** (`provas/ordem-caixa-expande/ferramentas/prova_caixa_expande.gd` — o passo 12 editou este ficheiro, +98/−0, ficheiro entregue pela F14):
- Corre dentro do ciclo do 11, porque só aí há 12 e depois 16 figuras, e acontece a seguir aos 3 gestos.
- Em 844×390 e 780×360, com a expandida aberta pelo rato, mede-se:
  - a lista no topo, sem rolar: as linhas inteiras à vista e a que a borda inferior corta;
  - a lista depois de um passo da roda;
  - a lista no fim;
  - a barra do tema: se está à vista, a largura, a altura e a pega, em unidades e em px reais.
- Capturas `12-barra-{topo,meio,fim}-*`, todas com um recorte ampliado 3× ao píxel.
- O lançador novo `provas/ordem-caixa-expande-vistas/ferramentas/correr-prova-vistas.sh` é uma cópia do da
  CAIXA-EXPANDE-INTERACAO com a saída nesta pasta. O PIN continua a ser novo por corrida.

**A ferramenta nova das fotos do Mestre:** `provas/ordem-caixa-expande-vistas/ferramentas/foto_mestre_vistas.gd`. Faz
as mesmas medidas da suite, mas com render, e tira as capturas.

**Biblioteca primeiro.** Vi a biblioteca GameDev Kit no `G:`. Na bib 5 (`06_Ferramentas_e_Plugins`) só há o G.U.I.D.E,
o UI_Builder, o dot-ui e o theme_assist. Nada lá limita um painel a um rectângulo nem mede uma barra de rolagem. A
correcção usa o `limitar_largura` que a caixa já tinha; não construí nenhum sistema.

## 2. Os números das suites
Godot 4.7.2, Windows 11, `--headless`, como no CI. Os logs estão em `provas/ordem-caixa-expande-vistas/suite/`; as
linhas finais dos outros passos estão em `suite/resumo-alheios.txt`.

| passo do cliente | ponta `8b78867` | agora |
|---|---|---|
| `medir_mestre` | 0 falhas, 87 ok | **0 falhas, 130 ok** (+43: o D4 com 12 e 16 figuras nos 3 ecrãs) |
| `rodar_testes` | 321/321 | **321/321** |
| `caixa_janela` | 123/123 | **123/123** |
| `caixa_jogadora` | 58/58 | **58/58** |
| `caixa_jogadora -- --estrita` | 57/58 | 57/58 (a mesma falha de sempre: 780×360, 11,5 u) |
| `abrir_scripts` | | 108 scripts, 0 falhas |
| `abrir_clareira` · `abrir_mestre` · `pecas_mestre` · `hud_acoes` | | 22/22 · 67/67 · 286/286 · 50/50 |
| `medir_painel_config` | | 0 falhas, 0 sem medida |
| `teste_relato_caixa` · `teste_nomes_relato` · `canario_privacidade` | | 31/31 · 26/26 · 10/10 |
| arranque da cena principal | | chega a «pronto», 0 erros de script |
| erros de script em todos os passos | | 0 |

**As verificações novas apanham o defeito.** Corri o `medir_mestre` novo com o `mestre.gd` da ponta (só na cópia de
trabalho, e depois reposto; o log está em `sem-correcao/medir_mestre.log`). Dá **125 ok e 5 falhas**, e as 5 são
exactamente as do D4:
- 780×360 com 12 figuras: a caixa passa para a folha (acaba em 883, e a folha começa em 867);
- 780×360 com 16 figuras: o mesmo, até 917;
- nesses dois casos, com o rato na folha, a caixa não volta à compacta;
- 1920×1080 na câmara livre com 16 figuras: a vista aberta tapa o manípulo.

## 3. D4 — o ecrã do Mestre, medido (u = unidades do ecrã do Mestre)
Ferramenta com render: `foto_mestre_vistas.gd`, **30/30** com a correcção e 25/30 sem ela. Os logs são
`mestre/foto_mestre.log` e `sem-correcao/foto_mestre.log`. A suite headless dá os mesmos rectângulos.

| ecrã · figuras | caixa aberta (x, y, l×a) | fim do tabuleiro / início da folha | linhas inteiras sem rolar | rato e clique na folha | sem a correcção |
|---|---|---|---|---|---|
| 844×390 · 12 | (36, 179, 787×884) | 968 | 9 de 12 | à folha, 1 clique; a caixa fecha | igual: neste ecrã já cabia |
| 844×390 · 16 | (36, 179, 821×884) | 968 | 9 de 16 | à folha, 1 clique; a caixa fecha | 883 u na suite, 884 u com render; neste ecrã já cabia |
| 780×360 · 12 | (39, 194, **808**×867), acaba em 847 | 867 | 8 de 12 | à folha, 1 clique; a caixa fecha | 844 de largo, acaba em **883**: entra 16 u na folha e fica aberta com o rato lá |
| 780×360 · 16 | (39, 194, **808**×867), acaba em 847 | 867 | 8 de 16 | à folha, 1 clique; a caixa fecha | 878 de largo, acaba em **917**: entra 50 u e fica aberta |
| câmara livre 1920×1080 · 16 | (22, 122, 521×**793**), acaba em 915 | manípulo em y = 926 | 13 de 16 | | 521×947, acaba em 1069: **tapa o manípulo** |

- **A caixa nunca passa do fundo do ecrã:** acaba em 1063 ≤ 1080 em 844×390 e em 1061 ≤ 1080 em 780×360.
- **A folha continua clicável onde a caixa não está:** em todos os casos o clique chega à folha (1 carregar contado no
  controlo dela), e a caixa volta à compacta.
- **A consequência do tecto:** em 780×360 os nomes compridos das criaturas de ensaio cortam-se com «…» na expandida (8
  de 12 linhas e 12 de 16). Os nomes inteiros só cabiam passando para a folha. É o mesmo comportamento que o HUD já tem.

**Vi as capturas:**
- `mestre/mestre-aberta-16-figuras-780x360.png`: a caixa acaba antes da folha, e a barra fina e o «Modo iniciativa»
  ficam à vista.
- `sem-correcao/sem-correcao-mestre-aberta-16-figuras-780x360.png`: a caixa vai por baixo da folha, e o «Modo
  iniciativa» e a barra de rolagem ficam escondidos atrás dela.
- `mestre/mestre-livre-aberta-16-figuras-1920x1080.png`: a lista pára acima do manípulo.
- `sem-correcao/sem-correcao-mestre-livre-aberta-16-figuras-1920x1080.png`: a lista desce por cima do manípulo.
- `mestre/mestre-fim-16-figuras-780x360.png`: a lista no fim, com a última figura inteira.

## 4. D2 — a barra e a prova viva 12/16, medidas (a matéria da F20)
**Prova viva: 241/241** (`provas/ordem-caixa-expande-vistas/cliente/`, com o relato em `relato.txt`):
- o cliente real pela ligação (127.0.0.1:8794);
- o servidor de mesa real, com o motor VLAB real (`a91c021c…`) e a semente 7;
- o manequim de referência, com o SHA conferido.

**Emenda da conferência (F32, 23/11/2026):** fontes da proveniência — semente 7 no lançador (`correr-prova-vistas.sh:20`); hash VLAB `a91c021c…` no log do job `motor-real` da run Testes 45101519738.

Por passo: 0 → 1 · 1 → 22 · 2 → 20 · 3 → 4 · 4 → 22 · 5 → 20 · 6 → 17 · 7 → 31 · 8 → 18 · 9 → 6 · 10 → 9 · 11 → 38 ·
**12 → 32**, mais 1 da abertura do manequim. Os passos 0 a 11 dão os mesmos 209 da CAIXA-EXPANDE-INTERACAO — os mesmos 209 ok; um valor deriva 1 u (ver a linha seguinte).

**Emenda da conferência (F33, 23/11/2026):** na re-corrida do passo 11 (16 figuras, 780×360), o fim da lista deriva de 736 u para 735 u, em 3 linhas do relato (relato.txt:344, 345, 347).

**A barra como é hoje.** Medida no HUD da jogadora: «u» são unidades do HUD e «px» são píxeis reais da janela.

| figuras · ecrã | linhas inteiras à vista sem rolar | a linha cortada no topo | barra (largura × altura) | pega | 1 passo da roda | no fim |
|---|---|---|---|---|---|---|
| 12 · 844×390 | **9 de 12** | a 10.ª, 38 % à vista | 8 × 843 u = **2,9 × 304 px** | 661 u = 239 px | 0 → 105 u (8 inteiras) | 233 u; a 12.ª inteira; 9 inteiras |
| 12 · 780×360 | **8 de 12** | a 9.ª, 47 % à vista | 8 × 828 u = **2,7 × 276 px** | 585 u = 195 px | 0 → 103 u (7 inteiras) | 344 u; a 12.ª inteira; 8 inteiras |
| 16 · 844×390 | **9 de 16** | a 10.ª, 38 % à vista | 8 × 843 u = **2,9 × 304 px** | 495 u = 179 px | 0 → 105 u (8 inteiras) | 593 u; a 16.ª inteira; 9 inteiras |
| 16 · 780×360 | **8 de 16** | a 9.ª, 48 % à vista | 8 × 829 u = **2,7 × 276 px** | 439 u = 146 px | 0 → 103 u (7 inteiras) | 735 u; a 16.ª inteira; 8 inteiras |

- A barra está sempre à vista quando a lista rola, mas tem **menos de 3 px reais de largura** nos dois ecrãs baixos.
- O que diz que a lista continua é a linha cortada a meio na borda inferior, a 38–48 %, e a pega da barra, que é tanto
  mais curta quanto mais figuras há.
- **No ecrã do Mestre** (§3), sem rolar, vêem-se 9 linhas em 844×390 e 8 em 780×360, com 12 ou 16 figuras.
- **Emenda da conferência (F35, 23/11/2026):** a tabela arredonda os valores ao inteiro.

**As capturas** são a matéria da pergunta ao olho do Mestre (barra discreta ou mais visível). Estão em `cliente/`:
- `12-barra-topo-N-figuras-WxH.png`: a lista cortada, sem rolar;
- `12-barra-meio-…`: um passo da roda;
- `12-barra-fim-…`: o fim da lista;
- todas têm o seu `-recorte.png`, ampliado 3×.

São 24 ficheiros, com os SHA-256 no `README.md` da prova. Vi o `12-barra-topo-16-figuras-844x390.png` e o recorte
dele: 9 linhas inteiras, o retrato da 10.ª cortado na borda inferior e a barra como um fio claro à direita. Vi também o
`12-barra-fim-16-figuras-780x360-recorte.png`: a última figura inteira em baixo e a pega no fim da barra.

## 5. CI
**CI da ponta `ecf46d6`, já na linha** (Testes 45101519738 + Sonda 45101519763): **10/10 jobs verdes e a Sonda
verde**. Os jobs são `servidor`, `validador-glb`, `foto-mestre`, `godot-cliente`, `cliente`, `ponta-a-ponta`,
`retoma-pc`, `provas-mapa`, `motor-real` e `protocolo`.

No Linux do CI os números são os de cá:
- `medir_mestre`: **130 ok, 0 falhas** («ecrã do Mestre: 0 falha(s), 0 sem medida»), com as 6 medidas da expandida e a
  da câmara livre. Os rectângulos da caixa são os de cá. O tabuleiro em 780×360 mede 866 u no Linux contra 867 cá — diferença de 1 u nas medidas da letra entre Linux e
  Windows, causa por determinar — e a caixa aberta continua a acabar em 847;
- `caixa_janela` 123/123, e a guarda «123 de 123» passou;
- `caixa_jogadora` 58/58;
- `rodar_testes` 321/321, nos jobs `cliente` e `godot-cliente`;
- `abrir_scripts` 108 scripts e 0 falhas · `abrir_clareira` 22/22 · `abrir_mestre` 67/67 · `pecas_mestre` 286/286 ·
  `hud_acoes` 50/50;
- `teste_relato_caixa` 31/31 · `teste_nomes_relato` 26/26 · o canário 10/10;
- o guião de mutação da CAIXA-JANELA-CI: 9 falhas, todas da B6, e «114 de 123».

O `foto-mestre`, que fotografa o ecrã do Mestre com render, passou. O `retoma-pc` passou com as listas do commit 2.

**Emenda da conferência (F35, 23/11/2026):** `sem-correcao/medir_mestre.log:73` traz a coluna `compacta` mal etiquetada (o valor é o da aberta).

**Listas da retoma:** corri o `actualizar-listas.py` depois do commit 1, porque ele lê o `HEAD`. Deu 0 novos e 0
tirados; só mudam os SHA de 2 ficheiros, `cenas/mestre/mestre.gd` e `testes/medir_mestre.gd`. O `depois.txt` e o
`MANIFESTO-SHA256.txt` vão sincronizados no commit deste ficheiro.

## 6. Privacidade: o conferidor estrito nos dois critérios
Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, critério alargado / `--velho`.

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-caixa-expande-vistas/README.md` | **0 / 0** | 0 |
| as linhas que acrescentei a `mestre.gd`, `medir_mestre.gd` e `prova_caixa_expande.gd` (o `+` do diff contra `8b78867`) e a ferramenta `foto_mestre_vistas.gd` | **0 / 0** | 0 |
| `suite/caixa_jogadora.log`, `suite/caixa_jogadora-estrita.log`, `suite/resumo-alheios.txt` | **0 / 0** | 0 |
| `suite/medir_mestre.log`, `sem-correcao/medir_mestre.log` | 6 / 6 por log | **0** |
| `mestre/foto_mestre.log`, `sem-correcao/foto_mestre.log` | 10 / 10 por log | **0** |
| `suite/caixa_janela.log` | 3 / 2 | **0** |
| o lançador `correr-prova-vistas.sh` (cópia do da CAIXA-EXPANDE-INTERACAO) | 2 / 2 | 0 |
| `cliente/relato.txt` | 108 / 108 | **0** |

- **Os logs do Mestre** só têm achados numa linha que o próprio jogo imprime ao carregar o cenário (a linha
  `[floresta] pronta em … ms | {…}`), uma vez por cena aberta: 3 linhas na suite e 5 nas fotos, com os 2 nomes por
  linha. O pedaço está dentro de uma chave técnica do cenário, não de um nome, e não a escrevi. As linhas que a
  ferramenta e a suite escrevem dão 0.
- **Os logs da `caixa_janela`** têm as mesmas linhas de sempre (o padrão aceite na CAIXA-JANELA-CI).
- **O lançador** herda a linha do servidor de ensaio, como o da CAIXA-EXPANDE-INTERACAO.
- **Emenda da conferência (F34, 23/11/2026):** padrão herdado aceite por decisão do juiz — o lançador dá 2/2 no critério alargado e 0 inteiros; o pedaço está no caminho herdado do servidor de ensaio (EXPANDE), pré-existente na base. A renomeação fica como higiene futura (F38).
- **Emenda da conferência (F31, 23/11/2026):** o README trocou «Cada» por «Todas» na l.41 no commit 2 — em `53c2945` tinha 2/2; na ponta fica 0/0.
- **O relato** imprime os nomes **públicos** das figuras, que é o que a caixa mostra: 108, como na
  CAIXA-EXPANDE-INTERACAO. As linhas novas do passo 12 não têm nomes.
- **As minhas linhas** tinham palavras correntes que partilham pedaços com os nomes.
  Troquei-as e ficaram 0 / 0. As suites, as fotos e a prova viva voltaram a correr depois da troca, e os números acima
  são dessa corrida.
- **As criaturas de ensaio** do ecrã do Mestre têm nomes inventados para a medida. Não são nomes das fichas.
- **Os logs dos outros passos não se cometem**, porque o do `teste_nomes_relato` imprime nomes verdadeiros de
  propósito. Fica só a linha final de todos (`resumo-alheios.txt`, 0 / 0).
- **O PIN** é novo por corrida e passa só por `--pin=`. O info e o log do servidor ficaram na pasta temporária, fora do
  repo. Não há nenhum valor de PIN em nenhum ficheiro.

## 7. O que não se pôde medir como descrito, e pontos para o coordenador
1. **«A expandida engole os cliques da folha.»** Medido, **não acontece** no ecrã do Mestre, nem sem a correcção. A
   folha é filha do ecrã do Mestre **depois** da caixa, por isso desenha-se por cima dela e recebe o rato primeiro.
   Mesmo com a caixa a passar para a folha, o clique contou 1 no controlo da folha.
   - O defeito real era outro: a expandida ia por baixo da folha e ficava cortada, com o «Modo iniciativa» e a barra
     de rolagem escondidos.
   - Como o rato na folha ainda estava «dentro» da caixa, ela ficava aberta por baixo.
   - Ambos estão na captura sem correcção e nas 2 falhas correspondentes.
2. **«Nunca passa a barra.»** A prova pedida não tem referente no ecrã do Mestre (não tem a barra das acções do HUD) — mediu-se o fundo do ecrã (a caixa acaba em 1063 e 1061, abaixo de 1080) e os controlos de andar da câmara livre, que são o que fica em baixo.
3. **A câmara livre nos ecrãs baixos.** Em 844×390 e 780×360, dentro da câmara livre, a caixa já saía de cena antes
   desta ordem, porque nem a compacta cabe entre a dica e o manípulo. Não mudou. A medida com a vista aberta na câmara
   livre só tem caixa à vista em 1920×1080.
4. **Os nomes cortados no Mestre em 780×360** (§3) são a consequência directa do tecto. Os nomes das criaturas de
   ensaio são compridos de propósito, «nome (nome público)».
5. **As etiquetas de nome das figuras na arena** sobrepõem-se nas capturas do Mestre, porque as criaturas de ensaio
   estão juntas. São da arena, fora do território desta ordem.
6. **A barra mede menos de 3 px reais** nos ecrãs baixos (§4). Fica medida e fotografada, sem mudança, para a pergunta
   ao Mestre (F20).
