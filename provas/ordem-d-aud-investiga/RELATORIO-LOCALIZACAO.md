# RELATÓRIO DE LOCALIZAÇÃO — ORDEM-D-AUD-INVESTIGA (23/11/2026)

**Ponta de partida:** `96baf99` (`fable/integracao-50`, depois de `git fetch` às 20:34 -03; antes estava em `cdc08be`, andou 4 commits do D-AUD-01-CORRECCOES).
**Bancada:** `bancada-rede/lancar.ps1 -SoLobby -Motor real` — servidor de produção (`servidor-ws.js` + VLAB real) e 2 clientes Godot 4.7.2 verdadeiros no RTX 4060. Jogadora a 1280×720 (2.º monitor), Mestre a 1600×900 (monitor principal). Input só por PostMessage às janelas (agente da sessão 1). Corrida das 20:37 às 20:45 (-03).
**Nada do jogo foi alterado.** Escrevi apenas este relatório, as capturas e o vídeo desta pasta, e o ESTADO-FINAL.
Nomes que aparecem: só os fictícios das fichas da bancada («Heroína Teste», «Orc Verdadeiro Teste»).

## O caminho da reprodução (o mesmo da auditoria)

1. Bancada **sem a batalha preparada** (`-SoLobby`): a jogadora abre na arena com «Esperando o Mestre começar…»; o cliente do Mestre também abre na arena da jogadora (ver «Achado lateral» no fim).
2. Mestre: ⚙ → «Sair da mesa» → lobby → «Sou o Mestre» → PIN → ecrã do Mestre (`l07`). Sala → «Continuar» (a saída pôs a sala em pausa).
3. Mesa → procurar «orc» → marcar → «Guardar a mesa» → «Começar a batalha» × 2. **O vídeo da jogadora começou antes do «Começar»** (`videos/d05-jog-comecar-do-lobby.mp4`).
4. Jogadora: Mover → um clique numa casa azul → andou para o lago.
5. Mestre: «Colocar Orc…» → duas casas → dois orcs da mesma ficha.
6. Heroína encerra; Mestre põe cada orc em «Automático» (a IA joga); heroína encerra mais duas vezes; Ataque.
7. Os 2 clientes acabaram com **0 SCRIPT ERROR e 0 ERROR** nos `godot.log`. Bancada fechada com `parar-bancada.cmd`; agente parado; porta 8790 livre e 0 processos Godot.

---

## D-AUD-05 — a câmara não segue a figura · **LOCALIZADO**

### Reprodução
- `l15-jog-antes-de-comecar` → `l17-jog-comecou` (e o vídeo `d05`): ao «Começar», a heroína nasce no canto superior direito, pequena e meio por baixo da caixa da ordem (`l17z`, recorte 3×). A câmara fica onde estava no lobby: **no centro da grelha**.
- `l19-jog-cursor` → `l20-jog-andou`: a heroína anda (um clique) e **o enquadramento não muda nem um píxel**.
- **Contraprova (A/B):** `i00-jog-inicio-bancada-preparada` é desta mesma sede, às 17:21, com a bancada **preparada pelo porteiro** (a batalha começa antes de o cliente abrir). Aí a câmara **está** na heroína. O código da câmara e da arena não mudou entre essa ponta (`cdc08be`) e `96baf99` (`git log e91fb95..96baf99` não toca em `arena.gd` nem em `camera/`).

### Causa (ficheiro/linha)
1. **A câmara só foca uma vez, e só num snapshot.** `rascunhos/cliente/cenas/arena/arena.gd:730-734`: dentro de `_ao_snapshot()`, `if not _focou and Estado.minha_figura_id != ""` → `camera.focar(centro_casa(minha))` → `_focou = true`. O handler dos eventos, `arena.gd:738-741` (`_ao_evento`), **não tenta focar**.
   - Quando a batalha começa com a jogadora já na arena (o caso normal: ela espera no lobby da arena), o único snapshot chega na fase `lobby`, com a heroína por colocar (`casa_de` dá `(-1,-1)`, `dentro()` falso). A colocação (`colocacao` no MASTER_START) chega depois como **evento**, e esse caminho não foca. `_focou` fica `false` para sempre. A câmara fica no foco que `configurar_arena` lhe deu: `rascunhos/cliente/camera/camera_mesa.gd:86-87` (`if foco == Vector3.ZERO: foco = centro`), chamado em `arena.gd:206` com o centro da grelha.
   - No caso A/B (porteiro), o snapshot do JOIN já traz a heroína colocada, por isso foca. É por isso que as bancadas preparadas não mostravam o defeito.
2. **Não existe «seguir».** Não há nenhum outro chamador de `camera.focar` no cliente (`grep`: só `arena.gd:733`). `camera_mesa.gd:93-95` (`focar`) só é chamado essa vez; o movimento da própria figura (`_atualizar_figura`, tween da posição) não mexe na câmara.

### Correcção proposta (âmbito)
- **Onde:** só `rascunhos/cliente/cenas/arena/arena.gd` (`_ao_snapshot` e `_ao_evento`, ~10–20 linhas). `camera_mesa.gd` não precisa de mudar (`focar` já suaviza com `suavidade`).
- **O quê:** (a) passar o «focar a primeira vez que a minha figura existe dentro da grelha» para um sítio comum chamado por **snapshot e evento**; (b) no evento `movimento` (e `colocacao`) da **própria** figura, `camera.focar(centro_casa(destino))`.
- **Decisão do Mestre (antes de construir):** seguir **sempre**, ou só quando a figura sai de uma margem do ecrã? Seguir sempre apaga o arrasto que a jogadora fez à mão; a alternativa conserva o arrasto e só recentra quando a figura deixa de se ver.
- **Risco:** baixo. A câmara é só apresentação; não toca em regra nem rede. Atenção ao «Panorama» (`_foco_alvo` ignora `foco` em PANORAMA: `camera_mesa.gd:129-130`, fica como está) e aos testes do cliente que carregam a arena (`rodar_testes`, `caixa_jogadora`, `caixa_janela`). Precisa de um teste novo: snapshot de lobby + evento `colocacao` da própria → foco na casa dela; `movimento` → foco no destino.
- **Efeito no D-AUD-06:** com a figura no centro, a caixa da ordem deixa de a tapar no arranque e os marcadores de alvo ficam maiores (ver abaixo).

---

## D-AUD-06 — a caixa da ordem tapa a figura e o alcance; marcadores minúsculos · **LOCALIZADO** (lado da jogadora reproduzido; lado do Mestre só pelo código)

### Reprodução
- `l17` / `l17z`: no arranque, a heroína está debaixo da caixa «Ordem de turnos».
- `l18-jog-mover` / `l18z` (recorte 3×): com «Mover», as casas azuis ao alcance ficam metade **por baixo da caixa**.
- `l32-jog-ataque-alvos` / `l32z` (recorte 4×): com «Ataque», o marcador de um orc é um fragmento vermelho de **~20×12 px**, e o do orc que está dentro de água **não se vê** (só a cabeça do orc). Distância: a câmara está no centro da arena, e os alvos estão a ~30 m do foco.
- Lado do Mestre (a caixa tapa o realce do Mover): **não reproduzido nesta corrida** (os orcs estavam em «Automático»). Fica a prova `r-18` da auditoria e a localização no código, abaixo.

### Causa (ficheiro/linha)
1. **A caixa não sabe do mundo 3D.** Jogadora: `rascunhos/cliente/hud/hud.gd:1016-1036` (`_posicionar_caixa`). A caixa encosta ao canto superior direito (`:1031`, `_caixa.position = Vector2(area.x - _caixa.size.x, 0)`) e só se desvia da ⚙ e da faixa de texto (`:1019-1025`). Não conhece a posição da figura nem a das casas destacadas. Mestre: `rascunhos/cliente/cenas/mestre/mestre.gd:1415-1424` (canto superior esquerdo do tabuleiro, só se desvia dos controlos da câmara livre).
2. **Por que a figura e o alcance calham debaixo dela:** é o D-AUD-05. Com a câmara no centro da grelha, a heroína (casa ~38,4 numa 50×50) projecta-se no canto superior direito, exactamente onde a caixa está. Com a câmara na figura, a figura fica no centro do ecrã e a caixa deixa de a tapar no arranque.
3. **Os marcadores de alvo** são a mesma malha dos destaques do Mover: um quadrado plano de 0,9 casa colado ao relevo (`rascunhos/cliente/cenas/arena/arena.gd:538-543`, `_malha_casas(lista, 0.9, LEVANTA_M + 0.01)`, com `campo_da_mesa.gd:325-354`). Não há anel à volta da figura, nem um tamanho mínimo no ecrã. Por isso o tamanho deles depende só da distância da câmara: a ~30 m do foco (D-AUD-05) ficam com ~10–20 px.
4. **Dentro de água desaparecem:** o shader dos destaques é `sobre_relevo.gdshader:11` (`depth_draw_never`) e o quadrado fica no **fundo** do lago (relevo + 0,04 m; o lago tem até 2,52 m de fundo, `godot.log` `lago_fundura_max_m`). Só é puxado 0,45 m para a câmara (`:14`, `puxar`). A superfície da água fica por cima. É o mesmo mecanismo do D-AUD-02 (figura afundada), que a auditoria marcou como provável.

### Correcção proposta (âmbito)
- **Primeiro o D-AUD-05:** isso resolve a maior parte do «tapa a figura» e do «minúsculo», porque o tamanho dos marcadores vem da distância. Esta parte não precisa de código próprio.
- **Marcadores de alvo** (`arena.gd:538-543`, e o mesmo em `arena_mestre.gd` se o Mestre os tiver): em cima da casa do alvo, desenhar um marcador que **não fique debaixo da água**. Por exemplo, um anel ou seta à altura do corpo/cabeça da figura (o `pe_figura` + a altura), em `no_depth_test`, ou com tamanho mínimo no ecrã. **O aspecto do marcador é decisão do Mestre** (estética). Risco baixo; o teste mede que o alvo tem marcador visível com a figura na água.
- **Caixa por cima do conteúdo** (`hud.gd:1016-1036`, `mestre.gd:1415-1424`): as opções são (a) a caixa compacta ficar semitransparente ou recolher-se enquanto há modo Mover/Ataque armado, ou (b) a câmara reservar a área da caixa (deslocar o foco para o lado livre). Ambas são decisão de desenho do Mestre. A Ordem CAIXA-HUD-JOGADORA escolheu o canto de cima à direita, palavra do Mestre. Risco médio: há 4 ordens de medições da caixa (`caixa_jogadora` 70, `caixa_janela` 123, `medir_mestre`) que fixam a posição e o tamanho. Mexer na posição obriga a refazer essas medidas.

---

## D-AUD-07 — rótulo e agrupamento do Registo · **LOCALIZADO**

### Reprodução
- `l30-mestre-registo3` (aba Registo do Mestre, ponto actual 29), lido de baixo para cima:
  - «Rodada 1 · vez de Heroína Teste · colocação, vez nova» = o MASTER_START (a vez a seguir já é a da heroína).
  - «Rodada 1 · vez de Orc Verdadeiro Teste (Orc) · vez nova» = **o encerrar da heroína**, rotulado com a vez do orc que vem a seguir.
  - «**Rodada 2 · vez de Heroína Teste · Ação do monstro, vez nova**» = o encerrar da IA do **2.º orc, que foi na rodada 1**, rotulado com a rodada e a vez que vêm a seguir. É a mesma linha que a auditoria viu (`r-40`).
- Repare-se que a linha da heroína a encerrar também está errada (diz «vez de Orc»). O defeito não é só do evento `ia`: é de **todas** as linhas que fecham uma vez.

### Causa (ficheiro/linha)
- **Agrupamento:** cada linha do Registo é um **ponto de «voltar»**, um por **transacção** do servidor. `rascunhos/servidor/nucleo/sala.js:1142` (`if (tx.eventos.length) guardarCheckpoint(tx)`). A IA automática faz a escolha e a acção **na mesma transacção**: `sala.js:2266-2280` (`passoIAAuto`: `tx.emitir('ia', …)` em `:2277` + `aplicarIntencao`). Quando a acção é `encerrar`, a mudança de vez (`turno`) entra também nessa transacção. Daí «Ação do monstro, vez nova» numa linha só.
- **Rótulo:** `sala.js:1228-1239` (`guardarCheckpoint`) escreve a `rodada` e o `vezId` do **mundo depois da transacção** (`:1236` `rodada: mundo.rodada`, `:1237` `vezId: mundo.vez?.figuraId`, com `mundo = mundoDe(journal.estado)` já commitado). Numa transacção que fecha uma vez, isso é a figura **seguinte** (e, no fim da volta, a rodada **seguinte**).
- O cliente só escreve o que recebe: `rascunhos/cliente/cenas/mestre/modelo_mestre.gd:276-287` (`linha_ponto`) → `textos_mestre.gd:171` (`PONTO := "Rodada %d · vez de %s · %s"`). O texto «Ação do monstro» é `textos_mestre.gd:212` (`"ia": "Ação do monstro"`, palavra do Mestre, Ordem 27). O texto está certo; o que falha é a vez em que ele aparece.
- **Não é um erro de dados:** o ponto representa o estado **para onde se volta**, e nesse estado é mesmo a vez da figura seguinte. O defeito está no rótulo: junta «de quem é a vez depois» com «o que aconteceu» na mesma frase.

### Correcção proposta (âmbito)
- **Servidor** (`sala.js:1228-1239`): guardar também a vez e a rodada de **antes** da transacção. O `antes` já existe em `transacao()` (`sala.js:1108`, `const antes = journal.estado`): passá-lo a `guardarCheckpoint`, por exemplo como `autorId: antes.vez?.figuraId` e `rodadaAutor: antes.rodada`. O `vezId` fica como está (é o estado do «voltar»). O campo novo é **aditivo** em `MASTER_VIEW.pontos`, por isso os clientes antigos não partem.
- **Cliente** (`modelo_mestre.gd:276-287`, `textos_mestre.gd:171`): a linha passa a ser «Rodada R · **vez de AUTOR** · tipos», e se a vez mudou, «… → vez de SEGUINTE». O texto exacto é palavra do Mestre. Sem o campo novo (sala de antes), fica a linha de hoje.
- **Risco:** baixo a médio. Mexe na projecção da MASTER_VIEW, que é só do Mestre e nunca vai à Party, por isso a privacidade não muda. Testes afectados: `servidor/testes/mestre-vista.test.mjs`, `ordem32-varredura.test.mjs`, `ordem25-n24-1.test.mjs` (que lêem `pontos`) e `cliente/testes/pecas_mestre.gd:98-100` (`linha_ponto`). O «voltar» continua a usar o `journalSeq`; o rótulo não entra na restauração.
- **Alternativa sem mexer no servidor (pior):** o cliente deduzir o autor pela linha anterior. É frágil, porque a lista vem cortada a `MAX_PONTOS_VISTA` e o «voltar» apaga pontos. Não recomendo.

---

## D-AUD-12 — nomes duplicados sem número · **LOCALIZADO**

### Reprodução
- `l22-mestre-orc1` → `l23-mestre-2orcs-figuras`: depois de colocar dois orcs da mesma ficha, a aba Figuras mostra **duas linhas iguais** («Orc Verdadeiro Teste (Orc) · criatura · vida 7777/7777 · PA 313/313 · À mão»), e os rótulos no tabuleiro também são iguais.
- `l25-mestre-agir-orc` / `l26-mestre-ia`: «Vez de Orc Verdadeiro Teste (Orc)» aparece **nas duas vezes seguidas**. O Mestre não consegue saber qual dos orcs está a jogar.
- `l28-jog` / `l23-jog-2orcs`: na jogadora, a caixa da ordem mostra «Orc» e «Orc» (o nome público), também sem distinção.
- `l30-mestre-registo3`: no Registo, as linhas dos dois orcs também não se distinguem.

### Causa (ficheiro/linha)
- **O nome é da ficha, não da figura.** Em nenhum ponto do caminho entra alguma coisa própria de cada figura:
  - Servidor, `MASTER_PLACE`: `rascunhos/servidor/nucleo/sala.js:2630-2640`. A figura nova tem `id` único (`novoId('f', …)`, `:2630`), mas o evento `colocacao` leva `nomePublico: nomePublicoDe(ficha)` (`:2638-2640`).
  - `rascunhos/servidor/nucleo/projecao.js:85-90` (`nomePublicoDe(ficha)`) e `:149-155` (`figuraDoMestre`: `nome: ficha?.nome`, `nomePublico: nomePublicoDe(ficha)`). Os dois saem só da ficha.
  - `novaFigura` (`sala.js:543-554`) não guarda nenhum número de ordem nem sufixo.
- **O cliente mostra-o tal e qual:** Mestre, `rascunhos/cliente/cenas/mestre/modelo_mestre.gd:31-38` (`nome_mestre` = «nome (público)»), usado nas Figuras (`:55`), nos rótulos do tabuleiro (`arena_mestre.gd:262,274`), no Agir (`aba_agir.gd:75`), na caixa (`mestre.gd:996,1469`) e no Registo (`modelo_mestre.gd:285`). Jogadora, `rascunhos/cliente/estado/estado.gd:355-359` (`nome_de` = `nomePublico`), na caixa (`hud.gd:994`), e o rótulo 3D em `arena.gd:709-710`.

### Correcção proposta (âmbito)
- **Recomendado: no servidor, uma vez.** Ao colocar (`sala.js:2630-2640`), se já existe outra figura da mesma ficha, a figura nova recebe um **ordinal** (2, 3, …) guardado nela (por exemplo, `f.ordinal`). O `nomePublico` e o `nome` projectados passam a ter o sufixo, por exemplo «Orc 2» (o formato é palavra do Mestre). Tocar em `projecao.js` (onde o nome é composto, `:85-90` e `:149-155`) e em todos os eventos que levam `nomePublico` (`colocacao`, `entrada`: `sala.js:2609`, `:2639`, `:3464`).
  - Vantagem: Mestre, Party, caixa, rótulos, Registo e exportação ficam todos coerentes, sem mudar o cliente.
  - **Privacidade:** o sufixo é só um número, e a Party já sabe que há duas criaturas (vê as duas figuras). Não revela nada novo. Mesmo assim, o canário de privacidade tem de correr.
  - Risco médio: o estado da sala ganha um campo (`conferir-estado.js` tem de o aceitar); salas e journals antigos não o têm (sem sufixo, como hoje). O «Recomeçar» (`casaColocacao`) e o «voltar» restauram o campo com o resto da figura.
- **Alternativa só no cliente:** numerar pela ordem do `id`, na apresentação (`nome_mestre`, `nome_de`). É mais rápida, mas o número pode mudar entre aparelhos se as listas vierem por ordem diferente, e a exportação/registo do servidor continua sem número. Não recomendo.

---

## D-AUD-14 (só o layout) — o tabuleiro do Mestre a metade · **LOCALIZADO** (o perfil gráfico não foi tocado)

### Reprodução
A **mesma janela de 1600×900**, medida em píxeis (a coluna onde começa a folha, à altura y=700):

| Captura | Caminho até 1600×900 | Tabuleiro |
|---|---|---|
| `l08-mestre-sala` | o ecrã do Mestre aberto já a 1600×900 | **880 px (55 %)** |
| `l10-mestre-1600-depois-800` | 1600×900 → **800×450** (`l09`) → 1600×900 | **712 px (44,5 %)** |
| `l11-mestre-1600-repassado` | a seguir: 1600×898 → 1600×900 | **865 px (54,1 %)** |

**A largura do tabuleiro depende do histórico de tamanhos da janela, não só do tamanho actual.** A auditoria abriu os clientes a meio ecrã (800×450, o lançador da bancada) e só depois os passou a 1600×900. Por isso viu 800 px, «metade». Uma janela aberta directamente a 1600×900 dá os 55 % do desenho.

A coluna 1 «quase vazia» também se vê aqui (`l08`, `l30`): a doca do cartão reserva a altura do título + cartão mesmo com «Nada por decidir.». O corte do alerta («…tentou») não apareceu nesta corrida (não houve alerta); fica a prova `r-40` da auditoria.

### Causa (ficheiro/linha)
- `rascunhos/cliente/cenas/mestre/mestre.gd:1311-1365` (`_ao_redimensionar`, ligado a `size_changed` em `:195`):
  - `:1319` a letra passa a `max(22, ceil(13 / escala))`. A 800×450 a escala é 0,417, por isso a letra fica em **32**; a 1600×900 volta a **22**.
  - `:1330` folha = 45 % (`FRACAO_TABULEIRO := 0.55`, `:44`), **mas** `:1335-1336` alarga-a até caber `largura_col1 + largura_abas`, com `largura_abas = _abas.get_tab_bar().get_minimum_size().x`. Esta medida é tirada **no mesmo quadro** em que a letra do tema acabou de mudar (`_tema.default_font_size = _fonte`), e por isso ainda tem o tamanho da letra **anterior**.
  - `:1361-1365`: a «segunda passagem» que devia corrigir isto (`_ao_redimensionar.call_deferred()`) corre no **fim do mesmo quadro**, e ainda apanha a medida velha. Depois disso, mais nada volta a calcular a folha até a janela mudar outra vez de tamanho. O resultado: a largura da barra das abas com a letra 32 fica presa, e o tabuleiro encolhe (712 px).
  - Mecanismo provado pelo efeito (o mesmo tamanho dá três larguras, e um novo redimensionamento quase repõe) e pelo código. O instante exacto em que o Godot actualiza o mínimo da `TabBar` não foi instrumentado.
- **Coluna 1:** `mestre.gd:1322` (`largura_col1 = fonte × 14`, ~260 px a 1600×900), `:1328` (a doca tem altura fixa de `LINHAS_TITULO + LINHAS_CARTAO` linhas), `:1124` (`_alerta.max_lines_visible = 2`, que corta o texto do alerta).

### Correcção proposta (âmbito)
- **Largura presa** (`mestre.gd:1333-1338`, `:1361-1365`): não medir a barra das abas no quadro em que a letra mudou. Recalcular quando a `TabBar` avisar que mudou (`minimum_size_changed` / `resized` da barra → `_ao_redimensionar`), ou adiar a 2.ª passagem um quadro inteiro (`await get_tree().process_frame`). Também se pode calcular a largura das abas pela letra nova (soma das larguras do texto com `get_string_size` na letra `_fonte` + o estilo da aba), sem depender do mínimo em cache.
  - Risco baixo. Teste novo em `medir_mestre`: abrir a 800×450, passar a 1600×900 e exigir que o tabuleiro seja igual ao de abrir directo a 1600×900. Hoje falharia: 712 contra 880.
- **Proporção de 55 %** (`:44`) e **coluna 1** (`:1322`, `:1328`, `:1124`): isto é desenho, não erro. Dar mais tabuleiro (por exemplo, a coluna 1 recolher quando não há cartão) é **decisão do Mestre**. Não mexi no perfil gráfico (decisão do Mestre, como manda a ordem).

---

## Achado lateral (fora dos 5; não investigado a fundo)

- **O cliente do Mestre abre na arena da jogadora.** Com o `lugar.cfg` do Mestre (`papel="mestre"`), a cena principal é `cenas/arena/arena.tscn` (`project.godot:11`), e a arena não manda o Mestre para `mestre.tscn`. Só o `lobby.gd:287-289` (`_verificar_fase`) faz isso. O Mestre via «Esperando o Mestre começar…» na arena da jogadora (`capturas/l01-mestre-abre-na-arena-da-jogadora`, e `capturas/i00-mestre-inicio-bancada-preparada`, da tentativa das 17:21, com «Vez de Heroína Teste» e a HUD da jogadora no cliente do Mestre). A auditoria contornou isto como eu: ⚙ → «Sair da mesa» → PIN. Esta saída põe a sala em **pausa** (`mestre_desconectado`). Proponho dar-lhe um número D-AUD na conferência.

## Provas nesta pasta

- `capturas/` (24): `l07`–`l11` (Mestre e o layout), `l15`–`l20` (+ `l17z`, `l18z`: D-AUD-05/06), `l22`–`l26` e `l28` (D-AUD-12), `l30` (D-AUD-07), `l32` e `l32z` (marcadores), `i00-jog-inicio-bancada-preparada` (contraprova do D-AUD-05), `l01-mestre-abre-na-arena-da-jogadora` e `i00-mestre-inicio-bancada-preparada` (achado lateral).
- `videos/d05-jog-comecar-do-lobby.mp4`: a janela da jogadora a 30 fps, a partir das 20:41:13 (-03) até ao fecho. Contém o «Começar» (a heroína aparece no canto, sem a câmara se mexer), o Mover para o lago (a câmara não segue), a colocação dos orcs, a IA e o Ataque.
