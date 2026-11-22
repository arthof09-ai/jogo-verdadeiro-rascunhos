# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES-4 (Claude conta 2, PC do cunhado) · 22/11/2026

Fecha as correcções **B1–B6** da sentença da CAIXA-TESTES-CORRECOES-3. Mexe só no território da ordem e na
documentação. Em `rascunhos/` mudaram só `ajudantes.mjs`, `caixa-hud-jogadora.test.mjs` e `privacidade.test.mjs`. Fora
de `rascunhos/` mudaram `ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-3.md` (B3, B4 e a nota da B5), as listas da retoma e
este ficheiro. Nenhum código do jogo, do HUD, das cores ou do protocolo foi tocado, e a prova também não.

- **Base:** `origin/fable/integracao-50` @ `f747427` (a ponta à hora do lançamento). Clone novo, `core.autocrlf=false`.
- **Ramo:** `claude2/caixa-testes-correcoes-4`, **não fundido** (a fusão é do coordenador).
- **Commits, por ordem:** `18da5a6` (os testes e o ESTADO-FINAL da CORRECOES-3) e depois o commit das listas da
  retoma (`actualizar-listas.py`), que traz também este ficheiro. Se depois disto entrar um commit só com o resultado do
  CI, isso fica escrito no fim deste ficheiro, com a ordem certa.
- **Conferência:** `~/workspace/conferencias/caixa-testes-correcoes-3/` não está neste PC nem no repositório. Trabalhei
  pelo resumo da ordem. Os números da conferência (2403, os «15 snapshots, 5 ao espectador», os «17/17») bateram com o
  que encontrei: a aliada fica com 2403, e o guião de `privacidade` dá 5 snapshots a cada papel da Party.

## Ponto a ponto

### B1: a Vida variável da outra jogadora (`privacidade.test.mjs`, teste novo)
- **O defeito:** `NUMEROS_HEROINA` e `NUMEROS_ALIADA` só têm a Vida **máxima** (5150 e 3579). No guião, a aliada fica
  ferida com **2403** (3579 − 1176). Uma fuga dessa `vidaActual` no snapshot da heroína ou do espectador passava calada.
- **Agora:** o teste novo é «canários: a Vida actual (variável) de uma jogadora ferida não chega à outra jogadora nem ao
  espectador» e tem duas guardas.
  1. **Valor:** a `vidaActual` de cada jogadora é lida do estado da sala no fim do guião. Varre-se tudo o que a outra
     jogadora e o espectador receberam (snapshots e eventos), e esse valor não pode aparecer.
  2. **Forma, snapshot a snapshot:**
     - Cada `ROOM_SNAPSHOT` da Party é varrido à procura de todas as chaves `vidaActual`.
     - Na jogadora, a única permitida é a da `propria`, e a `propria.figuraId` tem de ser a dela. No espectador não pode
       haver nenhuma, nem `propria`.
     - As figuras públicas têm de ter as chaves exactas de `figuraPublica`: `id, lado, nomePublico, orientacao, visivel,
       x, y`.
- **Sanidade:**
  - A aliada tem de estar ferida (`vidaActual < vidaTotal`). A `vidaTotal` vem da **ficha**, porque a figura não a tem
    (`sala.js` `novaFigura`).
  - No último snapshot, cada jogadora vê a Vida actual **dela**: a aliada vê o 2403.
- **Prova** (mutações executadas com `tmp/mutar.py` na sede, depois revertidas; `nucleo limpo: True`):

  | Mutação (temporária, no código do jogo) | `privacidade` nova | `privacidade` antiga (`f747427`) | Suite nova |
  |---|---|---|---|
  | **M18** (a da conferência): `fugaB1` = a `vidaActual` das jogadoras feridas (`[2403]`) no topo de todo o ROOM_SNAPSHOT da Party (`sala.js` `mensagemSnapshot`) | **falha**, 8/9, no teste novo, l. 157: «heroina viu a Vida actual de aliada (2403)» | **passa calada** (8/8) | 417/419: o teste novo e a fixture do ecrã do Mestre |
  | **M18b**: `vidaActual` com a chave verdadeira na figura pública de cada jogadora (`projecao.js` `figuraPublica`) | **falha**, 7/9: o teste novo e o da «outra jogadora» | falha (7/8), mas só pelo 5150 da heroína, que é um valor fixo | 415/419 |

  A (c) de `caixa-hud-jogadora` não apanha a M18, e não tem de apanhar: nela ninguém da Party está ferido. A guarda
  está no guião de `privacidade`, que é onde há uma jogadora ferida.

### B2: a perícia `8642` em texto
- `ajudantes.mjs` exporta `TEXTOS_HEROINA = ['8642']`. A lista **não** entrou em `TEXTOS_SO_MESTRE`, porque essa lista
  também se varre na heroína e ia dar falso positivo na `propria` dela (`'1d20+8642'` na ficha). Vale só para a aliada
  e o espectador:
  - em `privacidade`, no teste da «outra jogadora», com a varredura de tudo o que a aliada e o espectador receberam;
  - na (c) de `caixa-hud-jogadora`, com `TEXTOS_PROIBIDOS_NO_SNAPSHOT` por papel (a mesma regra dos números): a heroína
    fica com `TEXTOS_SO_MESTRE`; a aliada e o espectador ficam com `TEXTOS_SO_MESTRE` e `TEXTOS_HEROINA`. Isto vale no
    snapshot do «voltar» e no da re-entrada da aliada.
- **Prova (M19, executada):** `fugaB2: '1d20+8642'` em **todo** o ROOM_SNAPSHOT (`sala.js` `mensagemSnapshot`).
  - `privacidade` nova: **falha**, 8/9, l. 134: «a aliada não vê a perícia da heroína em texto». A antiga **passa
    calada** (8/8).
  - `caixa-hud-jogadora` nova: **falha**, 8/9, na (c), l. 313: «aliada: canários do Mestre (e da outra jogadora) no
    snapshot do «voltar»», chave `fugaB2`. A **heroína passa** essa linha, por isso não há falso positivo na `propria`
    dela. A antiga **passa calada** (9/9).
  - Suite nova: 416/419 (a (c), a «outra jogadora» e a fixture do ecrã do Mestre).
  - Antes desta ordem, os dois ficheiros antigos davam 17/17 com a M19, como a conferência diz.

### B3: o parênteses da B4 e a frase do PC (`ESTADO-FINAL-ORDEM-CAIXA-TESTES-CORRECOES-3.md`)
- O parênteses foi reescrito. Os 10 saltados do job `servidor` são **8 de disco** e **2 de leitura de `../protocolo`**:
  - os 8 de disco (`SEM_DISCO`) são 5 da ordem 16 (`ordem16-journal-disco`) e 3 da ordem 17 (`ordem17-varredura`);
  - os 2 de `../protocolo` (`SEM_PROTOCOLO`) são os N19-1 e N19-2 de `ordem21-decisoes`.

  Nenhum dos 10 é de rede. Os textos de *skip* na corrida dizem isso mesmo: «sem escrita» e «sem leitura de
  ../protocolo».
- **A frase do PC foi re-verificada, não só marcada.** Corri `node --permission --allow-fs-read=<servidor>/* --test`
  sobre `f747427`. Deu **401 passam, 7 falham, 10 saltados**, e as 7 falhas são **todas** `ERR_ACCESS_DENIED` com
  `permission: 'Net'` (os 4 V20 e os 3 da ordem 30). Portanto «7 falham, todos de rede» **está certa**. O erro estava
  na frase seguinte, «No CI esses testes saltam-se»: no CI esses 7 **passam** (408 = 418 − 10). Riscada e corrigida.

### B4: o bullet «Commits:» do ESTADO-FINAL da CORRECOES-3
- O bullet foi corrigido. A ordem real é `38f0c48` (testes), `eb74bb7` (listas) e `c835986` (o CI no ESTADO-FINAL), e
  as listas **não** são o último commit.
- **A mais:** esses três SHA já não existem no ramo publicado. O ramo foi reescrito por cima de `15eab43`: o committer
  é `Muse CM-000009`, a 22/11 às 03:45 UTC, e as datas de autor são as mesmas. Hoje são `8870275`, `ae62dd9` e
  `f049089`, pela mesma ordem, tanto em `origin/claude2/caixa-testes-correcoes-3` como em `fable/integracao-50`. O
  bullet dá os dois conjuntos, e eu conferi a correspondência pelas mensagens e pelas datas de autor.

### B5: `NUMEROS_MESTRE_CAIXA` deriva das listas partilhadas
- Agora: `NUMEROS_MESTRE_CAIXA = [...NUMEROS_SO_MESTRE, ...NUMEROS_HEROINA, ...NUMEROS_ALIADA]` (congelada). É a mesma
  lista que `NUMEROS_PROIBIDOS_NO_SNAPSHOT.espectador`, que passou a apontar para ela: a caixa da Party não leva número
  de ninguém.
- **A cópia já tinha derivado:** faltavam **8642, 5551 e 2468** (a perícia e um número da heroína, e a CA da aliada).
  Com eles a lista fica mais apertada e não houve falso positivo: os dois testes que a usam passam.
- `CHAVES_MESTRE_CAIXA` fica local, porque é uma lista genuinamente própria, como a ordem permite. A nota 4 do
  ESTADO-FINAL da CORRECOES-3 («não há cópia nenhuma que possa derivar») foi anotada como falsa para os números.

### B6: o ataque da (c) no limite do alcance
- **Re-verificado:**
  - A aliada em (2,4) tapa a linha recta de (2,2) ao orc em (2,6). O caminho das casas (`distanciaCasas`, uma BFS de 4
    vizinhos com as outras figuras vivas a bloquear) dá **6 passos**.
  - O chicote chega a 9 m / 1,5 m = **6 casas** (`alcanceEmCasas`).
  - `6 ≤ 6 + EPS`: o ataque está **exactamente no limite**, e hoje é válido (a (c) passa).
- **Guarda:** antes do ataque, a (c) confirma a geometria com `deepEqual`: `casaM 1.5`, `alcanceM 9` e as casas da
  heroína, da aliada e do orc. Se alguma coisa mudar, a falha diz «B6: a geometria do ataque (6 passos = 6 casas, no
  limite) mudou — re-verifica o alcance antes de mexer na (c)», em vez de um `acao_invalida` sem explicação.
- O guião de `privacidade.test.mjs` tem **a mesma geometria** (heroína em (2,2), aliada em (2,4), orc em (2,6)), por
  isso está no mesmo limite. Isso fica escrito no comentário da (c). Não mexi no guião: com o `exigirAplicada` dele,
  uma mudança de geometria falha alto.

**Privacidade:** não há fuga viva. As fugas das mutações M18, M18b e M19 foram temporárias e revertidas
(`git checkout -- rascunhos/servidor/nucleo`, `nucleo limpo: True`). Os números e os nomes são os valores-canário de
bancada das fichas de teste.

## Números das corridas (PC, Node 26.13, sobre `f747427` + este ramo)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` (sem `--permission`) | **419/419**, 0 saltados (`caixa-hud-jogadora` 9/9, `privacidade` **9/9**: mais o teste novo da B1) |
| Prova `node provas/ordem-caixa/ferramentas/prova-servidor.mjs` (da raiz) | **PROVA OK** (11 passos; não tocada) |
| Conferência dos schemas (`PROTOCOLO_DUMP` + `conferir-schemas.py`) | **0 falhas** nas mensagens que saem (exit 0) |
| Servidor **com** `--permission` (na base, para a B3) | 401 passam, 7 falham (todos `permission: 'Net'`), 10 saltados (8 de disco e 2 de `../protocolo`) |

**No CI espero:** no job `servidor`, **409 passam + 10 saltados**, de 419; no job `protocolo`, **419/419**. O número sobe
1 por causa do teste novo da B1.

### As mutações (resumo)

| | Mutação | Suite nova | `privacidade` antiga | (c) antiga |
|---|---|---|---|---|
| M18 | `vidaActual` da jogadora ferida (2403) no topo do snapshot da Party | 417/419: o teste novo da B1 e a fixture do Mestre | **passa calada** | passa calada |
| M18b | `vidaActual` (com a chave) na figura pública das jogadoras | 415/419 | falha (só pelo 5150) | falha |
| M19 | `'1d20+8642'` em todo o ROOM_SNAPSHOT | 416/419: a (c) (aliada), a «outra jogadora» e a fixture do Mestre | **passa calada** | **passa calada** |

## Pontos para o coordenador

1. **O ramo da CORRECOES-3 foi reescrito depois da publicação.** Os SHA que a ordem e a sentença citam (`38f0c48`,
   `eb74bb7`, `c835986`) estão no clone do PC mas não no remoto, onde são `8870275`, `ae62dd9` e `f049089`. Ficam os
   dois no bullet (B4).
2. **A frase do PC estava certa;** a errada era a frase sobre o CI (B3). Não a marquei como «não verificada», porque a
   verifiquei.
3. **A guarda da B1 vive em `privacidade`**, o único guião com uma jogadora ferida. Se esse guião deixar de ferir a
   aliada, a sanidade «a aliada está ferida» falha alto.
4. **B5:** a lista derivada é **mais** apertada do que a cópia, porque entram 8642, 5551 e 2468.
5. **B6:** a (c) e o guião de `privacidade` estão os dois no limite do alcance (6 = 6). A (c) tem a guarda explícita; o
   guião tem a guarda implícita do `exigirAplicada`.
6. As decisões registadas na ordem (os verbos como canários, a B2 filtrada-vs-bruta, os `41`/`61`, o tripwire
   `contexto`) não foram tocadas.
7. O `ORDEM.md` da sede não foi tocado.
