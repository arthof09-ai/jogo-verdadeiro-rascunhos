# Prova do Windows (JV2.1b) — ORDEM-PLANO-2-F2 e ORDEM-PLANO-2-F2-PROVA-WINDOWS

## O procedimento (cometido)

`rascunhos/servidor/aparelhos/prova-windows.ps1` corre a prova inteira, sem passos manuais:

```
powershell -NoProfile -ExecutionPolicy Bypass -File rascunhos/servidor/aparelhos/prova-windows.ps1 -Godot <Godot_v4.7.2-stable_win64_console.exe>
```

Importa o projecto, exporta o preset «Windows», arranca a mesa de prova (Mestre-bot, combate aberto), arranca o
`Assimilacao.console.exe` exportado **com o nome entre aspas**, espera o `ROOM_SNAPSHOT`, deixa o cliente **30 s na
mesa**, mata-o (o harness, por `Stop-Process -Force`, com o instante registado), espera o `SAIU`, pára a mesa,
confere e escreve os logs **inteiros e em UTF-8** em `corrida-30s/`. O exit code do guião é 0 se passa e 1 se falha;
a última linha do `procedimento.log` diz qual. Pré-requisito: os modelos de export do Godot 4.7.2 para Windows em
`%APPDATA%/Godot/export_templates/4.7.2.stable/` (o `.tpz` oficial; o guião falha com o erro do Godot se faltarem —
foi o que aconteceu na 1.ª tentativa desta ordem, ver o ESTADO-FINAL).

## `corrida-30s/` — 26/11/2026, sobre `acffac1`

| Ficheiro | O quê |
|---|---|
| `procedimento.log` | Cada passo com a hora (UTC, o relógio da mesa, e local -03): os comandos exactos, a versão do Godot e do Node, o SHA-256 dos dois `.exe`, a linha de comando que o Windows **de facto** entregou ao invólucro e ao processo do jogo (lida do `Win32_Process`), o snapshot, as 6 conferências de 5 em 5 s, a MORTE (pids, instante, exit code), ENTROU→SAIU e o resultado |
| `mesa.log` / `mesa.err` | A saída inteira da mesa (Node, UTF-8): `ENTROU Espadachim de Bancada` **10:44:14.171**, `SAIU` **10:44:44.372** |
| `windows.log` / `windows.err` | A saída inteira do `.exe` (sem filtro) |
| `import.log`, `export-Windows.log` (+ `.err`) | A saída inteira do import e do export (47 KB; o export de 24/11 tinha ficado em 950 B, sem as linhas de ficheiro a ficheiro). Trazem as sequências de cor ANSI do Godot, como saíram |

Números: snapshot 6,9 s depois de arrancar o cliente; o cliente ficou **30,110 s** depois do snapshot (relógio da mesa); a mesa mediu
**ENTROU→SAIU = 30,201 s**; o `SAIU` veio **16 ms depois** da morte (10:44:44.356 UTC); antes dela, 6 conferências
sem `SAIU` e com o processo vivo; 0 erros de script; exit do guião 0.

Os `.exe` ficam em `build/` (no `.gitignore`, 197 MB): não se cometem. O SHA-256 de cada um está no
`procedimento.log`; refaz-se com o mesmo export sobre o mesmo commit. Um export novo não dá forçosamente o mesmo SHA
do `Assimilacao.exe` (o `.pck` embutido), por isso o que se compara é o comportamento, não o hash.

## A corrida de 24/11 (`mesa.log`, `prova-windows.log`, `windows-godot.log`, nesta pasta)

É a corrida da ORDEM-PLANO-2-F2 que a sentença 595 arbitrou (F10, F11, F21/F22). Fica como estava, para a
conferência: o cliente foi morto pelo harness logo a seguir ao snapshot (`ENTROU 04:37:58.384` → `SAIU
04:37:58.544`, 160 ms); o `prova-windows.log` é um resumo filtrado escrito pelo Windows PowerShell, e as linhas da
mesa lá dentro estão em dupla codificação (`ligaÃ§Ãµes`: UTF-8 lido como CP1252 e regravado). A corrida de 26/11
substitui-a como prova.

## Suites (`suites/`)

`suites.sh` (nesta pasta) corre as suites da linha e grava os logs inteiros com a linha do comando e o exit no
`suites/resumo.txt`. No clone do PC (`core.autocrlf=true`, ver `suites/lf/worktree-lf.log`) o `servidor` (445/446) e o
`motor-real` (5/6) dão exit 1, cada um com uma só falha de comparação byte a byte contra um ficheiro guardado lido em
CRLF — o mesmo caso da D-AUD-01-CORRECCOES-4. Num worktree LF do mesmo commit (`suites/lf/`) dão **446/446 e 6/6,
exit 0**. O CI corre em LF.

**O aviso do canário** (`Unicode parsing error … Unexpected NUL character`, também no `abrir_mestre.log`): a origem
é a fixture `rascunhos/servidor/dados-exemplo/mesa-mestre.json`, que traz `"chave": "<seatId>\u0000fc-1"` — a chave de
idempotência do servidor junta o `seatId` e o id com um NUL. O Godot avisa ao converter esse carácter. Confirmado com
um `printerr` antes e depois do `FileAccess.get_file_as_string` + `JSON.parse_string` numa cópia descartável (o
aviso sai entre os dois). Benigno; o teste não muda.
