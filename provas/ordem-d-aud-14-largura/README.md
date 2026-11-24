# Provas — ORDEM-D-AUD-14-LARGURA (a largura do tabuleiro do Mestre não depende do caminho até à janela)

Godot 4.7.2 (win64), PC, 24/11/2026 (-03). Ponta de partida `afc7e85`; correcção em `672f3c1`.

## Ferramenta

`ferramentas/medir_largura.gd` — monta o ecrã do Mestre e mede, em **píxeis reais**, o tabuleiro e a folha em três
percursos até 1600×900:

- **A** — a janela abre já a 1600×900;
- **B** — a janela abre a 800×450, o ecrã monta-se, e a janela passa a 1600×900;
- **C** — a seguir a B, 1600×898 → 1600×900 (o «repassado» da INVESTIGA, `l11`).

Em cada passo compara a folha com a regra do próprio `_ao_redimensionar`, mas com o mínimo da barra das abas **na letra
de agora**: `max(45 % da área, coluna 1 + barra + 1 letra + 3 margens)`, com o tecto de 85 %. Se a folha não é essa,
escreve «MEDIDA VELHA». Sai com o código 0 só se A = B = C (±1 px) e a folha seguir a regra em todos os passos.

    cd rascunhos/cliente
    godot --headless --path . -s <raiz>/provas/ordem-d-aud-14-largura/ferramentas/medir_largura.gd
    godot --path . -s <raiz>/provas/ordem-d-aud-14-largura/ferramentas/medir_largura.gd -- --saida=<pasta das capturas>

## Números (iguais com e sem janela)

| passo | antes (`afc7e85`) | depois (`672f3c1`) |
|---|---|---|
| A — 1600×900 directo | **880 px** de tabuleiro (folha 864 u.; a regra pede 883) — MEDIDA VELHA | **864 px** (folha 883 u.) — certa |
| B — 800×450 | 407 px (folha 943 u.; a regra pede 1231; a barra acaba em 2140 de 1920 — **«Registo» e «Sala» fora do ecrã**) | 287 px (folha 1231 u.; a barra acaba em 1920) — certa |
| B — 800×450 → 1600×900 | **712 px** (folha 1066 u.; a regra pede 883) — MEDIDA VELHA | **864 px** (folha 883 u.) — certa |
| C — … → 1600×898 → 1600×900 | 864 px — certa | 864 px — certa |
| resultado | A=880, B=712, C=864 → **DIFERENTES**, saída 1 | A=B=C=**864** → **IGUAIS**, saída 0 |

O «880» directo de antes também estava errado: a folha foi medida com a barra das abas ainda na letra da passagem
anterior. A largura certa a 1600×900 é a do percurso C, que já era 864 antes da correcção (a INVESTIGA mediu 865 na
janela real, `l11`).

## Logs

- `logs/antes/medir-largura-headless.log`, `logs/antes/medir-largura-janela.log` — a ferramenta no `afc7e85` (o
  `mestre.gd` de HEAD posto na cópia de trabalho), sem e com janela.
- `logs/antes/medir-mestre-sem-correccao.log` — o teste novo do `medir_mestre.gd` com o `mestre.gd` **sem** a
  correcção: **4 falhas**, todas do bloco novo (as outras medidas passam). Prova de que o teste dispara.
- `logs/depois/medir-largura-headless.log`, `logs/depois/medir-largura-janela.log` — a ferramenta com a correcção.
- `logs/suites/*.log` — as 13 suites Godot que o CI corre, com a correcção (todas saída 0; ver ESTADO-FINAL §3). O
  caminho temporário dos comandos do Mestre está redigido como `<temp>`. As linhas `[floresta] pronta em …` (o
  relatório da carga do mapa, um JSON longo e igual em todas as corridas) foram tiradas dos logs.

## Capturas (janela real, 1600×900 e 800×450)

- `capturas/antes/a-1600x900-directo.png`, `b1-800x450.png`, `b2-1600x900-depois-800x450.png`
- `capturas/depois/` — os mesmos três.

O que se vê: em `antes/b2` o tabuleiro acaba aos 712 px e a folha tem um vazio largo à direita das abas; em `depois/b2`
o tabuleiro acaba aos 864 px, como em `depois/a`. Em `antes/b1` (800×450) só se vêem quatro abas («Figuras», «Agir»,
«Mesa», «Ambiente») e a barra corta-se na borda; em `depois/b1` vêem-se as seis.
