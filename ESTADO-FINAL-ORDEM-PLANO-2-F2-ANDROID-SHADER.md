# ESTADO-FINAL — ORDEM-PLANO-2-F2-ANDROID-SHADER (o Android no emulador não recebia o ROOM_SNAPSHOT)

**Estado: FEITA.** O job `android` do «Aparelhos (F2)» está **verde no CI**, e o APK **recebe o `ROOM_SNAPSHOT`** da
mesa de prova: `rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Android`, com `ENTROU Arqueira de Bancada` na mesa.
Isto aconteceu em cinco corridas seguidas: #45810074425, #45811149778, #45812668899, #45813289262 e #45813928709. O F1 da sentença 595 fica provado no CI.

**A causa NÃO eram os shaders.** O APK arrancava **sem argumentos**. O Godot 4.7.2 tira o `command_line_params` de
qualquer intent dirigida a uma activity exportada, e o guião lançava o `GodotAppLauncher`, que é exportado. Sem
`--servidor`, sem nome e sem senha, o jogo ficou no lobby e nunca se ligou. Corrigi o lançamento, só no guião da prova.

**Os erros de shader são do emulador: veredicto (a), MEDIDO.** Um Godot 4.7.2 vazio, a correr no mesmo motor e no mesmo
emulador, falha o link dos seus próprios shaders com o mesmo tecto de 261. Também não desenha nada. Os shaders do jogo
não foram tocados, nem precisavam.

- **Executor:** Claude (opus), PC (conta 2). **Data:** 26/11/2026, ~08:15–09:00 (-03).
- **Linha:** `fable/integracao-50`, trabalho directo. A `main` não foi tocada. Ponta de partida: `a3d0cbc`.

## 1. Onde a corrida parava (item 1), linha a linha

Reli o log do run #45457086158 por API (job 138670701384) e os artefactos `prova-android`. Estão inteiros em
`provas/ordem-plano-2-f2-android-shader/antes-45457086158/`. Linhas do `android-logcat.log`:

| Linha | O que diz |
|---|---|
| 2036 | `GodotActivity: Project command line parameters: [--xr_mode_regular, --xr-mode, off, --fullscreen, --background_color, #000000]`: o APK arranca |
| **2038** | **`GodotActivity: Launch intent Intent { flg=0x10000000 cmp=org.assimilacao.mesa/com.godot.game.GodotAppLauncher } with parameters []`**. O `am start` tinha enviado o extra (`ActivityTaskManager: START … (has extras)`), mas o Godot entregou-o **vazio** |
| **2376, 2387, 2395, 2449** | 4× `ERROR: SceneShaderGLES3: Program linking failed:` (detalhe na linha seguinte: `Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`) |
| 2470 | `OpenGL API OpenGL ES 3.0 (OpenGL ES 3.0 SwiftShader 4.0.0.1) - Compatibility …`: o banner do motor. Os 4 erros vêm **antes** dele |
| 6184 | `[floresta] pronta em 6363 ms` |
| 6220, 6232 | `pronto` ×2 (a arena e o lobby) |
| **6237, 6244** | 2× `ERROR: CanvasShaderGLES3: Program linking failed:` (detalhe na linha seguinte, idem) |
| — | **Nenhuma linha `rede:`.** O `mesa.log` só tem o Mestre-bot. A Arqueira nunca tentou entrar |

O `rede.gd` (`iniciar()` → `entrada_da_linha_de_comando()`) só entra sozinho se houver `--entrar-nome=` e
`--entrar-senha=` em `OS.get_cmdline_user_args()`. Sem eles, chama `_pedir_entrada("")` e fica no lobby à espera de
alguém. Os erros de shader não param o GDScript: a floresta carregou e o `pronto` saiu duas vezes.

**A causa, na fonte do Godot 4.7.2** (`fontes/godot-4.7.2-GodotActivity.kt.excerto`, tag `4.7.2-stable`):
`onCreate` chama `sanitizeLaunchIntent`, que faz `removeExtra(EXTRA_COMMAND_LINE_PARAMS)` quando
`activityInfo.exported`. Depois, `retrieveCommandLineParamsFromLaunchIntent` só lê os parâmetros de activities **não
exportadas**. O `GodotAppLauncher` é o atalho do ecrã inicial e é exportado. O `GodotApp` não é. O teste do próprio
Godot (`GodotAppTest.kt`, `testExplicitGodotAppLauncherLaunch`) confirma: pelo launcher, `assertNull(commandLineParams)`.

## 2. O defeito da prova: emulador ou jogo? (itens 2 e 3)

A ordem punha duas hipóteses para os shaders. A medição mostrou que **o ROOM_SNAPSHOT não dependia de nenhuma delas**.
Para a pergunta dos shaders, a resposta é **(a): o tecto do SwiftShader**. O «261» também se percebeu mal na ordem: não
é o que os shaders pedem, é o **tecto** do emulador.

### 2.1 O «261» é o tecto do SwiftShader (fonte)

O driver do emulador é o GLES antigo do SwiftShader (`OpenGL ES 3.0 SwiftShader 4.0.0.1`). Nas fontes
(`fontes/swiftshader-*.excerto`, google/swiftshader `103a69bd`, o último commit com o `src/OpenGL/libGLESv2`):

- `Config.hpp` (`src/Main/Config.hpp`): `FRAGMENT_UNIFORM_VECTORS = 264`
- `Context.h`: `MAX_FRAGMENT_UNIFORM_VECTORS = sw::FRAGMENT_UNIFORM_VECTORS - 3, // Reserve space for gl_DepthRange`, ou seja **261**
- `Program.cpp`: `appendToInfoLog("Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (%d)", MAX_FRAGMENT_UNIFORM_VECTORS)`. O número entre parênteses é a constante do driver, e não a contagem do shader

### 2.2 Os 4 primeiros erros são do motor, antes de o projecto carregar (fonte + log)

`fontes/godot-4.7.2-rasterizer_gles3.cpp.excerto`: o construtor `RasterizerGLES3()` cria o `GLES3::MaterialStorage`
(compila os shaders por omissão do motor) e só depois `initialize()` imprime o banner `OpenGL API …`. Os 4
`SceneShaderGLES3` falhados vêm antes do banner em todas as corridas. Nessa altura ainda não há nenhuma cena nem nenhum
shader do jogo carregado.

### 2.3 A medição: o controlo GLES no mesmo emulador e no mesmo motor (prova por medição)

O controlo é um projecto Godot 4.7.2 vazio (`rascunhos/servidor/aparelhos/controlo-gles/`): um cubo com o
`StandardMaterial3D` por omissão, uma luz, uma câmara e um `Label`. Não tem nenhum shader nem recurso do jogo. Para correr
**com o mesmo motor**, o `controlo-gles.sh` monta o APK do controlo a partir do APK do jogo. Mantém o
`libgodot_android.so`, o `classes.dex` e o manifesto, troca só os `assets/` pelos do export Android do controlo
(`controlo-gles-assets.zip`, 4 KB), e depois faz o `zipalign` e o `apksigner` com uma chave feita na hora. Corre no fim
do `prova-android.sh`, no mesmo emulador e logo a seguir à prova (o exit continua a ser o da prova).

Corrida #45812668899 (`56d3f91`), `controlo-45812668899/controlo-gles-medida.log`:

| | Controlo (Godot vazio) | Jogo |
|---|---|---|
| `libgodot_android.so` (prefixo SHA-256, 16 hex) | `7a103707ecbf1d24…` | `7a103707ecbf1d24…` (**IGUAL**) |
| `classes.dex` (prefixo SHA-256, 16 hex) | `4a3b10789d65d1e2…` | `4a3b10789d65d1e2…` (**IGUAL**) |
| Links falhados antes do banner (init do motor) | **4** | **4** |
| `SceneShaderGLES3` link falhado (total) | **10** | 85 |
| `CanvasShaderGLES3` | **1** | 2 |
| `SkyShaderGLES3` | 0 | 3 |
| Tecto declarado | `GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)` | `(261)` |
| Captura | cinzento liso #4D4D4D (`controlo-gles.png`) | cinzento liso #4D4D4D (`android-arena.png`) |
| Disse «pronto» | sim (`controlo-gles pronto`) | sim, e recebeu o ROOM_SNAPSHOT |

As duas capturas são byte-idênticas (um só pixel #4D4D4D, 640×320) porque uma cor de limpeza lisa codifica sempre igual; por isso as capturas provam só que o ecrã estava cinzento liso na altura da captura, e a identidade de cada captura (controlo vs jogo) prova-se pelos logs (`controlo-gles pronto` no log do controlo; `rede: ROOM_SNAPSHOT` no log do jogo), não pelos PNGs.

**Leitura:** o shader de cena do Godot 4.7.2 com o material **por omissão** já passa o tecto de 261 do SwiftShader.
Também o shader de canvas do `Label` por omissão. Por isso, o tecto deste emulador é **menor do que o mínimo** que o
Godot 4.7.2 (Compatibility) exige para os seus próprios shaders. O jogo tem mais falhas só porque tem mais materiais e
mais variantes (céu, folhagem, água), cada uma uma especialização do mesmo shader de cena. Neste emulador, nem o Godot
vazio desenha: o ecrã fica na cor de limpeza (#4D4D4D, o `default_clear_color` do Godot). É o critério (a): «mostra, por
medição, que o tecto do emulador é menor do que o mínimo que o Godot 4.7.2 exige para estes shaders».

**Por isso, não mexi nos shaders do jogo.** Reduzir os uniformes do jogo não chegava: o shader do motor falha sozinho.
Reduzi-los até caberem em 261 não teria efeito neste emulador, e mudaria o aspecto no PC sem razão provada.

**O que isto NÃO prova:** que o jogo **desenha** bem num Android real. O job `android` prova a rede (o APK liga-se, entra
e recebe o snapshot). O desenho num aparelho real é da JV3.4b (o telemóvel do Mestre), que é ordem própria. Para um
emulador que desenhe, a via seria trocar `-gpu swiftshader_indirect` por um modo com mais tecto (por exemplo
`swangle_indirect`, o ANGLE sobre o SwiftShader Vulkan). Isso muda o workflow, e o token do PC não pode mudar workflows
(§4). Não o experimentei: fica como sugestão para o dono.

## 3. A prova verde (critério de aceite)

`depois-45810074425/` (a 1.ª corrida verde, `1eb30db`) e `controlo-45812668899/` (a última, `56d3f91`):

| Medida | #45810074425 | #45812668899 |
|---|---|---|
| `adb uid` | 0 (root) | 0 (root) |
| Argumentos recebidos (`android-argumentos.log`) | `… cmp=org.assimilacao.mesa/com.godot.game.GodotApp (has extras) } with parameters [--, --servidor=10.0.2.2:8080, --entrar-nome=Arqueira de Bancada, --entrar-senha=prova-arqueira]` | idem |
| ROOM_SNAPSHOT (relógio do emulador) | `11:27:06.456 … rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Android` | `11:44:22.654 …` idem |
| Mesa (relógio do runner) | `11:27:07.201 ENTROU Arqueira de Bancada` | `11:44:22.926 ENTROU Arqueira de Bancada` |
| Fim | `PROVA ANDROID OK`, job success | `PROVA ANDROID OK`, `CONTROLO GLES MEDIDO`, job success |
| Run inteiro | success (6/6) | **success (6/6)** |

O `SAIU` vem depois. Na #45810074425 o emulador fecha-se no fim do job. Na #45812668899 a desinstalação do jogo para
instalar o controlo fecha o APK.

**O que mudou no guião** (`rascunhos/servidor/aparelhos/prova-android.sh`):
`adb root` (com a confirmação `id -u` = 0) e `am start -n org.assimilacao.mesa/com.godot.game.GodotApp` em vez do
`GodotAppLauncher`. Só um processo root pode lançar uma activity não exportada de fora. A imagem `google_apis` do
emulador deixa fazê-lo. A prova passa a **conferir os argumentos**: falha com «o Godot não recebeu os argumentos da
linha de comando» se a linha `Launch intent … with parameters [--, --servidor=…` não estiver no logcat. Assim, este erro
nunca mais se confunde com outro. Num telemóvel de loja não há root, e aí a entrada é pelo lobby (JV3.4b).

## 4. O que se mudou, e o que não

- `rascunhos/servidor/aparelhos/prova-android.sh`: o lançamento, a conferência dos argumentos e a chamada ao controlo no fim.
- `rascunhos/servidor/aparelhos/controlo-gles.sh`, `controlo-gles-assets.zip` e `controlo-gles/` (o projecto, com o
  `export_presets.cfg` copiado do preset Android do jogo; muda o pacote, o nome e o arm64 desligado): a medição.
- **Não toquei** nos shaders, no cliente, no servidor, no `export_presets.cfg` do jogo, no workflow, na C-7, na
  posição da caixa, na C-6 nem na caixa da jogadora.
- **O workflow:** a 1.ª versão punha o controlo como passo do workflow. O push foi recusado («refusing to allow an OAuth
  App to create or update workflow … without `workflow` scope»: o token do PC só tem `repo`). Passei-o para
  `ci-pendente/` e depois tirei-o, quando o controlo passou a correr só a partir do guião, que o workflow activo já
  chama. **Não há nada para o dono mover.**
- **O `--main-pack`** foi a 2.ª via do controlo e não serve: o modelo oficial aborta («compiled without support for path
  overrides»). A corrida está em `controlo-45811149778/`.
- **Os assets do controlo:** exportei-os neste PC com um Godot 4.7.2 **autónomo** (cópia em pasta temporária com
  `._sc_`, com as definições e os modelos lá dentro, sem tocar nas definições do utilizador). O `android_debug.apk` veio
  do `.tpz` oficial já em cache (o mesmo da ordem anterior). Usei um SDK de fachada só para passar a validação do editor,
  com `package/signed=false`: o export não chama o SDK. A assinatura real é a do `apksigner` do runner. O motor do APK
  exportado aqui é **igual** ao do jogo exportado no CI (SHA-256 acima). Para os refazer: um export Android de
  `controlo-gles/` com o Godot 4.7.2 e os templates oficiais, com `package/signed=false` e um SDK de fachada só para passar a validação do editor; depois os `assets/*` do APK num zip.
- **As listas da retoma** foram sincronizadas (`actualizar-listas.py`) depois de cada commit em `rascunhos/`.

## 5. Suites (verde) — `provas/ordem-plano-2-f2-android-shader/suites/`

Corri o `provas/ordem-plano-2-f2/windows/suites.sh` (o mesmo da ordem anterior) neste PC, com o Godot 4.7.2
`--headless`, num **worktree LF** (`git -c core.autocrlf=false worktree add`, em `6b59dca`; o clone tem
`core.autocrlf=true`, ver `suites/worktree-lf.log`). O código do cliente e do servidor de `6b59dca` é o mesmo da ponta:
os commits seguintes só mudam o guião, o controlo, as listas e as provas.

| Suite | Resultado |
|---|---|
| servidor (`testes/*.test.mjs`) | **446/446**, exit 0 |
| prova-caixa | exit 0 |
| motor real | **6/6**, exit 0 (o motor da pasta privada da bancada; fora do repo, não copiado) |
| aparelhos_f2, abrir_scripts, rodar_testes, abrir_mestre, pecas_mestre, medir_mestre, hud_acoes, caixa_jogadora, caixa_janela, canario_privacidade | exit 0, 0 erros de script em todas |
| validar-mensagens (pecas_mestre, abrir_mestre) | exit 0 |

No CI, sobre `56d3f91`: **Testes dos rascunhos 45812670759 success**, **Sonda de privacidade 45812668759 success** e
**Aparelhos (F2) 45812668899 success (6/6)**.

## 6. Privacidade

Varri toda a pasta `provas/ordem-plano-2-f2-android-shader/` com
`grep -raiE "pierre|rpg_local|gmail|arth\.of|rpg\.assimilacao"` e com um padrão de e-mail. Os únicos acertos são
«Gmail» nos logcat: é a app de sistema do emulador (`/product/app/PrebuiltGmail`). Não há nenhum e-mail. Nos logs das
suites, o caminho da máquina aparece como `<sede>`. Os assets do controlo também foram varridos já descomprimidos: só
aparecem `res://` e `local://`. Só aparecem fichas fictícias (Arqueira de Bancada / `prova-arqueira`). Nada do Mestre
real. A Sonda de privacidade do CI deu success.

## 7. Notas fora do âmbito

- **`qr` intermitente:** o job `qr` falhou em `a3d0cbc` (antes desta ordem) e em `6b59dca`, e passou em `1eb30db` e
  `56d3f91`. Nas falhas, `navegador.mjs:37` dá «o navegador não abriu o DevTools»: o Chromium não abriu a porta a tempo.
  Não tem que ver com esta ordem nem foi tocado.
- **Commit `7b22a95` de outra mão** (erratas de texto da PROVA-WINDOWS) entrou no ramo durante o trabalho. Só mexe em
  dois `.md`. Reapliquei por cima dele o último commit desta ordem (este ESTADO-FINAL e as provas).

## 8. Commits

- `445a71b` + `1eb30db` (listas): o lançamento pela activity não exportada, a conferência dos argumentos, o controlo
  (1.ª versão) e o `ci-pendente/`.
- `784d28c` + `6b59dca` (listas): o controlo por `--main-pack` (abortou, §4). Sai o `ci-pendente/`.
- `74fecdc` + `56d3f91` (listas): o controlo num APK montado a partir do APK do jogo. É a medição que fica.
- O commit deste ESTADO-FINAL, das provas e da linha no `provas/ordem-plano-2-f2/README.md`.

## Nota do CI (ponta `2eeb987`, com este ESTADO-FINAL e as provas)

**Testes dos rascunhos 45813928771 success**, **Sonda de privacidade 45813928703 success** e **Aparelhos (F2)
45813928709 success**, com os 6 jobs verdes (exportar, web-chromium, windows, **android**, rede-3-bots e qr). 
É a **quinta** corrida seguida com o `android` verde.

_Nota de registo (errata E1, sentença 862):_ seis, se contada a corrida sobre a própria ponta `5751cce` (#45814828108).
