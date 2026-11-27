# ESTADO-FINAL — ORDEM-PLANO-2-F1-F2-FECHO-4DEZ (CM-000009)

Executor: conta 1 (opus, effort medium) · PC: PCDANASA · 27/11/2026, 12:58–14:00 −03 · linha `fable/integracao-50`,
directamente na linha, sem ramo, sem fusão, sem force-push. Sede: `ordem-plano-2-f1-f2-fecho-4dez-pc\` (clone novo em
`repo\`). O clone velho do fecho-vídeo (ponta `b54ba87`) não foi tocado. Cópias: `G:\Meu Drive\RPG Assimilação\13 —
Trabalho das cadeiras\f1-f2-fecho-4dez\`.

## Resumo — o estado de cada item

| Item | Estado | Depende de |
|---|---|---|
| **F1** | **fechada salvo F3b (passo de pessoa)**. O registo de fecho da F1 **NÃO se escreveu** | o Mestre: `PESSOA-F3B.md` |
| F3b (run verde do `camera_segue`) | **POR FECHAR**: push recusado por falta do âmbito `workflow` | o Mestre (âmbito `workflow` na credencial) |
| **F2 (a)** run do CI na ponta, verificado | **verificado, com uma ressalva**: 6/6 jobs `success` e o conteúdo bate, **salvo** a repetibilidade ±10 % da V1.0 na web, que **FALHA** no `fps_p5` em 3 dos 4 runs da linha; o job sai verde porque o passo não propaga o exit (ver §B1.3) | o coordenador (decidir a correcção do passo e o critério ±10 % com SwiftShader) |
| **F2 (b)** Windows 30 s na mesa | **feito e cometido** (`5c4e689`): ENTROU→SAIU **30,157 s**, exit 0 | — |
| **F2 (c)** ensaio da casa (JV3.4b) | **ensaio preparado, por correr**: build publicado e verificado por curl, guia e registo prontos (`8541f20`) | o Mestre, com o celular, em 4/12 |
| Suites no PC | **verdes** (`17015a3`) | — |
| Listas da retoma | sincronizadas: **0 novos, 0 tirados** | — |

## Ponta

- Ao arrancar (`git ls-remote`, 12:58): `c64719d0d7711fb43f67cbbd21b0c1d76736d9d2` — não tinha andado desde a medição
  do coordenador.
- Commits desta ordem, por ordem, todos empurrados a cada passo:
  1. `5c4e689` — B1+B2 (o run `45946124164` lido por dentro; Windows 30 s na mesa);
  2. `8541f20` — B3 (o ensaio preparado: lançador, conferidor, guia, registo);
  3. `17015a3` — C (suites no PC; listas 0/0);
  4. o commit deste ESTADO-FINAL (e a nota do CI a seguir).

## A. F1 — a F3b

1. `testes.yml` sem mudanças desde `27b70e5`: `git log 27b70e5..HEAD -- .github/workflows/testes.yml` vazio, `git diff`
   0 linhas.
2. Patch copiado da sede velha para esta sede: `f3-workflow-pendente.patch`, **3.029 B**, SHA-256
   `b1af140842b0f4938cbe77172a5161bc8b583e61034027de34887070d57c7c2e`. O corpo (do `diff --git` em diante) é igual ao
   `provas/ordem-plano-2-f1/ci/passo-camera-segue.patch`; só lhe falta a assinatura do format-patch.
   `git am` **aplicou limpo** sobre `c64719d` → `b9a4855c241d02db8f02abf5d27c9fe4a20dd005` (+24/−0, só
   `.github/workflows/testes.yml`).
3. **Push recusado**, à letra:
   ```
   To https://github.com/arthof09-ai/jogo-verdadeiro-rascunhos.git
    ! [remote rejected] HEAD -> fable/integracao-50 (refusing to allow an OAuth App to create or update workflow `.github/workflows/testes.yml` without `workflow` scope)
   error: failed to push some refs to 'https://github.com/arthof09-ai/jogo-verdadeiro-rascunhos.git'
   ```
   `gh auth status -h github.com`: conta `arthof09-ai`, `Token scopes: 'gist', 'read:org', 'repo'` — **sem
   `workflow`**. Não tentei contornar o âmbito.
4. O commit `b9a4855` ficou no ramo **local** `f3b-pendente` do clone desta sede (não é ref no GitHub). A
   `fable/integracao-50` local voltou à ponta remota para os commits seguintes poderem subir. O passo de pessoa
   exacto está em **`PESSOA-F3B.md`** (sede + pasta partilhada): `gh auth refresh -h github.com -s workflow` →
   `gh auth status` com `workflow` → (se preciso) `gh auth setup-git` / o token do git → `git am` do patch na ponta
   nova (guardas: `testes.yml` sem mudanças desde `27b70e5`; `git am` limpo) → push → run verde do Testes com o passo
   `camera_segue` e o artefacto `camera-segue` com o log.
5. **O registo de fecho da F1 (follow-up 2 da sentença 855) NÃO se escreveu**: a ordem só o permite com o run verde.
   **F1 fechada salvo F3b (passo de pessoa).**

Nota: a guarda N de N do passo `camera_segue` foi corrida **no PC** pela `suites.sh` desta ordem (a mesma lógica do
passo do CI): `camera_segue 22 de 22 ok`. Isto não substitui o run verde no CI.

## B. F2

### B1. O run do CI, lido por dentro

**B1.1 — o run `45946124164`** (Aparelhos (F2), ponta `c64719d`, push, 2026-11-27T05:29:40Z, `completed | success`).
Artefactos `prova-android`, `prova-web`, `prova-3-bots`, `prova-qr`, `prova-windows`, `export-registos`, `export-web`
descarregados e lidos, e o log inteiro do run (2.657 linhas):

| Job | id | Prova lida |
|---|---|---|
| android | 140331615069 | `android-godot.log` l. 564: `11-27 05:33:18.720 … I godot   : rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Android`; mesa `05:33:19.309 ENTROU Arqueira de Bancada` → `05:33:40.936 SAIU`. O emulador (SwiftShader) dá falhas de ligação de shaders GLES3 (`GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`; «SceneShaderGLES3 link falhado: 10» e «85» no controlo-gles) — registadas, não tocam no snapshot |
| web-chromium | 140331615093 | `pronto` em **5,2 s** (≤ 30 s); `ROOM_SNAPSHOT seq=5 fase=combate plataforma=Web`; V1.0 **2 vezes**, as duas gravadas pelo servidor (envio 204); ±10 %: `fps_mediana 1 → 1.1` (no limite), `fps_p5 1 → 1`, `chamadas_mediana 87 → 87` — os 3 `ok`; 0 erros de script |
| rede-3-bots | 140331130331 | corte 25 s; hash lógico igual (`ea32c6278dcfc60a…`); A 6…37, B 7…37, C 8…37, 0 buracos, 0 repetidos, último seq = servidor (37); reconexão A 3,43 s, B 4,04 s; `falhas []` |
| windows | 140331615141 | `pronto` / `rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows`; mesa `05:31:48.111 ENTROU Espadachim de Bancada` |
| qr | 140331130062 | **15/15** `lido` (qr-00…qr-14, v1–v10) + a página `/qr` fotografada: `ok: o QR da página dá http://192.168.1.20:8080/` |
| exportar | 140331130334 | `aparelhos_f2.gd` ok; exports Web/Windows/Android e os 4 artefactos `export-*` |

**B1.2 — a ponta andou** (os meus commits). Runs da Aparelhos (F2) por ponta:

| Ponta | Run | Resultado |
|---|---|---|
| `5c4e689` | 46031007547 | `success`, 6/6 |
| `8541f20` | 46032812667 | **tentativa 1: `failure`** — job `qr` (140620615497), passo «A página /qr fotografada no Chromium…»: `Error: o navegador não abriu o DevTools` (o Chromium do runner não arrancou; o passo dos 15 QR do OpenCV passou). Commit só de `provas/`, código igual ao de `5c4e689`. **Tentativa 2** (re-run do falhado, `gh run rerun --failed`): `success`, 6/6 (qr 140623759998). Log da tentativa 1 na sede: `ci-46032812667-tentativa1-qr.log` |
| **`17015a3`** (a ponta verificada) | **46033830951** | `success`, 6/6 à 1.ª: rede-3-bots 140624094476, exportar 140624094807, qr 140624094932, windows 140624795159, web-chromium 140624795175, android 140624795245 |

Conteúdo do `46033830951` (artefactos descarregados): android `16:31:35.802 … rede: ROOM_SNAPSHOT seq=5 fase=combate
plataforma=Android`; windows `rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows`; web `pronto` **8,7 s**,
snapshot Web, V1.0 2×; 3 bots hash igual (`ea32c6278dcfc60a…`), 0 buracos/repetidos, reconexão A 1,02 s, B 6,3 s,
`falhas []`; qr 15/15 + a página.

**B1.3 — RESSALVA: a repetibilidade ±10 % da V1.0 na web FALHA e o job sai verde na mesma.**

| Run (ponta) | `fps_p5` 1.ª → 2.ª | linha do log |
|---|---|---|
| 45946124164 (`c64719d`) | 1 → 1 | `ok` |
| 46031007547 (`5c4e689`) | 0.7 → 0.9 | `FALHA repetir dá o mesmo ±10 %: fps_p5 0.7 → 0.9` |
| 46032812667 (`8541f20`) | 0.5 → 0.4 | `FALHA …: fps_p5 0.5 → 0.4` |
| 46033830951 (`17015a3`) | 0.4 → 0.3 | `FALHA …: fps_p5 0.4 → 0.3` (e `prova-web.json`: `"falhas": ["repetir dá o mesmo ±10 %: fps_p5 0.4 → 0.3"]`) |

Causa: em `.github/workflows/f2-aparelhos.yml`, o passo do `web-chromium` faz `node aparelhos/prova-web.mjs … 2>&1 |
grep -vE "…"` **sem `set -o pipefail`**. O `prova-web.mjs` sai com 1 (`process.exit(falhas.length ? 1 : 0)`), mas o
exit do passo é o do `grep`. **O `success` do job web-chromium não prova a repetibilidade.** A causa de fundo é o
SwiftShader do runner: FPS abaixo de 1, em passos de 0,1, onde ±10 % é uma décima ou menos. Os outros 5 jobs do
`46033830951` não têm nenhuma linha `FALHA`. **Não corrigi nada** (sem ordem; e mexer no workflow precisa também do
âmbito `workflow`). Fica para o coordenador: `set -o pipefail` no passo, e decidir o critério ±10 % com SwiftShader
(ou medir só no aparelho real — é o que o ensaio da casa faz).

### B2. Windows, 30 s na mesa (F10/B-3 da sentença 595) — `5c4e689`

O procedimento **já estava cometido** na linha (a ordem dizia que nunca tinha sido): `rascunhos/servidor/aparelhos/
prova-windows.ps1` desde `7f45aee`, endurecido em `c2c0280`/`52ce824`, com a citação do `Start-Process` corrigida, o
comando exacto e o instante da morte no `procedimento.log`. Não o dupliquei: corri-o tal como está, com o `.exe` do
artefacto `export-windows` do run `45946124164` (`-SemExport`).

- Comando: `powershell -NoProfile -ExecutionPolicy Bypass -File rascunhos/servidor/aparelhos/prova-windows.ps1 -Godot
  Godot_v4.7.2-stable_win64_console.exe -SemExport -Saida provas/ordem-plano-2-f1-f2-fecho-4dez/windows-30s -Porta 8090
  -SegundosNaMesa 30`
- `.exe`: `Assimilacao.exe` 197.730.824 B SHA-256 `3a5c4a2b936f98fca0e20bb1633dbe6e94e6caf6cb1d74e295feb032200e7f18`;
  `Assimilacao.console.exe` 188.928 B `52bdcae9068e8d23b840e5c63b0c1798ffe2cb66144e5c4bc7af11fb8c8600df`.
- Linha de comando recebida pelo jogo (`Win32_Process`): `… --servidor=127.0.0.1:8090 "--entrar-nome=Espadachim de
  Bancada" --entrar-senha=prova-espadachim`.
- `ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows` 2,6 s depois de arrancar; 6 conferências de 5 em 5 s (vivo 1 de 1,
  sem `SAIU`).
- **Morte** pelo harness (`Stop-Process -Force`, pids 1628 e 24668) às **16:07:16.347 UTC (13:07:16 −03)**, **30,037 s**
  depois do snapshot; exit do invólucro −1 (0xFFFFFFFF).
- Mesa: `ENTROU 16:06:46.203` → `SAIU 16:07:16.360` = **30,157 s** (o snapshot provado antes durou 160 ms).
- 0 erros de script; **exit do guião 0**. Logs inteiros em `provas/ordem-plano-2-f1-f2-fecho-4dez/windows-30s/`.

### B3. O ensaio — **ensaio preparado, por correr** (`8541f20`)

- **Build:** o artefacto `export-web` do run verde `45946124164` (via principal, errata E-2), copiado para a pasta
  partilhada `build-web\` com o `SHA256SUMS.txt` (`index.pck` `fa4ee2b3…967499b`, `index.wasm` `fc74679e…bfa57d0`,
  `index.html` `e0a57e96…ff2947a8`).
- **Servido** pelo servidor de produção (`servidor-ws.js` + journal + VLAB real SHA-256 `a91c021c…`, fichas «acertam»,
  monstros em auto, host 0.0.0.0), na mesma origem do WebSocket, com a página do QR, pelo lançador novo
  `provas/ordem-plano-2-f1-f2-fecho-4dez/ensaio-4dez/arrancar-ensaio.cmd`. Nota: a rota do WebSocket é **`/ws`** (a
  ordem escreve `ws://…/mesa`).
- **Verificado por curl** a partir do IP da rede (`http://192.168.1.38:8080`), com cache-busting (`?cb=<ns>`), em duas
  arrancadas: `index.html`, `index.js`, `index.wasm` (39.514.754 B, `application/wasm`), `index.pck` (88.462.328 B) com
  SHA-256 do servido **igual** ao do artefacto (e na 1.ª também `index.audio.worklet.js`, `index.audio.position.worklet.js`,
  `index.png`); `/` = `index.html`; `/qr` 200 com os links `/` e `/?medir=1`; `/?medir=1` 200; `Cache-Control: no-cache`.
  Uma sonda pela rede (`ws://192.168.1.38:8080/ws`, `ROOM_JOIN` de jogadora por nome+senha, o caminho do lobby web)
  recebeu `ROOM_WELCOME` e `ROOM_SNAPSHOT seq=5 fase=pausa` (a mesa espera o Mestre). A mesa de verificação foi fechada.
- **Guia:** `GUIA-ENSAIO-4DEZ.md` (sede, pasta partilhada e `ensaio-4dez/` no repo) — 8 passos, ~15 min: mesa no PC,
  Mestre no navegador do PC com o PIN, QR/link no celular sem instalar nada, 10 turnos, Wi-Fi desligado 25 s com
  reconexão ≤ 30 s e nada perdido, até à morte (sem «Terminar batalha»), V1.0 com 1 minuto, 4 fotos, Enter guarda o
  resultado.
- **Registo:** `REGISTO-ENSAIO-4DEZ.md`, por preencher (critérios 1–12). O conferidor
  `ensaio-4dez/conferir-ensaio.mjs` confere por máquina turnos ≥ 10, `fim {"desfecho":"morte"}` único, 0 colocações
  duplicadas, seq contínuo, SAIU→ENTROU, campos da V1.0; ensaiado sobre o journal da F1 (`f1-1929`): 16 turnos, `fim`
  seq 78 morte, 3 colocações sem repetidos, exit 0.
- **O ensaio NÃO correu e NÃO foi declarado feito.** É do Mestre, com o celular dele, em 4/12.

## C. Suites e listas (`17015a3`, sobre `8541f20`)

`suites.sh` desta ordem (clone LF, `core.autocrlf=false`), logs inteiros em `provas/ordem-plano-2-f1-f2-fecho-4dez/suites/`:

| Suite | Resultado |
|---|---|
| servidor (`node --test`) | **459/459**, exit 0 |
| abrir_scripts | 113 scripts, 0 falhas |
| rodar_testes | 333/333 |
| abrir_mestre | 67/67 |
| pecas_mestre | 337/337 |
| medir_mestre | 0 falhas, 0 sem medida |
| hud_acoes | 70/70 |
| caixa_jogadora | 70/70 |
| caixa_janela | 123/123 |
| **canário** (canario_privacidade) | **10/10** |
| **camera_segue** | **22/22**, guarda N de N ok |
| aparelhos_f2 | 46/46 |
| validar-mensagens (pecas_mestre, abrir_mestre) | exit 0, exit 0 |

Todas com exit 0 e 0 erros de script. O motor real não correu no PC (corre no CI, job `motor-real` do Testes).

**Listas da retoma:** `python retoma-i0004/actualizar-listas.py` → «antes.txt: 38 · depois.txt: 462 · MANIFESTO: 505
ficheiros (**0 novos, 0 tirados** nesta passagem)»; `git diff retoma-i0004` com 0 linhas mudadas (esta ordem não muda
`rascunhos/`).

## Nota do CI

| Ponta | Testes dos rascunhos | Aparelhos (F2) | Sonda de privacidade |
|---|---|---|---|
| `5c4e689` | 46031007699 success | 46031007547 success (web: FALHA ±10 % escondida) | 46031007641 success |
| `8541f20` | 46032812632 success | 46032812667 tentativa 1 failure (qr, Chromium sem DevTools) → tentativa 2 success (web: FALHA ±10 % escondida) | 46032812726 success |
| `17015a3` | 46033830661 success, 10/10 jobs | 46033830951 success, 6/6 (web: FALHA ±10 % escondida) | 46033830721 success |

O run do Testes **não tem** o passo `camera_segue` nem o artefacto `camera-segue` (F3b por fechar). Os runs do commit
deste ESTADO-FINAL vão na nota a seguir.

## O que fica pendente, e de quem

1. **F3b** — o Mestre: `PESSOA-F3B.md`. Depois do run verde, alguém escreve o registo de fecho da F1 (follow-up 2 da
   sentença 855, com o §6 «Ensaio por pessoa (sessão 4/12)»).
2. **Ensaio da casa (JV3.4b)** — o Mestre, em 4/12: `GUIA-ENSAIO-4DEZ.md`; o resultado lavra-se no
   `REGISTO-ENSAIO-4DEZ.md`.
3. **web-chromium ±10 %** — o coordenador: o passo sem `pipefail` esconde a falha do `fps_p5` (B1.3).

## Ficheiros na sede

`PESSOA-F3B.md`, `f3-workflow-pendente.patch`, `f3b-b9a4855.patch` (o commit aplicado, em format-patch),
`GUIA-ENSAIO-4DEZ.md`, `REGISTO-ENSAIO-4DEZ.md`, `ci-45946124164\` e `ci-46033830951\` (artefactos e logs lidos),
`ci-46032812667-tentativa1-qr.log`, `prova-windows-consola.txt`, `curl-ensaio\` (o servido descarregado),
`ensaio-4dez-privado\` (a mesa de verificação; fora do Git), `actualizar-listas.log`, `ferr\sonda-celular.mjs`.
