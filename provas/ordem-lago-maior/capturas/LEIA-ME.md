# Capturas — ORDEM LAGO-MAIOR (20/11/2026)

Render com GPU (NVIDIA GeForce RTX 4060, OpenGL 3.3), 1920 × 1080, a arena DO JOGO (`cenas/arena/arena.tscn`) com a
grelha-mapa 50 × 50 de 1,5 m (o jogo por omissão). Ferramenta: `../ferramentas/foto_lago_maior.gd`.

**A figura é o manequim de referência da casa** (regra do Mestre, 18:56): o `Mannequin_F` do UAL2 com o ANDAR v3
(`rascunhos/cliente/testes/manequim/andar-v3.glb`, SHA-256 conferido; 1,81 m na pose do quadro 0). A arena abre
**sem nenhuma figura do jogo** — nada de cápsulas nem de bichos de enchimento. O pé do manequim é o leito, como o
jogo põe hoje uma figura numa casa funda (sem natação inventada: frente NADO).

| foto | o que mostra | o manequim (x, z) | água acima do pé |
|---|---|---|---|
| `1-mapa-inteiro.png` | vista da jogadora (Panorama): a grelha sobre o mapa todo, o lago maior e **a floresta de dentro do campo devolvida** | (14,2; −18,5), parte funda | 1,49 m |
| `2-funda-pescoco.png` | de perto, da margem: a parte funda, **a água pelo pescoço** | (14,2; −18,5) | 1,49 m (82 % da altura) |
| `3-funda-meio.png` | o meio do lago (2,45 m): **o manequim fica coberto** | (21,0; −21,0) | 2,45 m |
| `4-margem-rasa.png` | a faixa de andar da margem: **a água pelo joelho** | (12,3; −17,8) | 0,42 m |
| `5-floresta-ne.png` | o lago inteiro visto de dentro do campo, com as árvores e as rochas devolvidas à volta | (13,4; −14,6), na margem | 0,31 m |

Antes (para comparar): `provas/ordem-mapa-jogavel/capturas/jogadora_50x50_1,5m_1-mapa-todo.png` (CAPTURAS-MAPA, com o
lago de 183 m² e o mapa sem a floresta de dentro do campo).

`medicao.json`: o render, a altura do manequim, o nível da água e, por foto, o sítio e a fundura.
