# Provas — Ordem CAIXA-MANEQUIM (21/11/2026, Claude conta 2, PC)

Os mesmos 5 momentos da prova viva da CAIXA-HUD-JOGADORA (`provas/ordem-caixa-hud-jogadora/cliente/`), voltados a
capturar com o **manequim de referência da casa** no lugar das cápsulas de bancada — nas figuras em cena **e** nos
retratos da caixa (que são cópias delas, `hud/retratos.gd`). Linha: `fable/integracao-50` @ `e38b4fc` (já com a
CAIXA-JANELA fundida).

## cliente/ — 46/46
- Servidor de mesa real, o da CAIXA-HUD-JOGADORA usado tal como está
  (`provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs`): semente 7, motor VLAB real sha256
  `a91c021c…`, cenário `7703320c…`, fichas `3c498137…` (`cliente/servidor-info.json`) — os mesmos da prova antiga.
- Cliente da jogadora a sério (`cenas/arena/arena.tscn` + HUD, pela Rede do jogo), Godot 4.7.2 Windows, render NVIDIA
  GeForce RTX 4060, `--resolution 1280x720` (janela 1028×720 na captura: o mesmo enquadramento das 5 antigas).
- Manequim: Mannequin_F (UAL2) com o ANDAR v3, `rascunhos/cliente/testes/manequim/andar-v3.glb`, sha256
  `8413b039…` conferido antes de abrir; parado no quadro 0 do `andar_v3` (a pose das capturas do LAGO-MAIOR).
- Ferramenta `ferramentas/prova_caixa_manequim.gd` (cópia da `prova_caixa_jogadora.gd` + o manequim), lançador
  `ferramentas/correr-prova-caixa-manequim.sh`. Relato em `cliente/relato.txt`.
- Capturas (sha256, 16 primeiros):
  1. `1-entrou-dinamica.png` `032370a23b4e55a2` — dinâmica: a Espadachim entra; Arqueira → Lobo → Espadachim, ela na vez.
  2. `2-iniciativa.png` `f2f872e6ce918e45` — iniciativa: o Mestre escolhe «Modo iniciativa»; Bruto na vez.
  3. `3-desligada.png` `26dbd430026c863b` — desligada: a caixa sai do HUD dela.
  4. `4-religada-avancou.png` `296e544774a89631` — religada no dinâmico; Bruto e Arqueira jogam; Arqueira na vez.
  5. `5-reentrou.png` `f053b3b5f5b33695` — reentrada: ela sai e volta a entrar; a caixa reconstrói-se igual.

## Como o manequim entra (só na ferramenta; o código do jogo não mudou)
Em cada figura em cena a ferramenta esconde a cápsula (`Corpo` fica no nó, invisível: a arena continua a pintá-la e a
assentá-la) e põe o manequim no pé da figura, virado como ela. Os retratos já desenhados esquecem a chave e
redesenham-se da cópia nova. Antes de cada captura confere: todas as figuras com manequim, 0 cápsulas à vista, e cada
retrato da caixa copiado de um modelo com o manequim e sem a cápsula.

Correr de novo (Git Bash, na raiz do repo; num clone novo, primeiro `godot --headless --path rascunhos/cliente --import`):
`bash provas/ordem-caixa-manequim/ferramentas/correr-prova-caixa-manequim.sh <Godot_console.exe> <vlab-completo.js> <pasta-tmp>`

## Nota da Ordem CAIXA-RELATO (B7b, 21/11/2026)
No `cliente/relato.txt` desta pasta, a linha do §4 «a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica
{…"fechada":false…}» imprime o JSON do **último ROOM_SNAPSHOT** (o da religação), que os eventos seguintes já tinham
adiantado — **não** é a caixa actual dela (essa é a da linha de cima, «fechada: true»). O relato fica como está. A
ferramenta foi corrigida (a mesma correcção da `prova_caixa_jogadora.gd`); a corrida nova está em
`provas/ordem-caixa-relato/cliente-manequim/` (48/48).
