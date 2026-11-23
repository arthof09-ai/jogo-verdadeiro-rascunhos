# Provas — Ordem CAIXA-EXPANDE-INTERACAO (22/11/2026, Claude conta 1, PC)

A F14 da sentença da CAIXA-EXPANDE: a interacção da caixa da ordem, 3 defeitos.
- **D1** — com a expandida aberta por toque, o toque fora que a fecha também dava um comando ao tabuleiro.
- **D2** — a rolagem da lista nunca tinha sido provada por um gesto.
- **D3** — a roda no topo ou no fim da lista passava para o tabuleiro e dava zoom.

## cliente/ — prova viva, 209/209
É a ferramenta da CAIXA-EXPANDE (`provas/ordem-caixa-expande/ferramentas/prova_caixa_expande.gd`) com duas mudanças.
O lançador é `ferramentas/correr-prova-interacao.sh`, uma cópia do da CAIXA-EXPANDE que escreve aqui. A semente é 7 e o
motor VLAB é o `a91c021c…`. A cena usa o manequim de referência.
- **passo 8**: a lista rola até ao fim com a roda do rato a sério, e já não com `scroll_vertical = max_value` posto pelo
  código. Em 780×360, com 9 figuras, mediu-se de 0 a 49 u em 2 passos da roda (`8-expandida-780x360-fim.png`).
- **passo 11** (novo, a seguir ao 10): o Mestre de ensaio põe criaturas até a ordem ter 12 figuras e depois 16. Em
  844×390 e em 780×360:
  - **D2** — a roda rola a lista (`11-roda-fim-*.png` mostra-a no fim). O arrastar com o botão do rato mede-se e fica
    registado (`REGISTO ARRASTAR`).
  - **D3** — a roda no fim e no topo da lista não muda o zoom da câmara da arena. De controlo: a roda fora da caixa
    muda o zoom.
  - **D1** — a expandida abre-se por toque, pelo `Input` do motor (`11-toque-aberta-*.png`). O motor imita o rato a
    partir do toque, como num aparelho. Um toque fora fecha-a, e o tabuleiro fica quieto (`11-toque-fora-*.png`): o
    `toque` da câmara não dispara, as figuras ficam no sítio (nó e casa do Estado), o modo e o cursor da arena não
    mudam, e não sai nenhuma intenção. De controlo: com a caixa fechada, o toque seguinte chega ao tabuleiro.

Verificações por passo: 0 → 1 · 1 → 22 · 2 → 20 · 3 → 4 · 4 → 22 · 5 → 20 · 6 → 17 · 7 → 31 · 8 → 18 · 9 → 6 ·
10 → 9 · 11 → 38 · mais 1 da abertura do manequim.

O PIN do Mestre é novo em cada corrida e só passa por `--pin=`. O info e o log do servidor ficam na pasta temporária.
O relato só leva nomes públicos: 0 nomes verdadeiros inteiros.

## suite/ — as suites da caixa
- `caixa_janela.log` dá **123/123**. A verificação «o que não cabe rola por dentro» comparava as mesmas alturas dos dois
  lados. Agora prova a rolagem com a roda do rato (`MEDIDA RODA`) e regista o arrastar (`REGISTO ARRASTAR`). O número de
  verificações não mudou: o CI exige «123 de 123».
- `caixa_jogadora.log` dá **58/58**. Eram 42; o §10 junta 16 verificações (D1 e D3 com a câmara da mesa a sério, com 12
  e 16 figuras, em 844×390 e 780×360). Com `--estrita` dá 57/58 (`caixa_jogadora-estrita.log`): a falha é a de
  sempre, 780×360 com 11,5 u.
- `resumo-alheios.txt` tem a última linha de cada um dos outros passos do cliente. Os logs inteiros desses passos não se
  cometem, porque trazem o texto das suites deles, e o `teste_nomes_relato` imprime nomes verdadeiros de propósito.

## sem-correcao/ — as suites novas contra a caixa da ponta 0bebd76
Corri as duas suites com o `hud/caixa_ordem.gd` da ponta, sem a correcção, só na cópia de trabalho, e depois reposto.
- `caixa_jogadora` dá **50/58**. Falham exactamente as 8 verificações D1/D3: o `toque` dispara 1 vez e o zoom vai de
  1,500 a 1,815.
- `caixa_janela` dá 123/123. O D2 era uma falta de prova e não um defeito do código: a roda já rolava a lista.

## mutacao/ — o guião da CAIXA-JANELA-CI na ponta desta ordem
`mutacao-celulas.resumo.txt`: 9 falhas, todas do assert B6, «114 de 123», 0 erros, e o ficheiro reposto.

| ficheiro | SHA-256 |
|---|---|
| `cliente/8-expandida-780x360-fim.png` | `7a5b6b3dfa9c7231f590e0e7580e6e8e628eb61b1acc97ac32fc156fc91a658c` |
| `cliente/11-roda-fim-12-figuras-844x390.png` | `77c8f501efce2ac32fbd05c9373789a85f4978fa80e36223a584c11520484fdb` |
| `cliente/11-roda-fim-12-figuras-780x360.png` | `db77f317fcd53908343b14133247753513fe32daa2fc924e5dfdb9e00d936a79` |
| `cliente/11-roda-fim-16-figuras-844x390.png` | `6b0809ea09413eb534afbbfeacfa9ec96167c25156545e04d5401d9e6d284206` |
| `cliente/11-roda-fim-16-figuras-780x360.png` | `76688eaffaa29464009218271049bcf7bc7218c4c49e274b51b2e2c5d4f0292f` |
| `cliente/11-toque-aberta-12-figuras-844x390.png` | `1de04a7f5d492184b9fc85cec614bb76033c81b1352ced6cc03fce2c83e76e4e` |
| `cliente/11-toque-aberta-12-figuras-780x360.png` | `bab8a398102c9cc04f9b506b0e0c83c75073d859f6212de469de35e2ed015aae` |
| `cliente/11-toque-aberta-16-figuras-844x390.png` | `5c25dd8964f754e380a7f02ed640b82d7ecbef6d4306541abf82bcce5c848a73` |
| `cliente/11-toque-aberta-16-figuras-780x360.png` | `72993fa2d8108cc1fae7ca091be694eaf17a498b8b7a3090f2e19d19b45b280a` |
| `cliente/11-toque-fora-12-figuras-844x390.png` | `f29a802fe1eef01e34fec052137ac8188df77e85c10dafc2d00116890d8bd29c` |
| `cliente/11-toque-fora-12-figuras-780x360.png` | `9575f0e08099f5b75744ca1f6b709024132f8c0284b497d42ac742aa7f9d493a` |
| `cliente/11-toque-fora-16-figuras-844x390.png` | `7a52d9b9efa15e38a5ee225ea3e10ea20429ec5a35ebd50abb1c16252a9ac233` |
| `cliente/11-toque-fora-16-figuras-780x360.png` | `65763c3c65155e64ac75a7f3b1f64c11301d78c03d6debe6d5b2f5e6e73dc278` |
