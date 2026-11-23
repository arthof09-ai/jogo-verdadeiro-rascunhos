# ESTADO-FINAL — Ordem CAIXA-EXPANDE-INTERACAO (ID ORDEM-CAIXA-EXPANDE-INTERACAO-2026-11-22)

**Dono:** Claude conta 1, no PC. **Linha:** `fable/integracao-50`, trabalho directo, sem ramo e sem fusão.
**Partida:** `0bebd76` (a F12 da CAIXA-EXPANDE e o complemento da ferramenta). Fiz `fetch` antes do commit 1 e outra
vez antes do push: a linha não tinha andado.

**Commits:**
1. `3fb546b` — o código (D1, D3), as suites, a ferramenta da prova (passo 8 pela roda, passo 11 novo), o lançador e
   as provas.
2. `4a33152` — este ESTADO-FINAL, `mutacao/` e as listas da retoma sincronizadas.
3. o commit que acrescenta o resultado do CI da ponta `4a33152` ao §5 (só documento).

Este ficheiro não tem nomes verdadeiros, nem pedaços deles, nem o valor de nenhum PIN (§6).

## 1. O que mudou

**`rascunhos/cliente/hud/caixa_ordem.gd`** (o único ficheiro do jogo tocado):
- **D1 — toque fora.** Com a expandida aberta por toque, o toque fora que a fecha passa a ficar na caixa
  (`set_input_as_handled()`, em `_fechar_por_toque_fora`). Isso cobre o gesto todo desse dedo: o carregar, o arrastar e
  o levantar. Cobre também o rato que o motor imita a partir do toque.
  - Medi o pormenor que decide isto: o `Input` do motor despacha o rato imitado (`device` −1) **antes** do próprio
    `ScreenTouch`. Na sonda, a janela recebeu primeiro o `InputEventMouseButton` e depois o `ScreenTouch`. A câmara arma
    o `toque` com o rato imitado (`MOUSE_BUTTON_LEFT` carregado) e dispara-o no levantar.
  - Por isso consumir só o `ScreenTouch` não chegava. A caixa consome o rato imitado do carregar fora e engole o resto
    do gesto até o dedo se levantar (`_engolir`).
  - O toque seguinte, já com a caixa fechada, vai ao tabuleiro como sempre.
- **D3 — roda nos fins.** Pus `mouse_force_pass_scroll_events = false` na caixa. No Godot esta opção vem ligada por
  omissão: um Control com `MOUSE_FILTER_STOP` deixa passar a roda que ninguém gastou. O `ScrollContainer` só aceita a
  roda quando a posição muda, e no topo ou no fim ela não muda. Com a opção desligada, essa roda pára no painel da caixa
  e nunca chega ao `_unhandled_input` da câmara.
  - A lista continua a rolar com a roda pelo meio, porque o `ScrollContainer` aceita-a antes de ela chegar ao painel.
- Nada de visual, de cores ou de texto à vista mudou: só comentários e o tratamento dos eventos.

**D2 — a rolagem provada por gesto** (só testes e prova; o código da lista já rolava, ver §3):
- `testes/caixa_janela.gd` `_medir_expandida`: a verificação «o que não cabe rola por dentro» comparava a mesma conta
  das alturas dos dois lados. Passa a ser a roda do rato a sério por `push_input` em cima da lista, com a posição medida
  antes, depois de 1 passo, no fim (com a última linha à vista) e de volta ao topo (`MEDIDA RODA`).
  - Quando a ordem cabe, a roda não mexe a lista.
  - O número de verificações não mudou (123): o CI exige «123 de 123» e eu não toco no workflow.
- **O arrastar.** Mede-se e regista-se como facto (`REGISTO ARRASTAR`, não conta): o arrastar com o botão do rato e com
  o dedo (`ScreenTouch` + `ScreenDrag`), 3 linhas para cima. Não se finge um gesto que o PC não dá.
- `provas/ordem-caixa-expande/ferramentas/prova_caixa_expande.gd`, passo 8: o `rol.scroll_vertical = max_value` passa
  a ser a roda a sério até parar, com a posição medida antes e no fim.

**A prova dos 3 gestos com o tabuleiro:**
- **`testes/caixa_jogadora.gd` §10 (novo).** O HUD a sério com a **câmara da mesa a sério** (`camera/camera_mesa.gd`,
  a que dá à arena o `toque`, ou seja mover ou escolher a casa, e o zoom da roda). Corre com 12 e 16 figuras, em 844×390
  e 780×360. Os toques vão pelo `Input.parse_input_event` (o caminho do aparelho, com a imitação do rato).
  - D1: o toque fora não dispara o `toque` e não deixa a câmara armada. De controlo, o toque seguinte, com a caixa
    fechada, dispara-o 1 vez.
  - D3: o zoom fica igual na subida até ao topo, no topo, na descida até ao fim e no fim. De controlo, a roda fora da
    caixa dá zoom.
- **A prova viva, passo 11 (novo, depois do 10).** O Mestre de ensaio põe criaturas até 12 e depois até 16 figuras. Em
  844×390 e 780×360 faz-se o seguinte:
  - a roda rola a lista;
  - a roda nos fins não dá zoom à câmara da arena;
  - o arrastar fica registado;
  - o toque pelo `Input` abre a caixa, e um toque fora fecha-a com o tabuleiro medido antes e depois: os nós das
    figuras, as casas do Estado, o modo e o cursor da arena, os alvos, o item e a última intenção.
- O lançador novo `provas/ordem-caixa-expande-interacao/ferramentas/correr-prova-interacao.sh` é uma cópia do da
  CAIXA-EXPANDE com a saída nesta pasta. O PIN continua a ser novo por corrida.

**Biblioteca primeiro.** Vi a biblioteca GameDev Kit (o atalho no `G:`) antes de escrever:
- na bib 5 (`06_Ferramentas_e_Plugins`) há o G.U.I.D.E, o UI_Builder, o dot-ui e o theme_assist;
- no catálogo da bib 9 procurei rolar, toque, input, evento e gesto.

Não há lá nada que segure eventos de interface; o G.U.I.D.E remapeia acções de entrada, não é isto. A correcção usa as
duas peças do próprio motor (`mouse_force_pass_scroll_events` e `set_input_as_handled`). Não construí nenhum sistema.

## 2. Os números das suites
Godot 4.7.2, Windows 11, `--headless`, como no CI. Logs da caixa em `provas/ordem-caixa-expande-interacao/suite/`; as
linhas finais dos outros passos em `suite/resumo-alheios.txt`.

| passo do cliente | ponta `0bebd76` | agora |
|---|---|---|
| `rodar_testes` | 321/321 | **321/321** |
| `caixa_janela` | 123/123 | **123/123** (a verificação da rolagem é agora a roda) |
| `caixa_jogadora` | 42/42 | **58/58** (+16 do §10) |
| `caixa_jogadora -- --estrita` | 41/42 | 57/58 (a mesma falha de sempre: 780×360, 11,5 u) |
| `abrir_scripts` | | 108 scripts, 0 falhas |
| `abrir_clareira` · `abrir_mestre` · `pecas_mestre` · `hud_acoes` | | 22/22 · 67/67 · 286/286 · 50/50 |
| `medir_painel_config` · `medir_mestre` | | 0 falhas, 0 sem medida (os dois) |
| `teste_relato_caixa` · `teste_nomes_relato` · `canario_privacidade` | | 31/31 · 26/26 · 10/10 |
| arranque da cena principal | | chega a «pronto», 0 erros de script |
| erros de script em todos os passos | | 0 |
| guião de mutação da CAIXA-JANELA-CI (na ponta `3fb546b`) | | 9 falhas, todas da B6, «114 de 123», 0 erros, ficheiro reposto |

**As verificações novas apanham os defeitos.** Corri as suites com o `caixa_ordem.gd` da ponta (só na cópia de
trabalho, e depois reposto; logs em `sem-correcao/`):
- a `caixa_jogadora` dá **50/58**, e as 8 falhas são exactamente as D1 e D3 dos 4 casos. O `toque` dispara 1 vez; o zoom
  vai de 1,500 a 1,815 no topo, porque a subida até ao topo já deixa vazar um passo e o passo no topo outro;
- a `caixa_janela` dá 123/123 dos dois lados. Isso confirma que o D2 era uma falta de prova e não um defeito do código.

**A roda a rolar (D2), `caixa_janela`, medida (u = unidades do HUD):**

| figuras | ecrã | rola | 1 passo | fim (= máximo) | passos |
|---|---|---|---|---|---|
| 12 | 844×390 | sim | 0 → 105 | 233 | 4 |
| 12 | 780×360 | sim | 0 → 103 | 343 | 5 |
| 16 | 844×390 | sim | 0 → 105 | 593 | 7 |
| 16 | 780×360 | sim | 0 → 103 | 735 | 9 |

- Com 8 figuras nos três ecrãs, e com 12 em 1280×720, a ordem cabe e a roda não mexe a lista (0 → 0).
- Com 16 figuras em 1280×720 a lista rola 1 u (0 → 1).
- Em todas as que rolam, a última linha fica à vista no fim e a roda leva a lista de volta a 0.

**O arrastar (facto da plataforma).** `DisplayServer.is_touchscreen_available()` é **falso** neste PC, na suite e na
janela a sério. O arrastar com o rato na lista dá 0 → 0 u, e com o dedo (`ScreenTouch` + `ScreenDrag` por
`push_input`) também 0 → 0 u, em todas as medições que rolam. Num aparelho de toque o `ScrollContainer` do motor rola
ao arrastar. Aqui não há como o medir, e não o fingi.

## 3. A prova viva — 209/209
Está em `provas/ordem-caixa-expande-interacao/cliente/` (o README tem os SHA-256 das capturas novas):
- o cliente real pela Rede;
- o servidor de mesa real com o motor VLAB real (`a91c021c…`) e a semente 7;
- o manequim `andar-v3.glb` com o SHA conferido (`sha256 8413b0395d6b9f161aefe05004999ee5f605d4eb68e81a4767a81f9b56ea3491`, 2.858.648 B).

Por passo: 0 → 1 · 1 → 22 · 2 → 20 · 3 → 4 · 4 → 22 · 5 → 20 · 6 → 17 · 7 → 31 · 8 → 18 · 9 → 6 · 10 → 9 ·
**11 → 38**, mais 1 da abertura do manequim. Os passos 0 a 10 dão os mesmos 171 da CAIXA-EXPANDE. O 8 continua com 18
verificações: a da rolagem é agora a da roda, e mediu-se 0 → 49 u em 2 passos em 780×360 com 9 figuras.

**Passo 11, medido:**

| figuras · ecrã | roda: 1 passo → fim (máx.) | zoom: antes / pelo meio / fim / topo | controlo da roda fora | toque fora: «toque» · armado · tabuleiro | controlo do toque |
|---|---|---|---|---|---|
| 12 · 844×390 | 0 → 105 → 233 (233) | 1,500 / 1,500 / 1,500 / 1,500 | 1,500 → 1,815 | 0 · não · igual | 1 |
| 12 · 780×360 | 0 → 103 → 344 (344) | 1,500 / 1,500 / 1,500 / 1,500 | 1,500 → 1,815 | 0 · não · igual | 1 |
| 16 · 844×390 | 0 → 105 → 593 (593) | 1,500 / 1,500 / 1,500 / 1,500 | 1,500 → 1,815 | 0 · não · igual | 1 |
| 16 · 780×360 | 0 → 103 → 736 (736) | 1,500 / 1,500 / 1,500 / 1,500 | 1,500 → 1,815 | 0 · não · igual | 1 |

- «Tabuleiro igual» quer dizer que ficaram iguais os nós das figuras, as casas do Estado, o modo da arena (0 → 0), o
  cursor ((−1, −1)), os alvos, o item e a última intenção enviada.
- Arrastar com o rato: 0 → 0 u nas 4 medições.
- O máximo em 780×360 é 344 e 736 na prova e 343 e 735 na suite.

**Vi as capturas:**
- `11-roda-fim-16-figuras-780x360.png`: a lista no fim, com a última figura inteira;
- `11-toque-aberta-16-figuras-844x390.png`: a expandida aberta por toque, com a vez a ouro no topo;
- `11-toque-fora-16-figuras-844x390.png`: a caixa já compacta e o tabuleiro com as mesmas figuras nos mesmos sítios.

## 4. O que não pude provar como descrito, e porquê
- **O tabuleiro «com uma figura que se moveria».** No passo 11 a arena está sem modo (`Modo.NENHUM`: não é a vez da
  jogadora e a gaveta Mover não está aberta). Nesse estado, mesmo com o defeito, um `toque` não moveria nem escolheria
  nada. A medida que separa o certo do errado é o `toque` da câmara: 0 com a caixa aberta, contra 1 no controlo com a
  caixa fechada. A suite sem a correcção mostra que, com o defeito, esse `toque` dispara.
  - Pôr a jogadora na vez com o Mover aberto, para o toque fora cair numa casa de destino, pedia conduzir a batalha de
    ensaio até à vez dela. Não o fiz.
- **O arrastar num ecrã de toque.** Este PC não tem ecrã de toque (§2). Fica registado o que ele faz.

## 5. CI
**CI da ponta `4a33152`, já na linha** (Testes 45096618851 + Sonda 45096618860): **10/10 jobs verdes e a Sonda
verde**.

**CI da ponta `94719e0` (F21–F24, emendas da conferência), já na linha** (Testes 45103970823 + Sonda 45103970834): **10/10 jobs verdes e a Sonda verde** — a condição da fusão da F14 está cumprida. Os jobs são `servidor`, `validador-glb`, `foto-mestre`, `godot-cliente`, `cliente`, `ponta-a-ponta`,
`retoma-pc`, `provas-mapa`, `motor-real` e `protocolo`.

No Linux do CI os números são os de cá:
- `caixa_janela` 123/123, e a guarda «123 de 123» passou;
- `caixa_jogadora` 58/58;
- `rodar_testes` 321/321, nos jobs `cliente` e `godot-cliente`;
- `abrir_scripts` 108 scripts e 0 falhas · `abrir_clareira` 22/22 · `abrir_mestre` 67/67 · `pecas_mestre` 286/286 ·
  `hud_acoes` 50/50;
- `teste_relato_caixa` 31/31 · `teste_nomes_relato` 26/26 · o canário 10/10;
- o guião de mutação: 9 falhas, todas da B6, e «114 de 123».

O `retoma-pc` passou com as listas deste commit.

**Listas da retoma:** corri o `actualizar-listas.py` depois do commit 1, porque ele lê o `HEAD`. Deu 0 novos e 0
tirados; só mudam os SHA de 3 ficheiros: `caixa_ordem.gd`, `caixa_janela.gd` e `caixa_jogadora.gd`. O `depois.txt` e o
`MANIFESTO-SHA256.txt` vão sincronizados neste commit.

## 6. Privacidade: o conferidor estrito nos dois critérios
Conferidor: `provas/ordem-caixa-relato/ferramentas/conferir-registo.mjs`, critério alargado / `--velho`.

| ficheiro | alargado / antigo | nomes inteiros |
|---|---|---|
| este ESTADO-FINAL | **0 / 0** | 0 |
| `provas/ordem-caixa-expande-interacao/README.md` | **0 / 0** | 0 |
| as linhas que acrescentei a `caixa_ordem.gd`, `caixa_janela.gd`, `caixa_jogadora.gd` e à ferramenta da prova (só o `+` do diff contra `0bebd76`) | **0 / 0** | 0 |
| `suite/caixa_jogadora.log`, `suite/caixa_jogadora-estrita.log`, `sem-correcao/caixa_jogadora.log`, `suite/resumo-alheios.txt`, `mutacao/mutacao-celulas.resumo.txt` | **0 / 0** | 0 |
| `suite/caixa_janela.log`, `sem-correcao/caixa_janela.log` | 3 / 2 por log | **0** |
| o lançador `correr-prova-interacao.sh` (cópia do da CAIXA-EXPANDE) | 2 / 2 | 0 |
| `cliente/relato.txt` | 108 / 108 | **0** |

- **Os logs da `caixa_janela`** têm os mesmos achados que a CAIXA-JANELA-CI já tinha: duas linhas que a suite imprime
  desde antes (B1), com palavras correntes que partilham pedaços com os nomes. Não as escrevi, e cabem no padrão
  aceite (3/2 por log).
- **O lançador** herda a linha do servidor de ensaio (2/2, como o da CAIXA-EXPANDE).
- **O relato** imprime os nomes **públicos** das figuras, que são o que a caixa mostra: 108, como na CAIXA-EXPANDE.
- **As minhas linhas** tinham dois pares de palavras com pedaços: um num comentário da caixa e outro num da ferramenta.
  Troquei-os e ficaram 0 / 0. As suites e a prova viva voltaram a correr depois da troca, e os números acima são dessa
  corrida.
- **Os logs dos outros passos não se cometem.** O do `teste_nomes_relato` imprime nomes verdadeiros inteiros de
  propósito (é o teste do canário). Cometi-o por engano num commit local, que **desfiz antes de qualquer push**: nunca
  saiu do PC. Do resto fica só a linha final (`resumo-alheios.txt`, 0 / 0).
**Emenda da conferência (F21, 23/11/2026): o quadro verdadeiro.** O que este §6 diz sobre *esta entrega* é verdade (0 nomes inteiros em tudo o que ela acrescenta), mas a ponta já contém **90 pares (linha, nome) de nomes verdadeiros inteiros pré-existentes em 11 ficheiros** que esta ordem não toca: 9 `teste-nomes-relato.log` (5 cada) em `provas/ordem-caixa-janela/nomes/`, `nomes-correcoes/`, `cobertura/`, `cobertura-correcoes/` e `cobertura-correcoes-2` a `-6`; `provas/ordem-caixa-relato/correcoes-3/mutacoes.log` (42); `provas/ordem-caixa-janela/nomes-correcoes/mutacoes.log` (3) — 188 ocorrências brutas no total. Os 90 são um piso, não um tecto: só 44 ficheiros foram varridos; os restantes ~515 `.log`/`.txt` pré-existentes sob `provas/` não foram. A Sonda varre a árvore toda mas **só procura e-mails pessoais, nunca nomes** — «Sonda verde» nunca quis dizer «repo limpo de nomes». A frase «desfiz antes de qualquer push» é palavra do executor, não prova (um commit local desfeito não deixa rasto no GitHub). A limpeza da ponta segue na F25; a do histórico publicado depende da palavra do Mestre (F26). Convenção de contagem: um «par (linha, nome)» é uma linha que contém um nome verdadeiro inteiro; «ocorrências brutas» contam cada achado do conferidor nos dois critérios.

- **O PIN** é novo por corrida e passa só por `--pin=`. O info e o log do servidor ficaram na pasta temporária, fora
  do repo. Não há nenhum valor de PIN em nenhum ficheiro.

## 7. Pontos para o coordenador
1. **O D1 também segura um toque fora que caia num botão do HUD.** Com a lista aberta por toque, tocar em «Mover» só
   fecha a lista, e é preciso tocar outra vez. É a consequência directa de «consumir o pressed fora que fecha». O rato
   do PC não muda: a expandida do rato fecha quando o rato sai, antes de qualquer clique.
2. **A lista guarda a posição de uma abertura para a outra.** Se se fecha a meio, reabre a meio. Já era assim antes
   desta ordem e não lhe toquei («nada mais»). As provas levam-na ao topo com a própria roda antes de medir o topo.
3. **O controlo da roda fora da caixa deu dois passos de zoom na janela a sério e um na suite.** Na prova viva deu
   1,500 → 1,815 (1,1², dois passos) com um só passo de roda enviado. Na suite headless o mesmo passo dá
   1,500 → 1,650 (um passo). Isto é na câmara, fora do território desta ordem, e não o investiguei. Fica o registo,
   para alguém ver se a roda chega duas vezes à câmara na janela a sério.
4. **A guarda do CI prende a `caixa_janela` a «123 de 123».** Para a respeitar sem tocar no workflow, a prova da roda
   substituiu a verificação que comparava as mesmas alturas, em vez de se somar. Por isso o D1 e o D3, que precisam da
   câmara, estão na `caixa_jogadora` §10. **Emenda da conferência (F22, 23/11/2026):** o §10 TEM rede no CI — `testes.yml:153-156` (`set -o pipefail`) e o `quit(1 if _falhas > 0 else 0)` da `caixa_jogadora.gd:269`: uma falha de asserção reprova a run. A frase anterior («só guardada contra erros de script») era falsa.
