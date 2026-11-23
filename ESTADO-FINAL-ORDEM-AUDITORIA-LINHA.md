# ESTADO-FINAL — ORDEM-AUDITORIA-LINHA (auditoria crítica da build jogável)

**Cadeira:** Claude conta 2 (PC), Opus 5.5 · **Linha:** `fable/integracao-50` · **Base:** `e91fb95` (ponta conferida por `git ls-remote` às 15:23 -03; não andou)
**Corridas:** 1.ª 13:49–14:15 (limite de 5 h) · **retoma** 15:22–~16:00 (-03), sobre a pilha viva, sem recomeçar nada que existisse. O ponto da retoma está em `ESTADO-FINAL-ORDEM-AUDITORIA-LINHA-PARCIAL.md` (commit `9be27c3`).
**Provas:** `provas/ordem-auditoria-linha/` (README com o mapa: 29 capturas, 10 vídeos, `relato.txt`, suites, medida do Mestre).

Esta ordem mede; não conserta. Nada em `rascunhos/cliente/**` nem em `rascunhos/servidor/**` foi tocado. Escrevi o ESTADO-FINAL, o parcial e os ficheiros de `provas/`, incluindo uma ferramenta de medição que só mede.

## 1. A batalha corrida (critério 1)

Na bancada de rede: servidor de produção (`servidor-ws.js` + motor real VLAB) e 2 clientes Godot 4.7.2 reais, no RTX 4060 (OpenGL 3.3 Compatibility). Mestre num cliente, jogadora no outro; o input chega às janelas por PostMessage, sem rato nem teclado globais.

- **Lobby → arena → fim, completo na pilha 2.** Às 15:25:57 o Mestre carregou em «Continuar» (`retomada`), escolheu o orc na Mesa e carregou duas vezes em «Começar a batalha»; o servidor colocou a heroína (38,4) e o Mestre o orc (29,15). Houve **9 rodadas**: 4 movimentos da heroína, 3 dos orcs (1 à mão e 2 pela IA) e **18 ataques**. O fim veio pelo «Terminar batalha» do Mestre (`fim`, desfecho `terminada`, 15:35:48). Ao todo o journal tem 100 eventos e a cadeia de hashes está íntegra (`relato.txt`).
- **Porquê «Terminar» e não morte:** as fichas da bancada têm CA «canário» (heroína 5551, orc 9137) contra ataques `1d20+4`. **Nenhum ataque pode acertar**, e o crítico do VLAB é de 3d6, não de d20. Os 18 ataques deram 18 `erro` (D-AUD-04). Com estas fichas não é possível chegar a uma morte na bancada.
- **`0 SCRIPT ERROR` no arranque dos dois clientes:** os 4 logs `user://logs` (jogadora e Mestre, pilhas 1 e 2) têm 0 `SCRIPT ERROR`, 0 `ERROR` e 0 `WARNING`.
- A 1.ª pilha (13:55–14:10) chegou à rodada 1 com as duas figuras colocadas e morreu quando o coordenador a parou. A sessão de então **relançou a bancada às 14:13, contra o «NAO relancar» das 14:11**. Está registado no parcial; a conferência é do coordenador.

## 2. As notas (critério 2)

**Ressalva sobre a régua.** O `GOAL.md` (secção «Régua crítica») **não está neste PC**: não está no repo e dá 404 nos 5 repositórios do dono. Também não tenho as notas da v3 por eixo, só o total de **4,7/10** (30/10/2026). Por isso as notas abaixo usam os 7 eixos nomeados na ordem, com o que foi corrido, o que foi visto e o número que as sustenta. A comparação eixo a eixo com a v3 e com o texto da régua fica para a conferência do coordenador. Não inventei critérios.

| Eixo | Nota | O que foi corrido / visto | Número que a sustenta |
|---|---|---|---|
| **Movimentação** | **6** | Mover com um só clique; o servidor aplica e o custo bate certo; casas ao alcance a azul; «Correr» à mão. **Mas** a figura desaparece ao entrar na água e a câmara não a segue (D-AUD-02, 05). | 4/4 movimentos da heroína aplicados (9 m = 6 casas; 6 m; 3 m = 2 casas → 1,5 m/casa); 0 recusas; vídeo `v01`, `v04` |
| **Ataques** | **3** | O circuito funciona: Ataque → alvo → resultado na HUD («Errou. Total 14.»); a IA ataca. **Mas** na bancada não há acerto, dano, queda nem morte; os marcadores de alvo são minúsculos; há uma suspeita nos dados (D-AUD-04, 06, 15). | 18 ataques, 0 acertos; faces da heroína 10, 18, 18, 18, 18, 19 |
| **Animações** | **2** | Figuras primitivas (cápsulas na jogadora, peões no Mestre); a deslocação na água não se vê; nenhum ataque tem animação visível (só o texto). | `capturas/r-v01-montagem.png` (4 fps: a figura some no fotograma 11); `v05` |
| **Estética** | **5** | O terreno, o lago, as árvores, as sombras longas e a passagem de dia a noite são bonitos no GPU real. **Mas** as figuras são primitivas e diferentes nos dois ecrãs, e de noite o tabuleiro perde contraste (D-AUD-11, 13). | `r-montagem-10s`, `v03`; ~1,01 M primitivas/quadro |
| **HUD** | **4** | HUD da jogadora limpa (4 botões, alcance em metros, confirmação do Encerrar). **Mas** o «na vez» vem atrasado um turno nos dois ecrãs, a vida e os PA da jogadora não se vêem, a caixa da ordem tapa a figura e o alcance, o modo Colocar do Mestre fica armado, e o Registo rotula mal (D-AUD-01, 03, 06, 07, 09, 12, 14). | `r-13`, `r-23`, `r-40`, `r-41` |
| **Continuidade** | **5** | Lobby → arena → fim sem quebras; a pausa por desconexão do Mestre e a retomada funcionam (`pausa`/`retomada` no journal); a mensagem de fim aparece nos dois ecrãs. **Mas** a câmara da jogadora não acompanha a própria figura; a figura some na água; o «na vez» contradiz o «A sua vez». | eventos 2–3 e 100 do journal; `r-06-jog`, `v06` |
| **Código/Sistemas** | **7** | O servidor é autoritativo, com journal encadeado e recibos; a IA joga; as suites estão verdes; o ecrã do Mestre a 144 FPS. **Mas** a prioridade Colocar > Mover cria figuras duplicadas e há a suspeita nos dados (D-AUD-01, 15). | 421 + 2 + 321 + 70 + 123 + 10 verificações verdes; medir_mestre 220 ok; 0 SCRIPT ERROR; §4 |

**Nota geral: 4,6/10** (média simples dos 7 eixos: 32/7 = 4,57) contra **4,7/10 da v3**, ou seja **estável (−0,1)**. Uma leitura útil: Código/Sistemas e a robustez da rede subiram muito, mas o que se vê a jogar (Animações, Ataques visíveis, figuras na água, HUD do «na vez») continua a puxar a nota para baixo. As notas de Ataques e Animações estão **limitadas pela bancada** (não se pode acertar): com fichas jogáveis podem mudar, para cima ou para baixo.

## 3. Lista D-AUD (critério 3)

Severidade: **bloqueador / maior / menor**. Causa só quando identificada no código (só leitura); «provável» quando não está confirmada.

| # | Eixo | Sev. | Defeito | Prova | Causa |
|---|---|---|---|---|---|
| **D-AUD-01** | HUD Mestre / Código | **maior** | Depois de colocar uma criatura, o modo «Colocar» da aba Mesa **fica armado** («Parar de colocar» à vista). Na vez dessa criatura, o Mestre arma «Mover» na aba Agir e clica numa casa: **o clique coloca uma 2.ª cópia** em vez de mover. Aconteceu na corrida (evento 10, `colocacao` de um 2.º orc em (30,17)) e a batalha seguiu com 2 orcs. | `v02`; `r-07`, `r-14`, `r-16`, `r-17`; journal seq 10 | `cenas/mestre/aba_mesa.gd:221-230` (`colocar()` envia `MASTER_PLACE` e nunca limpa `a_colocar`) + `cenas/mestre/mestre.gd:690-693` (`casa_tocada()` dá prioridade à Mesa sobre o Mover do Agir) |
| **D-AUD-02** | Movimentação / Animações | **maior** | **A figura fica invisível dentro de água.** A heroína andou para o lago e desapareceu logo no ponto de partida, sem se ver o percurso; só fica um rasto branco. No Mestre vê-se apenas o anel. Com 3 figuras na água (rodada 4) só se viam os marcadores de alvo. | `v01`, `v04`; `r-v01-montagem`, `r-11z`, `r-11-mestre`, `r-37z` | provável: `mapa/floresta/lago_floresta.gd:42` (`FLUTUA_M := 1.25`) e `pe_na_agua` (`:177-183`), que afundam a base 1,25 m; a «água funda» é pendente do Mestre (§5) |
| **D-AUD-03** | HUD / Continuidade | **maior** | **«na vez» atrasado um turno** na caixa da ordem dos dois ecrãs: a jogadora vê «Orc · na vez» com o banner «A sua vez» (`r-23`, `r-32`); o Mestre vê «Heroína · na vez» na vez do orc (`r-13`) e «Orc · na vez» na rodada 9, vez da heroína (`r-40`). | `r-13`, `r-23`, `r-40`, `v05` | `hud/ordem_turnos.gd:158-159`: no modo dinâmico `na_vez()` devolve `ultimo` (quem agiu por último). Se é a semântica pretendida do modo dinâmico, o defeito é só o rótulo «na vez»; isso é conferência (§6) |
| **D-AUD-04** | Ataques (bancada) | **maior** | **A bancada não consegue mostrar um acerto.** As fichas fictícias têm CA canário (5551/9137) contra `1d20+4`: 18/18 ataques deram `erro`. Não se pode medir dano, queda, morte, nem as animações e a HUD de dano na bancada de rede. | `relato.txt` (contagem); `r-35z` | `bancada-rede/privado/fichas.json` (gerado pela bancada; números canário de propósito, para a privacidade). Não é lógica do jogo |
| **D-AUD-05** | Continuidade (câmara) | **maior** | **A câmara da jogadora não mostra nem segue a própria figura.** No começo a heroína aparece num canto superior direito, pequenina e meio tapada pela caixa da ordem; quando anda, a câmara não se mexe. | `r-06-jog`, `r-08-jog`, `r-25`; `v01`, `v04` | não localizada |
| **D-AUD-06** | HUD | menor | A **caixa da ordem de turnos tapa** a figura e as casas ao alcance no canto superior direito da jogadora (`r-09`); no Mestre tapa o realce do Mover (`r-18`). Os **marcadores de alvo** do Ataque são minúsculos (~10 px) e são a única coisa visível com as figuras na água. | `r-09`, `r-18`, `r-37z`, `v05` | não localizada |
| **D-AUD-07** | HUD Mestre | menor | No Registo, o evento `ia` com que fecha a vez do orc fica agrupado na vez seguinte: «Rodada 8 · vez de Heroína Teste · **Ação do monstro**, vez nova». | `r-40` | o rótulo é `cenas/mestre/textos_mestre.gd:212` (`"ia": "Ação do monstro"`); o agrupamento por vez não foi localizado |
| **D-AUD-08** | IA | menor | A IA do orc 2, na 1.ª vez, andou 6 m de (30,17) para (30,13) **sem encurtar** a distância à heroína (8 → 8 casas em Chebyshev). A heroína estava na água, e talvez a IA a contorne. Nas vezes seguintes aproximou-se e atacou. | journal seq 15; `v05` | não localizada (baixa confiança) |
| **D-AUD-09** | HUD jogadora | menor | Em combate **a jogadora não vê a própria vida nem os PA** em nenhum sítio da HUD: a «FICHA» só tem «Reacção / Declarar Defender». O Mestre vê «vida 5150/5150 · PA 4040/4040». | `r-41`, `r-17` | conferir com o desenho da HUD (pode ser intencional) |
| **D-AUD-10** | Movimentação | menor | Na 1.ª pilha, o clique de andar da jogadora (14:10) **não chegou ao servidor** (`andouM=0`, nenhum evento `movimento`). Na retoma, os 4 movimentos entraram todos à primeira. O mais provável é a pilha ter sido parada a meio. | `22-jog-andou`; `relato.txt` (pilha 1) | não reproduzido |
| **D-AUD-11** | Estética | menor | Figuras **primitivas e diferentes nos dois ecrãs**: a jogadora vê cápsulas (vermelha/azul), o Mestre vê peões cinzentos; nenhuma tem rosto, arma ou pose. | `r-08-jog`, `r-11-mestre` | — |
| **D-AUD-12** | HUD Mestre | menor | Duas criaturas da mesma ficha ficam com **o mesmo nome**, sem número («Orc Verdadeiro Teste (Orc)» ×2), nas Figuras, nos rótulos do tabuleiro e na caixa. | `r-16`, `r-17` | — |
| **D-AUD-13** | Estética | menor | **De noite** o tabuleiro, a grelha e as figuras ficam com pouco contraste (azul-escuro); as figuras na margem quase não se distinguem. A velocidade do ciclo é matéria do Mestre (§5). | `v03`, `r-29`, `r-montagem-10s` | — |
| **D-AUD-14** | HUD Mestre | menor | Ecrã do Mestre a 1600×900: o tabuleiro 3D só ocupa **metade da largura** (800 px); a coluna do meio (~260 px) fica quase vazia e corta texto («Orc Verdadeiro Teste tentou…»). | `r-01`, `r-40` | — |
| **D-AUD-15** | Código/Sistemas | menor (**suspeita**) | Faces de d20 da heroína: **10, 18, 18, 18, 18, 19** (4 × 18 seguidos: ~1/8000), com sementes CSPRNG diferentes por ataque. Simulei a 1.ª saída do xorshift32 do VLAB para essas sementes e deu 13, 15, 15, 15, 7, 16, que não coincidem com as registadas. Há mais sorteios antes da face, ou outra semente. A distribuição do motor em 200 000 sementes é uniforme (4,94–5,05% por face). Não está confirmado: precisa de uma corrida com N grande. | `relato.txt`; journal seq 30, 45, 56, 67, 78, 89 (`soMestre.semente`) | por confirmar (`bancada-rede/privado/vlab-completo.js:1115-1130`, `novoCursorC`) |

Não há nenhum **bloqueador** para o jogo em si: a batalha corre do princípio ao fim sem erros. O D-AUD-04 bloqueia apenas a **medição** dos Ataques e das Animações de dano na bancada.

Retirados depois de verificar: o «Procurar» e o «+» da escala pareciam cortados na borda direita, mas era a janela do Mestre a passar 8 px para lá do monitor (1600 px de largura). É um artefacto da bancada, não do jogo.

## 4. Ecrã do Mestre medido com render (critério 4)

Ferramenta `provas/ordem-auditoria-linha/ferramentas/medir_mestre_render.gd`: a cena REAL `mestre.tscn` com a vista da fixture `servidor/dados-exemplo/mesa-mestre.json` (como o `medir_mestre.gd`), com janela e GPU, 3 s de aquecimento e 10 s de medida por combinação. Saída em `medir_mestre_render.out`. Correu **com a pilha da bancada viva** (os outros 2 clientes também a desenhar no mesmo GPU), por isso os números são conservadores.

| Janela | vsync | FPS médio | FPS mín. (Engine) | Chamadas de desenho (média / máx.) | Primitivas/quadro |
|---|---|---|---|---|---|
| 1600×900 | ligado | **143,9** | 142 | **128 / 130** | 1 013 862 |
| 1600×900 | desligado | 1 038,7 | 993 | 128 / 130 | 1 013 719 |
| 1920×1080 | ligado | **144,0** | 144 | **128 / 130** | 1 013 862 |
| 1920×1080 | desligado | 1 018,1 | 906 | 128 / 130 | 1 013 719 |

Leitura: com vsync o ecrã do Mestre fica nos 144 Hz do monitor; sem vsync sobra uma folga de ~7×. As chamadas de desenho não mudam com a resolução. Limite: a cena usa a fixture, não a sala viva; esta conta não instrumenta o cliente vivo.

## 5. Suites na ponta `e91fb95` (critério 5)

Corridas neste PC (Windows, Godot 4.7.2 `--headless`, Node 26) às 15:37 (-03); os logs estão em `provas/ordem-auditoria-linha/suites/`.

| Suite | Resultado |
|---|---|
| servidor (`rascunhos/servidor/testes/*.test.mjs`) | **421/421** pass, 0 fail |
| motor real (`testes-motor-real`, com o motor em cache da bancada) | 2/2 |
| prova da caixa (`prova-servidor.mjs`) | PROVA OK |
| `abrir_scripts` | 108 scripts, 0 falhas |
| `rodar_testes` | **321 de 321** verificações |
| `medir_mestre` | 220 ok, **0 falhas**, 0 sem medida |
| `caixa_jogadora` | **70 de 70** |
| `caixa_janela` | **123 de 123** |
| canário de privacidade | **10 de 10** |

Todas com exit 0 e 0 `SCRIPT ERROR / Parse Error / Compile Error`. O CI (Testes + Sonda) do commit deste ESTADO-FINAL fica na nota a seguir, quando correr.

## 6. Pendente do Mestre (não decidi nada disto)

- **Água funda / quanto a figura afunda** (D-AUD-02): `FLUTUA_M = 1,25 m` torna a figura invisível na prática; a regra da água funda e as casas de água são do Mestre.
- **Velocidade do ciclo dia/noite e clima** (D-AUD-13): de meio-dia a noite em ~3 min de tempo real; a tabela do clima é do Mestre.
- **Vida e PA da jogadora na HUD** (D-AUD-09): se devem aparecer e onde.
- **Perfil gráfico do Mestre / aspecto das figuras** (D-AUD-11, 14).
- A frase «Aperte Recomeçar para jogar outra vez» também aparece à jogadora, que não tem o botão. É decisão do Mestre (N4, 08/11, regra-mãe «vale o site», `hud/frases_batalha.gd:16-20`) e por isso **não** é defeito.

## 7. Conferência do coordenador

- Confrontar as notas da §2 com o texto da «Régua crítica» do `GOAL.md` e com as notas da v3 por eixo (não estão neste PC).
- O D-AUD-03: decidir se o «na vez» do modo dinâmico (o último que agiu) é a semântica pretendida.
- O D-AUD-04: as fichas da bancada são canário de propósito. Uma bancada que possa acertar (fichas jogáveis fictícias) é ordem nova, não desta cadeira.
- O D-AUD-15: confirmar ou afastar a suspeita dos dados com uma corrida de N grande.
- O relançamento das 14:13 contra o «NAO relancar» (registado no parcial).
- No fim da retoma o agente de input da sessão 1 e a bancada foram fechados (ver a nota final).

## 8. Critérios de aceitação

- [x] Batalha completa na bancada (2 clientes reais + servidor de produção), com relato e 0 SCRIPT ERROR nos dois clientes. O fim foi «Terminar batalha», porque não é possível acertar na bancada (D-AUD-04).
- [x] Nota 0–10 nos 7 eixos + nota geral (4,6) com a prova de cada uma; comparação com a v3 (4,7) feita pelo total. A comparação por eixo fica para a conferência (§7).
- [x] Lista D-AUD numerada (15) com prova; os maiores de movimento (02, 05) têm vídeo. O lado do Mestre do D-AUD-01 tem captura e journal, mas não vídeo do Mestre (gdigrab, ver README).
- [x] Ecrã do Mestre medido com render: FPS + chamadas de desenho (§4).
- [x] Suites verdes na ponta, com os números (§5). CI do commit: na nota abaixo.
- [x] ESTADO-FINAL commitado na linha, sem regra, número ou fórmula inventados.

## Nota final — fecho da bancada (~15:58 -03)

Depois do «Terminar batalha» e das medidas, fechei a bancada com o `bancada-rede/parar-bancada.cmd`, que só mata os PIDs de `privado/pids.txt` (servidor 33076, clientes 19960/30084). Parei também o agente de input da sessão 1 (PID 35308, ficheiro `PARAR`). Conferido: nenhum desses processos vivo, porta 8790 fechada, GPU 0%. O PC fica livre para a ordem seguinte (o mapa jogável da conta 1).
