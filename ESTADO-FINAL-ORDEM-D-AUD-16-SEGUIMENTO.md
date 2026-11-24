# ESTADO-FINAL — ORDEM-D-AUD-16-SEGUIMENTO (o estado de ligação visível + o caminho de reversão corrido)

**Estado: FEITA** (o CI fica na nota do fim). As 4 tarefas da secção C da sentença 710, pela ordem dada:

1. **A1:** o ecrã do Mestre mostra agora **«A ligar à mesa…»** desde que abre até ao primeiro WELCOME. Com o servidor
   fora do ar e o Mestre sem nunca ter estado na mesa, já não fica calado. Há teste novo no `pecas_mestre` para o
   `A_ESPERAR` sem mesa, e está provado com janela (`a01`, `a02`).
2. **A2:** o caminho de reversão (lugar do Mestre + constante em `lobby.tscn` + servidor em cima) foi corrido uma vez
   na bancada. O Mestre abriu pelo lobby e chegou ao ecrã dele (`r02` + o log). A constante voltou a `mestre.tscn`:
   **a predefinição continua «directo» e a C-7 não foi decidida.**
3. **F1/F4:** cada log de suite (e de medição) abre com `# comando: …` e `# hora: …`. A saída dos comandos de captura,
   com as horas, foi cometida, e cada PNG traz a hora num bloco `tEXt` «Creation Time».
4. **A7:** os dois `pronto` vêm de dois ficheiros diferentes: o 1.º de **`arena.gd:171`**, o 2.º de **`lobby.gd:84`**.
   O arranque sem lugar cai no lobby. Não é erro da bancada, e está provado com marcas temporárias.

- **Executor:** Claude (opus), PC, conta 2. **Data:** 24/11/2026, ~06:56–07:40 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** a ordem dava `1e2baab`; a ponta real ao começar era **`ba01d1e`**. Depois do `1e2baab` entraram
  9 commits de outras ordens (F3, F4-PARCIAL), nenhum deles em `cenas/mestre`, `cenas/arena`, `cenas/lobby` ou `rede/`.
  O `1e2baab` é antepassado da ponta.
- **Commits:** ver §7.
- **Não toquei** no servidor, nos workflows, nos dados, na `main`, no `arena.gd`, no `lobby.gd`, na `rede.gd` nem no
  cliente da jogadora.

## 1. A1 — o estado «a ligar…» no ecrã do Mestre

### 1.1 A medição (e a escolha que ela decidiu)

A ordem deixava duas opções: um estado «a ligar…» visível até ao primeiro WELCOME, ou um alerta ao fim de N segundos
em `A_ESPERAR` sem nunca ter estado na mesa. Para escolher, medi o que a Rede faz de facto com o servidor fora do ar
(`provas/…/medicao/ligacao-arranque-servidor-fora.log`). A ferramenta é `testes/medir_ligacao_arranque.gd`: o ecrã do
Mestre aberto com a Rede a ligar a uma porta sem nada à escuta, durante 75 s.

| t (ms) | ligação | o que aconteceu |
|---|---|---|
| 2 816 | `A_LIGAR` | o ecrã do Mestre abriu (a Rede já estava a ligar: o sinal disso foi **antes** de a cena existir) |
| 30 006 | `A_ESPERAR` | a 1.ª tentativa só falha ao fim de **~30 s** (ligação a uma porta fechada) |
| 31 165 | `A_LIGAR` | a espera durou **1,1 s** |
| 61 169 | `A_ESPERAR` | outra vez ~30 s em `A_LIGAR` |
| 63 389 | `A_LIGAR` | a espera durou **2,2 s** |

Em 75 s, a Rede esteve **~3,3 s em `A_ESPERAR` e ~69 s em `A_LIGAR`**. As esperas (1 → 2 → 4 → 8 s, ±20 %) são
curtas e partidas por tentativas longas. Com isto, a opção do alerta não serve:

- um alerta «ao fim de N s **em `A_ESPERAR`**» com N > ~9,6 s (o tecto da espera, 8 s × 1,2) **nunca** dispara. Com
  N pequeno, só dispararia ao fim de ~30 s;
- os primeiros ~30 s, que são exactamente o defeito, ficavam calados em qualquer dos casos.

**Escolha: o estado visível.** Aparece logo quando o ecrã abre, não precisa de N nem de relógio, e cobre `A_LIGAR`,
`A_ENTRAR` e `A_ESPERAR`.

### 1.2 A correcção

| ficheiro | mudança |
|---|---|
| `rascunhos/cliente/cenas/mestre/mestre.gd` | Rótulo novo **`Ligacao`** na coluna 1, logo abaixo do `Alerta`. `_mostrar_ligacao()` corre no `_ready`, porque no arranque directo a Rede já está a ligar quando a cena abre, e a cada `ligacao_mudou`. `texto_ligacao(estado, ja_esteve)`: se **nunca esteve na mesa**, `A_LIGAR`/`A_ENTRAR` dão «A ligar à mesa…» e `A_ESPERAR` dá «A ligar à mesa… o servidor não responde; a tentar de novo.». Na mesa, desligada ou depois de já ter estado na mesa, dá `""` e o rótulo **some e não ocupa lugar**. Depois de ter estado na mesa, a queda continua a dar o alerta «A ligação caiu» (D-AUD-16), sem mudança |
| `rascunhos/cliente/cenas/mestre/textos_mestre.gd` | `LIGACAO` = as duas frases |
| `rascunhos/cliente/testes/pecas_mestre.gd` | `_arranque_a_ligar`: **10 verificações novas** (297 → 307), ver §1.4 |
| `rascunhos/cliente/testes/medir_ligacao_arranque.gd` | a ferramenta da medição do §1.1 (não é suite; fica para se poder repetir) |

O cliente da jogadora não mudou (`arena.gd`, `hud/`, `lobby.gd` e `rede.gd` ficaram intactos).

### 1.3 A prova com janela (servidor fora do ar, sem nunca ter estado na mesa)

Um cliente Godot 4.7.2 com janela, aberto pela cena principal, com um `lugar.cfg` do Mestre (token fictício) e
`--servidor=127.0.0.1:8790` sem nada à escuta:

- `a01` (07:05:14, aos 11 s): o ecrã do Mestre com **«A ligar à mesa…»** e 0 alertas;
- `a02` (07:05:38, aos 34 s): «A ligar à mesa…» continua visível.

**Achado (não mexi: está fora do âmbito):** a D-AUD-16 escreveu que, neste arranque, «não há outro aviso de ligação no
ecrã dele». Não é exacto. Aos **~10 s** aparece um alerta **pré-existente** (Ordem 49, o tecto do pedido da vista),
«A vista da mesa não se pediu (40 tentativas). Toque em «Atualizar».», e está em `a02` e no `godot.log`
(`WARNING: MASTER_VIEW: vista_sem_pedido`). Com o servidor fora do ar, esse alerta **aponta a causa errada**: manda
tocar em «Atualizar», quando o que falta é a ligação. Agora o «A ligar à mesa…» aparece por baixo dele e diz a causa
certa. Calar ou reescrever o alerta da vista enquanto a Rede não está na mesa fica para uma ordem seguinte, se o
coordenador quiser.

### 1.4 O teste novo (`pecas_mestre`, «A_ESPERAR sem nunca ter estado na mesa mostra «a ligar…»»)

1. desligada (testes de ecrã): o rótulo existe e não se vê;
2. `A_LIGAR`, nunca esteve na mesa: «A ligar à mesa…»;
3. **`A_ESPERAR`, nunca esteve na mesa (o caso que faltava):** «A ligar à mesa… o servidor não responde; a tentar de novo.»;
4. o mesmo caso: **nenhum alerta falso**;
5. 3 voltas `A_LIGAR`/`A_ESPERAR`: o estado vê-se em todas e não se junta nenhum alerta;
6. o rótulo está no ecrã, logo abaixo do Alerta;
7. **um ecrã que abre com a Rede já em `A_ESPERAR`** (o arranque directo, em que o sinal veio antes da cena) mostra logo o estado e 0 alertas;
8. na mesa (depois do WELCOME): o estado some;
9. depois de ter estado na mesa, `A_ESPERAR` dá «A ligação caiu» e **não** o estado «a ligar…»;
10. de volta ao estado do teste: o rótulo some.

## 2. A2 — o caminho de reversão, corrido uma vez

Corri `bancada-rede/lancar.ps1 -SemEspera -HostServidor 127.0.0.1 -Motor auto` (fichas `canario`, porteiro com a
batalha preparada, dois clientes Godot com janela em simultâneo) com `CENA_ARRANQUE_MESTRE = "res://cenas/lobby/lobby.tscn"`
(`arena.gd:23`) **só na cópia de trabalho** (`logs/r-reversao-temporaria.diff`).

- O `godot.log` do Mestre tem `arranque: lugar do Mestre -> res://cenas/lobby/lobby.tscn (ORDEM-D-AUD-16)`, depois
  `pronto` e `ROOM_SNAPSHOT seq=5 fase=combate`. Esse `pronto` só pode ser o do lobby (`lobby.gd:84`), porque a arena
  sai do `_ready` (`return` depois de `_abrir_no_mestre()`) antes do `print` dela (`arena.gd:171`).
- `r02` (07:07:38) mostra o Mestre **no ecrã dele**, sem alertas: «[TESTE] Sala: em combate · Rodada 1 · vez de
  Heroína Teste», as abas Figuras / Agir / Mesa / Ambiente / Registo / Sala e as figuras da folha. O lobby só leva o
  Mestre ao ecrã dele por um caminho: `_verificar_fase` → `_ir(CENA_MESTRE)` (`lobby.gd:294-298`).
- `r01`/`r03` mostram a jogadora na arena dela, como sempre. O porteiro registou «o ecrã do Mestre (Godot) entrou na sala».
- 0 `ERROR` / 0 `SCRIPT ERROR` nos dois `godot.log`.

**Depois:** `git checkout -- rascunhos/cliente/cenas/arena/arena.gd`, e `arena.gd:23` voltou a `"res://cenas/mestre/mestre.tscn"`.
As suites do §5 correram **depois** disto. O teste que fixa a predefinição (`rodar_testes`, «predefinição: o Mestre
abre directo em mestre.tscn») passou, e os 333 / 333 confirmam que a constante ficou como estava.

**Fecho da bancada:** `parar-bancada.cmd` («Bancada parada.»). Ficaram 0 processos Godot e a porta 8790 sem ninguém à
escuta. Há dois `node.exe` vivos que **não são desta ordem** (um `desktop-commander`, aberto às 03:59) e um agente da
sessão 1 da `ordem-auditoria-linha-pc` (de 23/11, 13:55). Não lhes toquei. A tarefa agendada desta ordem (`DAud16Seg`)
foi parada e **apagada**.

## 3. F1/F4 — o rasto das provas

- **F1:** cada log em `provas/ordem-d-aud-16-seguimento/suites/` e `medicao/` abre com **`# comando: …`** (a linha
  exacta, com o directório de trabalho), depois `# hora: início …`, e fecha com `# hora: fim … rc=…`. O `RESUMO.txt`
  também. O executor está em `suites-executor.sh.txt`.
- **F4:** a saída dos comandos de captura, com as horas de cada captura, está cometida (`capturas-a-saida.txt`,
  `capturas-r-saida.txt`, ao lado dos comandos `capturas-*-comando.ps1.txt`). Além disso, cada PNG desta ordem traz
  agora um bloco `tEXt` **`Creation Time`** com essa hora, e um `Source` que diz de que saída vem.

## 4. A7 — os dois `pronto`

O `arranque.log` da D-AUD-16 (`provas/ordem-d-aud-16/suites/arranque.log`, linhas 4 e 5) vem do arranque **sem lugar
guardado**, o mesmo do passo «Arrancar a cena principal e esperar «pronto»» do CI. A cadeia é esta:

1. `arena.gd` `_ready`, l. 164: liga `Rede.precisa_entrar` → `_ao_precisa_entrar`; l. 167: `Rede.iniciar()`;
2. `rede.gd` `iniciar`: sem token, l. 125 `_pedir_entrada("")` → l. 509 `precisa_entrar.emit("")`;
3. `arena.gd` l. 190: `change_scene_to_file.call_deferred(CENA_LOBBY)`. A troca fica para o fim do quadro;
4. o `_ready` da arena continua e imprime o **1.º `pronto` (`arena.gd:171`)**;
5. no fim do quadro abre o lobby, e o `_ready` dele imprime o **2.º `pronto` (`lobby.gd:84`)**.

**Prova:** `medicao/dois-pronto-1-sem-marcas.log` (o código desta ordem, 2 × `pronto`) e
`medicao/dois-pronto-2-com-marcas.log`, com uma marca **temporária** em cada `print` (desfeita com `git checkout`, não
cometida): `pronto  <- arena.gd:171` e depois `pronto  <- lobby.gd:84`.

**Não é erro da bancada, e o registo estava certo.** O `RESUMO.txt` da D-AUD-16 dizia `pronto=2`. O que estava
impreciso era o ESTADO-FINAL dela (§4: «`pronto`, 0 `SCRIPT ERROR`»), que não dizia que eram dois nem porquê. Isto
acontece em todos os arranques sem lugar, desde sempre: os dois `print` são do CI (JV0.2), e o `grep -q pronto` aceita
um ou dois. No `RESUMO.txt` desta ordem a linha do arranque já diz porque são dois.

## 5. Suites no PC (Godot 4.7.2, `--headless`; Node), com a constante reposta

Corridas das 07:08:56 às 07:10:42, com `tmp/suites.sh` (`suites-executor.sh.txt`).

| suite | resultado | antes (D-AUD-16) |
|---|---|---|
| `abrir_scripts` | 112 scripts, 0 falhas | 111 (+1: `medir_ligacao_arranque.gd`) |
| `rodar_testes` | 333 / 333 (inclui «predefinição: o Mestre abre directo em mestre.tscn») | 333 |
| `abrir_clareira` | 22 / 22 | 22 |
| `medir_painel_config` | 0 falhas, 0 sem medida | igual |
| `abrir_mestre` | 67 / 67 | 67 |
| `pecas_mestre` | **307 / 307** (+10, §1.4) | 297 |
| `medir_mestre` | 0 falhas, 0 sem medida. A saída é igual, linha a linha, à da D-AUD-16 (tirando a linha de tempo da floresta): fora do arranque o rótulo novo está escondido e não ocupa lugar | igual |
| `hud_acoes` | 50 / 50 | 50 |
| `caixa_jogadora` | 70 / 70 | 70 |
| `caixa_janela` | 123 / 123 | 123 |
| `canario_privacidade` | 10 / 10 | 10 |
| `camera_segue` | 17 / 17 | 17 |
| arranque da cena principal (`--quit-after 600`, sem lugar) | 2 × `pronto` (§4), 0 `SCRIPT ERROR` | igual |
| servidor (`node --test testes/*.test.mjs`) | 442 / 442 (o servidor não mudou nesta ordem; os +7 são das ordens que entraram entre `1e2baab` e `ba01d1e`) | 435 |

Os 4 logs com o aviso pré-existente do Godot `Unicode parsing error ... Unexpected NUL character` são os mesmos da
D-AUD-16 (`abrir_mestre`, `canario_privacidade`, `medir_mestre`, `pecas_mestre`). É um aviso de leitura, não uma falha.

Todas sem `SCRIPT ERROR` / `Parse Error` / `Compile Error`. Os registos estão em `provas/ordem-d-aud-16-seguimento/suites/`,
cada um com a linha `# comando:` no topo.

## 6. Critérios da ordem

- [x] O ecrã do Mestre mostra «a ligar…» com o servidor fora do ar, sem nunca ter estado na mesa (`a01`, `a02`, §1.3),
  e o teste novo passa (`pecas_mestre` 307 / 307, §1.4).
- [x] O caminho de reversão foi corrido uma vez, com captura e log (§2). A predefinição continua «directo».
- [x] Cada log de suite traz a linha do comando (§3).
- [x] Os dois `pronto` estão explicados, com as linhas (§4).
- [x] Suites verdes (§5).
- [x] CI verde (Testes + Sonda): ver a nota do CI.
- [x] ESTADO-FINAL com os números e os commits (§7).
- [x] A C-7 não foi decidida. Não toquei no servidor, nos workflows, nos dados nem na `main`.

## 7. Commits

| commit | o quê |
|---|---|
| `7f83006` | A1: o rótulo «A ligar à mesa…» (`mestre.gd`, `textos_mestre.gd`), o teste novo (`pecas_mestre.gd`) e a ferramenta da medição (`medir_ligacao_arranque.gd`) |
| `ac9584a` | as listas da retoma sincronizadas depois de `7f83006` (`actualizar-listas`: 1 novo, 0 tirados) |
| `024d3e7` | as provas (`provas/ordem-d-aud-16-seguimento/`: README, capturas, logs, medição, suites) e este ESTADO-FINAL |

O `actualizar-listas.py` correu com `python` (o Python 3.12 do PC); no Windows, o `python3` é só o atalho da loja.
O commit das provas não muda `rascunhos/`, por isso as listas não precisam de nova passagem.
| (a seguir) | a nota do CI neste ESTADO-FINAL |

## Nota do CI

No `024d3e7` (código, listas, provas e este ESTADO-FINAL): **Testes dos rascunhos 45372456991: success** (os 10 jobs:
`provas-mapa`, `validador-glb`, `motor-real`, `godot-cliente`, `protocolo`, `retoma-pc`, `servidor`, `ponta-a-ponta`,
`cliente`, `foto-mestre`) · **Sonda de privacidade 45372457338: success**. O `ponta-a-ponta` (o Mestre Godot sem janela
pela ligação real) e o `foto-mestre` passaram com o rótulo novo.
