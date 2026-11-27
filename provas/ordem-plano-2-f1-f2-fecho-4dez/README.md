# ORDEM-PLANO-2-F1-F2-FECHO-4DEZ — provas da F2 (CM-000009)

PC: PCDANASA · 27/11/2026 · ponta medida ao arrancar: `c64719d0d7711fb43f67cbbd21b0c1d76736d9d2`.

## B1 — o run «Aparelhos (F2)» na ponta, lido por dentro

Run **`45946124164`** (push, `c64719d`, criado 2026-11-27T05:29:40Z, `completed | success`). Os artefactos e o log
inteiro do run foram descarregados e lidos; o `success` dos jobs não conta como prova do conteúdo.

| Job | id | O que o log/artefacto diz (citado) |
|---|---|---|
| `android` | 140331615069 | `prova-android/android-godot.log` l. 564: `11-27 05:33:18.720  3856  3925 I godot   : rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Android`; `mesa.log`: `05:33:19.309 ENTROU Arqueira de Bancada` → `05:33:40.936 SAIU`. Nota: no emulador (SwiftShader) o log traz falhas de ligação de shaders GLES3 (`Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`; «SceneShaderGLES3 link falhado: 10» e «85» nas duas contagens do controlo-gles) — não tocam no snapshot; ficam registadas como estão |
| `web-chromium` | 140331615093 | `ok o export web disse «pronto» em 5.2 s (≤ 30 s)` (`prova-web.json`: `prontoS 5.24`); `ok a web recebeu o ROOM_SNAPSHOT do combate («rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Web»)`; V1.0 medida **2 vezes**, as duas gravadas pelo servidor (`medicao-…-001.json`, `…-002.json`, envio 204); `ok repetir dá o mesmo ±10 %`: `fps_mediana 1 → 1.1`, `fps_p5 1 → 1`, `chamadas_mediana 87 → 87`. Nota: FPS 1 é o SwiftShader do runner sem GPU, não o desempenho de um aparelho; o `fps_mediana` 1 → 1.1 está **no limite** dos 10 % |
| `rede-3-bots` | 140331130331 | `relatorio-3-bots.json`: corte 25 s; `hashLogico` controlo = queda = `ea32c6278dcfc60a491fd88786194e72dd6badd13aead5d94fde812cdf13fd5d`; A 6…37, B 7…37, C 8…37, `buracos []`, `repetidos []`, último seq = servidor (37); A e B voltam com `lastSeq 11` e recebem a partir do 12 sem snapshot; reconexão A **3.43 s**, B **4.04 s**; `falhas []` |
| `windows` | 140331615141 | `prova-windows/windows.log`: `pronto` / `rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows`; `mesa.log`: `05:31:48.111 ENTROU Espadachim de Bancada` |
| `qr` | 140331130062 | **15/15** `ok … lido` (qr-00 … qr-14, versões v1–v10); e a página `/qr` fotografada no Chromium: `ok: o QR da página dá http://192.168.1.20:8080/` |
| `exportar` | 140331130334 | testes `aparelhos_f2.gd` com `ok`; exports Web/Windows/Android; artefactos `export-web`, `export-windows`, `export-android`, `export-registos` |

## B2 — Windows, 30 s na mesa (F10/B-3 da sentença 595) — `windows-30s/`

O procedimento **já está cometido** na linha: `rascunhos/servidor/aparelhos/prova-windows.ps1` (desde `7f45aee`,
endurecido em `c2c0280` e `52ce824`), com a citação do `Start-Process` corrigida (o nome entre aspas), o comando
exacto e o instante da morte no `procedimento.log`. Não o dupliquei: corri-o tal como está.

Comando (no PC, a partir de `repo/`):

```
powershell -NoProfile -ExecutionPolicy Bypass -File rascunhos/servidor/aparelhos/prova-windows.ps1 -Godot Godot_v4.7.2-stable_win64_console.exe -SemExport -Saida provas/ordem-plano-2-f1-f2-fecho-4dez/windows-30s -Porta 8090 -SegundosNaMesa 30
```

O `.exe` é o do artefacto **`export-windows` do run `45946124164`** (o build do CI na ponta), descarregado para
`build/windows/` (fora do repositório): `Assimilacao.exe` 197.730.824 B, SHA-256 `3a5c4a2b936f98fca0e20bb1633dbe6e94e6caf6cb1d74e295feb032200e7f18`;
`Assimilacao.console.exe` 188.928 B, SHA-256 `52bdcae9068e8d23b840e5c63b0c1798ffe2cb66144e5c4bc7af11fb8c8600df`.

Números (relógio da mesa, UTC; local = UTC−3):

- linha de comando que o Windows entregou ao jogo (`Win32_Process`): `… --servidor=127.0.0.1:8090 "--entrar-nome=Espadachim de Bancada" --entrar-senha=prova-espadachim`
- `ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows` 2,6 s depois de arrancar o cliente;
- 6 conferências de 5 em 5 s: invólucro vivo, jogo vivo 1 de 1, mesa sem `SAIU`;
- **MORTE** pelo harness (`Stop-Process -Force`, pids 1628 e 24668) às **16:07:16.347 UTC** (13:07:16 −03), **30,037 s** depois do snapshot; exit do invólucro −1 (0xFFFFFFFF, morto à força);
- mesa: `ENTROU 16:06:46.203` → `SAIU 16:07:16.360` = **30,157 s**; o `SAIU` veio 13 ms depois da morte;
- 0 erros de script; **exit do guião 0** (`PROVA WINDOWS OK; exit 0`).

Logs inteiros em UTF-8: `procedimento.log`, `mesa.log`/`.err`, `windows.log`/`.err` (sem import/export: `-SemExport`).
