#!/usr/bin/env bash
# Ordem PLANO-2-F2 (JV2.1b): o APK no Android recebe o ROOM_SNAPSHOT da mesa de prova.
#
#   bash aparelhos/prova-android.sh <assimilacao.apk> <pasta-de-saída> [servidor=10.0.2.2:8080]
#
# Precisa de um aparelho no adb (o emulador do CI, ou o telemóvel do Mestre com a depuração USB) e da mesa de prova a
# correr com --mestre-auto. No emulador, 10.0.2.2 é a máquina do CI (a rede local do emulador: a guarda do Android deixa
# o ws:// passar). A entrada vem da linha de comando (o extra «command_line_params» da activity do Godot), como no
# Windows: «-- --servidor=… --entrar-nome=… --entrar-senha=…». Só fichas fictícias.
#
# ORDEM-PLANO-2-F2-ANDROID-SHADER: o Godot 4.7.2 (GodotActivity.sanitizeLaunchIntent) TIRA o «command_line_params» de
# qualquer intent que vise uma activity EXPORTADA — e o GodotAppLauncher (o atalho do ecrã inicial) é exportado. Por isso
# a 1.ª corrida arrancou sem argumentos («Launch intent … with parameters []») e nunca se ligou à mesa. Os argumentos só
# passam para a activity NÃO exportada, com.godot.game.GodotApp, e só um processo com privilégio (root) a pode lançar de
# fora: daí o «adb root» (o emulador google_apis deixa; num telemóvel de loja não há root — aí a entrada é pelo lobby).
set -u
APK="$1"
SAIDA="$2"
SERVIDOR="${3:-10.0.2.2:8080}"
PACOTE=org.assimilacao.mesa
ACTIVITY=com.godot.game.GodotApp
mkdir -p "$SAIDA"
adb wait-for-device
adb root >/dev/null 2>&1 || true
adb wait-for-device
for i in $(seq 1 30); do [ "$(adb shell id -u 2>/dev/null | tr -d '\r')" = "0" ] && break; sleep 1; done
echo "adb uid $(adb shell id -u | tr -d '\r') (0 = root, preciso para lançar a activity não exportada)"
adb shell getprop ro.build.version.release | sed 's/^/Android /'
adb shell getprop ro.product.cpu.abi | sed 's/^/ABI /'
adb install -r "$APK" || exit 1
adb logcat -c
adb shell "am start -W -n $PACOTE/$ACTIVITY --esa command_line_params '--,--servidor=$SERVIDOR,--entrar-nome=Arqueira de Bancada,--entrar-senha=prova-arqueira'"
ok=1
for i in $(seq 1 120); do
  if adb logcat -d -s godot:* 2>/dev/null | grep -qE "rede: ROOM_SNAPSHOT seq=[0-9]+ fase=combate plataforma=Android"; then ok=0; break; fi
  sleep 1
done
sleep 3
adb exec-out screencap -p > "$SAIDA/android-arena.png" || true
adb logcat -d > "$SAIDA/android-logcat.log" 2>&1 || true
adb logcat -d -s godot:* > "$SAIDA/android-godot.log" 2>&1 || true
# Os argumentos que o Godot de facto recebeu (a linha da GodotActivity): têm de lá estar o servidor, o nome e a senha.
grep -E "GodotActivity: (Project command line|Launch intent)" "$SAIDA/android-logcat.log" | tee "$SAIDA/android-argumentos.log"
tail -40 "$SAIDA/android-godot.log"
r=0
if ! grep -q "Launch intent .* with parameters \[--, --servidor=$SERVIDOR" "$SAIDA/android-argumentos.log"; then
  echo "FALHA: o Godot não recebeu os argumentos da linha de comando"; r=1
elif grep -qE "SCRIPT ERROR|Parse Error" "$SAIDA/android-godot.log"; then echo "FALHA: erros de script no Android"; r=1
elif [ $ok -ne 0 ]; then echo "FALHA: o Android não recebeu o ROOM_SNAPSHOT em 120 s"; r=1
else
  grep -E "rede: ROOM_SNAPSHOT" "$SAIDA/android-godot.log" | head -1
  echo "PROVA ANDROID OK"
fi
# ORDEM-PLANO-2-F2-ANDROID-SHADER: a seguir, no MESMO emulador e com o MESMO motor, o controlo dos shaders (um Godot
# vazio, ver controlo-gles.sh). É uma medição: o exit deste guião continua a ser o da prova.
if [ -s "$(dirname "$0")/controlo-gles-assets.zip" ]; then
  bash "$(dirname "$0")/controlo-gles.sh" "$APK" "$SAIDA" "$SAIDA/android-godot.log" || echo "(o controlo GLES não correu até ao fim; a prova não depende dele)"
fi
exit $r
