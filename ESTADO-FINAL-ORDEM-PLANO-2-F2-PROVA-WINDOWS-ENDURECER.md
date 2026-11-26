# ESTADO-FINAL — ORDEM-PLANO-2-F2-PROVA-WINDOWS-ENDURECER (o guião da prova do Windows endurecido; F1 da sentença 870)

**Estado: FEITA.** Saíram do guião `rascunhos/servidor/aparelhos/prova-windows.ps1` a excepção do import (A2) e as
três verificações só-registo (A8). As quatro condições foram forçadas, uma a uma, numa cópia de trabalho do guião,
e cada uma faz a prova falhar com a sua falha, e só com essa. A corrida completa passou duas vezes seguidas com o
guião endurecido (30 s na mesa, `ROOM_SNAPSHOT`, morte pelo harness). As suites estão todas verdes. O CI fica na
Nota do CI, no fim.

Pelo caminho apareceu um defeito que a ordem não previa: um `seatToken` velho no `APPDATA` fazia a prova falhar
uma corrida sim, outra não. Ficou corrigido no guião, sem tocar no jogo (§2).

- **Executor:** Claude (opus), PC (conta 2). **Data:** 26/11/2026, ~10:30–12:00 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main`, o servidor e os dados não foram tocados. Os
  documentos da corrida original (`ESTADO-FINAL-ORDEM-PLANO-2-F2-PROVA-WINDOWS.md`, `provas/ordem-plano-2-f2/windows/`)
  também ficam como estavam.
- **Ponta de partida:** `db0fa6c`. Os dois primeiros commits desta ordem (`c2c0280` e `881616b`) vieram de uma 1.ª
  sessão que parou antes de correr o ensaio; esta sessão retomou a partir deles.

## 1. Os endurecimentos (itens 1 e 2) — `c2c0280`

| | Antes (`a3d0cbc`) | Agora |
|---|---|---|
| **A2**, exit do `--import` | só registado | exit ≠ 0 → `FALHA: import com exit N`, como o do export |
| **A8**, `$filhos` vazio | «0 de 0» e a prova seguia | espera até 10 s pelo `Assimilacao*` filho do invólucro; sem ele, `throw` → FALHA |
| **A8**, log em falta | «ausente» e a prova seguia | cada processo arrancado (`Iniciar`) junta o seu `.log` e `.err` à lista do passo 8; um em falta → FALHA |
| **A8**, «combate aberto» | escrito sem verificar | só se escreve depois de ler `[mesa-prova] combate aberto pelo Mestre-bot` no log da mesa; sem a linha, `throw` → FALHA |

Junto com isto, a limpeza de uma prova que falhe a meio passou a parar também os filhos do invólucro, para não
deixar um `Assimilacao.exe` órfão. A aceitação não mudou.

## 2. O `user://` do cliente isolado — `52ce824` (achado do 1.º ensaio)

O 1.º ensaio (11:37, `provas/ordem-plano-2-f2/windows-endurecer/ensaio-1-token-velho/`) mordeu nas quatro
condições, mas três das corridas endurecidas acrescentaram uma 2.ª falha que não era a da condição: «o cliente Windows
não recebeu o ROOM_SNAPSHOT em 60 s». As corridas alternavam entre falhar (endurecido) e passar (original).

A causa:
1. A corrida que entra deixa um `seatToken` em
   `%APPDATA%/Godot/app_userdata/Assimilação/lugar.cfg`.
2. Na corrida seguinte, a mesa é nova. O `Rede.iniciar()` vê o token e liga com ele, sem ler o `--entrar-nome`.
3. A mesa recusa o token com `credenciais`. O cliente esquece-o e volta ao lobby (o 2.º `pronto` no `windows.log`),
   e não há `ENTROU`.

O guião original tinha a mesma dependência escondida.

A correcção está só no guião:
- O cliente arranca com `APPDATA=<sede>/tmp/prova-windows/appdata-cliente`, que é refeito vazio em cada corrida.
- Só o processo do cliente vê esse `APPDATA`. O Godot do export continua a achar os modelos no `APPDATA` de sempre.
- O guião regista onde o cliente escreveu o `lugar.cfg`.

O guião de ensaio corre agora as oito corridas com um `APPDATA` de ensaio limpo, para o controlo do original também
ser justo. O jogo não mudou.

## 3. Cada endurecimento morde (item 3) — `ensaios/`, sobre `e02929b`

`provas/ordem-plano-2-f2/windows-endurecer/ensaio-endurecimentos.ps1` aplica UMA substituição de texto a uma cópia de
trabalho do guião (`prova-windows.ensaio.ps1`, apagada no fim de cada corrida e nunca cometida). Cada condição corre
sobre o guião endurecido e, como controlo, sobre o original de `a3d0cbc`, com `-SegundosNaMesa 5`.

| Condição forçada | Endurecido | Original (controlo) |
|---|---|---|
| import: `--path pasta-que-nao-existe` | **exit 1**, 1 falha: `import com exit 1` | exit 0, PROVA OK |
| filhos: o filtro procura `NaoExiste*` | **exit 1**, 1 falha: `o invólucro de consola (pid 18284) não tem processo do jogo Assimilacao* ao fim de 10,3 s` | exit 0, PROVA OK |
| log: o `windows.err` é apagado antes do passo 8 | **exit 1**, 1 falha: `log windows.err em falta` | exit 0, PROVA OK |
| combate: a mesa sem `--mestre-auto` | **exit 1**, 1 falha: `a mesa ficou pronta sem a linha «[mesa-prova] combate aberto pelo Mestre-bot»` | exit 1, só pelo efeito: `não recebeu o ROOM_SNAPSHOT em 60 s` |

O ensaio saiu com exit 0: «as quatro condições fazem o guião endurecido falhar».
- Nas três primeiras condições, a Espadachim entrou na mesa e a falha veio só da condição.
- Em todas as corridas, `restos: nenhum`: nenhum `Assimilacao.exe` ficou vivo.
- O controlo mostra o que o guião de `a3d0cbc` deixava passar: o import partido, o «0 de 0» e o log em falta.

## 4. A corrida completa (item 4) — `corrida-30s/`, sobre `e02929b`

| | |
|---|---|
| import / export | exit 0 / exit 0 (export 47 242 B de log) |
| combate aberto | linha lida no log da mesa (14:45:29.793 UTC) |
| processo do jogo | pid 3892 `Assimilacao.exe`, 1 de 1 vivo nas 6 conferências |
| `ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows` | 2,7 s depois de arrancar o cliente |
| na mesa até à morte | **30,019 s** |
| ENTROU → SAIU (relógio da mesa, UTC) | 14:45:32.371 → 14:46:02.532 = **30,161 s** |
| MORTE pelo harness (`Stop-Process -Force`) | 14:46:02.513 UTC; o `SAIU` veio **19 ms** depois |
| erros de script | 0 |
| logs | os 8 presentes, em UTF-8, com `<sede>`/`<casa>` |
| exit do guião | **0** — `PROVA WINDOWS OK` |

`corrida-30s-seguida/` é a mesma prova corrida logo a seguir. Era o caso que antes alternava, e passou:
- snapshot em 2,7 s;
- ENTROU→SAIU = **30,259 s**;
- `SAIU` 18 ms depois da morte;
- exit 0.

Os SHA-256 dos `.exe` estão no `procedimento.log`:
- `Assimilacao.exe`: `7619461e229abaa5…` (197 730 728 B);
- `Assimilacao.console.exe`: `52bdcae9068e8d23…`, o mesmo da corrida original.

## 5. Suites — `provas/ordem-plano-2-f2/windows-endurecer/suites/`, sobre `e02929b`

Correram com `provas/ordem-plano-2-f2/windows/suites.sh`, o da ordem original, e deram todas **exit 0**:

| Suite | Resultado |
|---|---|
| servidor | 446/446 |
| motor-real | 6/6 |
| prova-caixa | exit 0 |
| aparelhos_f2 | 46/46 |
| abrir_scripts | 113 scripts, 0 falhas |
| rodar_testes | 333/333 |
| abrir_mestre | 67/67 |
| pecas_mestre | 336/336 |
| medir_mestre | exit 0 |
| hud_acoes | 70/70 |
| caixa_jogadora | 70/70 |
| caixa_janela | 123/123 |
| canario_privacidade | 10/10 |
| validar-mensagens | 30 + 9 mensagens, 0 falhas |

As suites do Godot deram 0 erros de script.
- **Fim de linha:** este clone tem `core.autocrlf=false`, por isso o `servidor` e o `motor-real` passam directamente,
  sem worktree LF.
- **Motor real:** veio da pasta privada da bancada da D-AUD-06 (`MOTOR_MJS`, fora do repo) e não foi copiado.
- **Validador:** o `python` com `jsonschema` 4.26.0 é o venv da D-AUD-01-CORRECCOES-4, fora do repo. A 1.ª passagem
  usou o `python` do sistema, que não tem `jsonschema`, e deu exit 1 nos dois validadores (`ModuleNotFoundError`). A
  passagem foi refeita inteira com o venv.

## 6. Commits

| Commit | O quê |
|---|---|
| `c2c0280` | passos 1 e 2: A2 e as três A8 no guião |
| `881616b` | passo 3: o guião de ensaio (1.ª versão) |
| `678577c` | listas da retoma sincronizadas depois do `c2c0280` (1 SHA mudado) |
| `52ce824` | o `user://` do cliente isolado no guião; o ensaio com `APPDATA` limpo e com a linha «entrou na mesa» |
| `e02929b` | listas da retoma sincronizadas depois do `52ce824` |
| `7f18be3` | passos 3 e 4: os ensaios, as duas corridas de 30 s, as suites e o README das provas |
| este | o ESTADO-FINAL |

Corri `python3 retoma-i0004/actualizar-listas.py` depois de cada commit que mudou ficheiros em `rascunhos/`
(`c2c0280` e `52ce824`).

## 7. Perímetro

- Não toquei no jogo (`rascunhos/cliente`), no servidor nem nos dados. O único ficheiro de `rascunhos/` que mudou é o
  `prova-windows.ps1`.
- A aceitação da prova é a mesma: 30 s na mesa, o `ROOM_SNAPSHOT … fase=combate plataforma=Windows` e a morte pelo
  harness.
- As provas não trazem o caminho da máquina: o guião escreve `<sede>`/`<casa>`, e nos dois logs do Mestre a linha
  «comandos escritos em …» foi trocada à mão por `<sede>`.
- Fica para decidir, como na ordem original: o job `windows` do CI continua a matar o `.exe` logo a seguir ao
  snapshot, porque o workflow não foi mudado. Agora há também o seguinte: o job `windows` não tem `lugar.cfg` velho
  (corre numa máquina limpa), por isso o defeito do §2 não o afecta.

## Nota do CI

(por preencher depois do push)
