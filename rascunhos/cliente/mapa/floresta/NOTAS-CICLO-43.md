# Ordem 43 — o ciclo do dia e o vento do mundo · notas de medição

Ramo `fable/ciclo-43`, a partir de `254188c` (o ESTADO FINAL da Ordem 38). Godot 4.7.2.stable,
Compatibility, RTX 4060, 1920×1080, sem v-sync. Tudo é **apresentação**: nenhuma regra, custo
ou turno lê a hora nem o vento (conferido: fora de `mapa/floresta/` ninguém chama
`hora_do_mundo`, `vento_actual`, nem os grupos `relogio_mundo` / `vento_mundo`).

Os números desta nota saem de dois ficheiros, gravados pelas ferramentas (não à mão):

- `capturas/ciclo43/medicao_ciclo.json` — `ferramentas/filmar_dia.gd -- --horas` (com render);
- `capturas/ciclo43/curvas_ciclo_vento.json` — `ferramentas/provar_ciclo_vento.gd` (headless).

## As peças (onde vive cada coisa)

| peça | ficheiro | API |
|---|---|---|
| relógio do mundo | `ciclo_dia.gd` (grupo `relogio_mundo`) | `hora_do_mundo()` 0–24 contínua · `hora_texto()` · `fase()` · `estado()` · sinal `fase_mudou` |
| vento do mundo | `vento_mundo.gd` (grupo `vento_mundo`) | `vento_actual()` · `vento_em(pos)` · `vetor()` · `vetor_em(pos)` · `curva_do_dia(h)` (pura) |
| forno vivo das sombras | `sombras_floresta.gd` | repinta o mapa das sombras quando a luz roda mais de 0,04° |
| céu vivo | `shaders/ceu_ciclo.gdshader` + `ceu/ceu_camadas_v1.png` | um céu só, que muda (nunca troca de céu) |
| o vento nos shaders | `shaders/vento_floresta.gdshaderinc` | relva, hastes, copas, anel; e a copa da Árvore Ancestral (`ancestral.gdshader`) |
| a cena | `campo_floresta.gd` | `hora_do_mundo()`, `vento_actual()`, `vento_em(p)` também na raiz |

**A duração do dia, num só sítio:** `ciclo_dia.gd` → `DURACAO_DIA_S = 1440.0` (24 min reais por
dia: 1 min real = 1 h do mundo; 1 s real = 1 min do mundo). **Modo de prova:** `modo_prova = true`
(tecla **T** na cena) → o dia inteiro em `DURACAO_PROVA_S = 96 s`. Teclas: **P** pára/anda o
relógio · **,** e **.** recuam/avançam 1 hora. O mundo abre às 16:15 (a tarde da Ordem 38).

## Parte A — o ciclo do dia

### Os astros (números de `curvas_ciclo_vento.json → transicoes`)

| | nasce | culmina | põe-se |
|---|---|---|---|
| sol | 06:00, az 77,9° (és-nordeste) | 12:30, elev 61,5°, a sul | 19:00, az 282,1° (oés-noroeste) |
| lua (cheia, oposta) | 18:30, a leste | 00:30, elev 52,0°, a sul | 06:30, a oeste |

Latitude 38°, declinação do sol 9,5°, da lua 0°. A elevação e o azimute saem da hora por
trigonometria esférica (ângulo horário + declinação + latitude) — não há tabela de posições.

### As fases e os tempos de cada transição

Fases (por nome; mudam à elevação do sol): noite → madrugada **05:29** · madrugada → manhã
**06:31** · manhã → dia **08:34** · dia → tarde **16:27** · tarde → entardecer **18:30** ·
entardecer → noite **19:32**.

| passagem | de → a | horas do mundo | segundos reais (dia de 24 min) | no modo de prova |
|---|---|---|---|---|
| fim da noite (sol −18° → −6°) | 04:22 → 05:28 | 1,10 h | 66 s | 4,4 s |
| aurora (−6° → +6°): rosa/dourado, a luz passa da lua ao sol | 05:28 → 06:31 | 1,04 h | 62 s | 4,2 s |
| pôr do sol (+6° → −6°): laranja/vermelho, a luz passa do sol à lua | 18:29 → 19:32 | 1,04 h | 62 s | 4,2 s |
| cair da noite (−6° → −18°) | 19:32 → 20:38 | 1,10 h | 66 s | 4,4 s |

Luzes artificiais (as lanternas do santuário e as janelas dos pagodes da Árvore — **existem**
no mapa): acendem a meio às **19:07** e apagam a meio às **05:54** (`lume`, em degradé entre
sol a +1,5° e −4°).

### Continuidade (nada muda de um quadro para o outro)

`provar_ciclo_vento.gd` percorre o dia minuto a minuto e mede o maior salto de cada saída da
hora. Com o dia de 24 min, um minuto do mundo = 1 s real = 60 quadros a 60 q/s.

- **Defeito encontrado e fechado nesta sessão:** a luz-chave trocava da lua para o sol (e ao
  contrário) por um interruptor — a direcção da luz saltava ~180° num minuto do mundo (05:49 e
  19:12; distância entre vectores unitários **1,99** num passo). Agora a passagem é um peso
  contínuo (sol de −5° a −1°) e a direcção roda por cima (lua → zénite → sol): maior passo
  **0,214** (~12°/min do mundo, quando a luz directa está no mínimo).
- **Segundo defeito, também fechado:** a sombra da lua entrava em ~9 min do mundo; com a lua
  baixa a leste a sombra comprida da orla caía de repente na clareira (no timelapse: −6,4 e
  −4,8 níveis de luma em dois quadros às 05:37 e 19:22). Agora entra com o crepúsculo
  (sol −2,5° → −9°, ~35 min do mundo).
- O maior passo de cor que fica: `cor_luz` **0,056 por minuto do mundo**, às 05:57 — o sol a
  acender (energia 0 → 0,40 entre −1,5° e +2°, ~17 min do mundo). É uma rampa, não um degrau.

### As 10 capturas (o mesmo enquadramento: orla sul da clareira a olhar para norte)

`capturas/ciclo43/c43_HHhMM_fase.jpg`. Luma média do quadro inteiro (0–255), com o painel:

| hora | fase | luz de | sol (az, elev) | lua (az, elev) | luma média | % quase preto | FPS | chamadas |
|---|---|---|---|---|---|---|---|---|
| 05:30 | madrugada | lua | 73°, -5,7° | 261°, 11,8° | 38,7 | 10,2 | 1154 | 80 |
| 07:00 | manhã | sol | 87°, 11,7° | 275°, -5,9° | 75,3 | 0,3 | 1242 | 80 |
| 10:00 | dia | sol | 120°, 45,9° | 309°, -38,7° | 119,5 | 0,3 | 1252 | 80 |
| 13:00 | dia | sol | 195°, 60,7° | 12°, -51,4° | 122,7 | 0,3 | 1258 | 80 |
| 16:00 | dia | sol | 253°, 35,1° | 65°, -28,7° | 100,6 | 0,3 | 1263 | 80 |
| 18:30 | entardecer | sol | 278°, 5,8° | 90°, 0,0° | 61,8 | 0,4 | 1270 | 80 |
| 19:45 | noite | lua | 289°, -8,5° | 102°, 14,7° | 24,7 | 28,1 | 1224 | 80 |
| 22:00 | noite | lua | 316°, -31,0° | 129°, 38,7° | 35,1 | 33,1 | 1223 | 80 |
| 01:00 | noite | lua | 10°, -42,0° | 192°, 51,4° | 38,8 | 34,5 | 1182 | 80 |
| 04:00 | noite | lua | 57°, -21,8° | 245°, 28,7° | 28,8 | 36,5 | 1184 | 80 |

(«quase preto» conta o céu nocturno e o painel; a cena em si nunca vai a preto.)

O que se vê nelas: madrugada rosa/violeta com a lua a pôr-se a oeste; manhã dourada baixa;
meio-dia branco e alto (0,28–0,32 % de píxeis estourados — é o disco do sol e as letras do
painel); fim de tarde laranja/vermelho no horizonte; noite azul-escura ao luar, com as janelas
dos pagodes acesas — a clareira e a Árvore lêem-se sempre. **19:45 é o quadro mais escuro**: a
lua ainda está baixa (14,7°) a leste e a sombra da orla cobre a frente da clareira; a Árvore, as
lanternas e o fundo da clareira lêem-se. É a física certa; se o Mestre a quiser mais clara, o
botão é `lua_baixa` em `ciclo_dia.gd` (hoje 1,35× a 8°).

### FPS e chamadas por fase

80 chamadas de desenho visíveis em **todas** as horas (81 no servidor), 1,197 milhões de
primitivas. FPS sem v-sync: dia ~1240–1265 · entardecer ~1228 · noite ~1185–1230. O forno das
sombras pinta 12 vezes em 2 s ao ritmo do jogo; no pior caso (modo de prova, o dia em 96 s) pinta
quase todos os quadros (263 em 3 s) e a cena fica a **~1217 FPS**. As **estrelas** (1 sorteio por
píxel no shader do céu, sem textura) não têm custo que se meça: a noite e o dia diferem em <5 %
de FPS e o céu não acrescenta chamadas. A luz da lua (DirectionalLight3D) tem sombra ligada para
as figuras do jogo; o mapa é todo pintado (unshaded) e as suas sombras de luar vêm do forno —
0 chamadas de sombra medidas.

## Parte B — o vento do mundo

### A curva (força por hora, com rajadas a correr 120 s em tempo real a cada hora)

`força 1 = 7,5 m/s = 27 km/h`. «Rajadas fortes» = subidas acima de 1,2 × a força média da
hora (com histerese); por baixo delas há a ondulação contínua de duas escalas de ruído.

| hora | força-base | sopra de | km/h mín · média · máx | rajadas fortes em 120 s | intervalo entre elas (mín · médio · máx, s) | desvio da direcção (dp · máx) |
|---|---|---|---|---|---|---|
| 00:00 | 0,20 | NNE (028°) | 4,5 · 8,4 · 12,1 | 5 | 5,5 · 15,3 · 28,1 | 4,8° · 11,3° |
| 01:00 | 0,19 | NE (044°) | 4,5 · 8,2 · 11,3 | 7 | 7,0 · 12,1 · 23,3 | 6,0° · 12,9° |
| 02:00 | 0,17 | ENE (057°) | 4,5 · 7,8 · 10,6 | 3 | 33,4 · 33,5 · 33,7 | 6,3° · 15,0° |
| 03:00 | 0,16 | ENE (066°) | 4,8 · 7,3 · 9,8 | 5 | 15,4 · 21,6 · 40,0 | 4,9° · 9,9° |
| 04:00 | 0,13 | ENE (076°) | 3,5 · 5,9 · 8,4 | 8 | 7,1 · 16,5 · 35,1 | 6,2° · 15,9° |
| 05:00 | 0,09 | E (091°) | 2,6 · 4,2 · 5,9 | 6 | 8,3 · 19,5 · 38,5 | 4,3° · 9,2° |
| 06:00 | 0,10 | ESE (111°) | 2,8 · 4,5 · 6,4 | 6 | 6,0 · 15,7 · 23,5 | 5,5° · 13,3° |
| 07:00 | 0,14 | SE (136°) | 3,6 · 6,5 · 9,0 | 5 | 16,7 · 25,9 · 44,5 | 6,0° · 18,6° |
| 08:00 | 0,25 | SSE (162°) | 6,2 · 11,0 · 15,2 | 6 | 10,9 · 20,3 · 27,3 | 5,4° · 13,9° |
| 09:00 | 0,36 | S (184°) | 8,6 · 14,7 · 20,1 | 5 | 10,1 · 19,0 · 37,7 | 5,3° · 13,0° |
| 10:00 | 0,48 | SSO (201°) | 13,5 · 19,7 · 26,5 | 4 | 23,5 · 26,7 · 31,5 | 4,8° · 11,0° |
| 11:00 | 0,60 | SSO (213°) | 14,2 · 22,2 · 30,8 | 5 | 14,5 · 16,3 · 18,3 | 3,5° · 9,3° |
| 12:00 | 0,71 | SO (224°) | 15,2 · 25,7 · 34,4 | 4 | 13,0 · 21,1 · 34,7 | 4,9° · 11,9° |
| 13:00 | 0,82 | OSO (237°) | 17,3 · 27,2 · 38,5 | 3 | 24,8 · 29,9 · 34,9 | 3,1° · 7,3° |
| 14:00 | 0,88 | OSO (255°) | 20,2 · 29,0 · 40,0 | 6 | 8,5 · 19,6 · 42,7 | 3,5° · 8,7° |
| 15:00 | 0,98 | O (276°) | 19,7 · 33,2 · 42,5 | 4 | 12,5 · 24,4 · 34,3 | 4,0° · 9,3° |
| 16:00 | 0,96 | ONO (296°) | 20,2 · 29,7 · 41,6 | 1 | — | 3,0° · 7,2° |
| 17:00 | 0,86 | NO (311°) | 18,1 · 28,4 · 38,3 | 4 | 12,0 · 19,5 · 26,3 | 3,7° · 7,9° |
| 18:00 | 0,61 | NO (321°) | 14,6 · 23,1 · 31,1 | 7 | 8,1 · 16,5 · 22,5 | 4,8° · 16,0° |
| 19:00 | 0,46 | NO (326°) | 9,6 · 17,4 · 24,9 | 5 | 7,7 · 19,6 · 34,6 | 5,0° · 13,8° |
| 20:00 | 0,27 | NNO (330°) | 6,2 · 11,0 · 15,9 | 5 | 11,1 · 21,4 · 32,1 | 4,5° · 11,7° |
| 21:00 | 0,24 | NNO (338°) | 5,9 · 10,3 · 14,2 | 6 | 8,2 · 16,9 · 33,8 | 5,6° · 13,2° |
| 22:00 | 0,20 | N (351°) | 5,0 · 8,4 · 11,7 | 3 | 17,1 · 21,4 · 25,7 | 5,2° · 12,2° |
| 23:00 | 0,20 | N (009°) | 4,7 · 8,2 · 12,1 | 4 | 12,8 · 17,5 · 24,6 | 3,2° · 7,0° |

### A deriva da direcção

A direcção RODA sempre no mesmo sentido (o dos ponteiros, como o sol — a volta da brisa):
**360° em 24 h**, fechando sem salto à meia-noite. Graus por hora, das 00h às 23h:

`16,5 · 12,3 · 9,4 · 10,0 · 14,4 · 20,4 · 25,0 · 25,7 · 22,3 · 16,8 · 12,2 · 11,0 · 13,5 · 17,7 · 20,6 · 20,0 · 15,6 · 9,6 · 5,0 · 4,3 · 7,7 · 13,2 · 17,8 · 19,0`

Maior passo num minuto do mundo: **0,44°**. Por cima da deriva, cada rajada traz um desvio
breve (desvio-padrão 3–6°, máximo 7–19° por hora; mais de noite, com o vento fraco e irregular).

### A física (resumo; o pormenor está no cabeçalho de `vento_mundo.gd`)

- **Inércia:** força e direcção seguem o alvo com atraso (rajada sobe em 0,5 s, morre em 1,6 s;
  a direcção em 1,3 s).
- **Advecção:** o campo de rajadas (o ruído do mundo) é levado pelo vento a 0,42 × a velocidade:
  vê-se a rajada a atravessar a clareira.
- **Pressão:** a dobra da vegetação ∝ v² e satura (`v²/(v²+0,9)`) — a lâmina deita-se, não estica.
- **Fases integradas:** as ondas e o tremor correm mais depressa com mais vento; com calma quase
  param.
- **Um vento só:** relva, hastes, copas, anel de floresta e a copa da Árvore Ancestral recebem os
  MESMOS uniforms (`vento_dir`, `vento_v`, `vento_desloc`, `vento_fase`, `vento_tremor`) — o vento
  próprio que a relva tinha na Ordem 38 deixou de existir. (A água continua com a sua ondulação
  própria em TIME — não é vento, é a ruga da superfície.)

### Para o clima (Ordem 40/41 — noutro ramo; NÃO se fez merge)

Como o módulo do clima deve amostrar o vento:

```gdscript
var vento := get_tree().get_first_node_in_group("vento_mundo")
# uma vez por quadro, para a inclinação geral da chuva / neve:
var v: Vector3 = vento.vetor()          # m/s no plano do chão (x leste, z sul), rajada incluída
# por emissor ou por célula (se quiser a rajada local — é o MESMO campo que a relva mostra):
var v_local: Vector3 = vento.vetor_em(posicao)
# inclinação: a gota cai a vq (chuva ~6–9 m/s, neve ~1 m/s); a direcção da queda é
#   normalize(Vector3(v.x, -vq, v.z))  — a neve deita-se muito mais do que a chuva.
```

- Ler **uma vez por quadro**; não guardar o dicionário entre quadros.
- `vento_actual()["rajada"]` (0–1) serve para modular a densidade/agitação das partículas.
- `curva_do_dia(h)` é pura (estática): dá a força-base e o rumo de qualquer hora sem precisar
  do nó (para pré-cálculos).
- Se o nó não existir (cena sem o mapa), usar vento nulo — o clima não deve depender dele.

## Os vídeos

Os filmes ficam **fora do repositório** (como o filme da Ordem 38; o do vento passa os 100 MB do
GitHub), em `C:\Users\txcga\fable-ciclo\filmes\`:

| filme | o quê | ficheiro | sha256 |
|---|---|---|---|
| (a) um dia completo | 05:00 → 07:00 do dia seguinte (26 h) em **65,0 s**, 1950 quadros a 30 q/s, 1920×1080 H.264 (1 s de filme = 24 min do mundo); câmara fixa na clareira a olhar para norte; a hora, a fase, o sol e a lua (az/elev), o vento e o encaixe «o céu por cima da clareira» (câmara ao zénite, norte em cima) escritos no ecrã | `ordem43_dia.mp4` (89 166 838 bytes) | `84b05ebb…325da589` |
| (b) o vento | 05:00 → 05:00 (24 h) em **120,0 s**, 3600 quadros; as horas a 720×, mas **as rajadas em tempo real**; câmara à altura dos olhos sobre o relvado; a hora, o rumo (de onde sopra), a força, km/h, a rajada, a rosa do vento e o gráfico da força dos últimos 20 s (com a curva do dia por baixo) | `ordem43_vento.mp4` (162 140 495 bytes) | `7fa94e5d…736ab71b` |

Refazem-se com (na pasta `rascunhos/cliente`):

```
godot --path . --resolution 1920x1080 -s res://mapa/floresta/ferramentas/filmar_dia.gd -- --dia   --quadros=<pasta>/dia
godot --path . --resolution 1920x1080 -s res://mapa/floresta/ferramentas/filmar_dia.gd -- --vento --quadros=<pasta>/vento
ffmpeg -framerate 30 -i q%05d.jpg -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -movflags +faststart filme.mp4
```

O relógio e o vento ficam parados e são avançados quadro a quadro pela ferramenta: o filme sai
igual seja qual for a velocidade da máquina. Os registos (hora, força, rumo, rajada, 1 amostra por
segundo de filme) estão em `capturas/ciclo43/registo_dia.json` e `registo_vento.json`. As folhas
de contacto estão em `capturas/ciclo43/_folha_filme_dia.jpg`, `_folha_filme_vento.jpg` e
`_folha_horas.jpg` (as 10 capturas).

**Vistos com os olhos nesta sessão (folhas de contacto, quadros soltos e 1 quadro de cada MP4):**
o sol nasce a leste às 06:00, sobe, culmina a sul e põe-se a oeste às 19:00, e no encaixe vê-se o
disco a atravessar o céu. A lua nasce a leste quando o sol se põe e atravessa a noite. As sombras
das árvores rodam e alongam (curtas às 13:00, compridas pela clareira às 16:00–17:00). A noite
lê-se azul, com a Árvore e as janelas acesas; a madrugada é rosa e o pôr do sol laranja/vermelho.
No filme do vento a relva deita-se forte à tarde e quase pára de madrugada, e a rosa do vento roda
com as horas. **Os MP4 não foram vistos a correr de ponta a ponta num leitor**: foram vistos pelos
quadros (as folhas cobrem cada 2 h do dia) e pelas medidas abaixo.

**Medido nos quadros** (ferramentas em `C:\Users\txcga\fable-ciclo\ferr\`, fora do repositório):

- *saltos*: a diferença média entre quadros seguidos, só na cena (sem o painel). No filme do dia,
  média **0,69**, p99 **2,62**, máximo **3,59** níveis (0–255). Antes da correcção da sombra da lua
  o máximo era 6,42 (05:37 e 19:22); agora os maiores saltos estão ao nível do movimento da relva
  ao vento a meio da tarde (3,1). Nenhum degrau.
- *o vento vê-se*: o movimento da relva (diferença em 5 quadros, normalizada pelo brilho) contra a
  força registada dá correlação **0,71 de dia** (08–18 h). Movimento médio por força:
  0,3–0,6 → 1,4 % · 0,6–0,9 → 3,0 % · 0,9–1,2 → 4,3 % · ≥ 1,2 → 6,4 %. De noite e de madrugada a
  medida é baralhada pela luz a mudar a 720× e pelo ruído do JPEG nos quadros escuros: no dia
  inteiro a correlação é só 0,35. Fica dito, não escondido.

## O que ficou por fazer

- O olho do Mestre e a bancada: nenhuma destas notas aprova nada.
- A lua é sempre cheia (oposta ao sol). Fases da lua não entraram (não foram pedidas).
- O dia não tem estações: a declinação do sol é fixa (9,5°).
- A luz-chave, na passagem lua↔sol, roda pelo zénite durante ~20 min do mundo com a luz directa
  no mínimo. Nos vídeos não se vê; com figuras de jogo no meio da clareira, merece um olhar.
- As figuras do jogo (personagens) ainda não existem neste mapa: a DirectionalLight do sol e a da
  lua estão prontas para elas, mas não foram vistas a iluminar figuras.
