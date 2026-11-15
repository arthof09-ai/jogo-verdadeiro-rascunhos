# ESTADO FINAL — Ordem 51: o toque que falhava na grelha 30 × 30

Branch `fable/toque-51`, a partir de `8cd941d` (o fecho da Ordem 45). Só código do produto e medição. Nada visual.

## O defeito

Na grelha 30 × 30 de 1,5 m, com a câmara 360° rasante (rumo 135°, inclinação 20°, zoom 0,6: o modo rasante
da prova da Ordem 45), 3 toques davam «fora da grelha» (−1,−1) em vez da casa tocada. Isto acontecia **igual**
nas duas arenas, porque as duas tocam pelo mesmo raio, `CampoDaMesa.ponto_no_chao`
(`rascunhos/cliente/cenas/arena/campo_da_mesa.gd`).

## Parte A: a medição

`rascunhos/cliente/cenas/arena/ferramentas/medir_toque_rasante.gd` mede os três modos da prova da Ordem 45 (Fixa,
Panorama, 360° rasante) na 20 × 20 e na 30 × 30, na arena do jogador e na do Mestre. O centro de cada casa à vista
vai ao ecrã, e o toque nesse ponto tem de voltar à mesma casa. Cada falha fica nomeada com a casa, o modo, a câmara,
a direcção do raio e o que o raio devolveu. Também se registam o relevo nesse ponto e um chão de referência: o mesmo
raio marchado a 0,01 m. Por fim mede-se a folga mínima do raio sobre o relevo a ±0,6 m do centro da casa, em passos
de 1 mm.

    godot --headless --path cliente -s res://cenas/arena/ferramentas/medir_toque_rasante.gd -- --json=caminho

O resultado de antes do conserto está em `provas/ordem-51-toque/antes.txt` e `antes.json`. São as 3 falhas, iguais nas duas arenas.
A câmara está em (29,901; 15,305; −29,901):

| casa | deu | o raio devolveu (chão, já fora da grelha) | casa desse ponto | folga do raio no centro da casa |
|---|---|---|---|---|
| (0,6) | (−1,−1) | (−33,224; −0,788; −8,940) | (−8,9) | −0,00000 m |
| (24,27) | (−1,−1) | (9,952; 0,613; 32,109) | (21,36) | 0,00000 m |
| (24,28) | (−1,−1) | (9,363; 0,673; 35,909) | (21,38) | 0,00000 m |

O raio de referência a 0,01 m também passa por cima, ao milímetro. Não é a bisseção nem o ponto de partida aos 12 m.

## Parte B: a causa e o conserto

**A causa.** Nestas 3 casas, o centro fica num cimo do relevo, e esse cimo é o horizonte do chão visto da câmara
rasante. O raio do ecrã passa pelo centro da casa **tangente** ao relevo: a folga medida é 0 m, com uma margem de
alguns micrómetros abaixo do chão ao longo de menos de 1 mm. `ponto_no_chao` marcha em passos de 0,25 m e só pára
num passo que fique **abaixo** do relevo. O contacto tangente cabe entre dois passos e nenhum o apanha. O raio
segue então por cima do cimo e desce no chão muito depois, já fora da grelha. Na 20 × 20 não há casas destas
nestes modos, por isso dá 400/400.

**O conserto**, no módulo partilhado `campo_da_mesa.gd`, a mesma porta para as duas arenas. Não há remendo numa arena
nem cópia do raio. A marcha guarda a folga (altura do raio − relevo) dos dois passos anteriores. Quando a folga
desce e volta a subir (um mínimo entre passos, abaixo de um passo de altura), esse mínimo afina-se por secção áurea
em [t − 2·passo, t]. Se a folga mínima for ≤ `TOQUE_RASANTE_M` (1 mm), o raio conta como tocando o chão nesse ponto.
Tudo o resto fica como estava: a marcha, a bisseção quando o raio fica abaixo do relevo, o início aos 12 m e os
limites. O cimo só ganha o toque se vier **antes** do primeiro ponto abaixo do relevo, isto é, quando o raio o
rasa a menos de 1 mm. Fora disso, nada muda.

## Parte C: as provas (antes → depois)

O resultado de depois do conserto está em `provas/ordem-51-toque/depois.txt` e `depois.json`. A medição compara
cada toque com o raio de antes (uma cópia congelada **só na ferramenta de medição**, `_raio_antes`, que o produto
não usa). Assim conta os toques que já acertavam e mudaram de ponto (> 1 mm).

| grelha · modo | antes (jogador · Mestre) | depois (jogador · Mestre) | já acertavam e mudaram |
|---|---|---|---|
| 20 × 20 · Fixa | 340/340 · 301/301 | 340/340 · 301/301 | 0 · 0 |
| 20 × 20 · Panorama | 400/400 · 400/400 | 400/400 · 400/400 | 0 · 0 |
| 20 × 20 · 360° rasante | 400/400 · 400/400 | 400/400 · 400/400 | 0 · 0 |
| 30 × 30 · Fixa | 637/637 · 467/467 | 637/637 · 467/467 | 0 · 0 |
| 30 × 30 · Panorama | 900/900 · 900/900 | 900/900 · 900/900 | 0 · 0 |
| 30 × 30 · 360° rasante | **892/895 · 892/895** | **895/895 · 895/895** | 0 · 0 |

As duas câmaras vêem números diferentes de casas na Fixa porque o Mestre vê pelo seu SubViewport. Isto já era assim
e não é falha: o que falha é o mesmo nas duas.

A prova da Ordem 45 (`cenas/mestre/ferramentas/provar_mestre_no_relevo.gd`) dá agora 895 de 895 no rasante da 30 × 30,
e TUDO PASSOU.

Suites, locais, no Godot 4.7.2 (Windows, `--headless`):
- `testes/rodar_testes.gd`: 176 de 176, sem erros de script;
- `testes/abrir_scripts.gd`: 68 scripts, 0 falhas (inclui o script novo de medição);
- servidor (`node --test testes/*.test.mjs`): 348 de 348;
- ponta a ponta com o motor falso (servidor + jogadora Node + Mestre Godot): 17 de 17, Mestre 0, jogadora 0.
- CI: ver a secção «Push e CI» abaixo.

## Resíduos nomeados

1. **As 5 casas tapadas** na 30 × 30 rasante (iguais antes e depois, nas duas arenas): o relevo tapa-lhes o centro
   desta câmara, e por isso não contam como vistas. Não são toques falhados: não há centro no ecrã para tocar.
2. **A tolerância de 1 mm é uma escolha.** Um raio que passe a menos de 1 mm por cima de um cimo antes do chão toca
   o cimo. É imperceptível no ecrã (milímetros a 15 m de câmara) e é o comportamento certo para um toque. Mudar é
   uma constante (`TOQUE_RASANTE_M`).
3. **Um mínimo de folga mais curto que um passo**, com dois mínimos entre os mesmos três passos: a secção áurea
   encontra um deles. Não aparece em nenhum dos 6 × 2 conjuntos medidos.
4. **O modo rasante medido é o da Ordem 45** (uma câmara: rumo 135°, inclinação 20°, zoom 0,6). Não meço outros rumos.
