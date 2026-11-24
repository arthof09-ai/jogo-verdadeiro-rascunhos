# ESTADO-FINAL — ORDEM-D-AUD-16 (o cliente do Mestre abre directo no ecrã dele)

**Estado: FEITA** (o CI fica na nota do fim). O cliente cujo lugar guardado é o do Mestre abre agora **directo em
`mestre.tscn`**. O cliente da jogadora continua a abrir em `arena.tscn`, e o fluxo do lobby dela não mudou. Está provado
na bancada de rede, com os dois clientes Godot abertos ao mesmo tempo. As suites do PC estão verdes.

- **Executor:** Claude (opus), PC, conta 2. **Data:** 24/11/2026, ~02:59–03:25 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `b149a7b` (a nota do CI da D-AUD-01-CORRECCOES-3). `git fetch` antes do commit: não andou.
- **Commits:** `d0dfb00` (código + testes), `97dc8c1` (listas da retoma), `a2c3c83` (provas e este ESTADO-FINAL) e
  `3d8c187` (nota do CI neste ESTADO-FINAL).
- **Não toquei** no servidor, nos workflows, nos dados, no `project.godot`, no lobby nem no arranque da jogadora.

## 1. A causa e a correcção

A causa é a que a INVESTIGA mediu: a cena principal é `arena.tscn` (`project.godot:11`), e só o `lobby.gd`
(`_verificar_fase`) manda o Mestre para o ecrã dele. O cliente é um só, e o papel vem do `user://lugar.cfg`. Com o lugar
do Mestre guardado, a Rede entrava directamente com o token, e o lobby nunca chegava a abrir. O Mestre ficava na arena
da jogadora.

Mudar a cena principal mudava também o arranque da jogadora, e por isso não a mudei. A decisão passou para o arranque:

| ficheiro | mudança |
|---|---|
| `rascunhos/cliente/rede/rede.gd` | `papel_do_arranque()`: lê o papel do `lugar.cfg` **antes de ligar**. Usa as mesmas regras do `_carregar_lugar` (o mesmo servidor) e só conta com token. Devolve `""` se a Rede já arrancou (veio do lobby), sem disco (testes) ou no link de medição. **Só lê.** `papel_do_lugar(cfg, servidor)` é a parte pura (testada) |
| `rascunhos/cliente/cenas/arena/arena.gd` | Logo no início do `_ready`: se a arena é a **cena principal** e `Rede.papel_do_arranque() == "mestre"`, então `_abrir_no_mestre()`. A arena fica parada e escondida, imprime a linha do log, chama `Rede.iniciar()` e troca para `CENA_ARRANQUE_MESTRE`. A arena não chega a montar. Em qualquer outro caso (jogadora, sem lugar, lugar sem token, vindo do lobby, arena instanciada por testes e ferramentas), o `_ready` corre como antes, linha a linha |
| `rascunhos/cliente/cenas/mestre/mestre.gd` | `_ao_ligacao`: o alerta «A ligação caiu; a tentar de novo.» só aparece se o Mestre **já esteve na mesa** (`Rede.ja_esteve_na_mesa()`). Esta mudança veio do arranque directo: o ecrã do Mestre passa a abrir com a ligação ainda a abrir, o que nunca acontecia pelo lobby, e na 1.ª corrida da bancada o painel abriu com «Alertas: 1» falso. Uma queda a sério continua a dar o alerta (testado) |

**A linha do log** (no `godot.log` do cliente do Mestre):
`arranque: lugar do Mestre -> res://cenas/mestre/mestre.tscn (ORDEM-D-AUD-16)`.

**Limite conhecido:** no arranque directo, com o servidor fora do ar, o ecrã do Mestre abre e volta a tentar ligar em silêncio — o alerta «A ligação caiu» só aparece depois de o Mestre já ter estado na mesa (`mestre.gd:654-660`), e não há outro aviso de ligação no ecrã dele — impreciso no sentido largo: o alerta
pré-existente da vista (Ordem 49) aparece aos ~10 s neste arranque; ver
ORDEM-D-AUD-16-SEGUIMENTO §1.3. O «Conectando à mesa…» do lobby (`lobby.gd:284`) fica fora deste arranque. A correcção (um estado «a ligar…» visível até ao primeiro WELCOME, com teste no `pecas_mestre` para o `A_ESPERAR` sem nunca ter estado na mesa) fica para uma ordem seguinte.

## 2. A predefinição reversível (C-7 é do Mestre)

A predefinição é do coordenador: o Mestre abre **directo** no ecrã dele, sem passar pelo lobby. **Não decidi a C-7.**

- **Para reverter para «passa pelo lobby»** muda uma linha, em `rascunhos/cliente/cenas/arena/arena.gd`:
  `const CENA_ARRANQUE_MESTRE := "res://cenas/mestre/mestre.tscn"` passa a `"res://cenas/lobby/lobby.tscn"`. O lobby abre
  com a Rede já a ligar e, quando chega o WELCOME, o `_verificar_fase` manda o Mestre para o ecrã dele (o caminho de
  sempre do lobby). Este caminho **não foi corrido na bancada** nesta ordem.
- Há um teste do `rodar_testes` que **fixa** a predefinição («predefinição: o Mestre abre directo em mestre.tscn»). Se a
  linha mudar, o teste falha até ser actualizado com ela. Está assim de propósito: ninguém muda a predefinição sem dar por isso.

## 3. A prova na bancada de rede (`provas/ordem-d-aud-16/`)

`bancada-rede/lancar.ps1 -SemEspera -HostServidor 127.0.0.1 -Motor auto` (fichas `canario`, porteiro com a batalha
preparada). Correram o servidor de produção e **dois clientes Godot 4.7.2 com janela, em simultâneo**, ambos pela cena
principal, cada um com o seu `user://` e o lugar que o porteiro lá deixou. A bancada correu na sessão 1, através de um
agente por tarefa agendada, como na D-AUD-04. As capturas são das 03:16:17 (-03).

| | jogadora | Mestre |
|---|---|---|
| ecrã | `arena.tscn`: «A sua vez», Ataque / Mover / Consumível / Encerrar (`c01`) | `mestre.tscn`: abas Figuras / Agir / Mesa / Ambiente / Registo / Sala, «Rodada 1 · vez de Heroína Teste», **sem alertas** (`c02`) |
| log | `pronto` + `ROOM_SNAPSHOT seq=4 fase=combate` | **`arranque: lugar do Mestre -> res://cenas/mestre/mestre.tscn (ORDEM-D-AUD-16)`** + `ROOM_SNAPSHOT seq=5 fase=combate`; sem `pronto` (a arena não montou) |
| erros | 0 `ERROR` / 0 `SCRIPT ERROR` | 0 `ERROR` / 0 `SCRIPT ERROR` |

`c03` mostra as duas janelas no mesmo instante. O porteiro registou «o ecrã do Mestre (Godot) entrou na sala». O «antes»
está nas capturas da INVESTIGA (`l01-mestre-abre-na-arena-da-jogadora`, `i00-mestre-inicio-bancada-preparada`).

**Fecho da bancada:** `parar-bancada.cmd`. Ficaram 0 processos Godot e node, e a porta 8790 está livre. As duas tarefas
agendadas desta ordem (`DAud16S1`, `DAud16S1b`) foram paradas e **apagadas**. Ficou um `ffmpeg` vivo que **não é
desta ordem** (`ordem-plano-2-f1-pc\tmp\ffmpeg.exe`, aberto às 01:59) e que não toquei.

## 4. Suites no PC (Godot 4.7.2, `--headless`; Node), depois da correcção final

| suite | resultado |
|---|---|
| `abrir_scripts` | 111 scripts, 0 falhas |
| `rodar_testes` | **333 / 333** (12 verificações novas: «Arranque do cliente pelo lugar guardado») |
| `abrir_clareira` | 22 / 22 |
| `medir_painel_config` | 0 falhas, 0 sem medida |
| `abrir_mestre` | 67 / 67 |
| `pecas_mestre` | **297 / 297** (2 novas: a ligação a abrir no arranque não dá alerta; a queda depois de estar na mesa dá) |
| `medir_mestre` | 0 falhas, 0 sem medida |
| `hud_acoes` | 50 / 50 |
| `caixa_jogadora` | 70 / 70 |
| `caixa_janela` | 123 / 123 |
| `canario_privacidade` | 10 / 10 |
| `camera_segue` | 17 / 17 |
| arranque da cena principal (`--quit-after 600`, sem lugar) | `pronto`, 0 `SCRIPT ERROR` |
| servidor (`node --test testes/*.test.mjs`) | 435 / 435 (não mudou; corri-o por inteireza) |

Todas sem `SCRIPT ERROR` / `Compile Error` (0 ocorrências em todos os logs). Nota: 4 logs trazem na linha 3 o aviso pré-existente do Godot `Unicode parsing error ... Unexpected NUL character` (`abrir_mestre`, `canario_privacidade`, `medir_mestre`, `pecas_mestre`) — aviso de leitura, não falha; já existia na ordem anterior e nenhum ficheiro desta ordem tem bytes NUL. Os registos estão em `provas/ordem-d-aud-16/suites/`.

## 5. Critérios da ordem

- [x] O cliente do Mestre abre em `mestre.tscn`: captura `c02` e a linha do log (`logs/godot-mestre.log`, l. 4).
- [x] O cliente da jogadora continua em `arena.tscn` (`c01`, `pronto` no log), e o lobby dela não mudou.
- [x] Os dois clientes estiveram abertos em simultâneo na bancada de rede (`c03`).
- [x] Suites do PC verdes (§4).
- [x] CI verde (Testes + Sonda): ver a nota do CI.
- [x] Listas da retoma sincronizadas depois do commit em `rascunhos/` (`97dc8c1`: 0 novos, 0 tirados).
- [x] A C-7 não foi decidida. A predefinição é reversível e a linha da reversão está no §2.

## Nota do CI

No `a2c3c83` (código, listas, provas e este ESTADO-FINAL): **Testes dos rascunhos 45339473687: success** (os 10 jobs, incluindo `cliente`, `godot-cliente`, `ponta-a-ponta`, `foto-mestre` e `retoma-pc`) · **Sonda de privacidade 45339473715: success**.

Na ponta `3d8c187`: **Testes dos rascunhos 45340029866: success** · **Sonda de privacidade 45340029870: success** (o código é idêntico ao do `a2c3c83`; só este ESTADO-FINAL mudou).
