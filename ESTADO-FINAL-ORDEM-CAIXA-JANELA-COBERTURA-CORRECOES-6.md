# ESTADO FINAL — ORDEM CAIXA-JANELA-COBERTURA-CORRECOES-6 (Claude conta 2, PC · 22/11/2026)

Esta ordem faz as correcções B1–B3 da sentença da CAIXA-JANELA-COBERTURA-CORRECOES-5. As três mexem só em registo e
nenhuma é fuga.

- **Quem executou:** a **conta 2**. O lançador chama `run-claude-conta2.cmd` e o ramo tem o prefixo `claude2/`.
- **Ramo:** `claude2/caixa-janela-cobertura-correcoes-6`, **não fundido**.
- **Base:** `1b907bc`, a ponta de `fable/integracao-50` à hora do lançamento. Voltei a conferir antes do commit e
  continuava a ser a ponta.
- **Commits:**
  - `7f1dab7` tem B1–B3, as corridas, a conferência nova, a captura do `--import`, o `actualizar-listas` e o README.
  - O segundo commit volta a correr o `actualizar-listas` e junta este ficheiro.
- **A conferência:** não está neste PC, porque `~/workspace/conferencias/` não existe. Trabalhei pelo texto da ordem,
  que traz os pontos D1, D2 e O1, e conferi cada afirmação nas fontes.
- **Território:** só `provas/ordem-caixa-janela/` e este ESTADO-FINAL.
  - `git diff --stat 1b907bc -- rascunhos/ .github/` dá saída vazia, capturada em
    `cobertura-correcoes-6/actualizar-listas.log`.
  - Não toquei em código do jogo, HUD ou cores.
  - Os registos cometidos da CORRECOES-5 ficaram como estavam.
- **Privacidade:** não há valores novos. Os registos só trazem linhas de código citadas e os valores-canário de bancada.
  A sonda de privacidade do CI passou em `7f1dab7`.

Abaixo, as pastas são relativas a `provas/ordem-caixa-janela/`.

## 1. Ponto a ponto

### B1 — `alma` no `conferencia-fontes.log`: «não existe como chave/campo»

O registo da CORRECOES-5 é registo cometido e não se emenda. A correcção vai por isso no próximo log, que é
`cobertura-correcoes-6/conferencia-fontes.log`. Tirei-o da base `1b907bc` com os mesmos comandos e com as secções
(a)–(f).

- **O §0 confirma que as fontes não mudaram.** `git diff --stat 3b84797 1b907bc -- rascunhos/servidor/nucleo/
  rascunhos/servidor/autojogo/fichas-bancada.json` dá saída vazia, por isso os números de linha são os mesmos da
  CORRECOES-5.
- **O §(f) tem como título a frase da sentença:** «alma: não existe como chave/campo (a palavra ocorre 1× num comentário
  TODO, sala.js:615)».
- **As provas do §(f)**, com o comando, a saída e o rc de cada uma:
  - Nas 3 fontes da conferência:
    - `projecao.js`: 0 ocorrências da palavra.
    - `sala.js`: 1 ocorrência, a linha 615 (`// TODO(JV1.x): "comprometido" da alma (REF_7 §7) ainda não modelado.`).
    - `fichas-bancada.json`: 0 ocorrências.
  - Como chave ou campo (`alma:`, `'alma'`, `"alma"`, `.alma`), procurei em **todo** o `rascunhos/servidor/`. A saída é
    vazia (rc=1).
- **Um facto a mais, que registei para não repetir o erro ao contrário.** Fora das 3 fontes, a palavra aparece ainda em
  3 comentários de `nucleo/ordem-dinamica.js`, nas linhas 19, 126 e 156. São prosa das regras, do género «nenhum valor
  de vida ou de alma», e não chaves. O log mostra-os.

A frase da sentença, «1× num comentário TODO, sala.js:615», é exacta para as fontes que a conferência varre. Não é
exacta para o servidor inteiro, onde a palavra aparece 4 vezes, todas em comentários.

### B2 — a saída do `godot --import` capturada

Escolhi capturar a saída, em vez de retirar a afirmação. O ficheiro é `cobertura-correcoes-6/godot-import.log`.

- **Como correu:** num clone novo. O próprio log mostra que `rascunhos/cliente/.godot` não existia antes (`ls` com
  rc=2). Depois veio `timeout 600 "$G" --headless --path rascunhos/cliente --import`, com `$G` = o `_console.exe` do
  Godot 4.7.2. O caminho e o sha256 do executável estão no cabeçalho do log.
- **Resultado:** rc=0, 415 linhas e 0 `SCRIPT ERROR`/`Parse Error`/`Compile Error`.
- **Códigos de cor:** a saída traz os códigos ANSI que o Godot escreve, tal como saíram. Não os limpei.

A afirmação do §2 abaixo, sobre o `--import`, tem assim artefacto.

### B3 — os eventos do `dano:` no §(d)

O §(d) do log novo diz quais eventos levam a chave:
- o `dano:` do `soMestre` vem no evento **`raio`** (`sala.js:1351` abre, `:1353` leva-o, só quando há alvo);
- vem também no evento **`dano_ambiente`**, duas vezes: com origem raio (`:1357` → `:1359`) e com origem fogo
  (`:1365` → `:1367`);
- o evento chamado **`dano`** não o leva, porque emite com `soMestre` `null` (`:1918` e `:1925`; os dados dele são
  `alvoId`, `autorId`, `valor` e `tipos`).

**As provas**, todas no §(d) com o comando, a saída e o rc:
- `grep -c 'rd: 0, dano: r.aplicado'` dá **3**;
- as linhas dos `tx.emitir('raio'|'dano_ambiente'` estão intercaladas com essas 3;
- todas as chaves `dano:` de `sala.js` são só essas 3 (`1353`, `1359`, `1367`);
- as 2 chamadas `tx.emitir('dano', {…}, null)` aparecem inteiras.

A conta não muda: 8 chaves na vista, mais `paLivre` no `estado` e `dano` no `soMestre` de `raio`/`dano_ambiente`, dão
**10 das 12** chaves que o servidor emite. A linha final do log diz isto mesmo.

## 2. Corridas

Ambiente: PC, Godot 4.7.2 Windows `_console.exe`, Node, motor VLAB real sha256 `a91c021c…3261`, semente 7. Antes de
tudo, corri `godot --headless --path rascunhos/cliente --import` no clone novo: rc=0 e 0 SCRIPT ERROR. A saída está em
`cobertura-correcoes-6/godot-import.log` (B2).

| Corrida | Resultado | Registo |
|---|---|---|
| Importação do cliente | rc=0, 0 SCRIPT ERROR, 415 linhas | `cobertura-correcoes-6/godot-import.log` |
| Teste dos nomes do relato | **26/26**, rc=0, 0 SCRIPT ERROR; «correram as 25 verificações do teste (esperadas 25)». **Igual byte a byte** ao registo da CORRECOES-5 (`cmp`) | `cobertura-correcoes-6/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **41/41**, rc=0, 0 SCRIPT ERROR. 0 nomes verdadeiros e 0 achados das 17 chaves na passagem 1 (47 linhas), na passagem 2 (76) e no fim (78). O relato é **igual byte a byte** ao da CORRECOES-5 (`cmp`) | `cobertura-correcoes-6/cliente/relato.txt` |
| Conferência das fontes (B1, B3) | §0 com diff vazio. A conta continua 8 + `paLivre` + `dano` = 10. `alma` não aparece como chave. Os eventos do `dano:` são `raio`/`dano_ambiente` | `cobertura-correcoes-6/conferencia-fontes.log` |
| `actualizar-listas` | «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)». As listas ficaram iguais antes e depois | `cobertura-correcoes-6/actualizar-listas.log` |

- **Capturas da prova viva** (sha256, 16 primeiros caracteres):
  - `1-janela-1280x720.png`: `9fc06ba84c04ed5d`;
  - `2-baixo-844x390.png`: `e3f8a21e3cde48a6`;
  - `3-baixo-780x360.png`: `a43957257b8f8bab`.

  O relato é igual ao da CORRECOES-5, mas os PNG não. Já nas ordens anteriores mudavam de corrida para corrida.
- **SHA-256 das listas** (iguais antes e depois): `antes.txt` `cf3b16fa…`, `depois.txt` `b2fe7042…` e
  `MANIFESTO-SHA256.txt` `9433f1c2…`.
- **Não havia listas a sincronizar.** O script só olha para `rascunhos/`, e o ramo não lhe toca. Corri-o antes do commit
  do trabalho e outra vez antes do commit final.
- **Não corri as suites largas.** Esta ordem só junta registos e o README, e o CI corre-as todas (§3).

## 3. CI

| Workflow | Commit | Corrida | Resultado |
|---|---|---|---|
| «Testes dos rascunhos» | `7f1dab7` (trabalho) | 45027245901 | **verde, 10/10 jobs**: servidor, protocolo, provas-mapa, motor-real, ponta-a-ponta, **retoma-pc**, cliente, foto-mestre, validador-glb, godot-cliente |
| «Sonda de privacidade» | `7f1dab7` (trabalho) | 45027245891 | **verde** |

No job `cliente`, o passo «Nomes do relato da caixa-janela» dá **26 de 26** e «correram as 25 verificações do teste
(esperadas 25)».

O CI da ponta, que é o commit deste ESTADO-FINAL, não pode estar dentro deste ficheiro, como nas ordens anteriores. Dou-o
no relatório final da corrida.

## 4. Pontos para o coordenador

1. **B1: a frase da sentença vale para as 3 fontes, não para o servidor inteiro.**
   - Em `projecao.js`, `sala.js` e `fichas-bancada.json`, `alma` ocorre 1× (`sala.js:615`, TODO).
   - No núcleo há mais 3 comentários com a palavra, em `ordem-dinamica.js` nas linhas 19, 126 e 156.
   - Como chave, não existe em lado nenhum de `rascunhos/servidor/`.

   O log usa a frase da sentença no título do §(f) e mostra os 3 comentários à parte.
2. **B2: escolhi capturar a saída, em vez de retirar a afirmação.**
   - A saída do `--import` desta ordem está em `godot-import.log`.
   - O `--import` da CORRECOES-5 continua sem artefacto cometido. A saída dele ficou fora do repo, na sede dessa ordem
     (`…\ordem-caixa-janela-cobertura-correcoes-5\tmp\import.log`). Não a trouxe para o repo, porque o ESTADO-FINAL
     dessa ordem é registo cometido e não se emenda.
3. **A base não avançou durante esta ordem.** `origin/fable/integracao-50` estava em `1b907bc` ao lançar e antes do
   commit do trabalho.
4. **O `ORDEM.md` desta ordem**, como os das duas anteriores, não termina numa linha só com «Estado: NOVA». O último
   ponto da ordem cita essa linha. Segui a decisão registada: não toquei no ficheiro e não pus a linha aqui.
5. **As decisões registadas** ficaram como estavam:
   - «10 das 12 do servidor»;
   - a ressalva O2 da nota «conta 2» da CORRECOES-3, que continua por verificar pelo lançador no PC;
   - o avanço `3b84797` → `66da920` na ordem anterior.
