# ESTADO FINAL — Ordem 41 (expansão do clima: nevasca e chuva que alaga)

Ramo `fable/clima-41-expansao` (nasce da ponta da Ordem 40, `cd94361`). Fecho escrito a 2026-11-14 pela
SUCESSÃO 2 da conta 1, depois de duas sessões mortas: a primeira às 07:30 (limite de 5 h, sem nunca ter
corrido o código) e a segunda às 12:16 (limite semanal do modelo Fable, depois de commitar o módulo).
Esta sessão não criou nada visual: fechou, provou e escreveu. Nenhum ficheiro deste ramo aprova nada: o
veredicto é do coordenador e do olho do Mestre, sobre os vídeos.

## O que a expansão entregou, commit a commit

Tudo no mesmo módulo `rascunhos/cliente/arte/clima/`. Os climas fracos ficam como eram. Continua a ser só
apresentação (o teste «o código do clima não toca no Estado nem na Rede» passa).

| Commit | O quê |
| --- | --- |
| `dada019` | `clima.gd` + `clima_terreno.gdshaderinc`: o estado do clima forte. **Nevasca** (= neve forte): rajadas legíveis (calma ×0,65 … pico ×2,9, guinada até 26°), `aglomerado` (cantos, bordas, base e sotavento dos obstáculos; o centro fica varrido), `gelo` com a exposição, véu ao longe. **Chuva que alaga** (= chuva forte): com o chão encharcado (≥ 0,7) a `agua` junta-se nas bacias (`definir_bacias()`, até 8; sem isso, 5 sorteadas), `lama` à volta, drenagem em 3 fases (escoa → lama baça → lama seca), pés na água. API nova: `definir_forte`, `definir_bacias`, `bacias`, `abrigos`, `registar_obstaculo`, `nevasca()`, `alaga()`, `rajada_da_nevasca`, `fundura_em`, `abrigo_em`, `neve_em`, `medir_alagamento`. Grupo novo `clima_obstaculo`. |
| `0752eec` | `clima_chao.gdshader`: a camada do chão — bolsas de água, lama, montes de neve, gelo, neve rasteira (anda com o vento) e véu. |
| `0e78d3c` | `clima_figura.gdshader`: figuras e obstáculos — neve a sotavento, gelo no contorno e do lado do vento, pés na água. |
| `940ae30` | `neve_flocos.gdshader` e `chuva_salpicos.gdshader`: o floco com rasto e o véu da nevasca; o salpico de água (coroa) dentro das bolsas. |

Desta sucessão (fecho):

| Commit | O quê |
| --- | --- |
| `06772d7` + o commit da correção | `testes/pecas_mestre.gd`: o teste da Ordem 40 «desligado e seco… o módulo dorme» **falhava neste PC** (233 de 234) desde o `dada019`. Com a Ordem 41, o aglomerado e o gelo derretem devagar de propósito e o vento da nevasca acalma em `segundos_levantar`. Por isso, só `definir_acumulacao(0, 0)` já não chega para o módulo dormir. No CI passava, porque o resultado dependia do passo de tempo da máquina. Agora o teste põe à mão um resíduo de neve aglomerada (`definir_forte`) e verifica que, com ele, o módulo fica acordado. Depois zera o estado forte e encurta `segundos_levantar`, como já fazia com a transição. Fica determinístico: **235 de 235**. A primeira versão (`06772d7`) dependia do passo de tempo e falhou no CI (run 43614399996); corrigi-a no commit seguinte. |
| `15452c2` | `testes/video_clima.gd`: a bancada da expansão (ver a decisão 1). |
| `21137b8` | Listas da retoma e MANIFESTO refeitos (`actualizar-listas.py`). **O `retoma-pc` da ponta `940ae30` estava vermelho** (run 43608837602: «o clone não bate com depois.txt») porque ninguém tinha corrido isto depois dos commits do módulo. |
| `5cd8bd1` | Os 3 vídeos. |
| `6a6b15a` | Capturas, folhas e medição. |
| este | `ESTADO-FINAL-ORDEM-41.md`. |

## As decisões do fecho

1. **O diff de `video_clima.gd` — fica, e foi completado.** Era o guião das provas (cabeçalho com os 5 modos,
   variáveis, despacho e o desvio da etiqueta), mas chamava 6 funções que não existiam e por isso o modo não
   corria. As funções estavam escritas fora do repo, em
   `C:\Users\txcga\fable-clima-expansao\ferramentas\bancada41.gd.txt` (12:16, o minuto em que a sessão
   anterior morreu), e eram o par exato do cabeçalho: 57 s de nevasca, 112 s de alaga. Juntei-as **tal como
   estavam**, sem as reescrever. (Antes de dar com elas, escrevi uma versão minha; deitei-a fora e fiquei com a
   da sessão que desenhou o módulo, para não recomeçar trabalho.) Os 37 scripts abrem e os 5 modos correm com
   render, 0 falhas.
2. **Os `.uid` — não se commitam.** O repositório não rastreia nenhum `.uid`: 0 em `main`, 0 em
   `fable/clima-40` e 0 neste ramo. Também não há regra no `.gitignore`. Segui a convenção: os 50 `.uid` que o
   Godot gerou ficam por rastrear, e não acrescentei regra ao `.gitignore`, porque mudar a convenção é do
   coordenador. Nota: desde o Godot 4.4 a recomendação é commitá-los.

## As provas

Tudo em `provas/ordem-41-clima/`. Render: RTX 4060, Godot 4.7.2, **renderer Compatibility (OpenGL 3.3)**.
Os vídeos foram gravados quadro a quadro (`--write-movie`, 30 fps certos), com a etiqueta no ecrã (clima,
intensidade, perfil, contagens de partículas e do véu, vento do frame com a seta laranja, rajada, e o estado:
neve pousada, aglomerado, gelo, ou molhado, água com m² e fundura, lama com m² e brilho) e a frase do guião.
Muro, pedra, tronco, as marcas CANTO, OBSTÁCULO e P1–P4, as bacias de bancada e o lobo a andar dentro da
bolsa são **demonstração da bancada**, não o jogo.

### Vídeos (`videos/`, MP4 H.264, 1280×720, 30 fps, perfil Alto)

| Vídeo | Duração | Tamanho | O que mostra |
| --- | --- | --- | --- |
| `nevasca.mp4` | 57,2 s | 32,5 MB (32 461 812 B) | antes → liga → rajadas → de perto: obstáculo, canto, figura → o mesmo plano largo, aglomerado → Panorama. No fim: 9000 flocos + 260 do véu, neve 100 %, aglomerado 100 %, gelo 79 %. |
| `alaga.mp4` | 113,2 s | 25,0 MB (24 965 205 B) | chão seco → encharca → a bolsa P1 nasce e cresce → as bolsas crescem → coroa e lobo a andar (anel nos pés) → formadas → Panorama → parou: escoa → lama → lama baça → seca → seco. No fim: água, lama e molhado a 0. |
| `fracos.mp4` | 35,2 s | 7,4 MB (7 438 390 B) | a base não regrediu: chuva fraca (também em cima de P1, onde não se junta água) e neve fraca (sem monte, sem véu). A bancada confere e grava `sem_estado_forte: true`. |

Os AVI originais (1,1 GB) e os quadros de cada vídeo ficam fora do repo, em
`C:\Users\txcga\fable-clima-expansao\prova41\`, com os logs de cada corrida (`log-*.txt`).

### Capturas em 3 tempos (`capturas/`, 1920×1080, 17 PNG, 18 MB)

- **Nevasca**, sempre no mesmo plano: `nevasca-tempo-0-antes` · `-1-inicio` (5 s) · `-2-meio` (22 s:
  neve 49 %, aglomerado 56 %, gelo 31 %) · `-3-aglomerado` (52 s). De perto, com tudo aglomerado:
  `nevasca-perto-obstaculo`, `-perto-canto`, `-perto-figura`, e `nevasca-panorama`.
- **Alagamento**, sempre no mesmo plano: `alaga-tempo-1-seco` · `-1b-a-crescer` (18 s) · `-2-bolsa` (47 s:
  bolsas 76,3 m², fundura 8,6 cm, lama 87,0 m²) · `-3-lama` (a água escoou, a lama fica). De perto:
  `alaga-perto-bolsa` (o lobo a andar, anel nos pés), `-perto-lama` (com brilho), `-perto-lama-baca`.
  Também `alaga-panorama` e `alaga-bacias-sorteadas`: as 5 bacias que o módulo sorteia quando ninguém lhe dá
  bacias, que é o que as arenas de hoje mostram.
- `folhas/folha-{nevasca,alaga,fracos}.png`: 6 quadros de cada vídeo numa folha.

### Custo por perfil (`medicao41.md` / `.json`; 1920×1080, sem vsync, 2 s por caso, já em regime)

Partículas = gotas + salpicos, ou flocos + véu. O que se paga a mais em relação a «sem clima» na câmara Fixa:

| Perfil | Nevasca formada | Chuva alagada | Sem clima |
| --- | --- | --- | --- |
| Baixo | 3000 flocos, 0 véu · +12 draw calls · 0,55 ms (+0,08) | 2800 gotas, 0 salpicos · +12 · 0,57 ms (+0,10) | 56 DC · 0,47 ms |
| Médio | 6000 + 140 véu · +13 · 0,59 ms (+0,10) | 5000 + 350 · +13 · 0,60 ms (+0,11) | 56 DC · 0,49 ms |
| Alto | 9000 + 260 véu · +13 · 0,57 ms (+0,11) | 8000 + 600 · +13 · 0,58 ms (+0,12) | 56 DC · 0,46 ms |

O clima forte custa o mesmo número de draw calls que o fraco. A exceção é a nevasca no Médio e no Alto,
com mais 1 (o véu); a chuva alagada tem os mesmos 69 da chuva fraca. O custo cresce com as primitivas: no Alto vai de 12 010 (neve fraca) a 24 530 (nevasca). A
camada do chão e a das figuras não acrescentam draw calls: são overlays. A tabela completa, também com a
câmara Panorama, está em `medicao41.md`.

### O crescimento medido (a conta do módulo, passos de 1/30 s, perfil Alto, 4 bacias P1–P4)

- **Alagamento** (chuva forte desde o seco; parou aos 50 s): primeira água aos 6,4 s; a bolsa lê-se
  (≥ 1 m²) aos 7,2 s; 5 m² aos 9,6 s; cheias aos 42,4 s, com 76,4 m² (8,5 % do campo), 8,6 cm de fundura e
  86,8 m² de lama. Parou: sem água aos 74,0 s (24 s depois); lama baça aos 83,5 s; lama seca aos 107,5 s;
  chão seco aos 90,0 s.
- **Nevasca**: aglomerado cheio aos 37,7 s, gelo cheio aos 70,0 s. Neve no ponto aos 45 s (1 = manto
  cheio, > 1 = monte): canto 2,27 · borda 1,34 · sotavento do muro 1,08 · barlavento do muro 0,45 ·
  centro aberto 0,33. O sotavento oscila entre 0,79 e 1,09 com a guinada do vento.

### Testes (sem janela)

`abrir_scripts.gd`: 37 scripts, 0 falhas · `rodar_testes.gd`: 167 de 167 · `pecas_mestre.gd`: 235 de 235.

## Os pontos abertos, para o coordenador

Não corrigi nenhum, porque corrigi-los pede criação visual nova ou é decisão de outros. É o que vi nos
quadros, nas folhas e nas capturas.

1. **O véu da nevasca não se vê.** A etiqueta conta 260 cartões no Alto, mas em nenhum quadro, nem na Fixa
   nem no Panorama, o fundo do campo se fecha: o longe fica nítido. A câmara de cima (Panorama a 78°) pode
   nunca dar «longe» suficiente para o véu aparecer.
2. **Com a nevasca formada, o centro varrido lê-se como verde.** Com neve pousada a 100 % e aglomerado a
   100 %, o campo aberto fica quase todo verde, com a neve nas bordas, nos cantos e nos obstáculos (neve no
   ponto 0,33 no centro aberto). É o desenho pedido («o centro fica varrido»), mas em Panorama a nevasca no
   máximo pode parecer menos nevada do que a neve fraca. Pede o olho do Mestre.
3. **A cauda a sotavento do muro é curta no plano de perto.** A neve junta-se à volta da base, quase como
   uma auréola. O tronco e a pedra mostram melhor o monte. Nos números, o sotavento do muro (1,08) fica acima
   do barlavento (0,45).
4. **A «figura de perto» da bancada não chega para julgar** neve nas costas e gelo no contorno: o lobo fica
   pequeno no quadro (zoom 3,0, o máximo da câmara da mesa). Precisa de outro plano, ou da câmara livre.
5. **As bacias sorteadas não evitam obstáculos nem casas destacadas.** Em `alaga-bacias-sorteadas.png`
   uma bolsa fica debaixo da pedra e das casas destacadas (os destaques continuam a ler-se). Com
   `definir_bacias()`, que é como o mapa da cadeia entra, isto não acontece.
6. **Defeitos da bancada (não do clima):**
   - no `alaga.mp4` a 1280 px, a 2.ª linha da etiqueta corta no fim e perde o «brilho da lama»; o valor
     está completo nas capturas a 1920 px e no `medicao41.md`;
   - a marca CANTO fica por baixo dos nomes das figuras;
   - as marcas P1–P4 ficam pequenas no vídeo;
   - nos planos de perto, a seta laranja tapa parte do primeiro plano.
7. **Faltam testes sem janela para o estado forte.** Os 167 do `rodar_testes.gd` são os da Ordem 40; da
   Ordem 41 só há a verificação nova do `pecas_mestre.gd`. O `README.md` do módulo também não fala da Ordem 41
   (a tabela de custos não tem o véu; faltam `definir_bacias`, `clima_obstaculo` e `definir_forte`).
8. Não medido no telemóvel nem no export web (só PC, renderer Compatibility). Lá, o que conta é o
   enchimento de píxeis das camadas transparentes: véu, coroas, rastos.
9. Os 50 `.uid` por rastrear: a convenção do repo é não os rastrear (decisão 2); mudá-la é do coordenador.

## ESTADO FINAL — Passagem

- **O que mudou** (sobre `940ae30`): `06772d7`, `15452c2`, `21137b8`, `5cd8bd1`, `6a6b15a`, `0f9bf83`,
  `ed13ac7`, `6d0f50b` e este commit (só este ficheiro).
- **Onde parou**: a ordem está fechada do lado do executor. Tudo foi empurrado sem force para
  `origin/fable/clima-41-expansao`. **CI verde na ponta `6d0f50b`**: Testes dos rascunhos (run 43614614178,
  todos os jobs, incluindo `retoma-pc` e `cliente`) e Sonda de privacidade (run 43614614148). A `main` e os
  outros ramos não foram tocados.
- **Próximo passo**: conferência do coordenador sobre os 3 vídeos e os pontos abertos 1 a 5, e depois o
  olho do Mestre.
- **Fora do repo** (`C:\Users\txcga\fable-clima-expansao\`): `prova41/` (AVIs, quadros, logs),
  `ferramentas/bancada41.gd.txt` (o rascunho da sessão anterior, agora dentro do `video_clima.gd`).
