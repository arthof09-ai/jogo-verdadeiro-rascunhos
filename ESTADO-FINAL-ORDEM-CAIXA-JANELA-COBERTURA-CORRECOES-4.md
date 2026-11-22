# ESTADO FINAL — ORDEM CAIXA-JANELA-COBERTURA-CORRECOES-4 (Claude conta 2, PC · 22/11/2026)

As correcções B1–B4 da sentença da CAIXA-JANELA-COBERTURA-CORRECOES-3.

- **Quem executou:** a **conta 2**. O lançador desta ordem chama `run-claude-conta2.cmd`, e o ramo tem o prefixo
  `claude2/`, que é o da conta que executou (B4).
- **Ramo:** `claude2/caixa-janela-cobertura-correcoes-4`, **não fundido**.
- **Base:** `30a16b5`, a ponta de `fable/integracao-50` à hora do lançamento. Voltei a conferir antes do commit final e
  a base não se mexeu.
- **Commits:**
  - `e323042`: B1, B2 e B3, as corridas, a conferência das fontes, as mutações e o `actualizar-listas`;
  - o commit deste ESTADO-FINAL, que volta a correr o `actualizar-listas` e junta este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/` não existe). Trabalhei pelo texto da ordem, que
  traz os pontos D1–D5 da sentença, e conferi cada afirmação contra as fontes.
- **Território:** só `provas/ordem-caixa-janela/` e este ESTADO-FINAL. `git diff --stat 30a16b5 -- rascunhos/ .github/`
  está vazio (em `cobertura-correcoes-4/actualizar-listas.log`). Não toquei em código do jogo, no HUD nem nas cores.
- **Privacidade:** não há valores novos. Os registos só trazem as linhas de código citadas e os valores-canário de
  bancada que os registos anteriores já traziam. A sonda de privacidade passou em `e323042`.

Abaixo, as pastas são relativas a `provas/ordem-caixa-janela/`.

## 1. Ponto a ponto

### B1: a tabela das 12 chaves da CORRECOES, no cabeçalho de `nomes_relato.gd`

O parágrafo «CAIXA-JANELA-COBERTURA-CORRECOES (B1)» dizia que as 12 chaves são «as que o servidor guarda por figura e só
o Mestre vê». **Isso é falso para 9 delas.** O parágrafo foi reescrito e tem agora a tabela, conferida contra a base
`30a16b5`. O Mestre recebe as 12 todas na vista do Mestre:

| Chave | Onde chega à dona | Quem a recebe |
|---|---|---|
| `vidaActual` | `propria` do evento `estado` (`projecao.js:37`, emitida em `sala.js:1314`); `base.propria` do snapshot (`projecao.js:218`) | o Mestre **e a dona** |
| `paLivre` | idem (`projecao.js:37`, `sala.js:1315`; `projecao.js:220`) | o Mestre **e a dona** |
| `estadoMorte` | idem (`projecao.js:37`, `sala.js:1316`; `projecao.js:222`) | o Mestre **e a dona** |
| `armaCaida` | idem (`projecao.js:37`, `sala.js:1318`; `projecao.js:223`) | o Mestre **e a dona** |
| `armaQuebrada` | idem (`projecao.js:37`, `sala.js:1319`; `projecao.js:224`) | o Mestre **e a dona** |
| `corpoPartido` | idem (`projecao.js:37`, `sala.js:1320`; `projecao.js:225`) | o Mestre **e a dona** |
| `vidaTotal` | só no `base.propria` do snapshot (`projecao.js:219`) | o Mestre **e a dona** |
| `paTotal` | só no `base.propria` do snapshot (`projecao.js:221`) | o Mestre **e a dona** |
| `custoPA` | na própria ficha (`ficha: clonarJson(ficha)`, `projecao.js:226`), como campo de cada técnica (`fichas-bancada.json:27…134`); não vai nas opções (`sala.js:908`/`924` levam só `alvoId` + `arma`/`tecnica`) | o Mestre **e a dona** |
| `paGasto` | não chega: guarda-se por figura (`sala.js:549`) e vai na vista do Mestre (`...clonarJson(fig)`, `projecao.js:152`); à dona vai só `paLivre = paTotal − paGasto` (`projecao.js:220`) | **só o Mestre** |
| `alma` | não chega: não há campo de alma em `projecao.js`, nas fichas de bancada, nem como chave em `sala.js` | **ninguém** (a chave fica de guarda) |
| `dano` | não chega como chave: o evento `dano` leva `valor`/`tipos` (`projecao.js:32`), e a ficha só tem `expressaoDano` | **só o Mestre**: o `dano:` só existe no `soMestre` (`sala.js:1353/1359/1367`; o 3.º argumento de `tx.emitir`, `sala.js:1122`) |

São **9 das 12 a chegar à dona**: as 6 do `estado`, mais `vidaTotal`, `paTotal` e `custoPA`. Somadas às 3 da
CORRECOES-3 (`custoM`, `reservaM`, `perdeQuarto`), são **12 das 17**. Só `paGasto`, `alma`, `dano`, `reacaoDisponivel`
e `defendendo` não chegam a ela.

**O filtro não muda.** O relato é cometido e lido por quem não é a dona, por isso exclui as 17 na mesma. Este erro não
tinha impacto vivo: era a razão escrita que estava errada, não a lista.

**A prova:** `cobertura-correcoes-4/conferencia-fontes.log` mostra cada linha citada, tirada da base com `git show
30a16b5:<ficheiro>`, junto do comando que a deu. A secção (d) extrai as **chaves** (o lado esquerdo) do
`base.propria` e a lista `propria` do `estado`. Saem as 8 da tabela, mais `figuraId` e `ficha`, e as 6 do `estado`.
`paGasto`, `alma` e `dano` não estão em nenhuma. Os greps de `alma` dão saída vazia, e a contagem de `"dano"` e de
`paGasto` nas fichas dá 0.

### B2: o rótulo passa a «nenhuma chave privada no relato»

- **Prova viva** (`ferramentas/prova_caixa_janela.gd`): o rótulo das passagens dizia «nenhuma chave privada do Mestre no
  relato» e passa a «**nenhuma chave privada no relato** (… 17 chaves proibidas; …)». O do fim dizia «… nenhuma das 17
  chaves privadas do Mestre» e passa a «… **nenhuma das 17 chaves privadas** (…)». Os comentários explicam porquê: a
  dona recebe 12 das 17, e o relato é lido por quem não é a dona.
- **Prosa do §5** (`ferramentas/teste_nomes_relato.gd`): entram os dois rótulos novos, iguais aos da prova viva. Os
  rótulos antigos («do Mestre», com 17, 12 e 5 chaves) ficam, porque estão nos registos cometidos e não podem tropeçar.
  O cabeçalho do §5 e a 1.ª verificação dizem «17 chaves privadas» e já não dizem «do Mestre».
- **Registos:** o relato desta ordem (`cobertura-correcoes-4/cliente/relato.txt`) tem os rótulos novos nas linhas 48,
  77 e 79. Os registos anteriores são registo histórico e não os emendo.

### B3: o total de 25 verificações, afirmado no código

- No teste há `const VERIFICACOES := 25`, com um comentário que explica a conta: 22 `_ok` locais, mais 1 num ciclo de 3
  (os custos do §5).
- O `_fim()` guarda `_total` antes de contar a própria verificação e faz `_ok(corridas == VERIFICACOES, "fim: correram
  as %d verificações do teste (esperadas %d)")`.
- **Consequência:** a verificação do total é ela própria um `_ok`, por isso a linha final diz **26 de 26** (as 25 e a do
  total). Também falha no caminho curto, quando as fichas não abrem.
- **Mutações** (`cobertura-correcoes-4/mutacoes.log`), feitas em cópias do teste que apaguei a seguir:

| Mutação | Resultado |
|---|---|
| MT0, sem mutação | 26 de 26, rc=0 |
| MT9, uma verificação apagada (§2, «figura que não está na vista») | FALHA «correram as 24 … (esperadas 25)», **24 de 25, rc=1** |
| MT10, o ciclo dos custos com 2 voltas em vez de 3 | **24 de 25, rc=1** |
| MT11, uma verificação a mais | FALHA «correram as 26 …», **26 de 27, rc=1** |

Antes desta ordem, a MT9 e a MT10 passavam caladas.

### B4: o registo

- **Este ESTADO-FINAL** diz quem executou (a conta 2, no cabeçalho e no topo) e afirma o CI **da ponta** (§3), além do
  do commit de trabalho.
- **O ESTADO-FINAL da CORRECOES-3 diz «conta 1» quando correu na conta 2.** O lançador dessa ordem
  (`ordem-caixa-janela-cobertura-correcoes-3/lanca.cmd`, no PC) chama `run-claude-conta2.cmd`. É registo histórico e
  não o emendo; fica registado aqui. O ramo `claude1/` dessa ordem fica como está, como a ordem decidiu.

## 2. Corridas

Ambiente: PC, Godot 4.7.2 Windows `_console.exe`, Node, motor VLAB real sha256 `a91c021c…3261`, semente 7. Antes de
tudo, corri `godot --headless --path rascunhos/cliente --import` no clone novo (rc=0, 0 SCRIPT ERROR).

| Corrida | Resultado | Registo |
|---|---|---|
| Teste dos nomes do relato | **26/26** (as 25 de antes e a do total), rc=0, 0 SCRIPT ERROR; «69 linhas (esperadas 69 = 17×4+1), 69 achado(s)»; os limites dão «15 formas escapam por desenho» | `cobertura-correcoes-4/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **41/41**, rc=0, 0 SCRIPT ERROR. No relato, 0 nomes verdadeiros (2 canários) e 0 achados das 17 chaves na passagem 1 (47 linhas), na 2 (76) e no fim (78) | `cobertura-correcoes-4/cliente/relato.txt` |
| Mutações da B3 | MT9 a MT11 todas com rc=1; MT0 com rc=0 | `cobertura-correcoes-4/mutacoes.log` |
| Conferência das fontes (B1) | as 9 que chegam à dona e as 3 que não chegam, cada uma com a linha da base | `cobertura-correcoes-4/conferencia-fontes.log` |
| `actualizar-listas` | 0 novos, 0 tirados, as 3 listas iguais antes e depois | `cobertura-correcoes-4/actualizar-listas.log` |

- **Capturas da prova viva** (sha256, 16 primeiros): `3236673a0ce143d5`, `00896476369c1b8c` e `561363927bab83f2`. Vi a
  de 780×360: a fila parte em 9 + 1 e a faixa lê-se.
- **SHA-256 das listas** (iguais antes e depois): `antes.txt` `cf3b16fa…`, `depois.txt` `cc53679e…`,
  `MANIFESTO-SHA256.txt` `c30cc19f…`. O script dá «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos,
  0 tirados nesta passagem)». O ramo não toca em `rascunhos/`, por isso não havia nada a sincronizar. Corri o script
  antes do commit do trabalho e outra vez antes do commit final.
- Não corri as suites largas, porque esta ordem só muda comentários, rótulos e o fim do teste. O CI corre-as todas (§3).

## 3. CI

| Workflow | Commit | Corrida | Resultado |
|---|---|---|---|
| «Testes dos rascunhos» | `e323042` (trabalho) | 45015355693 | **verde, 10/10 jobs**: cliente, godot-cliente, servidor, protocolo, motor-real, ponta-a-ponta, foto-mestre, provas-mapa, validador-glb, **retoma-pc** |
| «Sonda de privacidade» | `e323042` | 45015355703 | **verde** |
| ambos | **a ponta** (o commit deste ESTADO-FINAL) | ver abaixo | ver abaixo |

No job `cliente`, o passo «Nomes do relato da caixa-janela» dá **26 de 26**, com «ok fim: correram as 25 verificações do
teste (esperadas 25)».

**O CI da ponta:** este ficheiro não pode trazer o resultado do commit que o junta. Por isso, depois de publicar a
ponta, esperei pelo CI dela e só dei a ordem por acabada com ele verde. Os números (o commit, as corridas, os 10/10 jobs)
estão no relatório final ao coordenador. A ponta só difere de `e323042` neste ficheiro e no
`cobertura-correcoes-4/actualizar-listas.log` corrido de novo, ambos fora de `rascunhos/`.

## 4. Pontos para o coordenador

1. **O teste dos nomes diz agora 26/26 e não 25/25.** As 25 verificações de conteúdo são as mesmas; a 26.ª é a do
   total (B3). Se preferires que a linha final continue a dizer 25, a verificação do total tem de sair do `_ok` (e então
   uma falha dela diria «24 de 24» com rc=1, o que confunde mais). Fiz como a ordem sugeria.
2. **B1:** 9 das 12 chegam à dona, e o filtro não muda. Com a CORRECOES-3, ficam 12 das 17 a chegar à dona e só 5 que
   nunca lhe chegam (`paGasto`, `alma`, `dano`, `reacaoDisponivel`, `defendendo`).
3. **B4:** o ESTADO-FINAL da CORRECOES-3 diz «conta 1», mas a ordem correu na conta 2. Fica registado aqui e o ficheiro
   não foi emendado. Esta ordem corre na conta 2, com o ramo `claude2/`.
4. **O README de `provas/ordem-caixa-janela/`** não tem secção da CORRECOES-3 (essa ordem não a escreveu). Acrescentei
   só a desta ordem.
5. **«Estado: NOVA».** Li-a como uma regra para o próprio ficheiro da ordem, como nas ordens anteriores, por isso este
   ESTADO-FINAL não a leva. Atenção: o `ORDEM.md` que recebi (na sede, fora do repo) não termina com essa linha sozinha.
   Termina com o ponto da lista que a cita («- O ficheiro da ordem termina com a linha exacta: <b>Estado: NOVA</b>»).
   Não lhe toquei, porque o ficheiro é teu.
