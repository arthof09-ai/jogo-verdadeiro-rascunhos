# ESTADO-FINAL — ORDEM-D-AUD-01 (o clique de Mover com «Colocar» armado já não duplica a criatura)

**Estado: FEITA.** Reproduzi o defeito na bancada de rede, na ponta, e saiu igual ao da auditoria (evento 10 =
`colocacao` de um orc a mais). Corrigi a causa no cliente do Mestre e corri o mesmo guião, com os mesmos cliques: o
evento 10 passou a ser um `movimento`, ficam 2 orcs e não 3, e o «Colocar» sozinho continua a pôr exactamente 1.
As suites estão verdes. O CI está na nota do fim.

- **Executor:** Claude (opus), PC, conta 2. **Data:** 23/11/2026, das 16:06 às ~16:40 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `8e9bf81` (a nota do CI da AUDITORIA-LINHA), conferida por `git ls-remote` às 16:06:
  `8e9bf81479708b73506fee2aed1ef11949601a2b`. Clonei-a de novo em `ordem-d-aud-01-pc/repo`.
  **A ponta andou durante a obra:** às ~16:24 o `git ls-remote` deu `e08f908dd6506b1184043c584d57191df4263197`
  (ORDEM-ANALISE-PLANO-2). Esse commit só acrescenta 3 ficheiros `.md` na raiz e não toca em código, por isso avancei
  por fast-forward, sem rebase de código, e o commit desta ordem fica por cima de `e08f908`.
- **PC:** livre (inactivo há 7.690 s quando comecei, GPU a 8 %, 25,7 GB livres no C:). A bancada foi parada pelo
  `parar-bancada.cmd` no fim de cada corrida.

## 1. A causa (confirmada, é a da auditoria)

Os dois modos que respondem a um toque no tabuleiro do ecrã do Mestre podiam estar armados ao mesmo tempo, e o
toque tinha um dono fixo:

- `rascunhos/cliente/cenas/mestre/aba_mesa.gd:221-230` na ponta `8e9bf81` (`colocar()`): manda o `MASTER_PLACE` e **não limpa**
  `a_colocar`. O «Colocar» fica armado («Parar de colocar» à vista). Isto é de propósito: o botão «Parar de colocar»
  existe para isso, e o esquema L5 conta com o modo armado.
- `rascunhos/cliente/cenas/mestre/mestre.gd:690-694` na ponta (`casa_tocada()`): pergunta **sempre primeiro** à Mesa. Com
  `a_colocar` preenchido, a Mesa fica com o toque e devolve `true`, e o `_aba_agir.mover()` nunca chega a correr.
- Armar o «Mover» (`aba_agir.gd`, `iniciar_mover()`) não desarmava o «Colocar», e o contrário também não acontecia.

O defeito está na junção das duas coisas, que é o sítio que a auditoria apontou. **Não houve desvio.**

## 2. A correcção

O «Colocar» e o «Mover» passam a excluir-se: **fica armado só o último que o Mestre escolheu**.

| Ficheiro | Mudança |
|---|---|
| `cenas/mestre/mestre.gd` | `armou_colocar()` desarma o Mover do Agir (`parar_mover()`, que também apaga o destaque). `armou_mover()` desarma o Colocar da Mesa (`parar()`; o esquema, se houver, fica na lista). O comentário de `casa_tocada()` explica que a ordem já não escolhe nada |
| `cenas/mestre/aba_mesa.gd` | `escolher_colocar()` chama `mestre.armou_colocar()` |
| `cenas/mestre/aba_agir.gd` | `iniciar_mover()` chama `mestre.armou_mover()` quando o Mover fica de facto armado (há casas do servidor) |
| `testes/pecas_mestre.gd` | 4 verificações novas: «Mover» armado (pré-condição); escolher «Colocar» desarma o Mover e apaga o destaque; armar «Mover» desarma o Colocar; com o Colocar escolhido antes, os toques do Mover mandam **0 `MASTER_PLACE`** |

O que **não** mudou: o servidor; o «Colocar» continua a ficar armado depois de colocar (um clique põe 1, e o seguinte
põe outro, até «Parar de colocar» ou até se armar o Mover); o esquema L5; os textos.

**Relação com o Plano 2 (entrado na linha durante a obra, `e08f908`):** o `PLANO-2-FECHO-DO-JOGO.md` (F1, item 2)
deixa como **[DECISÃO DO MESTRE]** escolher entre «o Colocar desarma depois de cada `MASTER_PLACE`» e «o Mover tem
prioridade». **Esta correcção não escolhe nenhuma das duas.** Não muda o que o Colocar faz sozinho e não dá ao Mover
uma prioridade fixa. Só impede que os dois fiquem armados ao mesmo tempo, que é o que cria a cópia. Se o Mestre
decidir que o Colocar desarma depois de cada `MASTER_PLACE`, isso cabe por cima disto, numa linha em
`aba_mesa.colocar()`. A decisão continua em aberto e é dele.

## 3. As provas (`provas/ordem-d-aud-01/`, mapa no README)

A rota é a da auditoria: a bancada de rede (`bancada-rede/lancar.ps1`), com o servidor de produção e o motor real VLAB
(SHA-256 `a91c021c…3261`), 2 clientes Godot 4.7.2 com janela, input por PostMessage e o journal do servidor.
Correu-se **o mesmo guião duas vezes**: a corrida «antes» em `8e9bf81`, sem a correcção, e a corrida «depois», com a
correcção na árvore de trabalho. Os cliques foram os mesmos, nas mesmas coordenadas: «Colocar orc-teste» → 1 clique
no tabuleiro → a jogadora encerra → vez do orc#1 → Agir → Mover → clique na casa azul (35,12).

| Journal do servidor | antes (`journal-antes.txt`) | depois (`journal-depois.txt`) |
|---|---|---|
| «Colocar» sozinho, 1 clique | evento 8: `colocacao` orc#2 em (24,26), **1** | evento 8: `colocacao` orc#2 em (24,26), **1** |
| clique de Mover em (35,12) | evento 10: **`colocacao` orc#3 em (35,12)** | evento 10: **`movimento` orc#1 (38,11)→(35,12)**, `custoM` 6 |
| orcs no fim | **3** | **2** |
| eventos `movimento` | 0 | 1 |

- **Vídeos:** `antes-mestre.mp4` (1:48) e `depois-mestre.mp4` (1:04), do ecrã do Mestre a 1280×720. Desta vez há vídeo
  do Mestre: a janela foi posta dentro do monitor principal, e assim o `gdigrab` não a recusou como na auditoria.
  Também há `antes-jogadora.mp4` e `depois-jogadora.mp4`. **Limite:** no enquadramento da jogadora não se vê o orc a
  mais, porque fica na água e fora da câmara dela (D-AUD-02/05). Que a cópia chegou à Party prova-o o journal
  (`visivel: de_pe`).
- **Capturas:** `a16-mestre-figuras` (antes: 3 orcs, e o orc#1 não saiu do sítio), `d16-mestre-figuras` (depois: 2 orcs,
  e o orc#1 andou), `d17-mestre-mesa-desarmada` (depois do Mover, a Mesa já não mostra «Parar de colocar»), e as dos
  passos intermédios.
- **Logs dos clientes da corrida «depois»:** 0 `SCRIPT ERROR / Parse Error / Compile Error` (jogadora 6 linhas,
  Mestre 10 linhas).
- **Teste de unidade, antes e depois:** `pecas_mestre` sem a correcção deu **14 FALHA**: as 4 novas e mais 10 em
  cascata, porque o toque do Mover ia para o Colocar (`suites/pecas_mestre-ANTES-da-correccao.log`). Com a correcção
  dá **290 de 290**.

## 4. Suites (com a correcção, neste PC, Godot 4.7.2 `--headless`, Node 26)

Os logs estão em `provas/ordem-d-aud-01/suites/`. Todas deram exit 0 e 0 `SCRIPT ERROR / Parse Error / Compile Error`.

| Suite | Resultado | Na auditoria |
|---|---|---|
| servidor (`testes/*.test.mjs`) | **421/421** pass, 0 fail | 421/421 |
| motor real (`testes-motor-real`) | 2/2 | 2/2 |
| prova da caixa (`prova-servidor.mjs`) | PROVA OK | PROVA OK |
| `abrir_scripts` | 108 scripts, 0 falhas | 108, 0 |
| `rodar_testes` | **321 de 321** | 321 |
| `abrir_mestre` | **67 de 67** | — |
| `pecas_mestre` | **290 de 290** (com as 4 novas de D-AUD-01) | — |
| `medir_mestre` | 220 ok, **0 falhas**, 0 sem medida | 220, 0 |
| `hud_acoes` | **50 de 50** | — |
| `caixa_jogadora` | **70 de 70** | 70 |
| `caixa_janela` | **123 de 123** | 123 |
| canário de privacidade | **10 de 10** | 10 |
| comandos do Mestre contra os schemas v2 (`validar-mensagens.py`) | `pecas_mestre` 26 mensagens, 0 falhas (mínimo 16); `abrir_mestre` 9, 0 falhas (mínimo 5) | — |

As suites correram sobre `8e9bf81` com a correcção. O fast-forward para `e08f908` só trouxe ficheiros `.md` e não
mexeu em nada do que elas correm.

## 5. Perímetro e privacidade

- Escrevi o código da causa (3 ficheiros do ecrã do Mestre), o teste da causa (`pecas_mestre.gd`), as provas e este
  ESTADO-FINAL. O servidor, os workflows, os dados e a `main` ficaram como estavam.
- Ponho o teste no perímetro porque é a prova automática da causa e o CI passa a guardá-la. Se o coordenador o
  quiser fora, sai sozinho, sem tocar na correcção.
- Nomes: só os fictícios das fichas de teste. Tirei dos logs e das ferramentas os caminhos com o utilizador da
  máquina (`<sede>`, `<tmp>`). A Sonda de privacidade corre no CI.
- Ficaram tarefas agendadas do Windows para o agente de input da sessão 1 (`DAud01S1`, `DAud01S1b`), paradas no fim
  com o ficheiro `PARAR` e apagadas.

## Nota do CI

(a preencher depois de o CI correr sobre o commit desta ordem)
