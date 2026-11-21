# ESTADO FINAL — ORDEM CAIXA-TESTES (Claude conta 1, PC do cunhado) · 21/11/2026

Fecha as correcções **B4** e **B5** da conferência da Ordem CAIXA-HUD-JOGADORA. Só provas e testes: nenhum ficheiro de
código do jogo, de HUD ou de cores mudou (`git diff --stat 7c97b48..HEAD -- rascunhos` só mostra os 2 ficheiros de testes).

- **Base:** `origin/fable/integracao-50` @ `7c97b48` (o passo B2 do CI, do coordenador). Clone novo com `core.autocrlf=false`.
- **Ramo:** `claude1/caixa-testes` — **não fundido** (a fusão é do coordenador).
- **Commits:** `f0d24ac` (B4 + B5) · `7008328` (listas da retoma, `actualizar-listas`) · e o deste ESTADO-FINAL (só a raiz;
  não toca em `rascunhos/`, as listas continuam certas).

## B4 — a prova antiga da CAIXA-PERSISTENTE

**Escolha: actualizar, não aposentar.** Os outros 10 passos da prova continuam verdadeiros e úteis (a escolha sobrevive à
reentrada, ao journal, ao «voltar», ao «Recomeçar», à pausa e ao cartão aberto; mal formada = `formato`; a Party nunca
recebe `caixaMestre`). Aposentar o ficheiro por causa de uma linha deitava fora essa cobertura.

Antes de mexer, confirmei a falha: a prova parava na linha 62 (`actual { heroina: 19, aliada: 16, espectador: 12 }`,
`expected { 18, 15, 11 }`), um snapshot a mais por cada membro da Party, como desenhado.

O que mudou em `provas/ordem-caixa/ferramentas/prova-servidor.mjs`:
- **Passo 3:** a asserção falsa saiu. Agora, para cada membro da Party (heroína, aliada, espectador), as mensagens novas
  depois do op `caixa` são **exactamente `['ROOM_SNAPSHOT']`**. A `caixa` desse snapshot tem só as chaves `ligada`,
  `ordemDinamica` e `ordemPor`, com `ordemPor = 'iniciativa'`, e **não traz `caixaMestre`**. O resto do passo fica igual
  (journalSeq, pontos do «voltar» e revisões inalterados).
- **Linha do log:** passou de «Party: 0 mensagens novas» para «Party: exactamente 1 mensagem nova cada (ROOM_SNAPSHOT,
  caixa.ordemPor iniciativa)».
- **Cabeçalho:** «a Party nunca sabe dela» passou a «a Party nunca recebe a `caixaMestre`», com uma nota datada da B4.
- `provas/ordem-caixa/prova-servidor.log` foi refeito com a prova nova, que dá **PROVA OK**. O log antigo, com a frase
  falsa, fica no histórico do git.

## B5 — os três testes de privacidade

| | Teste (nome na casa) | Onde vive |
|---|---|---|
| (a) | `caixa no HUD da jogadora: a jogadora que envia MASTER_SUPERVISOR op caixa recebe ERRO proibido «Só o Mestre.» e a caixa fica inalterada` | `rascunhos/servidor/testes/caixa-hud-jogadora.test.mjs` |
| (b) | o guião `guiao()` dos canários chama o `escolherCaixa`; as asserções de sanidade estão no teste `canários: nada do Mestre chega a nenhum papel da Party (jogadoras e espectador)` | `rascunhos/servidor/testes/privacidade.test.mjs` |
| (c) | `caixa no HUD da jogadora: o «voltar» repõe a ordemDinamicaParty do checkpoint e o snapshot seguinte leva-a à Party` | `rascunhos/servidor/testes/caixa-hud-jogadora.test.mjs` |

- **(a)** A tentativa é feita pela jogadora e também pelo espectador. Cada um recebe uma só resposta,
  `ERRO` / `proibido` / «Só o Mestre.», e mais nada acontece:
  - `caixaMestre` fica igual no estado da sala e na MASTER_VIEW;
  - o `journalSeq` e as revisões não mudam;
  - nenhum outro lugar recebe mensagem, nem a Party nem o Mestre;
  - a jogadora que volta a entrar continua a ver `ligada`/`dinamico`.
- **(b)** O guião faz 3 escolhas da caixa a meio da batalha, com a ordem dinâmica já formada: `iniciativa`, desligada,
  `dinamico`. Os snapshots que essas escolhas produzem são varridos com todos os canários do Mestre.
  - Juntei `caixaMestre` às `CHAVES_MESTRE`.
  - Sanidade nova: cada papel da Party recebeu um snapshot da caixa em `iniciativa`, um desligado e um com a ordem não
    vazia. Assim o teste prova que varreu esse caminho e não o vazio. O Mestre vê a escolha dele na MASTER_VIEW.
- **(c)** A sequência é esta:
  1. A heroína anda: este é o ponto de volta, com a ordem da Party em `[H]`.
  2. A heroína encerra e a aliada anda: a ordem passa a `[H, A]`.
  3. O Mestre faz «voltar» ao ponto de 1.

  Resultado: `estado.ordemDinamicaParty` fica igual à do checkpoint, e o snapshot seguinte de cada membro da Party traz
  `caixa.ordemDinamica` igual à do checkpoint (a aliada já não está lá). Quem volta a entrar depois recebe a mesma.

### Os testes mordem (mutações temporárias no código do jogo, todas revertidas; `git status` limpo antes do commit)

| Mutação | Apanhada por |
|---|---|
| a projecção da Party leva a `caixaMestre` no snapshot | (b) canários, e 2 testes antigos da caixa |
| `ordemDinamicaParty` tirada das `CHAVES_MUNDO` (o «voltar» deixa de a repor) | (c), **só** este |
| o op `caixa` deixa de exigir o papel Mestre | (a), **só** este |
| fuga (`modo`) **só** no snapshot que o `escolherCaixa` manda | (b) com o guião novo; o guião **antigo passa calado** (8/8). É a lacuna que a B5-b fecha |

## Números das corridas

| Corrida | Onde | Resultado |
|---|---|---|
| Servidor, base `7c97b48` | PC, Node 26.13 | 414/414 |
| Servidor, com os testes novos | PC, Node 26.13 | **416/416** (`caixa-hud-jogadora` 7/7, `privacidade` 8/8) |
| Prova antiga `prova-servidor.mjs`, base | PC | falha na linha 62 (a B4) |
| Prova antiga, corrigida | PC | **PROVA OK** (11 passos) |
| Conferência dos schemas (tráfego dos testes do servidor) | PC, Python | **0 falhas** nas mensagens que saem |
| Cliente `rodar_testes.gd` | PC, Godot 4.7.2 headless | **290/290**, 0 erros de script |
| Cliente `caixa_jogadora.gd` | PC, Godot 4.7.2 headless | **18/18**, 0 erros de script |
| CI «Testes dos rascunhos» em `7008328` | run 44963224984 | **verde, 10/10 jobs** (retoma-pc incluído) |
| CI «Sonda de privacidade» em `7008328` | run 44963224965 | **verde** |

O cliente não tem código mudado nesta ordem. Corri-o para o número e porque o CI o corre.

## Pontos para o coordenador

1. **B4 actualizada, não aposentada** (razão acima). Se preferir a aposentação, basta um cabeçalho, mas perde-se a
   cobertura dos outros 10 passos.
2. O teste (a) vai além da letra da ordem: também testa o **espectador**. O ramo de código é o mesmo
   (`seat.papel !== 'mestre'`), e assim fica provado para os dois papéis da Party.
3. O guião dos canários acaba agora com a caixa em `ligada`/`dinamico`, depois de 3 escolhas. Os outros 4 testes que usam
   o `guiao()` passam sem mudança.
4. `caixaMestre` passou a canário de chave em `privacidade.test.mjs`. Se um dia a Party tiver uma chave com esse nome por
   desenho, o canário tem de ser revisto (hoje é só do Mestre).
5. A prova `prova-servidor.mjs` não está no CI (corre-se à mão). Quebrou sem ninguém notar desde a CAIXA-HUD-JOGADORA.
   Vale pensar num passo de CI para ela, mas mexer no workflow precisa do token `workflow`, por isso não é desta ordem.
6. Corri as suites no PC com o Node 26.13; o CI usa o 24/22. Os resultados batem.
