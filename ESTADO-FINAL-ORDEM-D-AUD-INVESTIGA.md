# ESTADO-FINAL — ORDEM-D-AUD-INVESTIGA (localizar as causas dos D-AUD-05, 06, 07, 12 e o layout do 14, sem corrigir)

**Estado: FEITA.** Os 5 estão **localizados**, com ficheiro e linha, e foram reproduzidos na bancada de rede a partir da ponta. Há uma ressalva no D-AUD-06: o lado do Mestre (a caixa por cima do realce do Mover) ficou localizado só no código, sem reprodução nesta corrida. **Nenhum código do jogo foi alterado.**

- **Executor:** Claude (opus), PC, conta 2. **Data:** 23/11/2026, 20:34–20:50 (-03). Foi o relançamento fresco depois do fecho da janela das 18:33 (ver `AVISO-JANELA-FECHOU-2026-11-23-1833.md` na sede). Da corrida das 17:21 só aproveitei duas capturas, como contraprova.
- **Linha:** `fable/integracao-50`, trabalho directo; a `main` não foi tocada.
- **Ponta de partida:** `96baf9981ba6f86ff6e413ba8926b1a818427b29` (`96baf99`, nota do CI do D-AUD-01-CORRECCOES). Conferida por `git ls-remote` às 20:34 e outra vez às 20:48: **não andou**.
- **Bancada:** `bancada-rede/lancar.ps1 -SoLobby -Motor real`. Servidor de produção + VLAB real + 2 clientes Godot 4.7.2 verdadeiros (RTX 4060). Jogadora a 1280×720; Mestre a 1600×900. Input por PostMessage. Os 2 clientes acabaram com **0 SCRIPT ERROR / 0 ERROR**. Fechei tudo no fim: `parar-bancada.cmd`, o agente da sessão 1 parado, porta 8790 livre e 0 processos Godot/node/ffmpeg.
- **Provas:** `provas/ordem-d-aud-investiga/RELATORIO-LOCALIZACAO.md` (um capítulo por defeito: reprodução, causa, correcção proposta), mais `capturas/` (24) e `videos/d05-jog-comecar-do-lobby.mp4`.
- **Escrito:** só esse relatório, as provas e este ESTADO-FINAL. Nomes só os fictícios das fichas da bancada.

## Resumo por defeito

| # | Resultado | Causa (onde) | Correcção proposta (onde · risco) |
|---|---|---|---|
| **D-AUD-05** câmara não segue | **localizado** e reproduzido (`l17`, `l20`, vídeo; contraprova `i00` com a bancada preparada → a câmara está na heroína) | `cliente/cenas/arena/arena.gd:730-734`: a câmara foca **só uma vez e só num snapshot**. `_ao_evento` (`:738-741`) não foca. Quando a batalha começa com a jogadora já na arena, a figura chega por **evento** (`colocacao`), e a câmara fica no centro da grelha (`camera_mesa.gd:86-87` via `arena.gd:206`). Não existe «seguir»: o único `camera.focar` do cliente é o de `arena.gd:733` | `arena.gd` (`_ao_snapshot`/`_ao_evento`): focar quando a própria figura aparece, e no `movimento` dela. **Risco baixo.** O Mestre tem de decidir: seguir sempre, ou só quando a figura sai do ecrã |
| **D-AUD-06** caixa tapa; marcadores minúsculos | **localizado**; reproduzido na jogadora (`l17z`, `l18z`, `l32z`); o lado do Mestre só pelo código | A caixa ancora num canto sem saber do 3D: `hud/hud.gd:1016-1036` (`:1031`) e `cenas/mestre/mestre.gd:1415-1424`. O alcance calha debaixo dela **por causa do D-AUD-05**; a figura, no arranque, fica ao lado da caixa, visível (`l17`). Os marcadores são quadrados planos de 0,9 casa no relevo (`arena.gd:538-543`): o tamanho é só o da distância da câmara. Na água ficam no fundo do lago, debaixo da superfície (`sobre_relevo.gdshader:11` `depth_draw_never`, `:14` `puxar = 0.45`) | 1.º o D-AUD-05. Depois, um marcador à altura da figura e visível na água (**o aspecto é do Mestre**, risco baixo). A caixa por cima do conteúdo é decisão de desenho do Mestre (**risco médio**: mexe nas medições da caixa) |
| **D-AUD-07** Registo | **localizado** e reproduzido **exactamente** («Rodada 2 · vez de Heroína Teste · Ação do monstro, vez nova» = o encerrar da IA do 2.º orc na rodada 1; `l30`) | Cada linha é um ponto de «voltar», um por transacção (`servidor/nucleo/sala.js:1142`). A IA faz `ia` + acção + `turno` numa só transacção (`sala.js:2266-2280`). `guardarCheckpoint` (`sala.js:1228-1239`, `:1236-1237`) rotula com a rodada e a vez **depois** da transacção. Atinge todas as linhas que fecham uma vez: o encerrar da heroína aparece como «vez de Orc». O cliente só escreve (`modelo_mestre.gd:276-287`) | Servidor: guardar também a vez/rodada **de antes** (o `antes` já existe em `sala.js:1108`), como campo aditivo em `MASTER_VIEW.pontos`. Cliente: «vez de AUTOR … → vez de SEGUINTE» (o texto é do Mestre). **Risco baixo a médio**; a privacidade não muda (só o Mestre vê) |
| **D-AUD-12** nomes duplicados | **localizado** e reproduzido (`l23`, `l25`/`l26` «Vez de Orc…» duas vezes, `l28` «Orc»/«Orc» na jogadora) | O nome é **da ficha, não da figura**: `sala.js:2630-2640` (`MASTER_PLACE`: `nomePublico: nomePublicoDe(ficha)`), `projecao.js:85-90` e `:149-155`. `novaFigura` (`sala.js:543-554`) não guarda nenhum ordinal. O cliente mostra-o tal e qual (`modelo_mestre.gd:31-38`, `estado.gd:355-359`, `arena.gd:709-710`) | Servidor: um ordinal por ficha ao colocar, com sufixo no `nome`/`nomePublico` projectado (formato do Mestre). **Risco médio** (campo novo no estado; `conferir-estado.js` não precisa de mudar; o canário de privacidade tem de correr) |
| **D-AUD-14** layout | **localizado** e reproduzido: a mesma janela 1600×900 dá **880 / 712 / 865 px** de tabuleiro conforme o histórico de tamanhos (`l08`, `l10`, `l11`, medido em píxeis) | `cenas/mestre/mestre.gd:1311-1365`: a folha alarga até caber a barra das abas (`:1335-1336`), medida **no mesmo quadro em que a letra mudou**. A 800×450 a letra é 32 e a 1600×900 é 22, e a 2.ª passagem diferida (`:1361-1365`) ainda apanha a medida velha. A auditoria abriu a 800×450 e passou a 1600×900, e por isso viu a «metade». Coluna 1: `:1322`, `:1328`, `:1124` (desenho) | Recalcular quando a `TabBar` mudar de mínimo (ou um quadro depois), ou medir as abas na letra nova. **Risco baixo.** Teste novo em `medir_mestre` (800×450 → 1600×900 = igual ao directo). Os 55 % e a coluna 1 são do Mestre. **Perfil gráfico não tocado** |

## Achado lateral (fora da ordem)

O cliente do Mestre abre na **arena da jogadora**. A cena principal é `arena.tscn`, e só o `lobby.gd:287-289` manda o Mestre para o ecrã dele. Para lá chegar, o Mestre tem de ir a ⚙ → «Sair da mesa» → PIN, e isso pausa a sala (`mestre_desconectado`). Provas: `l01-mestre-abre-na-arena-da-jogadora`, `i00-mestre-inicio-bancada-preparada`. Para a conferência numerar.

## Pendente do Mestre (não decidi nada)

- D-AUD-05: a câmara segue sempre, ou só quando a figura sai do ecrã.
- D-AUD-06: o aspecto do marcador de alvo; a caixa da ordem sobre o conteúdo (transparência/recolher, ou a câmara reservar a área).
- D-AUD-07: o texto da linha do Registo com autor e vez seguinte.
- D-AUD-12: o formato do sufixo («Orc 2», «Orc (2)», …).
- D-AUD-14: mais tabuleiro (os 55 %, a coluna 1 recolher sem cartão). O perfil gráfico continua dele.

## Critérios da ordem

- [x] Cada defeito reproduzido na bancada de rede a partir da ponta fresca (`96baf99`, registada acima). O lado do Mestre do D-AUD-06 ficou só com a prova da auditoria (`r-18`) e com o código.
- [x] A causa de cada um com ficheiro e linha (tabela acima; o pormenor está no relatório).
- [x] O âmbito da correcção proposta (o que muda, onde, e o risco) para cada um.
- [x] Nenhum código do jogo alterado; só o relatório, as provas e o ESTADO-FINAL; nenhum nome verdadeiro.

## Nota do CI

Commit do relatório e deste ESTADO-FINAL `b3f3382`: **Testes dos rascunhos 45292070232: success** · **Sonda de privacidade 45292070110: success**.

Sobre a errata E1–E13 + condição de fecho (a) (`2fe0b3f`), os dois workflows deram **success**:
- **Testes dos rascunhos** (run `45304270254`);
- **Sonda de privacidade** (run `45304270210`).
