# ESTADO-FINAL PARCIAL — ORDEM-AUDITORIA-LINHA (ponto da retoma)

**Cadeira:** Claude conta 2 (PC) · **Linha:** `fable/integracao-50` · **Escrito:** 23/11/2026 ~15:30 (-03), à entrada da RETOMA (`ORDEM-RETOMA.md`)
**Base:** `repo/` na ponta `e91fb95`. Conferida por `git ls-remote` às 15:23 (-03): `e91fb957c67e3fc49cc3debf20402681a3486c55`. A ponta **não andou**; árvore limpa.

Este ficheiro regista o ponto exacto em que a 1.ª corrida parou (13:49:45 → 14:15:13, limite de 5 h). Até às 14:15 **não se fixou nenhuma nota de eixo**: a 1.ª corrida só produziu capturas, vídeos e os registos do servidor. Não houve `relato.txt`, nem `provas/ordem-auditoria-linha/`, nem nenhum commit.

## 1. Cronologia reconstruída (dos `.out` do agente, dos registos do servidor e dos carimbos dos ficheiros)

| Hora (-03) | O que aconteceu | Prova |
|---|---|---|
| 13:55–13:56 | Bancada de pé (1.ª pilha: Godot 26136 / 33668 + servidor na 8790). Motor real baixado, com SHA-256 `a91c021c…3261`. | `tmp/cmd/…-lancar.out` |
| 14:06–14:08 | Arranque; o Mestre saiu pela engrenagem para o lobby, escreveu o PIN e entrou no ecrã do Mestre; janelas passadas para 960×540. | `00`…`07` |
| 14:07:41 | Servidor: `pausa` (motivo `mestre_desconectado`), por causa da saída pela engrenagem. Às 14:08:55 veio a `retomada`. | registo do servidor (corrida 1), seq 2–3 |
| 14:08–14:09 | Separador Mesa: procurou-se o orc, foi escolhido e a mesa guardada (14:09:20, `lobby`); depois «Começar batalha». | `08`…`14` |
| 14:09:36 | Servidor: `colocacao` da heroína em (38,4) e depois `turno`, rodada 1, vez da heroína. | seq 5–6 |
| 14:10:03 | Servidor: `colocacao` do orc em (26,21). | seq 7; `15`, `16`, `17` |
| 14:10 | Jogadora: Mover, zoom, hover e clique para andar. **O servidor não registou nenhum movimento**: o estado final tem a heroína em (38,4), com `andouM=0` e 4 recibos, todos `APLICADA`. Fica por esclarecer se o clique se perdeu ou se a pilha foi parada antes de ele chegar. **Não é um defeito até ser reproduzido na retoma.** | `18`…`22`; registo seq 7 |
| ~14:10 | **Janela fechou** (cunhado presente). O coordenador parou a 1.ª pilha e escreveu `JANELA-FECHOU-PARAR.txt` (14:11:16: «NAO relancar a bancada»). | `JANELA-FECHOU-PARAR.txt` |
| 14:12 | Comandos `pan` e `est` falharam porque as janelas já não existiam (cliente 0×0). | `tmp/cmd2/…-pan.out`, `…-est.out` |
| 14:13:09 | **A 1.ª corrida relançou a bancada, contra o «NAO relancar» das 14:11.** Esta é a pilha viva de agora: servidor 33076 e Godot 19960 (jogadora) / 30084 (Mestre). Fica aqui registado como facto; a decisão sobre isso é do coordenador. | `tmp/lancar2.log`, `bancada-rede/privado/pids.txt` |
| 14:13–14:15 | O fluxo do Mestre foi refeito na 2.ª pilha (engrenagem → sair → lobby → PIN → ecrã do Mestre); a jogadora ficou a 1280×720 e o Mestre a 1600×900; foi aberto o separador Sala. | `c2-00`…`c2-09` |
| 14:14:11 | Servidor (2.ª pilha): `pausa`, motivo `mestre_desconectado`. **Não houve `retomada`.** | registo do servidor (vivo), seq 2 |
| 14:15:13 | Limite de 5 h; a sessão morreu. | `corrida.log` (66 B, intacto) |

## 2. Estado vivo da pilha (conferido às 15:22–15:25 -03)

- Servidor node **33076**, a ouvir em `127.0.0.1:8790` (dono 33076). Godot **19960** (jogadora, 1280×720 em -1912,31) e **30084** (Mestre, 1600×900 em 8,31), ambos com início às 14:13:10/11. O lançador 6884 já morreu e os filhos continuam.
- Agente de input da sessão 1 (`tmp/s1-agente.ps1 -pasta cmd2`, PowerShell **35308**) **vivo**: é a via para conduzir as janelas (PostMessage) a partir da sessão 0 desta cadeira.
- Estado do jogo na pilha viva: fase **`pausa`**, rodada 0, ordem vazia, heroína **por colocar** (`colocada=false`), orc ainda não adicionado à mesa. Ecrã do Mestre no separador Sala, com «Sala: em pausa» e «Terminar batalha / Recomeçar» a cinzento; a jogadora vê «A mesa está em pausa. O Mestre já volta.» (`c2-09-sala.png`, `c2-08-jog-1280.png`).
- **Consequência para a retoma:** a batalha da 1.ª pilha (rodada 1, as duas figuras colocadas) morreu com essa pilha às ~14:10 e não pode ser continuada. Na pilha viva, «continuar do ponto onde parou» quer dizer: Mestre → «Continuar» (sair da pausa) → Mesa (orc) → Começar → colocar → turnos → ataque → fim. Isto não recomeça nada que já exista na pilha viva: lá a batalha nunca começou.

## 3. Higiene feita à entrada da retoma

- **ffmpeg órfão PID 25652** (gravava `tmp/vid/batalha-jogadora.mp4` desde as 14:14:59). Às 14:15 o segundo `VideoInicio` (o do Mestre) substituiu a referência no agente e o primeiro ficou sem dono; o `batalha-mestre.mp4` nunca chegou a existir. O ffmpeg continuou a gravar o ecrã parado durante 69 min e estava a puxar GPU e CPU. **Foi fechado limpo** com um Ctrl+C na consola dele (`tmp/ctrlc.ps1`, às ~15:27) e o ficheiro ficou válido: 1h09m15s, 1280×720, 180 MB. Só os primeiros ~15 s têm conteúdo de jogo; o resto é ecrã em pausa. **Não foi apagado nem regravado.**
- Não se matou nem reiniciou nenhum processo da pilha (33076/19960/30084).

## 4. Capturas (`tmp/cap/`, 35 ficheiros) e o que cada grupo prova

| Ficheiros | Pilha | O que mostra |
|---|---|---|
| `00-arranque` | 1.ª | os 2 clientes a arrancar (800×450) |
| `01`–`06` | 1.ª | saída do Mestre pela engrenagem → lobby → PIN → ecrã do Mestre (eixo **Continuidade**) |
| `07-ambos-960` | 1.ª | os dois clientes lado a lado a 960×540 |
| `08`–`12` | 1.ª | separador Sala; Mesa → procurar «orc» → escolher → guardar (ecrã do Mestre, **HUD do Mestre**) |
| `13`, `14` | 1.ª | batalha começada |
| `15`–`17` | 1.ª | colocação do orc, lista de figuras (vida 5150/5150 · PA 4040/4040; orc 7777/7777 · PA 313/313) |
| `18`–`22` | 1.ª | jogadora: Mover (alcance «até 9,0 m», casas azuis), zoom, hover, clique para andar (eixos **Movimentação** e **HUD**) |
| `c2-00`…`c2-07` | 2.ª (viva) | arranque e fluxo do Mestre refeito |
| `c2-08-jog-1280`, `c2-08-mestre-1600` | 2.ª (viva) | as duas janelas redimensionadas para medir |
| `c2-09-sala` | 2.ª (viva) | **último ponto:** Sala em pausa |

## 5. Vídeos (`tmp/vid/`, 3 ficheiros)

| Ficheiro | Duração | Pilha | O que prova |
|---|---|---|---|
| `corrida1-lobby-comecar-colocar.mp4` | 4:16 (1920×540) | 1.ª | Mesa → orc → começar → colocar → Mover/andar da jogadora (até à paragem às ~14:10) |
| `corrida2-arranque-lobby-mestre.mp4` | 1:18 (1920×540) | 2.ª | arranque e fluxo engrenagem → lobby → PIN → ecrã do Mestre |
| `batalha-jogadora.mp4` | 1:09:15 (1280×720) | 2.ª | só os ~15 s iniciais têm conteúdo (a jogadora em pausa); o resto é o órfão a gravar (§3) |

## 6. O que foi medido e o que falta

- **Medido (sem número de nota):** fluxo de entrada do Mestre (funciona, mas com pausa/retomada pelo meio); Mesa e Começar funcionam; colocação servida pelo servidor; a HUD da jogadora mostra o alcance em metros e os botões Ataque/Mover/Consumível/Encerrar.
- **Nenhum eixo tem nota provisória.** As 7 notas ficam todas para a retoma.
- **Falta:** batalha completa até ao fim (movimento confirmado no servidor, ataques, turno do orc, desfecho); vídeos de movimento, ataque e câmara; FPS e chamadas de desenho do ecrã do Mestre; `0 SCRIPT ERROR` no arranque dos 2 clientes (ler os logs `user://`); suites (servidor, `rodar_testes`, `caixa_jogadora`, `caixa_janela`, `medir_mestre`, canário de privacidade); `provas/ordem-auditoria-linha/` com README e relato; lista D-AUD; ESTADO-FINAL; CI.

## 7. Estado de arranque da retoma (15:22 -03)

PC: `idle` pelo sensor do vigia 4.371 s (15:14), sem jogo nem stream à frente; GPU 40% (era a pilha órfã mais o ffmpeg órfão); disco C: 21,3 GB livres por `Get-PSDrive` (acima do piso de 15 GB). Conta 1 sem ordem em simultâneo.
