# ORDEM ÁGUA-REAÇÃO — ESTADO FINAL (as figuras mexem a água) · 19/11/2026

Sessão na nuvem (conta 1) que cumpriu `ORDEM-AGUA-REACAO.md` no ramo `claude1/agua-reacao` (ponta à chegada `55e5814`,
que contém a linha `fable/integracao-50` @ `e09ba96`). Godot 4.7.2 oficial descarregado para a sessão; renderizador
Compatibility (OpenGL 3) por software (Mesa llvmpipe) em Xvfb; sem GPU.
Etiquetas: **VERIFICADO** = corrido/visto nesta sessão, com evidência no repo ou no CI; **RECONSTRUÍDO** = deduzido de
evidência indirecta; **PROPOSTO** = escolha minha, por conferir; **PENDENTE** = por fazer.

## O que foi feito

| Commit | O quê |
| --- | --- |
| `aa26e65` | A reacção: `mapa/floresta/lago_floresta.gd` (salpico, agito, calma), `shaders/agua.gdshader` (agito por corpo), `testes/video_lago.gd` (etiqueta, série, custo), `testes/rodar_testes.gd` (17 verificações). |
| `7888f85` | Listas da retoma e MANIFESTO refeitos. |
| `4785173` | `provas/ordem-agua-reacao/ferramentas/folha.py` (folhas antes/depois a partir dos vídeos). |
| `861a9fe` + `750b660` | O agito passa de `float[4]` para `vec4` no shader + listas refeitas. Ver «Erro registado» (foi um falso alarme meu). |
| `4015fa5` | Provas: folhas, quadros, medições, suites. |
| este | Vídeos, medição de custo e este ESTADO FINAL. |

### 1. O que a água faz agora — VERIFICADO (testes headless + bancada filmada)

Tudo vive no nó que já existia (`LagoFloresta`, Ordem 66). O estado de cada figura seguida vem das funções que o NADO
já expõe — `imersao(x, z, y)` para «dentro de água» e `LagoFloresta.a_nadar(x, z)` para «a nadar». **Não há outra
detecção de água.** Nada aqui é regra: não há campo novo de dados, nem vida/alma, nem Estado/Rede.

1. **Entrar** (rasa ou funda): um **salpico** no ponto de contacto (o primeiro furo: o pé que entra) — `SALPICO_ANEIS`
   = 3 anéis, a 0,24 s uns dos outros, cada um mais fraco (×0,72), que se abrem como os anéis da Ordem 66. A força
   cresce com a velocidade e com quanto do corpo vai dentro. **Ao passar a nadar** (a fronteira `a_nadar` do NADO)
   há outro salpico, no tronco, mais forte (0,85). Quem já começa dentro de água (o primeiro quadro em que é
   seguido) não entrou: não salpica.
2. **Mover-se dentro de água** (vadear ou nadar): cada figura tem um **agito** (0–1). Sobe logo com a velocidade
   (`veloc / 0,45 m/s`, até 1); a ondulação colada ao corpo e a espuma da linha de água multiplicam pelo agito no
   shader (`corpos_agito`). Os anéis do caminho (um a cada 0,42 m) e a esteira (um ponto a cada 0,30 m) já eram
   proporcionais ao caminho andado (Ordem 66) e ficam.
3. **Parada:** o agito cai a direito de 1 a 0 em `CALMA_S` = 3,5 s; a ondulação e a espuma colada apagam-se com
   ele. O anel fraco de quem está parado (de 1,6 em 1,6 s) passa a ter a força × agito e **deixa de nascer** quando a
   água acalma. Os anéis já nascidos morrem sozinhos (≤ 7 s). Fica só o vento.
   **Antes desta ordem** a figura parada deixava o anel fraco e a espuma colada **para sempre**.

Evidência:
- `rodar_testes.gd` `_teste_agua_reacao` — 17 verificações, com o lago verdadeiro e uma figura a andar quadro a
  quadro: em seco não reage; o salpico nasce no quadro em que entra, com 3 anéis e agito 1; uma entrada = um salpico;
  a vadear agito 1 e anéis; devagar (0,09 m/s) agito 0,2; parada há 1,75 s agito 0,5, há 3,6 s agito 0; parada,
  0 anéis vivos depois de 7,5 s; andar e parar não salpica; ao passar `a_nadar` um salpico (e só um); posta dentro de
  água não salpica; fora de água agito 0; o shader tem o uniforme. Log: `provas/ordem-agua-reacao/suites/rodar_testes.log`
  (**243/243**).
- Bancada (`--modo=rasa` e `--modo=funda`), série em `provas/ordem-agua-reacao/medicao/`:
  - **a geometria é igual antes e depois** (fundura, água no corpo, pés no leito: 742/742 e 1354/1354 linhas); o
    nado igual (601 quadros a nadar nos dois); o «antes» desta sessão é igual linha a linha à prova do NADO
    (`provas/ordem-nado/rasa-antes-depois/depois_rasa_medicao.json`);
  - rasa: entra aos 6,85 s → salpico 1, agito 1; pára aos 15,77 s → agito 0,43 (+2 s), 0 (+3,7 s); anéis vivos
    parada: antes 4–5 até ao fim do vídeo de antes, depois 2 (+8 s) → **0 (+11 s)**;
  - funda: começa parado na rasa → agito 0, 0 salpicos; deita-se a nadar aos 5,47 s → salpico 1; pára na rasa aos
    29,13 s → anéis vivos +11 s: antes 5, **depois 0**; +15 s: antes 4, depois 0.

### 2. Provas — VERIFICADO (`provas/ordem-agua-reacao/`, ver README lá)
- `videos/rasa.mp4` (27,7 s), `videos/funda.mp4` (45,1 s): o DEPOIS; `videos/*_antes-depois.mp4`: ANTES | DEPOIS lado a
  lado. Figura a entrar, a vadear, a nadar e parada.
- `folhas/`: antes/depois nos mesmos quadros do guião; `*-de-perto_*` ampliadas à volta da figura.
- `quadros/`: as capturas da bancada no DEPOIS.

### 3. Custo medido no palco real — VERIFICADO
`--modo=medir` da bancada (arena integrada com o mapa da floresta, 1920×1080, sem vsync, o manequim a nadar na funda),
três corridas seguidas: ANTES (`55e5814`), DEPOIS, ANTES outra vez (para ver o ruído). JSON em `medicao/custo/`.

| Perfil | custo do lago + manequim (ms/quadro, com − sem): antes · depois · antes (2.ª) | chamadas de desenho (com) | CPU do lago (DEPOIS) |
| --- | --- | --- | --- |
| Alto | 137,8 · **143,1** · 168,7 | 49 · 49 · 49 | 57 µs/quadro |
| Médio | 86,8 · **74,1** · 74,6 | 49 · 49 · 49 | 58 µs/quadro |
| Baixo | 26,3 · **37,3** · 33,9 | 50 · 50 · 50 | 62 µs/quadro |

- Leitura: chamadas de desenho e primitivas **iguais**; no Alto e no Médio o DEPOIS cai dentro do intervalo das duas
  corridas do ANTES; no Baixo fica 3,4 ms acima da maior (o ruído entre as duas do ANTES é de 7,6 ms). **Não há
  diferença mensurável acima do ruído** neste render por software. O shader ganha um `if` e três multiplicações
  por corpo (máx. 4); a CPU do `avancar()` do lago é ~0,06 ms por quadro com o manequim a nadar.
- Limite da medição: llvmpipe (1,8–8 q/s), não um telemóvel nem uma GPU. A conta numa GPU fica para o coordenador.

### 4. Construção — VERIFICADO
- Local, Godot 4.7.2 headless: abrir_scripts **104 scripts, 0 falhas**; rodar_testes **243/243** (226 + 17 novos);
  arranque da cena principal «pronto», 0 erros de script.
- CI (Testes dos rascunhos, 9 jobs, e Sonda): **success** em `7888f85` (run 44559249404), `4785173` (44559654910),
  `750b660` (44564134228, a ponta do código), `4015fa5` (44567776428) e `4815a92` (44578264812; Sonda 44578264985).

## Erro registado (falso alarme, corrigido no registo)
- **Problema:** na 1.ª folha antes/depois julguei que a espuma colada aos pés sumia no DEPOIS com agito 1, e mudei o
  uniforme `float[4]` para `vec4` (`861a9fe`, cuja mensagem dá isso como causa provável e «confirmado num quadro»).
- **Causa (RECONSTRUÍDO):** leitura visual numa miniatura reduzida. A folha refeita com o `vec4` saiu com **o mesmo
  tamanho exacto em bytes** (1 625 888 B) que a primeira, o que indica vídeos iguais; nos recortes 1:1 a espuma e
  os anéis estão lá nos dois. O `float[4]` muito provavelmente funcionava. A «confirmação» foi um quadro do `vec4`
  sem par do `float[4]` — não era prova.
- **Solução:** o `vec4` fica (equivalente, um só uniforme, `MAX_CORPOS` = 4 documentado nos dois ficheiros); este
  registo corrige a mensagem do `861a9fe`.
- **Prevenção:** julgar diferenças visuais em recortes 1:1 de pares do mesmo quadro (a `folha.py` ganhou
  `--recorte`) e só chamar «confirmado» a uma comparação A/B.

## Riscos e pontos para o coordenador
1. **PROPOSTO — legibilidade do salpico.** Os 3 anéis lêem-se bem com a câmara alta da funda; na rasa, a 3/4 e em
   llvmpipe, a diferença para o anel único de antes é pequena (`folhas/rasa-de-perto_entrar.jpg`). A acalmia lê-se
   (`folhas/funda-de-perto_parado-na-rasa.jpg`, `rasa-de-perto_parada-acalma.jpg`). Se o Mestre quiser o salpico
   mais forte: `SALPICO_ANEIS`, o ×0,72 e as forças em `avancar()` — sem mexer no resto.
2. **PROPOSTO — `CALMA_S` = 3,5 s** e a acalmia total (a espuma da linha de água também some parada). Se o Mestre
   quiser uma linha de água leve na figura parada, é um mínimo no `mix` do shader.
3. **PENDENTE (vem do NADO, não muda aqui) — as figuras do jogo.** As figuras da arena são marcadores sem esqueleto e
   o lago fica fora da grelha de 20 × 20: hoje nenhuma figura do jogo pode entrar na água. A reacção não depende do
   esqueleto: `lago.seguir(nó)` sem `pontos` faz um anel à volta do nó, e salpico/agito/calma funcionam igual (o
   teste headless usa um `Node3D` simples). O que falta é a decisão de mapa (o lago dentro da grelha) ou de regra
   (casas de água) — reservada ao Mestre/servidor.
4. Na funda, a figura que começa já dentro de água não salpica (decisão minha, PROPOSTO): foi posta lá, não entrou.
5. `pulsos_vivos()` conta também os anéis do salpico que ainda vão nascer (até 0,48 s): a coluna «aneis» da série
   sobe 3 de uma vez na entrada.

## Fecho
- CI verde no código final (`750b660`) e na ponta antes deste commit (`4815a92`). Este commit só muda este ficheiro.
- Fusão na linha junta `fable/integracao-50` — a ÚLTIMA parte, depois das provas: **fast-forward** (a ponta da
  linha, `e09ba96`, já estava contida neste ramo; nada a resolver). Feita depois deste commit, que fica a ponta das
  duas; confirmada com `git ls-remote` (o resultado vai no relatório da sessão e no Diário).
- Próximo passo: conferência do coordenador (os vídeos com GPU; o olho do Mestre sobre a força do salpico e o
  `CALMA_S`); decisão do Mestre sobre pôr o lago ao alcance das figuras do jogo (risco 3).
