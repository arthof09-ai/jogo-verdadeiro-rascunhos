# Ordem 64: a chuva na arena integrada (item 4 da fila visual, metade da chuva). ESTADO FINAL

*Fecho da ordem, 2026-11-15/16, Claude conta 2, uma só sessão. **Modelo: Claude Opus 5.5 (`claude-opus-5-5`), não
o `claude-fable-5-2` que a ordem pede**; fica escrito para o coordenador decidir se conta. Godot 4.7.2, RTX 4060,
neste PC. Trabalhei directamente na linha `fable/integracao-50`, partindo da ponta `8e530b7` (conferida com o
remoto antes de começar), no clone `fable-mapa/repo`. Não toquei na main, nos worktrees nem nos ramos da grama, da
água ou da neve, nem nos workflows. A `mesa-mestre.json` (o «M» do CRLF local) não entrou em commit nenhum. Os
registos brutos ficaram em `fable-mapa/_tmp/o64/`, fora do repositório.*

## Resumo

**A chuva da arena integrada cai agora com o vento do mundo**, o mesmo que dobra a relva e as copas (Ordem 43).
Antes caía com um vento seu, fixo, e era o ponto 3 («Dois ventos») do `ESTADO-FINAL-ORDEM-57.md`.

O resto da chuva já estava na linha: as gotas, os salpicos, o chão molhado, as figuras molhadas, as intensidades e
as contagens por perfil (Ordens 40 e 41), mais a ligação ao mapa (Ordem 42). Os ramos `fable/clima-40` e
`fable/clima-41-expansao` são ancestrais da linha, por isso não houve transplante de código, só a ligação ao vento.
A prova é feita em vídeo, sobre a arena integrada, com figuras, a grelha e as casas do Mover.

## O que mudou

| commit | o quê |
| --- | --- |
| `03824b9` | `arte/clima/clima.gd`: `seguir_vento(fonte, tipos)`, `fonte_do_vento()`, `segue_fonte(tipo)` e `vento_do_frame(tipo)`. O vento da fonte é lido uma vez por quadro e integrado frame a frame. As rajadas sintéticas não se somam, e a chuva não herda a nevasca. Sem fonte, fica o vento manual. `cenas/arena/campo_da_mesa.gd`: `ligar_clima` liga a fonte para `TIPOS_COM_VENTO_DO_MUNDO = ["chuva"]`, nas duas arenas. README do módulo. Testes: `rodar_testes` (+10) e `pecas_mestre` (+2). Nota 1. |
| `4b92dcf` | Listas da retoma e MANIFESTO. CI verde: runs `43789172659` (testes) e `43789172680` (sonda). |
| `d4bf8e6` | A ferramenta `cenas/arena/ferramentas/chuva_no_mapa.gd` e as provas em `provas/ordem-64-chuva/`: 3 vídeos, 6 capturas, 3 folhas, a medição e a nota 2. |
| `86af461` | Listas da retoma e MANIFESTO. |
| (este) | O ESTADO FINAL, com as listas num commit à parte. |

Todos os pushes foram feitos sem force, depois do fetch da linha: `8e530b7..4b92dcf` e `4b92dcf..86af461`.

## As provas (`provas/ordem-64-chuva/`)

- **Vídeos** (`.ogv` Theora, 1920×1080, 30 q/s, gravados pelo próprio Godot; este PC não tem ffmpeg):
  - `chuva-fraca.ogv`: 23 s, 5,0 MB;
  - `chuva-forte.ogv`: 23 s, 10,8 MB;
  - `chuva-comutacao.ogv`: 19 s, 5,4 MB (fraca → forte → fraca → desligada, sem reiniciar).

  Cada um mostra a câmara do jogo, um plano de lado para o vento e um rasante perto das figuras. A etiqueta
  mostra o vento do mundo e o vento da chuva, e a seta amarela no chão é o vento do mundo.
- **Capturas** do chão seco, molhado a chover e molhado depois da chuva, em duas câmaras.
- **Folhas de quadros**, tiradas dos próprios `.ogv` pelo `ferramentas/folha.gd`.
- **Medição** (`medicao/`): o custo por perfil (três corridas) e o registo por meio segundo do vento do mundo e
  do vento da chuva, que são iguais em todas as amostras.
- **NOTAS.md:** o que foi transplantado e o que ficou para trás, o que vi, a tabela das partículas e a do custo.

**Partículas:**

- fraca: 900 / 1600+120 / 2400+200;
- forte: 2800 / 5000+350 / 8000+600 (gotas + salpicos, Baixo / Médio / Alto).

**Custo:**

- a chuva acrescenta +15 draw calls no Baixo e +16 no Médio/Alto;
- o pior caso é Médio forte, com 1,55 ms por quadro (~650 FPS), contra 0,94 ms sem chuva;
- medido a 1028×749, porque o ecrã deste PC não deu 1920×1080.

**Suites locais** (sobre `d4bf8e6`): todas verdes e sem `SCRIPT ERROR`. `rodar_testes` 187/187, `pecas_mestre`
286/286, `clima_forte` 119/119, `abrir_scripts` 84 scripts 0 falhas, `hud_acoes` 50/50, `abrir_mestre` 67/67, mais
as `provar_*` e o arranque. A lista completa está nas NOTAS.

## O que vi com os olhos (nos quadros dos vídeos)

- A chuva cai em «\\» no sentido da seta do vento do mundo: inclina ~30° na forte e ~38° na fraca, com 8,6 m/s.
- O chão escurece, brilha e mostra os anéis dos pingos. Na forte, as bolsas de água nascem nas covas do relevo.
- As figuras brilham de molhado e continuam a ler-se.
- A grelha e as casas do Mover lêem-se com chuva fraca e forte.

A fraca, vista de cima na câmara do jogo, é discreta: lê-se mais o chão a molhar do que os riscos.

---

## ESTADO FINAL — Passagem

- **O que mudou:**
  - `03824b9`: a fonte do vento no `arte/clima/clima.gd`, a ligação no `cenas/arena/campo_da_mesa.gd`, o
    README do clima e os testes em `testes/rodar_testes.gd` e `testes/pecas_mestre.gd`.
  - `4b92dcf`: listas.
  - `d4bf8e6`: `cenas/arena/ferramentas/chuva_no_mapa.gd` e `provas/ordem-64-chuva/` (3 vídeos `.ogv`,
    6 capturas, 3 folhas, medição, NOTAS).
  - `86af461`: listas.
  - Depois deste ficheiro, o commit dele e o das listas.
  - Pushes sem force na `fable/integracao-50`: `8e530b7..4b92dcf` (CI verde, runs `43789172659`/`43789172680`)
    e `4b92dcf..86af461`. O resultado do último push e do CI da ponta está na mensagem final da sessão.
- **Onde parou:** a chuva funciona na arena integrada (jogadora e Mestre).
  - Segue o vento do mundo, liga e desliga, e troca fraca/forte sem reiniciar.
  - As contagens seguem o perfil gráfico.
  - Está provada em três vídeos vistos quadro a quadro, com as suites locais todas verdes.
  - A neve ficou como estava, no vento manual.
- **Próximo passo:**
  1. O Mestre vê os três `.ogv` e dá o veredicto. Se os riscos da fraca forem pouco visíveis de cima, é
     afinação do `chuva_gotas.gdshader` (largura e alfa).
  2. A frente da neve (ou o coordenador) liga a neve ao vento do mundo, pondo `"neve"` em
     `CampoDaMesa.TIPOS_COM_VENTO_DO_MUNDO`. Tem de decidir a escala, porque com 7–10 m/s a neve deita-se
     quase horizontal.
  3. Opcional: a rajada local (`vetor_em`) por célula e o céu e a luz a responderem à chuva.
- **O que falta conferir:**
  - o olho do Mestre sobre o movimento, a ver os vídeos a correr. Eu vi quadros tirados dos ficheiros, não um
    leitor;
  - o custo a 1920×1080, no telemóvel e no web;
  - o CI sobre a ponta final (ver a mensagem da sessão);
  - a chuva na arena do Mestre com render: está provada por teste headless (`pecas_mestre`) mas não filmada;
  - o modelo: esta sessão não correu no `claude-fable-5-2` pedido.
