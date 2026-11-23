# PLANO 2 — Fecho e lapidação do jogo (2026-11-23)

**Base:** `ANALISE-JOGO-2026-11-23.md` (a mesma linha, ponta `8e9bf81`). O plano original é o Plano A v1.1, o Plano B
v1.1 e a página-mãe dos Planos (Notion, 06/11/2026; ver a análise §0). Os defeitos citados vêm da auditoria de hoje
(`ESTADO-FINAL-ORDEM-AUDITORIA-LINHA.md`, D-AUD-01 a 15).

**O fim do plano** é o jogo da visão: o campo de batalha das sessões do Mestre.
- O Mestre narra e comanda no ecrã dele.
- As jogadoras jogam **cada uma no seu aparelho**, na mesma partida.
- A caixa e a HUD seguem as ordens já fechadas.
- Os dados mostram a fórmula.
- As figuras **mexem-se com o corpo todo**.

Este plano **não inventa mecânicas**. Onde o plano original e as ordens fechadas calam, está escrito
**[DECISÃO DO MESTRE]**. Onde falta prova de que uma coisa exista, está escrito **[FALTA]**.

---

## Regra de rumo (vale para todas as fases)

1. **Cada ordem nomeia a fase deste plano e a missão do plano original que fecha** (JV… ou V…), e diz **o que o
   jogador vê de novo** quando ela acaba. A causa do desvio foi as ordens terem deixado de citar as missões a
   partir de 13/11 (análise §3.5).
2. **Prova proporcional:** suites verdes, mais **uma** captura ou vídeo do que mudou no ecrã. As ferramentas de prova
   só mudam quando impedem a prova do jogo. Uma correcção de correcção para além da 2.ª sobe ao coordenador como
   decisão, e não abre ordem nova sozinha. *(Proposta de regra da casa: **[DECISÃO DO MESTRE]**, porque mexe no
   modo de trabalho que ele mandou.)*
3. **Uma fase só fecha com o seu critério de aceitação cumprido e uma entrega visível ao Mestre** (fotos, vídeo ou
   link), como manda a P1 §8 («Ao Mestre só chegam entregas»).

---

## Mapa das fases

| Fase | Entrega visível | Depende de | Pode correr em paralelo com |
|---|---|---|---|
| **F1** Batalha que se vê | Golpes que acertam, quedas e mortes na mesa de rede; a câmara segue a figura; o «na vez» certo; o Mestre sem criaturas duplicadas | — | F2 |
| **F2** Cada um no seu aparelho | O Mestre no PC; as jogadoras entram pelo QR no telemóvel e no PC; 10 turnos na rede da casa | — (o teste final usa a F1) | F1 |
| **F3** HUD e dados à vista | A vida e os PA da jogadora; o dano por tipo; **a fórmula do dado no ecrã**; a caixa sem tapar nada | F1 | F4 |
| **F4** As acções que faltam | Consumível e reacção na barra e na ficha; os dados físicos validados; os números do ambiente vindos do pacote | F1 | F3 |
| **F5** Figuras de corpo inteiro | Personagens com ossos a andar, correr, atacar, ser atingidos, cair, morrer e nadar; o mesmo corpo nos dois ecrãs; o machucado à vista | F1; a entrada dos personagens (Plano C) | F3, F4 |
| **F6** O olho do Mestre | A página de entrega do mapa (a «Clareira» do Plano B) de dia e de noite, no PC e no telemóvel; «Aprovo / Quero ajustes» | F2 (para medir no telemóvel), F5 | — |
| **F7** A sessão de teste | Uma sessão real: o Mestre a narrar, as jogadoras nos seus aparelhos, uma batalha inteira | F1–F6 | — |
| **F8** Lapidar e crescer | Tiro, replay, ficha interactiva, publicação, IA com doutrina, mais mapas | F7 | — |

---

## F1 — A batalha que se vê

**O que entrega de VISÍVEL:** numa batalha de bancada, os ataques acertam, e vêem-se o dano, a queda, os testes de
morte e a morte. A câmara da jogadora mostra e segue a figura dela. O «na vez» bate com o banner. O «Colocar» do
Mestre já não cria uma 2.ª cópia.

**Trabalho, com a missão do plano original que fecha:**
1. **Fichas fictícias jogáveis** para a bancada de rede, com CA e Vida em números que um `1d20+n` alcança, e os
   canários **só** onde a sonda os procura (D-AUD-04; JV2.4). As fichas reais continuam fora do repositório (P2 §A2).
2. **D-AUD-01:** o «Colocar» desarma depois de cada `MASTER_PLACE`, ou o Mover da aba Agir tem prioridade
   (`cenas/mestre/aba_mesa.gd:221-230`, `mestre.gd:690-693`). Qual das duas leituras vale é desenho do ecrã do
   Mestre (JV3.1). A auditoria propõe o desarmar; não há palavra do Mestre sobre isso: **[DECISÃO DO MESTRE]**.
3. **D-AUD-03:** o rótulo «na vez» da caixa no modo dinâmico (`hud/ordem_turnos.gd:158-159`). Se o modo dinâmico
   deve mostrar «quem agiu por último» ou «quem joga agora» é **[DECISÃO DO MESTRE]** (a auditoria, §7, deixou-o à
   conferência). O que não pode ficar é o texto «na vez» a contradizer o banner.
4. **D-AUD-05:** a câmara da jogadora abre centrada na figura dela e acompanha-a quando ela anda (JV2.2). O modo
   «dinâmica e retrato» da M-33 entra aqui, se o texto da M-33 o disser. Esse texto **[FALTA]** no repositório.
5. **D-AUD-12:** as criaturas da mesma ficha ganham número («Orc 1», «Orc 2») na lista, no tabuleiro e na caixa.
6. **D-AUD-15:** uma corrida de N grande (≥10 000 sementes) pelo caminho real do ataque, que confirma ou afasta a
   suspeita dos dados (JV1.3).

**Critério de aceitação:**
- Batalha de bancada com 2 clientes reais e o servidor de produção, **acabada por morte** e não por «Terminar»; vídeo
  dos dois ecrãs.
- 0 colocações duplicadas no journal da corrida.
- Em 20 vezes seguidas, o «na vez» da caixa é igual ao banner (ou à regra decidida no ponto 3).
- A figura da jogadora fica dentro do terço central da imagem no arranque e depois de cada movimento (captura).
- A distribuição das faces na corrida do ponto 6 fica dentro de ±0,5 pp de 5 % por face; a sequência registada é
  igual à simulada.
- Suites verdes e canários a 10/10.

---

## F2 — Cada um no seu aparelho

**O que entrega de VISÍVEL:** o Mestre arranca o servidor no PC. As jogadoras lêem o QR com o telemóvel ou abrem o
link no PC, entram no lobby **sem instalar nada** (M-46) e jogam na mesma partida. Se uma cai da rede, volta sem
perder nada.

**Trabalho, com a missão que fecha:**
1. **JV2.1b:** `export_presets.cfg` com Web (Thread Support desligado), Android (INTERNET, arm64-v8a + x86_64,
   tráfego em claro só na rede local) e Windows. Um job de export no CI a cada commit.
2. **JV3.4:** o servidor serve o export web e o `ws://…/mesa` na **mesma origem** (`servidor-ws.js:432-455` já serve
   estáticos) e mostra o **QR**. O teste do CI com 3 bots e 25 s sem rede: o hash lógico fica igual e o `seq` contínuo.
3. **V1.0:** o link de medição de 1 minuto (FPS mediana e p5, chamadas, GPU, viewport e DPR), que devolve o JSON
   sozinho. Ao Mestre só vai «abra e espere 1 minuto».
4. **JV3.4b:** a prova na rede da casa com 1 Android e 1 PC: 10 turnos e o Wi-Fi desligado 25 s.
5. **JV0.5 (b):** a máquina do servidor. O Plano A pede «uma máquina que não seja o PCDANASA», e a sentença **[FALTA]**.
   Enquanto ela não sair, a máquina da sessão é **[DECISÃO DO MESTRE]**.
6. **JV0.2:** o destino do repositório (o privado provisório ou o definitivo, mais o público só de builds) é a
   sentença JV0.5 (a), que **[FALTA]**. Sem ela a F2 entrega por artefacto do CI, não por Pages.

**Critério de aceitação (os aceites do Plano A, à letra):**
- O export web emite «pronto» no Chromium sem janela do CI em até 30 s (JV0.2); a web, o Windows e o Android
  recebem o `ROOM_SNAPSHOT` de um servidor de teste (JV2.1b).
- As duas jogadoras entram pelo QR sem instalar nada; a reconexão demora ≤ 30 s e nada se perde (JV3.4b).
- O JSON da V1.0 do telemóvel do Mestre traz todos os campos; repetir dá o mesmo com ±10 %.
- Relatório de 5 blocos, com fotos dos aparelhos e os logs.

---

## F3 — HUD e dados à vista (conforme as ordens fechadas)

**O que entrega de VISÍVEL:**
- Em combate, a jogadora vê a sua vida e os seus PA.
- Os números de dano saem por tipo.
- Cada rolagem mostra a **fórmula**: a expressão, as faces, os modificadores e o total.
- A caixa da ordem não tapa a figura nem as casas ao alcance.

**Trabalho, com a missão que fecha:**
1. **A caixa da ordem fica como as ordens fechadas a deixaram:**
   - o cartão grande da vez e as 4 seguintes; a expandida com o rato ou o toque (commit `878b13e`);
   - quadradinhos do mesmo tamanho e retrato em busto (commit `6083d1c`);
   - as cores da paleta C (commit `a63c2c1`, palavra do Mestre de 21/11 12:12);
   - a ligada/desligada e o modo escolhidos pelo Mestre e lidos do servidor (commit `fd7f978`).

   **Nada disto se redesenha.** Só se fecha o D-AUD-06: a posição, para não tapar. Onde a pôr no ecrã da jogadora
   é **[DECISÃO DO MESTRE]**, se o «encostada à direita, acima da barra» do `878b13e` não chegar.
2. **D-AUD-09 (JV2.3, JV4.3):** a vida e os PA da jogadora. Se aparecem, e onde, é **[DECISÃO DO MESTRE]** (auditoria
   §6). A R0 do site seria a régua, mas a página da R0 **[FALTA]**.
3. **Dano por tipo (JV2.3, «palavra dele»):** o servidor manda as partes por tipo, e não um só `valor`
   (`estado/estado.gd:510`, «DIVERGÊNCIA»). A projecção mostra à jogadora só o dano dela (M-18; P2 JV2.3 ponto 5).
4. **A fórmula do dado à vista.** Hoje a jogadora só lê «Errou. Total 14.» (`hud.gd:841-849`). Passa a ver a
   expressão da técnica, as faces que saíram, os modificadores e o total, **tal como o motor os devolve**, sem conta
   nenhuma no cliente (P2 §A1.2, «o Godot nunca calcula regra»).
   - **Privacidade:** nunca a CA nem a RD do alvo (P2 JV1.2, «o recibo público não traz bruto nem RD do alvo»).
   - O desenho exacto (onde, por quanto tempo, se as rolagens dos outros também aparecem) é
     **[DECISÃO DO MESTRE]**: nem o Plano A nem as ordens fechadas o dizem.
5. **O contador de Vantagem/Desvantagem** (errata v1.2 do Plano A, `DESENHO-CONTADOR-VD-v2.md`). O desenho está na VM
   do Muse; no repositório **[FALTA]**. As perguntas P-VD-1 a 4 são **[DECISÃO DO MESTRE]**.
6. **D-AUD-07** (o rótulo do Registo do Mestre) e **D-AUD-14** (o tabuleiro do Mestre só com metade da largura).

**Critério de aceitação:**
- Capturas a 1920×1080 e no viewport do telemóvel do Mestre (o da V1.0 da F2), com a vida, os PA, o dano por tipo e
  a fórmula de 1 ataque que acerta e de 1 que erra.
- O OCR lê o dano e a fórmula em 20 de 20 capturas a 500 ms, sobre 4 fundos (P3 §B3).
- Os canários continuam a 10/10 e nenhum campo novo leva CA ou RD de criatura à jogadora (`canario_privacidade.gd`).
- B5: numa bateria de 50 turnos, o chip é sempre igual à ficha (P2 JV2.3).

---

## F4 — As acções que faltam

**O que entrega de VISÍVEL:** a jogadora usa um consumível e responde a uma reacção. O Mestre confirma os dados
físicos e um valor fora do intervalo é recusado.

**Trabalho, com a missão que fecha:**
1. **Consumíveis (JV2.4):** hoje `consumiveis: []` (`sala.js:947`). O REF_7 §9.10 diz «ainda sem conteúdo». **Que
   consumíveis existem, e o que fazem, é [DECISÃO DO MESTRE].** O servidor e a barra ficam prontos a ligar quando o
   conteúdo chegar pelo pacote de fichas (JV0.6b).
2. **Reacções (A-4, janela de reacção):** hoje `reacoes: []` (`sala.js:947, 2227`). A janela da A-4 e o **valor do
   Defender** (`sala.js:1599`) são **[DECISÃO DO MESTRE]**.
3. **Dados físicos (JV1.3, M-28):** validar o intervalo de cada face contra a expressão (`sala.js:201`, TODO).
4. **O dano do raio** passa do código (`ambiente.js:35`, `DANO_RAIO = 15`) para o pacote do Mestre, como manda a
   JV3.3a. O valor final é **[DECISÃO DO MESTRE]** («depois eu resolvo», `ambiente.js:8`).
5. **As perguntas R0 abertas no servidor:** correr depois de andar (`sala.js:931`), apanhar a arma sem reserva
   (`:935`), levantar o monstro (`:1443`), a estabilização por ajudante (`:1462`), a defesa na AoO (`:1594`) e a
   margem de crítico (`:1676`). Fecham-se com a R0 do site, se ela existir; senão, cada uma é
   **[DECISÃO DO MESTRE]**.
6. **JV0.3, vetores-ouro:** pelo menos 500 casos em 9 grupos, para a batalha roteirizada da JV2.4 ter contra que se
   medir.

**Critério de aceitação:**
- Os testes do servidor mostram a recusa de um valor físico fora do intervalo e a aplicação de um consumível e de uma
  reacção a partir do pacote fictício.
- Os vetores-ouro dão 100 % no CI e duas corridas são byte-idênticas (P2 JV0.3).
- O grep da regra no cliente dá 0 (P2 JV2.1a).
- Um vídeo de 1 consumível e de 1 reacção na bancada.

---

## F5 — Figuras que se mexem com o corpo todo

**O que entrega de VISÍVEL:**
- As figuras deixam de ser peões: são corpos com ossos que respiram parados, andam, correm, atacam, são atingidos,
  caem, morrem e nadam.
- O mesmo corpo nos dois ecrãs.
- Vêem-se dentro da água.
- O machucado aparece no corpo.

**Trabalho, com a missão que fecha:**
1. **V3.1:** a entrada dos personagens no jogo, com o GLB-JOGO-v1 validado (`rascunhos/validador-glb/`, já existe), o
   kit de materiais e os clips da lista da O1.1. A produção é do Plano C, cujo estado está fora deste repositório:
   **[FALTA]**.
2. **Enquanto não houver personagens do Plano C:** a casa tem o manequim com ossos (`testes/manequim/andar-v3.glb`,
   `nado-v1.glb`), que já está a andar e a nadar nos vídeos de prova. Pô-lo provisoriamente no lugar dos marcadores é
   **[DECISÃO DO MESTRE]**: o Plano B proíbe marcador e chibi na Clareira, mas não diz nada sobre o manequim.
3. **D-AUD-11:** um só modelo por figura, igual na jogadora e no Mestre (`cenas/comum/marcador_figura.gd` passa a ser
   só o recurso de quando não há GLB).
4. **V1.2:** o feedback do golpe, com flash, recuo, VFX em flipbook e números de 28 a 36 px. Os «indícios de intenção»
   só aparecem depois de o servidor confirmar (P3 V1.2).
5. **D-AUD-02:** a figura vê-se na água. A fundura e quanto a figura afunda (`mapa/floresta/lago_floresta.gd:42`,
   `FLUTUA_M = 1.25`) são **[DECISÃO DO MESTRE]** (auditoria §6).
6. **JV4.3 (machucado):** o machucado segue o estado do servidor. O aspecto é **[DECISÃO DO MESTRE]** (C-43, cujo
   texto **[FALTA]** no repositório).

**Critério de aceitação:**
- Teste de estátua: pelo menos 2 % dos píxeis de cada figura parada mudam em 1,2 s (P3 §B3).
- Os 8 ângulos e o validador verde por personagem (P3 V3.1).
- Um vídeo com os clips andar, correr, atacar, atingido, cair, morrer e nadar, no mapa, nos dois ecrãs.
- A silhueta com contraste ≥ 2,0 em pelo menos 95 % dos quadros (P3 §B3), **também de noite** (D-AUD-13).
- Nenhuma figura desaparece na água (captura da rodada com 3 figuras no lago, como `r-37z` da auditoria).

---

## F6 — O olho do Mestre (a «Clareira»)

**O que entrega de VISÍVEL:** a página de entrega da P3 V2.1, com:
- 2 pares antes × depois;
- dia e noite nas câmaras Fixa, 360° e Panorama;
- PNG a 1920×1080 e no telemóvel;
- um vídeo de 20 a 30 s;
- o link para jogar;
- um toque: «Aprovo» ou «Quero ajustes».

**Trabalho:**
1. **Fechar o desvio da V2.1.** Entrega-se o **mapa da floresta** (o campo de batalha de hoje) como a cena de prova.
   Se o Mestre aceita o mapa no lugar da clareira pequena do plano é **[DECISÃO DO MESTRE]**: é ele quem disse que a
   sessão só acontece com a Clareira aprovada (P1 §6).
2. **D-AUD-13:** o contraste do tabuleiro de noite. A velocidade do ciclo de dia e noite e a tabela do clima são
   **[DECISÃO DO MESTRE]** (auditoria §6).
3. As métricas do B3 (sombra L\*, silhueta, chamadas p95 ≤ 150) nas 4 horas, e o FPS no telemóvel dele pelo link da
   V1.0 (Médio: mediana ≥ 30, p5 ≥ 20).
4. **V2.0c:** os vagalumes passam da Clareira de prova (`arte/cenas/clareira_prova.gd`) para o mapa.
5. As peças do Muse de que a V2.1 dependia (V0.1 guia de estilo, V0.2 triagem, V2.0a T1, V2.0b lapidação) **[FALTA]**.
   O coordenador confirma se existem; sem elas, a página de entrega diz o que é placeholder.

**Critério de aceitação:** o B3 cumprido nas 4 horas; os Críticos artista, programador e de fluidez liberam; **o
Mestre carrega em «Aprovo»** (P3 V2.1).

---

## F7 — A sessão de teste (o «pronto» da v1)

**O que entrega de VISÍVEL:** a primeira sessão real.
- O Mestre narra e comanda no ecrã dele.
- As jogadoras jogam cada uma no seu aparelho, na mesma partida.
- Há uma batalha completa com as regras oficiais e as fichas reais, que só o servidor lê.

**Depende de:** F1–F6, e do pacote real de fichas (JV0.6b, do Muse: **[FALTA]**).

**Critério de aceitação (P2 §A0, à letra):**
- sessão real, cada jogadora no seu aparelho;
- batalha completa numa arena de pelo menos 20×20 casas, com as regras oficiais e **zero dados do Mestre** no
  aparelho das jogadoras (a sonda e os canários sobre o tráfego da sessão);
- a Clareira aprovada (F6).

Relatório de 5 blocos com o journal (a cadeia de hashes íntegra) e as falhas vistas.

---

## F8 — Lapidar e crescer (depois da sessão)

| Missão do plano original | O que entrega | Aceite | Decisões |
|---|---|---|---|
| JV4.1 Tiro (C-42) | Arco 18 m (até 30 m), arremessável 6 m, cobertura em escada, linha de visão (fecha o B9) | Os vetores de tiro passam; o B9 fecha por teste (P2 JV4.1) | Q-01/Q-02 da prévia de tiro: **[DECISÃO DO MESTRE]** (errata v1.2) |
| JV4.2 Replay | O replay colectivo; salvar e carregar entre sessões; os checkpoints do «voltar» em disco (`sala.js:1229`) | Replay com o mesmo hash (P2 JV4.2) | — |
| JV4.3 Ficha interactiva | A jogadora vê e usa a ficha dela | Só os canários dela (P2 JV4.3) | O conteúdo da ficha (C-20): **[DECISÃO DO MESTRE]** |
| JV4.4 Publicação | Web não listada, APK e pacote Windows | Sonda zero no Pages e no raw (P2 JV4.4) | O repositório de builds: sentença JV0.5 (a), **[FALTA]** |
| JV3.5a/b IA com doutrina | A IA «gerar → 6 críticos → Juiz», com a razão só para o Mestre; o exame com ≥ 10 000 batalhas por arena | O alvo do exame cumprido (P2 JV3.5b) | O alvo do «0,50 %» e o âmbito: **[DECISÃO DO MESTRE]** |
| JV1.5 Hospedagem | A medição workerd e Cloudflare (só se se quiser jogar fora de casa) | p99 ≤ 5 ms, nenhuma invocação > 10 ms (P2 JV1.5) | Jogar pela internet: **[DECISÃO DO MESTRE]** |
| V4.1/V4.1b, V4.2, V4.4 | Os kits T1–T8, a vida ambiente D-01 a D-13, os perfis confirmados nos 3 aparelhos | Os aceites da P3 | A ordem das tranches é dele (P3 V4.1) |
| JV3.2 (o desvio) | Ratificar o ecrã do Mestre no app Godot no lugar da ligação à C-17 | A sentença escrita | **[DECISÃO DO MESTRE]** (ou bancada JV0.5 (c), se o Mestre a delegar) |

---

## Pontas da análise → onde fecham

| Ponta (análise) | Fecha em |
|---|---|
| A0 «sessão real», A0 «Clareira aprovada» | F7, F6 |
| JV0.1 R0 (página [FALTA]) | F3 e F4 (cada pergunta R0 vira [DECISÃO DO MESTRE] se a R0 não aparecer) |
| JV0.2, JV0.5 | F2 (pontos 5 e 6) |
| JV0.3 vetores-ouro | F4 |
| JV0.4 `VISIBILIDADE.md` | F3: escrever a tabela a partir do `projecao.js` quando entrarem os campos novos (dano por tipo, fórmula) |
| JV0.6b pacote real | F7 (do Muse) |
| JV1.3 intervalo e D-AUD-15 | F4, F1 |
| JV1.5 | F8 |
| JV2.1b, JV3.4, JV3.4b, V1.0 | F2 |
| JV2.2 câmara (D-AUD-05) | F1 |
| JV2.3 HUD (D-AUD-03, 06, 07, 09, 14; dano por tipo) | F1, F3 |
| JV2.4 batalha completa (D-AUD-04; consumível, reacção) | F1, F4 |
| JV3.2 desvio | F8 (ratificação) |
| JV3.3a raio no código | F4 |
| JV3.5a/b | F8 |
| JV4.1, JV4.2, JV4.4 | F8 |
| JV4.3 | F5 (machucado), F8 (ficha) |
| V0.1, V0.2, V2.0a, V2.0b, V4.1 ([FALTA], do Muse) | F6 (ponto 5), F8 |
| V1.1, V1.2, V2.0c, V3.1, V4.2, V4.3, V4.4 | F5, F6, F8 |
| V2.1 desvio (mapa no lugar da Clareira) | F6 |
| D-AUD-01, 03, 04, 05, 12, 15 | F1 |
| D-AUD-02, 11, 13 | F5, F6 |
| D-AUD-06, 07, 09, 14 | F3 |
| D-AUD-08 (IA sem encurtar) | F8 (JV3.5a), baixa confiança |
| D-AUD-10 (o clique que não chegou) | F2 (o teste de 3 bots apanha-o; não foi reproduzido) |
| A proporção do esforço (análise §3) | Regra de rumo, no topo |
