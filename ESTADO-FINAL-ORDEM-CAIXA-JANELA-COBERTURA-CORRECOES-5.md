# ESTADO FINAL — ORDEM CAIXA-JANELA-COBERTURA-CORRECOES-5 (Claude conta 2, PC · 22/11/2026)

As correcções B1–B3 da sentença da CAIXA-JANELA-COBERTURA-CORRECOES-4. As três mudam só prosa e registo; nenhuma é
fuga.

- **Quem executou:** a **conta 2**. O lançador chama `run-claude-conta2.cmd`, e o ramo tem o prefixo `claude2/`.
- **Ramo:** `claude2/caixa-janela-cobertura-correcoes-5`, **não fundido**.
- **Base:** `3b84797`, a ponta de `fable/integracao-50` à hora do lançamento.
- **Commits:**
  - `a2e0ba9`: B1, B2 e B3, as corridas, a conferência das fontes e o `actualizar-listas`;
  - o commit deste ESTADO-FINAL, que volta a correr o `actualizar-listas` e junta este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/` não existe). Trabalhei pelo texto da ordem, que
  traz os pontos D1, D2 e D4 da sentença, e conferi cada afirmação nas fontes.
- **Território:** só `provas/ordem-caixa-janela/` e este ESTADO-FINAL. `git diff --stat 3b84797 -- rascunhos/ .github/`
  dá saída vazia, capturada em `cobertura-correcoes-5/actualizar-listas.log`. Não toquei em código do jogo, HUD ou
  cores.
- **Privacidade:** não há valores novos. Os registos só trazem linhas de código citadas e os valores-canário de bancada.
  A sonda de privacidade do CI passou em `a2e0ba9`.

Abaixo, as pastas são relativas a `provas/ordem-caixa-janela/`.

## 1. Ponto a ponto

### B1 — «do Mestre» fora da linha 80

Em `ferramentas/nomes_relato.gd`, a linha 80, que abre o parágrafo C1:
- **antes:** `… da B7 da CAIXA-JANELA-NOMES-CORRECOES): as CHAVES privadas do Mestre`;
- **agora:** `… da B7 da CAIXA-JANELA-NOMES-CORRECOES): as CHAVES privadas`.

A frase seguinte («que nenhuma linha do relato pode trazer») não muda, e o parágrafo já não contradiz a tabela da
CORRECOES-4. **A prova** é o diff de `a2e0ba9` (`git show a2e0ba9 -- provas/ordem-caixa-janela/ferramentas/nomes_relato.gd`).

As outras ocorrências de «do Mestre» no ficheiro ficam como estão, porque estão certas:
- as linhas 14, 27, 37 e 84 dizem «vista do Mestre», que é a coisa certa;
- a linha 86 diz «NÃO são todas «só do Mestre»», que é a própria correcção da CORRECOES-4;
- as linhas 128 e 132 (o parágrafo da CORRECOES-3) dizem que `reacaoDisponivel`/`defendendo` «são mesmo só do Mestre»,
  o que é verdade.

### B2 — o que o Mestre recebe, preciso

**O que estava errado:** o parêntese antes da tabela (a antiga linha 87) dizia «o Mestre recebe-as todas, na vista do
Mestre». A linha do `custoPA` dizia «o Mestre e a dona».

**O que mudou:**
- **O parêntese** (agora nas linhas 87–91): «CORRECOES-5, B2: o Mestre recebe 10 das 12 do servidor — 8 nas figuras da
  vista do Mestre, `paLivre` no evento `estado` e `dano` no `soMestre`; a chave `custoPA` tem-na nas fichas que escreve e
  o servidor carrega, não na vista; `alma` não existe». A seguir vêm os dois registos da conferência, o da CORRECOES-4 e
  o desta ordem.
- **A linha do `custoPA`** na tabela: «a dona (na ficha); o Mestre tem-na nas fichas que carrega, não na vista». É a frase
  da ordem, partida em 3 linhas para caber na coluna.

**Uma diferença da frase sugerida, que tens de ver.** A ordem propunha «o Mestre recebe 11 das 12 na vista (`alma` não
existe)». Isso também não está certo. As fontes dão 8 na vista e 10 no total:
- **8 na vista** (`mestre.figuras` = `figuraDoMestre`, `projecao.js:190`):
  - 6 vêm da figura interna (`...clonarJson(fig)`, `projecao.js:152`; `novaFigura`, `sala.js:549–550`): `vidaActual`,
    `paGasto`, `estadoMorte`, `armaCaida`, `armaQuebrada` e `corpoPartido`;
  - 2 vêm da ficha: `vidaTotal` e `paTotal`.
- **`paLivre` não está na vista**, que traz o `paGasto`. Chega ao Mestre no evento `estado` (`sala.js:1315`), porque o
  Mestre recebe os dados do evento inteiros (`projetarEvento`, `projecao.js:117–121`).
- **`dano` também não está na vista.** Chega-lhe só no `soMestre` (3 linhas com `dano: r.aplicado` em `sala.js`).
- **`custoPA` não chega ao Mestre pelo servidor.** Não está na figura interna, `figuraDoMestre` não leva a ficha, e
  nenhuma das 8 ocorrências de `custoPA` no núcleo é um campo que se envie: são o esquema, os filtros das opções, a
  entrada do motor da cura e o débito.
- **`alma` não existe** em lado nenhum.

Escrevi «10 das 12 do servidor», que é o que as fontes mostram. As duas excepções, `custoPA` e `alma`, são as que a
sentença apontou. Se preferires a outra saída que a ordem permitia, que é retirar o parêntese, é uma linha.

**A prova:** `cobertura-correcoes-5/conferencia-fontes.log`. Cada linha foi tirada da base `3b84797` com o comando que a
deu, nas secções (a)–(f), e o log fecha com a conta: 8 + `paLivre` + `dano` = 10.

### B3 — a secção da CORRECOES-3 no README

O README de `provas/ordem-caixa-janela/` saltava de `cobertura-correcoes-2/` para `cobertura-correcoes-4/`. Agora tem a
secção `cobertura-correcoes-3/` entre as duas, reposta a partir dos registos dessa ordem:
- **o que fez:** B1 (quem recebe as 5 chaves novas), B2 (a razão certa de não listar `modo`; os limites passam de 13
  para 15 formas) e B3 (três linhas, não duas);
- **as corridas:** teste 25/25 e prova viva 41/41, com 47, 76 e 78 linhas nas passagens 1, 2 e fim;
- **os registos:** `conferencia-fontes.log` e `actualizar-listas.log`;
- **as capturas:** `6599f088d8e89519`, `0d79c56b84bf6f7c` e `283606fe52605c00`.

Antes de escrever, conferi tudo isto nos ficheiros da pasta: recalculei o sha256 das 3 capturas e li a última linha do
teste e do relato. A secção diz «Claude conta 2» e explica que o ESTADO-FINAL dessa ordem diz «conta 1», como a
CORRECOES-4 registou na B4.

Juntei também a secção `cobertura-correcoes-5/`, desta ordem, no fim do README.

## 2. Corridas

Ambiente: PC, Godot 4.7.2 Windows `_console.exe`, Node, motor VLAB real sha256 `a91c021c…3261`, semente 7. Antes de
tudo, corri `godot --headless --path rascunhos/cliente --import` no clone novo (rc=0, 0 SCRIPT ERROR).

| Corrida | Resultado | Registo |
|---|---|---|
| Teste dos nomes do relato | **26/26**, rc=0, 0 SCRIPT ERROR; «correram as 25 verificações do teste (esperadas 25)». Igual ao registo da CORRECOES-4, linha a linha | `cobertura-correcoes-5/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **41/41**, rc=0, 0 SCRIPT ERROR. 0 nomes verdadeiros e 0 achados das 17 chaves na passagem 1 (47 linhas), na 2 (76) e no fim (78). O relato é igual byte a byte ao da CORRECOES-4 | `cobertura-correcoes-5/cliente/relato.txt` |
| Conferência das fontes (B2) | 8 na vista, `paLivre` no `estado`, `dano` no `soMestre`; `custoPA` e `alma` sem saída | `cobertura-correcoes-5/conferencia-fontes.log` |
| `actualizar-listas` | «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos, 0 tirados nesta passagem)»; listas iguais antes e depois | `cobertura-correcoes-5/actualizar-listas.log` |

- **Capturas da prova viva** (sha256, 16 primeiros): `1-janela-1280x720.png` `6d9191e10994fe46`, `2-baixo-844x390.png`
  `99e615ac0c993d55` e `3-baixo-780x360.png` `ca3ec3ee02df0441`.
- **SHA-256 das listas** (iguais antes e depois): `antes.txt` `cf3b16fa…`, `depois.txt` `b2fe7042…` e
  `MANIFESTO-SHA256.txt` `9433f1c2…`.
- **Não havia listas a sincronizar.** O script só olha para `rascunhos/`, e o ramo não lhe toca. Corri-o antes do
  commit do trabalho e outra vez antes do commit final.
- **Não corri as suites largas.** Esta ordem só muda comentários e o README. O CI corre-as todas (§3).

## 3. CI

| Workflow | Commit | Corrida | Resultado |
|---|---|---|---|
| «Testes dos rascunhos» | `a2e0ba9` (trabalho) | 45021560317 | **verde, 10/10 jobs**: servidor, cliente, godot-cliente, protocolo, validador-glb, foto-mestre, provas-mapa, ponta-a-ponta, motor-real, **retoma-pc** |
| «Sonda de privacidade» | `a2e0ba9` (trabalho) | 45021560332 | **verde** |

No job `cliente`, o passo «Nomes do relato da caixa-janela» dá **26 de 26** e «correram as 25 verificações do teste
(esperadas 25)».

O CI da ponta, que é o commit deste ESTADO-FINAL, não pode estar dentro deste ficheiro. O coordenador já o aceitou
assim. Dou-o no relatório final da corrida.

## 4. Pontos para o coordenador

1. **B2: escrevi «10 das 12», e não «11 das 12».** A frase sugerida dava 11 na vista, mas as fontes dão 8 na vista e
   10 no total do servidor (§1, B2). Se preferires retirar o parêntese, como a ordem também permitia, é uma linha.
2. **A base avançou durante a ordem**, de `3b84797` para `66da920` (+3 commits: a CAIXA-TESTES-CORRECOES-9 e as listas
   do coordenador). `git diff --name-only 3b84797 66da920` dá 6 ficheiros:
   - 3 ESTADO-FINAL;
   - `rascunhos/servidor/testes/privacidade.test.mjs`;
   - `retoma-i0004/depois.txt` e `MANIFESTO-SHA256.txt`.

   Este ramo não toca em nenhum deles, nem nas fontes citadas (`projecao.js`, `sala.js`, `fichas-bancada.json`). Não
   fiz rebase. A fusão não deve ter conflitos, mas as listas da retoma, depois dela, são as da base nova.
3. **O `ORDEM.md` desta ordem**, como o da anterior, não termina numa linha só com «Estado: NOVA»; o último ponto cita
   essa linha. Segui a decisão registada: não toquei no ficheiro e não pus a linha aqui.
4. As decisões já registadas na ordem ficaram como estavam: 26/26, o CI da ponta fora do ESTADO-FINAL e o ESTADO-FINAL
   da CORRECOES-4 por emendar (§B3, `quit(2)` sem `_fim()`).
