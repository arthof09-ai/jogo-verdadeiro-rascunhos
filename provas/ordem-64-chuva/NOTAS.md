# Ordem 64 — a chuva na arena integrada (notas)

Linha `fable/integracao-50`, no clone principal `C:\Users\txcga\fable-mapa\repo`. Só apresentação.

## Nota 1 — a base e o ponto de partida (2026-11-15)

- **Base conferida:** `HEAD` = `8e530b7` (`8e530b7cb5aed0cc1e8c1a154eda7cc99d6792ce`), igual a
  `origin/fable/integracao-50` depois do fetch. A árvore só mostra o `mesa-mestre.json` modificado, que é o
  artefacto CRLF conhecido. Não é trabalho desta ordem e não entra em commit.
- **Modelo:** a ordem pede `claude-fable-5-2`, mas esta sessão corre em **Claude Opus 5.5**
  (`claude-opus-5-5`). Fica escrito aqui para o coordenador decidir se o trabalho conta.
- **Disco:** C: com 1,4 GB livres ao começar. Por isso os vídeos são curtos e leves.
- **A Ordem 40 já está na linha.** `fable/clima-40` (`cd94361`) e `fable/clima-41-expansao` (`c167f52`) são
  ancestrais da linha. O módulo `arte/clima/` (chuva, salpicos, chão molhado, figuras molhadas, contagens
  por perfil, intensidades sem reiniciar) já existe. A Ordem 42 (parte 2) já o ligou ao mapa integrado
  (`CampoDaMesa.ligar_clima`, nas duas arenas). Não houve nada a transplantar à mão: o transplante já estava
  feito, e a falta era outra.
- **O que faltava (a frente desta ordem):** o ponto 3 do `ESTADO-FINAL-ORDEM-57.md`, «Dois ventos». O clima
  caía com um vento seu (`definir_vento`, 20° e 2,5 m/s, com rajadas sintéticas). Ao mesmo tempo, o vento do
  mundo da Ordem 43 (`vento_mundo.gd`) dobrava a relva e as copas para outro lado e rodava com o dia.

## Nota 2 — a chuva com o vento do mundo, provada em vídeo (2026-11-15)

### O que mudou no código (só apresentação)

- `rascunhos/cliente/arte/clima/clima.gd`: nova **fonte do vento**.
  - `seguir_vento(fonte, tipos = ["chuva"])` liga os tipos da lista a um nó com `vetor() -> Vector3`. É o vento
    do mundo do mapa: m/s no chão, x leste, z sul, os mesmos eixos do clima.
  - Para esses tipos, `vento_do_frame(tipo)` devolve o vento do mundo desse quadro. É lido uma vez por quadro
    e integrado frame a frame pelo mesmo integrador da Ordem 40: quando o vento roda ou dá uma rajada, a chuva
    segue-o sem saltar.
  - As rajadas sintéticas do módulo não se somam por cima, porque as do mundo já lá vêm. A chuva também não
    herda as rajadas da nevasca que ainda se está a deitar. Isto apareceu no `pecas_mestre`, que corre a neve
    forte antes da chuva, e foi corrigido.
  - Sem fonte, com a fonte apagada ou com uma fonte sem `vetor()`, volta o vento manual (`definir_vento`).
    É o que a bancada sem mapa e os testes usam.
- `rascunhos/cliente/cenas/arena/campo_da_mesa.gd`: `ligar_clima` liga a fonte. É o caminho comum às duas
  arenas, a da jogadora e a do Mestre. A lista `TIPOS_COM_VENTO_DO_MUNDO = ["chuva"]` fica numa constante.
- **Extensível para a neve:** a neve continua no vento manual, como estava. Para a frente da neve se ligar,
  basta pôr `"neve"` nessa lista. As rajadas da nevasca somam-se então por cima do vento do mundo. Não toquei
  na neve.
- `arte/clima/README.md`: secção «A fonte do vento (Ordem 64)».
- Testes headless (correm no CI):
  - `rodar_testes.gd` `_teste_chuva_vento_do_mundo`: 10 verificações, com o `vento_mundo.gd` verdadeiro.
    Em 90 de 90 quadros a gota anda com o vento do mundo desse quadro. O vento roda 90° e a chuva roda com
    ele. A fonte apagada devolve o vento manual, sem erro. A neve fica no manual.
  - `pecas_mestre.gd`: 2 verificações na arena do Mestre, com o mapa. A chuva segue `mapa.vento` e o vento
    dela é o do mundo nesse quadro.
- A ferramenta de prova com render: `rascunhos/cliente/cenas/arena/ferramentas/chuva_no_mapa.gd`
  (modos `fraca`, `forte`, `comutar`, `fotos`, `medir`). O leitor dos vídeos que tira as folhas é
  `ferramentas/folha.gd` (corre fora do projecto, com `-s`).

### O que foi transplantado da Ordem 40 e o que ficou para trás

- **Veio inteiro, sem mudança (já estava na linha):**
  - as gotas (MultiMesh, risco esticado ao longo da velocidade do quadro);
  - os salpicos no Médio e no Alto;
  - a camada do chão: molhado com reflexo, poças e anéis dos pingos; na forte, as bolsas de água e a lama
    nas bacias reais do relevo (Ordem 42);
  - a camada das figuras: brilho de molhado;
  - as contagens por perfil;
  - as intensidades fraca e forte, comutáveis sem reiniciar;
  - a ligação ao perfil gráfico (`CampoDaMesa.ligar_perfil`).
- **Ficou para trás:**
  - o vento próprio do clima, para a chuva. Era o «segundo sistema de vento» que a ordem proíbe. Fica como
    vento de recurso, só para as cenas sem mapa.
  - a bancada `testes/video_clima.gd` da Ordem 40, que filma a arena antiga num chão liso. A prova desta
    ordem é a `chuva_no_mapa.gd`, sobre a arena integrada, com o mapa da floresta.
- **Não houve código a portar** do ramo `fable/clima-40`, porque ele já é ancestral da linha. A Ordem 42
  fez a ligação ao mapa.

### Os vídeos (a prova principal)

Formato: `.ogv` (Theora), gravados pelo próprio Godot (`--write-movie`, 30 q/s certos, 1920×1080). Este PC
não tem ffmpeg, por isso não há mp4. A qualidade é 0,4, posta por um `override.cfg` temporário, apagado
logo a seguir. Perfil Alto, arena da jogadora, às 16:15 do mundo.

| Vídeo | Duração | Tamanho | O que mostra |
| --- | --- | --- | --- |
| `videos/chuva-fraca.ogv` | 23 s | 5,0 MB | Seco (câmara do jogo) → fraca liga aos 1,5 s → de lado para o vento (8 s) → rasante perto das figuras (14 s) → câmara do jogo (19 s). 2400 gotas + 200 salpicos. Molhado chega a ~0,9. |
| `videos/chuva-forte.ogv` | 23 s | 10,8 MB | O mesmo guião com a forte. 8000 gotas + 600 salpicos. Encharca aos ~10 s e as bolsas começam a alagar (água 0,37 aos 21 s). |
| `videos/chuva-comutacao.ogv` | 19 s | 5,4 MB | De lado para o vento, sem reiniciar: seco → fraca (1 s) → forte (6 s) → fraca (11 s) → desligada (15 s). As gotas saem e o chão fica molhado. |

- A etiqueta mostra o tempo, o perfil, as gotas e os salpicos, o vento do mundo (rumo, m/s, rajada), o vento
  da chuva (igual), a inclinação e o molhado.
- A **seta amarela** desenhada no chão é o vento do mundo (o `vetor()` desse quadro).
- Nos planos «de lado» a câmara 360 põe-se perpendicular ao vento do mundo, que vai para a direita do ecrã.
  A inclinação da chuva vê-se assim inteira.
- Os registos por meio segundo estão em `medicao/chuva_*_medicao.json`: vento do mundo, vento da chuva,
  molhado, água e contagens. Em **todas as amostras o vento da chuva é igual ao do mundo**, por exemplo na
  forte: (8,03; 4,27) → (9,75; 4,20) → (6,99; 3,64) → (4,98; 3,48) m/s.

#### O que vi com os olhos (quadros tirados dos próprios `.ogv`, folhas em `folhas/`)

- **A chuva inclina com o vento.** Nos planos rasantes, os riscos caem em «\\», de cima-esquerda para
  baixo-direita: andam para a direita enquanto caem, no sentido da seta. A inclinação medida é ~30° na
  forte e ~38° na fraca, com 8,6 m/s.
  - Na câmara do jogo, de cima, a fraca lê-se pouco: os riscos são finos e a compressão come parte deles.
  - A forte lê-se nos três planos.
- **O chão responde.**
  - Na câmara do jogo escurece, ganha manchas de reflexo acinzentado e os anéis dos pingos. Na forte, a
    seguir, nascem bolsas de água nas covas do relevo (canto esquerdo, aos 22 s).
  - De perto vêem-se os anéis a bater e o chão a brilhar.
  - Depois de desligada a chuva, o chão continua molhado (`capturas/chao-2-*`).
- **As figuras** ganham um brilho especular de molhado (visível no rasante) e continuam a ler-se: cor, nome
  e sombra.
- **A grelha e as casas do Mover** (azuis, com a casa da figura a amarelo) lêem-se em todos os planos, com
  chuva fraca e forte.
- **A chuva cobre o campo inteiro.** A caixa do clima é o campo mais 4 m de folga; na câmara do jogo há
  gotas e molhado de ponta a ponta.
- **Não vi o vídeo a correr num leitor.** Vi quadros tirados dos `.ogv` pelo `folha.gd`, que lê o próprio
  ficheiro: três folhas de 9 quadros e três quadros inteiros. A prova final do movimento é do Mestre, a ver
  os vídeos.

### Capturas (antes/depois do chão molhado), `capturas/`

São seis JPG a 1028×749, o máximo que o ecrã deste PC dá à janela: `chao-0-seco_*` (antes),
`chao-1-molhado-a-chover_*` (10 s de forte) e `chao-2-molhado-sem-chuva_*` (a chuva parou e o chão continua
molhado). Cada uma existe em duas câmaras, a do jogo e a rasante.

### Partículas por intensidade e por perfil (as contagens do módulo, medidas no ecrã)

| | Baixo | Médio | Alto |
| --- | --- | --- | --- |
| Chuva fraca (gotas + salpicos) | 900 + 0 | 1600 + 120 | 2400 + 200 |
| Chuva forte (gotas + salpicos) | 2800 + 0 | 5000 + 350 | 8000 + 600 |

### Custo medido (`medicao/medicao-ordem64.json`)

Condições: RTX 4060, Godot 4.7.2, renderer Compatibility, sem vsync, janela 1028×749 (o ecrã não deixou
1920×1080), câmara do jogo, arena integrada com 5 figuras e as casas do Mover. Cada caso esperou 3 s pelo
regime e mediu 3 s. Corri tudo três vezes e a tabela dá a mediana; as três corridas estão no JSON. DC = draw
calls do quadro.

| Perfil | Sem chuva | Chuva fraca | Chuva forte |
| --- | --- | --- | --- |
| Baixo | 120 DC · 0,84 ms (~1190 FPS) | 135 DC · 0,95 ms (~1060 FPS) | 135 DC · 1,31 ms (~760 FPS) |
| Médio | 125 DC · 0,94 ms (~1070 FPS) | 141 DC · 1,27 ms (~790 FPS) | 141 DC · 1,55 ms (~650 FPS) |
| Alto | 125 DC · 1,09 ms (~920 FPS) | 141 DC · 1,46 ms (~690 FPS) | 141 DC · 1,38 ms (~720 FPS) |

- A chuva custa **+15 DC no Baixo e +16 no Médio/Alto**, igual nas três corridas. São as nuvens e,
  sobretudo, as camadas `material_overlay` do chão do mapa, dos obstáculos e das figuras.
- Na Ordem 41, numa bancada lisa, eram +12/+13. O mapa tem mais malhas vestidas.
- As primitivas sobem ~110 mil, quase todas das camadas, que voltam a desenhar o terreno do mapa. As gotas
  são só 2 triângulos cada.
- O pior caso medido é Médio forte, a 1,55 ms (~650 FPS). Há ruído entre corridas (±0,3 ms; o relógio do
  mundo e o céu mudam a cada quadro). Por isso o Alto forte sai mais rápido do que o Alto fraca, e isso não
  é um resultado.
- **Não medido:** no telemóvel, no export web e a 1920×1080. Nesses casos conta o enchimento de píxeis das
  camadas transparentes.

### Suites (local, Godot 4.7.2, sobre o código desta ordem)

Passaram todas, sem `SCRIPT ERROR`:

- `abrir_scripts`
- `rodar_testes` 187/187 (eram 177)
- `clima_forte` 119/119
- `pecas_mestre` 286/286 (eram 284)
- `hud_acoes` 50/50
- `abrir_clareira` 22/22
- `abrir_mestre` 67/67
- `canario_privacidade` 10/10
- `medir_mestre`, `medir_painel_config`
- `provar_assentamento`, `provar_terreno_servidor`, `exportar_terreno --conferir` (EM DIA)
- `provar_molde_54`, `provar_mestre_no_relevo`, `provar_pes_bloqueadas`, `provar_recusa_no_ecra`
- o arranque («pronto»)

### O que ficou por fazer

1. **O olho do Mestre** sobre os três vídeos. Em particular, a chuva fraca vista de cima na câmara do jogo é
   discreta: lê-se o chão a molhar mais do que os riscos. Se o Mestre quiser os riscos mais visíveis de cima,
   isso é afinação do `chuva_gotas.gdshader` (largura e alfa), que não mexi.
2. **A neve no vento do mundo**: pôr `"neve"` em `CampoDaMesa.TIPOS_COM_VENTO_DO_MUNDO`. É da frente da neve
   e do coordenador. Com o vento da tarde (7–10 m/s) e a queda da neve a 1,2–1,8 m/s, a neve vai deitar-se
   quase horizontal: é preciso decidir se se escala.
3. **A rajada local** (`vento_mundo.vetor_em(pos)`, o mesmo campo que a relva mostra) não entra: a chuva usa
   o vento global do quadro, como a nota da Ordem 43 recomenda. Uma rajada por célula seria trabalho de shader.
4. **A chuva não mexe na luz, no céu nem na névoa**, como antes. O céu continua azul e com sol enquanto chove
   forte.
5. **Medição a 1920×1080, no telemóvel e no web.**
