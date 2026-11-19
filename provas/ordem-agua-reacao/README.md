# Provas — Ordem ÁGUA-REAÇÃO (19/11/2026)

Godot 4.7.2 oficial; renderizador Compatibility (OpenGL 3) por software (Mesa llvmpipe, Xvfb), sem GPU. Bancada:
`rascunhos/cliente/testes/video_lago.gd` (a mesma do NADO), 1280×720 de conteúdo, 30 q/s fixos. Ver
`ESTADO-FINAL-ORDEM-AGUA-REACAO.md` na raiz.

**ANTES** = a árvore `55e5814` (Ordem 66 + NADO, sem esta ordem). **DEPOIS** = esta ordem. Mesma bancada, mesmo guião:
a geometria (caminho, fundura, água no corpo, pés no leito) é igual linha a linha nas duas; só a reacção da água muda.

- `videos/` — os filmes do DEPOIS (`rasa.mp4`: entrar, vadear e parar; `funda.mp4`: começa parado, deita-se a nadar,
  sai e pára) e os dois lado a lado ANTES | DEPOIS (`*_antes-depois.mp4`). Convertidos dos `.ogv` do Godot com ffmpeg
  (H.264).
- `folhas/` — ANTES à esquerda, DEPOIS à direita, o mesmo quadro do guião; as `*-de-perto_*` são recortes ampliados à
  volta da figura (entrar, deitar-se a nadar, parada a acalmar). Feitas com `ferramentas/folha.py`.
- `quadros/` — as capturas da bancada no DEPOIS (o nome diz o instante e o momento).
- `medicao/antes|depois/` — `<modo>_fases.json` e `<modo>_medicao.json` de cada corrida. A série do DEPOIS tem duas
  colunas novas: `agito` (0–1) e `salpicos`.
- `medicao/custo/` — `--modo=medir` (1920×1080, sem vsync, tempo real) no ANTES, no DEPOIS e outra vez no ANTES.
- `suites/` — logs: rodar_testes (243/243), abrir_scripts, arranque e as duas corridas da bancada.
