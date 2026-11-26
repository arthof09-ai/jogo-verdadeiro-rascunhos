# Provas — ORDEM-PLANO-2-F2-ANDROID-SHADER

Todos os ficheiros vêm dos artefactos `prova-android` do CI («Aparelhos (F2)»), descarregados com `gh run download`,
mais o log do job `android` (`gh run view --log --job`, sem as cores ANSI). Estão inteiros e sem filtro.

| Pasta | Corrida (commit) | O que mostra |
|---|---|---|
| `antes-45457086158/` | #45457086158 (`1035436`), job 138670701384 | A falha original. `android-logcat.log` l. 2038: `Launch intent … GodotAppLauncher } with parameters []`, ou seja, o Godot arrancou sem `--servidor`, sem nome e sem senha. Depois vêm 4 `SceneShaderGLES3` com o link falhado antes do banner (cabeçalhos l. 2376–2449), o banner `OpenGL API … SwiftShader` (l. 2470), `[floresta] pronta em 6363 ms` (l. 6184), `pronto` ×2 (l. 6220 e 6232) e 2 `CanvasShaderGLES3` (cabeçalhos l. 6237 e 6244). Nenhuma linha `rede:`. O `mesa.log` não tem nenhum `ENTROU` da Arqueira |
| `depois-45810074425/` | #45810074425 (`1eb30db`), job 139876113623 | A correcção do lançamento: `android-argumentos.log` = `GodotApp (has extras) } with parameters [--, --servidor=10.0.2.2:8080, --entrar-nome=Arqueira de Bancada, --entrar-senha=prova-arqueira]`. O `android-godot.log` tem `rede: ROOM_SNAPSHOT seq=5 fase=combate plataforma=Android`, com os erros de link AINDA presentes (85 Scene, 2 Canvas e 3 Sky). O `mesa.log` tem `ENTROU Arqueira de Bancada`. `PROVA ANDROID OK` |
| `controlo-45811149778/` | #45811149778 (`6b59dca`) | 1.ª tentativa do controlo, com `--main-pack`: o modelo oficial aborta (`controlo-gles-godot.log`: «compiled without support for path overrides. Aborting.»). A prova do jogo nesta corrida também passou |
| `controlo-45812668899/` | #45812668899 (`56d3f91`), job 139885092523 | **A medição.** `controlo-gles-medida.log` põe lado a lado o controlo (um Godot 4.7.2 vazio no MESMO `libgodot_android.so` do jogo, SHA-256 `7a103707…` IGUAL) e o jogo. O controlo dá 4 links falhados antes do banner, 10 Scene e 1 Canvas, com o tecto declarado de 261. O jogo dá 4 antes do banner, 85 Scene, 2 Canvas e 3 Sky, também com 261. `controlo-gles.png` e `android-arena.png` são o mesmo cinzento liso (#4D4D4D, a cor de limpeza do Godot): no emulador nem o Godot vazio desenha. O jogo recebeu o ROOM_SNAPSHOT na mesma corrida |
| `fontes/` | — | Excertos das fontes citadas. `godot-4.7.2-GodotActivity.kt.excerto` (tag `4.7.2-stable`): `sanitizeLaunchIntent` / `retrieveCommandLineParamsFromLaunchIntent`. `godot-4.7.2-rasterizer_gles3.cpp.excerto`: o banner sai de `initialize()`, depois de o construtor criar o `MaterialStorage`. `swiftshader-*.excerto` (google/swiftshader `103a69bd`, o último commit com o GLES antigo): `FRAGMENT_UNIFORM_VECTORS = 264`, `MAX_FRAGMENT_UNIFORM_VECTORS = … − 3` (= 261), e a mensagem que imprime essa constante. `swiftshader-Config.hpp.excerto` = `src/Main/Config.hpp` (google/swiftshader `103a69bd`) |
| `suites/` | worktree LF em `6b59dca` | As suites do `provas/ordem-plano-2-f2/windows/suites.sh`, com o `resumo.txt` |

O caminho da máquina aparece como `<sede>`. Nos logcat, a única palavra próxima de dados pessoais é «Gmail»: é a
app de sistema do emulador (`/product/app/PrebuiltGmail`).
