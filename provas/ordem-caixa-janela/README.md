# Provas — Ordem CAIXA-JANELA (21/11/2026, Claude conta 1, PC)

A janela lobby→arena fechada (B1) e a caixa da ordem de turnos medida com 8+ figuras em ecrãs baixos (B3).

## cliente/ — o cliente da jogadora a sério, 10 figuras (35/35)
- Servidor de mesa real: `provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs` (o da CAIXA-HUD-JOGADORA,
  intacto), porta 8793, semente 7, motor VLAB real sha256 `a91c021c…` (`cliente/servidor-info.json`). 2 heroínas + 8
  criaturas de bancada (as fichas do cenário repetidas em casas da floresta).
- O cliente da jogadora a sério (`cenas/arena/arena.tscn` + HUD, pela Rede do jogo), Godot 4.7.2 Windows, render NVIDIA
  GeForce RTX 4060, pela ferramenta `ferramentas/prova_caixa_janela.gd` (lançador `ferramentas/correr-prova-caixa-janela.sh`).
  Relato completo em `cliente/relato.txt`.
- **B1:** a Espadachim entra e recebe o snapshot (seq 33) SEM a arena aberta; a bancada joga 3 vezes nesse intervalo
  (10 eventos, seq 33 → 43). Só então a arena abre: a caixa é logo a ordem do servidor (10 figuras, vez Lobo), sem
  snapshot novo.
- **B3:** a janela passa por 1280×720, 844×390 e 780×360; a caixa cabe, não tapa a ⚙/ficha/barra, e a faixa tem a largura
  da frase mais comprida (a da pausa) numa linha, fora da caixa. Capturas (sha256, 16 primeiros), vistas por mim:
  1. `1-janela-1280x720.png` `eb1aa86637683178` — 10 figuras numa linha; «O Mestre narra» entre a ⚙ e a caixa.
  2. `2-baixo-844x390.png` `f1bffa6c10cf68c8` — 10 numa linha (57% da largura); a faixa lê-se à esquerda da caixa.
  3. `3-baixo-780x360.png` `cf2fc7fce5f7cd93` — a fila parte em 2 linhas (9 + 1); a faixa lê-se.
- Privacidade: nenhuma mensagem do Mestre no aparelho dela; a caixa só com `ligada/ordemPor/ordemDinamica`; nenhum nome
  verdadeiro, vida ou PA nos textos da caixa, e nenhum dígito nesses textos.

## suites/ — as suites da casa, locais (PC, Godot 4.7.2 headless)
rodar_testes 290/290 · abrir_scripts 107/0 falhas · caixa_jogadora 18/18 (+2 do §7 novo) · **caixa_janela 69/69 (novo)** ·
hud_acoes 50/50 · canário de privacidade 10/10 · medir_painel_config 0 falhas · abrir_clareira 22/22 · abrir_mestre 67/67 ·
pecas_mestre 286/286 · medir_mestre sem falhas · arranque sem erros de script.
Regressão: a prova viva da CAIXA-HUD-JOGADORA (`prova_caixa_jogadora.gd`) corrida de novo com saída fora do repo: 36/36.
O servidor não mudou (nenhum ficheiro de `rascunhos/servidor`).

Correr de novo (Git Bash, na raiz do repo):
`bash provas/ordem-caixa-janela/ferramentas/correr-prova-caixa-janela.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`
