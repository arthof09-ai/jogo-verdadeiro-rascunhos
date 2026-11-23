# Provas — Ordem CAIXA-EXPANDE-VISTAS (22/11/2026, Claude conta 2, PC)

A F15 da sentença da CAIXA-EXPANDE (conferência 820): medir as vistas que faltavam à caixa da ordem.
- **D4** — no ecrã do Mestre a caixa não tinha limite de largura, e a protecção dos controlos de andar usava o rectângulo
  da vista compacta mesmo com a expandida aberta.
- **D2 (C2)** — com 12 e 16 figuras, só a barra fina do tema diz que a lista continua. Aqui só se mede e fotografa:
  **a barra não se muda**.

## mestre/ — o ecrã do Mestre com a expandida aberta, com a correcção (30/30)
Ferramenta: `ferramentas/foto_mestre_vistas.gd`, com render, a partir de `rascunhos/cliente`:

    <godot.exe> --resolution 844x390 --path rascunhos/cliente -s <repo>/provas/ordem-caixa-expande-vistas/ferramentas/foto_mestre_vistas.gd -- --saida=<pasta>

- A vista vem da fixture do servidor (`dados-exemplo/mesa-mestre.json`). Juntam-se criaturas de ensaio até haver 12 e 16
  figuras, em modo iniciativa. São as mesmas da suite `testes/medir_mestre.gd`.
- Em 844×390 e 780×360, com 12 e com 16 figuras, há três capturas:
  - `mestre-aberta-*`: a expandida aberta pelo rato a sério, com a lista no topo;
  - `mestre-fim-*`: a lista levada ao fim pela roda;
  - `mestre-rato-na-folha-*`: o rato e um clique na folha, à altura da caixa.
- `mestre-livre-aberta-16-figuras-1920x1080.png`: a câmara livre com a expandida aberta. A lista pára acima do manípulo.
- As medidas e as verificações estão em `foto_mestre.log`.

## sem-correcao/ — o mesmo, com o `mestre.gd` da ponta 8b78867 (25/30)
Corri a mesma ferramenta e a suite com o `cenas/mestre/mestre.gd` da ponta, só na cópia de trabalho, e depois reposto.
- Em 780×360 a expandida entra na folha: acaba em x = 883 com 12 figuras e em x = 917 com 16, e a folha começa em 867.
- Com o rato na folha, a caixa fica aberta por baixo dela.
- Na câmara livre, em 1920×1080 com 16 figuras, a expandida tapa o manípulo.
- `medir_mestre.log` dá 125 ok e 5 falhas, que são exactamente as do D4.

## cliente/ — a prova viva, 241/241
É a ferramenta da CAIXA-EXPANDE (`provas/ordem-caixa-expande/ferramentas/prova_caixa_expande.gd`) com o passo 12 novo.
- O lançador é `ferramentas/correr-prova-vistas.sh`, uma cópia do da CAIXA-EXPANDE-INTERACAO que escreve aqui.
- O cliente real liga-se pela Rede ao servidor de mesa real, com o motor VLAB `a91c021c…`, a semente 7 e o manequim de
  referência.
- **Passo 12**: corre dentro do ciclo do 11, com as mesmas 12 e 16 figuras, em 844×390 e 780×360, a seguir aos 3 gestos.
  Com a expandida aberta pelo rato mede-se:
  - a lista no topo, sem rolar: as linhas inteiras à vista e a que a borda inferior corta;
  - a lista depois de um passo da roda;
  - a lista no fim;
  - a barra do tema: se está à vista, a largura, a altura e a pega.
- Capturas `12-barra-{topo,meio,fim}-N-figuras-WxH.png`. Todas têm também um recorte da caixa, ampliado 3× ao píxel
  (`-recorte.png`), para o olho ver a barra. O recorte é a mesma imagem, só cortada.

Verificações por passo: 0 → 1 · 1 → 22 · 2 → 20 · 3 → 4 · 4 → 22 · 5 → 20 · 6 → 17 · 7 → 31 · 8 → 18 · 9 → 6 ·
10 → 9 · 11 → 38 · **12 → 32**, mais 1 da abertura do manequim. Os passos 0 a 11 dão os mesmos 209 da
CAIXA-EXPANDE-INTERACAO.

O PIN do Mestre é novo por corrida e só passa por `--pin=`. O info e o log do servidor ficaram na pasta temporária.

## suite/
- `medir_mestre.log`: **0 falhas, 130 ok**. Na ponta eram 87; as 43 novas são do D4.
- `caixa_janela.log` 123/123, `caixa_jogadora.log` 58/58, e `caixa_jogadora-estrita.log` 57/58, com a mesma falha de
  sempre (780×360, 11,5 u).
- `resumo-alheios.txt`: a última linha dos outros passos do cliente. Os logs inteiros não se cometem: o do
  `teste_nomes_relato` imprime nomes verdadeiros de propósito.

## SHA-256 das capturas novas
| ficheiro | SHA-256 |
|---|---|
| `cliente/12-barra-fim-12-figuras-780x360-recorte.png` | `4d89d4acab7247f061d56643eb0bef8a26bf415bb072d28b539408b95918b25b` |
| `cliente/12-barra-fim-12-figuras-780x360.png` | `f9dfbf92f75d5b9eea6495f2e668275ba0657bb7fc5582d48b57f85f5b80b267` |
| `cliente/12-barra-fim-12-figuras-844x390-recorte.png` | `d3e3ff507103f464ee017c50c1fea7717e70e447bbb12ea1c0fd9f4f76bdd278` |
| `cliente/12-barra-fim-12-figuras-844x390.png` | `080605235fba08ced5acead06691ec86a6f84964da9ce5e1d272be9b2041b783` |
| `cliente/12-barra-fim-16-figuras-780x360-recorte.png` | `1f508229b808f94673461a42ec923bf4ee540192ac87deece70ee3a9fb9b271a` |
| `cliente/12-barra-fim-16-figuras-780x360.png` | `ba1a785cd2e003dedfef51bb9e52fdcc475ec372c1e18a109f17b9b4c238cf28` |
| `cliente/12-barra-fim-16-figuras-844x390-recorte.png` | `c8752ca0d5d45b8d1b8463dc000b7098f3f4cce39a1b20c96c7a3897c38a6147` |
| `cliente/12-barra-fim-16-figuras-844x390.png` | `1cc4b1b3c8f30c76d72dab9e2d44cdc011284162ce5a01fac2494300a4d703e7` |
| `cliente/12-barra-meio-12-figuras-780x360-recorte.png` | `4b2568dfa7a139d0adc10f438d0ccfa821d233612e7cbbd902a98696b6486b74` |
| `cliente/12-barra-meio-12-figuras-780x360.png` | `8365321562957145a6100bbea615fb1ccb05fa2ebd535c39a1fbf8345fa9ae73` |
| `cliente/12-barra-meio-12-figuras-844x390-recorte.png` | `758de8ade44252841e2beb67514af297a2bd285c64342e5d0b825bd44457ffa0` |
| `cliente/12-barra-meio-12-figuras-844x390.png` | `3363f9129517bfd77fde4a46823ae714e9f96ea825dd4e6a267bf404bf097c66` |
| `cliente/12-barra-meio-16-figuras-780x360-recorte.png` | `63c2db632e3dcf5978b4991a0ab95f63c279dab9090d7872f68f1cfc0c9ec4a2` |
| `cliente/12-barra-meio-16-figuras-780x360.png` | `0a31390dc0bea24a69f6cf08d912588f8f2944ffc175078b16d0642bfc02fa1d` |
| `cliente/12-barra-meio-16-figuras-844x390-recorte.png` | `0156a899cf5125c2adb782fa27a9ec91752934038552cee02724df46aefd23d1` |
| `cliente/12-barra-meio-16-figuras-844x390.png` | `a89aaf9411d41dd9df3ce9894d39e8bbf81da7ced43d8459a3fc3126e12d8d13` |
| `cliente/12-barra-topo-12-figuras-780x360-recorte.png` | `7887e6e9fff4f193ef55cb3b8bced9fa27ad02eb3b6b8c6dcb40de725bd6320e` |
| `cliente/12-barra-topo-12-figuras-780x360.png` | `88017ac8fc5d4a76e78c7da397567ddbec94a6ddaf8425e00b17a10609854389` |
| `cliente/12-barra-topo-12-figuras-844x390-recorte.png` | `ef24bf38242bbbedff8c15c840f1c3a147e679ee2613d2b5773c0a5bebc3b0ba` |
| `cliente/12-barra-topo-12-figuras-844x390.png` | `ae6d91b9c39718717bbc2077210274658da2c213c85387f8405f54c5626df1e0` |
| `cliente/12-barra-topo-16-figuras-780x360-recorte.png` | `a208f8cef646b51bebff0f82f796443592e3f811e8b81fce914f00a1886080c5` |
| `cliente/12-barra-topo-16-figuras-780x360.png` | `8f3e853f8678bed251d92b162c1593287cb891c4fe8333c451f40f73ccf67787` |
| `cliente/12-barra-topo-16-figuras-844x390-recorte.png` | `f3839e1116cfc99d8c43029f72ad6fa549babb424b2082fa653a6090de0d3f25` |
| `cliente/12-barra-topo-16-figuras-844x390.png` | `00c2d34e7aa3865c51d9a8a8f55a0ba8aec0a6c419d0f59c6a488c5fe8ad3992` |
| `mestre/mestre-aberta-12-figuras-780x360.png` | `4f8f15f1313d7d57530d68eeebba92fe6e22a881b051cbbc2a4b29a7b56c5792` |
| `mestre/mestre-aberta-12-figuras-844x390.png` | `73ed6c3789aa5367c42376ba130cfd532c0d20e713379bdd7dbf09b79b52368d` |
| `mestre/mestre-aberta-16-figuras-780x360.png` | `c9fadca50b1e617c1baa4b4312833016423b608719a167ae7a2c51776879631f` |
| `mestre/mestre-aberta-16-figuras-844x390.png` | `168665d54c4b4946639b20af5aaad451451e68b0e577c36cb5ea679738d26e2e` |
| `mestre/mestre-fim-12-figuras-780x360.png` | `711ba4b19d5bb286f860e3b890978124f053c8f8f78972bf309f4cb521e9de91` |
| `mestre/mestre-fim-12-figuras-844x390.png` | `6f1f8ace43cf35f9bd72b77f41a1775f0b0ecacbd81398cb8bc319b00be9cb0b` |
| `mestre/mestre-fim-16-figuras-780x360.png` | `a0896482423d4f255e4ec45b109ccc06e7be565ec8c0139f711bc5d7f871c768` |
| `mestre/mestre-fim-16-figuras-844x390.png` | `b9f05b81c6a37e4bd90c4a3b6d190a1dc71091c912f2a45b95a400dc52e5006d` |
| `mestre/mestre-livre-aberta-16-figuras-1920x1080.png` | `0f03f9ab565960b8d3dbe078f8c126faf005d8bde037a00791b5aedb0dcdaa22` |
| `mestre/mestre-rato-na-folha-12-figuras-780x360.png` | `252430ad622d9faee3919661deddca1eddffe4eaa58ee31f056b202ddc789eee` |
| `mestre/mestre-rato-na-folha-12-figuras-844x390.png` | `ebbfe438d6eacd0d7ffb06b481ad385995f08c94ec209684312aa799a9082c14` |
| `mestre/mestre-rato-na-folha-16-figuras-780x360.png` | `8c73b2d6b68d5cc458d2f6c60e70de2969dd54df8d2e27ac014dea7ac6606645` |
| `mestre/mestre-rato-na-folha-16-figuras-844x390.png` | `600c358c7c9be43e3067735a4bf130dfb59d9f44cd7e667319d81b84fd460901` |
| `sem-correcao/sem-correcao-mestre-aberta-12-figuras-780x360.png` | `a66b1891382512d2e96d25ee3387036a542c57ce282ed4d00180520793fa9d6c` |
| `sem-correcao/sem-correcao-mestre-aberta-16-figuras-780x360.png` | `247852658e90e9d90a9c8738ca14a7792976be71379d209e9381a5c807738227` |
| `sem-correcao/sem-correcao-mestre-livre-aberta-16-figuras-1920x1080.png` | `47c693352df560a3508d2283b9e2120894782bf6261b60c631f9ebea0c320bed` |
| `sem-correcao/sem-correcao-mestre-rato-na-folha-16-figuras-780x360.png` | `06246f8426e4bc108c561bbbe20cdbbbdde0fc4ecf20ccf04d05a7cf552567c2` |
