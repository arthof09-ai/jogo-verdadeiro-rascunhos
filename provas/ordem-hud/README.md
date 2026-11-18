# Provas da Ordem HUD — caixa da ordem de turnos + retratos (ecrã do Mestre)

Feitas na sessão na nuvem de 18/11/2026, ramo `claude2/hud`, código em `cd0cfb6`. Godot 4.7.2 oficial
(`4.7.2.stable.official.ed1daf0bf`), render Compatibility / OpenGL 3 por software (Mesa llvmpipe) num ecrã virtual
Xvfb 1280×720, `--fixed-fps 30`. Não há GPU nesta sessão: as cores e a luz são as do llvmpipe.

## `videos/`
- `ordem-turnos.mp4` (26,6 s; H.264 a partir do AVI do Movie Maker do Godot) — `testes/video_ordem.gd` no ecrã do
  Mestre a sério (`cenas/mestre/mestre.tscn`) com a vista real da fixture do servidor (cenário «mestre»). A etiqueta em
  baixo diz cada passo. **Guião de DEMONSTRAÇÃO** posto pela bancada (os eventos têm os campos do `ROOM_EVENT`, mas a
  sequência é escrita aqui; a «Jogadora 3» é uma cópia da Aliada marcada «demo»).
- `guiao.json` — cada passo com o tempo, a ordem que a caixa mostrava (`ordem`, ids) e quem estava na vez (`vez`).
- `video_ordem.log` — a saída da ferramenta (0 falhas).

## `capturas/`
| Ficheiro | O que mostra |
| --- | --- |
| `caixa-dinamica.png` | modo dinâmico: a ordem formou-se pelas acções — Heroína, Aliada, Jogadora 3, Orc (1-2-3-monstro) |
| `caixa-repete.png` | a segunda volta: a mesma ordem; o `guiao.json` mostra a vez a passar 1 → 2 → 3 → monstro |
| `caixa-iniciativa.png` | «Modo iniciativa» ligado: a caixa passa à ordem `iniciativa` da vista do servidor (entra o Lobo, que não agiu) |
| `caixa-desligada.png` | caixa desligada (aba Sala): o tabuleiro sem a caixa |
| `retrato-<tipo>.png` | o retrato de cada tipo de figura presente: humanoide (Heroína), orc, lobo |
| `retrato-vs-cena-<tipo>.png` | o retrato (esquerda) ao lado da figura em cena (direita): o retrato é a cópia do próprio modelo |

Nas capturas a caixa já está **por baixo** do «Entrar na câmera livre» (correcção desta sessão, ver ESTADO FINAL).

## `comparacao/` — caixa desligada = a batalha exactamente como antes
`testes/foto_sem_caixa.gd` corre a mesma cena e o mesmo guião (4 ataques) em duas árvores e grava o ecrã inteiro no
mesmo quadro: a de hoje (caixa LIGADA durante as acções, forma a ordem e os retratos; o Mestre desliga-a antes da foto)
e a de antes da missão HUD (`cbe7729`, ponta de `fable/integracao-50`, onde a caixa não existe). Duas corridas de cada.

- `hoje-caixa-desligada.png` e `antes-cbe7729.png`: **o mesmo SHA-256** (`088ff9a6…`) — 0 píxeis diferentes, 4/4
  corridas iguais byte a byte (`sha256.txt`).
- Controlo de sensibilidade: `controlo-caixa-ligada.png` (a mesma foto com a caixa ligada) difere em 54 116 píxeis,
  todos dentro do rectângulo da caixa (14,65)–(390,209).
- O que a foto não cobre: a aba Sala tem mais um botão («Caixa da ordem: ligada/desligada»); a foto mostra a aba
  Figuras. Com a caixa desligada, os palcos dos retratos já criados ficam em memória (não se desenham no ecrã).

## `suites/`
Os logs locais (ponta `cd0cfb6`, Godot 4.7.2 headless) dos passos Godot do job `cliente` do CI: abrir_scripts
102 scripts / 0 falhas · rodar_testes 226/226 · abrir_clareira 22/22 · medir_painel_config 0 falhas · abrir_mestre
67/67 · pecas_mestre 286/286 · medir_mestre 0 falhas · hud_acoes 50/50 · canario_privacidade 10/10 · arranque
«pronto», 0 erros de script. Os comandos do Mestre passam nos schemas (9/9 e 26/26 mensagens).

## Como refazer
```
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
  --write-movie <pasta>/ordem-turnos.avi --path rascunhos/cliente -s res://testes/video_ordem.gd -- --saida=<pasta>
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
  --path rascunhos/cliente -s res://testes/foto_sem_caixa.gd -- --saida=<ficheiro.png> [--caixa-ligada]
```
Para o «antes»: `git worktree add <dir> cbe7729`, copiar `foto_sem_caixa.gd` para `<dir>/rascunhos/cliente/testes/`,
importar o projecto e correr o mesmo comando lá.
