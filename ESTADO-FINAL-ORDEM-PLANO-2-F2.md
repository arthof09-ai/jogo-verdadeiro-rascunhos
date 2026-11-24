# ESTADO-FINAL — ORDEM-PLANO-2-F2 (cada um no seu aparelho: JV2.1b, JV3.4, V1.0, JV3.4b)

**Estado: FEITA, COM 2 BLOQUEADORES E 5 SUB-ITENS POR CUMPRIR.** Os 2 bloqueadores: (1) activar o workflow
«Aparelhos (F2)» (falta o âmbito `workflow` na credencial do PC); (2) a JV3.4b (precisa do telemóvel do
Mestre). Os 5 sub-itens por cumprir: o `ROOM_SNAPSHOT` no Android, o pronto no Chromium do CI, o
`aparelhos_f2.gd` no CI, a V1.0 no telemóvel do Mestre e as fotos dos aparelhos reais.

O Mestre arranca a mesa no PC, e o terminal e a página `/qr` mostram o QR. A jogadora lê o QR (ou abre o link no PC)
e entra no lobby pelo navegador, sem instalar nada. O jogo web vem do mesmo servidor e da mesma origem do
`ws://…/ws`. Quem cai da rede volta com o token e o `lastSeq` e não perde nada.

- Os três exports constroem no PC. A web e o Windows recebem o `ROOM_SNAPSHOT`.
- A prova dos 3 bots com 25 s sem rede passa (hash igual, seq contínuo).
- A V1.0 mede sozinha e repete dentro de ±10 %.
- As suites estão verdes e o canário dá 10/10.

**Pendente 1: o workflow do CI** (`ci-pendente/f2-aparelhos.yml`). O GitHub recusou o push, porque a credencial deste
PC não tem o âmbito `workflow`. Falta um comando do dono da conta (§5.1).

**Pendente 2: a JV3.4b** com o telemóvel do Mestre. Ele não estava na hora. Não é falha. Os passos exactos estão em
`provas/ordem-plano-2-f2/rede-da-casa/PASSOS-PENDENTES.md`.

- **Executor:** Claude (opus), PC (conta 2). **Data:** 24/11/2026, das ~01:32 às ~02:00 (-03). Retomei o trabalho
  que uma corrida anterior desta mesma ordem deixou por commitar no clone (23/11, ~22:00-22:33). Revi-o, corrigi-o e
  voltei a provar tudo sobre a ponta nova.
- **Linha:** `fable/integracao-50`, trabalho directo, sem ramo. A `main` não foi tocada.
- **Ponta de partida:** `4052913` (CORRECCOES-2, errata A1-A3), medida por `git fetch` + `git ls-remote`
  (`4052913ea68d746ef98ddaf55fc37e5a72d7187a`). Medi-a outra vez antes de cada push. O trabalho anterior estava
  sobre `68ffd3e`, 7 commits atrás (a F1 correu entretanto). Repus-o por `stash` + fast-forward, sem conflitos.

## 1. O que se entrega (por item da ordem)

### JV2.1b — os três exports

| Peça | O quê |
|---|---|
| `rascunhos/cliente/export_presets.cfg` | **Web**: Thread Support desligado (`variant/thread_support=false`; o `index.html` sai com `GODOT_THREADS_ENABLED = false`, sem COOP/COEP). **Android**: `permissions/internet` (e o estado da rede e do Wi-Fi), `arm64-v8a` + `x86_64`, APK de depuração. **Windows**: x86_64, com o `.pck` embutido. As saídas vão para `build/` (no `.gitignore`) |
| Tráfego em claro só na rede local | O Godot usa sockets nativos, e o `NetworkSecurityPolicy` do Android não os filtra. Por isso a guarda está no cliente: `rede.gd` `url_permitida_no_android()`. Só deixa `ws://` para localhost, 127/8, 10/8, 172.16/12, 192.168/16, 169.254/16, `::1`, fc00::/7, fe80::/10 e `.local`. O `wss://` passa sempre. Fora da rede local, o lobby diz «Este endereço não é da rede de casa» |
| Entrada pela linha de comando (fora da web) | `-- --servidor=IP:porta --entrar-nome=… --entrar-senha=…`. É o que as provas do Windows e do Android usam. Ao 1.º snapshot de cada ligação, o cliente escreve `rede: ROOM_SNAPSHOT seq=… fase=… plataforma=…` (sem nada da ficha) |
| Job de export no CI | `ci-pendente/f2-aparelhos.yml`, com 6 jobs: `exportar` (os 3 exports, o `aparelhos_f2.gd`, o manifesto e as ABIs), `web-chromium`, `windows`, `android` (emulador x86_64, API 30), `rede-3-bots` e `qr`. Os artefactos ficam 14 dias. **Não está activo** (§5.1) |

O Android **constrói no PC**: o SDK está em `%LOCALAPPDATA%/Android/Sdk` (build-tools 34 e 35). O que falta no PC é
um aparelho para o **correr**. O `adb devices` vem vazio e não há emulador nem imagem de sistema instalados. Por isso a
prova do APK a receber o `ROOM_SNAPSHOT` é a do job `android` do CI.

### JV3.4 — a mesa serve o export e o QR

| Peça | O quê |
|---|---|
| `servidor-ws.js` | O `pastaEstatica` aponta para `build/web`: o jogo e o `ws://…/ws` saem da **mesma origem**. A ordem escreve `/mesa`. O caminho do protocolo continua `/ws` e a sala chama-se `mesa`. **`GET /qr`**: a página com o QR de cada IPv4 da rede local (192.168 primeiro) e o QR pequeno da medição. **No arranque**: o QR no terminal, com os links por extenso. Config nova: `"qr": false` cala o QR do terminal |
| `adaptadores/node/qr.js` | Gerador de QR próprio (byte mode, versões 1-10, ECC M), sem dependências. Faz SVG e terminal |
| `aparelhos/mesa-prova.mjs` | A mesa de prova: o servidor de verdade com as fichas fictícias de bancada, o Mestre-bot e, opcionalmente, o export web e as medições |
| `aparelhos/prova-3-bots.mjs` + `bots.mjs` | 3 bots, a mesma semente em duas corridas: uma de controlo e outra com 25 s sem rede para A e B, na vez de C |

### V1.0 — o link de medição de 1 minuto

`http://<mesa>/?medir=1` (ou `-- --medir` fora da web) abre a arena sem ligar à mesa e mede 5 s de aquecimento + 55 s,
pelo relógio de parede. Mede o FPS (mediana e p5), as chamadas de desenho (mediana e máximo), a GPU (o nome do Godot e
o `WEBGL_debug_renderer_info`), o viewport (o do motor, o CSS e a janela), o DPR, a plataforma e o navegador. O JSON
aparece no ecrã e vai **sozinho** para o servidor (`POST /medicao`). O servidor confere o formato, aceita até 16 KB e
500 medições por arranque, e grava na pasta `medicoes` (fora da estática). Ao Mestre vai só «abra e espere 1 minuto».

### JV3.4b — a reconexão em ≤ 30 s

O tecto da espera entre tentativas desceu de 30 s para **8 s** (1-2-4-8 s, ±20 %). Com 30 s, a tentativa seguinte
podia cair até ~36 s depois de a rede voltar. Na web, o evento `online` do navegador faz tentar logo. A prova com o
telemóvel está pendente (§5.2).

## 2. As provas (`provas/ordem-plano-2-f2/`, mapa no README)

| Aceite da ordem | Resultado |
|---|---|
| O export web diz «pronto» no Chromium sem janela em ≤ 30 s (JV0.2) | **7,9 s desde a navegação (8,6 s desde
o arranque do harness)** com a GPU, **4,5 s** com o SwiftShader (simulação do CI) |
| A web, o Windows e o Android recebem o `ROOM_SNAPSHOT` (JV2.1b) | **Web: sim** (`seq=5 fase=combate
plataforma=Web`). **Windows: sim**, o `.exe` exportado, 2,1 s depois de arrancar. **Android: não provado.** O
APK constrói (manifesto e ABIs certos), mas não há onde o correr no PC. Fica para o job `android` do CI quando
o workflow for activado. O APK é de depuração: `debuggable=true` e pede `android.permission.DUMP`, além das
três permissões listadas. O log do export Android traz ainda `ERROR: No project icon specified` (o projecto
não tem ícone) e `Could not find version of build tools that matches Target SDK, using 34.0.0` — cosmético: o
APK saiu assinado. Nos logs só aparece a build-tools 34.0.0. |
| 3 bots e 25 s sem rede: hash lógico igual e `seq` contínuo (JV3.4) | **PROVA OK**: hash `ea32c627…` igual
nas duas corridas. Seq contínuo nos três (A 6…37, B 7…37, C 8…37; 0 buracos, 0 repetidos). A e B voltaram com
o `lastSeq` 11 e receberam do 12 em diante, sem snapshot. Reentrada a **6,45 s** e **3,21 s**. Nota: o
`hashEstadoCompleto` difere entre a corrida de controlo e a de queda — é esperado: cada JOIN gera um token
novo e `epoch += 1` (`sala.js`), por isso duas corridas nunca dão o mesmo hash completo. A prova da igualdade
do jogo é o `hashLogico` (igual) mais o `seq` contínuo. `eventosPerdidosNoCorte` é `seqNaVolta − seqNoCorte`
para todos os bots: no C (que não caiu) é o número de eventos que o servidor emitiu durante o corte, não
eventos perdidos por ele. O C não perdeu nenhum evento. |
| O QR | Decodificação independente por OpenCV: **15/15 QR lidos certos** (máscaras 0, 2, 3, 6, 7; versões
1–10) — **5 casos reais da mesa + 10 de capacidade** (enchimento sintético até à capacidade da versão). As
máscaras 1, 4 e 5 não foram exercidas. A página `/qr` fotografada dá o link certo |
| As duas jogadoras entram pelo QR sem instalar nada; reconexão ≤ 30 s (JV3.4b) | **PENDENTE**: precisa do telemóvel do Mestre |
| O JSON da V1.0 traz todos os campos; repetir dá ±10 % | **No PC: sim.** 60,2 → 60,2 FPS mediana, 55,9 → 55,6
p5, 87 → 87 chamadas (RTX 4060, Chromium). **No telemóvel do Mestre: PENDENTE** (passo 6 da JV3.4b).
`viewport: 2184×1080` é o viewport do motor; a janela CSS era 1264×625 — o aceite pede só viewport + DPR. |
| Relatório de 5 blocos, com fotos dos aparelhos e logs | Este ESTADO-FINAL e os logs. As fotos dos aparelhos reais ficam para a JV3.4b. Há capturas do Chromium |
| Suites verdes e canário a 10/10 | Sim (§3) |

**Defeito apanhado e corrigido nesta corrida.** A prova do Windows falhava sem erro: o `.exe` mostrava «pronto» e
nunca entrava. Causa: o `Start-Process -ArgumentList` junta os argumentos sem aspas, e
`--entrar-nome=Espadachim de Bancada` chegava partido em três. O mesmo cliente, corrido pelo projecto, entrava. O
argumento vai agora entre aspas, na prova local e no job `windows` do workflow.

## 3. Suites (neste PC, Godot 4.7.2 `--headless`, sobre `976f897`)

| Suite | Resultado | Na D-AUD-01-CORRECCOES-2 |
|---|---|---|
| servidor (`testes/*.test.mjs`) | **435/435 no PC** (6 novos da F2); **425 executados + 10 saltos no CI** (os
10 saltos são os testes de protocolo/disco, que correm no job `protocolo` do CI) | 421 |
| motor real | 2/2 | 2/2 |
| prova da caixa | PROVA OK | PROVA OK |
| `aparelhos_f2` (novo) | **46 de 46** | — |
| `abrir_scripts` | 111 scripts, 0 falhas | 108 |
| `rodar_testes` | 321 de 321 | 321 |
| `abrir_mestre` | 67 de 67 | 67 |
| `pecas_mestre` | 294 de 294 | 294 |
| `medir_mestre` | 0 falhas, 0 sem medida | 0, 0 |
| `hud_acoes` | 50 de 50 | 50 |
| `caixa_jogadora` | 70 de 70 | 70 |
| `caixa_janela` | 123 de 123 | 123 |
| **canário de privacidade** | **10 de 10** | 10 |

Todas deram exit 0, com 0 `SCRIPT ERROR / Parse Error / Compile Error`.

**Nota sobre o servidor.** Corri primeiro como o CI, com `--permission --allow-fs-read`. Deu **418 pass, 7
fail, 10 skipped (de 435)**: os 7 que falharam são testes antigos (V20 e ordem 30) que abrem uma porta. O Node
deste PC é o 26, que já filtra a rede com
`--permission` (`ERR_ACCESS_DENIED`, `--allow-net`); o Node 24 do CI não filtra. Os 6 testes da F2 passaram mesmo
assim. O log fica em `suites/servidor-com-permission-node-local.log`. A corrida de referência é a sem `--permission`,
como nas ordens anteriores.

## 4. Commits

- `976f897`: o código (cliente, servidor, aparelhos e testes) e o workflow em `ci-pendente/`.
- `525e314`: as listas da retoma sincronizadas (`actualizar-listas.py`: **16 novos, 0 tirados, 4 mudados**).
  Nota: a mensagem do commit `525e314` diz «15 novos» por engano; o número certo é 16 (cabeçalho do
  `depois.txt`: 418 → 434 ficheiros). Fecha também o
  `retoma-pc` vermelho da ponta `4052913` (run 45305120396: «CLONE DIFERENTE: rascunhos/cliente/testes/pecas_mestre.gd»).
  A errata A1-A3 mudou esse ficheiro sem passar o guião. O `project.godot` entra no `antes.txt`, porque o ramo passa a
  mudá-lo (o autoload `Medicao`).
- O commit das provas e deste ESTADO-FINAL, e depois a nota do CI. Não mexem em `rascunhos/`, por isso não precisam de
  nova passagem das listas.

Na corrida anterior, os commits locais incluíam `.github/workflows/f2-aparelhos.yml`, e o push foi recusado
(«refusing to allow an OAuth App to create or update workflow … without `workflow` scope»). Esses commits nunca
chegaram ao remoto. Refi-los localmente com o ficheiro em `ci-pendente/`.

## 5. Pendentes, perímetro e privacidade

### 5.1 Activar o CI da F2 (um comando do dono da conta)

O âmbito do token do `gh` e do Git Credential Manager deste PC é `gist, read:org, repo`, sem `workflow`. O GitHub não
aceita commits que criem ou mudem ficheiros em `.github/workflows/` sem esse âmbito. Para activar:

```
gh auth refresh -h github.com -s workflow      # abre o navegador; só o dono da conta
git mv ci-pendente/f2-aparelhos.yml .github/workflows/f2-aparelhos.yml
# tirar as 5 linhas «PENDENTE DE ACTIVAÇÃO» do topo, commit e push
```

Até lá:
- o `aparelhos_f2.gd` não corre no CI (o `testes.yml` também precisa de `workflow` para ganhar o passo);
- o export «a cada commit» e o Android no emulador não correm;
- os testes do servidor da F2 (`plano2-f2-aparelhos.test.mjs`) já correm no job `servidor` do `testes.yml`, que
  apanha `testes/*.test.mjs`.

### 5.2 JV3.4b (prova da casa) e a V1.0 do telemóvel

Estão pendentes, com os passos exactos (cerca de 15 minutos) em `provas/ordem-plano-2-f2/rede-da-casa/PASSOS-PENDENTES.md`:
- a mesa com `--estatica=../../build/web`;
- o QR lido pelo telemóvel do Mestre;
- a 2.ª jogadora no PC;
- 10 turnos, com o Wi-Fi desligado 25 s no 5.º;
- a hora do `ENTROU (token, lastSeq)` no log contra o cronómetro;
- o `?medir=1` duas vezes;
- as 4 fotos.

O export web vem do artefacto do CI (quando activo) ou de `--export-release Web` no PC.

### 5.3 Fora do âmbito, conforme a ordem

- **Destino do repositório (JV0.5 (a) [FALTA]):** sem a sentença, a entrega é por artefacto do CI (`export-web`,
  `export-windows`, `export-android`, 14 dias), não por Pages. Com o workflow por activar, por agora os exports só
  existem no `build/` do PC (ignorado pelo git).
- **Máquina do servidor (JV0.5 (b)):** não tocada. A sessão corre no PC.
- **Fichas reais:** não entraram. As provas usam só as fictícias de bancada (`autojogo/fichas-bancada.json`).

### 5.4 Observação (não mexi)

O lobby abre com os avisos vermelhos já à vista («Nome: até 64 letras», «Falta a senha»), antes de a jogadora
escrever. Vê-se em `web/web-01-pronto-lobby.png`. É da Ordem 34 (`_validar_campos()` corre no `_atualizar()` do
arranque), não da F2. Quem chega pelo QR vê isto primeiro. Fica como sugestão para a caixa do lobby.

### 5.5 Perímetro e privacidade

- Escrevi o cliente (`rede.gd`, `lobby.gd`, `project.godot`, `export_presets.cfg`, `medicao/`), o adaptador do
  servidor (`servidor-ws.js`, `qr.js`), as ferramentas de prova (`servidor/aparelhos/`), os 2 testes, o workflow
  pendente, as provas e este ESTADO-FINAL. As listas da retoma mudaram pelo guião da casa. O núcleo da sala, o
  protocolo, os dados e a `main` ficaram como estavam.
- Nomes: só os fictícios de bancada. Nos logs, `<sede>` e `<casa>` substituem os caminhos com o utilizador da máquina
  (conferido: 0 ocorrências). A sonda de privacidade (e-mails) é a do CI.
- O IP `192.168.1.20` das provas do QR é de exemplo (`--links=`). As medições gravam o IP de quem as manda, que nas
  provas é `127.0.0.1`.

## Nota do CI

- `525e314` (código + listas): **Testes dos rascunhos 45328734361: success** e **Sonda de privacidade 45328734356:
  success**. O `retoma-pc`, vermelho na ponta `4052913` (run 45305120396), ficou verde.
- `0cdf245` (provas + ESTADO-FINAL): **Testes dos rascunhos 45328919592: success**, com os 10 jobs verdes (servidor,
  validador-glb, motor-real, protocolo, cliente, godot-cliente, foto-mestre, provas-mapa, ponta-a-ponta, retoma-pc),
  e **Sonda de privacidade 45328919620: success**.
  - No log do CI, o `servidor` dá 435 testes: 425 pass, 0 fail e 10 skipped, os saltos antigos do job sem rede. Os 6
    testes da F2 (JV3.4 ×4, V1.0 ×2) estão «✔».
  - O `rodar_testes` dá 321 de 321.
- **O workflow «Aparelhos (F2)» não correu**: está em `ci-pendente/` (§5.1). Os três exports, a web no Chromium, o
  `.exe` do Windows, os 3 bots e o QR estão provados só no PC. O APK a correr num Android não está provado em lado
  nenhum: ele constrói, mas falta o job `android`.
