# ESTADO FINAL — ORDEM CAIXA-JANELA-COBERTURA-CORRECOES-3 (Claude conta 1, PC · 22/11/2026)

As correcções B1–B3 da sentença da CAIXA-JANELA-COBERTURA-CORRECOES-2.

- **Ramo:** `claude1/caixa-janela-cobertura-correcoes-3`, **não fundido**.
- **Base:** `ba56b7e`, a ponta de `fable/integracao-50` à hora do lançamento.
- **Commits:**
  - `79d2eb9`: B1, B2 e B3, as corridas, a conferência das fontes e o `actualizar-listas`;
  - o commit deste ESTADO-FINAL, que volta a correr o `actualizar-listas` (agora sobre `79d2eb9`; deu outra vez nada a
    mudar) e junta este ficheiro.
- **A conferência:** não está neste PC (`~/workspace/conferencias/caixa-janela-cobertura-correcoes-2/` não existe e não
  está no repositório). Trabalhei pelo texto da ordem, que traz os pontos D1–D3 da sentença, e conferi cada afirmação
  contra as fontes do servidor e do cliente.
- **Território:** só `provas/ordem-caixa-janela/` e este ESTADO-FINAL. `git diff --stat ba56b7e -- rascunhos/ .github/`
  está vazio, com a saída capturada em `cobertura-correcoes-3/actualizar-listas.log`. Nada de código do jogo, de HUD
  nem de cores.
- **Privacidade:** não há valores novos. Os registos só trazem as linhas de código citadas, os nomes públicos e de
  bancada que os relatos já traziam, e os valores-canário de bancada. A sonda de privacidade do CI passou em `79d2eb9`.

Abaixo, as pastas são relativas a `provas/ordem-caixa-janela/`.

## 1. Ponto a ponto

### B1 — a tabela das 5 chaves novas, reescrita

A tabela da B1 no ESTADO-FINAL da CORRECOES-2 dizia «Só o Mestre vê: sim» para as 5 chaves. **Isso é falso para 3
delas.** A tabela certa:

| Chave | Onde o servidor a guarda | Quem a recebe |
|---|---|---|
| `custoM` | `propria` do evento `movimento` (`projecao.js:25`); cada casa de `opcoes.mover` (`sala.js:889`) | o Mestre **e a própria jogadora**: no evento do movimento dela, e nas opções da vez dela (`sala.js:965`) |
| `reservaM` | `propria` do evento `movimento` (`projecao.js:25`); nas opções como `orcamentoM` (`sala.js:947`) | o Mestre **e a própria jogadora**: com o nome `reservaM` no evento e como `orcamentoM` nas opções |
| `perdeQuarto` | `propria` da `desgraca` (`projecao.js:38`) | o Mestre **e a própria jogadora** (a da desgraça aplicada) |
| `reacaoDisponivel` | por figura (`sala.js:551`); ausente de `projecao.js` e de `ordem-dinamica.js` | **só o Mestre** |
| `defendendo` | por figura (`sala.js:551`); ausente de `projecao.js` e de `ordem-dinamica.js` | **só o Mestre** |

**O filtro não muda.** As 17 chaves continuam na lista e o relato continua a excluí-las. Uma chave `propria` vai só à
dona; o relato é cometido e lido por quem não é a dona, e por isso não a pode trazer. Não era um buraco no filtro: era
uma frase que a sentença pediu para confirmar e que não se confirmou para 3 das 5.

**Onde ficou escrito:** no cabeçalho de `CHAVES_PROIBIDAS` (`ferramentas/nomes_relato.gd`) há agora um parágrafo
«CAIXA-JANELA-COBERTURA-CORRECOES-3 (B1)», com quem recebe cada uma. O ESTADO-FINAL da CORRECOES-2 é registo histórico
e não o emendo; a tabela certa fica aqui.

**A prova:** `cobertura-correcoes-3/conferencia-fontes.log` mostra cada linha citada, tirada da base `ba56b7e` com o
comando que a deu:
- `projecao.js:25` (`propria: ['custoM', 'reservaM']`) e `projecao.js:38` (`propria: ['perdeQuarto']`);
- `sala.js:889` (`custoM` em `mover`), `sala.js:947` (`orcamentoM: arred(v.reservaM)`) e `sala.js:965` (a jogadora
  recebe as opções quando é a vez dela);
- `sala.js:551` (`reacaoDisponivel`/`defendendo` por figura);
- `grep` destas duas em `projecao.js` e `ordem-dinamica.js`: **saída vazia**. Nunca se projectam.

### B2 — a razão de não listar `modo`, reescrita

**A decisão continua:** `modo` não entra na lista. A razão escrita estava errada.

- **Antes** (cabeçalho de `nomes_relato.gd` e comentário do §5): «`modo` (H10: o modo da ordem, que só o Mestre vê)».
- **Agora:** o `modo=` da linha «caixa da jogadora ao abrir: visível=true modo=dinamico …» **não é o H10**. É o rótulo
  do cliente (`ordem_turnos.modo`, `hud.gd:1049`). O cliente carrega-o do `ordemPor` da caixa (`hud.gd:955`), e o
  servidor manda esse `ordemPor` à Party por desenho (`ordem-dinamica.js:166`). O H10 é o `modo` de cada figura
  (`manual`/`semi`/`auto`, `sala.js:62`), que nunca se projecta (`sala.js:552`).
- **O latente, registado:** uma futura linha do relato com o `modo` H10 de uma figura escaparia à varredura. Fica escrito
  no cabeçalho e **fixado no §5**: os limites passam de 13 para **15 formas que escapam por desenho**, com
  `  x modo=auto` e `  x {"modo":"manual"}`. Se um dia se listar o H10 (com outra regra que não apanhe o rótulo), esta
  verificação cai, e cai de propósito.

A prova das fontes está em `cobertura-correcoes-3/conferencia-fontes.log`, secção B2. A última linha dela é a linha 38
do relato vivo desta ordem, com o `modo=dinamico`.

### B3 — «duas linhas» → três

A frase do ESTADO-FINAL da CORRECOES-2, «a prosa ganhou duas linhas», está errada. **A prosa do §5 ganhou três linhas**:
1. o rótulo das 17 chaves («… 17 chaves proibidas; 0 achado(s), linhas []»);
2. «as figuras reservam 3 m; custom; o custo em m; …»;
3. «a Arqueira está defendendo; …; incustoM; areservaM».

A prova está no fim de `cobertura-correcoes-3/conferencia-fontes.log`: as linhas com `+` no bloco da prosa do diff de
`6652f02`, onde entrou o §5 da CORRECOES-2 na linha de integração. Há 4 linhas com `+`; a de «recustoPA» já existia, e
só ganhou a vírgula do fim. Esse ESTADO-FINAL é registo histórico e não o emendo.

## 2. Corridas

Ambiente: PC, Godot 4.7.2 Windows `_console.exe`, Node, motor VLAB real sha256 `a91c021c…3261`, semente 7. Antes de
tudo, `godot --headless --path rascunhos/cliente --import` no clone novo (rc=0, 0 SCRIPT ERROR).

| Corrida | Resultado | Registo |
|---|---|---|
| Teste dos nomes do relato | **25/25**, rc=0, 0 SCRIPT ERROR. As mesmas 25 verificações; a dos limites varre agora **15** formas (eram 13) | `cobertura-correcoes-3/teste-nomes-relato.log` |
| Prova viva da caixa-janela | **41/41**, rc=0, 0 SCRIPT ERROR. No relato: 0 achados das 17 chaves na passagem 1 (47 linhas), na 2 (76) e no fim (78) | `cobertura-correcoes-3/cliente/relato.txt` |
| Conferência das fontes (B1, B2, B3) | todas as linhas citadas existem na base e dizem o que a tabela diz; `reacaoDisponivel`/`defendendo` ausentes da projecção | `cobertura-correcoes-3/conferencia-fontes.log` |
| `actualizar-listas` | 0 novos, 0 tirados, as 3 listas iguais antes e depois, saídas capturadas | `cobertura-correcoes-3/actualizar-listas.log` |

- **Capturas da prova viva** (sha256, 16 primeiros): `6599f088d8e89519`, `0d79c56b84bf6f7c` e `283606fe52605c00`.
- **SHA-256 das listas** (iguais antes e depois): `antes.txt` `cf3b16fa…`, `depois.txt` `e387a468…`,
  `MANIFESTO-SHA256.txt` `a3bfde23…`. O script dá «antes.txt: 37 · depois.txt: 415 · MANIFESTO: 459 ficheiros (0 novos,
  0 tirados nesta passagem)».
- **Não havia listas a sincronizar:** o script só olha para `rascunhos/`, e o ramo não lhe toca. Corri-o antes do
  commit do trabalho e outra vez antes do commit final; deu nada a mudar das duas vezes.
- Não corri as suites largas: esta ordem só muda comentários e uma lista de formas do teste. O CI corre-as todas (§3).

## 3. CI

| Workflow | Commit | Corrida | Resultado |
|---|---|---|---|
| «Testes dos rascunhos» | `79d2eb9` | 45008792750 | **verde, 10/10 jobs**: cliente, godot-cliente, servidor, protocolo, motor-real, ponta-a-ponta, foto-mestre, provas-mapa, validador-glb, **retoma-pc** |
| «Sonda de privacidade» | `79d2eb9` | 45008792748 | **verde** |

No job `cliente`, o passo «Nomes do relato da caixa-janela» dá **25 de 25** no registo do CI, com «limites registados —
15 formas escapam por desenho» e «69 linhas (esperadas 69 = 17×4+1), 69 achado(s)», todas a «ok».

O commit final (este ESTADO-FINAL e o `actualizar-listas.log` corrido de novo) só junta texto fora de `rascunhos/`; o seu
CI fica para o coordenador conferir na página do ramo.

## 4. Pontos para o coordenador

1. **O teste dos nomes continua com 25/25.** Não há verificações novas. A dos limites passa de 13 para 15 formas, com o
   latente do `modo` H10 (B2).
2. **A mesma imprecisão, mais antiga, no cabeçalho de `nomes_relato.gd`.** O parágrafo da CAIXA-JANELA-COBERTURA-CORRECOES
   (B1) diz que as 12 chaves de então são «as que o servidor guarda por figura e só o Mestre vê». Também não é exacto:
   `vidaActual`, `paLivre`, `estadoMorte`, `armaCaida`, `armaQuebrada` e `corpoPartido` são `propria` do evento
   `estado` (`projecao.js:37`), e chegam à dona. Não lhe toquei, porque está fora das B1–B3. É a mesma correcção da B1
   desta ordem: a lista certa, a razão errada. Se quiseres, entra numa ordem seguinte.
3. **O rótulo da prova viva** diz «nenhuma chave privada do Mestre no relato» (`prova_caixa_janela.gd`). Com a tabela
   da B1, «privada» está certo (nenhuma chega à Party inteira), mas «do Mestre» deixa de fora a dona. Não lhe toquei:
   o texto é fixado pela prosa do §5 e pelos registos das corridas, e mudá-lo é uma decisão de forma.
4. **O total de verificações** continua sem ser afirmado em lado nenhum do código, como a sentença registou. Aqui só
   está nos registos das corridas.
5. **A base avançou** durante a ordem: à hora do commit final, `origin/fable/integracao-50` está em `c847966` (+2
   commits: `86853ca` e `c847966`, a CAIXA-RELATO-CORRECOES-5). Não fiz rebase. `git diff --name-only ba56b7e c847966`
   dá 13 ficheiros, e nenhum toca em `provas/ordem-caixa-janela/`, nas listas da retoma (`retoma-i0004/`,
   `MANIFESTO-SHA256.txt`) ou nas fontes citadas (`sala.js`, `projecao.js`, `ordem-dinamica.js`, `hud.gd`). A fusão
   não deve ter conflitos.
6. As decisões já registadas na ordem (o `M` final só maiúsculo, `defendendo` na família de palavra, a B3 anterior sem
   emendas) ficaram como estavam.
