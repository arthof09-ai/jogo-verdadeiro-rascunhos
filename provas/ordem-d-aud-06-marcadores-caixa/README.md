# Provas — ORDEM-D-AUD-06-MARCADORES-CAIXA (retoma no PC do Pierre, 25/11/2026)

O ESTADO-FINAL está em `ESTADO-FINAL-ORDEM-D-AUD-06-MARCADORES-CAIXA.md`, na raiz da linha.

## Como foram feitas

Usei a **bancada de rede verdadeira**: o servidor de produção (`servidor-ws.js` com a config do `bancada-rede/preparar.mjs`,
motor real em cache, fichas `canario`, monstros em «À mão»), o porteiro da bancada e **dois clientes Godot 4.7.2
verdadeiros**: a jogadora (Heroína Teste) a **1280×720** e o Mestre a **1600×900**. Corre a cena principal, com o
render verdadeiro (Compatibility, OpenGL 3.3, AMD RX 7900 XTX).

- `ferramentas/correr-bancada.ps1` faz os passos do `lancar.ps1` (sem o journal da corrida anterior). Dá ao porteiro a
  casa do orc (`--orc`) e abre os dois clientes com o condutor.
- `ferramentas/condutor_bancada.gd` (`-s`) abre `cenas/arena/arena.tscn` como em produção. A Rede entra sozinha pelo
  `lugar.cfg` que o porteiro deixou, e o Mestre vai para o ecrã dele (D-AUD-16). Depois prime os botões que a jogadora e
  o Mestre primiriam (`pressed`; o toque do Mestre numa casa é `casa_tocada`) e grava a imagem da janela. Mede tudo em
  **píxeis da janela**: a caixa é o `get_global_rect()` pelo `get_final_transform()`, e as casas e as figuras saem da
  câmara da arena (no Mestre, pelo SubViewport do tabuleiro).
- `ferramentas/medir_cor_recortes.gd` conta a cor de alvo nos recortes ×3.
- **Sem janelas no ecrã:** o agente corre na sessão 0 (serviço) deste PC. As janelas do Godot existem e desenham na
  GPU, mas não aparecem no ecrã de quem está sentado ao PC. O ecrã virtual da sessão 0 tem 1024×768 e corta o
  `--resolution`. Por isso o condutor põe a janela no tamanho da bancada à mão (`window_set_max_size` +
  `window_set_size`). As capturas saem com 1280×720 e 1600×900 exactos.
- **Antes / depois:** «antes» é o cliente da ponta `b884b75` (extraído com `git archive` para fora do repositório).
  «Depois» é o cliente desta ordem (`cac02a1`). O servidor e o porteiro são os mesmos nas duas corridas.

Duas cenas, cada uma corrida «antes» e «depois»:

| cena | onde está o orc | o que faz |
|---|---|---|
| **A** (marcadores) | (38,14), a casa mais funda do lago: **2,52 m** de água | a jogadora «Mover» (a caixa e o realce), anda para (38,10) (2,47 m de água, a 4 casas do orc, dentro dos 9 m do arco), «Ataque» (o alvo debaixo de água) e «Encerrar». O Mestre: a vez do orc → aba Agir → «Mover» → toca em (38,11), ao lado da heroína → os alvos do orc (a heroína a 2,47 m de água) |
| **B** (a caixa do Mestre, C1-3) | (20,12), na zona do tabuleiro que a caixa tapa na vista do Mestre (medida na cena A) | a jogadora «Mover» e «Encerrar». O Mestre: a vez do orc → aba Agir → «Mover» → captura com a caixa por cima do realce |

## As medidas (JSON em `medidas/`)

### A caixa da ordem, lado a lado

| | janela | caixa (x, y, largura × altura, px) | casas do realce do Mover | debaixo da caixa | figura da vez |
|---|---|---|---|---|---|
| **Mestre, cena B** (antes = depois) | 1600×900 (tabuleiro 0,0, 864×900) | **18, 67, 468 × 67** (compacta, sem retratos) | 40, todas no tabuleiro | **19 de 40**: (20,11) (20,10) (19,11) (21,11) (20,9) (19,10) (21,10) (18,11) (22,11) (17,12) (20,8) (19,9) (21,9) (18,10) (22,10) (17,11) (23,11) (16,12) (17,13) | **tapada**: a cabeça do orc fica debaixo da caixa; o pé está em (296,144), 10 px abaixo do bordo de baixo dela (134) |
| **Mestre, cena A** (antes = depois) | 1600×900 | **18, 67, 468 × 179** (com os 2 retratos) | 39, 26 no tabuleiro | 0 (o orc está no lago, a nordeste) | não (pé em 824,244) |
| **Jogadora, cenas A e B** (antes = depois) | 1280×720 | **986, 16, 278 × 71** | 70, todas no ecrã | **0** | não: a figura está no centro (640,360), pela câmara que segue (D-AUD-05) |

A zona do tabuleiro do Mestre que a caixa tapa, na câmara do jogo de arranque: **70 casas** (x 13–26, y 6–14) com a
caixa compacta, e **138 casas** (x 13–26, y 6–17) com os 2 retratos. Do lado da jogadora, a caixa não tapa **nenhuma**
casa da grelha. Por cima da caixa só há céu e árvores, porque a câmara está centrada na figura dela.

### O marcador de alvo

| | alvo | água por cima do leito | marcador | tamanho no ecrã | píxeis «vivos» / «avermelhados» (vermelhidão máx.) |
|---|---|---|---|---|---|
| jogadora **antes** | Orc 1 em (38,14) | **2,52 m** | quadrado plano no relevo (no fundo do lago) | 45×44 px | 0 / 988 (0,31): vê-se baço, tingido pela água, com a forma das casas do Mover |
| jogadora **depois** | Orc 1 em (38,14) | **2,52 m** | anel + seta | 59×69 px | **847** / 1177 (0,70) |
| Mestre **antes** | Heroína Teste em (38,10) | 2,47 m | **nenhum** (só o botão «Atacar Heroína Teste» na aba Agir) | — | 0 / 48 (0,18) |
| Mestre **depois** | Heroína Teste em (38,10) | 2,47 m | anel + seta | 52×65 px | **257** / 366 (0,70) |

«Vivo»: r > 0,70, g < 0,45, b < 0,45 e r − g > 0,35. «Avermelhado»: r − g > 0,15 e r − b > 0,15. Conta-se no
recorte de 140×140 px (jogadora) ou 160×160 px (Mestre) à volta da figura (`medidas/cor-dos-recortes.txt`).

## As capturas (`capturas/`)

- `A-j01`, `A-j02a` (a caixa medida, a magenta), `A-j03` (andou para dentro de água), **`A-j04` (os alvos)** e
  **`A-j04z` (recorte ×3 do orc a 2,52 m)**, cada uma «antes» e «depois».
- `A-m03a` (o Mover do Mestre com a caixa a magenta e o tabuleiro a ciano), **`A-m04` (os alvos do orc)** e
  **`A-m04z` (recorte ×3 da heroína a 2,47 m)**, cada uma «antes» e «depois».
- **`B-m03` / `B-m03a`: a caixa da ordem por cima do realce do Mover no ecrã do Mestre (C1-3)**, «antes» e «depois»
  (iguais: esta ordem não mexe na caixa). `B-j02a`: o ecrã da jogadora na mesma cena.

Os JPG estão em qualidade 90 e os recortes em PNG. As medidas em píxeis vêm do JSON, que foi medido no render, não nos
JPG.

## Registos (`logs/`)

`A-`/`B-godot-<lugar>-<antes|depois>.log` (a saída do cliente com as linhas do condutor), `A-`/`B-porteiro-*.log` e
`suites.txt`. Os 8 clientes acabaram com **0 SCRIPT ERROR / 0 ERROR** e 0 falhas do condutor. Ficam de fora o
`servidor.log` (traz o IP da rede local e o QR), o `preparar.log` (traz caminhos do PC) e o journal (MESTRE-ONLY).
