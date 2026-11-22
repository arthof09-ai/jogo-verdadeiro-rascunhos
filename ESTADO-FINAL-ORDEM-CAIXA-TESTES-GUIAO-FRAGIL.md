# ESTADO-FINAL — ORDEM-CAIXA-TESTES-GUIAO-FRAGIL (22/11/2026)

**Ramo:** `claude1/caixa-testes-guiao-fragil`, sobre `fable/integracao-50` @ `5bc5c72` (a ponta à hora do lançamento).
**Não fundido** — a fusão é do coordenador.

> **Corrigido pela Ordem CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES** (sentença da conferência da CAIXA-TESTES-GUIAO-FRAGIL,
> B1 e B3): a errata da secção B1 e do ponto 2 e a frase do ponto 4 levam a marca «[GUIAO-FRAGIL-CORRECOES Bn]».
> Ver `ESTADO-FINAL-ORDEM-CAIXA-TESTES-GUIAO-FRAGIL-CORRECOES.md`.
**Commits:** `0368a78` (B1–B3: teste + provas) e o commit das listas da retoma + este ESTADO-FINAL (o último do ramo).

**Território mexido:** em `rascunhos/` só `rascunhos/servidor/testes/privacidade.test.mjs`. Fora de `rascunhos/`:
`provas/ordem-caixa-testes-guiao-fragil/` (os logs e os guiões das provas), as listas da retoma
(`retoma-i0004/depois.txt`, `MANIFESTO-SHA256.txt`) e este ficheiro. Nada de código do jogo, de HUD nem de cores
(a mutação M3 tocou `nucleo/ordem-dinamica.js` só durante a corrida e foi revertida com `git checkout`).

## B1 — reproduzir primeiro (executada antes e depois da correcção)

> **Errata [GUIAO-FRAGIL-CORRECOES B3].** Pela letra da ordem, «duas voltas» são voltas **inteiras** — e essas
> (variante B) **não** reproduzem a fragilidade. As «duas voltas» desta ordem ficam lidas como as do **caminho da
> M51b** (variante A): é a reprodução válida, o único caminho onde a ordem da Party muda depois das escolhas. A
> variante B é **informativa** e não parte o 1.º teste. O juiz aceitou esta leitura; a sanidade nova é independente
> do caminho (só depende do instante do snapshot).

Guião: `provas/ordem-caixa-testes-guiao-fragil/b1-repro.py` (gera cópias do `privacidade.test.mjs` do repo com o
guião estendido, corre-as com `node --test` e escreve o log). Logs cometidos: `b1-antes.log` (HEAD `5bc5c72`, sem
correcção) e `b1-depois.log` (com a correcção).

**O caminho que parte** (variante A): as duas voltas da M51b depois das escolhas da caixa — uma volta inteira
(o orc leva a aliada 2403 → 1227) e a volta seguinte até o lobo a levar a 51 —, **sem** o «voltar», debaixo do
guião do 1.º teste. Na 2.ª volta o lobo joga antes do orc: a ordem dinâmica da Party (fechada) põe o lobo depois do
orc. Números exactos, antes da correcção (`b1-antes.log`):

- 1.º teste `canários: nada do Mestre chega a nenhum papel da Party` **✖** — `heroina: a ordem no snapshot do
  escolherCaixa`:
  - no snapshot do escolherCaixa: `[f1a88a9eef918a8b4, f0c1870b843e1465f, fb43618ae935f84df, f1c8fc87e558f2d7e]`
  - na ordem da Party do FIM: `[f1a88a9eef918a8b4, f0c1870b843e1465f, f1c8fc87e558f2d7e, fb43618ae935f84df]`
    (os dois últimos — lobo `fb43…` e orc `f1c8…` — trocados).
- Ficheiro: 10 testes, 8 passam, 2 falham (o 1.º e a M51b; a M51b falha na sanidade do próprio caminho,
  `o «voltar» repôs a aliada no 2403` — 51 ≠ 2403 —, porque a variante lhe tira o «voltar»: esperado, não é a
  fragilidade).

**O que não parte** (variante B, informativa): duas voltas **inteiras** no fim do guião de sempre, sem «voltar».
A ordem da Party não troca (o orc e o lobo jogam pela mesma sequência), e o 1.º teste passa — antes e depois. Só a
M51b falha, na sanidade do caminho dela (`M51b: o lobo levou a aliada a 51`: −4653 ≠ 51). Fica registado porque a
fragilidade só aparece quando a ordem muda depois das escolhas — «duas voltas» por si não chegam.

**Depois da correcção** (`b1-depois.log`), variante A: o 1.º teste **✔**; o controlo novo da B3 **✔**; só a M51b
falha, pela mesma sanidade do caminho de cima (11 testes, 10 passam, 1 falha). Variante B: o 1.º teste ✔; a M51b
e o controlo B3 (que segue o caminho da M51b) falham nas sanidades do caminho (`o lobo levou a aliada a 51`),
porque a variante empurra o guião duas voltas antes de esse caminho começar. Nenhuma falha na asserção do
escolherCaixa.

## B2 — a sanidade vale pelo estado registado

`privacidade.test.mjs`:

- **`ordemPartyRegistada(m, ateSeq)`** — a ordem dinâmica da Party que a sala registou no instante `ateSeq` do
  journal. A mesma regra do servidor (`sala.js` `finalizar`): cada evento, projectado como o vê o espectador
  (`projetarEvento`), passa por `registarEvento` (`ordem-dinamica.js`); o «Recomeçar» limpa (`registarEvento`); o
  «voltar» (`revertido`, `soMestre.ateSeq`) repõe a ordem do ponto a que se volta, reconstruindo esse ponto (o journal
  nunca apaga história). Uma batalha nova sem `recomeco` nem `revertido` (rodada de volta para trás) não é modelada:
  **falha alta**, não calada.
- **`journalSeqDoSnapshot(m, s)`** — o instante do snapshot: o último evento com `ts` ≤ o `ts` do snapshot. O
  relógio da mesa anda a cada transacção e o escolherCaixa não emite evento, por isso o snapshot dele é o estado
  nesse ponto (o RESYNC com `lastSeq` reenvia o snapshot gravado, com o mesmo `ts`).
- **A sanidade** «a ordem no snapshot do escolherCaixa» compara agora cada snapshot em `iniciativa` com
  `ordemPartyRegistada(m, journalSeqDoSnapshot(m, s))` (2+ figuras, como antes), e não com
  `estado().ordemDinamicaParty` do fim. Exige também que haja pelo menos um snapshot em `iniciativa` por papel.
- **Guarda da reconstrução:** pelo journal inteiro, `ordemPartyRegistada` tem de dar a `ordemDinamicaParty` da sala
  (`ordem`, `fechada`, `ultimo`, `vezes`). Se a função se desviar da regra do servidor, falha aqui.
- O corpo do 1.º teste passou para `conferirCanariosDoMestre(m)`, sem mudar nenhuma asserção além da sanidade acima.
  O 1.º teste chama-a com `guiao()`. **O guião de sempre não muda.**

O guião ganhou só a opção `voltar` (por omissão `true`) no caminho da M51b, para o controlo da B3. Não esconde nada:
o guião de sempre e a M51b correm exactamente como antes.

### Mutações (executadas; `provas/ordem-caixa-testes-guiao-fragil/mutar.py` → `mutar.log`)

| Mutação | Resultado |
|---|---|
| M0 — o ficheiro corrigido | 11/11 |
| M1 — a sanidade volta à ordem do FIM | o controlo B3 ✖ (`heroina: a ordem no snapshot do escolherCaixa`), o 1.º ✔ — 10/11 |
| M2 — `journalSeqDoSnapshot` devolve o fim do journal | o controlo B3 ✖ (mesma asserção) — 10/11 |
| M3 — o servidor manda a ordem INVERTIDA no snapshot da Party (`caixaParaParty`; revertida) | o 1.º ✖ e o controlo ✖ (mesma asserção) — 9/11 |
| M4 — o 1.º teste sobre o guião da M51b COM «voltar» (exercita o `revertido` da reconstrução) | ✔ |
| M5 — como a M4, mas a reconstrução ignora o `revertido` | ✖ (`a ordem reconstruída do journal = a da sala`) |

A M3 prova que a sanidade continua a morder (uma ordem trocada no snapshot é apanhada); a M1/M2 provam que o controlo
B3 prende a correcção; a M4/M5 provam que o «voltar» está modelado e que a guarda da reconstrução morde.

## B3 — preso na suite

Teste novo `canários: nada do Mestre chega à Party com o guião duas voltas depois das escolhas da caixa, sem «voltar»`:
`guiao({ m51b: true, voltar: false })`, com as sanidades do caminho (nenhum `revertido` no journal; a aliada acaba a
51; a ordem da Party do fim **≠** a do snapshot do escolherCaixa — senão o controlo não tocava a fragilidade) e
depois `conferirCanariosDoMestre(m)` inteiro. Passa. A M51b (com «voltar») continua a passar, sem alterações.

## Corridas

| Corrida | Resultado |
|---|---|
| Suite do servidor na base `5bc5c72` (`npm test` em `rascunhos/servidor`) | 420/420 |
| Suite do servidor no ramo, com o controlo novo | **421/421** (`privacidade` 11/11) |
| B1 antes da correcção (`b1-antes.log`) | variante A: 1.º teste ✖ (8/10); variante B: 1.º ✔ (9/10) |
| B1 depois da correcção (`b1-depois.log`) | variante A: 1.º ✔, controlo ✔ (10/11); variante B: 1.º ✔ (9/11) |
| Mutações (`mutar.log`) | M0–M5 como na tabela acima |
| `python3 retoma-i0004/actualizar-listas.py` (sobre `0368a78`) | antes.txt 37, depois.txt 415, MANIFESTO 459 (0 novos, 0 tirados) |

## Pontos para o coordenador

1. **420 vs 421.** A ordem pede «420/420 com o controlo novo incluído». A base já tem 420; o controlo é um teste
   novo, por isso o ramo dá **421/421**. Pus o controlo num teste à parte (falha com nome próprio) em vez de o meter
   dentro de outro teste só para o total dar 420. Se o coordenador o quiser dentro do 1.º teste, é mudar uma linha.
2. **O caminho exacto da fragilidade.** (Errata [GUIAO-FRAGIL-CORRECOES B3]: as «duas voltas» da ordem são as do
   caminho da M51b — variante A, a reprodução válida; a variante B, voltas inteiras, é informativa e não parte o 1.º
   teste. Ver a errata no topo da secção B1.) A conferência não está neste PC. Fui pela letra da ordem e da nota do
   ESTADO-FINAL-6. Duas voltas **inteiras** sem «voltar» **não** partem o 1.º teste (variante B). O que parte são as
   duas voltas da M51b sem «voltar» (variante A), em que a ordem da Party troca o lobo e o orc. Se o caminho dos
   críticos for outro, vale a pena corrê-lo contra este ramo: a sanidade nova não depende da volta em que o guião
   está, só do instante do snapshot.
3. **A reconstrução repete a regra do servidor** (projecção do espectador + `registarEvento`), importando as funções
   do núcleo. Não é circular para o que a sanidade prende: o valor comparado é o do snapshot que chegou à Party, e a
   guarda «reconstruída = a da sala» falha alto se a regra do servidor mudar sem a função acompanhar. Limite
   declarado: duas batalhas no mesmo journal sem `recomeco` falham alto (não modelado).
4. **O instante pelo `ts`** pressupõe o relógio da mesa a andar a cada transacção (`ajudantes.mjs` `relogio`, passo
   250 ms). ~~Com um relógio parado, o instante sai cedo demais e a sanidade falha alto, não calada.~~
   [GUIAO-FRAGIL-CORRECOES B1] Com um relógio parado, o instante sai **tarde demais**: pela fórmula `e.ts <= s.ts`,
   com os `ts` todos empatados, o instante salta para o **último evento do journal** (o fim), não para um ponto
   anterior. A conclusão prática mantém-se: em geral a sanidade falha alto, não calada.
5. **Margem do canário 51:** não mexi. Com o controlo, o guião vai além do `seq` 38 (o caminho da M51b já ia); os
   contadores `seq` < 100 estão isentos em `procurarCanarios`, e o controlo passa.
6. **O CI** do último commit não fica registado aqui, porque o commit das listas tem de ser o último. O resultado vai
   na resposta da corrida.
7. **O `ORDEM.md` da sede** não foi tocado. Já termina com a linha `- O ficheiro da ordem termina com a linha exacta:
   <b>Estado: NOVA</b>`.
8. O ESTADO-FINAL-4 (l. 42) fica como registo histórico, como decidido.
