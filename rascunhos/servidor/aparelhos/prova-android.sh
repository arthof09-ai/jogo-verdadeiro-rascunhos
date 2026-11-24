#!/usr/bin/env bash
# Ordem PLANO-2-F2 (JV2.1b): o APK no Android recebe o ROOM_SNAPSHOT da mesa de prova.
#
#   bash aparelhos/prova-android.sh <assimilacao.apk> <pasta-de-saída> [servidor=10.0.2.2:8080]
#
# Precisa de um aparelho no adb (o emulador do CI, ou o telemóvel do Mestre com a depuração USB) e da mesa de prova a
# correr com --mestre-auto. No emulador, 10.0.2.2 é a máquina do CI (a rede local do emulador: a guarda do Android deixa
# o ws:// passar). A entrada vem da linha de comando (o extra «command_line_params» da activity do Godot), como no
# Windows: «-- --servidor=… --entrar-nome=… --entrar-senha=…». Só fichas fictícias.
set -u
APK="$1"
SAIDA="$2"
SERVIDOR="${3:-10.0.2.2:8080}"
PACOTE=org.assimilacao.mesa
mkdir -p "$SAIDA"
adb wait-for-device
adb shell getprop ro.build.version.release | sed 's/^/Android /'
adb shell getprop ro.product.cpu.abi | sed 's/^/ABI /'
adb install -r "$APK" || exit 1
adb logcat -c
adb shell "am start -W -n $PACOTE/com.godot.game.GodotAppLauncher --esa command_line_params '--,--servidor=$SERVIDOR,--entrar-nome=Arqueira de Bancada,--entrar-senha=prova-arqueira'"
ok=1
for i in $(seq 1 120); do
  if adb logcat -d -s godot:* 2>/dev/null | grep -qE "rede: ROOM_SNAPSHOT seq=[0-9]+ fase=combate plataforma=Android"; then ok=0; break; fi
  sleep 1
done
sleep 3
adb exec-out screencap -p > "$SAIDA/android-arena.png" || true
adb logcat -d > "$SAIDA/android-logcat.log" 2>&1 || true
adb logcat -d -s godot:* > "$SAIDA/android-godot.log" 2>&1 || true
tail -40 "$SAIDA/android-godot.log"
if grep -qE "SCRIPT ERROR|Parse Error" "$SAIDA/android-godot.log"; then echo "FALHA: erros de script no Android"; exit 1; fi
if [ $ok -ne 0 ]; then echo "FALHA: o Android não recebeu o ROOM_SNAPSHOT em 120 s"; exit 1; fi
grep -E "rede: ROOM_SNAPSHOT" "$SAIDA/android-godot.log" | head -1
echo "PROVA ANDROID OK"
