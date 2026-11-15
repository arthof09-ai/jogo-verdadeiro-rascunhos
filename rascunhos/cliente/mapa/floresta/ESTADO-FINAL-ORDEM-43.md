# ESTADO FINAL — Ordem 43 (o vento com física e o ciclo completo do dia)

Ramo `fable/ciclo-43` (no remoto), a partir de `254188c` (o ESTADO FINAL da Ordem 38). Clone
próprio em `C:\Users\txcga\fable-ciclo\repo`. Nada tocado fora deste ramo nem fora de
`C:\Users\txcga\fable-ciclo\`. Sem merges (o ramo do clima não entrou).

**Quem fez:** sessão 1 (Fable 5.2, parou no limite às ~21:40 de 14/11 sem commitar) → sessão 2
(recolheu o trabalho: `35dc4de`; escreveu `filmar_dia.gd` e parou sem o commitar) → **sessão 3,
esta, a correr em Opus 5.5** (não em `claude-fable-5-2`: o lançador `launch43c2s.cmd` passou
`--model opus`, porque o limite do Fable se tinha esgotado — `ordem43-c2-out.txt`). Fica dito para
o coordenador decidir se isto conta.

As medidas, os números e as tabelas estão em `NOTAS-CICLO-43.md`.

## Prova corrida no fecho

- Cena em headless (`campo_floresta.tscn`, 300 quadros): **erros: 0**, carga 1448 ms, 2068
  lançadores de sombra.
- Com render (RTX 4060, Compatibility, 1920×1080): as 10 capturas, o filme do dia e o do vento
  correram sem erro nem aviso do mapa. FPS sem v-sync 1154–1270, **80 chamadas em todas as
  fases**; modo de prova (o dia em 96 s, o forno a repintar quase todos os quadros) 1214 FPS.
- `provar_ciclo_vento.gd` (headless): a curva do vento por hora, a deriva (360° em 24 h, maior
  passo 0,44°/min do mundo) e a continuidade (maior passo da direcção da luz 0,214 por minuto do
  mundo; era 1,99).

## ESTADO FINAL — Passagem

**O que mudou** (commits, do mais antigo ao mais novo):

- `35dc4de`: o trabalho das sessões 1–2. O relógio do mundo (`ciclo_dia.gd`), o vento do mundo
  (`vento_mundo.gd`), o forno vivo das sombras, o céu vivo, e os shaders ligados ao vento único.
- `c8b03ae`: `filmar_dia.gd`, a ferramenta da prova por render (sessão 2, commitada pela sessão 3).
- `927e505`: as 10 capturas etiquetadas e `medicao_ciclo.json`. Corrigidos 2 erros de análise na
  ferramenta (nunca tinha corrido) e o painel do vento (a rosa tapava a rajada). A lua baixa ganha
  até 1,35× de força e o céu do crepúsculo sobe um pouco.
- `a5391a5`: **defeito fechado** — a luz-chave trocava da lua para o sol por interruptor (a
  direcção saltava ~180° num minuto do mundo, às 05:49 e 19:12). Agora há um peso contínuo e a
  direcção roda por cima. Entra também `provar_ciclo_vento.gd`.
- `9841e68`: **defeito fechado** — a sombra da lua entrava em 9 min do mundo e escurecia a
  clareira de repente; agora entra com o crepúsculo, em ~35 min.
- `4a0219a`: o rascunho de `NOTAS-CICLO-43.md`; as capturas refeitas sobre a ponta; o enquadramento
  do filme do vento sai de dentro do tufo de relva.
- `91a3761`: a secção dos vídeos nas notas, os registos e as folhas de contacto.
- (este commit): `ESTADO-FINAL-ORDEM-43.md`.

**Onde parou:** tudo o que a ordem pede está feito e commitado, com o push feito (sem force).

- O ciclo e o vento correm na cena, sem erros, em headless e com render.
- Os dois vídeos estão em `C:\Users\txcga\fable-ciclo\filmes\`, fora do repositório (o do vento
  tem 162 MB, mais do que os 100 MB que o GitHub aceita):
  - `ordem43_dia.mp4` — 65,0 s, de 05:00 às 07:00 do dia seguinte;
  - `ordem43_vento.mp4` — 120,0 s, 24 h.
- As 10 capturas estão em `capturas/ciclo43/`, com as 3 folhas de contacto.
- As notas de medição estão em `NOTAS-CICLO-43.md`.

**Próximo passo:** a conferência do coordenador e do Mestre:

1. ver `capturas/ciclo43/_folha_horas.jpg` (as 10 horas), depois `_folha_filme_dia.jpg` e
   `_folha_filme_vento.jpg`;
2. ver os dois MP4 inteiros;
3. ler as notas.

Depois disso, se for aprovado, o clima (Ordem 40/41, noutro ramo) pode ler o vento como está
escrito em «Para o clima» nas notas: `vetor()` / `vetor_em(pos)`, uma vez por quadro.

**O que falta conferir:**

- **Os MP4 não foram vistos a correr de ponta a ponta num leitor.** Esta sessão viu-os pelos
  quadros: folhas de contacto de 2 em 2 horas, tiras de quadros seguidos, 1 quadro descodificado
  de cada MP4. Também os mediu (saltos entre quadros, e movimento da relva contra a força do
  vento). O juízo do movimento é do olho do Mestre.
- **19:45 é o quadro mais escuro** (luma 24,7). A lua ainda está baixa a leste e a sombra da orla
  cobre a frente da clareira. A Árvore, as janelas e o fundo da clareira lêem-se, mas é aqui que o
  olho deve decidir se a noite está «jogável». O botão para a aclarar é `lua_baixa` em
  `ciclo_dia.gd`.
- **A passagem lua↔sol** roda a direcção da luz pelo zénite durante ~20 min do mundo, com a luz
  directa no mínimo. Nos filmes não se nota; com figuras de jogo no meio da clareira (ainda não
  existem), merece um olhar.
- **A prova de que «o vento vê-se»** é forte de dia (correlação 0,71 entre o movimento da relva e a
  força) e fraca no dia inteiro (0,35): de noite a medida é baralhada pela luz a mudar a 720× e
  pelo ruído do JPEG nos quadros escuros. Só o olho resolve a noite.
- **O que ficou fora da ordem:** a lua é sempre cheia (sem fases), não há estações, e as
  DirectionalLight do sol e da lua não foram vistas a iluminar figuras (o mapa é todo pintado).
- **O modelo:** esta sessão correu em Opus 5.5, não no Fable 5.2 que a ordem manda.
