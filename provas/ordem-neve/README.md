# Ordem Neve — provas das correcções (17/11/2026)

Provas refeitas depois da sentença da bancada (nota 560/1000). Foram feitas no PC do Mestre: NVIDIA GeForce RTX 4060 (driver 610.88),
Godot 4.7.2, renderer `gl_compatibility` (OpenGL 3.3). **Nenhuma imagem tem legendas nem rótulos de depuração**: o que se vê é o
jogo, com a HUD normal da jogadora. A janela dos retratos tem 1920×1398 (o tamanho que o Windows deu à janela; os recortes são fracções
do ecrã, iguais antes e depois). A medição da GPU corre numa janela fixa de 1920×1080.

## Como se fez (e porque não é circular)

- `rascunhos/cliente/cenas/arena/ferramentas/neve_no_mapa.gd` **só grava** as imagens. Nos retratos (`--modo=renders`) impõe F **uma vez**
  por retrato, porque é um retrato determinístico. A curva natural (`--modo=dinamica`) e a rajada (`--modo=rajada`) **não** impõem F
  quadro a quadro. Cada retrato sai em par: `nome.png` é a imagem tal como se vê; `nome_sem_flocos.png` é o mesmo instante, com o clima
  congelado e só as partículas escondidas.
- `rascunhos/cliente/cenas/arena/ferramentas/medir_pixeis_neve.gd` **só lê PNG** com `Image.get_pixel`. Não chama `neve_em()`, nem `fator_f()`,
  nem nenhuma função do clima. As definições (branco-neve, regiões, ladrilhos, floco) estão no topo do ficheiro e foram fixadas antes
  de haver números novos.
- O que o clima diz de si próprio fica gravado à parte, em `registo_*.json → declarado_pelo_sistema`, e não entra em conta nenhuma.
- **Antes / depois:** o "antes" foi gravado com o shader e o controlador de `39b3414` (a primeira execução), repostos por um momento,
  com a MESMA ferramenta e o MESMO medidor (`medicao/*_antes_39b3414.json`).

## Resultados (píxeis)

| | antes (39b3414) | depois |
|---|---|---|
| **1a — modulação do centro, t2 ao meio-dia** (desvio-padrão da luminância por ladrilho; p90−p10) | 0,046 · 0,126 | 0,054 · 0,148 |
| 1a — o mesmo às 16:15 | 0,031 · 0,085 | 0,047 · 0,124 |
| 1a — cobertura branca do centro, t2 ao meio-dia | 0,914 | 0,874 (as zonas varridas são mais escuras: continua coberto) |
| **1b — contraste dos flocos no CENTRO, média de 6 instantes**: nevasca F=1 × neve fraca | 0,155 × 0,173 (a nevasca lia-se pior) | 0,208 × 0,185 |
| 1b — fracção de píxeis de floco no centro (6 instantes): nevasca × fraca | 0,019 × 0,008 | 0,062 × 0,010 |
| **1c — distância RGB da lagoa ao quadro sem neve da mesma hora**: fraca / t1 / t2 / 16:15 / noite | 0,159 / 0,199 / 0,201 / 0,254 / 0,149 | 0,005 / 0,004 / 0,004 / 0,006 / 0,002 |

As imagens: `renders/` (os 6 retratos, com flocos) e `renders/centro_t2_antes_depois.png`, que mostra o centro ampliado 2× (à esquerda o antes, à direita o depois).

### Curva natural (`medicao/medicao_pixeis_dinamica.json`, `dinamica/`)
O clima correu pelo seu `_process`, em tempo real, cronometrado pelo relógio de parede, sem F imposto: limpo de 0 a 5 s, nevasca de
5 a 115 s, chuva de 115 a 165 s e limpo de 165 a 215 s. Ao meio-dia, de 5 em 5 s, gravou-se um quadro sem partículas.
A cobertura branca do centro foi medida nos píxeis:
- a nevasca começa aos 5 s; o centro vai a 0,43 aos 20 s, a 0,75 aos 25 s e a 0,80 aos 30 s; chega ao patamar (0,87–0,88) aos 50 s;
- com a chuva (desde os 115 s), aguenta 0,82–0,85 até aos 130 s; cai para 0,72 aos 135 s e para 0,06 aos 140 s. **A queda medida
  pelo branco é mais brusca do que o factor F que o sistema declara** (0,29 → 0,13 no mesmo intervalo). Nos quadros, a relva volta a
  furar por manchas (`dinamica/dinamica_027.png`). Fica registado para o olho do Mestre;
- o chão molhado escurece (luminância 0,66 → 0,61) e seca de volta a 0,66 entre os 165 e os 205 s.

### Rajada (`medicao/medicao_pixeis_rajada.json`, `rajada/`)
A nevasca correu sozinha durante 24 s, com o vento do mundo livre e as rajadas do próprio sistema. Não houve teleporte de azimute nem
salto do relógio. Os pares com/sem flocos foram gravados de ~1 em ~1 s. Nas duas janelas de rajada (≈ 9–14 s e ≈ 21–23 s) os píxeis
mostram, sem consultar o sistema:
- a área de floco sobe de 0,029 para 0,039–0,045;
- o contraste por floco desce de 0,24 para 0,21–0,23 (os traços ficam mais longos e mais ténues);
- a coerência dos traços sobe de 0,001–0,011 para 0,010–0,040.

Em quadro parado a diferença é **subtil**: os flocos passam de pontos a pontos esticados (`rajada/centro_calma_rajada_rajada.png`).
A força visual fica ao juízo do Mestre.

## Custo na GPU (`medicao/registo_gpu.json`)
Medido na RTX 4060, janela 1920×1080, vsync desligado (`window_get_vsync_mode() = 0`; os fps passam muito os 165 Hz do monitor) e
`max_fps = 0`. Houve 8 s de aquecimento e cada caso correu 10 s, em duas voltas (a segunda em ordem inversa). O tempo de quadro foi
medido pelo relógio de parede.

| caso | ms/quadro (média · p95 · p99) | fps | render GPU (ms) |
|---|---|---|---|
| limpo, sem camada de clima | 1,653 · 1,714 · 2,312 | 605 | 1,587 |
| limpo, F=0 com a camada presa | 1,742 · 1,804 · 2,34 | 574 | 1,677 |
| neve fraca F=0,35, 3.000 flocos | 2,598 · 2,71 · 3,39 | 385 | 2,534 |
| nevasca F=1, só o chão (flocos escondidos) | 2,652 · 2,83 · 3,50 | 377 | 2,590 |
| **nevasca F=1, 9.000 flocos + chão** | **2,670 · 2,75 · 3,21** (2.ª volta 2,675) | **374** | 2,608 |

A nevasca cheia custa cerca de **+1,0 ms por quadro** nesta GPU. Desse custo, os 9.000 flocos são cerca de 0,02 ms; o resto é a neve no
chão e na vegetação. **Limitação:** só se mediu esta GPU de secretária. Telemóvel e WebGL 2 não foram medidos.
