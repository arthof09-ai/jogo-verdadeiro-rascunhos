# Ordem 38 — correcções do mapa da floresta: ESTADO FINAL

*Fecho da ordem, 2026-11-14 (sucessão 4, conta 2). Ramo `fable/mapa-38-correcoes`, a partir de
`b4b8a79` (ponta da Ordem 37). A ponta final é o commit que traz este documento; o último commit
de prova antes dele é `a942143`. Tudo o que aqui está foi corrido ou visto nesta máquina (NVIDIA
GeForce RTX 4060, Godot 4.7.2, Compatibility). Os números vêm de `capturas/medicao.json` e da
saída das ferramentas; onde cito um commit sem ter repetido a prova, digo-o.*

*Sem críticos internos: «fechado» quer dizer construído e provado por quem construiu. O juízo é
do coordenador — o que os meus olhos acharam discutível está no fim, em «O que falta conferir».*

## Os 11 defeitos, um a um

| # | Defeito | Fechado em | O que entrou antes | Prova |
|---|---|---|---|---|
| 1 | Vistas para fora desmascaram o truque | `0ff0b54` | `1e68bf8`, `6aaac6d`, `3bba3c8` | vistas 09–12 (`d8f723a`); costura (`cc23522`) |
| 2 | Árvore-âncora fantasma → Árvore Ancestral | `6321e7a` | `aacb2c1`, `0ff0b54`, `461a9e7`, `a7aab18`, `2b1c208` | 4 faces em `capturas/ancestral`; lado a lado; o filme |
| 3 | Monocromia verde-lima | `aa64b25` | `3bba3c8` | cor medida por vista (`16b689b`, `a942143`) |
| 4 | Repetição temática | `82fb97c` | `b52d3d1`, `dd80cd9`, `6cd73a9`, `0ff0b54`, `539d164`, `ccc86d7` | vistas 05–08 e 14 |
| 5 | Céu incoerente e relva estourada | `e4eea14` | `3bba3c8`, `656c4fe`, `7c8e96d` | 8 vistas do centro; branco estourado medido (`a942143`) |
| 6 | Vegetação de um só carimbo | `e4eea14` | `b52d3d1`, `dd80cd9`, `a23bb54`, `7c8e96d`, `0ff0b54` | vistas 02–04, 09–12 |
| 7 | Relva com carecas e vento em gelatina | `0ff0b54` | `40efd29`, `7c8e96d`, `a23bb54` | imagens `_MOVIMENTO-2s` das vistas 01 e 13 |
| 8 | Relevo ilegível | `ccc86d7` | `1e68bf8`, `40efd29`, `539d164`, `508b424` | vistas 05, 07, 08, 14 |
| 9 | Fundação da grelha | `0ff0b54` | `1e68bf8`, `3a0cf3a`, `6aaac6d` | `provar_altura.gd` (`cb6b2cf`) |
| 10 | Desempenho por provar | `a942143` | `7c8e96d`, `a23bb54`, `0ff0b54`, `16b689b` | `capturas/medicao.json` |
| 11 | Higiene | `cc23522` | `9820276`, `0ff0b54`, `461a9e7` | cena em headless: 0 erros |

«Fechado em» é o último commit que mexeu no defeito. De `1e68bf8` a `0ff0b54` a cena não abria
(a fundação estava a ser trocada): nada do que entrou antes de `0ff0b54` foi visto em render antes
dele.

### 1. Vistas para fora (09–12)
Os troncos-impostores saíram. Para lá da orla rica há um anel de 720 árvores INTEIRAS das mesmas
famílias (tronco, copa e pé), plantadas no MESMO chão — a zona larga do terreno, que vai até
88 m para lá da arena e derrete na cor do horizonte — e, atrás, duas silhuetas fechadas e a serra.
**Visto:** as quatro vistas para fora lêem-se como floresta a continuar; nenhum tronco sem copa,
nenhum pé no ar, nenhuma falha de céu. **Medido:** `provar_costura.gd` — desvio à cor do horizonte
0/255 nos 4 rumos, maior degrau entre amostras 3/255, saída 0.

### 2. Árvore Ancestral
Geometria opaca com cor própria e luz do mapa, a 580 m, azimute −7° (norte), sobre um outeiro com
mar de copas e sombra de contacto. **Medido na malha:** cimo a 259,8 m (alvo 260), 412,3 m de
largura, 42 pagodes e **0 no ar** (se algum ficar sem apoio a cena dá o erro `FLORESTA-E15`),
92 317 triângulos (folha 57 720 · madeira 17 069 · construção 15 368 · luz 2 160).
**Visto:** nas vistas 01, 13, 07, 15 e 18 (legível de norte, de sueste e das diagonais); as 4 faces
com o enquadramento das referências estão em `capturas/ancestral`; o lado a lado com as 5
referências fica em `capturas/_lado-a-lado` (pasta ignorada: as referências não entram no
repositório). O que o lado a lado ainda mostra de diferente está em «O que falta conferir».

**O filme** — `C:\Users\txcga\fable-mapa\filme-arvore-nova.avi` (fora do repositório, nunca commitado):

| | Medido no ficheiro |
|---|---|
| Tamanho | **245 808 330 bytes** (245,8 MB; 234,4 MiB) |
| Duração | **32,00 s** — 960 quadros a 30 q/s |
| Imagem | 1920 × 1080, MJPEG (JPEG a 90 %; quadro médio 256 kB, de 204 a 297 kB) |
| Integridade | RIFF e índice (`idx1`) batem com o tamanho do ficheiro; 960 quadros no índice, 0 maus |
| Conteúdo | órbita inteira a começar na face norte (21 s) + aproximação ao palácio (8,5 s) + 2,5 s parado |

Foi gerado de novo na sucessão 4, a partir da ponta, com `ferramentas/filmar_ancestral.gd`
(25 s de render), e saiu **byte a byte igual** ao que a sucessão 3 tinha deixado às 11:34 dentro
do clone (`repo/filme-arvore-nova.avi`, ignorado pelo git) — ou seja, o filme das 11:34 já era o
da árvore corrigida. Quadros dos 0, 12 e 31,9 s vistos com os olhos. Ficam as duas cópias, iguais.

### 3. Monocromia verde-lima
Paleta por função (combate verde-ouro · cobertura verdes frios · fundo azul-esverdeado), saturação
contida, o ouro mistura-se na copa em vez de se somar. **Medido nas 18 vistas** (% dos píxeis):
o verde-lima da Ordem 37 (matiz 70–110°, saturação e valor > 0,55) ocupa **0,0–0,6 %** de cada
quadro (eram ~90 % segundo a bancada); verde-ouro 4,6–50,1 %; verdes frios 0,6–29,2 %; saturação
média dos verdes 0,39–0,49.

### 4. Repetição temática
Um marco e uma situação por quadrante: **NO** o outeiro dos menires · **NE** a cova do charco ·
**SE** o terraço do santuário (pagode e lanternas) · **SO** a garganta (tronco tombado e lombo de
rocha). Cada quadrante tem a sua família de árvores (carvalho · vidoeiro · pinheiro-manso · abeto).
O último acerto foi o forro dos telhados (`82fb97c`): visto de baixo, o santuário era só um aro
preto contra o céu. **Visto:** vistas 05–08 (um marco diferente em cada uma) e 14 (do alto).

### 5. Céu e relva estourada
Céu v3 cozido: um só gradiente e uma só hora nos 360°, sem estrelas; sol a −112°/31° (Ø 5,75°),
lua de dia menor (Ø 3,9°); a luz da arena vem do mesmo rumo que o sol pintado. Relva e hastes sem
somas de luz, com tecto de cor. **Medido:** branco estourado em 0,00–0,01 % dos píxeis em 14 das
18 vistas; as outras 4 são as que têm o disco do sol no quadro (04: 1,09 % · 17: 1,07 % ·
06: 0,65 % · 12: 0,14 %). **Visto:** a volta do centro (01–04, 15–18) tem a mesma hora em todos os
rumos. *Não repeti a medição dos discos:* `cozer_ceu.gd` regrava o PNG do céu; os diâmetros são os
da paleta e do commit `656c4fe`.

### 6. Vegetação de um só carimbo
4 famílias de árvore (guarda-sol, redonda, conífera, jovem), 268 árvores reais (24 na arena, 244
na orla); estrato intermédio com silhueta própria — 96 arbustos, 44 silvados, 240 fetos, 210
folhas-largas; tufos fino e largo; 1 408 espigas, 883 flores, 85 juncos; 118 rochas.

### 7. Relva e vento
Sementeira em grelha tremida: 44 590 tufos em 50 blocos de 25 m. Vento em onda que viaja (a fase
vem só da posição), ponta a desviar no máximo ~0,17 m (eram ~0,6 m). **Medido:** diferença média
de luma entre dois quadros a 2 s: 2,6–10,2/255 conforme a vista. **Visto:** nas imagens do
movimento acendem a relva e as copas; céu, pedras e troncos ficam pretos.

### 8. Relevo
Um marco de relevo por quadrante (outeiro +3,3 m · cova −2,6 m · terraço +3,6 m com escarpa,
rampas e encosta de relva pelas costas · garganta), luz pintada franca por vertente, oclusão de
contacto, clareira de sol a oés-sudoeste do outeiro. **Visto:** na vista 05 a encosta do outeiro
está ao sol com os menires recortados no céu; na 07 o santuário está em cima do terraço, com a
escarpa de rocha à esquerda; na 14 (do alto) lêem-se os quatro.

### 9. Fundação da grelha
Contrato mundo↔casa de 50 × 50 casas de 1,5 m (arena de 75 × 75 m), bloqueio e cobertura por casa,
API de ocupação com erros nomeados. UMA altura: a malha, a colisão e a consulta saem da mesma
grelha cozida e dos mesmos triângulos. **Medido (`provar_altura.gd`, headless, 6000 pontos —
2000 deles em cima da orla da arena, onde a Ordem 37 divergia até 1,4 m):** 0 raios falhados;
consulta − colisão: maior **0,00002 m** (na orla também 0,00002 m); malha − colisão: 75 264
vértices de face de cada lado, maior distância 0,00005 m. Passou (tolerância 1 cm).
Grelha escrita: 2 500 casas, 208 bloqueadas, 2 292 livres, **0 livres isoladas**, centro livre.

### 10. Desempenho (RTX 4060, 1920 × 1080, sem v-sync, 2 s por vista)
Contadores do motor lidos pela ferramenta de captura (`Viewport.get_render_info` e relógio) — não
o painel Profiler do editor.

| | Mínimo | Máximo |
|---|---|---|
| FPS | 1 280 (vista 14, do alto) | 2 887 (vista 12) |
| Triângulos por quadro | 300 mil (vista 12) | 1,20 milhões (vista 13) |
| Chamadas de desenho, cena inteira | 21 | 92 |
| Chamadas de desenho, só o fundo | 3 | 8 |
| Tufos de relva desenhados (de 44 590) | 24 321 | 34 113 |
| Triângulos que o LOD da relva poupa | 0 (vistas para fora) | 335 mil (vista 14: 1,52 → 1,19 milhões) |

Do centro (8 rumos): 1 463–1 827 FPS, 0,80–1,07 milhões de triângulos. Cantos a olhar para o
centro: 1 434–1 512 FPS, 1,01–1,13 milhões. Malhas: relva 802,6 mil triângulos · árvores 227,7 mil
· anel 167,6 mil · estrato 166,5 mil · Árvore Ancestral 92,3 mil · hastes 42,2 mil · terreno
37,5 mil · rochas 23,5 mil · outeiro da árvore 22,8 mil. Carga da cena: 1,5 s.

### 11. Higiene
Erros com nome (`FLORESTA-E01` … `E15`) e contagem — a cena fecha a carga com `erros: 0`; o mapa
do chão é cozido UMA vez (`mapa_chao_cozeduras: 1`) e carimbar depois é erro com nome; os ensaios
vão para `capturas/_ensaio` (ignorada pelo git) e as ferramentas instanciam a cena no seu próprio
SubViewport. Na sucessão 4 achei e corrigi uma ferramenta partida: `provar_costura.gd` pedia um nó
da Ordem 37 e ficava pendurada num erro de script (`cc23522`).

## As provas do fecho (corridas na sucessão 4)

| Prova | Resultado |
|---|---|
| A cena abre em headless (`--headless campo_floresta.tscn --quit-after 30`) | saída 0, **0 linhas de erro**, `erros: 0`, carga 1,5 s |
| `provar_altura.gd` (headless) | PASSOU — maior divergência 0,00002 m |
| `provar_costura.gd` (janela) | SEM COSTURA — desvio 0/255 |
| `filmar_ancestral.gd` | FILME OK — 960 quadros, 32,00 s, igual byte a byte ao das 11:34 |
| As 18 vistas, as 5 folhas, 2 só-fundo e 2 de movimento | vistas com os olhos; nenhum defeito novo |

Como repetir (a partir de `rascunhos/`):

```
godot --path cliente --headless res://mapa/floresta/campo_floresta.tscn --quit-after 30
godot --path cliente --headless -s res://mapa/floresta/ferramentas/provar_altura.gd
godot --path cliente --resolution 1280x720 -s res://mapa/floresta/ferramentas/provar_costura.gd
godot --path cliente --resolution 1920x1080 -s res://mapa/floresta/ferramentas/capturar_floresta.gd -- --jpg
godot --path cliente --headless -s res://mapa/floresta/ferramentas/folha_contacto.gd -- --pasta=capturas
godot --path cliente --resolution 1920x1080 -s res://mapa/floresta/ferramentas/provar_ancestral.gd -- --refs=C:/caminho/das/referencias
godot --path cliente --resolution 1920x1080 -s res://mapa/floresta/ferramentas/filmar_ancestral.gd -- --avi=C:/caminho/filme.avi
```

## Passagem

**O que mudou** (31 commits sobre `b4b8a79`, todos em `rascunhos/cliente/mapa/floresta/`)
- Sucessões 1–3: os 24 commits da tabela acima, até `6321e7a`.
- Sucessão 4 (este fecho), sem tocar na cena:
  - `cb6b2cf` — `provar_altura.gd` (escrita na sucessão 3, por commitar).
  - `16b689b` — a captura mede o LOD da relva e a cor do quadro (idem).
  - `cc23522` — `provar_costura.gd` volta a correr.
  - `d8f723a`, `61d41f5`, `a942143` — a volta final das capturas: 18 vistas (+ 2 só-fundo, 2 de
    movimento), 5 folhas de contacto e `medicao.json`.
  - este documento e uma nota no cimo de `NOTAS-MEDICAO.md` (que é da Ordem 37).

**Onde parou**
- Ordem fechada do meu lado: árvore de trabalho limpa, ramo empurrado sem `--force`; `main` e os
  outros ramos não foram tocados.
- O filme está em `C:\Users\txcga\fable-mapa\filme-arvore-nova.avi` (e a cópia igual dentro do
  clone, ignorada pelo git).
- A pasta `referencias-arvore-ancestral/` continua no clone, fora do repositório (acrescentei-a
  ao `.git/info/exclude` local, como o filme).

**Próximo passo**
1. Conferência do coordenador: o filme; depois `capturas/_folha_1.jpg` a `_folha_5.jpg`; depois
   o lado a lado em `capturas/_lado-a-lado`.
2. Medir no Redmi (exige exportar para Android) — ver o primeiro ponto abaixo.
3. Só depois a grelha jogável e a integração na arena, que não eram desta ordem.

**O que falta conferir** (o que os meus olhos e os números não fecham)
- **FPS no Redmi (≥ 45): não medido, e o risco cresceu.** As vistas cheias desenham agora
  0,8–1,2 milhões de triângulos por quadro (na Ordem 37 eram 0,55–0,74 milhões). O LOD da relva
  poupa no máximo 22 % de um quadro; árvores, estrato, anel e Árvore Ancestral não têm nível de
  detalhe. Os 1 280–2 887 FPS são de uma RTX 4060 e não provam o telemóvel.
- **A árvore contra a referência** (face norte, lado a lado): a copa do render é mais espessa e
  em blocos, com o forro escuro, onde a referência é rendilhada e clara; o palácio é mais pequeno
  e mais simples que o de ouro da referência; faltam as lianas e o verde sobre o tronco; o mar de
  copas do outeiro lê-se como seixos. A silhueta, as proporções, as raízes e os pagodes batem.
- **Vista 05:** a meia-encosta do outeiro tem relva rala — vê-se o chão pintado entre os tufos.
  Não é nova (a sucessão 3 conferiu esta vista), mas é o sítio onde «sem carecas» é discutível.
- **Só-fundo (tecla F):** com a arena escondida, a orla interior do chão largo aparece como riscos
  escuros finos ao nível dos olhos (`01_…_SO-FUNDO.jpg`, à esquerda e à direita). Com a arena à
  vista não os encontrei em nenhuma das 18 vistas.
- **Ficheiros mortos da Ordem 37** ainda no repositório, sem ninguém que os leia:
  `shaders/anel_perto.gdshader` e `ceu/ceu_floresta_v2.png`. Não os apaguei.
- **«Ensaio em cena irmã»:** não há cena irmã em ficheiro. A cena do produto continua a levar a
  legenda de medição (`mostrar_medicao`, ligada por omissão; as ferramentas desligam-na) e as
  teclas de bancada (1–9, F, L, M).
- **As 14 vistas da ordem são 18** — as 14 da Ordem 37 mais as 4 diagonais do centro que o fecho
  da 37 acrescentou.
- **`NOTAS-MEDICAO.md`** descreve a Ordem 37 (arena de 60 × 60 m, âncora de 96 m): os números
  estão ultrapassados por este documento; os comandos «como repetir a prova» continuam certos.
- **O filme** mostra só o céu, a árvore e o outeiro (a arena e os anéis escondem-se, como na
  prova das 4 faces): não prova como a árvore se vê de dentro do mapa — isso são as vistas 01 e 13.
