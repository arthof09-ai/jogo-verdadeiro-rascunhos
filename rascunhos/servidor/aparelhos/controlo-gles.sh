#!/usr/bin/env bash
# ORDEM-PLANO-2-F2-ANDROID-SHADER: a medição de CONTROLO dos shaders no emulador.
#
#   bash aparelhos/controlo-gles.sh <assimilacao.apk do jogo> <pasta-de-saída> [android-godot.log do jogo]
#
# O controlo é um Godot 4.7.2 vazio (aparelhos/controlo-gles/: um cubo com o material padrão e um texto; NENHUM shader
# nem recurso do jogo). Para correr com o MESMO motor do jogo, este guião faz o APK do controlo a partir do APK do jogo:
# copia tudo (o libgodot_android.so, o classes.dex, o manifesto) menos os assets/ e a assinatura, põe no lugar dos
# assets/ os do controlo (aparelhos/controlo-gles-assets.zip: os assets/ do export Android do controlo, 4 KB), alinha
# (zipalign) e assina com uma chave de depuração feita aqui (apksigner). Depois tira o jogo do emulador, instala o
# controlo, espera o «controlo-gles pronto», guarda o log e a captura, e conta os «Program linking failed» por shader do
# motor e o tecto que o driver declara — no controlo e, se for dado, no log do jogo, lado a lado.
# (O «--main-pack» não serve: o modelo oficial vem compilado com disable_path_overrides e aborta.)
# É uma MEDIÇÃO: só falha se o controlo não chegar a correr; nunca por haver erros de link.
# Precisa do adb, do $ANDROID_HOME (build-tools com zipalign e apksigner), do java/keytool e do python3 (o runner do CI
# tem tudo). Os assets refazem-se com um export Android do controlo-gles/ (ver o ESTADO-FINAL da ordem).
set -u
APK_JOGO="$1"
SAIDA="$2"
JOGO_LOG="${3:-}"
AQUI="$(cd "$(dirname "$0")" && pwd)"
PACOTE=org.assimilacao.mesa
mkdir -p "$SAIDA"
T="$(mktemp -d)"
BT=$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)
python3 - "$APK_JOGO" "$AQUI/controlo-gles-assets.zip" "$T/controlo-sem-assinatura.apk" <<'EOF' || { echo "FALHA: não consegui montar o APK do controlo"; exit 1; }
import sys, zipfile
jogo, assets, saida = sys.argv[1:4]
with zipfile.ZipFile(jogo) as j, zipfile.ZipFile(assets) as a, zipfile.ZipFile(saida, 'w') as o:
    for i in j.infolist():
        n = i.filename
        assinatura = n.startswith('META-INF/') and n.count('/') == 1 and (n == 'META-INF/MANIFEST.MF' or n.endswith(('.SF', '.RSA', '.DSA', '.EC')))
        if n.startswith('assets/') or assinatura:
            continue
        o.writestr(i, j.read(i.filename), compress_type=i.compress_type)
    for i in a.infolist():
        o.writestr(i, a.read(i.filename), compress_type=i.compress_type)
print('controlo montado:', saida)
EOF
"$BT/zipalign" -f -p 4 "$T/controlo-sem-assinatura.apk" "$T/controlo-alinhado.apk" || exit 1
keytool -genkeypair -keyalg RSA -alias controlo -keypass android -storepass android -keystore "$T/controlo.keystore" \
  -dname "CN=Controlo GLES" -validity 1 -deststoretype pkcs12 >/dev/null 2>&1 || exit 1
"$BT/apksigner" sign --ks "$T/controlo.keystore" --ks-pass pass:android --key-pass pass:android \
  --out "$T/controlo-gles.apk" "$T/controlo-alinhado.apk" || exit 1
python3 - "$APK_JOGO" "$T/controlo-gles.apk" <<'EOF' | tee "$SAIDA/controlo-gles-motor.log"
import sys, zipfile, hashlib
for n in ('lib/x86_64/libgodot_android.so', 'classes.dex'):
    h = [hashlib.sha256(zipfile.ZipFile(f).read(n)).hexdigest() for f in sys.argv[1:3]]
    print('%s jogo=%s controlo=%s %s' % (n, h[0], h[1], 'IGUAL' if h[0] == h[1] else 'DIFERENTE'))
EOF
adb wait-for-device
adb shell am force-stop "$PACOTE" || true
adb uninstall "$PACOTE" >/dev/null 2>&1 || true   # a assinatura é outra: o jogo sai, o controlo entra com o mesmo pacote
adb install -r "$T/controlo-gles.apk" || exit 1
adb logcat -c
adb shell "am start -W -n $PACOTE/com.godot.game.GodotAppLauncher"
ok=1
for i in $(seq 1 60); do
  if adb logcat -d -s godot:* 2>/dev/null | grep -q "controlo-gles pronto"; then ok=0; break; fi
  sleep 1
done
sleep 2
adb exec-out screencap -p > "$SAIDA/controlo-gles.png" || true
adb logcat -d > "$SAIDA/controlo-gles-logcat.log" 2>&1 || true
adb logcat -d -s godot:* > "$SAIDA/controlo-gles-godot.log" 2>&1 || true
adb shell am force-stop "$PACOTE" || true
rm -rf "$T"

contar() {  # <log> -> os «Program linking failed» por shader do motor, o tecto declarado e o driver
  local log="$1"
  for s in SceneShaderGLES3 CanvasShaderGLES3 SkyShaderGLES3 ParticlesShaderGLES3 CopyShaderGLES3; do
    printf '  %-28s %s\n' "$s link falhado:" "$(grep -c "ERROR: $s: Program linking failed" "$log")"
  done
  printf '  %-28s %s\n' "antes do banner (init):" "$(awk '/OpenGL API/{exit} /Program linking failed/{n++} END{print n+0}' "$log")"
  printf '  %-28s %s\n' "tecto declarado:" "$(grep -oE 'GL_MAX_FRAGMENT_UNIFORM_VECTORS \([0-9]+\)' "$log" | sort -u | tr '\n' ' ')"
  printf '  %-28s %s\n' "driver:" "$(grep -oE 'OpenGL API .*' "$log" | head -1)"
}
{
  echo "== CONTROLO (Godot 4.7.2 vazio, o MESMO motor do APK do jogo, nenhum shader do jogo)"
  sed 's/^/  /' "$SAIDA/controlo-gles-motor.log"
  contar "$SAIDA/controlo-gles-godot.log"
  grep -E "controlo-gles" "$SAIDA/controlo-gles-godot.log" | sed 's/^/  /'
  if [ -n "$JOGO_LOG" ] && [ -s "$JOGO_LOG" ]; then
    echo "== JOGO: $(basename "$JOGO_LOG")"
    contar "$JOGO_LOG"
  fi
} | tee "$SAIDA/controlo-gles-medida.log"
if [ $ok -ne 0 ]; then echo "FALHA: o controlo não disse «pronto» em 60 s"; exit 1; fi
echo "CONTROLO GLES MEDIDO"
