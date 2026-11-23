# Provas — ORDEM-AUDITORIA-LINHA (23/11/2026)

Bancada de rede (`bancada-rede/`): o servidor de produção (`servidor-ws.js` com o motor real VLAB, SHA-256 `a91c021c…3261`) e 2 clientes Godot 4.7.2 verdadeiros (Jogadora «Heroína Teste» + Mestre), num RTX 4060 (OpenGL 3.3 Compatibility, driver 610.88). Nomes: só os fictícios das fichas de teste.

Houve **duas pilhas**. A 1.ª correu das 13:55 às 14:10 e foi parada pelo coordenador quando a janela fechou. A 2.ª arrancou às 14:13 e foi nela que a batalha completa correu, na retoma das 15:25–15:36 (-03). Os pormenores estão em `ESTADO-FINAL-ORDEM-AUDITORIA-LINHA-PARCIAL.md`.

## Vídeos (`videos/`): tudo o que se move

O vídeo da retoma é da janela da jogadora, 1280×720 a 30 fps. Começou às 15:25:55 (-03) = 18:25:55Z, por isso um evento do journal às 18:MM:SSZ aparece no vídeo em t = (MM−25)×60 + SS − 55 s.

| Ficheiro | De | O que prova | D-AUD |
|---|---|---|---|
| `v00-jog-batalha-completa-8x.mp4` | retoma 0–605 s, 8× | a batalha inteira do lado da jogadora: pausa → começar → 9 rodadas → «Fim da batalha» | — |
| `v01-jog-anda-para-a-agua-e-some.mp4` | 80–100 s | a heroína entra no lago e **desaparece** logo à partida; só fica um rasto branco (ver `capturas/r-v01-montagem.png`) | 02 |
| `v02-jog-segundo-orc-aparece.mp4` | 130–150 s | o clique de Mover do Mestre faz aparecer **um 2.º orc** | 01 |
| `v03-jog-dia-para-noite-acelerado-4x.mp4` | 0–200 s, 4× | de meio-dia a noite em ~3 min de tempo real; de noite fica pouco legível | 13 |
| `v04-jog-rodada2-andar-na-agua.mp4` | 218–256 s | 2.º movimento na água: a figura continua invisível e a câmara não a segue | 02, 05 |
| `v05-jog-ia-orcs-aproximam-e-atacam.mp4` | 280–340 s | a IA dos dois orcs aproxima-se e ataca; ataque da heroína com «Errou. Total 14.»; marcadores de alvo minúsculos | 04, 06 |
| `v06-jog-fim-da-batalha.mp4` | 585–605 s | «Fim da batalha … Aperte Recomeçar», sem botão Recomeçar na jogadora | 08 |
| `c1-ambos-lobby-comecar-colocar-2x.mp4` | 1.ª pilha, 2× | Mesa → orc → Começar → colocar → Mover (as duas janelas) | — |
| `c2-ambos-arranque-lobby-mestre.mp4` | 2.ª pilha | arranque e entrada do Mestre (engrenagem → lobby → PIN) | — |
| `c2-jog-mesa-em-pausa-20s.mp4` | 2.ª pilha, 14:15 | a jogadora com «A mesa está em pausa. O Mestre já volta.» | — |

**Não há vídeo do ecrã do Mestre.** A janela do Mestre (1600×900 em x=8) passava 8 px para lá do monitor principal (1600×1024), e o `gdigrab` recusou a área («Capture area … extends outside»), tanto às 14:15 como às 15:25. O lado do Mestre fica provado pelas capturas abaixo e pelo journal do servidor.

## Capturas (`capturas/`)

`07`, `13`, `22` são da 1.ª pilha; `c2-*` são da 2.ª pilha antes da paragem das 14:15; `r-*` são da retoma (a numeração segue a corrida). As mais citadas são:
`r-09-jog-mover` (alcance a azul debaixo da caixa da ordem), `r-11z-jog-lago-zoom` (heroína invisível no lago), `r-11-mestre-apos-andar` (só o anel da heroína no Mestre; orc em peão cinzento), `r-13-mestre-vez-orc` (o Mestre marca «Heroína · na vez» na vez do orc), `r-16-mestre-mesa-2orcs` / `r-17-mestre-figuras` (dois orcs com o mesmo nome; «Parar de colocar» ainda armado), `r-23-jog-r2-mover` (a jogadora vê «Orc · na vez» quando é a vez dela), `r-35z` («Errou. Total 14.»), `r-37z` (as 3 figuras submersas, só os marcadores de alvo), `r-40-mestre-registo` (vez da heroína rotulada «Ação do monstro»), `r-41-jog-ficha` (a ficha sem vida nem PA), `r-43-jog-fim` / `r-43-mestre-fim` (fim), `r-montagem-10s` (um fotograma a cada 10 s da retoma).

## Outros ficheiros

- `relato.txt`: o journal das duas pilhas (eventos menos os `ia`, ids trocados por `ficha#n`) e a contagem dos ataques.
- `medir_mestre_render.out`: a saída da `ferramentas/medir_mestre_render.gd` (ecrã do Mestre com render, ponto 4 da ordem).
- `suites/*.log`: as suites existentes corridas na ponta (`servidor`, `motor-real`, `prova-caixa`, `abrir_scripts`, `rodar_testes`, `medir_mestre`, `caixa_jogadora`, `caixa_janela`, `canario_privacidade`).
- `ferramentas/medir_mestre_render.gd`: a ferramenta de medição, que **só mede** (não toca no jogo).
