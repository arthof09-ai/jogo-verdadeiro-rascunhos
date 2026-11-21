# ESTADO-FINAL — ORDEM-PROVAS-MAPA-CORR8 (conta 1 · Opus · 21/11/2026)

**Objecto:** a correcção 8 da sentença da conferência PROVAS-MAPA (C2-4). Pedia duas coisas:
- dar à sonda de privacidade um controlo positivo: enviar à jogadora uma mensagem de teste com canário e confirmar
  que a sonda a apanha;
- escrever o que a jogadora **deve** receber quando a escala muda, para que um «silêncio correcto» se distinga de
  uma «notificação em falta».

**Base:** `fable/integracao-50`. Antes de partir, `git ls-remote` deu a ponta `b7ecadd1fa43dd033eb0b1ffaaeb8bd26815be16`
= `b7ecadd`, a ponta conhecida: a linha não andou.
**Ramo:** `claude1/provas-mapa-corr8`, **SEM fusão**.
Marcas: VERIFICADO (corrido e conferido nesta sessão), ACHADO (para o coordenador decidir).

## Leia primeiro

1. **A sonda APANHA o canário — VERIFICADO.** Na batalha de bancada real, o servidor meteu no fio da jogadora três
   mensagens de teste com canário. A sonda da jogadora (Godot) apanhou as três, cada uma por todos os canários que
   levava e só por esses.
   - **K1, as chaves só do Mestre:** `soMestre`, `casaMAntes`, `grelhaAntes`, `casasQuePaga`.
   - **K2, os textos:** `ESCALA_`, `Orc Verdadeiro`, `CANARIO-FANTASMA` e o PIN.
   - **K3, os números do orc:** 7777, 313, 9137.

   Fora das mensagens de teste, a sonda deu 0 achados, também nessa mesma corrida. A sonda Node (`procurarCanarios`)
   teve o mesmo controlo positivo, no fio e num teste de servidor novo. Correu três vezes com o mesmo resultado (ver
   §1).
2. **A lista do «deve receber» está no §2.** Numa mudança aplicada, a jogadora recebe exactamente 3 mensagens na vez
   dela e 2 fora dela. Numa recusa não recebe **nenhuma**.
   - O silêncio na recusa é correcto: a recusa é só do Mestre.
   - A ausência de qualquer frase ou aviso escrito sobre a mudança também é o desenho actual (Ordem 8, item 8).
   - Isto está provado por teste, e cada mutação que o quebra faz cair o teste certo.
3. **ACHADO — até onde a sonda da jogadora chega.** A sonda varre o que sai dos sinais da Rede do cliente, não o fio.
   - Uma MASTER_VIEW enviada por engano à jogadora (K4) **nunca chega à sonda**: a Rede deita-a fora, porque a
     jogadora não é Mestre (`rede.gd:488`). Isto é defesa do cliente, não fuga, mas a sonda não o pode ver. O
     contador `mensagensDeMestre == 0` da bancada, num lugar de jogadora, não pode dar outra coisa.
   - Um ROOM_REJECT com texto `ESCALA_…` e um intentId que não é dela (K5) também não chega: a Rede ignora-o
     (`rede.gd:566`). Mais em geral, a bancada não junta às mensagens varridas o texto de nenhuma recusa
     (`bancada_jogadora_mapa.gd:75`), nem o ROOM_PAUSED.
   - Por isso, nesta ordem, o fio da jogadora passou a ser escutado também no servidor e varrido pela sonda Node. Aí
     K1–K5 são **todos** apanhados.
   - Não mudei a ferramenta original da PROVAS-MAPA. Fica para o coordenador decidir se a bancada passa a varrer
     também o fio ou as recusas.
4. **ACHADO — os números da base.** A ordem dava «servidor 409». Esses 409 são do ramo `claude1/provas-mapa-corr7`
   (403 + 6), que não está fundido em `b7ecadd`.
   - A base real deu **403/403**. Depois desta ordem dá **407/407** (403 + 4 testes novos).
   - O cliente dá **290/290**, como a ordem dizia.
5. **Nenhuma linha da lógica do jogo mudou.** `git diff b7ecadd -- rascunhos` dá só o ficheiro de teste novo. Nenhuma
   prova falhou contra a lógica, por isso não houve nada para parar.

---

## 1. O controlo positivo da sonda — VERIFICADO

### 1a. Na batalha de bancada real (servidor WebSocket + jogadora Godot + Mestre e espectador Node)
É a bancada da PROVAS-MAPA, posta a correr outra vez com o controlo positivo. Tudo está em
`provas/ordem-provas-mapa-corr8/ferramentas/`, fora de `cliente/` e de `servidor/`.

- **`bancada-servidor-canario.mjs`** é o mesmo servidor que `bancada-servidor.mjs`: o `sala.js` de verdade, o
  adaptador WebSocket do repo, a grelha-mapa, o terreno, o motor falso e as fichas fictícias. Muda só um invólucro
  de fora, à volta de `sala.receber`/`entrar`, que faz duas coisas:
  - **Escuta o fio da heroína.** Cada mensagem que o servidor lhe entrega vai para `escuta-jogadora.jsonl`, com o
    `seatToken` retirado.
  - **Mete as mensagens de teste K1–K5.** Vão na primeira mudança de escala (1,5 → 1 m), logo a seguir ao evento
    `escala` real dela e com o **mesmo seq**. Por isso o Estado do cliente descarta-as como repetidas
    (`estado.gd:178`) e a batalha não muda: deu as mesmas 47 verificações que a PROVAS-MAPA, mais as da sonda. Cada
    mensagem leva `canarioTeste: "K…"` no topo:

| caso | mensagem de teste | canários |
|---|---|---|
| K1 | o evento `escala` com os **dados do Mestre** (a fuga típica: o evento sem a projecção da Party) | chaves |
| K2 | um evento `escala` com o detalhe `ESCALA_JUNTA_FIGURAS: …`, o nome verdadeiro do orc, `CANARIO-FANTASMA` e o PIN | textos |
| K3 | um evento `escala` com 7777 / 313 / 9137 (a Vida, os PA e a CA do orc) | números |
| K4 | uma MASTER_VIEW, com as figuras e o bloco `mestre` do snapshot que o Mestre recebe na mesma entrega | limite |
| K5 | um ROOM_REJECT com o texto `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS: … CANARIO-FANTASMA`, com um intentId alheio | limite |

- **`bancada_jogadora_canario.gd`** é `bancada_jogadora_mapa.gd` linha a linha. A recolha das mensagens (os sinais
  da Rede) e o `_varrer` da sonda são **os mesmos**. Muda só o cabeçalho e o veredicto da `_sonda`:
  - K1, K2 e K3 têm de chegar à sonda e de ser apanhados, cada um por exactamente os seus canários;
  - fora deles tem de haver 0 achados e 0 mensagens de Mestre;
  - K4 e K5 só se registam.

  O `diff` contra o original dá só 4 blocos: o cabeçalho (2), o título da `_sonda` e o corpo da `_sonda`.
- **`bancada-mestre.mjs`** é o da PROVAS-MAPA, **sem mudança**. A sonda do espectador tem de continuar limpa, porque
  as mensagens de teste só vão ao fio da heroína.
- **`sonda-fio.mjs`** corre `procurarCanarios` sobre a escuta do fio: K1–K5 têm de ser apanhados, e fora deles tem de
  haver 0 achados. Escreve também a cronologia.
- O guião é `correr-bancada-canario.sh`.

**Saída (corrida 3, a do commit: `provas/ordem-provas-mapa-corr8/bancada-jogadora.log`, `sonda-fio.log`,
`bancada-mestre.log`). O que está entre `[…]` foi abreviado aqui; os registos têm o texto inteiro:**
```
[canario] 5 mensagens de teste no fio da heroína (K1, K2, K3, K4, K5), seq 6
  ok    controlo positivo K1: a mensagem de teste chegou à sonda (sim) e a sonda APANHOU ["chave:casaMAntes", "chave:casasQuePaga", "chave:grelhaAntes", "chave:soMestre"] (esperado […os mesmos…])
  ok    controlo positivo K2: a mensagem de teste chegou à sonda (sim) e a sonda APANHOU ["texto:90210777", "texto:CANARIO-FANTASMA", "texto:ESCALA_", "texto:Orc Verdadeiro"] (esperado […os mesmos…])
  ok    controlo positivo K3: a mensagem de teste chegou à sonda (sim) e a sonda APANHOU ["numero:313", "numero:7777", "numero:9137"] (esperado […os mesmos…])
  ok    privacidade: fora das mensagens de teste, 0 achados e 0 mensagens de Mestre (de 25 mensagens à jogadora)
  nota  limite da sonda: K4 (MASTER_VIEW) não chegou à sonda (a Rede deita-a fora); K5 (ROOM_REJECT alheio) não chegou à sonda (a Rede ignora a recusa alheia)
bancada da jogadora: 47 de 47 verificações passaram.
== a sonda Node no fio da jogadora: 28 mensagens, casos de teste ["K1","K2","K3","K4","K5"] ==
  ok    K1: no fio e APANHADO — ["chave:casaMAntes","chave:casasQuePaga","chave:grelhaAntes","chave:soMestre"]
  ok    K2: no fio e APANHADO — ["texto:90210777","texto:CANARIO-FANTASMA","texto:ESCALA_","texto:Orc Verdadeiro"]
  ok    K3: no fio e APANHADO — ["numero:313","numero:7777","numero:9137"]
  ok    K4: no fio e APANHADO — ["numero:313","numero:7777","texto:Orc Verdadeiro"]
  ok    K5: no fio e APANHADO — ["texto:CANARIO-FANTASMA","texto:ESCALA_"]
  ok    fora das mensagens de teste: 0 achados []
[mestre] espectador: 12 mensagens, 0 achados; mapas vistos […50×50 @ 1,5 · 75×75 @ 1 · 37×37 @ 2…]
Mestre/espectador=0 jogadora=0 sonda-do-fio=0 erros-de-script=0
```
- **A diferença entre o fio (28) e a sonda (25) está explicada:** é K4, K5 e o ROOM_PAUSED que chega quando o Mestre
  sai, no fim. O ROOM_PAUSED não leva canário. A Rede emite-o como `sala_pausada`, que a bancada não liga, e ele chega
  depois de a jogadora fechar. Este é o achado 3.
- **As corridas.** A bancada correu 4 vezes nesta sessão:
  - **Corrida 0:** K4 falhou na sonda do fio por defeito do **meu** invólucro. Usei a MASTER_VIEW da entrada do Mestre,
    que é do lobby, antes de o orc ser posto, e não tinha canário nenhum. Corrigi o invólucro, não a lógica. Os
    ficheiros desta corrida não foram guardados. K1–K3 e as 47 verificações já tinham passado.
  - **Corridas 1 e 2:** iguais à 3, tudo verde. Os registos estão na sede, em `registos/corrida-1/` e `corrida-2/`.
    Ficam só na sede porque a escuta ainda levava o `seatToken` do servidor de teste.
  - **Corrida 3:** a do commit, com o token retirado da escuta.

### 1b. No teste de servidor novo: `rascunhos/servidor/testes/ordem-provas-mapa-corr8.test.mjs` (a)
- Na grelha-mapa, a 1,5 → 1 m, o fio real da jogadora dá 0 achados.
- O mesmo fio, com uma mensagem de teste de cada tipo depois do evento real, é apanhado. Todos os achados caem no
  índice da mensagem de teste, e o conjunto apanhado é exactamente o que ela leva.
- As mensagens de teste são feitas de coisas **reais** do fio do Mestre: o evento `escala` dele e o detalhe
  `ESCALA_INVALIDA` do evento `recusa`.

### 1c. A sonda do CI (`privacidade.yml`, o grep dos e-mails) — VERIFICADO
Não é a sonda da C2-4, mas também tem o nome «sonda de privacidade», por isso dei-lhe também um controlo positivo.
- A mesma regex, numa pasta temporária **fora do repo**, com um endereço fictício num dos domínios vigiados, **apanha-o**.
- No ramo, com os ficheiros novos, dá «Sonda limpa».
- O registo está em `registos/sonda-ci.log`, com o domínio mascarado para não pôr o CI vermelho.

---

## 2. O que a jogadora DEVE receber quando a escala muda a meio da batalha

A fonte é o código, e tudo está provado por `ordem-provas-mapa-corr8.test.mjs` (b)/(c) e pela escuta do fio na
bancada (`sonda-fio.log`, lotes 12 e 14).

### 2a. Mudança APLICADA, na vez dela (o caso da bancada) — 3 mensagens, por esta ordem, e mais nada
1. **`ROOM_EVENT` `tipo: "escala"`, `dados: {}`.** Leva o `seq` e a `revision` dela, mas nem o antes/depois, nem a
   vez, nem a grelha.
   - Fonte: `sala.js:3167` (grelha-mapa) e `:3068` (grelha fixa) emitem `tx.emitir('escala', {}, {…soMestre})`.
   - `projecao.js:47-48`: `escala: { todos: [], propria: [] }`.
   - `sala.js:1161` projecta o evento por destinatário.
2. **`ROOM_SNAPSHOT`, com o mesmo `seq` do evento.**
   - Leva `mapa` = `{largura, altura, casaM}` novos: 75 × 75 @ 1, 50 × 50 @ 1,5, 37 × 37 @ 2 na grelha-mapa; na
     grelha fixa, o tamanho fica e só muda o `casaM`.
   - Leva as `figuras` nas casas novas (na grelha-mapa, a casa do mesmo sítio no mapa) e a `propria` dela.
   - Fonte: `tx.snapshotsTodos = true` (`sala.js:3172` / `:3073`) → `finalizar` passo 2 (`sala.js:1173`).
3. **`ROOM_OPTIONS`.** A reserva continua em metros (`orcamentoM`) e as casas de mover são contadas na escala nova.
   - Fonte: `finalizar` passo 4 (`sala.js:1198`); `opcoesDoLugar` só dá opções à jogadora da vez (`sala.js:965`).
   - Na bancada foram `orcamentoM` 7,5 com 112 casas a 1 m, e 6,5 com 24 casas a 2 m.

Ela **não** recebe:
- o recibo, que vai só ao Mestre;
- o evento `recusa`;
- nenhuma MASTER_*;
- nenhum aviso, frase ou texto sobre a mudança.

### 2b. Mudança APLICADA, fora da vez dela — 2 mensagens
O `ROOM_EVENT` `escala` com `{}` e o `ROOM_SNAPSHOT`. Não recebe `ROOM_OPTIONS` (`sala.js:965`). O espectador recebe
sempre estas 2, na vez dela ou não.

### 2c. Mudança RECUSADA — NENHUMA mensagem (o silêncio correcto)
Isto vale para `ESCALA_JUNTA_FIGURAS`, `ESCALA_DEIXA_FIGURAS_EM_CASAS_BLOQUEADAS`, `ESCALA_INVALIDA` e «a mesma
escala».
- A jogadora e o espectador: **0 mensagens**. O Mestre recebe o `ROOM_REJECT` `acao_invalida`, com o texto fixo
  «Ação não disponível.».
- Quando há detalhe, o Mestre recebe também o evento interno `recusa`, com `soMestre.detalhe` = «ESCALA_…: …». O
  evento `recusa` não tem regra na projecção, por isso à Party não sai (`projecao.js:122-123`, «falha fechada»).
- A sala fica igual.

### 2d. A jogadora a pedir a escala
Recebe só `ERRO` `proibido` «Só o Mestre.» (`sala.js:3337`). Mais ninguém recebe nada e a escala fica.

### 2e. O que ela vê no ecrã
- **Não há frase.** O Estado do cliente não tem ramo para o evento `escala` (`estado.gd:399` e seguintes), por isso
  não sai `frase_batalha` nenhuma.
- **A mudança vê-se pela arena:** o `_ao_snapshot` refaz a grelha quando a largura, a altura ou o `casaM` mudam
  (`arena.gd:723`). As figuras são desenhadas na casa nova e as opções refazem-se.

### 2f. Como distinguir os dois silêncios
| situação | o que tem de chegar à jogadora | se faltar… |
|---|---|---|
| mudança aplicada, na vez dela | evento `escala` `{}` + snapshot com o mapa novo + opções | **notificação em falta** (é o que a mutação M2 provoca) |
| mudança aplicada, fora da vez | evento `escala` `{}` + snapshot | idem |
| mudança recusada | nada | se chegar alguma coisa, é **fuga** (é o que a mutação M3 provoca) |
| aviso escrito («o Mestre mudou a escala») | nada: não existe no desenho | é **silêncio correcto pelo desenho actual** (ver o achado abaixo) |

**ACHADO (desenho, não defeito).** Que a jogadora não receba nenhum aviso escrito sobre a mudança de escala é a regra
escrita da Ordem 8, item 8: «A Party vê só o resultado (evento `escala` sem campos + snapshot novo + as opções da
vez)» (`sala.js:3036-3038`). Se o Mestre quiser uma frase para a jogadora, isso é ordem nova, no cliente
(`estado.gd`) e talvez no protocolo. Não mexi.

### 2g. Os testes mordem (controlo negativo) — VERIFICADO
Fiz mutações temporárias em `nucleo/`, cada uma revertida com `git checkout` antes da seguinte. `git status nucleo`
ficou vazio. A saída está em `registos/mutacoes.log`.

| mutação | falham |
|---|---|
| M1: o evento `escala` da grelha-mapa leva `casaMAntes` à Party (fuga) | (a) [o fio real deixa de estar limpo] e (b) grelha-mapa |
| M2: a grelha-mapa não manda o snapshot novo (notificação em falta) | só (b) grelha-mapa |
| M3: o evento interno `recusa` passa a sair para a Party (fuga na recusa) | (a) e (c) |

---

## 3. Suites — VERIFICADO

| suite | base `b7ecadd` | depois |
|---|---|---|
| servidor `node --test testes/` (Node 26.13.0) | **403/403** | **407/407** (403 + 4 novos), 0 falhas |
| escala + privacidade (6 ficheiros: corr8, ordem-escala, ordem11, ordem-mapa-jogavel, ordem62, privacidade) | — | **48/48** |
| cliente `rodar_testes.gd` (Godot 4.7.2 headless, depois de `--import`) | 290 (a da ordem) | **290 de 290 verificações passaram**, código de saída 0, 0 «SCRIPT ERROR / Parse Error / Compile Error» |
| bancada com o controlo positivo | — | jogadora **47/47**; sonda do fio 6/6; Mestre/espectador TUDO PASSOU; 3 corridas verdes |

Os registos estão em `provas/ordem-provas-mapa-corr8/registos/`: `servidor-base.log`, `servidor-todos.log`,
`servidor-escala-privacidade.log`, `cliente-import.log`, `cliente-rodar_testes.log`, `mutacoes.log` e
`sonda-ci.log`.

## 4. Comandos corridos
```
git ls-remote origin fable/integracao-50                  # b7ecadd1fa43… (a linha não andou)
git clone --config core.autocrlf=false <origin> repo ; git checkout -b claude1/provas-mapa-corr8 b7ecadd
cd rascunhos/servidor && node --test testes/              # base 403/403
node --test testes/ordem-provas-mapa-corr8.test.mjs       # 4/4 (+ as 3 mutações, revertidas)
cd ../cliente && godot --headless --path . --import
GODOT=<godot> bash provas/ordem-provas-mapa-corr8/ferramentas/correr-bancada-canario.sh 8792   # 4 corridas (ver §1a)
node --test testes/                                       # depois 407/407
godot --headless --path . -s res://testes/rodar_testes.gd # 290/290
python -I retoma-i0004/actualizar-listas.py               # as listas da retoma (ver §5)
```

## 5. O que fica no ramo
- `rascunhos/servidor/testes/ordem-provas-mapa-corr8.test.mjs` (novo): os 4 testes.
- `provas/ordem-provas-mapa-corr8/`:
  - `ferramentas/`: `bancada-servidor-canario.mjs`, `bancada_jogadora_canario.gd`, `sonda-fio.mjs`,
    `correr-bancada-canario.sh`;
  - os registos da corrida 3: `bancada-*.log/.json`, `escuta-jogadora.jsonl`, `sonda-fio.log/.json`;
  - `registos/`.
- `MANIFESTO-SHA256.txt` e `retoma-i0004/depois.txt`, refeitos por `actualizar-listas.py`:
  - o teste novo está em `rascunhos/` e o job `retoma-pc` do CI exige-o nas listas;
  - como na CORR7, isso põe também a linha do `provar_terreno_servidor.gd` (a deriva do `d21f734`, achado 3 da
    CORR7), que deixava a base vermelha no `retoma-pc`;
  - se o coordenador preferir essa reparação numa ordem própria, basta reverter essa linha nas duas listas.
- `ESTADO-FINAL-ORDEM-PROVAS-MAPA-CORR8.md`: este ficheiro.
- Os `.uid` que o `--import` gerou ficaram fora do commit, como nas ordens anteriores.

## 6. Passagem
- **Onde parou:** a correcção 8 está feita e empurrada em `claude1/provas-mapa-corr8`, **sem fusão**.
- **Para o coordenador decidir:**
  - o alcance da sonda da jogadora, que vê só o que passa pelos sinais da Rede (achado 3): ligar a bancada ao fio ou às
    recusas?
  - o aviso escrito da mudança de escala para a jogadora, que hoje não existe por desenho (achado do §2f);
  - a reparação das listas do `d21f734`, se não a quiser aqui (§5).
- As correcções 9 e 10 da sentença não foram tocadas.
