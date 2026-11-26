# Prova do Windows, guião endurecido — ORDEM-PLANO-2-F2-PROVA-WINDOWS-ENDURECER

Follow-up F1 da sentença da ORDEM-PLANO-2-F2-PROVA-WINDOWS (870). A corrida original (`../windows/corrida-30s/`,
guião de `a3d0cbc`) fica como estava; esta pasta traz as provas do guião endurecido.

## O que mudou no guião (`rascunhos/servidor/aparelhos/prova-windows.ps1`)

| | Antes (`a3d0cbc`) | Agora |
|---|---|---|
| **A2** exit do `--import` | só-registo (só o do export falhava) | exit ≠ 0 do import **falha a prova**, como o do export |
| **A8** `$filhos` vazio | «0 de 0» nas conferências, a prova seguia | espera até 10 s pelo processo do jogo filho do invólucro; sem ele **falha** |
| **A8** log em falta | `ausente` no registo, a prova seguia | cada processo arrancado regista o seu `.log` e `.err`; um em falta no passo 8 **falha** |
| **A8** «combate aberto» | afirmado sem ler a mesa | só se afirma depois de ler `[mesa-prova] combate aberto pelo Mestre-bot` no log da mesa; sem a linha **falha** |
| limpeza numa falha a meio | só matava o invólucro (o `Assimilacao.exe` podia ficar órfão) | pára os filhos do invólucro e depois o invólucro |
| `user://` do cliente | o `APPDATA` de sempre | um `APPDATA` próprio e vazio em `<sede>/tmp/prova-windows/appdata-cliente` (ver abaixo) |

A aceitação não mudou: o `.exe` entra, recebe o `ROOM_SNAPSHOT … fase=combate plataforma=Windows`, fica 30 s na
mesa (conferido de 5 em 5 s), morre pelo harness (`Stop-Process -Force`), e o `SAIU` tem de vir depois da morte.

### O `user://` isolado (achado do 1.º ensaio)

O 1.º ensaio (`ensaio-1-token-velho/`, 26/11 11:37) deu, nas corridas do guião endurecido que chegavam ao cliente,
uma 2.ª falha que não era a da condição: «o cliente Windows não recebeu o ROOM_SNAPSHOT em 60 s». As corridas
alternavam: endurecido falha, original passa, endurecido falha… (`resumo.txt` dessa pasta). A causa não é o
guião, é o estado no `APPDATA`: a corrida que entra deixa em `%APPDATA%/Godot/app_userdata/Assimilação/lugar.cfg`
um `seatToken`; a seguinte, contra uma mesa nova, tenta esse token (`rede.gd`, `iniciar()`: com token, liga com ele
e não lê o `--entrar-nome`), a mesa recusa com `credenciais`, o cliente esquece o token e volta ao lobby (o 2.º
`pronto` no `windows.log`), e não há `ENTROU`. O guião original tinha a mesma dependência escondida; o controlo
`import / original` desse ensaio passou por vir logo a seguir a uma corrida que esqueceu o token. Para a corrida de
26/11 da ordem original não há registo do `lugar.cfg` de então; o que se sabe é que entrou.

O guião passa a arrancar o cliente com `APPDATA` próprio e vazio (só o processo do cliente o vê; o Godot do
export continua a achar os modelos no `APPDATA` de sempre) e regista onde o cliente escreveu o `lugar.cfg`. O jogo
não mudou. A `corrida-30s-seguida/` é a corrida logo a seguir à `corrida-30s/` — o caso que antes falhava — e passa.

## `ensaio-endurecimentos.ps1` e `ensaios/` — cada endurecimento morde

```
powershell -NoProfile -ExecutionPolicy Bypass -File provas/ordem-plano-2-f2/windows-endurecer/ensaio-endurecimentos.ps1 -Godot <Godot_v4.7.2-stable_win64_console.exe>
```

Para cada condição, UMA substituição de texto numa **cópia de trabalho** do guião (`prova-windows.ensaio.ps1`, ao
lado do verdadeiro, apagada no fim de cada corrida e nunca cometida); o guião verdadeiro, o jogo e o servidor não
são tocados. Cada condição corre sobre o guião endurecido e, como controlo, sobre o original (`a3d0cbc`), com
`-SegundosNaMesa 5` e um `APPDATA` de ensaio limpo antes de cada corrida (cópia dos modelos de export; o
`app_userdata` apagado).

| Condição forçada (na cópia) | Endurecido | Original (controlo) |
|---|---|---|
| `import`: `--path pasta-que-nao-existe` (Godot sai com exit 1) | exit 1, **1 falha: `import com exit 1`** | exit 0, PROVA OK |
| `filhos`: o filtro procura `NaoExiste*` (`$filhos` vazio) | exit 1, **1 falha: `o invólucro de consola (pid …) não tem processo do jogo Assimilacao* ao fim de 10,3 s`** | exit 0, PROVA OK |
| `log`: o `windows.err` é apagado antes do passo 8 | exit 1, **1 falha: `log windows.err em falta`** | exit 0, PROVA OK |
| `combate`: a mesa sem `--mestre-auto` | exit 1, **1 falha: `a mesa ficou pronta sem a linha «[mesa-prova] combate aberto pelo Mestre-bot»`** | exit 1, mas só pelo efeito: `não recebeu o ROOM_SNAPSHOT em 60 s` (o padrão pede `fase=combate`) |

Em cada corrida endurecida a falha é **só** a da condição (nas três primeiras a Espadachim entrou na mesa e o resto
da prova correu). `restos: nenhum` em todas: nenhum `Assimilacao.exe` ficou vivo. Exit do ensaio 0. Resumo inteiro
em `ensaios/resumo.txt`; o `procedimento.log` e os logs de cada corrida em `ensaios/<condição>-<guião>/`.

## `corrida-30s/` — a corrida completa com o guião endurecido (26/11/2026, sobre `e02929b`)

Import (exit 0) + export (exit 0) do preset Windows, mesa, cliente, 30 s, morte, conferências:

| | |
|---|---|
| `combate aberto` | linha lida no log da mesa às 14:45:29.793 UTC |
| processo do jogo | 1 filho do invólucro (pid 3892 `Assimilacao.exe`), 1 de 1 vivo nas 6 conferências |
| `ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows` | 2,7 s depois de arrancar o cliente |
| na mesa | **30,019 s** depois do snapshot até à morte |
| ENTROU → SAIU (relógio da mesa) | 14:45:32.371 → 14:46:02.532 = **30,161 s** |
| MORTE pelo harness | 14:46:02.513 UTC; `SAIU` **19 ms** depois |
| erros de script | 0 |
| logs | os 8 (`import`, `export-Windows`, `mesa`, `windows`, `.log` + `.err`) presentes |
| exit do guião | **0** (`PROVA WINDOWS OK`) |

`corrida-30s-seguida/`: a mesma prova logo a seguir (14:46:10 UTC): snapshot em 2,7 s, ENTROU→SAIU **30,259 s**,
SAIU 18 ms depois da morte, exit 0.

SHA-256 dos `.exe` (no `procedimento.log`): `Assimilacao.exe` `7619461e…` (197 730 728 bytes),
`Assimilacao.console.exe` `52bdcae9…` (igual ao de `a3d0cbc`). Os `.exe` ficam em `build/` (no `.gitignore`).

## Suites (`suites/`)

`../windows/suites.sh` (o mesmo da ordem original), sobre `e02929b`, logs inteiros e `suites/resumo.txt` — **todas
com exit 0**:

| Suite | Resultado |
|---|---|
| `servidor` (Node) | 446/446 |
| `motor-real` (Node, motor privado fora do repo) | 6/6 |
| `prova-caixa` | exit 0 |
| `aparelhos_f2` | 46/46 |
| `abrir_scripts` | 113 scripts, 0 falhas |
| `rodar_testes` | 333/333 |
| `abrir_mestre` / `pecas_mestre` | 67/67 / 336/336 |
| `medir_mestre` | exit 0 |
| `hud_acoes` / `caixa_jogadora` / `caixa_janela` | 70/70 / 70/70 / 123/123 |
| `canario_privacidade` | 10/10 |
| `validar-mensagens` (pecas_mestre / abrir_mestre) | 30 / 9 mensagens, 0 falhas |

0 erros de script em todas as do Godot. Este clone tem `core.autocrlf=false`, por isso o `servidor` e o `motor-real`
passam aqui directamente (na ordem original, num clone CRLF, precisaram de um worktree LF). O `python` dos
`validar-mensagens` é um venv com `jsonschema` 4.26.0 fora do repo (a 1.ª passagem, com o `python` do sistema sem
`jsonschema`, deu exit 1 nos dois validadores por `ModuleNotFoundError`; refeita inteira com o venv). Nos dois logs do
Mestre, o caminho da máquina na linha «comandos escritos em …» foi trocado por `<sede>`, como na ordem original.
