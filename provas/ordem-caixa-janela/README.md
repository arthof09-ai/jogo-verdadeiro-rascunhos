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

## cobertura-correcoes-2/ — Ordem CAIXA-JANELA-COBERTURA-CORRECOES-2 (22/11/2026, Claude conta 1, PC): B1–B5
A varredura das chaves do relato passa de 12 para **17 chaves** (B1: `custoM`, `reservaM`, `perdeQuarto`,
`reacaoDisponivel`, `defendendo` — privadas reais, latentes, não vivas). `custoM`/`reservaM` com o `M` final só maiúsculo
(para «reservam»/«custom» não tropeçarem); `defendendo` só em forma de chave, como «alma»/«dano». Os limites novos (B2:
`modo` não listável, kebab `alma-total`/`dano-total`, `m` minúsculo) e o falso alarme aceite «a alma 3 vezes» (B5) estão
escritos em `ferramentas/nomes_relato.gd` e fixados no teste.

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `cobertura-correcoes-2/teste-nomes-relato.log`: **teste 25/25** (eram 23: + o caso do `custoM`, + o falso alarme B5).
- `cobertura-correcoes-2/cliente/`: **prova viva 41/41**, 0 nomes verdadeiros e 0 das 17 chaves no relato. Capturas
  (sha256, 16 primeiros): `1-janela-1280x720.png` `28a15fedf11d2e9e`, `2-baixo-844x390.png` `4053e9acff9e21be`,
  `3-baixo-780x360.png` `875701c2187f2a0e`.
- `cobertura-correcoes-2/mutacoes.log` + `cobertura-correcoes-2/m1c/`: a **M1c**, com o `custoM` real de `opcoes.mover`.
  Na base (`ed3ae11`, 12 chaves) passa calada (41/41, rc=0). Nesta ordem dá FALHA em 1, em 2 e no fim (38/41, rc=1;
  10 achados). Os relatos mutados diferem em **4 linhas** (as 3 verificações + o total). Também lá estão as mutações
  MT5–MT8 do teste (20, 23, 23 e 23 de 25, todas com rc=1; diffs em `cobertura-correcoes-2/mt*.diff`).
- `cobertura-correcoes-2/actualizar-listas.log`: o artefacto do `retoma-i0004/actualizar-listas.py` com a saída REAL
  capturada de cada comando (B4).

## cobertura-correcoes-3/ — Ordem CAIXA-JANELA-COBERTURA-CORRECOES-3 (22/11/2026, Claude conta 2, PC): B1–B3
(O ESTADO-FINAL desta ordem diz «conta 1», mas a ordem correu na conta 2, como a CORRECOES-4 registou na B4. Esta
secção foi reposta pela CORRECOES-5, na B3, a partir dos registos da pasta e do
`ESTADO-FINAL-ORDEM-CAIXA-JANELA-COBERTURA-CORRECOES-3.md`.)
- **B1:** a tabela das 5 chaves novas da CORRECOES-2 dizia «só o Mestre vê» para todas, e isso é falso para 3 delas.
  `custoM`, `reservaM` (`propria` do evento `movimento`; `custoM` em `opcoes.mover`, `reservaM` como `orcamentoM`) e
  `perdeQuarto` (`propria` da `desgraca`) chegam também à dona. `reacaoDisponivel` e `defendendo` são mesmo só do
  Mestre e nunca se projectam. O filtro não muda (as 17 continuam na lista). A tabela certa está no parágrafo
  «CAIXA-JANELA-COBERTURA-CORRECOES-3 (B1)» de `ferramentas/nomes_relato.gd`.
- **B2:** `modo` continua fora da lista, mas com a razão certa. O `modo=` do relato é o rótulo do cliente
  (`ordem_turnos.modo`, carregado do `ordemPor` da caixa), não o H10 (o `modo` de cada figura, `manual`/`semi`/`auto`,
  que nunca se projecta). O latente fica fixado no §5 do teste: os limites passam de 13 para **15 formas que escapam
  por desenho** (`  x modo=auto`, `  x {"modo":"manual"}`).
- **B3:** a prosa do §5 da CORRECOES-2 ganhou três linhas, não duas (o ESTADO-FINAL dessa ordem não se emenda).

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `cobertura-correcoes-3/teste-nomes-relato.log`: **teste 25/25** (as mesmas 25; a dos limites varre agora 15 formas).
- `cobertura-correcoes-3/cliente/`: **prova viva 41/41**, 0 nomes verdadeiros e 0 das 17 chaves no relato (passagem 1:
  47 linhas, passagem 2: 76, fim: 78). Capturas (sha256, 16 primeiros): `1-janela-1280x720.png` `6599f088d8e89519`,
  `2-baixo-844x390.png` `0d79c56b84bf6f7c`, `3-baixo-780x360.png` `283606fe52605c00`.
- `cobertura-correcoes-3/conferencia-fontes.log`: cada linha citada nas B1–B3, tirada da base `ba56b7e` com o comando
  que a deu (`reacaoDisponivel`/`defendendo` ausentes de `projecao.js` e de `ordem-dinamica.js`).
- `cobertura-correcoes-3/actualizar-listas.log`: o artefacto do `retoma-i0004/actualizar-listas.py` (0 novos, 0 tirados).

## cobertura-correcoes-4/ — Ordem CAIXA-JANELA-COBERTURA-CORRECOES-4 (22/11/2026, Claude conta 2, PC): B1–B4
- **B1:** o parágrafo antigo do cabeçalho de `ferramentas/nomes_relato.gd` (as 12 chaves da CORRECOES, que dizia
  «só o Mestre vê») tem agora a tabela de quem recebe cada uma. **9 das 12 chegam à dona**: as 6 do `estado`
  (`vidaActual`, `paLivre`, `estadoMorte`, `armaCaida`, `armaQuebrada`, `corpoPartido`), `vidaTotal`/`paTotal` (no
  `base.propria` do snapshot) e `custoPA` (dentro da própria ficha). `paGasto`, `alma` e `dano` não chegam a ela como
  chaves. O filtro não muda. A conferência está em `cobertura-correcoes-4/conferencia-fontes.log`.
- **B2:** os rótulos da prova viva dizem «nenhuma chave privada no relato» e «nenhuma das 17 chaves privadas» (já não
  dizem «do Mestre»). A prosa do §5 do teste tem os dois rótulos novos e mantém os antigos.
- **B3:** o teste afirma o total no `_fim()` (`VERIFICACOES` = 25). A verificação do total é ela própria um `_ok`, por
  isso a linha final diz **26 de 26**.

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `cobertura-correcoes-4/teste-nomes-relato.log`: **teste 26/26** (as 25 de antes + a do total).
- `cobertura-correcoes-4/cliente/`: **prova viva 41/41**, 0 nomes verdadeiros e 0 das 17 chaves no relato. Capturas
  (sha256, 16 primeiros): `1-janela-1280x720.png` `3236673a0ce143d5`, `2-baixo-844x390.png` `00896476369c1b8c`,
  `3-baixo-780x360.png` `561363927bab83f2`.
- `cobertura-correcoes-4/mutacoes.log`: as mutações MT9–MT11 da B3, com uma verificação apagada, o ciclo dos custos com
  2 voltas e uma verificação a mais. Dão 24 de 25, 24 de 25 e 26 de 27, todas com rc=1.
- `cobertura-correcoes-4/actualizar-listas.log`: o artefacto do `retoma-i0004/actualizar-listas.py`.

## cobertura-correcoes-5/ — Ordem CAIXA-JANELA-COBERTURA-CORRECOES-5 (22/11/2026, Claude conta 2, PC): B1–B3
Só prosa e registo; o código do teste e da prova não muda.
- **B1:** o parágrafo C1 do cabeçalho de `ferramentas/nomes_relato.gd` abria com «as CHAVES privadas do Mestre», o que a
  tabela da CORRECOES-4, umas linhas abaixo, contradiz. Diz agora «as CHAVES privadas».
- **B2:** o parêntese antes da tabela dizia «o Mestre recebe-as todas, na vista do Mestre». Diz agora que o Mestre
  recebe **10 das 12** do servidor: 8 nas figuras da vista do Mestre, `paLivre` no evento `estado` e `dano` no
  `soMestre`. A chave `custoPA` só a tem nas fichas que escreve e o servidor carrega, não na vista, e `alma` não existe. A
  linha do `custoPA` na tabela diz «a dona (na ficha); o Mestre tem-na nas fichas que carrega, não na vista». A
  conferência está em `cobertura-correcoes-5/conferencia-fontes.log`.
- **B3:** a secção `cobertura-correcoes-3/` deste README, que faltava, foi reposta a partir dos registos dessa ordem.

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `cobertura-correcoes-5/teste-nomes-relato.log`: **teste 26/26**, igual ao da CORRECOES-4 linha a linha.
- `cobertura-correcoes-5/cliente/`: **prova viva 41/41**, 0 nomes verdadeiros e 0 das 17 chaves no relato (passagem 1:
  47 linhas, passagem 2: 76, fim: 78). O relato é igual byte a byte ao da CORRECOES-4. Capturas (sha256, 16
  primeiros): `1-janela-1280x720.png` `6d9191e10994fe46`, `2-baixo-844x390.png` `99e615ac0c993d55`,
  `3-baixo-780x360.png` `ca3ec3ee02df0441`.
- `cobertura-correcoes-5/actualizar-listas.log`: o artefacto do `retoma-i0004/actualizar-listas.py`.

## cobertura-correcoes-6/ — Ordem CAIXA-JANELA-COBERTURA-CORRECOES-6 (22/11/2026, Claude conta 2, PC): B1–B3
Só registo. O código do teste e da prova não muda, e o registo cometido da CORRECOES-5 também não.
- **B1 e B3:** a conferência das fontes foi tirada de novo da base `1b907bc`, que tem as mesmas fontes que `3b84797`
  (diff vazio, §0 do log), e está em `cobertura-correcoes-6/conferencia-fontes.log`.
  - **§(f), B1:** «`alma`: não existe como chave/campo (a palavra ocorre 1× num comentário TODO, `sala.js:615`)». Nas
    3 fontes da conferência, a palavra só aparece nessa linha. Como chave (`alma:`, `'alma'`, `"alma"`, `.alma`) não
    aparece em lado nenhum de `rascunhos/servidor/`. Fora dessas fontes, aparece ainda em 3 comentários de
    `ordem-dinamica.js`, que são prosa das regras e não chaves.
  - **§(d), B3:** o `dano:` do `soMestre` vem nos eventos `raio` (`sala.js:1353`) e `dano_ambiente` (`:1359`, com
    origem raio, e `:1367`, com origem fogo). O evento chamado `dano` não o leva, porque emite com `soMestre` `null`
    (`:1918`, `:1925`).
- **B2:** a saída do `godot --headless --path rascunhos/cliente --import`, corrido no clone novo e sem `.godot/`, está
  em `cobertura-correcoes-6/godot-import.log`: rc=0 e 0 SCRIPT ERROR.

Corridas (Godot 4.7.2 Windows, `_console.exe`; motor VLAB real sha256 `a91c021c…`; semente 7):
- `cobertura-correcoes-6/teste-nomes-relato.log`: **teste 26/26**, igual byte a byte ao da CORRECOES-5.
- `cobertura-correcoes-6/cliente/`: **prova viva 41/41**, 0 nomes verdadeiros e 0 das 17 chaves no relato (passagem 1:
  47 linhas, passagem 2: 76, fim: 78). O relato é igual byte a byte ao da CORRECOES-5. Capturas (sha256, 16
  primeiros): `1-janela-1280x720.png` `9fc06ba84c04ed5d`, `2-baixo-844x390.png` `e3f8a21e3cde48a6`,
  `3-baixo-780x360.png` `a43957257b8f8bab`.
- `cobertura-correcoes-6/actualizar-listas.log`: o artefacto do `retoma-i0004/actualizar-listas.py`.
