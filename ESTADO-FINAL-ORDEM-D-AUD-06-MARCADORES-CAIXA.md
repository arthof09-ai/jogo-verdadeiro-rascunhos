# ESTADO-FINAL — ORDEM-D-AUD-06-MARCADORES-CAIXA (retoma no PC do Pierre): marcadores de alvo e medida da caixa

**Estado: FEITA, COM COMMITS SÓ LOCAIS.** Fiz três coisas:

- reproduzi o lado do Mestre (C1-3) e medi a caixa nos dois ecrãs;
- construí um marcador de alvo **candidato**, à altura da figura e visível dentro de água, nos dois lados;
- acrescentei testes, e as suites locais estão verdes.

O aspecto do marcador e a posição da caixa ficam para o Mestre (secção C). **Não fiz push:** nesta máquina não há
credencial do GitHub. O coordenador recolhe a sede e publica.

- **Executor:** Claude (opus), conta 2, PC do Pierre. **Data:** 25/11/2026, ~21:20–23:00 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo, commits locais. A `main` não foi tocada.
- **Ponta de partida:** `b884b75a09de8d312afab4b9ad770189e9465447` (`b884b75`), a que o coordenador mediu. Como a ordem
  manda, recomecei daí: os `4757095`/`0167b4f` da corrida do PC do Daniel nunca subiram e não os usei.
- **Não toquei** no servidor, nos workflows, nos dados, na `main`, no perfil gráfico, na largura do tabuleiro
  (D-AUD-14), na C-6 nem no «na vez» da caixa (D-AUD-03). Do cliente da jogadora, só mudou o marcador de alvo.

## Commits (locais)

| commit | o quê |
|---|---|
| `cac02a1` | o marcador de alvo: `cenas/comum/marcador_alvo.gd` (novo), `arena.gd`, `arena_mestre.gd`, `mestre.gd`, `aba_agir.gd`, mais os testes em `hud_acoes.gd` e `pecas_mestre.gd` |
| `62e7585` | as listas da retoma sincronizadas (`retoma-i0004/actualizar-listas.py`: `depois.txt` e `MANIFESTO-SHA256.txt`; o `antes.txt` não mudou) |
| o commit deste ficheiro | este ESTADO-FINAL e `provas/ordem-d-aud-06-marcadores-caixa/` (README, ferramentas, medidas, capturas, registos). Não muda nada em `rascunhos/`, por isso não volta a correr o guião das listas |

## A. A reprodução do lado do Mestre (C1-3) e a medida da caixa nos dois ecrãs

Usei a bancada de rede verdadeira, com o servidor de produção e os dois clientes Godot 4.7.2 verdadeiros: **Mestre a
1600×900**, **jogadora a 1280×720**. O condutor prime os mesmos botões que o Mestre e a jogadora primiriam, e mede em
píxeis da janela. O método está em `provas/.../README.md`.

**C1-3 reproduzido (cena B: o orc em (20,12), a vez dele, aba Agir → «Mover»):** a caixa da ordem fica por cima do
realce do Mover no ecrã do Mestre (`B-m03-mestre-mover-*.jpg`; medido em `B-m03a`).

| ecrã | caixa (x, y, largura × altura, px) | realce do Mover | tapado pela caixa |
|---|---|---|---|
| **Mestre** 1600×900 (tabuleiro 0,0, 864×900) | **18, 67, 468 × 67** (compacta) | 40 casas, todas no tabuleiro | **19 de 40 casas**: toda a metade norte do alcance, (16..23, 8..13). Também **a cabeça do orc**; o pé dele fica 10 px abaixo do bordo da caixa |
| **Mestre**, com os 2 retratos na caixa (cena A) | **18, 67, 468 × 179** | — | a zona tapada cresce de 70 para **138 casas** da grelha (x 13–26, y 6–17) |
| **Jogadora** 1280×720 (cenas A e B) | **986, 16, 278 × 71** | 70 casas, todas no ecrã | **0 casas, figura não tapada**: a câmara segue-a (D-AUD-05) e a figura fica no centro (640,360); a caixa não tapa nenhuma casa da grelha |

Na câmara do jogo de arranque, a caixa do Mestre tapa as casas x 13–26 e y 6–14: 70 casas com a caixa compacta,
138 com os retratos. O C1-3 acontece quando a criatura da vez está aí. A câmara do Mestre não segue a vez (o
D-AUD-05 é só da jogadora). Na cena A o orc estava a nordeste, no lago, e a caixa não tapou nada (0 de 39).

As medidas são as mesmas antes e depois desta ordem: a caixa não mudou de sítio.

## B. O marcador de alvo (candidato)

`rascunhos/cliente/cenas/comum/marcador_alvo.gd` é um nó 3D posto **na figura** (segue o nó dela, também na animação
de andar). Tem duas partes:

- um **anel** horizontal à volta do corpo, à cintura (½ da altura da figura medida pelas malhas dela): raio 0,72 m, tubo
  0,07 m, contorno escuro;
- uma **seta** (haste e ponta) a apontar para baixo, 0,7 m acima da cabeça. **No lago, a seta sai sempre 0,3 m acima
  da superfície da água**, qualquer que seja a fundura.

O material é **sem luz e sem teste de profundidade**: a água, o relevo, a relva e o corpo não o tapam. A cor é o
vermelho-alvo da mesa, opaco (`ff4d40` a 95 %). Distingue-se do Mover pela **forma** (anel e seta no ar, contra o
quadrado plano no chão) e pela **cor** (vermelho, contra o azul `4dbfff` da jogadora e o `cab577` do Mestre). Os
números estão todos no topo do ficheiro, para se trocarem sem mexer nas arenas.

- **Jogadora** (`arena.gd`): no Ataque e no Consumível, os alvos deixam de ir para a malha plana `Destaques`, que fica
  só para as casas do Mover. Cada alvo leva o marcador (`mostrar_alvos`).
- **Mestre** (`arena_mestre.gd` `marcar_alvos`, `mestre.gd`, `aba_agir.gd`): até aqui o Mestre **não tinha marcador
  nenhum**, só o botão «Atacar X (arma)». Agora a aba Agir marca na arena os `alvoId` dos ataques que o servidor manda
  à criatura da vez, com o mesmo marcador. Tira-os quando a vez muda ou quando não há opções. Os alvos vêm sempre do
  servidor; o cliente não decide nada.

**A prova viva (cena A: o orc em (38,14), a casa mais funda do lago, com 2,52 m de água):**

| | alvo | água | antes | depois |
|---|---|---|---|---|
| jogadora (`A-j04`, `A-j04z`) | Orc 1 | **2,52 m** | quadrado plano no fundo do lago, 45×44 px, **baço**: 0 píxeis de vermelho vivo, vermelhidão máx. 0,31, com a forma das casas do Mover | anel e seta, 59×69 px, **847 píxeis de vermelho vivo**, vermelhidão 0,70 |
| Mestre (`A-m04`, `A-m04z`) | Heroína Teste | 2,47 m (o corpo não se vê: só o anel da ordem no leito) | **nenhum marcador** | anel e seta, 52×65 px, **257 píxeis de vermelho vivo** |

Uma nota honesta sobre o «antes» da jogadora: com a câmara a seguir a figura (D-AUD-05, já na ponta), o quadrado
antigo a 2,52 m **vê-se**, mas tingido pela água e com a forma das casas alcançáveis. Já não é o fragmento invisível
da INVESTIGA (`l32z`), em que a câmara estava a ~30 m.

**Os testes no CI** (as suites que o `testes.yml` já corre; não mexi nos workflows):

- `hud_acoes.gd`, 50 → **70**. A arena verdadeira, a grelha 50×50 e o alvo na casa mais funda do lago, que o teste
  procura sozinho: (38,14), com 2,52 m. O teste confere:
  - no Mover, a malha plana e nenhum marcador; no Ataque, um marcador por alvo e a malha plana vazia;
  - o marcador fora da Grelha; o anel à altura do corpo e a seta acima da cabeça;
  - sem teste de profundidade e sem luz; a cor diferente da do Mover;
  - **a seta acima da superfície com o alvo a 2,52 m**; o alvo que anda leva o marcador; fora do Ataque não há
    marcador.

  A verificação da seta sobre a água **falhou** na primeira versão (−0,11 m: a cabeça do orc a 2,52 m fica debaixo de
  água). Daí vem a regra dos 0,3 m acima da superfície.
- `pecas_mestre.gd`, 329 → **332**. Com a vista real da fixture do servidor: um marcador por alvo dos ataques da
  criatura da vez; na figura, à altura dela e sem teste de profundidade; a aba Agir marcou os alvos do servidor.

## C. Para o olho do Mestre (não decidi)

- **C-2 — o aspecto do marcador.** O candidato é anel e seta, vermelho-alvo opaco, sem teste de profundidade. Vê-o
  em `A-j04-jog-ataque-alvos-depois.jpg` e `A-m04-mestre-alvos-depois.jpg` (e nos recortes ×3). As variantes
  possíveis são só números em `marcador_alvo.gd`: só o anel, só a seta, outra cor, pulsar, tamanho mínimo no ecrã.
- **A posição da caixa da ordem (Lote 1), sobretudo no Mestre.** Na câmara de arranque, a caixa tapa a zona x 13–26,
  y 6–14 do tabuleiro (até y 17 com os retratos). Na cena B tapou 19 das 40 casas do Mover e a cabeça do orc. As
  opções que a INVESTIGA já deixou continuam abertas:
  - a caixa recolher ou ficar semitransparente enquanto o Mover/Ataque está armado;
  - a câmara do Mestre reservar essa área;
  - a caixa mudar de canto.

  Mexer na posição obriga a refazer as medições das ordens da caixa (`caixa_jogadora`, `caixa_janela`, `medir_mestre`).
  Do lado da jogadora, a ponta não tem o problema (0 casas tapadas).

## Suites locais (sobre o `cac02a1`)

| suite | resultado |
|---|---|
| Godot 4.7.2, `--headless` | `abrir_scripts` 113 scripts / 0 falhas · `rodar_testes` 333/333 · `abrir_clareira` 22/22 · `medir_painel_config` 0 falhas · `abrir_mestre` 67/67 · `pecas_mestre` **332/332** · `medir_mestre` 0 falhas · `hud_acoes` **70/70** · `caixa_jogadora` 70/70 · `caixa_janela` 123/123 · `canario_privacidade` 10/10 · `camera_segue` 17/17 — 0 SCRIPT ERROR |
| servidor, `node --test servidor/testes/*.test.mjs` | **446/446**. Ressalva: no checkout deste PC (`core.autocrlf=true`) o `fixture-mestre` falha (445/446), porque compara byte a byte o `mesa-mestre.json` em CRLF com o texto em LF que o servidor gera. Com o ficheiro em LF dá 446/446. Repus o ficheiro e ele não aparece no `git status`. É do ambiente, não desta ordem |
| `validador-glb` | 33 testes, 31 passam, 0 falhas |
| Sonda de caminhos do PC (`.github/sonda/caminhos_pc.py`) | Corrida aqui, no Windows, **não serve de veredicto**: dá 347 «NOVO», todos em ficheiros antigos que a base já lista, também numa cópia em LF. Será a forma como a Sonda lê os ficheiros no Windows; o CI corre-a em Linux. **Nenhum ficheiro desta ordem aparece**, e um `grep` directo das três formas nos ficheiros novos dá 0. O veredicto é o do CI, depois da publicação |

Antes das alterações, as mesmas suites Godot deram tudo verde: `hud_acoes` 50/50 e `pecas_mestre` 329/329.

## Notas

- A nota da bancada diz que a heroína fica «em terra a norte do lago», mas no relevo de hoje **a casa (38,4) tem
  0,9 m de água**. O lago cresceu na ordem LAGO-MAIOR. Fica registado para quem medir com a bancada.
- No PC do Pierre o agente corre na sessão 0 (serviço). As janelas do Godot não aparecem no ecrã, mas o ecrã virtual
  de 1024×768 corta o `--resolution`. O condutor repõe o tamanho da bancada (README das provas). Ao fim de cada
  corrida, o servidor, o porteiro e os clientes foram parados pelo lançador.
- O trabalho fora do repositório ficou na sede, em `trabalho/`, e não sobe: a árvore «antes» extraída, as capturas em
  PNG completas, o `privado/` da bancada e o journal.
