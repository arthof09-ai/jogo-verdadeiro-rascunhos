# Provas — Ordem CAIXA-HUD-JOGADORA (20/11/2026, Claude conta 1, PC)

A caixa da ordem de turnos no HUD da jogadora, com a escolha do Mestre lida do servidor.

## cliente/ — a jogadora entra a meio de uma batalha de bancada (36/36)
- Servidor de mesa real (`ferramentas/servidor-bancada-prova.mjs`, cópia da da CAIXA com caminhos portáteis): sala e
  WebSocket do jogo, cenário e fichas de bancada, semente 7, motor VLAB real sha256 `a91c021c…` (`servidor-info.json`).
- O cliente da jogadora a sério (`cenas/arena/arena.tscn` + HUD, pela Rede do jogo), Godot 4.7.2 Windows, render
  NVIDIA GeForce RTX 4060 (janela 1028×720 na captura), pela ferramenta `ferramentas/prova_caixa_jogadora.gd`
  (lançador `ferramentas/correr-prova-caixa-hud.sh`). Relato em `cliente/relato.txt`.
- Capturas (sha256, 16 primeiros):
  1. `1-entrou-dinamica.png` `60250e76d86d6a38` — a Espadachim entra: caixa ligada, dinâmica, Arqueira → Lobo → Espadachim, ela na vez.
  2. `2-iniciativa.png` `f995b4785c7038f3` — o Mestre escolhe «Modo iniciativa»: a caixa dela passa à iniciativa, Bruto na vez.
  3. `3-desligada.png` `10eed5b6385dd249` — o Mestre desliga: a caixa sai do HUD dela.
  4. `4-religada-avancou.png` `577466d65bc74666` — religada no dinâmico; Bruto e Arqueira jogam: a volta fecha pelos eventos, Arqueira na vez.
  5. `5-reentrou.png` `79d9cbbe29985403` — ela sai e volta a entrar: a caixa reconstrói-se igual.
- Os nomes na caixa são os PÚBLICOS («Lobo», «Bruto»; o Mestre vê «nome n.º 2», «nome n.º 1»).

## suites/ — as suites da casa, locais (PC, Godot 4.7.2 headless, Node 26)
servidor 380/380 · schemas (tráfego dos testes) 0 falhas nas mensagens que saem · abrir_scripts 105/0 falhas ·
rodar_testes 243/243 · caixa_jogadora 16/16 (novo) · hud_acoes 50/50 · canário de privacidade 10/10 ·
medir_painel_config 0 falhas · abrir_clareira 22/22 · abrir_mestre 67/67 · pecas_mestre 286/286 ·
medir_mestre 0 falhas · arranque «pronto».

Correr de novo (Git Bash, na raiz do repo):
`bash provas/ordem-caixa-hud-jogadora/ferramentas/correr-prova-caixa-hud.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`

## Nota da Ordem CAIXA-RELATO (B7b, 21/11/2026)
No `cliente/relato.txt` desta pasta, a linha do §4 «a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica
{…"fechada":false…}» imprime o JSON do **último ROOM_SNAPSHOT** (o da religação), que os eventos seguintes já tinham
adiantado — **não** é a caixa actual dela (essa é a da linha de cima, «fechada: true»). O relato é o registo do que se
viu a 20/11 e fica como está. A ferramenta foi corrigida (a linha diz de que snapshot é o JSON, marca-o
«DESACTUALIZADO» e imprime a caixa actual); a corrida nova está em `provas/ordem-caixa-relato/cliente-hud/` (38/38).
