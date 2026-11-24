# ESTADO-FINAL — ORDEM-D-AUD-16-SEGUIMENTO-B1 (a corrida viva do ramo `DESLIGADA` → lobby do `mestre.gd`)

**Estado: FEITA COM RESSALVA.** O ramo foi corrido vivo e está provado, mas **não pelo arranque que a ordem
descreve**. O lugar de papel mestre **sem token** não chega ao ramo. Corri-o como a ordem pede e ele leva ao lobby
**pela arena**, sem abrir o ecrã do Mestre. Por isso a linha `ecrã do Mestre aberto sem ligação (estado 0)` não
aparece no `godot.log` (§1). O ramo correu vivo numa 2.ª corrida, com a guarda da rede local do Android, que é a
origem real da `DESLIGADA` antes da cena (§2). Para isso foi preciso uma mudança de uma linha, **só na cópia de
trabalho e só durante a corrida**. Fica para o coordenador decidir se esta prova serve para a errata E-1 (§4).

- **Executor:** Claude (opus), PC, conta 2. **Data:** 24/11/2026, ~11:59–12:15 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. **Ponta de partida:** `a4c2668`. A `main` não foi tocada.
- **Código:** nenhuma mudança cometida. Esta ordem só junta provas e este ESTADO-FINAL, e não toca em `rascunhos/`.
- **A C-7 não foi decidida.** A predefinição continua «directo» (`arena.gd:23`, sem mudança).
- **Não toquei** no servidor, nos workflows, nos dados, na `main` nem no cliente da jogadora.

## 1. Corrida A — o arranque da ordem (lugar de papel mestre sem token): **não chega ao ramo**

### 1.1 Porquê

A ordem diz que a arena «chama `Rede.iniciar()`, que carrega o lugar (papel mestre) sem ligar, e muda para o ecrã
do Mestre com a Rede `DESLIGADA`». O código não faz isso. A arena só muda para o ecrã do Mestre quando
`Rede.papel_do_arranque() == "mestre"` (`arena.gd:143`). O `papel_do_arranque` usa o `papel_do_lugar`
(`rede.gd:724–730`), que **devolve `""` quando o lugar não tem token** (`rede.gd:727`). O comentário diz: «sem
token a Rede pede a entrada: o arranque fica o de sempre». Por isso, sem token:

1. a arena monta-se como a cena da jogadora (a floresta carrega);
2. liga o `precisa_entrar` (`arena.gd:166`) e chama o `Rede.iniciar()`;
3. a Rede carrega o lugar (papel `mestre`), não tem token, e pede a entrada (`_pedir_entrada("")`);
4. a arena muda para o lobby (`arena.gd:186–190`).

O `mestre.tscn` nunca chega a ser instanciado.

### 1.2 O que a corrida mostrou

Corri o arranque directo com janela, às 12:06:18. O lugar era `ws://127.0.0.1:8790/ws`, com `seatToken=""` e papel
`mestre`; o servidor estava fora do ar. Antes, às ~12:00, fiz a mesma corrida sem janela.

- `a01` (12:06:30, t = 12 s) e `a02` (12:06:43, t = 25 s): aparece o lobby, mas **no modo da jogadora** («Entre com
  o nome da sua personagem e a senha.» / «Sou o Mestre»), sem motivo.
- `godot.log`: a floresta da arena, depois `pronto` e `pronto` (arena e lobby). **Não aparece** `arranque: lugar do
  Mestre -> …`, **nem** `ecrã do Mestre aberto sem ligação`. O log é igual ao do arranque sem lugar.

**Conclusão:** a frase corrigida do ESTADO-FINAL da D-AUD-16-SEGUIMENTO-B, §1.3 («esse arranque deixa a Rede
`DESLIGADA` com o papel certo e o ramo dispara»), **também é inexacta**. O papel fica certo e a Rede fica
`DESLIGADA`, mas quem abre o lobby é a arena, e o ramo do `mestre.gd` não corre. A frase original («no PC não há
maneira de o provocar sem mexer no código») **está certa** para o código desta linha. Procurei outras maneiras e
não encontrei nenhuma:
- com token, o `_ligar()` passa a `A_LIGAR` (ou a `A_ESPERAR`, se o `connect_to_url` falhar). Não passa a `DESLIGADA`;
- a única `DESLIGADA` no `_ligar()` é a guarda do Android (`rede.gd:426`), e essa só dispara com
  `OS.has_feature("android")`;
- as outras `DESLIGADA` (`ERRO` em `A_ENTRAR`, `montar_join` vazio, `sair()`) e a `PARADA` por outro aparelho
  precisam de uma ligação aberta. Não acontecem no quadro que vai do `_abrir_no_mestre` ao `_ready` do Mestre;
- correr o `mestre.tscn` como cena principal está fora: a ordem proíbe-o, e nesse caso ninguém chama o
  `Rede.iniciar()`, por isso o papel continua `jogadora` e a cena recusa.

## 2. Corrida B — o ramo vivo, pela guarda do Android

O caso real que o comentário do ramo cita é a guarda da rede local do Android (`mestre.gd:219`). No PC essa guarda
só dispara se o `OS.has_feature("android")` for forçado a verdadeiro. Fiz isso numa linha
(`provas/…/logs/b-guarda-android-temporaria.diff`), **só na cópia de trabalho e só durante a corrida**. É o mesmo
processo do `b-versao-temporaria.diff` da D-AUD-16-SEGUIMENTO-B. No fim desfiz a mudança com `git checkout`, e o
`git status` ficou limpo.

O lugar tinha papel `mestre`, **com** token, e o servidor `ws://servidor-de-fora.example:8790/ws`, fora da rede
local. A guarda pára antes de haver DNS ou socket. O caminho foi este:

1. arena → `_abrir_no_mestre()`;
2. `Rede.iniciar()` → `_ligar()` → a guarda → `DESLIGADA` + `precisa_entrar("rede_local")`, antes de a cena do
   Mestre existir;
3. `mestre.gd` `_ready`: papel `mestre`, `current_scene == self`, `abre_sem_saida(DESLIGADA)` → **o ramo** → lobby.

- `godot.log` (com janela, às 12:06:59; e sem janela, às ~12:01): **`arranque: lugar do Mestre ->
  res://cenas/mestre/mestre.tscn (ORDEM-D-AUD-16)`**, depois **`ecrã do Mestre aberto sem ligação (estado 0): para
  o lobby`**, depois `pronto` (o lobby). Não carrega a floresta (a arena não chega a montar-se). 0 `ERROR`.
- `b01` (12:07:12, t = 12 s) e `b02` (12:07:25, t = 25 s): o lobby **no modo do Mestre** («Entre com o PIN do
  Mestre.»), com o motivo **«Este endereço não é da rede de casa. Peça ao Mestre o link certo.»**. Fica no lobby e
  não volta ao Mestre.

A corrida B com janela foi feita duas vezes. A 1.ª, às 12:04:45, deu o mesmo log e as mesmas imagens, mas o comando
tinha um erro no nome dos ficheiros das capturas. Corrigi-o e repeti, para que o comando cometido seja exactamente
o que correu (README das provas, §2).

## 3. Suites no PC (Godot 4.7.2, `--headless`; Node), de 12:07:49 a 12:10:03

| suite | resultado |
|---|---|
| `abrir_scripts` | 112 scripts, 0 falhas |
| `rodar_testes` | 333 / 333 (inclui «predefinição: o Mestre abre directo em mestre.tscn») |
| `abrir_clareira` | 22 / 22 |
| `medir_painel_config` | 0 falhas, 0 sem medida |
| `abrir_mestre` | 67 / 67 |
| `pecas_mestre` | 329 / 329 (inclui o `abre_sem_saida` do `_seguimento_b`) |
| `medir_mestre` | 0 falhas, 0 sem medida |
| `hud_acoes` | 50 / 50 |
| `caixa_jogadora` | 70 / 70 |
| `caixa_janela` | 123 / 123 |
| `canario_privacidade` | 10 / 10 |
| `camera_segue` | 17 / 17 |
| arranque da cena principal (sem lugar) | 2 × `pronto`, 0 `SCRIPT ERROR` |
| servidor (`node --test testes/*.test.mjs`) | 446 / 446 |

O `pecas_mestre` passou de 325 para 329 e o servidor de 442 para 446 desde a D-AUD-16-SEGUIMENTO-B. Essas
verificações vieram de ordens que entraram na linha entre as duas; esta ordem não juntou nenhuma. Nenhuma suite tem
`SCRIPT ERROR`, `Parse Error` ou `Compile Error`. Os logs estão em `provas/ordem-d-aud-16-seguimento-b1/suites/`, e
o executor em `suites-executor.sh.txt`.

**Fecho:** o agente da sessão 1 foi parado e a tarefa agendada `DAud16SegB1` foi **apagada**. Ficaram 0 processos
Godot. Não houve servidor nesta ordem.

## 4. Critérios da ordem

- [~] **O lobby aparece no arranque directo com lugar de papel mestre sem token:** aparece, mas pela arena, não pelo
  ramo (§1).
- [~] **O `godot.log` traz `ecrã do Mestre aberto sem ligação (estado 0)`:** **não traz** no arranque sem token (§1).
  Traz na corrida B (§2), que precisou de uma mudança temporária, não cometida.
- [x] Captura do lobby cometida (as quatro: `a01`/`a02` e `b01`/`b02`).
- [x] Suites verdes (§3).
- [x] CI verde (Testes + Sonda) no `b159e9a`: ver a nota do CI.
- [x] ESTADO-FINAL com os números e os commits (§5).
- [x] A C-7 não foi decidida. Não toquei no servidor, nos workflows, nos dados, na `main` nem no cliente da
  jogadora.

**Para o coordenador (errata E-1 da sentença 885).** Os factos desta corrida são três:
- o recipe «sem token» não dispara o ramo;
- a frase original do §1.3 («no PC não há maneira de o provocar sem mexer no código») estava certa;
- com uma linha temporária a forçar a guarda do Android, o ramo dispara vivo e leva ao lobby com o motivo certo.

Se for preciso provar o ramo sem mexer no código, há dois caminhos: um aparelho Android real (um APK com um lugar de
Mestre a apontar para fora da rede local) ou um gancho de teste no código. Os dois são decisões do coordenador; não
fiz nenhum deles.

## 5. Commits

| commit | o quê |
|---|---|
| `b159e9a` | as provas (`provas/ordem-d-aud-16-seguimento-b1/`) e este ESTADO-FINAL |

Nenhum commit desta ordem muda `rascunhos/`, por isso não foi preciso passar o `actualizar-listas.py`.

## Nota do CI

No `b159e9a` (as provas e este ESTADO-FINAL), os dois workflows deram `success`:
- **Testes dos rascunhos 45422561272:** passaram os 10 jobs — `motor-real`, `foto-mestre`, `cliente`, `servidor`,
  `validador-glb`, `retoma-pc`, `protocolo`, `ponta-a-ponta`, `godot-cliente` e `provas-mapa`;
- **Sonda de privacidade 45422561586.**

Depois disso só entrou o commit desta nota, que muda só este ficheiro.
