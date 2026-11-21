# ESTADO-FINAL — ORDEM-PROVAS-MAPA-CORR9 (conta 1 · Opus · 21/11/2026)

**Objecto:** correcção 9 da sentença da PROVAS-MAPA (C2-2). Pedia uma de duas coisas:
- ligar a bancada e a ferramenta adaptada ao CI;
- ou registar que a prova é de uma só corrida.

E, no mínimo, correr a bancada uma segunda vez e registar a repetição.

**Base:** `fable/integracao-50`. Antes de partir, `git ls-remote` deu a ponta `b7ecadd1fa43dd033eb0b1ffaaeb8bd26815be16`
(`b7ecadd`). A linha não andou desde a CORR8.
**Ramo:** `claude1/provas-mapa-corr9`, **SEM fusão**.
> **Corrigido pela ORDEM-PROVAS-MAPA-CORR9-CORRECOES (21/11/2026).** Mudaram as frases marcadas «[CORR9-C …]». O
> que foi feito e medido, correcção a correcção, está em `ESTADO-FINAL-ORDEM-PROVAS-MAPA-CORR9-CORRECOES.md` (na
> mesma pasta). Em resumo: o comparador passou a comparar a floresta e o dentro/fora dos desvios em separado e a
> ordenar o hash dos marcos — **461 números e 73 bits**, em vez de 419 e 73 —, e o import do job passou a falhar o job.

Marcas: VERIFICADO (corrido e conferido nesta sessão), PREPARADO (feito, mas não activo), ACHADO (para o coordenador
decidir).

## Leia primeiro

1. **A via que ficou: o CI está PREPARADO mas não ligado, e a repetição está registada — VERIFICADO no PC.**
   - Escrevi o job `provas-mapa` no padrão dos que já correm. Ele faz quatro coisas:
     - descarrega o Godot 4.7.2 fixo e o Node 24;
     - corre a ferramenta original e a cópia adaptada nas 18 grelhas;
     - corre a batalha de bancada;
     - compara os números com os da primeira corrida.
   - **Não o consegui empurrar.** O GitHub recusou o push: `refusing to allow an OAuth App to create or update
     workflow .github/workflows/testes.yml without workflow scope`. O token desta conta tem só os escopos `gist`,
     `read:org` e `repo`.
   - Por isso o job vai no ramo **como patch**, `provas/ordem-provas-mapa-corr9/ci-job-provas-mapa.patch` (também na
     sede). É o mesmo caminho da Ordem 21 (`o21-job-godot-cliente.patch`). `git apply --check` confirma que aplica.
     Tem de o aplicar e empurrar quem tiver o escopo `workflow`.
   - **O job nunca correu em Linux.** Não há WSL nem Docker neste PC, e o GitHub não deixa empurrar o workflow. Não sei
     se os números se repetem no Linux. Os números são contagens e desvios entre servidor e cliente, por isso espero
     que sim, mas é só expectativa: **não está provado**.
2. **A repetição: corri tudo mais duas vezes, e as duas dão o mesmo que a primeira, bit a bit — VERIFICADO.**
   - [CORR9-C N6] **O que isto é:** uma corrida original (a da ORDEM-PROVAS-MAPA, 20/11) e duas re-corridas no mesmo
     PC, na mesma sessão, com o mesmo Godot e o mesmo Node. Não são três confirmações independentes: provam que a
     prova é determinística neste PC, não que se repete noutra máquina ou noutro sistema.
   - **Corrida 2 e corrida 3** (nesta sessão) contra a **corrida 1** (os registos da ORDEM-PROVAS-MAPA no repo):
     **419/419 números iguais e 73/73 impressões bit a bit iguais**. [CORR9-C B1] Com o comparador corrigido, re-corrido
     sobre as mesmas corridas: **461/461 números** (os 419 + 42 da floresta) **e 73/73 bits**, `REPETE-SE`.
   - Isto vale para a prova 1 (ferramenta original e cópia adaptada, 18 grelhas cada) e para a prova 2 (a batalha).
   - A sequência da floresta (`casas_bloqueadas` por carga) também se repete: as mesmas 18 + 18 + 3 contagens.
     [CORR9-C B1] Na entrega original esta linha era conferida à mão, fora do portão; agora o comparador lê-a das
     linhas `[floresta]` dos registos e compara-a carga a carga (42 números: o número de cargas e cada carga, para a
     ferramenta original, a adaptada e a bancada).
   - A tabela inteira, lado a lado, está em `provas/ordem-provas-mapa-corr9/repeticao-pc.md`.
3. **Nenhuma prova falhou e nenhuma linha do jogo mudou.** `git diff b7ecadd HEAD -- rascunhos` está vazio, e nenhuma
   ferramenta da ORDEM-PROVAS-MAPA foi copiada nem mudada. Não houve nada para parar.
4. **Suites:** servidor **403/403**, cliente **290/290**, ambos com código 0 e 0 erros de script (§4).
5. **ACHADO, que vem de trás e não é desta ordem:** o job `retoma-pc` está vermelho no ramo, como na base.
   - O erro é `CLONE DIFERENTE: rascunhos/cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd`. É a deriva do
     `d21f734` (achado 3 da CORR7).
   - A base `b7ecadd` falha da mesma maneira (run 44862505065). [CORR9-C N5] A reparação está nos ramos da CORR7
     (`claude1/provas-mapa-corr7` @ `e140dfc`) e da CORR8 (`claude1/provas-mapa-corr8` @ `d39f9fa`; a primeira
     reparação foi `726ad85`), ainda por fundir. Ordem das fusões decidida: CORR7, CORR8, CORR9.
   - Não a repeti aqui, porque mexe nas listas da retoma, que são estrutura fora desta ordem.

---

## 1. A repetição — VERIFICADO

### 1a. Como se correu
`provas/ordem-provas-mapa-corr9/ferramentas/correr-provas-mapa.sh <pasta> [porta]` corre as três peças, por ordem:

| peça | ferramenta (da ORDEM-PROVAS-MAPA, sem mudança) |
|---|---|
| prova 1a, a ferramenta original | `res://cenas/arena/ferramentas/provar_terreno_servidor.gd` (18 grelhas) |
| prova 1b, a cópia adaptada | `provas/ordem-mapa-jogavel/provas-bancada/ferramentas/provar_terreno_servidor_mapa.gd` (18 grelhas) |
| prova 2, a batalha de bancada | `bancada-servidor.mjs` + `bancada_jogadora_mapa.gd` (Godot, arena real) + `bancada-mestre.mjs` |

- O encadeamento da prova 2 é o de `correr-bancada.sh`, linha a linha. Muda só a pasta dos registos.
- Escrevi um guião próprio porque o `correr-bancada.sh` escreve sempre em `provas-bancada/`, por cima dos registos da
  primeira corrida. Assim a corrida 1 fica intacta.
- Os registos levam `# início`, `# fim` e `# código de saída`.

`provas/ordem-provas-mapa-corr9/ferramentas/comparar-corridas.mjs` põe as corridas lado a lado.
- Compara o **resumo** de cada corrida, e não o JSON bruto, porque o JSON bruto traz duas coisas que mudam de corrida
  para corrida por natureza:
  - os ids das figuras, aleatórios por sala;
  - os tempos das verificações («(0.2 s)»).
- **Números (o portão), 419 campos.** São os números que o ESTADO-FINAL da PROVAS-MAPA regista:
  - por grelha e por ferramenta: grelha pedida → servida e canto NO, casas dentro/fora, bloqueadas, juízo ≠,
    motivo ≠, cobertura afirmada ≠, cobertura não afirmada (cli ≠ ref), faixa da fronteira, desvios de altura, pé e
    figuras, figuras, recusas (e a impressão dos detalhes), mover (bloqueadas no cliente) e marcos;
  - na bancada, por escala: grelha, figuras (casa, nó, desvio, água), caminho servidor/cliente, alcance e passo;
  - ainda na bancada: as verificações da jogadora (com a impressão dos textos), a sonda, os mapas vistos, os recibos,
    as escalas e os movimentos do Mestre, o espectador e as falhas.
- [CORR9-C B1] **Floresta, 42 números (também portão):** de cada linha `[floresta] pronta …` dos registos
  (`provar-terreno-servidor.log`, `provar-terreno-servidor-adaptada.log`, `bancada-jogadora.log`), o campo
  `casas_bloqueadas`, carga a carga, e o número de cargas (18, 18 e 3). Com isto o portão tem **461 números**.
- [CORR9-C N3] **Os desvios dentro e fora vão em separado.** Na entrega original o campo dos desvios guardava
  `max(dentro, fora)` da altura e do pé, e o portão só vigiava o máximo; agora compara os dois valores.
- **Bits, 73 impressões SHA-256.** Cobrem as alturas desenhadas e as do servidor, em cada figura e em cada marco de
  cada grelha, e os nós desenhados na bancada. No PC uso `--bits`, e aí também são portão.
- **Controlo do comparador:** a corrida 1 contra si própria dá 419/419 e 73/73. [CORR9-C B2] Os controlos negativos
  (um número mudado → `NÃO SE REPETE`, saída 1, uma linha «NÃO»; e os da floresta, das bits, do dentro/fora e dos
  marcos) estão em `ferramentas/controlo-comparador.mjs` e `registos/controlo-comparador.log`.
- [CORR9-C N2] O hash dos marcos passou a ser ordenado, como o das figuras.

### 1b. Os números lado a lado (resumo; a tabela completa está em `repeticao-pc.md`)
A corrida 1 é a dos registos do repo, em `provas/ordem-mapa-jogavel/provas-bancada/`:
- a prova 1 (original e adaptada) é a re-corrida das correcções `d21f734`, com 84 s e 80 s;
- a bancada é a de `b62a887`, sem duração registada.

| | corrida 1 (PROVAS-MAPA) | corrida 2 (21/11, 02:08) | corrida 3 (21/11, 02:11) |
|---|---|---|---|
| prova 1a, original: resultado | TUDO PASSOU, código 0 | TUDO PASSOU, código 0 (61 s) | TUDO PASSOU, código 0 (61 s) |
| prova 1b, adaptada: resultado | TUDO PASSOU | TUDO PASSOU, código 0 (60 s) | TUDO PASSOU, código 0 (61 s) |
| 18 grelhas: juízo ≠ / motivo ≠ / cob. afirmada ≠ / desvios | 0 em todas | 0 em todas | 0 em todas |
| grelha 11 (pedida 50×50 @ 1 → servida) | 75×75 @ 1, NO −37,5; 5625 casas (841/4784); 156 bloq.; 156 recusas; mover 110 (0); marcos 14/14 | igual | igual |
| grelhas-mapa 10 / 11 / 12: bloqueadas | 67 / 156 / 43 | igual | igual |
| cob. não afirmada por grelha (1–18) | 99, 107, 76, 91, 184, 42, 87, 112, 120, 0, 0, 0, 97, 96, 88, 112, 65, 74 | igual | igual |
| floresta `casas_bloqueadas` (prova 1, 18 cargas; no portão desde a CORR9-C) | 173 146 128 173 164 188 141 204 125 157 88 88 88 151 141 122 133 91 | igual | igual |
| bancada 1,5 m | 50×50; caminho 80/80 (0·0·0), 4 de água, 9 m = 6 casas; orc a 7 passos, **fora**; → (38,5) 1,5 m APLICADA | igual | igual |
| bancada 1 m | 75×75; desvio 0,25 / 0,25; heroína (57,8), orc (57,17) na água; 112/112, 9 de água, 7,5 m = 7 casas; 9 ≤ 9, **ao alcance**; → (57,9) 1 m APLICADA | igual | igual |
| bancada 2 m | 37×37; desvio 0 / 0; heroína (28,4), orc (28,8); 24/24, 4 de água, 6,5 m = 3 casas; 4 ≤ 4,5, **ao alcance**; → (28,6) água, 4 m APLICADA | igual | igual |
| jogadora | **44 de 44**; sonda 22 mensagens, 0 de Mestre, 0 achados | 44 de 44 (os mesmos textos); 22 / 0 / 0 | igual |
| Mestre | 5 recibos APLICADA; escalas 50→75 (reserva 7,5, paga 7) e 75→37 (6,5, paga 3); movimentos 1,5 / 1 / 4 m, ficam 7,5 / 6,5 / 2,5 m | igual | igual |
| espectador | 12 mensagens, 0 achados, eventos `escala` `{}` | igual | igual |
| floresta na bancada (no portão desde a CORR9-C) | 173 88 88 | igual | igual |
| duração da bancada | — | 10 s | 11 s |
| **comparador** | — | **419/419 números, 73/73 bits** | **419/419 números, 73/73 bits** |
| **comparador corrigido (CORR9-C)** | — | **461/461 números, 73/73 bits** (as três juntas) | igual |

- **Duração.** [CORR9-C N4] As corridas 2 e 3 levaram 60–61 s por ferramenta (pelos `# início` / `# fim` dos
  registos); as da corrida 1 levaram 84 e 80 s, no mesmo PC. Medido nos registos: a soma dos `carga_ms` das 18
  cargas da floresta caiu de 62,2 s para 48,7 s (original) e de 60,3 s para 47,9 s (adaptada) — cerca de 13 s dos
  20–23 s de diferença; os outros 8–10 s por ferramenta estão fora das cargas da floresta e não os medi. **Não sei
  porque é que as cargas foram mais rápidas**; a frase original («noutro regime de carga») era uma explicação sem
  medida e fica retirada. A duração não entra no resumo.
- Nas três corridas: 0 «SCRIPT ERROR / Parse Error / Compile Error», e código 0 em todas as peças.

## 2. O CI — PREPARADO, não ligado

### 2a. O job `provas-mapa` (em `ci-job-provas-mapa.patch`)
- **Padrão.** É o dos jobs `godot-cliente` e `ponta-a-ponta`:
  - `ubuntu-latest`, com `timeout-minutes: 20`;
  - `actions/checkout@v4` e `setup-node@v4` com Node 24;
  - o Godot `4.7.2-stable` fixo; [CORR9-C B3] o SHA-256 do zip é **impresso no registo, não comparado** com um
    valor esperado (como nos jobs existentes — a verificação seria mudança em todos os jobs, N1 da sentença);
  - `--import`, que [CORR9-C B3] **falha o job quando falha** (`set -o pipefail`, sem `|| true`, como no passo de
    import do job `godot-cliente`).
- **Passos.**
  1. Corre `correr-provas-mapa.sh "$RUNNER_TEMP/provas-mapa" 8794` e mostra as caudas dos registos. O job falha se
     alguma das três peças falhar ou se aparecer um erro de script.
  2. **Repetição:** corre `comparar-corridas.mjs primeira=provas/ordem-mapa-jogavel/provas-bancada ci=$RUNNER_TEMP/…`.
     O job falha se os números não se repetirem.
  3. Os bits **não** são portão aqui, porque a primeira corrida foi no Windows e o CI é Linux. São só registados em
     `repeticao.md`.
  4. Os registos e a tabela da repetição ficam no artefacto `provas-mapa`.
- **O que muda no repo.** Só se acrescenta o job, e mais nada em `testes.yml`.

### 2b. Porque não ficou ligado
- O push com `.github/workflows/testes.yml` foi recusado pelo GitHub, por falta do escopo `workflow` no token OAuth
  (`gh auth status`: `'gist', 'read:org', 'repo'`).
- Ganhar esse escopo é mudar a credencial da conta (`gh auth refresh -s workflow`, que pede o navegador). Isso não
  cabe nesta ordem e não o fiz.
- **Para ligar:** no ramo, correr `git am provas/ordem-provas-mapa-corr9/ci-job-provas-mapa.patch` e empurrar com uma
  credencial que tenha o escopo `workflow`.
- **No primeiro run, conferir duas coisas:**
  - o passo «Repetição» tem de dar `REPETE-SE`;
  - as impressões bit a bit do Linux, registadas em `repeticao.md` no artefacto.
- **Se os números do Linux divergirem,** isso é um achado e não se arranja ajustando o comparador.

### 2c. CI do ramo como está (sem o job novo) — VERIFICADO
Run **44869950199** («Testes dos rascunhos», em `ad2d165`):
- 8 de 9 jobs verdes: protocolo, servidor, godot-cliente, validador-glb, cliente, foto-mestre, motor-real e
  ponta-a-ponta;
- **`retoma-pc` vermelho**, o mesmo da base (achado 5).

Run **44869950260** («Sonda de privacidade»): verde. A sonda local deu limpo nos ficheiros novos.

## 3. Regra dura
Nenhuma prova falhou contra a lógica. `git diff --stat b7ecadd HEAD -- rascunhos` não dá nada. As ferramentas da
ORDEM-PROVAS-MAPA correram tal como estão no repo. Os `.uid` que o `--import` gerou ficaram fora do commit, como nas
ordens anteriores.

## 4. Suites — VERIFICADO
| suite | resultado | registo |
|---|---|---|
| servidor `node --test testes/` (Node 26.13.0) | **403/403**, 0 falhas, código 0 | `registos/servidor-todos.log` |
| cliente `rodar_testes.gd` (Godot 4.7.2 headless, depois de `--import`) | **290 de 290 verificações passaram**, código 0, 0 erros de script | `registos/cliente-rodar_testes.log` |

São os mesmos números da base que a CORR8 registou: 403 e 290.

## 5. Comandos corridos
```
git ls-remote origin fable/integracao-50     # b7ecadd1fa43… (a linha não andou)
git clone --config core.autocrlf=false <origin> repo ; git checkout -b claude1/provas-mapa-corr9 b7ecadd
godot --headless --path rascunhos/cliente --import
GODOT=<godot> bash provas/ordem-provas-mapa-corr9/ferramentas/correr-provas-mapa.sh provas/ordem-provas-mapa-corr9/corrida-2 8793
GODOT=<godot> bash provas/ordem-provas-mapa-corr9/ferramentas/correr-provas-mapa.sh provas/ordem-provas-mapa-corr9/corrida-3 8795
node provas/ordem-provas-mapa-corr9/ferramentas/comparar-corridas.mjs --bits --md=provas/ordem-provas-mapa-corr9/repeticao-pc.md \
  corrida-1=provas/ordem-mapa-jogavel/provas-bancada corrida-2=provas/ordem-provas-mapa-corr9/corrida-2 corrida-3=provas/ordem-provas-mapa-corr9/corrida-3
cd rascunhos/servidor && node --test testes/                       # 403/403
cd rascunhos/cliente && godot --headless --path . -s res://testes/rodar_testes.gd   # 290/290
git push origin claude1/provas-mapa-corr9    # com o workflow: RECUSADO (sem escopo workflow) → job em patch
```

## 6. O que fica no ramo (`provas/ordem-provas-mapa-corr9/`)
- `ferramentas/correr-provas-mapa.sh` e `ferramentas/comparar-corridas.mjs`;
- `corrida-2/` e `corrida-3/`, com os registos e os JSON das três peças e o `resultado.txt` de cada corrida;
- `repeticao-pc.md`, as três corridas lado a lado (419 + 73 linhas);
- `ci-job-provas-mapa.patch`, o job do CI;
- `registos/servidor-todos.log` e `registos/cliente-rodar_testes.log`;
- `ESTADO-FINAL-ORDEM-PROVAS-MAPA-CORR9.md`, este ficheiro.

## 7. Passagem
- **Onde parou:** a correcção 9 está cumprida no mínimo obrigatório (a bancada correu mais duas vezes e a repetição
  está registada, igual bit a bit) e com o CI preparado. Está empurrada em `claude1/provas-mapa-corr9`, **sem fusão**.
- **Para o coordenador decidir:**
  - aplicar o patch do job com uma credencial que tenha o escopo `workflow` e conferir o primeiro run em Linux (§2b).
    Até lá, a prova fica **registada como de corridas no PC: três, idênticas** — [CORR9-C N6] uma original e duas
    re-corridas no mesmo PC, não três confirmações independentes;
  - o `retoma-pc` vermelho que vem da base (achado 5). A reparação está na CORR7 e na CORR8 (`e140dfc`, `d39f9fa`).
- As correcções 7, 8 e 10 não foram tocadas nesta ordem.
