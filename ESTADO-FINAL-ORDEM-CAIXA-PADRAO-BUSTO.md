# ESTADO FINAL — ORDEM-CAIXA-PADRAO-BUSTO (Claude conta 1, PC · 21/11/2026)

**Ramo:** `claude1/caixa-padrao-busto`, a partir de `origin/claude1/caixa-teste-estetica` @ `ffb7181`. Está publicado
e **não está fundido**: a fusão é do coordenador, depois de o Mestre ver as capturas. A estética do teste fica como estava.

## As 5 capturas
Estão em `provas/ordem-caixa-padrao-busto/cliente/`, com os nomes de sempre (`1-entrou-dinamica.png` … `5-reentrou.png`).
Comparam-se com as do teste em `provas/ordem-caixa-teste-estetica/cliente/`. Vi as cinco, uma a uma. Em
`cliente/retratos/` está o retrato de cada figura (160×160), para ver de perto.

## O que mudou

### Correcção 1: os quadradinhos todos do mesmo tamanho (`hud/caixa_ordem.gd`)
- **Antes**, cada quadradinho era um VBoxContainer com o retrato e o nome por baixo. O contentor media-se pelo que
  levava, por isso um nome comprido («Espadachi…») alargava a célula e um curto («Lobo») deixava-a estreita.
- **Agora**, cada quadradinho é um `Control` de **tamanho fixo**, dado por `tamanho_celula()`:
  - em cima, o retrato quadrado, com 3,4 letras de lado (`LADO_RETRATO_EM_LETRAS`; antes 2,8);
  - por baixo, uma linha de nome com a mesma largura;
  - a moldura e o nome são postos à mão dentro da célula, e nada do que ela leva a alarga.
- O nome corta-se dentro da largura fixa: primeiro aos 10 caracteres, como antes, e depois com «…» se ainda não couber.
- Subi o lado de 2,8 para 3,4 letras para os nomes caberem melhor numa célula que já não cresce. A caixa continua
  mais baixa do que o cartão da vez.
- O **cartão grande da figura na vez** não mudou: continua com 4,6 letras e maior do que os quadradinhos.

### Correcção 2: o retrato em busto, rosto e peitoral (`hud/retratos.gd`)
A regra do enquadramento, num parágrafo:

> O retrato mede a figura **na pose em que está**, e não pela malha do ficheiro. Nas malhas rígidas (as cápsulas e
> os marcadores) a caixa da malha já é a da pose. Nas malhas esfoladas (as que têm esqueleto e skin, como o manequim)
> faz a conta que o motor faz para desenhar: cada osso que deforma a malha traz a caixa dos vértices que move
> (`bone_aabbs`), e essa caixa é levada pela pose actual do osso. A soma destas caixas é a figura em pose.
> A figura conta como de pé se, em pose, for mais de 1,2 vezes mais alta do que larga. Nesse caso o retrato é uma
> janela quadrada que começa um pouco acima do alto da cabeça (3 % da altura) e desce 30 % da altura: a cabeça e o
> peito. A janela fica centrada nas partes da figura que caem nessa faixa, e a largura dos braços não a alarga.
> A câmara fica **à frente** da figura, do lado do rosto. Uma figura deitada, ou mais larga do que alta (um
> quadrúpede, por exemplo), continua a aparecer de corpo inteiro.

- **A causa medida pela CAIXA-MANEQUIM.** A malha em pose de T mede 1,76 × 1,81 m e por isso não contava como «de
  pé». Em pose (quadro 0 do ANDAR v3) a mesma figura mede 0,48 m de largo (1,01 m de fundo, por causa do passo) por
  1,77 m de alto, e já conta como de pé. Para validar o método, pus a pose de volta à de repouso: a conta dá
  exactamente a caixa da malha (1,76 × 1,81). O método funciona igual com `--headless`, que é o modo do CI.
- **Um erro antigo que o busto pôs à vista.** A câmara do retrato estava em +Z, mas a frente das figuras é −Z (é essa
  a convenção da arena, em `RUMO_ORIENTACAO`). Com a cápsula, que é simétrica, não se notava. Com o manequim, o
  retrato mostrava as costas. Agora a câmara está do lado do rosto (`DIRECAO_CAMARA` com z = −1).
- As constantes novas e alteradas: `FRACAO_BUSTO` 0,62 → 0,30, `FOLGA_CIMA` 0,03, `FOLGA_BUSTO` 1,08, `DE_PE` 1,2.
  As funções novas são `caixas_em_pose`, `de_pe` e `janela_busto`, e `caixa_visivel` passou a medir em pose.
- A regra serve para qualquer figura e não depende dos nomes dos ossos. Como o ecrã do Mestre usa o mesmo
  `retratos.gd`, também lá os retratos passam a ser em busto e de frente.

### Testes
- `testes/rodar_testes.gd` (passa de 290 para 297 verificações):
  - o teste do busto do marcador passa a pedir a janela nova e a câmara à frente;
  - teste novo `_teste_retrato_busto_em_pose`: abre o manequim, confirma que pela malha em T não contaria como de pé
    (era o erro), que em pose conta, que a câmara olha para o rosto e o peito, que a janela é o busto e que a câmara
    está à frente;
  - `_teste_caixa_ordem`: 5 nomes de comprimentos diferentes dão 5 quadradinhos do mesmo tamanho.
- `testes/caixa_janela.gd`: o lado do retrato passa a ler-se de `LADO_RETRATO_EM_LETRAS` e deixa de estar escrito
  à mão como 2,8.

## A lista medida dos tamanhos dos quadradinhos
Mediram-se em píxeis reais da janela de 1028×720. O HUD é esticado a partir de 1920 de largo, com a escala medida de
0,5354. Entre parênteses, as unidades do HUD.

| captura | quadradinhos seguintes | retrato | cartão na vez |
|---|---|---|---|
| 1 dinâmica | Arqueira… 46×60 · Lobo 46×60 · Espadachi… 46×60 | 46×46 | 62×62 |
| 2 iniciativa | Arqueira… 46×60 · Lobo 46×60 · Espadachi… 46×60 · Bruto 46×60 | 46×46 | 62×62 |
| 3 desligada | (a caixa não está à vista) | — | — |
| 4 religada | Arqueira… 46×60 · Lobo 46×60 · Espadachi… 46×60 · Bruto 46×60 | 46×46 | 62×62 |
| 5 reentrada | Arqueira… 46×60 · Lobo 46×60 · Espadachi… 46×60 · Bruto 46×60 | 46×46 | 62×62 |

Todos são iguais ao píxel: 46×60 px (85×112 u), que é a célula fixa da caixa. No teste anterior, as células da
captura 2 iam de cerca de 36 px («Bruto», «Lobo») a cerca de 60 px («Espadachi…»).

## Os números da prova
A prova correu com o jogo vivo:
- cliente real pela Rede e servidor de mesa real com o motor VLAB real (`a91c021c…`), semente 7;
- Godot 4.7.2, RTX 4060, janela 1028×720;
- manequim de referência `andar-v3.glb` com o SHA conferido (`8413b039…`) e nenhuma cápsula à vista.

O resultado foi **78/78**:
- As 62 do teste estético dão o mesmo, linha a linha (comparei os dois relatos com `diff`): as mesmas ordens e vezes,
  o manequim em todas as figuras, as cores e a privacidade.
- As 16 novas são 4 por cada momento com a caixa à vista: (a) os quadradinhos iguais ao píxel, (a) esse tamanho é
  a célula fixa, o cartão da vez é maior, e (b) os retratos são busto. Em cada retrato confere-se que o alto da cabeça,
  o rosto e o peito ficam dentro do quadro, que a cintura, os joelhos e os pés ficam fora, e que a câmara está à frente.

Privacidade, igual ao teste: a caixa só leva `ligada/ordemPor/ordemDinamica`, e não aparece nenhum nome verdadeiro,
vida, alma, PA ou mensagem do Mestre na vista da jogadora.

Os passos do cliente que o CI corre, todos verdes nesta máquina:

| passo | resultado |
|---|---|
| `abrir_scripts` | 107 scripts, 0 falhas |
| `rodar_testes` | **297/297** |
| `caixa_jogadora` | 18/18 |
| `caixa_janela` | 69/69 |
| `abrir_clareira`, `medir_painel_config`, `abrir_mestre`, `pecas_mestre`, `medir_mestre`, `hud_acoes`, `canario_privacidade` | 0 falhas, 0 erros de script |
| arranque da cena principal | chega a «pronto» |

O `actualizar-listas` da retoma correu antes do commit final. `antes.txt`, `depois.txt` e `MANIFESTO-SHA256.txt` vão
sincronizados no ramo, para o passo retoma-pc do CI.

## Pontos para o coordenador e o Mestre
1. **Os nomes compridos cortam mais cedo.** Na célula fixa cabem cerca de 7 letras à vista («Arqueir…», «Espada…»).
   Antes, a célula esticava para o nome inteiro até 10 letras. Se o Mestre quiser nomes mais longos à vista, sobe-se
   `LADO_RETRATO_EM_LETRAS`: todas as células crescem juntas e ficam iguais.
2. **A câmara do retrato mudou de lado** (+Z → −Z), para ver o rosto. Isto vale também para o ecrã do Mestre. Com
   as cápsulas de hoje não se nota diferença. Com modelos de verdade, o retrato passa a mostrar a frente. Se algum
   modelo futuro vier virado ao contrário (com a frente em +Z), aparece de costas no retrato e também anda de costas
   na arena, porque a convenção é a mesma.
3. **Quadrúpedes e criaturas largas continuam de corpo inteiro** (mais largas do que 1/1,2 da altura). A ordem
   pedia o busto para figuras humanas. Se o Mestre quiser também a cabeça do lobo, isso é uma regra à parte.
4. O manequim só entra na prova, pela ferramenta. O jogo continua a pôr as cápsulas.
5. O retrato do manequim mostra a figura sem rosto modelado, porque o manequim não tem feições. O enquadramento é o
   da cabeça e do peito.
