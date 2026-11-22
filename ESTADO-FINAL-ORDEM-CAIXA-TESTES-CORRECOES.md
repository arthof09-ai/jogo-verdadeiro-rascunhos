# ESTADO FINAL — ORDEM CAIXA-TESTES-CORRECOES (Claude conta 1, PC do cunhado) · 21/11/2026

Fecha as correcções **B1 e B3–B7** da conferência da Ordem CAIXA-TESTES (veredicto FUNDE COM CORRECÇÕES 860). A B2 (passo
de CI da `prova-servidor.mjs`) é do coordenador e não foi tocada. Só a prova, os dois ficheiros de testes da CAIXA-TESTES
e os ESTADO-FINAL: `git diff --stat 0d26f9f..HEAD -- rascunhos` mostra só `caixa-hud-jogadora.test.mjs` e
`privacidade.test.mjs`. Nenhum código do jogo, de HUD ou de cores mudou.

- **Base:** `origin/fable/integracao-50` @ `0d26f9f` (a CAIXA-LOBBY e o passo B2 do CI). Parti de `6381f50`, a ponta à
  hora do lançamento. Enquanto eu trabalhava, a linha avançou 8 commits (a CAIXA-LOBBY e a B2, que também mexem no
  `caixa-hud-jogadora.test.mjs` e nas listas), por isso **rebaseei** o ramo sobre `0d26f9f` para ele fundir limpo:
  - o commit dos testes aplicou-se sem conflito;
  - nas listas fiquei com as da base e corri o `actualizar-listas` de novo;
  - corri tudo outra vez em cima da base nova, incluindo as mutações; os números de baixo são dessa corrida.

  Os SHA de antes do rebase (`88c20a8`, `e00f708`, `63e5496`) tiveram CI verde, mas já não estão no ramo.
  Clone novo, com `core.autocrlf=false`.
- **Ramo:** `claude1/caixa-testes-correcoes`, **não fundido** (a fusão é do coordenador).
- **Commits:**
  - `9aad79b`: B1, B5, B6, B7 (a prova, o log da prova e os testes);
  - `9877cff`: as listas da retoma (`actualizar-listas.py`: `MANIFESTO-SHA256.txt`, `retoma-i0004/depois.txt`);
  - o deste ESTADO-FINAL, com a B3/B4 no `ESTADO-FINAL-ORDEM-CAIXA-TESTES.md`. Só toca na raiz e não mexe em
    `rascunhos/`, por isso as listas continuam certas.

## Ponto a ponto

### B1: o passo 3 da prova prova o VALOR (`provas/ordem-caixa/ferramentas/prova-servidor.mjs`)
- **Passo 2:** a ordem formada guarda-se em `ordemDoPasso2` e afirma-se `[H, A]`.
- **Passo 3:** para cada membro da Party (heroína, aliada, espectador), o snapshot novo tem de cumprir:
  - `caixa.ligada === true`;
  - `caixa.ordemDinamica.ordem` igual a `ordemDoPasso2`.
- **Log:** a linha do passo 3 passa a dizer `ligada true, ordem Heroína → Aliada`.
- `provas/ordem-caixa/prova-servidor.log` foi refeito e dá **PROVA OK**; só essa linha mudou.
- **Morde:** a M4 (`ligada` trocada só no snapshot do `escolherCaixa`) e a M5 (ordem da Party invertida só nesse
  snapshot) passavam na prova antiga e agora param-na: a M4 na linha 76, a M5 na linha 77. **A M5 não é apanhada por
  nenhum teste da suite (416/416), só pela prova.** Ver o ponto 1 abaixo.

### B3: onde vaza a `caixaMestre`, e a contagem certa (`ESTADO-FINAL-ORDEM-CAIXA-TESTES.md`)
A linha da tabela de mutações partiu-se em duas, e as duas foram repetidas no PC sobre os testes de `6381f50`:
- **No topo do ROOM_SNAPSHOT** (`projecao.js:209`, `base.caixaMestre`): é apanhada pela (b) e por **3** testes antigos,
  não 2:
  - «… por omissão», por desenho;
  - «a escolha do Mestre segue para a Party…», por efeito lateral: o hash da revisão (`snapshotParaRevisao`) tira a
    `caixa` mas não uma chave no topo, por isso a revisão sobe e sai um `ROOM_OPTIONS` a mais;
  - a fixture do ecrã do Mestre.
- **Dentro da `caixa`:** é apanhada pela (b) e por **4** testes antigos:
  - «… por omissão»;
  - «nada do Mestre na caixa da Party (canários)»;
  - «a ordem da Party sobrevive ao journal…»;
  - a fixture do ecrã do Mestre.
- A prova também falha nas duas formas: no topo na linha 65, dentro da `caixa` na linha 69. Ficou numa nota de rodapé
  datada.

### B4: o sítio exacto da mutação de `modo` (mesma tabela)
O sítio exacto: `sala.js:1187`, ramo `else if (tx.snapshotsParty)` da entrega dos snapshots, com
`msg: { ...mensagemSnapshot(m, s, tx.ts), modo: m.caixaMestre.modo }`. Isto põe uma chave `modo` no **topo** do
ROOM_SNAPSHOT, **fora da `caixa`**, e só no snapshot que o `escolherCaixa` manda.

Repetida no PC:
- com o guião novo, só a (b) a apanha (415/416);
- com o guião antigo de `7c97b48`, a suite passa calada (416/416).

A nota diz porque é que o teste dos canários da caixa não a vê: esse teste só varre `x.caixa`.

### B5: o teste (a) compara os pontos do «voltar» e a `ordemDinamicaParty`
- **Antes da tentativa:** a heroína anda primeiro, para que haja pontos do «voltar» e a ordem da Party seja `[H]`. Sem
  isso, «não mudou» compararia listas vazias. O teste afirma as duas pré-condições.
- **Depois de cada tentativa falhada** (jogadora e espectador): `vista().pontos` e `estado().ordemDinamicaParty` são
  `deepEqual` aos de antes.
- **No fim:** a jogadora que volta a entrar vê a ordem `[H]`.
- **Morde:** a M6 (a tentativa proibida limpa a `ordemDinamicaParty`) e a M7 (a tentativa apaga o último ponto do
  «voltar») só são apanhadas pela (a).

### B6: `'vezes'` em `CHAVES_MESTRE` e as chaves exactas da `caixa` (`privacidade.test.mjs`)
- `'vezes'` entrou em `CHAVES_MESTRE`, com uma nota.
- Na sanidade do teste (b), **todos** os snapshots com `caixa` de cada papel da Party têm de ter exactamente as chaves
  `['ligada', 'ordemDinamica', 'ordemPor']`, e a `ordemDinamica` exactamente `['fechada', 'ordem', 'ultimo']`.
- **Morde:** a M8 (`vezes` na `ordemDinamica`, só no snapshot do `escolherCaixa`) é apanhada pela (b), pelo teste dos
  canários da caixa e, na base nova, pelo teste do lobby da CAIXA-LOBBY.

### B7: o teste (c) e o snapshot do «voltar» (`caixa-hud-jogadora.test.mjs`)
- **Depois do ponto e antes do «voltar»,** o Mestre muda a caixa para `ligada`/`iniciativa`, fora da omissão. Sem isso,
  «sobrevive» não se distinguiria de «volta à omissão».
- **No snapshot do «voltar»** de cada membro da Party, o teste afirma:
  - as chaves exactas da `caixa` e da `ordemDinamica`;
  - nenhuma `caixaMestre`;
  - `ligada === true` e `ordemPor === 'iniciativa'`;
  - a ordem do checkpoint (como antes).
- **No estado da sala:** a `caixaMestre` continua `{ ligada: true, modo: 'iniciativa' }`.
- **Varredura com os canários,** em dois níveis:
  - a `caixa` com os canários da caixa: as mesmas listas do teste dos canários da caixa, agora em constantes partilhadas
    `CHAVES_MESTRE_CAIXA`/`NUMEROS_MESTRE_CAIXA`, mais `caixaMestre`;
  - o snapshot inteiro com os canários que são **só do Mestre** (`CHAVES_SO_MESTRE`/`NUMEROS_SO_MESTRE`, um subconjunto
    dos de `privacidade.test.mjs`).

  Os números das jogadoras ficam fora da varredura do snapshot inteiro de propósito: o `propria` leva, por desenho, a
  Vida e o PA da própria jogadora (5150 e 4040 da heroína). A primeira tentativa, com as listas da caixa no snapshot
  inteiro, falhou exactamente por isso.
- **Quem volta a entrar** depois recebe `caixa` igual a
  `{ ligada: true, ordemPor: 'iniciativa', ordemDinamica: <a do checkpoint> }`.
- **Morde:**
  - a M9 (`caixaMestre` nas `CHAVES_MUNDO`: o «voltar» repõe a escolha) é apanhada pela (c), entre os testes **só** por
    esta; a prova também a apanha, na linha 145;
  - a M10 (`modo` no topo, só nos snapshots de todos: «voltar», «Recomeçar», escala) é apanhada pela (c), **só** por
    esta. O guião dos canários não faz «voltar».

**Privacidade:** nenhum teste novo abre caminho de dados do Mestre para a jogadora. As mudanças são só asserções e
varreduras sobre o que a Party já recebia. O único passo novo de guião é a jogadora andar e o Mestre escolher a caixa,
ambos caminhos normais.

## As mutações (temporárias, no código do jogo, todas revertidas)

Corridas com `tmp/mutar.py` (fora do repo, na sede): cada mutação, depois a suite inteira e a prova, e no fim
`git checkout -- rascunhos/servidor/nucleo`. O `git status` do núcleo ficou limpo no fim de cada corrida.

| | Mutação | Suite (testes novos) | Prova |
|---|---|---|---|
| M1 | `caixaMestre` no topo do snapshot da Party | 5 falham: (b), (c), «por omissão», «segue para a Party», fixture | falha (l. 69) |
| M2 | `caixaMestre` dentro da `caixa` | 7 falham: (b), (c), «por omissão», «canários da caixa», «journal», «escolha feita no lobby» (CAIXA-LOBBY), fixture | falha (l. 73) |
| M3 | `modo` no topo, só no snapshot do `escolherCaixa` | 1 falha: (b) | passa |
| M4 | `ligada` trocada, só nesse snapshot | 2 falham: «segue para a Party», «escolha feita no lobby» | **falha (l. 76), B1** |
| M5 | ordem da Party invertida, só nesse snapshot | **0 falham (418/418)** | **falha (l. 77), B1** |
| M6 | a tentativa proibida limpa a `ordemDinamicaParty` | 1 falha: (a) | passa |
| M7 | a tentativa proibida apaga o último ponto do «voltar» | 1 falha: (a) | passa |
| M8 | `vezes` na `ordemDinamica`, só no snapshot do `escolherCaixa` | 3 falham: (b), «canários da caixa», «escolha feita no lobby» | passa |
| M9 | `caixaMestre` nas `CHAVES_MUNDO` (o «voltar» repõe a escolha) | 1 falha: (c) | falha (l. 145) |
| M10 | `modo` no topo, só nos snapshots de todos («voltar»…) | 1 falha: (c) | passa |

As linhas da prova referem-se à versão deste ramo, e a tabela é a da corrida sobre `0d26f9f`. A M8 é também apanhada pela
(b), e não está na secção da B6 com esse número de testes porque o teste do lobby (CAIXA-LOBBY) só veio com a base nova.

## Números das corridas (PC, Node 26.13, Godot 4.7.2, sobre `0d26f9f` + este ramo)

| Corrida | Resultado |
|---|---|
| Servidor, `node --test --test-isolation=none --test-timeout=30000 "testes/*.test.mjs"` | **418/418**: `caixa-hud-jogadora` 9/9 (7 da CAIXA-TESTES e 2 da CAIXA-LOBBY), `privacidade` 8/8 |
| Prova `prova-servidor.mjs` | **PROVA OK** (11 passos); o log refeito é igual byte a byte ao commitado |
| Conferência dos schemas (tráfego dos testes do servidor) | **0 falhas** nas mensagens que saem |
| Cliente `rodar_testes.gd` (headless) | **290/290**, 0 erros de script |
| Cliente `caixa_jogadora.gd` (headless) | **18/18**, 0 erros de script |
| CI em `e00f708` | **verde**: 10/10 jobs, mais a sonda (secção abaixo) |

O número de testes do servidor é o da base (418): esta ordem só aperta testes que já existiam. Antes do rebase, sobre
`6381f50`, os números foram 416/416, 290/290 e 18/18, os schemas deram 0 falhas e o CI 10/10 verde, em `e00f708`.

## CI

| Workflow em `e00f708` | Run | Resultado |
|---|---|---|
| «Testes dos rascunhos» | 44966609627 | **verde, 10/10 jobs**: servidor, protocolo, cliente, godot-cliente, ponta-a-ponta, foto-mestre, provas-mapa, motor-real, validador-glb, **retoma-pc** |
| «Sonda de privacidade» | 44966609612 | **verde** |

O commit deste ESTADO-FINAL só toca na raiz (não em `rascunhos/`), por isso as listas da retoma continuam certas. O CI
corre outra vez com ele.

## Pontos para o coordenador

1. **A M5 só é apanhada pela prova.** A ordem da Party errada (aqui invertida) só no snapshot do `escolherCaixa` passa a
   suite toda (418/418): o teste 2 da caixa só olha para `ligada`/`ordemPor`, e a (b) só para a forma e para os canários.
   Só o passo 3 da prova, com a B1, a apanha. Com a B2 (`0d26f9f`, o passo «Prova da caixa» no job servidor), essa
   cobertura passa a estar no CI. Se se quiser também na suite, bastava uma linha num teste (p. ex. na sanidade da (b): o snapshot em `iniciativa` traz
   `ordemDinamica.ordem` igual à de `estado().ordemDinamicaParty`). Não a pus porque sai da letra da ordem (B6 pede
   chaves, não valores).
2. **O que causa o efeito lateral da M1:** o hash da revisão (`snapshotParaRevisao`, `sala.js:980`) tira a `caixa` mas
   não uma chave nova no topo. Uma fuga no topo do snapshot sobe a revisão da Party e manda um `ROOM_OPTIONS` a mais. É
   por isso que o teste 2 a apanha «sem querer», e a prova pelo «nenhuma revisão mudou».
3. **A tabela da B3/B4 foi corrigida no próprio `ESTADO-FINAL-ORDEM-CAIXA-TESTES.md`,** como a ordem pede: a linha
   partiu-se em duas, com duas notas de rodapé datadas. O resto desse ficheiro não mudou.
4. **O guião dos testes (a) e (c) mudou um pouco.** Na (a), a heroína anda antes da tentativa; na (c), o Mestre escolhe
   `iniciativa` depois do ponto. Os outros testes do ficheiro não dependem disso: cada um monta a sua mesa.
5. **Ambiente do PC:** com `--permission --allow-fs-read` (a linha exacta do job do CI), o Node 26 daqui recusa a rede e
   7 testes de socket falham com `Use --allow-net`. São testes de socket que esta ordem não toca. O CI usa o
   Node 24/22, que não restringe a rede assim. Os números de cima são da corrida sem `--permission`, como na ordem
   anterior.
6. **O ficheiro da ordem na sede** (`ORDEM.md`) ficou como estava e termina com `<b>Estado: NOVA</b>`.
