# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-2 (Claude conta 2, PC do cunhado) · 21/11/2026

Fecha as correcções **B1–B7** da conferência da CAIXA-TESTES-CORRECOES. Só testes e um ESTADO-FINAL antigo:
`git diff --stat 0418d18..HEAD -- rascunhos` mostra só `caixa-hud-jogadora.test.mjs` e `privacidade.test.mjs` (mais as
listas da retoma, fora de `rascunhos/`). Nenhum código do jogo, de HUD, de cores ou de protocolo mudou; a prova
`prova-servidor.mjs` e o seu log não foram tocados.

- **Base:** `origin/fable/integracao-50` @ `0418d18` (a ponta à hora do lançamento; ainda a ponta à hora do commit).
  Clone novo, `core.autocrlf=false`.
- **Ramo:** `claude2/caixa-testes-correcoes-2`, **não fundido** (a fusão é do coordenador).
- **Commits:** o dos testes + B7 + este ESTADO-FINAL; depois o das listas da retoma (`actualizar-listas.py`:
  `MANIFESTO-SHA256.txt`, `retoma-i0004/depois.txt`; o `antes.txt` não mudou), que é o último.

## Ponto a ponto

### B1 (Privacidade D1): a varredura do snapshot do «voltar» por papel (`caixa-hud-jogadora.test.mjs`, teste (c))
- Antes: o snapshot inteiro de heroína, aliada e espectador varria-se com UMA lista (`NUMEROS_SO_MESTRE`), sem números
  de jogadoras. O espectador não tem `propria` (`projecao.js`), por isso a Vida da heroína (5150) no snapshot dele
  passava limpa; o mesmo para a Vida da aliada (3579) no da heroína.
- Agora: `NUMEROS_PROIBIDOS_NO_SNAPSHOT[k]`, por papel —
  - **heroína:** os só do Mestre + os da aliada (`2468, 3579, 1357`);
  - **aliada:** os só do Mestre + os da heroína (`8642, 5551, 5150, 4040`);
  - **espectador:** os só do Mestre + os das duas jogadoras (sem exclusões).
  As listas das jogadoras são as de `privacidade.test.mjs` (`NUMEROS_HEROINA`/`NUMEROS_ALIADA`).
- Sanidade da exclusão: a heroína tem `propria.vidaTotal === 5150`, a aliada `3579`, o espectador `propria === undefined`
  (a exclusão não está a esconder o que não existe).
- Justificação corrigida no comentário: cada jogadora recebe por desenho a **ficha inteira dela** em `propria`; só os
  números DELA ficam de fora.
- **Prova exigida** (`tmp/prova-b1.py` na sede, mutações temporárias em `projecao.js`, revertidas; núcleo limpo):

  | Mutação | (c) nova | (c) antiga (`0418d18`) |
  |---|---|---|
  | M11: `5150` (Vida da heroína) no topo do snapshot do **espectador** | **falha**: «espectador: canários do Mestre (e da outra jogadora) no snapshot do «voltar»», `chave fugaB1, valor 5150` | passa calada (9/9) |
  | M12: `3579` (Vida da aliada) na `propria` da **heroína** | **falha**: «heroina: canários …», `chave fugaB1, valor 3579` | passa calada (9/9) |

  Na suite inteira (com os testes novos), a M11 parte 2 testes ((c) e «"outra jogadora" e espectador não veem…») e a M12
  parte 4 ((c), «"outra jogadora"…», REF_19, a fixture do ecrã do Mestre) — mas o único que olha para o snapshot do
  «voltar» é a (c).

### B2 (Mecânica D1): a ordem no snapshot do `escolherCaixa`, na sanidade da (b) (`privacidade.test.mjs`)
- Para cada papel da Party, todos os snapshots com `caixa.ordemPor === 'iniciativa'` (os únicos são os do
  `escolherCaixa`: a sala começa em `dinamico`) trazem `ordemDinamica.ordem` **igual** a
  `estado().ordemDinamicaParty.ordem` (nada mexe nela depois das escolhas do guião). Afirma-se também que essa ordem tem
  2+ figuras, para uma ordem trocada se ver.
- **Morde:** a M5 (ordem da Party invertida só no snapshot do `escolherCaixa`) passava a suite calada (418/418); agora
  **falha a (b)** (417/418). Ver a tabela.

### B3 (Privacidade D2): `41, 61, 6601` e `SEMENTE` em `NUMEROS_SO_MESTRE`
- `NUMEROS_SO_MESTRE` passa a ser a lista inteira de `NUMEROS_MESTRE` de `privacidade.test.mjs`: `9137, 7777, 313, 41,
  61, 6601, 4949, 4848, 6363, 6464, SEMENTE` e os valores de iniciativa. `SEMENTE = 0xc0ffee11` (a mesma).
- Para a semente não ser um canário morto, a mesa da (c) abre agora com `rngSemente: () => SEMENTE` (`mesaEmCombate`
  aceita opções; os outros testes do ficheiro não mudam). A (c) passa igual.
- `41`/`61` são pequenos: o `procurarCanarios` já os ignora só em `seq`/`revision`/`rodada`/`x`/`y`. Nenhum falso
  positivo no snapshot do «voltar».

### B4 (Privacidade D3): os números dos inimigos em `NUMEROS_MESTRE_CAIXA`
- `9137, 4949, 6363, 6464` entraram. A lista é usada pelo teste «nada do Mestre na caixa da Party (canários)» e pela
  varredura da `caixa` na (c); ambos passam.

### B5 (Privacidade D4): `CHAVES_SO_MESTRE` completa
- Completei-a em vez de documentar omissões: as 18 chaves de `CHAVES_MESTRE` de `privacidade.test.mjs`. As 7 que
  faltavam — `recibo`, `verificacaoCritico`, `reacaoDefensiva`, `desgracaProposta`, `mestre`, `contexto`, `tokenHash` —
  não aparecem em nenhum snapshot do «voltar» da Party (nem na `propria.ficha`), por isso não há omissão a justificar.

### B6 (Privacidade D5): `textos` na (c)
- `TEXTOS_SO_MESTRE`: o PIN, as senhas das três (heroína, aliada, espectador), a semente escrita (`c0ffee11`,
  `C0FFEE11`, decimal), os nomes verdadeiros e os `fichaId` dos inimigos (`Orc Verdadeiro`, `orc-teste`, `lobo-teste`,
  `bandido-teste`) e `pagina-`. Os de `privacidade.test.mjs` que esta mesa pode ter (os `CANARIO-*` dos cartões e do
  ambiente não existem no guião da (c)). A varredura do snapshot inteiro do «voltar» leva-os.

### B7 (Mecânica D2): uma linha na nota ¹ da B3 (`ESTADO-FINAL-ORDEM-CAIXA-TESTES.md`)
- Acrescentada, datada: os totais actuais são **5** (topo) e **7** (dentro da `caixa`), com a (c) da B7 e o teste do
  lobby. Confirmados nesta corrida (M1 e M2 abaixo).

**Privacidade:** nenhuma fuga viva. Só asserções e varreduras sobre o que a Party já recebia; os números são os
valores-canário de bancada das fichas de teste. As fugas das mutações M11/M12 foram temporárias e revertidas.

## As mutações (temporárias, no código do jogo, todas revertidas)

`tmp/mutar.py` na sede (o da ordem anterior, com o caminho deste clone e M11/M12): cada mutação, a suite inteira
(`node --test testes/`) e a prova, depois `git checkout -- rascunhos/servidor/nucleo`. No fim: `nucleo limpo: True`.

| | Mutação | Suite | Prova |
|---|---|---|---|
| M1 | `caixaMestre` no topo do snapshot da Party | 413/418 — 5 falham: (b), (c), «por omissão», «segue para a Party», fixture | falha (l. 69) |
| M2 | `caixaMestre` dentro da `caixa` | 411/418 — 7 falham: (b), (c), «por omissão», «canários da caixa», «journal», «escolha feita no lobby», fixture | falha (l. 73) |
| M3 | `modo` no topo, só no snapshot do `escolherCaixa` | 417/418 — (b) | passa |
| M4 | `ligada` trocada, só nesse snapshot | 416/418 — «segue para a Party», «escolha feita no lobby» | falha (l. 76) |
| **M5** | **ordem da Party invertida, só nesse snapshot** | **417/418 — (b) (B2)**; antes 418/418 | falha (l. 77) |
| M6 | a tentativa proibida limpa a `ordemDinamicaParty` | 417/418 — (a) | passa |
| M7 | a tentativa proibida apaga o último ponto do «voltar» | 417/418 — (a) | passa |
| M8 | `vezes` na `ordemDinamica`, só nesse snapshot | 415/418 — (b), «canários da caixa», «escolha feita no lobby» | passa |
| M9 | `caixaMestre` nas `CHAVES_MUNDO` | 417/418 — (c) | falha (l. 145) |
| M10 | `modo` no topo, nos snapshots de todos («voltar»…) | 417/418 — (c) | passa |
| M11 | `5150` no snapshot do espectador (B1) | 416/418 — (c), «"outra jogadora" e espectador…» | passa |
| M12 | `3579` na `propria` da heroína (B1) | 414/418 — (c), «"outra jogadora"…», REF_19, fixture | passa |

M1–M10 dão o mesmo que na CAIXA-TESTES-CORRECOES, menos a M5, que agora a suite apanha.

## Números das corridas (PC, Node 26.13, Godot 4.7.2, sobre `0418d18` + este ramo)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` | **418/418** (`caixa-hud-jogadora` 9/9, `privacidade` 8/8) |
| Prova `prova-servidor.mjs` | **PROVA OK** (11 passos; não tocada) |
| Conferência dos schemas (`PROTOCOLO_DUMP` + `conferir-schemas.py`) | **0 falhas** nas mensagens que saem |
| Cliente `rodar_testes.gd` (headless, depois de `--import`) | **290/290**, 0 erros de script |
| Cliente `caixa_jogadora.gd` (headless) | **18/18**, 0 erros de script |

O número de testes do servidor é o da base: esta ordem só aperta testes que já existiam.

## Pontos para o coordenador

1. **B5 completada, não documentada:** as 18 chaves passam sem falso positivo. Se um dia a `propria.ficha` ganhar uma
   chave com um destes nomes (p. ex. `contexto`), a (c) falha e é preciso decidir se é fuga ou desenho.
2. **B3 tornou a semente viva na (c):** a mesa da (c) usa `rngSemente: () => SEMENTE`, como o guião de
   `privacidade.test.mjs`. Sem isso o canário `SEMENTE` só existia no papel.
3. **B2 assume que nada muda a `ordemDinamicaParty` depois das escolhas da caixa no `guiao()`** (só RESYNC/RECEIPT_QUERY).
   Se o guião crescer com jogadas depois da caixa, a asserção tem de comparar com a ordem capturada à hora da escolha.
4. **Listas partilhadas por cópia:** `CHAVES_SO_MESTRE`, `NUMEROS_SO_MESTRE`, `TEXTOS_SO_MESTRE` e os números das
   jogadoras são cópias das de `privacidade.test.mjs`. Movê-las para `ajudantes.mjs` evitaria a deriva — não o fiz
   (fora da letra da ordem).
5. **Ambiente do PC:** como na ordem anterior, os números são da corrida sem `--permission` (o Node 26 daqui recusa a
   rede nesse modo; o CI com o Node 24/22 não).
6. O `ORDEM.md` da sede não foi tocado. A última linha é o bullet que contém `<b>Estado: NOVA</b>`, e não uma linha só
   com isso (como na ordem anterior).
