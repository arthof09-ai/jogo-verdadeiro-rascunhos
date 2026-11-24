# Provas — ORDEM-PLANO-2-F2 (cada um no seu aparelho)

Todas as corridas foram feitas no PC, em 24/11/2026, sobre os exports feitos a partir do código do commit `976f897`
(Godot 4.7.2, Node 26, Chromium 157 sem janela). Só entram fichas fictícias de bancada (Espadachim, Arqueira e
Batedora de Bancada; «Mestre da prova»). Nos logs, `<sede>` e `<casa>` substituem o caminho com o utilizador da máquina.

| Pasta | O que prova | Resultado |
|---|---|---|
| `exportes/` | JV2.1b: os três exports constroem (logs sem as linhas de arquivo a arquivo), os tamanhos e o SHA-256 | Web, Windows e Android com exit 0 e 0 erros de script. Web com `GODOT_THREADS_ENABLED = false` |
| `android/` | JV2.1b: o manifesto e as ABIs do APK (`aapt2` 35.0.0) | `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`. Só `lib/arm64-v8a` e `lib/x86_64` |
| `web/` | JV0.2, JV2.1b e V1.0 com a **GPU real** do PC (`--gpu --repetir-medicao`) | «pronto» em **7,9 s**. `ROOM_SNAPSHOT seq=5 fase=combate plataforma=Web`. V1.0 ×2: FPS mediana **60,2 / 60,2**, p5 **55,9 / 55,6**, chamadas **87 / 87**. Os dois JSON foram gravados pelo servidor (`medicoes-v1.0/`) |
| `web-ci-swiftshader/` | A mesma prova, em SwiftShader (WebGL por software), **como correrá no CI** quando o
workflow «Aparelhos (F2)» for activado. | «pronto» em **4,5 s**, `ROOM_SNAPSHOT` recebido, V1.0 com todos os
campos (1,5 FPS: é o SwiftShader, não o jogo) |
| `windows/` | JV2.1b: o `Assimilacao.console.exe` exportado entra pela linha de comando e recebe o snapshot | `ROOM_SNAPSHOT seq=5 fase=combate plataforma=Windows` **2,1 s** depois de arrancar. 0 erros de script |
| `qr/` | JV3.4: o QR lido por um decodificador independente (OpenCV 5.1) | **15 de 15** QR (versões 1-10, máscaras várias) lidos certos. A página `/qr` fotografada no Chromium dá `http://192.168.1.20:8080/` |
| `rede-3-bots/` | JV3.4: 3 bots com 25 s sem rede para 2 deles | Hash lógico **igual** (`ea32c627…`). Seq contínuo nos três (0 buracos, 0 repetidos). Reentrada **6,45 s** e **3,21 s** depois de a rede voltar |
| `rede-da-casa/` | JV3.4b: a prova com o telemóvel do Mestre | **PENDENTE** (sem o Mestre na hora). O guião exacto está em `PASSOS-PENDENTES.md` |
| `suites/` | As suites da linha e o canário | Todas com exit 0 e 0 erros de script. Canário **10/10**. O resumo está em `resumo.txt` |

O `web-01-pronto-lobby.png` é a captura do lobby no momento do «pronto». O `web-02-arena-na-mesa.png` mostra a arena
depois da entrada. Os `web-03-medicao-*.png` mostram o ecrã com o JSON da V1.0.

**O que não está aqui:** as fotos dos aparelhos reais (telemóvel e PC lado a lado), o JSON da V1.0 do telemóvel do
Mestre e a prova do APK num Android a correr. As duas primeiras dependem da JV3.4b (ver `rede-da-casa/`). A terceira
depende do job `android` do workflow, que está em `ci-pendente/` (ver o ESTADO-FINAL).

Os logs `qr.log` e `prova-windows.log` saíram da consola do Windows em CP1252 e têm caracteres fora de UTF-8;
o conteúdo é o lido aqui. O `canario.log` abre com um aviso `Unicode parsing error … Unexpected NUL character`
do Godot antes do primeiro teste — benigno, de origem não determinada; o canário dá 10/10 na mesma.
