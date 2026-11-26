# ESTADO-FINAL — ORDEM-PLANO-2-F2-PROVA-WINDOWS (o guião da prova do Windows; B-3 da sentença 595)

**Estado: FEITA.** O procedimento da prova do Windows está cometido em
**`rascunhos/servidor/aparelhos/prova-windows.ps1`** e correu do princípio ao fim neste PC: o `.exe` exportado entrou,
recebeu o `ROOM_SNAPSHOT` e **ficou 30 s na mesa** (ENTROU→SAIU = **30,201 s** no relógio da mesa), até o harness o
matar por comando, com o instante registado. Os logs estão inteiros, com o exit code, e em UTF-8. As suites estão
verdes (com a ressalva do CRLF do clone, §3). O CI está na Nota do CI no fim.

- **Executor:** Claude (opus), PC (conta 2). **Data:** 26/11/2026, ~07:38–08:10 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada.
- **Ponta de partida:** `acffac1` (clone). Antes de cometer, o `git fetch` deu `e2d784a`: um só commit novo, que só
  muda `ESTADO-FINAL-ORDEM-D-AUD-14-SEGUIMENTO-MUTACAO.md` (3 linhas). Reabri os meus commits sobre `e2d784a` sem
  conflitos. O código do cliente e do servidor é o mesmo nas duas pontas, por isso a prova e as suites, corridas
  sobre `acffac1`, valem para a ponta nova.

## 1. O procedimento (item 1 da ordem)

`rascunhos/servidor/aparelhos/prova-windows.ps1`, para o Windows PowerShell 5.1 (UTF-8 com BOM, para que o 5.1 leia
os acentos):

```
powershell -NoProfile -ExecutionPolicy Bypass -File rascunhos/servidor/aparelhos/prova-windows.ps1 -Godot <Godot_v4.7.2-stable_win64_console.exe>
   [-SemExport] [-Saida <pasta>] [-Porta 8090] [-SegundosNaMesa 30]
```

Os passos, cada um com a hora no `procedimento.log` (UTC, o relógio da mesa, e local -03):

1. `--import` e `--export-release Windows` (o preset do `export_presets.cfg`), com o exit de cada um. Depois o tamanho
   e o SHA-256 dos dois `.exe`. Com `-SemExport`, usa o `build/windows` que lá estiver.
2. `node aparelhos/mesa-prova.mjs --porta=8090 --host=127.0.0.1 --pin=11223344 --mestre-auto` (os argumentos da
   corrida de 24/11). Espera o `pronto-mesa-prova`.
3. O cliente arranca **com a citação corrigida**:
   `Start-Process build/windows/Assimilacao.console.exe -ArgumentList '--headless','--','--servidor=127.0.0.1:8090','"--entrar-nome=Espadachim de Bancada"','--entrar-senha=prova-espadachim'`.
   O `Start-Process` junta os argumentos sem aspas, e foi por isso que na corrida de 24/11 o nome chegava partido
   em três (ESTADO-FINAL da F2, §2). O guião lê do `Win32_Process` a linha de comando que o Windows **de facto**
   entregou, ao invólucro de consola e ao processo do jogo (`Assimilacao.exe`, filho do invólucro), e escreve-a no log.
4. Espera a linha `rede: ROOM_SNAPSHOT seq=… fase=combate plataforma=Windows` do cliente (60 s no máximo).
5. Deixa o cliente na mesa durante `SegundosNaMesa` (30 s). De 5 em 5 s confere que os processos estão vivos e que a
   mesa não registou `SAIU`. Se o cliente sair sozinho, ou se o `SAIU` vier antes da hora, a prova falha.
6. **A morte, pelo harness:** `Stop-Process -Force` ao processo do jogo e depois ao invólucro. Ficam registados os
   pids, o instante (UTC e local) e o exit code do invólucro.
7. Espera o `SAIU` na mesa, pára a mesa (`Stop-Process -Force`, com o exit) e confere quatro coisas: que há ENTROU e
   SAIU com horas, que SAIU − ENTROU ≥ 30 s, que o SAIU vem depois da morte, e que há 0 `SCRIPT ERROR / Parse Error /
   Compile Error`.
8. Normaliza **todos** os logs (import, export, mesa, cliente, cada um com o `.err`) para UTF-8 sem BOM. O que não for
   UTF-8 válido é lido como CP1252. Troca o caminho da máquina por `<sede>` e `<casa>` e grava os logs **inteiros**
   (sem filtro) na pasta de saída. A última linha do `procedimento.log` é `PROVA WINDOWS OK; exit 0` ou
   `PROVA WINDOWS FALHOU (n falhas); exit 1`, e o guião sai com esse código.

O guião não muda o cliente nem o servidor: só os arranca. Usa só as fichas fictícias de bancada.

**Pré-requisito que faltava neste PC:** os modelos de export do Godot 4.7.2. A pasta
`%APPDATA%/Godot/export_templates/` estava vazia, e a 1.ª corrida do guião falhou no export, como devia: exit 1, com
o erro do Godot «Nenhum modelo de exportação encontrado…» (registado na saída da corrida, não cometido). Baixei o
`.tpz` oficial (`github.com/godotengine/godot/releases/download/4.7.2-stable/`, a fonte do CI). O SHA-512
`ca4d71c4…ccb84079` confere com o `SHA512-SUMS.txt` da release. Extraí só os 4 modelos do Windows e o `version.txt`.
A 2.ª corrida, a que fica, passou.

## 2. A prova (itens 2 e 3) — `provas/ordem-plano-2-f2/windows/corrida-30s/`

Corrida de 26/11/2026, sobre `acffac1`, com o Godot 4.7.2.stable.official.ed1daf0bf, o Node v26.13.1 e o Windows
10.0.26300. O exit do guião na consola foi **0**.

| Medida | Valor (do `procedimento.log` e do `mesa.log`) |
|---|---|
| Export Windows | exit 0. `Assimilacao.exe` com 197 737 240 B, SHA-256 `a9e40c2b…ec1f9c11`. `Assimilacao.console.exe` com 188 928 B, SHA-256 `52bdcae9…8c8600df` |
| Linha de comando recebida | `"<sede>\repo\build\windows\Assimilacao.console.exe" --headless -- --servidor=127.0.0.1:8090 "--entrar-nome=Espadachim de Bancada" --entrar-senha=prova-espadachim`. O filho `Assimilacao.exe` (pid 11008) recebeu o mesmo, com o nome inteiro entre aspas |
| `ROOM_SNAPSHOT` | `rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows`, 6,9 s depois de o cliente arrancar (em 24/11 foram 2,1 s; nesta corrida o `.exe` acabara de ser exportado) |
| **ENTROU** (mesa, UTC) | **10:44:14.171** `ENTROU Espadachim de Bancada (senha/PIN; ip 127.0.0.1)` |
| Na mesa | Conferido a +5, +10, +15, +20, +25 e +30 s: invólucro vivo, processo do jogo vivo (1 de 1), a mesa sem SAIU |
| **MORTE** | **10:44:44.356 UTC** (07:44:44.356 -03), 30,104 s depois do snapshot. O harness fez `Stop-Process -Id 11008 -Force` (o jogo) e `Stop-Process -Id 29844 -Force` (o invólucro). O invólucro saiu com o exit −1 (0xFFFFFFFF, o código do `TerminateProcess`) |
| **SAIU** (mesa, UTC) | **10:44:44.372** `SAIU Espadachim de Bancada`, 16 ms depois da morte |
| Sessão | ENTROU→SAIU = **30,201 s**. Em 24/11 tinham sido 160 ms |
| Erros de script | 0 |
| Mesa | Parada pelo harness, com o exit −1 |

Os ficheiros são o `procedimento.log`, o `mesa.log`/`.err`, o `windows.log`/`.err`, o `import.log`/`.err` e o
`export-Windows.log`/`.err`, todos em UTF-8 e inteiros. O `export-Windows.log` tem 47 KB, com as linhas de ficheiro a
ficheiro e as cores ANSI do Godot. O de 24/11 tinha 950 B. Os `.err` vazios ficam lá, para se ver que nada saiu pelo
stderr. 0 ocorrências do utilizador da máquina nos logs (conferido com `grep -i`).

**Quem matou o cliente:** o harness, por comando, depois dos 30 s. Já não é preciso ler o workflow para o saber: está
na linha `MORTE` do `procedimento.log`, e o `SAIU` vem 16 ms depois dela. Antes da morte, a mesa não registou nenhum
`SAIU` nas 6 conferências.

**Os SHA (F21/F22):** os `.exe` ficam em `build/` (no `.gitignore`, 197 MB), e por isso não se cometem nem se podem
re-hashar a partir do repo. O que o guião dá é o SHA registado na hora, junto com o comando exacto que os refaz. Um
export novo do mesmo commit não dá forçosamente o mesmo SHA do `Assimilacao.exe` (o `.pck` embutido), por isso a
prova reprodutível é o comportamento, não o hash. Isto fica escrito no `windows/README.md`.

**A corrida de 24/11** (`windows/mesa.log`, `prova-windows.log`, `windows-godot.log`) ficou no sítio, sem mudanças,
para a conferência. O `windows/README.md` explica-a: a sessão de 160 ms e a dupla codificação `ligaÃ§Ãµes` do
`prova-windows.log` (UTF-8 lido como CP1252 e regravado pelo Windows PowerShell). A corrida de 26/11 substitui-a
como prova. No README das provas actualizei a linha do Windows e marquei a nota de 24/11 sobre o CP1252 como
corrigida no método.

### A regra para as provas desta ordem (item 3)

Os logs vão inteiros, sem filtro que corte o fim, com a linha de êxito e o exit code. Antes de cometer, normalizam-se
para UTF-8. No guião do Windows isto é o passo 8, e não depende de quem o corre. Nas suites, o `suites.sh` grava a
saída inteira de cada suite, com a linha do comando, e o exit vai para o `resumo.txt`. Todos os ficheiros cometidos
por esta ordem passaram pelo `file`: UTF-8 ou ASCII, nenhum noutra codificação.

**O aviso do canário (F11 / E-12).** O `canario_privacidade.log` e o `abrir_mestre.log` trazem
`Unicode parsing error … Unexpected NUL character`. A origem já está determinada: a fixture
`rascunhos/servidor/dados-exemplo/mesa-mestre.json` (byte 6664) traz `"chave": "<seatId>\u0000fc-1"`, porque a chave
de idempotência do servidor junta o lugar e o id com um NUL. As duas suites lêem essa fixture. Confirmei-o numa cópia
descartável do canário (no worktree LF, reposta com `git checkout`): pus um `printerr` antes e outro depois do
`JSON.parse_string(FileAccess.get_file_as_string(p))`, e o aviso sai entre os dois. Um script vazio no mesmo projecto
não o dá. É benigno, e nem o teste nem a fixture mudam (o jogo não se toca).

## 3. Suites (item 4) — `provas/ordem-plano-2-f2/windows/suites/`

Corri-as pelo `provas/ordem-plano-2-f2/windows/suites.sh`: as suites da D-AUD-01-CORRECCOES-4 sem a mutação do B1,
que é dessa ordem, mais o `aparelhos_f2.gd`. Foi neste PC, com o Godot 4.7.2 `--headless` e sobre `acffac1`.

| Suite | Resultado |
|---|---|
| servidor (`testes/*.test.mjs`) | clone (CRLF): 445/446, exit 1. **Worktree LF: 446/446, exit 0** |
| motor real | clone (CRLF): 5/6, exit 1. **Worktree LF: 6/6, exit 0** |
| prova da caixa | PROVA OK, exit 0 |
| `aparelhos_f2` | 46 de 46 |
| `abrir_scripts` | 113 scripts, 0 falhas |
| `rodar_testes` | 333 de 333 |
| `abrir_mestre` | 67 de 67 |
| `pecas_mestre` | 334 de 334 |
| `medir_mestre` | 0 falhas, 0 sem medida |
| `hud_acoes` | 70 de 70 |
| `caixa_jogadora` | 70 de 70 |
| `caixa_janela` | 123 de 123 |
| canário de privacidade | 10 de 10 |
| `validar-mensagens.py` | `pecas_mestre` 29 mensagens e `abrir_mestre` 9, 0 falhas |

Todas as suites Godot deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.

**O CRLF (o mesmo caso da D-AUD-01-CORRECCOES-4).** No clone, cada uma das duas suites Node tem uma só falha, e é de
comparação byte a byte contra um ficheiro guardado lido em CRLF. No `servidor` é o `mesa-mestre.json` (o diff no
`servidor.log` mostra `\r\n`); no `motor-real` é o `01-ataque-normal.json`. Desta vez a configuração ficou registada
com output: `git config --get core.autocrlf` → `true`, em `suites/lf/worktree-lf.log`. O worktree LF
(`git -c core.autocrlf=false worktree add --detach`, no mesmo `acffac1`) deu 446/446 e 6/6. O CI corre em LF.

Para as suites usei o motor real da pasta privada da bancada da D-AUD-06 (`MOTOR_MJS`, fora do repo; não foi copiado)
e o `python` com `jsonschema` do venv da D-AUD-01-CORRECCOES-4 (fora do repo).

## 4. Commits

- `7f45aee`: o guião `rascunhos/servidor/aparelhos/prova-windows.ps1`, a corrida `windows/corrida-30s/`, o
  `windows/README.md`, o `suites.sh` com os logs, e a linha do Windows no README das provas.
- `c27f164`: as listas da retoma sincronizadas (`python retoma-i0004/actualizar-listas.py`): **1 novo, 0 tirados**
  (`depois.txt` com 453 ficheiros, MANIFESTO com 496). O `antes.txt` não muda, porque o ficheiro é novo.
- O commit deste ESTADO-FINAL e, depois, a Nota do CI. Nenhum dos dois mexe em `rascunhos/`, e por isso não precisam
  de nova passagem das listas.

Autor dos commits: `Claude Pierre C2 <claude-pierre@local>`, a mesma identidade dos commits anteriores deste PC
(posta no `.git/config` do clone, que vinha sem identidade).

## 5. Perímetro

- **Escrevi:** o guião, as provas, o README da pasta, a linha do README das provas e este ESTADO-FINAL. As listas da
  retoma mudaram pelo guião da casa.
- **Ficou como estava:** o cliente, o servidor, os testes, as fixtures, os dados, o workflow e a `main`. A experiência
  do aviso NUL correu numa cópia descartável, e o worktree ficou limpo.
- **Nomes e caminhos:** só os nomes fictícios de bancada. O caminho da máquina sai como `<sede>`/`<casa>`.
- **Fora desta ordem:** o job `windows` do workflow «Aparelhos (F2)» continua a matar o `.exe` logo a seguir ao
  snapshot. O guião local é que fixa o método. Levar os 30 s para o CI muda o workflow e fica como sugestão.
  Também não decidi nada da secção C da sentença 595.

## Nota do CI

- `34d6f0c` (os três commits desta ordem): **Testes dos rascunhos 45804679330: success**, com os 10 jobs verdes
  (motor-real, protocolo, godot-cliente, cliente, ponta-a-ponta, foto-mestre, provas-mapa, servidor, validador-glb e
  retoma-pc). O `retoma-pc` verde confirma as listas do `c27f164`. **Sonda de privacidade 45804679558: success.**
- «Aparelhos (F2)» 45804679276: `failure`, só por causa do job `android`. É a falha anterior a esta ordem (o F1 da
  sentença 595; a ponta `e2d784a` também tinha falhado, no run 45802964273). `exportar`, `windows`, `web-chromium`,
  `rede-3-bots` e `qr` deram success. Esta ordem não mexe no workflow nem no Android.
