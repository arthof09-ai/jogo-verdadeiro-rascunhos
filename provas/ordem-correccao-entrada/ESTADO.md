# ESTADO — ORDEM CORRECÇÃO DA ENTRADA (achado do ensaio de 27/11)

Executor: conta 1 (Opus 5.5) · PC do cunhado · início 27/11/2026 ~20:20 · linha `fable/integracao-50`
Sede local: `C:\Users\txcga\RPG_Local\jogo-verdadeiro\ordem-correccao-entrada-pc\` (clone novo em `repo\`; ponta ao
arrancar `c067430`). Casa partilhada: esta pasta. Provas no repo: `provas/ordem-correccao-entrada/`.

| Passo | Estado |
|---|---|
| 1 Diagnóstico medido | **FECHADO** (abaixo) |
| 1b Entrar no protótipo | **FECHADO** (abaixo) — ver a nota sobre `prototipo-referencia\` |
| 2 Correcção | a correr |
| Prova (vídeo + fotos + CI) | por fazer |

---

## Passo 1 — Diagnóstico medido (lido na construção servida, e medido)

**O que foi servido no ensaio:** o export web do run `45946124164` (via principal do guia), em
`ordem-plano-2-f1-f2-fecho-4dez-pc\repo\build\web\` (`index.pck` SHA-256 `fa4ee2b3…967499b`). A entrada é **toda
desenhada pelo Godot dentro do `<canvas>`**: `cenas/lobby/lobby.gd` monta um `PanelContainer` com `LineEdit` do Godot
(nome, senha, PIN). Não há HTML por cima do canvas: o DOM visível tem **0 controlos** (`passo1-antes/dom-retrato.json`:
`"controlos": []`, canvas 360×640 CSS = 1080×1920 px).

### Causa A — a caixa «não pega» (não abre o teclado, não recebe letras)

1. **O teclado virtual do export está desligado.** `rascunhos/cliente/export_presets.cfg` l. 46:
   `html/experimental_virtual_keyboard=false`; no `index.html` servido: `"experimentalVK":false`. Sem isso o Godot não
   tem nenhum `<input>` de verdade para o celular abrir o teclado.
2. **O que o Godot usa em vez disso** (lido no `index.js` servido, `GodotIME.ime_active`): quando um `LineEdit` ganha o
   foco, mostra uma `div.ime` `contentEditable` **invisível** (`opacity:0`, `pointer-events:none`, `font-size:1px`) e
   **re-foca-a por um temporizador** `setInterval(focusTimer, 100)` — fora do gesto do toque. A `div.ime` só passa ao
   jogo eventos `compositionstart/update/end` e `keydown/keyup`; o texto que o teclado do celular insere sem composição
   (`input`/`insertText`, keyCode 229) não chega ao jogo.
3. **Medido** (Chromium com ecrã de celular, toque verdadeiro do CDP, DPR 3 — `passo1-antes/paisagem-toque/`): tocar
   no campo do nome → o foco vai para `DIV.ime`; inserir «Arqueira» como o teclado do celular insere
   (`Input.insertText`) → **o campo continua vazio** (foto `03-depois-de-escrever.png`: «Nome da personagem» vazio,
   «Entrar» inactivo).
4. **Porque é que o CI passava:** `aparelhos/prova-web.mjs` escreve com `Input.dispatchKeyEvent` (teclado físico pelo
   DevTools), que entra pelo `keydown` do canvas. Esse caminho não existe num celular. O CI nunca testou o toque.

### Causa B — nasce minúscula no meio

- `project.godot`: base 1920×1080, `stretch/mode="canvas_items"`, `aspect="expand"`; o Godot web usa
  `hidpi:true` (`getPixelRatio = devicePixelRatio`), logo o «ecrã» do jogo num celular de 360×640 CSS com DPR 3 é
  **1080×1920 px de aparelho**.
- `lobby.gd` `_ao_redimensionar()`: `escala = min(1080/1920, 1920/1080) = 0,5625`; fonte = `max(22, ceil(13/0,5625))`
  = 24 unidades = **13,5 px de aparelho = 4,5 px CSS**; painel `fonte×18` = 432 unidades = **243 px de aparelho = 81 px
  CSS** de largura num ecrã de 360. O mínimo «13 px reais» (`FONTE_MIN_PX_REAIS`) foi contado em px de aparelho, não
  em px CSS; com DPR 3 é um terço do que se lê.
- **Medido:** `passo1-antes/retrato/01-entrada-nasce.png` — a caixa ocupa ~22 % da largura, letras ilegíveis sem zoom
  (e o `index.html` do Godot põe `user-scalable=no`: nem com zoom). Em paisagem 640×360 lê-se, mas é o painel cinzento
  azulado do Godot, nada do protótipo.

### Causa C — «nada a ver com o layout do protótipo»

A entrada do jogo é um painel cinzento-azulado (`COR_FUNDO 0.10,0.13,0.18`, `COR_PAINEL` azul-escuro) com «Sou o
Mestre» em texto. O protótipo (passo 1b) é a arte pintada a ecrã inteiro com o título, três botões-placa de ouro e
painéis escuros com moldura de ouro. Nenhuma peça do protótipo foi levada para o jogo.

---

## Passo 1b — Entrar no protótipo

**Nota sobre `prototipo-referencia\`:** ao começar, a pasta **não existia** nesta casa (só `desktop.ini`). Para não
parar o caminho crítico, fui eu buscar a **versão publicada actual**: o ramo `gh-pages` do
`arthof09-ai/arena-das-bestas-prototipo-cm9` na ponta **`410dd02`** (o que o GitHub Pages serve hoje; a cópia em
`Desktop\RPG Assimilação\pages-publish` é velha, `885a9bb` de 31/10). A entrada do Mestre está em **`jogo-t1/`**
(`VERSAO_JOGO = 'REF_133'`). Coloquei a pasta `jogo-t1\` executável em `prototipo-referencia\` com o SHA do commit.
**Coordenador: confirme que é este o protótipo de referência** (há também `teste-porte-godot/`, um porte Godot
publicado no mesmo Pages — com `experimentalVK:false` também; a fonte dele não está no repo, o `main` é o Arena das
Bestas antigo).

**Como o corri:** servido por HTTP local (`http-server`, porta 8571), aberto no Chromium com ecrã de celular (toque,
DPR 3), 360×640 e 640×360, com o roteiro `ferramentas/roteiro-toque.mjs` + `passos-prototipo.json`. Fotos e registo
em `provas/ordem-correccao-entrada/passo1b-prototipo/`.

**Comportamento (visto a correr):**
1. A página nasce num **filme** a ecrã inteiro (`video-entrada.mp4`, 18 s, só imagem, com a trilha), com «PULAR»; ao
   chegar ao título (~14 s) aparecem os botões; depois fica o **loop** (`video-loop.mp4`). Marca `REF_133` discreta no
   canto inferior esquerdo.
2. Ecrã dos botões: **arte a ecrã inteiro** (em retrato o fundo vertical; em paisagem o fundo largo com o título
   «ASSIMILAÇÃO» pintado), e **três botões-placa** (moldura de ouro em losango nas pontas, fundo escuro, letras em
   versaletes de ouro claro `rgb(236,210,138)`): «ENTRAR COMO MESTRE», «ENTRAR COMO JOGADORA», «CONFIGURAÇÕES».
   Retrato: empilhados em baixo, 252×46 px CSS cada, letra 15–16 px CSS. Paisagem: os três lado a lado em baixo.
3. Tocar «Entrar como Mestre» abre um **painel** escuro com moldura de ouro fina e cantos redondos: título
   «ENTRAR COMO MESTRE» em ouro espaçado + botão ✕ com moldura de ouro; dentro, «Entrar com o Google» e o acesso
   pequeno «Entrar com a senha».
4. Tocar «Entrar com a senha» abre o campo **e foca-o logo** (`INPUT#ent-senha-campo`, `type=password`): rótulo «A
   sua senha», campo escuro com **moldura de ouro ao focar**, botão **«Entrar» cheio a ouro** com letra escura, e
   «Esqueci a senha» sublinhado.
5. Tocar no campo → foco num `<input>` de verdade (o teclado do celular abre); inserir «1234» como o teclado insere →
   aparecem os 4 pontos (`valor_len 4`, foto `06-escrito`). «Entrar» com senha errada → limpa e volta a focar o campo.
6. Em paisagem o painel fica centrado, com scroll interno quando não cabe.
7. **Código:** é HTML/CSS por cima do jogo — `index.html` + `entrada.css` + `entrada.js` (2 330 linhas); os campos são
   `<input>` nativos; o jogo (three.js) só arranca depois da entrada.

**O que a correcção vai seguir:** a mesma construção — a entrada passa a ser **HTML por cima do canvas**, com
`<input>` nativos e o CSS do protótipo (fundo pintado, botões-placa, painéis com moldura de ouro), ligada ao Godot por
`JavaScriptBridge`. O que não se leva (decisão minha, para o coordenador confirmar): o Google (o jogo verdadeiro entra
por PIN e nome+senha no servidor); «Configurações» (o jogo não tem as definições do protótipo — um botão sem função
seria outra caixa de enfeite).
