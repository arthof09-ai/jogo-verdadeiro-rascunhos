# Provas — Ordem CAIXA-JANELA (21/11/2026, Claude conta 1, PC)

A janela lobby→arena fechada (B1) e a caixa da ordem de turnos medida com 8+ figuras em ecrãs baixos (B3).

## cliente/ — o cliente da jogadora a sério, 10 figuras (35/35)
- Servidor de mesa real: `provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs` (o da CAIXA-HUD-JOGADORA,
  intacto), porta 8793, semente 7, motor VLAB real sha256 `a91c021c…` (`cliente/servidor-info.json`). 2 heroínas + 8
  criaturas de bancada (as fichas do cenário repetidas em casas da floresta).
- O cliente da jogadora a sério (`cenas/arena/arena.tscn` + HUD, pela Rede do jogo), Godot 4.7.2 Windows, render NVIDIA
  GeForce RTX 4060, pela ferramenta `ferramentas/prova_caixa_janela.gd` (lançador `ferramentas/correr-prova-caixa-janela.sh`).
  Relato completo em `cliente/relato.txt`.
- **B1:** a Espadachim entra e recebe o snapshot (seq 33) SEM a arena aberta; a bancada joga 3 vezes nesse intervalo
  (10 eventos, seq 33 → 43). Só então a arena abre: a caixa é logo a ordem do servidor (10 figuras, vez Lobo), sem
  snapshot novo.
- **B3:** a janela passa por 1280×720, 844×390 e 780×360; a caixa cabe, não tapa a ⚙/ficha/barra, e a faixa tem a largura
  da frase mais comprida (a da pausa) numa linha, fora da caixa. Capturas (sha256, 16 primeiros), vistas por mim:
  1. `1-janela-1280x720.png` `eb1aa86637683178` — 10 figuras numa linha; «O Mestre narra» entre a ⚙ e a caixa.
  2. `2-baixo-844x390.png` `f1bffa6c10cf68c8` — 10 numa linha (57% da largura); a faixa lê-se à esquerda da caixa.
  3. `3-baixo-780x360.png` `cf2fc7fce5f7cd93` — a fila parte em 2 linhas (9 + 1); a faixa lê-se.
- Privacidade: nenhuma mensagem do Mestre no aparelho dela; a caixa só com `ligada/ordemPor/ordemDinamica`; nenhum nome
  verdadeiro, vida ou PA nos textos da caixa, e nenhum dígito nesses textos.

## suites/ — as suites da casa, locais (PC, Godot 4.7.2 headless)
rodar_testes 290/290 · abrir_scripts 107/0 falhas · caixa_jogadora 18/18 (+2 do §7 novo) · **caixa_janela 69/69 (novo)** ·
hud_acoes 50/50 · canário de privacidade 10/10 · medir_painel_config 0 falhas · abrir_clareira 22/22 · abrir_mestre 67/67 ·
pecas_mestre 286/286 · medir_mestre sem falhas · arranque sem erros de script.
Regressão: a prova viva da CAIXA-HUD-JOGADORA (`prova_caixa_jogadora.gd`) corrida de novo com saída fora do repo: 36/36.
O servidor não mudou (nenhum ficheiro de `rascunhos/servidor`).

Correr de novo (Git Bash, na raiz do repo):
`bash provas/ordem-caixa-janela/ferramentas/correr-prova-caixa-janela.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`

## nomes/ — Ordem CAIXA-JANELA-NOMES (21/11/2026, Claude conta 1, PC): o relato só com o nome público
O relato desta prova trazia os nomes verdadeiros das criaturas de bancada («Lobo de Bancada», «Bruto de Bancada»): o
`_nome()` e a linha «bancada:» liam o `nome` da vista do Mestre, e o canário só varria os textos da caixa. O mesmo
remédio da B1 da CAIXA-RELATO-CORRECOES-2, as duas metades:
- **a fonte:** os nomes do relato vêm do `nomePublico` (sem ele, o id) — `ferramentas/nomes_relato.gd`, partilhado pela
  prova e pelo teste;
- **o canário estende-se ao relato:** em cada passagem (1, 2) uma verificação nova confere que nenhuma linha do relato
  traz um nome verdadeiro (os que diferem do público; ≥ 1 canário exigido), e no fim o relato inteiro.

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `nomes/teste-nomes-relato.log` — **teste 14/14** (`ferramentas/teste_nomes_relato.gd`, sem servidor nem ecrã, com as
  fichas de bancada reais; reproduz o caso: «Bruto de Bancada» numa linha → o canário falha; e apanha os 22 nomes
  verdadeiros do relato antigo `cliente/relato.txt`).
- `nomes/cliente/` — **prova viva 38/38** (eram 35; +3 do canário do relato). Capturas (sha256, 16 primeiros):
  `1-janela-1280x720.png` `13ea9aa6ade3a432`, `2-baixo-844x390.png` `9125924cc4b1e23e`, `3-baixo-780x360.png`
  `b4d327e1b0c34764`.
- `nomes/suites/` — rodar_testes 290/290 · abrir_scripts 107/0 falhas · caixa_janela 69/69 · caixa_jogadora 18/18 ·
  hud_acoes 50/50 · canario_privacidade 10/10 · teste_relato_caixa 21/21.

O `cliente/` de cima fica como estava (o registo da Ordem CAIXA-JANELA, com os nomes verdadeiros de bancada).
Correr o teste (raiz do repo): `godot --headless --path rascunhos/cliente -s "$PWD/provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd"`.
A prova: o lançador aceita agora um 4.º argumento, a pasta de saída (sem ele, `provas/ordem-caixa-janela/cliente`).

## nomes-correcoes/ — Ordem CAIXA-JANELA-NOMES-CORRECOES (22/11/2026, Claude conta 1, PC): as correcções B1–B7
- **B1:** o teste dos nomes entra no CI (job `cliente`, a seguir ao passo «Relato da caixa»). O remendo ao workflow é
  `nomes-correcoes/remendo-ci-testes.yml.patch` — aplica-o o coordenador (token `workflow`). O corpo exacto do passo,
  corrido aqui, dá rc=0 e rc=1 com um canário mudado (`nomes-correcoes/mutacoes.log`).
- **B2:** o §4 do teste já não lê `cliente/relato.txt`: o relato antigo está congelado dentro do teste (`RELATO_VELHO`,
  igual byte a byte, sha256 `6df653c41a29e23a…`), e o §4 afirma **22 achados** (28 ocorrências brutas), o 1.º «Lobo de
  Bancada na linha 7». O `cliente/relato.txt` pode ser limpo por outra ordem sem tocar no teste.
- **B3:** a varredura final da prova (`_fim()`) é incondicional; sem canários é FALHA.
- **B4:** os diagnósticos das varreduras (relato e textos da caixa) dizem a contagem e as linhas/índices, nunca o nome.
- **B5:** o rótulo «as 8 criaturas da prova» passou a «aqui as 4 fichas + 1 Bruto repetido; na prova viva, 10 figuras
  de 4 fichas».
- **B6:** os canários da prova vêm do elenco (as fichas de bancada) no arranque, pelo mesmo ajudante que o teste usa
  (`nomes_relato.gd`, `vista_do_elenco`), além dos de cada vista do Mestre.

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `nomes-correcoes/teste-nomes-relato.log` — **teste 14/14**.
- `nomes-correcoes/cliente/` — **prova viva 38/38**; 0 nomes verdadeiros no relato. Capturas (sha256, 16 primeiros):
  `1-janela-1280x720.png` `0086b0edbd6a8051`, `2-baixo-844x390.png` `b46e4b57b68effbb`, `3-baixo-780x360.png`
  `79f7c54d69c4c0db`.
- `nomes-correcoes/suites/` — servidor (`node --test`) 418/418 · prova-servidor PROVA OK · teste_relato_caixa 28/28 ·
  rodar_testes 290/290 · abrir_scripts 107/0 falhas · caixa_jogadora 18/18 · hud_acoes 50/50 · canario_privacidade 10/10.
- `nomes-correcoes/mutacoes.log` — as provas da B1 (o passo verde/vermelho) e da B3 (a fuga com paragem no passo 0:
  calada na base, FALHA «fim» agora).

## cobertura/ — Ordem CAIXA-JANELA-COBERTURA (22/11/2026, Claude conta 2, PC): as correcções C1–C2
- **C1:** o relato é varrido por **chaves proibidas** de vida/PA/alma (`nomes_relato.gd`, `CHAVES_PROIBIDAS` = as 5:
  `vidaActual`, `vidaTotal`, `paTotal`, `paLivre`, `alma`). Na prova: em cada passagem (1, 2) e no fim (incondicional,
  como a dos nomes). No teste: o §5 (5 verificações novas, 14 → 19). As chaves camelCase contam em qualquer sítio da
  linha. «alma» é também palavra portuguesa, por isso só conta em posição de chave (`"alma"`, `'alma'`, `alma:`,
  `alma=`) ou como início de um identificador camelCase (`almaLivre`). Os rótulos «vida, PA, alma», em palavra, não
  tropeçam. O diagnóstico diz a contagem e as linhas, sem a chave. Cobre a linha «bancada:», que escreve o passo
  inteiro.
- **C2 (condição):** não se cumpre. Nenhuma ficha (a de bancada, o protocolo ou o servidor) tem um campo de alma, por
  isso não há valor para o canário.

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `cobertura/teste-nomes-relato.log`: **teste 19/19** (os 14 de antes, iguais, + 5 do §5).
- `cobertura/cliente/`: **prova viva 41/41** (eram 38; +3: 1, 2 e fim). 0 nomes verdadeiros e 0 chaves proibidas no
  relato. Capturas (sha256, 16 primeiros): `1-janela-1280x720.png` `95903df226a9cfd0`, `2-baixo-844x390.png`
  `00410562fefa1dbd`, `3-baixo-780x360.png` `939137737ead4137`.
- `cobertura/suites/`:
  - servidor (`node --test`): 419/419;
  - prova-servidor: PROVA OK;
  - teste_relato_caixa: 30/30;
  - rodar_testes: 290/290;
  - abrir_scripts: 107 scripts, 0 falhas;
  - caixa_jogadora 18/18 · hud_acoes 50/50 · canario_privacidade 10/10.
- `cobertura/mutacoes.log`: as mutações, todas executadas.
  - **M1:** um passo «bancada:» com um custo de PA, na prova viva. Na base passa calado (38/38, rc=0, com 13 linhas com
    a chave). Agora dá FALHA em 1, em 2 e no fim (38/41, rc=1).
  - **M2:** a chave do PA livre tirada da lista. O teste dá 17/19, rc=1.
  - **M3:** «alma» procurada como texto simples. O teste dá 18/19, rc=1, porque os rótulos em palavra tropeçam.

## cobertura-correcoes/ — Ordem CAIXA-JANELA-COBERTURA-CORRECOES (22/11/2026, Claude conta 2, PC): B1–B6
A varredura das chaves do relato passa de 5 para **12 chaves** (B1: `paGasto`, `estadoMorte`, `armaCaida`,
`armaQuebrada`, `corpoPartido`, `custoPA`, `dano`). As 10 camelCase contam sem distinguir maiúsculas (B4, `(?i)`) e não a
meio de outra palavra (B2, lookbehind: `capaLivre` passa). «alma» e «dano» só em forma de chave (B2: `"k"`, `'k'`, `k:`,
`k=`, `kCamel`, `k_snake`, `k` nua + número). Os limites que ficam estão escritos em `ferramentas/nomes_relato.gd` e
fixados no teste.

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `cobertura-correcoes/teste-nomes-relato.log`: **teste 23/23** (os 14 de antes, iguais, + 9 do §5; eram 5).
- `cobertura-correcoes/cliente/`: **prova viva 41/41**, 0 nomes verdadeiros e 0 das 12 chaves no relato. Capturas
  (sha256, 16 primeiros): `1-janela-1280x720.png` `88c434c6d428352c`, `2-baixo-844x390.png` `f9c92f6d42f8c7fc`,
  `3-baixo-780x360.png` `8fcff83eae9c3f93`.
- `cobertura-correcoes/mutacoes.log` + `cobertura-correcoes/m1b/`: a **M1b**, com valores reais (`paGasto` da vista do
  Mestre, `custoPA` da técnica). Na base passa calada (41/41, rc=0). Nesta ordem dá FALHA em 1, em 2 e no fim (38/41,
  rc=1). Os relatos mutados estão cometidos inteiros. Também lá estão as mutações MT1–MT4 do teste (17, 22, 21 e 21 de 23,
  todas com rc=1).
- `cobertura-correcoes/actualizar-listas.log`: o artefacto do `retoma-i0004/actualizar-listas.py` (B5).
